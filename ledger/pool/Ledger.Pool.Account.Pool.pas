unit Ledger.Pool.Account.Pool;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Common.Types,
  Common.Version,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Ledger.Pool.Batch,
  Ledger.Pool.Tree,
  Ledger.Verifier,
  Log15,
  Ledger.Pool.BCPool,
  Ledger.Pool.Common.Block,
  Ledger.Pool.RecoverStat,
  Ledger.Pool.Blacklist,
  Ledger.Pool.BranchChain;

type
  TAccountPoolBlock = class(TInterfacedObject, ICommonBlock)
  private
    FForkBlock: TForkBlock;
    FBlock: TAccountBlock;
    FVmBlock: IVmDb;
    FRecover: TRecoverStat;
    FFailStat: TRecoverStat;
    FDelStat: TRecoverStat;
    FFailNum: Integer;
  public
    constructor Create(ParaBlock: TAccountBlock; ParaVmBlock: IVmDb; ParaVersion: TVersion; ParaSource: TBlockSource);
    function ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
    function Height: UInt64;
    function Hash: THash;
    function PrevHash: THash;
    function Owner: TAddress;
    function Ready: Boolean;
    function ShouldFetch: Boolean;
    function GetForkVersion: TVersion;
    procedure SetForkVersion(ParaVersion: TVersion);
    function CheckForkVersion: Boolean;
    procedure ResetForkVersion;
    function GetNTime: Int64;
    procedure SetNTime(ParaNTime: Int64);
    function GetSource: TBlockSource;
    procedure SetSource(ParaSource: TBlockSource);
    function GetConfirmTime: Int64;
    procedure SetConfirmTime(ParaConfirmTime: Int64);
    function Latency: Int64;
  end;

  TAccountPool = class(TBCPool)
  private
    FRw: IChainRw;
    FLoopTime: Int64;
    FLoopFetchTime: Int64;
    FAddress: TAddress;
    FV: IAccountVerifier;
    FF: TAccountSyncer;
    FPool: TPool;
    FHashBlacklist: IBlacklist;
    procedure CheckReset;
    procedure Reset;
  public
    constructor Create(ParaName: string; ParaRw: IChainRw; ParaVersion: TVersion; ParaHashBlacklist: IBlacklist; ParaLog: ILog);
    procedure Init(ParaTools: TTools; ParaPool: TPool; ParaV: IAccountVerifier; ParaF: TAccountSyncer);
    function Compact: Integer;
    function PendingAccountTo(ParaH: THashHeight; ParaSHeight: UInt64): THashHeight;
    function VerifySuccess(ParaBs: TAccountPoolBlock): UInt64;
    function FindInPool(ParaHash: THash; ParaHeight: UInt64): Boolean;
    function FindInTree(ParaHash: THash; ParaHeight: UInt64): IBranch;
    function FindInTreeDisk(ParaHash: THash; ParaHeight: UInt64; ParaDisk: Boolean): IBranch;
    function AddDirectBlocks(ParaReceived: TAccountPoolBlock): Exception;
    function GetCurrentBlock(ParaI: UInt64): TAccountPoolBlock;
    function MakePackage(ParaQ: IBatch; ParaInfo: TOffsetInfo; ParaMax: UInt64): TPair<UInt64, Exception>;
    function ChooseAndSwitchCurrentForMake(ParaInfo: TOffsetInfo): IBranch;
    function TryInsertItems(ParaP: IBatch; ParaItems: TArray<IItem>; ParaLatestSb: ISnapshotBlock; ParaVersion: UInt64): Exception;
    function CheckSnapshotSuccess(ParaBlock: TAccountPoolBlock): Exception;
    function GenForSnapshotContents(ParaP: IBatch; ParaB: TSnapshotPoolBlock; ParaK: TAddress; ParaV: THashHeight): TPair<Boolean, TStack<ICommonBlock>>;
    function ShouldDestroy: Boolean;
  end;

implementation

uses
  System.DateUtils,
  System.Math;

{ TAccountPoolBlock }

constructor TAccountPoolBlock.Create(ParaBlock: TAccountBlock; ParaVmBlock: IVmDb; ParaVersion: TVersion; ParaSource: TBlockSource);
begin
  FForkBlock.SetForkVersion(ParaVersion);
  FForkBlock.SetSource(ParaSource);
  FForkBlock.SetNTime(Now.ToUnix);
  FBlock := ParaBlock;
  FVmBlock := ParaVmBlock;
  FRecover := TRecoverStat.Create(10, 60 * 60 * 1000);
  FFailStat := TRecoverStat.Create(10, 30 * 1000);
  FDelStat := TRecoverStat.Create(100, 10 * 60 * 1000);
  FFailNum := 0;
