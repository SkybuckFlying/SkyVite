unit V2.Ledger.Chain.Check;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Ledger.Chain.State,
  V2.Ledger.Chain.Utils,
  V2.Common.DB.XLevelDB.Util,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.Chain.Chain;

type
  TChainCheckHelper = class helper for TChain
  public
    function CheckRedo: string;
    function CheckRecentBlocks: string;
    function CheckOnRoad: string;
    function CheckHash: string;
  private
    function PrintSnapshotLog(const ASnapshotLog: TSnapshotLog): string;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  V2.Ledger.Chain.State,
  V2.Ledger.Chain.Utils,
  V2.Common.DB.XLevelDB.Util,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.Chain.Chain;

{ TChainCheckHelper }

function TChainCheckHelper.PrintSnapshotLog(const ASnapshotLog: TSnapshotLog): string;
var
  LAddr: TAddress;
  LLogItems: TLogItems;
begin
  Result := '';
  for LAddr in ASnapshotLog.Keys do
  begin
    LLogItems := ASnapshotLog[LAddr];
    Result := Result + Format('%s: %d, ', [LAddr.ToString, Length(LLogItems)]);
  end;
end;

function TChainCheckHelper.CheckRedo: string;
var
  LRedoStore: ILedgerStore;
  LIter: IIterator;
  LRedo: TRedo;
  LPrevHeight: TUInt64;
  LKey: TBytes;
  LSnapshotHeight: TUInt64;
  LChunks: TArray<IChunk>;
  LSnapshotLog: TSnapshotLog;
  LOk: Boolean;
  LBlockCount: Integer;
  LChunk: IChunk;
  LAccountBlock: IAccountBlock;
  LLogs: TLogItems;
  LLogLength: Integer;
  LLogItems: TLogItems;
  LErr: string;
begin
  Result := '';
  LRedoStore := Self.FStateDB.RedoStore;
  LIter := LRedoStore.NewIterator(nil);
  try
    LRedo := Self.FStateDB.Redo;
    LPrevHeight := 0;
    while LIter.Next do
    begin
      LKey := LIter.Key;
      LSnapshotHeight := BytesToUint64(Copy(LKey, 2, Length(LKey) - 1));
      if (LPrevHeight > 0) and (LPrevHeight + 1 <> LSnapshotHeight) then
      begin
        Result := Format('prevHeight + 1 != snapshotHeight, prev height is %d, snapshot height is %d', [LPrevHeight, LSnapshotHeight]);
        Exit;
      end;
      LPrevHeight := LSnapshotHeight;

      try
        LChunks := Self.GetSubLedger(LSnapshotHeight - 1, LSnapshotHeight);
      except
        on E: Exception do
        begin
          Result := Format('c.GetSubLedger failed, start snapshot height is %d, end snapshot height is %d', [LSnapshotHeight - 1, LSnapshotHeight]);
          Exit;
        end;
      end;

      try
        LOk := LRedo.QueryLog(LSnapshotHeight, LSnapshotLog);
        if not LOk then
        begin
          Result := Format('ok is false, snapshot height is %d', [LSnapshotHeight]);
          Exit;
        end;
      except
        on E: Exception do
        begin
          Result := Format('redo.QueryLog failed, snapshot height is %d', [LSnapshotHeight]);
          Exit;
        end;
      end;

      LBlockCount := 0;
      for LChunk in LChunks do
      begin
        LBlockCount := LBlockCount + Length(LChunk.AccountBlocks);
        for LAccountBlock in LChunk.AccountBlocks do
        begin
          if not LSnapshotLog.TryGetValue(LAccountBlock.AccountAddress, LLogs) or (Length(LLogs) <= 0) then
          begin
            Result := Format('!ok || len(logs) <= 0. snapshot log is %s. accountBlock is %s, snapshot height is %d',
              [PrintSnapshotLog(LSnapshotLog), LAccountBlock.ToString, LSnapshotHeight]);
            Exit;
          end;
        end;
      end;

      LLogLength := 0;
      for LLogItems in LSnapshotLog.Values do
        LLogLength := LLogLength + Length(LLogItems);

      if LBlockCount <> LLogLength then
      begin
        Result := Format('blockCount != logLength, blockCount is %d, logLength is %d, snapshot log is %s',
          [LBlockCount, LLogLength, PrintSnapshotLog(LSnapshotLog)]);
        Exit;
      end;

      Self.FLog.Info(Format('snapshot height: %d. %d logs, %d blocks', [LSnapshotHeight, LLogLength, LBlockCount]), 'method', 'checkRedo');
    end;
    LErr := LIter.Error;
    if LErr <> '' then
      Result := LErr;
  finally
    LIter.Release;
  end;
end;

