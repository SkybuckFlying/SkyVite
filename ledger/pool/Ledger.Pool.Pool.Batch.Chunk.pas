unit Ledger.Pool.Pool.Batch.Chunk;

interface

uses
  System.SysUtils, System.Generics.Collections,
  net.interface,
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Pool,
  Ledger.Pool.Tree,
  Ledger.Pool.Batch;

type
  TChainState = (DISCONNECT = 1, CONNECTED = 2, FORKED = 3);

  TPoolBatchChunkHelper = class helper for TPool
  public
    function InsertChunks(reader: IChunkReader; chunks: IChunk): Boolean;
    procedure InsertChunksToPool(chunks: TArray<ISnapshotChunk>; source: TBlockSource);
    function InsertChunksToChain(chunks: TArray<ISnapshotChunk>; source: TBlockSource): Exception;
    function CheckSnapshotInsert(headHH, tailHH: IHashHeight; hashes: TDictionary<THash, Boolean>): TChainState;
    function CheckAccountsInsert(minAddrs: TDictionary<TAddress, TArray<IHashHeight>>; hashes: TDictionary<THash, Boolean>): TChainState;
    function CheckInsert(branch: IBranch; waitingHeadH, waitingTailH: IHashHeight; hashes: TDictionary<THash, Boolean>): TChainState;
  end;

implementation

{ TPoolBatchChunkHelper }

function TPoolBatchChunkHelper.InsertChunks(reader: IChunkReader; chunks: IChunk): Boolean;
var
  vSource: TBlockSource;
  vHashes: TDictionary<THash, Boolean>;
  vSnapshotRange: TArray<IHashHeight>;
  vHead, vTail: IHashHeight;
  vState: TChainState;
  vAccountRange: TDictionary<TAddress, TArray<IHashHeight>>;
  vError: Exception;
begin
  vSource := chunks.GetSource;
  vHashes := chunks.GetHashMap;
  vSnapshotRange := chunks.GetSnapshotRange;
  vHead := vSnapshotRange[1];
  vTail := vSnapshotRange[0];

  vState := CheckSnapshotInsert(vHead, vTail, vHashes);
  if vState = FORKED then
  begin
    InsertChunksToPool(chunks.GetSnapshotChunks, vSource);
    reader.Pop(vHead.Hash);
    Exit(False);
  end;
  if vState = DISCONNECT then
    Exit(False);

  vAccountRange := chunks.GetAccountRange;
  vState := CheckAccountsInsert(vAccountRange, vHashes);
  if vState = FORKED then
  begin
    InsertChunksToPool(chunks.GetSnapshotChunks, vSource);
    reader.Pop(vHead.Hash);
    Exit(False);
  end;
  if vState = DISCONNECT then
    Exit(False);

  LockInsert;
  try
    vState := CheckSnapshotInsert(vHead, vTail, vHashes);
    if vState <> CONNECTED then
      Exit(False);
    vState := CheckAccountsInsert(vAccountRange, vHashes);
    if vState <> CONNECTED then
      Exit(False);

    FBC.SetCacheLevelForConsensus(1);
    try
      vError := InsertChunksToChain(chunks.GetSnapshotChunks, vSource);
      if vError <> nil then
      begin
        FLog.Error('insert chunks fail.', ['err', vError.Message]);
        InsertChunksToPool(chunks.GetSnapshotChunks, vSource);
        reader.Pop(vHead.Hash);
        Exit(False);
      end;
    finally
      FBC.SetCacheLevelForConsensus(0);
    end;
  finally
    UnLockInsert;
  end;

  FLog.Info('insert chunks success.', ['headHeight', vHead.Height, 'headHash', vHead.Hash.ToString, 'tailHeight', vTail.Height, 'tailHash', vTail.Hash.ToString]);
  reader.Pop(vHead.Hash);
  Result := True;
end;

procedure TPoolBatchChunkHelper.InsertChunksToPool(chunks: TArray<ISnapshotChunk>; source: TBlockSource);
var
  vChunk: ISnapshotChunk;
  vAccountBlock: IAccountBlock;
begin
  for vChunk in chunks do
  begin
    if Length(vChunk.AccountBlocks) > 0 then
    begin
      for vAccountBlock in vChunk.AccountBlocks do
        AddAccountBlock(vAccountBlock.AccountAddress, vAccountBlock, source);
    end;
    if vChunk.SnapshotBlock <> nil then
      AddSnapshotBlock(vChunk.SnapshotBlock, source);
  end;
end;

function TPoolBatchChunkHelper.InsertChunksToChain(chunks: TArray<ISnapshotChunk>; source: TBlockSource): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolBatchChunkHelper.CheckSnapshotInsert(headHH, tailHH: IHashHeight; hashes: TDictionary<THash, Boolean>): TChainState;
var
  vCur: IBranch;
begin
  vCur := FPendingSc.CurrentChain;
  Result := CheckInsert(vCur, headHH, tailHH, hashes);
end;

function TPoolBatchChunkHelper.CheckAccountsInsert(minAddrs: TDictionary<TAddress, TArray<IHashHeight>>; hashes: TDictionary<THash, Boolean>): TChainState;
var
  vPair: TPair<TAddress, TArray<IHashHeight>>;
  vCur: IBranch;
begin
  for vPair in minAddrs do
  begin
    vCur := SelfPendingAc(vPair.Key).CurrentChain;
    Result := CheckInsert(vCur, vPair.Value[1], vPair.Value[0], hashes);
    if Result <> CONNECTED then
      Exit;
  end;
  Result := CONNECTED;
end;

function TPoolBatchChunkHelper.CheckInsert(branch: IBranch; waitingHeadH, waitingTailH: IHashHeight; hashes: TDictionary<THash, Boolean>): TChainState;
var
  vCurHeight: TUInt64;
  vCurHash: THash;
begin
  vCurHeight := branch.HeadHH.Height;
  vCurHash := branch.HeadHH.Hash;
  if waitingTailH.Height = vCurHeight then
  begin
    if waitingTailH.Hash.IsEqual(vCurHash) then
      Exit(CONNECTED);
    Exit(FORKED);
  end;
  if vCurHeight > waitingTailH.Height then
  begin
    if vCurHeight >= waitingHeadH.Height then
    begin
      if branch.ContainsKnot(waitingHeadH.Height, waitingHeadH.Hash, True) then
        Exit(CONNECTED);
      Exit(FORKED);
    end;

    if hashes.ContainsKey(vCurHash) then
      Exit(CONNECTED);
    Exit(FORKED);
  end;
  Result := DISCONNECT;
end;

end.