end;

function TAccountPoolBlock.CheckForkVersion: Boolean;
begin
  Result := FForkBlock.CheckForkVersion;
end;

function TAccountPoolBlock.GetConfirmTime: Int64;
begin
  Result := FForkBlock.GetConfirmTime;
end;

function TAccountPoolBlock.GetForkVersion: TVersion;
begin
  Result := FForkBlock.GetForkVersion;
end;

function TAccountPoolBlock.GetNTime: Int64;
begin
  Result := FForkBlock.GetNTime;
end;

function TAccountPoolBlock.GetSource: TBlockSource;
begin
  Result := FForkBlock.GetSource;
end;

function TAccountPoolBlock.Hash: THash;
begin
  Result := FBlock.Hash;
end;

function TAccountPoolBlock.Height: UInt64;
begin
  Result := FBlock.Height;
end;

function TAccountPoolBlock.Latency: Int64;
begin
  Result := FForkBlock.Latency;
end;

function TAccountPoolBlock.Owner: TAddress;
begin
  Result := FBlock.AccountAddress;
end;

function TAccountPoolBlock.PrevHash: THash;
begin
  Result := FBlock.PrevHash;
end;

function TAccountPoolBlock.Ready: Boolean;
begin
  Result := True;
end;

function TAccountPoolBlock.ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
var
  vKeys, vAccounts: TArray<THash>;
  vSnapshot: THash;
  vSendB: TAccountBlock;
begin
  if FBlock.IsReceiveBlock then
  begin
    SetLength(vAccounts, Length(vAccounts) + 1);
    vAccounts[High(vAccounts)] := FBlock.FromBlockHash;
  end;
  if Height > 1 then
  begin
    SetLength(vAccounts, Length(vAccounts) + 1);
    vAccounts[High(vAccounts)] := PrevHash;
  end;
  SetLength(vKeys, Length(vKeys) + 1);
  vKeys[High(vKeys)] := Hash;
  if Length(FBlock.SendBlockList) > 0 then
  begin
    for vSendB in FBlock.SendBlockList do
    begin
      SetLength(vKeys, Length(vKeys) + 1);
      vKeys[High(vKeys)] := vSendB.Hash;
    end;
  end;
  Result := TTuple.Create(vKeys, vAccounts, vSnapshot);
end;

procedure TAccountPoolBlock.ResetForkVersion;
begin
  FForkBlock.ResetForkVersion;
end;

procedure TAccountPoolBlock.SetConfirmTime(ParaConfirmTime: Int64);
begin
  FForkBlock.SetConfirmTime(ParaConfirmTime);
end;

procedure TAccountPoolBlock.SetForkVersion(ParaVersion: TVersion);
begin
  FForkBlock.SetForkVersion(ParaVersion);
end;

procedure TAccountPoolBlock.SetNTime(ParaNTime: Int64);
begin
  FForkBlock.SetNTime(ParaNTime);
end;

procedure TAccountPoolBlock.SetSource(ParaSource: TBlockSource);
begin
  FForkBlock.SetSource(ParaSource);
end;

function TAccountPoolBlock.ShouldFetch: Boolean;
begin
  Result := FForkBlock.ShouldFetch;
end;

{ TAccountPool }

function TAccountPool.AddDirectBlocks(ParaReceived: TAccountPoolBlock): Exception;
var
  vLatestSb: ISnapshotBlock;
  vCurrent: IBranch;
  vTailHeight: UInt64;
  vTailHash: THash;
  vStat: TAccountVerifierStat;
  vResult: TVerifierResult;