function TChainCheckHelper.CheckRecentBlocks: string;
var
  LLatestSb: ISnapshotBlock;
  LSbList: TArray<ISnapshotBlock>;
  LPrevSb: ISnapshotBlock;
  LAccountLatestBlockMap: TDictionary<TAddress, IAccountBlock>;
  LSb: ISnapshotBlock;
  LAddr: TAddress;
  LHashHeight: IAccountBlockHashHeight;
  LBlock: IAccountBlock;
  LCacheLatestBlock: IAccountBlock;
  LOk: Boolean;
  LLatestBlock: IAccountBlock;
  LConfirmedSb: ISnapshotBlock;
  LPrevBlock: IAccountBlock;
  LErr: string;
begin
  Result := '';
  LLatestSb := Self.GetLatestSnapshotBlock;
  Self.FLog.Info(Format('latest snapshot block is %d, %s', [LLatestSb.Height, LLatestSb.Hash.ToString]), 'method', 'checkRecentBlocks');
  try
    LSbList := Self.GetSnapshotBlocks(LLatestSb.Hash, False, 100);
  except
    on E: Exception do
    begin
      Result := Format('c.GetSnapshotBlocks failed. Error: %s', [E.Message]);
      Exit;
    end;
  end;

  LPrevSb := nil;
  LAccountLatestBlockMap := TDictionary<TAddress, IAccountBlock>.Create;
  try
    for LSb in LSbList do
    begin
      if (LPrevSb <> nil) and ((LPrevSb.PrevHash <> LSb.Hash) or (LPrevSb.Height <> LSb.Height + 1)) then
      begin
        Result := Format('prevSb is %s, sb is %s', [LPrevSb.ToString, LSb.ToString]);
        Exit;
      end;

      LPrevSb := LSb;
      Self.FLog.Info(Format('check snapshot block %d, %s', [LSb.Height, LSb.Hash.ToString]), 'method', 'checkRecentBlocks');

      for LAddr in LSb.SnapshotContent.Keys do
      begin
        LHashHeight := LSb.SnapshotContent[LAddr];
        try
          LBlock := Self.GetAccountBlockByHash(LHashHeight.Hash);
        except
          on E: Exception do
          begin
            Result := Format('c.GetAccountBlockByHash failed, addr is %s, hash is %s. Error: %s', [LAddr.ToString, LHashHeight.Hash.ToString, E.Message]);
            Exit;
          end;
        end;

        while True do
        begin
          if LBlock = nil then
          begin
            Result := Format('c.GetAccountBlockByHash(), block is nil, addr is %s, hash is %s', [LAddr.ToString, LHashHeight.Hash.ToString]);
            Exit;
          end;

          Self.FLog.Info(Format('check account block %s %d %s %s', [LBlock.AccountAddress.ToString, LBlock.Height, LBlock.Hash.ToString, LBlock.FromBlockHash.ToString]));

          if not LAccountLatestBlockMap.TryGetValue(LAddr, LCacheLatestBlock) then
          begin
            try
              LLatestBlock := Self.GetLatestAccountBlock(LAddr);
            except
              on E: Exception do
              begin
                Result := Format('c.GetLatestAccountBlock failed, addr is %s. Error: %s', [LAddr.ToString, E.Message]);
                Exit;
              end;
            end;

            if LLatestBlock = nil then
            begin
              Result := Format('c.GetAccountBlockByHash(), latest account block is nil, addr is %s', [LAddr.ToString]);
              Exit;
            end;

            if LLatestBlock.Hash <> LBlock.Hash then
            begin
              Result := Format('latest account block is %s, block is %s', [LLatestBlock.ToString, LBlock.ToString]);
              Exit;
            end;
          end
          else if LCacheLatestBlock.Height <= LBlock.Height then
          begin
            Result := Format('cacheLatestBlock.Height <= block.Height, cacheLatestBlock is %s, block is %s', [LCacheLatestBlock.ToString, LBlock.ToString]);
            Exit;
          end;

          LAccountLatestBlockMap.AddOrSetValue(LAddr, LBlock);

          if LBlock.Height <= 1 then
            Break;

          try
            LConfirmedSb := Self.GetConfirmSnapshotBlockByAbHash(LBlock.PrevHash);
          except
            on E: Exception do
            begin
              Result := Format('GetConfirmSnapshotBlockByAbHash failed, addr is %s, prevHash is %s. Error: %s', [LAddr.ToString, LBlock.PrevHash.ToString, E.Message]);
              Exit;
            end;
          end;

          if LConfirmedSb = nil then
          begin
            Result := Format('confirmd sb is nil, account block hash is %s', [LBlock.PrevHash.ToString]);
            Exit;
          end;

          if LConfirmedSb.Hash <> LSb.Hash then
            Break;

          try
            LPrevBlock := Self.GetAccountBlockByHash(LBlock.PrevHash);
          except
            on E: Exception do
            begin
              Result := Format('get prev account block failed, addr is %s, prevHash is %s. Error: %s', [LAddr.ToString, LBlock.PrevHash.ToString, E.Message]);
              Exit;
            end;
          end;

          if LPrevBlock = nil then
          begin
            Result := Format('get prev account block is nil, addr is %s, prevHash is %s', [LAddr.ToString, LBlock.PrevHash.ToString]);
            Exit;
          end;

          LBlock := LPrevBlock;
        end;
      end;
    end;
  finally
    LAccountLatestBlockMap.Free;
  end;