begin
  vLatestSb := FRw.GetLatestSnapshotBlock;
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      vCurrent := CurrentChain;
      vTailHeight := vCurrent.TailHH.Height;
      vTailHash := vCurrent.TailHH.Hash;
      if (ParaReceived.Height <> vTailHeight + 1) or (not ParaReceived.PrevHash.IsEqual(vTailHash)) then
      begin
        Result := Exception.CreateFmt('account head not match[%d-%s][%s]', [ParaReceived.Height, ParaReceived.PrevHash.ToString, vCurrent.SprintTail]);
        Exit;
      end;

      CheckCurrent;
      vStat := FV.VerifyAccount(ParaReceived, vLatestSb);
      vResult := vStat.VerifyResult;
      case vResult of
        TVerifierResult.Pending:
          begin
            Result := Exception.CreateFmt('db for directly adding account block[%s-%s-%d].', [ParaReceived.FBlock.AccountAddress.ToString, ParaReceived.Hash.ToString, ParaReceived.Height]);
            Exit;
          end;
        TVerifierResult.Fail:
          begin
            if vStat.Err <> nil then
            begin
              Result := vStat.Err;
              Exit;
            end;
            Result := Exception.CreateFmt('directly adding account block[%s-%s-%d] fail.', [ParaReceived.FBlock.AccountAddress.ToString, ParaReceived.Hash.ToString, ParaReceived.Height]);
            Exit;
          end;
        TVerifierResult.Success:
          begin
            FLog.Debug('AddDirectBlocks', 'height', ParaReceived.Height, 'hash', ParaReceived.Hash.ToString);
            VerifySuccess(vStat.Block);
            Result := nil;
            Exit;
          end;
      else
        raise Exception.Create('verify unexpected.');
      end;
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

function TAccountPool.ChooseAndSwitchCurrentForMake(ParaInfo: TOffsetInfo): IBranch;
var
  vMain: IBranch;
  vUTime: Int64;
  vBrothers: TArray<IBranch>;
  vRandN: Integer;
  vBranch: IBranch;
begin
  vMain := FChainPool.FTree.Main;
  if ParaInfo.Offset = nil then
  begin
    Result := vMain;
    Exit;
  end;
  vUTime := vMain.UTime;
  if Now.ToUnix > vUTime + 5 * 1000 then
  begin
    vBrothers := FChainPool.FTree.Brothers(vMain);
    if Length(vBrothers) = 0 then
    begin
      Result := vMain;
      Exit;
    end;
    vRandN := Random(Length(vBrothers));
    vBranch := vBrothers[vRandN];
    FLog.Info('current modify for random', 'targetId', vBranch.ID, 'TargetTail', vBranch.SprintTail, 'currentId', vMain.ID, 'CurrentTail', vMain.SprintTail);
    FChainPool.FTree.SwitchMainTo(vBranch);
    Result := FChainPool.FTree.Main;
    Exit;
  end;
  Result := vMain;
end;

function TAccountPool.Compact: Integer;
var
  vNow: Int64;
  vSum: Integer;
begin
  EnterCriticalSection(FChainHeadMu);
  try
    vNow := Now.ToUnix;
    vSum := 0;

    FLoopTime := vNow;
    vSum := vSum + LoopGenSnippetChains(False);
    vSum := vSum + LoopAppendChains;

    if vNow > FLoopFetchTime + 200 then
    begin
      FLoopFetchTime := vNow;
      vSum := vSum + LoopFetchForSnippets;
      CheckCurrent;
      CheckReset;
    end;
    Result := vSum;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

constructor TAccountPool.Create(ParaName: string; ParaRw: IChainRw; ParaVersion: TVersion; ParaHashBlacklist: IBlacklist; ParaLog: ILog);
begin
  inherited Create;
  FID := ParaName;
  FRw := ParaRw;
  FVersion := ParaVersion;
  FLoopTime := Now.ToUnix;
  FLog := ParaLog.New('account', ParaName);
  FHashBlacklist := ParaHashBlacklist;
end;

function TAccountPool.FindInPool(ParaHash: THash; ParaHeight: UInt64): Boolean;
begin
  EnterCriticalSection(FBlockPool.FPendingMu);
  try
    Result := FBlockPool.ContainsHash(ParaHash);
  finally
    LeaveCriticalSection(FBlockPool.FPendingMu);
  end;
end;

function TAccountPool.FindInTree(ParaHash: THash; ParaHeight: UInt64): IBranch;
begin
  Result := FChainPool.FTree.FindBranch(ParaHeight, ParaHash);
end;

function TAccountPool.FindInTreeDisk(ParaHash: THash; ParaHeight: UInt64; ParaDisk: Boolean): IBranch;
var
  vCur: IBranch;
  vTargetHash: THash;
  vC: IBranch;
  vB: IKnot;
begin
  vCur := CurrentChain;
  vTargetHash := vCur.GetHash(ParaHeight, ParaDisk);
  if (vTargetHash <> nil) and (vTargetHash.IsEqual(ParaHash)) then
  begin
    Result := vCur;
    Exit;
  end;

  for vC in FChainPool.AllChain.Values do
  begin
    vB := vC.GetKnot(ParaHeight, False);
    if vB = nil then
      Continue
    else
    begin
      if vB.Hash.IsEqual(ParaHash) then
      begin
        Result := vC;
        Exit;
      end;
    end;
  end;
  Result := nil;
end;

function TAccountPool.GetCurrentBlock(ParaI: UInt64): TAccountPoolBlock;
var
  vB: IKnot;
begin
  vB := FChainPool.FTree.Main.GetKnot(ParaI, False);
  if vB <> nil then
    Result := vB as TAccountPoolBlock
  else
    Result := nil;
end;

procedure TAccountPool.Init(ParaTools: TTools; ParaPool: TPool; ParaV: IAccountVerifier; ParaF: TAccountSyncer);
begin
  inherited Init(ParaTools);
  FPool := ParaPool;
  FV := ParaV;
  FF := ParaF;
end;

function TAccountPool.MakePackage(ParaQ: IBatch; ParaInfo: TOffsetInfo; ParaMax: UInt64): TPair<UInt64, Exception>;
var
  vCurrent: IBranch;
  vTailHeight: UInt64;
  vTailHash: THash;
  vBlock: TAccountPoolBlock;
  vMinH, vHeadH, vI: UInt64;
  vUsed, vUnused: UInt64;
  vEnought: Boolean;
begin
  if FChainPool.FTree.Main.Size <= 0 then
  begin
    Result := TPair<UInt64, Exception>.Create(0, Exception.Create('empty chainpool'));
    Exit;
  end;

  FPool.RLockInsert;
  try
    EnterCriticalSection(FChainHeadMu);
    try
      EnterCriticalSection(FChainTailMu);
      try
        vCurrent := ChooseAndSwitchCurrentForMake(ParaInfo);

        if ParaInfo.Offset = nil then
        begin
          vTailHeight := vCurrent.TailHH.Height;
          vTailHash := vCurrent.TailHH.Hash;
          ParaInfo.Offset := THashHeight.Create(vTailHeight, vTailHash);
          ParaInfo.QuotaUnused := FRw.GetQuotaUnused;
        end
        else
        begin
          vBlock := vCurrent.GetKnot(ParaInfo.Offset.Height + 1, False) as TAccountPoolBlock;
          if (vBlock = nil) or (not vBlock.PrevHash.IsEqual(ParaInfo.Offset.Hash)) then
          begin
            Result := TPair<UInt64, Exception>.Create(0, Exception.Create('current chain modify'));
            Exit;
          end;
        end;

        vMinH := ParaInfo.Offset.Height + 1;
        vHeadH := vCurrent.HeadHH.Height;
        for vI := vMinH to vHeadH do
        begin
          if vI - vMinH >= ParaMax then
          begin
            Result := TPair<UInt64, Exception>.Create(vI - vMinH, Exception.Create('arrived to max'));
            Exit;
          end;
          vBlock := GetCurrentBlock(vI);
          if vBlock = nil then
          begin
            Result := TPair<UInt64, Exception>.Create(vI - vMinH, Exception.Create('current chain modify'));
            Exit;
          end;
          if FHashBlacklist.Exists(vBlock.Hash) then
          begin
            Result := TPair<UInt64, Exception>.Create(vI - vMinH, Exception.Create('block in blacklist'));
            Exit;
          end;
          vUsed := ParaInfo.QuotaEnough(vBlock).Key;
          vUnused := ParaInfo.QuotaEnough(vBlock).Value;
          vEnought := ParaInfo.QuotaEnough(vBlock).Key > 0;
          if not vEnought then
          begin
            Result := TPair<UInt64, Exception>.Create(vI - vMinH, Exception.Create('block quota not enough'));
            Exit;
          end;
          FLog.Debug(Format('[%s][%d][%s]quota info [used:%d][unused:%d]', [vBlock.FBlock.AccountAddress.ToString, vBlock.Height, vBlock.Hash.ToString, vUsed, vUnused]));
          CheckSnapshotSuccess(vBlock);

          ParaQ.AddAItem(vBlock, nil);
          ParaInfo.Offset.Hash := vBlock.Hash;
          ParaInfo.Offset.Height := vBlock.Height;
          ParaInfo.QuotaSub(vBlock);
        end;

        Result := TPair<UInt64, Exception>.Create(vHeadH - vMinH, Exception.Create('all in'));
      finally
        LeaveCriticalSection(FChainTailMu);
      end;
    finally
      LeaveCriticalSection(FChainHeadMu);
    end;
  finally
    FPool.RUnLockInsert;
  end;