end;

function TChainCheckHelper.CheckOnRoad: string;
var
  LIndexStore: ILedgerStore;
  LIter: IIterator;
  LOnRoadCount: Integer;
  LKey: TBytes;
  LToAddrBytes: TBytes;
  LSendBlockHashBytes: TBytes;
  LToAddr: TAddress;
  LSendBlockHash: THash;
  LExisted: Boolean;
  LReceived: Boolean;
  LErr: string;
begin
  Result := '';
  LIndexStore := Self.FIndexDB.Store;
  LIter := LIndexStore.NewIterator(BytesPrefix([OnRoadKeyPrefix]));
  try
    LOnRoadCount := 0;
    while LIter.Next do
    begin
      Inc(LOnRoadCount);
      LKey := LIter.Key;
      LToAddrBytes := Copy(LKey, 2, AddressSize);
      LSendBlockHashBytes := Copy(LKey, 2 + AddressSize, Length(LKey) - (1 + AddressSize));

      try
        LToAddr := BytesToAddress(LToAddrBytes);
      except
        on E: Exception do
        begin
          Result := Format('types.BytesToAddress failed, toAddrBytes is %s', [ToHex(LToAddrBytes)]);
          Exit;
        end;
      end;

      try
        LSendBlockHash := BytesToHash(LSendBlockHashBytes);
      except
        on E: Exception do
        begin
          Result := Format('types.HexToHash failed, sendBlockHashBytes is %s', [ToHex(LSendBlockHashBytes)]);
          Exit;
        end;
      end;

      try
        LExisted := Self.IsAccountBlockExisted(LSendBlockHash);
        if not LExisted then
        begin
          Result := Format('send block is not exsited, sendBlockHash is %s, toAddr is %s', [LSendBlockHash.ToString, LToAddr.ToString]);
          Exit;
        end;
      except
        on E: Exception do
        begin
          Result := Format('c.IsAccountBlockExisted failed, sendBlockHash is %s, toAddr is %s', [LSendBlockHash.ToString, LToAddr.ToString]);
          Exit;
        end;
      end;

      try
        LReceived := Self.IsReceived(LSendBlockHash);
        if LReceived then
        begin
          Result := Format('is received, sendBlockHash is %s', [LSendBlockHash.ToString]);
          Exit;
        end;
      except
        on E: Exception do
        begin
          Result := Format('c.IsReceived failed, sendBlockHash is %s', [LSendBlockHash.ToString]);
          Exit;
        end;
      end;

      Self.FLog.Info(Format('check on road, to addr is %s, send block hash is %s', [LToAddr.ToString, LSendBlockHash.ToString]), 'method', 'checkOnRoad');
    end;

    Self.FLog.Info(Format('total onroad: %d', [LOnRoadCount]), 'method', 'checkOnRoad');
    LErr := LIter.Error;
    if LErr <> '' then
      Result := LErr;
  finally
    LIter.Release;
  end;
end;

function TChainCheckHelper.CheckHash: string;
var
  LStore: ILedgerStore;
  LIter: IIterator;
  LKey: TBytes;
  LHash: THash;
  LBlock: IAccountBlock;
  LComputedHash: THash;
begin
  Result := '';
  LStore := Self.FIndexDB.Store;
  LIter := LStore.NewIterator(BytesPrefix([AccountBlockHashKeyPrefix]));
  try
    while LIter.Next do
    begin
      LKey := LIter.Key;
      try
        LHash := BytesToHash(Copy(LKey, 2, Length(LKey) - 1));
      except
        on E: Exception do
        begin
          Result := Format('BytesToHash failed, key is %s. Error: %s', [ToHex(LKey), E.Message]);
          Exit;
        end;
      end;

      try
        LBlock := Self.GetAccountBlockByHash(LHash);
      except
        on E: Exception do
        begin
          Result := Format('c.GetAccountBlockByHash failed, hash is %s. Error: %s', [LHash.ToString, E.Message]);
          Exit;
        end;
      end;

      if LBlock = nil then
      begin
        Result := Format('block is nil, hash is %s.', [LHash.ToString]);
        Exit;
      end;

      if not (LBlock.IsSendBlock and (LBlock.Height = 0) and LBlock.PrevHash.IsZero) then
      begin
        LComputedHash := LBlock.ComputeHash;
        if LBlock.Hash <> LComputedHash then
        begin
          Self.FLog.Error(Format('error. block.Hash <> block.ComputeHash(), block is %s, computedHash is %s', [LBlock.ToString, LComputedHash.ToString]), 'method', 'CheckHash');
          Continue;
        end;
      end;

      Self.FLog.Info(Format('check account block, blockHash: %s', [LBlock.Hash.ToString]), 'method', 'CheckHash');
    end;
    if LIter.Error <> '' then
    begin
      Result := LIter.Error;
      Exit;
    end;
  finally
    LIter.Release;
  end;
end;

end.