end;

function TAccountPool.PendingAccountTo(ParaH: THashHeight; ParaSHeight: UInt64): THashHeight;
var
  vTargetChain: IBranch;
  vCurrent: IBranch;
  vForkPoint: IKnot;
  vTailHeight: UInt64;
begin
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      vTargetChain := FindInTree(ParaH.Hash, ParaH.Height);
      if vTargetChain <> nil then
      begin
        vCurrent := CurrentChain;
        if vTargetChain.ID = vCurrent.ID then
        begin
          Result := nil;
          Exit;
        end;

        vForkPoint := FChainPool.FTree.FindForkPointFromMain(vTargetChain).Value;
        vTailHeight := vCurrent.TailHH.Height;
        if vForkPoint.Height < vTailHeight then
        begin
          Result := ParaH;
          Exit;
        end;
        FLog.Info('PendingAccountTo->CurrentModifyToChain', 'addr', FAddress.ToString, 'hash', ParaH.Hash.ToString, 'height', ParaH.Height, 'targetChain',
          vTargetChain.ID, 'targetChainTailt', vTargetChain.SprintTail, 'targetChainHead', vTargetChain.SprintHead,
          'forkPoint', Format('[%s-%d]', [vForkPoint.Hash.ToString, vForkPoint.Height]));
        CurrentModifyToChain(vTargetChain);
        Result := nil;
        Exit;
      end;
      Result := nil;
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

procedure TAccountPool.Reset;
begin
  inherited Init(FTools);
end;

function TAccountPool.ShouldDestroy: Boolean;
begin
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      if FBlockPool.Size > 0 then
      begin
        Result := False;
        Exit;
      end;

      if FChainPool.FSnippetChains.Count > 0 then
      begin
        Result := False;
        Exit;
      end;

      if FChainPool.FTree.Size > 0 then
      begin
        Result := False;
        Exit;
      end;
      if Now.ToUnix < FChainPool.FTree.Main.UTime + 8 * 60 * 1000 then
      begin
        Result := False;
        Exit;
      end;
      Result := True;
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

function TAccountPool.VerifySuccess(ParaBs: TAccountPoolBlock): UInt64;
var
  vCp: TChainPool;
begin
  vCp := FChainPool;
  FRw.InsertBlock(ParaBs);
  vCp.InsertNotify(ParaBs);
  Result := 1;
end;

procedure TAccountPool.CheckReset;
var
  vTailHeight, vHeadHeight: UInt64;
  vKnot: IKnot;
  vBlock: TAccountPoolBlock;
begin
  vTailHeight := CurrentChain.TailHH.Height;
  vHeadHeight := CurrentChain.HeadHH.Height;
  if vHeadHeight > vTailHeight then
  begin
    vKnot := CurrentChain.GetKnot(vTailHeight + 1, False);
    if vKnot = nil then
      Exit;
    vBlock := vKnot as TAccountPoolBlock;
    if (vBlock.FFailNum > 20) and (Now.ToUnix > vBlock.GetNTime + 60 * 1000) then
      Reset;
  end;
end;

function TAccountPool.CheckSnapshotSuccess(ParaBlock: TAccountPoolBlock): Exception;
var
  vNum: Byte;
  vB: UInt64;
begin
  if ParaBlock.FBlock.IsReceiveBlock then
  begin
    if not ParaBlock.FBlock.AccountAddress.IsContractAddress then
    begin
      Result := nil;
      Exit;
    end;
    vNum := FRw.NeedSnapshot(ParaBlock.FBlock.AccountAddress);
    if vNum > 0 then
    begin
      vB := FRw.GetConfirmedTimes(ParaBlock.FBlock.FromBlockHash);
      if vB >= vNum then
      begin
        Result := nil;
        Exit;
      end;
      Result := Exception.Create('send block need to snapshot');
      Exit;
    end;
  end;
  Result := nil;
end;

function TAccountPool.GenForSnapshotContents(ParaP: IBatch; ParaB: TSnapshotPoolBlock; ParaK: TAddress; ParaV: THashHeight): TPair<Boolean, TStack<ICommonBlock>>;
var
  vAcurr: IBranch;
  vTailHeight: UInt64;
  vTargetHash: THash;
  vTmp: TStack<ICommonBlock>;
  vH: UInt64;
  vCurrB: TAccountPoolBlock;
begin
  EnterCriticalSection(FChainTailMu);
  try
    vAcurr := CurrentChain;
    vTailHeight := vAcurr.TailHH.Height;
    vTargetHash := vAcurr.GetHash(ParaV.Height, True);
    if vTargetHash = nil then
    begin
      Result := TPair<Boolean, TStack<ICommonBlock>>.Create(True, nil);
      Exit;
    end;
    if not vTargetHash.IsEqual(ParaV.Hash) then
    begin
      FLog.Info(Format('account chain has forked. snapshot block[%d-%s], account block[%s-%d][%s<->%s]',
        [ParaB.Height, ParaB.Hash.ToString, ParaK.ToString, ParaV.Height, ParaV.Hash.ToString, vTargetHash.ToString]));
      Result := TPair<Boolean, TStack<ICommonBlock>>.Create(True, nil);
      Exit;
    end;

    if ParaV.Height > vTailHeight then
    begin
      vTmp := TStack<ICommonBlock>.Create;
      for vH := ParaV.Height downto vTailHeight + 1 do
      begin
        vCurrB := GetCurrentBlock(vH);
        if ParaP.Exists(vCurrB.Hash) then
          Break;
        vTmp.Push(vCurrB);
      end;
      if vTmp.Count > 0 then
      begin
        Result := TPair<Boolean, TStack<ICommonBlock>>.Create(False, vTmp);
        Exit;
      end;
    end;
    Result := TPair<Boolean, TStack<ICommonBlock>>.Create(False, nil);
  finally
    LeaveCriticalSection(FChainTailMu);
  end;
end;

function TAccountPool.TryInsertItems(ParaP: IBatch; ParaItems: TArray<IItem>; ParaLatestSb: ISnapshotBlock; ParaVersion: UInt64): Exception;
var
  vCp: TChainPool;
  vI: Integer;
  vItem: IItem;
  vBlock: TAccountPoolBlock;
  vCurrent: IBranch;
  vTailHeight: UInt64;
  vTailHash: THash;
  vStat: TAccountVerifierStat;
begin
  EnterCriticalSection(FChainTailMu);
  try
    vCp := FChainPool;
    for vI := 0 to High(ParaItems) do
    begin
      vItem := ParaItems[vI];
      vBlock := vItem as TAccountPoolBlock;
      FLog.Info(Format('[%d]try to insert account block[%d-%s]%d-%d.', [ParaP.ID, vBlock.Height, vBlock.Hash.ToString, vI, Length(ParaItems)]));
      vCurrent := vCp.FTree.Root;
      vTailHeight := vCurrent.HeadHH.Height;
      vTailHash := vCurrent.HeadHH.Hash;
      if (vBlock.Height = vTailHeight + 1) and (vBlock.PrevHash.IsEqual(vTailHash)) then
      begin
        vBlock.ResetForkVersion;
        if vBlock.GetForkVersion.Val <> ParaVersion then
        begin
          Result := Exception.Create('snapshot version update');
          Exit;
        end;

        vStat := FV.VerifyAccount(vBlock, ParaLatestSb);
        if not vBlock.CheckForkVersion then
        begin
          vBlock.ResetForkVersion;
          Result := Exception.Create('new fork version');
          Exit;
        end;
        case vStat.VerifyResult of
          TVerifierResult.Fail:
            begin
              FLog.Warn('add account block to blacklist.', 'hash', vBlock.Hash.ToString, 'height', vBlock.Height, 'err', vStat.Err.Message);
              FHashBlacklist.AddAddTimeout(vBlock.Hash, 10 * 1000);
              Inc(vBlock.FFailNum);
              Result := Exception.Create('fail verifier');
              Exit;
            end;
          TVerifierResult.Pending:
            begin
              FLog.Error('snapshot db.', 'hash', vBlock.Hash.ToString, 'height', vBlock.Height);
              Result := Exception.Create('fail verifier db.');
              Exit;
            end;
        end;
        vCp.WriteBlockToChain(vStat.Block);
      end
      else
      begin
        Result := Exception.Create('tail not match');
        Exit;
      end;
      FLog.Info(Format('[%d]try to insert account block[%d-%s]%d-%d [latency:%d]success.', [ParaP.ID, vBlock.Height, vBlock.Hash.ToString, vI, Length(ParaItems), vBlock.Latency]));
    end;
    Result := nil;
  finally
    LeaveCriticalSection(FChainTailMu);
  end;
end;

end.
