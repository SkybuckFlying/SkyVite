unit Ledger.Pool.BCPool;

interface

uses
  Common.Types,
  Common.Version,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.ChainPool,
  Ledger.Pool.Common.Block,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.RecoverStat,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Tree,
  Ledger.Pool.Worker,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  TBlockPool = class
  private
    FFreeBlocks: TDictionary<THash, ICommonBlock>;
    FCompoundBlocks: TDictionary<THash, Boolean>;
    FPendingMu: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function Sprint(ParaHash: THash): TPair<ICommonBlock, string>;
    function ContainsHash(ParaHash: THash): Boolean;
    procedure PutBlock(ParaHash: THash; ParaPool: ICommonBlock);
    procedure Compound(ParaW: ICommonBlock);
    procedure DelFromCompound(ParaWs: TDictionary<UInt64, ICommonBlock>);
    procedure DelHashFromCompound(ParaHash: THash);
    function Size: Integer;
  end;

  TChain = record
    mHeightBlocks: TDictionary<UInt64, ICommonBlock>;
    mHeadHeight: UInt64;
    mTailHeight: UInt64;
    mChainID: string;
    function Size: UInt64;
    function HeadHeight: UInt64;
    function ChainID: string;
    function ID: string;
  end;

  TSnippetChain = class
  private
    FChain: TChain;
    FTailHash: THash;
    FHeadHash: THash;
    FUTime: Int64;
  public
    constructor Create(ParaW: ICommonBlock; ParaId: string);
    procedure AddTail(ParaW: ICommonBlock);
    procedure DeleteTail(ParaNewtail: ICommonBlock);
    function RemTail: ICommonBlock;
    procedure Merge(ParaSnippet: TSnippetChain);
    function Info: TDictionary<string, TObject>;
    function GetBlock(ParaHeight: UInt64): ICommonBlock;
  end;

  TBCPool = class
  protected
    FID: string;
    FLog: ILog;
    FBlockPool: TBlockPool;
    FChainPool: TChainPool;
    FTools: TTools;
    FVersion: TVersion;
    FChainTailMu: TCriticalSection;
    FChainHeadMu: TCriticalSection;
    FLimitLongestNum: UInt64;
    FRStat: TRecoverStat;
    procedure InitPool;
    procedure RollbackCurrent(ParaBlocks: TArray<ICommonBlock>);
    function CheckChain(ParaBlocks: TArray<ICommonBlock>): Exception;
    function Printf(ParaBlocks: TArray<ICommonBlock>): string;
    procedure AddBlock(ParaBlock: ICommonBlock);
    function ExistInPool(ParaHashes: THash): Boolean;
    function LoopGenSnippetChains(ParaReadyFilter: Boolean): Integer;
    function LoopAppendChains: Integer;
    function LoopFetchForSnippets: Integer;
    procedure LoopDelUselessChain;
    procedure DelForIrreversible(ParaHeight: UInt64; ParaHash: THash);
    procedure DelSnippet(ParaC: TSnippetChain);
    procedure CheckPool;
    procedure Check;
    procedure CheckCurrent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init(ParaTools: TTools);
    function CurrentModifyToChain(ParaTarget: IBranch): Exception;
    function CurrentModifyToEmpty: Exception;
    function LongerChain(ParaMinHeight: UInt64): TArray<IBranch>;
    function CurrentChain: IBranch;
    procedure Loop;
    function Info: TDictionary<string, TObject>;
    function DetailChain(ParaId: string; ParaHeight: UInt64): TDictionary<string, TObject>;
  end;

implementation

uses
  System.DateUtils,
  System.StrUtils;

{ TBlockPool }

constructor TBlockPool.Create;
begin
  FFreeBlocks := TDictionary<THash, ICommonBlock>.Create;
  FCompoundBlocks := TDictionary<THash, Boolean>.Create;
  InitializeCriticalSection(FPendingMu);
end;

destructor TBlockPool.Destroy;
begin
  FFreeBlocks.Free;
  FCompoundBlocks.Free;
  DeleteCriticalSection(FPendingMu);
  inherited;
end;

procedure TBlockPool.Compound(ParaW: ICommonBlock);
begin
  EnterCriticalSection(FPendingMu);
  try
    FCompoundBlocks.Add(ParaW.Hash, True);
    FFreeBlocks.Remove(ParaW.Hash);
  finally
    LeaveCriticalSection(FPendingMu);
  end;
end;

function TBlockPool.ContainsHash(ParaHash: THash): Boolean;
begin
  Result := FFreeBlocks.ContainsKey(ParaHash) or FCompoundBlocks.ContainsKey(ParaHash);
end;

procedure TBlockPool.DelFromCompound(ParaWs: TDictionary<UInt64, ICommonBlock>);
var
  vB: ICommonBlock;
begin
  EnterCriticalSection(FPendingMu);
  try
    for vB in ParaWs.Values do
      FCompoundBlocks.Remove(vB.Hash);
  finally
    LeaveCriticalSection(FPendingMu);
  end;
end;

procedure TBlockPool.DelHashFromCompound(ParaHash: THash);
begin
  EnterCriticalSection(FPendingMu);
  try
    FCompoundBlocks.Remove(ParaHash);
  finally
    LeaveCriticalSection(FPendingMu);
  end;
end;

procedure TBlockPool.PutBlock(ParaHash: THash; ParaPool: ICommonBlock);
begin
  FFreeBlocks.Add(ParaHash, ParaPool);
end;

function TBlockPool.Size: Integer;
begin
  EnterCriticalSection(FPendingMu);
  try
    Result := FFreeBlocks.Count;
  finally
    LeaveCriticalSection(FPendingMu);
  end;
end;

function TBlockPool.Sprint(ParaHash: THash): TPair<ICommonBlock, string>;
var
  vB1: ICommonBlock;
  vFree: Boolean;
  vCompound: Boolean;
begin
  vFree := FFreeBlocks.TryGetValue(ParaHash, vB1);
  if vFree then
  begin
    Result := TPair<ICommonBlock, string>.Create(vB1, '');
    Exit;
  end;
  vCompound := FCompoundBlocks.ContainsKey(ParaHash);
  if vCompound then
  begin
    Result := TPair<ICommonBlock, string>.Create(nil, 'compound' + ParaHash.ToString);
    Exit;
  end;
  Result := TPair<ICommonBlock, string>.Create(nil, '');
end;

{ TChain }

function TChain.ChainID: string;
begin
  Result := mChainID;
end;

function TChain.HeadHeight: UInt64;
begin
  Result := mHeadHeight;
end;

function TChain.ID: string;
begin
  Result := mChainID;
end;

function TChain.Size: UInt64;
begin
  Result := mHeadHeight - mTailHeight;
end;

{ TSnippetChain }

procedure TSnippetChain.AddTail(ParaW: ICommonBlock);
begin
  FTailHash := ParaW.PrevHash;
  FChain.mTailHeight := ParaW.Height - 1;
  FChain.mHeightBlocks.Add(ParaW.Height, ParaW);
  FUTime := Now.ToUnix;
end;

constructor TSnippetChain.Create(ParaW: ICommonBlock; ParaId: string);
begin
  FChain.mChainID := ParaId;
  FChain.mHeightBlocks := TDictionary<UInt64, ICommonBlock>.Create;
  FChain.mHeadHeight := ParaW.Height;
  FHeadHash := ParaW.Hash;
  FTailHash := ParaW.PrevHash;
  FChain.mTailHeight := ParaW.Height - 1;
  FChain.mHeightBlocks.Add(ParaW.Height, ParaW);
  FUTime := Now.ToUnix;
end;

procedure TSnippetChain.DeleteTail(ParaNewtail: ICommonBlock);
begin
  FTailHash := ParaNewtail.Hash;
  FChain.mTailHeight := ParaNewtail.Height;
  FChain.mHeightBlocks.Remove(ParaNewtail.Height);
end;

function TSnippetChain.GetBlock(ParaHeight: UInt64): ICommonBlock;
begin
  if FChain.mHeightBlocks.ContainsKey(ParaHeight) then
    Result := FChain.mHeightBlocks[ParaHeight]
  else
    Result := nil;
end;

function TSnippetChain.Info: TDictionary<string, TObject>;
begin
  Result := TDictionary<string, TObject>.Create;
  Result.Add('TailHeight', TObject(FChain.mTailHeight));
  Result.Add('TailHash', TObject(FTailHash));
  Result.Add('HeadHeight', TObject(FChain.mHeadHeight));
  Result.Add('HeadHash', TObject(FHeadHash));
  Result.Add('Id', TObject(FChain.ID));
end;

procedure TSnippetChain.Merge(ParaSnippet: TSnippetChain);
var
  vK: UInt64;
  vV: ICommonBlock;
begin
  FChain.mTailHeight := ParaSnippet.FChain.mTailHeight;
  FTailHash := ParaSnippet.FTailHash;
  for vK in ParaSnippet.FChain.mHeightBlocks.Keys do
  begin
    vV := ParaSnippet.FChain.mHeightBlocks[vK];
    FChain.mHeightBlocks.Add(vK, vV);
  end;
  FUTime := Now.ToUnix;
end;

function TSnippetChain.RemTail: ICommonBlock;
var
  vNewTail: ICommonBlock;
begin
  vNewTail := FChain.mHeightBlocks[FChain.mTailHeight + 1];
  if vNewTail = nil then
  begin
    Result := nil;
    Exit;
  end;
  DeleteTail(vNewTail);
  Result := vNewTail;
end;

{ TBCPool }

procedure TBCPool.AddBlock(ParaBlock: ICommonBlock);
var
  vHash: THash;
  vHeight: UInt64;
begin
  EnterCriticalSection(FBlockPool.FPendingMu);
  try
    vHash := ParaBlock.Hash;
    vHeight := ParaBlock.Height;
    if not FBlockPool.ContainsHash(vHash) and not FChainPool.FTree.Exists(vHash) then
      FBlockPool.PutBlock(vHash, ParaBlock)
    else
      FLog.Warn(Format('block exists in BCPool. hash:[%s], height:[%d].', [vHash.ToString, vHeight]));
  finally
    LeaveCriticalSection(FBlockPool.FPendingMu);
  end;
end;

function TBCPool.CheckChain(ParaBlocks: TArray<ICommonBlock>): Exception;
var
  vPrev: ICommonBlock;
  vB: ICommonBlock;
begin
  vPrev := nil;
  for vB in ParaBlocks do
  begin
    if vPrev = nil then
    begin
      vPrev := vB;
      Continue;
    end;
    if not vB.PrevHash.IsEqual(vPrev.Hash) then
    begin
      Result := Exception.Create('not a chain');
      Exit;
    end;
    if vB.Height - 1 <> vPrev.Height then
    begin
      Result := Exception.Create('not a chain');
      Exit;
    end;
    vPrev := vB;
  end;
  Result := nil;
end;

procedure TBCPool.Check;
var
  vMain: IBranch;
  vTailHeight: UInt64;
  vTailHash: THash;
  vHeadHeight: UInt64;
  vHeadHash: THash;
begin
  vMain := CurrentChain;
  vTailHeight := vMain.TailHH.Height;
  vTailHash := vMain.TailHH.Hash;
  vHeadHeight := FChainPool.FDiskChain.HeadHH.Height;
  vHeadHash := FChainPool.FDiskChain.HeadHH.Hash;
  if (vHeadHeight <> vTailHeight) or (not vHeadHash.IsEqual(vTailHash)) then
    raise Exception.CreateFmt('pool[%s] tail[%d-%s], chain head[%d-%s]', [vMain.ID, vTailHeight, vTailHash.ToString, vHeadHeight, vHeadHash.ToString]);
  FTree.CheckTree(FChainPool.FTree);
end;

procedure TBCPool.CheckCurrent;
begin
  if Random(10000) > 10 then
    Exit;
  Check;
end;

procedure TBCPool.CheckPool;
begin
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      Check;
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

constructor TBCPool.Create;
begin
  inherited;
  InitializeCriticalSection(FChainTailMu);
  InitializeCriticalSection(FChainHeadMu);
end;

function TBCPool.CurrentChain: IBranch;
begin
  Result := FChainPool.FTree.Main;
end;

function TBCPool.CurrentModifyToChain(ParaTarget: IBranch): Exception;
var
  vMain: IBranch;
begin
  vMain := FChainPool.FTree.Main;
  FLog.Info('current modify', 'targetId', ParaTarget.ID, 'TargetTail', ParaTarget.SprintTail, 'currentId', vMain.ID, 'CurrentTail', vMain.SprintTail);
  Result := FChainPool.FTree.SwitchMainTo(ParaTarget);
end;

function TBCPool.CurrentModifyToEmpty: Exception;
begin
  Result := FChainPool.FTree.SwitchMainToEmpty;
end;

procedure TBCPool.DelForIrreversible(ParaHeight: UInt64; ParaHash: THash);
begin
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      //
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

procedure TBCPool.DelSnippet(ParaC: TSnippetChain);
begin
  FChainPool.FSnippetChains.Remove(ParaC.FChain.ID);
  FBlockPool.DelFromCompound(ParaC.FChain.mHeightBlocks);
end;

destructor TBCPool.Destroy;
begin
  DeleteCriticalSection(FChainTailMu);
  DeleteCriticalSection(FChainHeadMu);
  inherited;
end;

function TBCPool.DetailChain(ParaId: string; ParaHeight: UInt64): TDictionary<string, TObject>;
var
  vV: IBranch;
  vKnot: IKnot;
begin
  Result := FTree.PrintTree(FChainPool.FTree);
  if ParaHeight <> 0 then
  begin
    for vV in FChainPool.FTree.Branches.Values do
    begin
      if vV.ID = ParaId then
      begin
        vKnot := vV.GetKnot(ParaHeight, False);
        if vKnot <> nil then
          Result.Add('block', vKnot);
      end;
    end;
  end;
end;

function TBCPool.ExistInPool(ParaHashes: THash): Boolean;
begin
  EnterCriticalSection(FBlockPool.FPendingMu);
  try
    Result := FBlockPool.ContainsHash(ParaHashes) or FChainPool.FTree.Exists(ParaHashes);
  finally
    LeaveCriticalSection(FBlockPool.FPendingMu);
  end;
end;

function TBCPool.Info: TDictionary<string, TObject>;
var
  vBp: TBlockPool;
  vCp: TChainPool;
  vSnippetIds: TArray<TObject>;
  vV: TSnippetChain;
  vChainIds: TArray<TObject>;
  vV2: IBranch;
begin
  EnterCriticalSection(FBlockPool.FPendingMu);
  try
    EnterCriticalSection(FChainHeadMu);
    try
      EnterCriticalSection(FChainTailMu);
      try
        Result := TDictionary<string, TObject>.Create;
        vBp := FBlockPool;
        vCp := FChainPool;

        Result.Add('FreeSize', TObject(vBp.FFreeBlocks.Count));
        Result.Add('CompoundSize', TObject(vBp.FCompoundBlocks.Count));
        Result.Add('SnippetSize', TObject(vCp.FSnippetChains.Count));
        Result.Add('TreeSize', TObject(vCp.FTree.Size));
        Result.Add('CurrentLen', TObject(vCp.FTree.Main.Size));

        SetLength(vSnippetIds, vCp.FSnippetChains.Count);
        for vV in vCp.FSnippetChains.Values do
          vSnippetIds[Succ(High(vSnippetIds))] := vV.Info;
        Result.Add('Snippets', TObject(vSnippetIds));

        SetLength(vChainIds, vCp.AllChain.Count);
        for vV2 in vCp.AllChain.Values do
          vChainIds[Succ(High(vChainIds))] := FTree.PrintBranchInfo(vV2);
        Result.Add('Chains', TObject(vChainIds));
        Result.Add('ChainSize', TObject(Length(vChainIds)));
        Result.Add('Current', TObject(FTree.PrintBranchInfo(vCp.FTree.Main)));
        Result.Add('Disk', TObject(FTree.PrintBranchInfo(vCp.FDiskChain)));
      finally
        LeaveCriticalSection(FChainTailMu);
      end;
    finally
      LeaveCriticalSection(FChainHeadMu);
    end;
  finally
    LeaveCriticalSection(FBlockPool.FPendingMu);
  end;
end;

procedure TBCPool.Init(ParaTools: TTools);
begin
  FTools := ParaTools;
  FLimitLongestNum := 3;
  FRStat := TRecoverStat.Create(10, 10 * 1000);
  InitPool;
end;

procedure TBCPool.InitPool;
var
  vT: ITree;
  vDiskChain: TBranchChain;
  vChainPool: TChainPool;
  vBlockPool: TBlockPool;
begin
  vT := FTree.NewTree;
  vDiskChain := TBranchChain.Create(FTools.FRw, FID + '-diskchain', FVersion, vT);
  vChainPool := TChainPool.Create(FID, FLog);
  vChainPool.Init;
  vBlockPool := TBlockPool.Create;
  FChainPool := vChainPool;
  FBlockPool := vBlockPool;
end;

function TBCPool.LongerChain(ParaMinHeight: UInt64): TArray<IBranch>;
var
  vReaders: TDictionary<string, IBranch>;
  vCurrent: IBranch;
  vReader: IBranch;
  vHeight: UInt64;
begin
  SetLength(Result, 0);
  vReaders := FChainPool.AllChain;
  vCurrent := CurrentChain;
  for vReader in vReaders.Values do
  begin
    if vCurrent.ID = vReader.ID then
      Continue;
    vHeight := vReader.HeadHH.Height;
    if vHeight > ParaMinHeight then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := vReader;
    end;
  end;
end;

procedure TBCPool.Loop;
begin
  while True do
  begin
    LoopGenSnippetChains(False);
    LoopAppendChains;
    LoopFetchForSnippets;
    TThread.Sleep(1000);
  end;
end;

function TBCPool.LoopAppendChains: Integer;
var
  vSortSnippets: TArray<TSnippetChain>;
  vTmpChains: TDictionary<string, IBranch>;
  vW: TSnippetChain;
  vForky, vInsertable: Boolean;
  vC: IBranch;
  vErr: Exception;
  vNewChain: IBranch;
begin
  if FChainPool.FSnippetChains.Count = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := 0;
  // vSortSnippets := copyMap(FChainPool.FSnippetChains);
  // sort.Sort(ByTailHeight(sortSnippets));

  vTmpChains := FChainPool.AllChain;

  for vW in vSortSnippets do
  begin
    vForky := FChainPool.Fork2(vW, vTmpChains, FBlockPool).Item1;
    vInsertable := FChainPool.Fork2(vW, vTmpChains, FBlockPool).Item2;
    vC := FChainPool.Fork2(vW, vTmpChains, FBlockPool).Item3;
    vErr := FChainPool.Fork2(vW, vTmpChains, FBlockPool).Item4;
    if vErr <> nil then
    begin
      DelSnippet(vW);
      Continue;
    end;
    if vForky then
    begin
      Inc(Result);
      vNewChain := FChainPool.ForkChain(vC, vW);
      if vNewChain <> nil then
      begin
        DelSnippet(vW);
        FLog.Debug(Format('insert new chain[%s][%s][%s],[%s][%s][%s]', [vC.ID, vC.SprintHead, vC.SprintTail, vNewChain.ID, vNewChain.SprintHead, vNewChain.SprintTail]));
      end;
      Continue;
    end;
    if vInsertable then
    begin
      Inc(Result);
      FChainPool.InsertSnippet(vC, vW);
      DelSnippet(vW);
      Continue;
    end;
  end;
end;

procedure TBCPool.LoopDelUselessChain;
var
  vC: TSnippetChain;
  vDels: TArray<IBranch>;
  vC2: IBranch;
begin
  EnterCriticalSection(FChainHeadMu);
  try
    EnterCriticalSection(FChainTailMu);
    try
      for vC in FChainPool.FSnippetChains.Values do
      begin
        if vC.FUTime + (5 * 60 * 1000) < Now.ToUnix then
        begin
          DelSnippet(vC);
          FLog.Info(Format('delete snippet[%s][%d-%s][%d-%s]', [vC.FChain.ID, vC.FChain.mHeadHeight, vC.FHeadHash.ToString, vC.FChain.mTailHeight, vC.FTailHash.ToString]));
        end;
      end;

      vDels := FChainPool.FTree.PruneTree;
      for vC2 in vDels do
        FLog.Debug('del useless chain', 'info', Format('%s', [vC2.ID]), 'tail', vC2.SprintTail, 'height', vC2.SprintHead);
    finally
      LeaveCriticalSection(FChainTailMu);
    end;
  finally
    LeaveCriticalSection(FChainHeadMu);
  end;
end;

function TBCPool.LoopFetchForSnippets: Integer;
var
  vSortSnippets: TArray<TSnippetChain>;
  vCur: IBranch;
  vHeadH: UInt64;
  vHead: TUInt64;
  vZero: TUInt64;
  vPrev: TUInt64;
  vW: TSnippetChain;
  vDiff: TUInt64;
  vTailHeight: TUInt64;
  vB: ICommonBlock;
  vHash: THashHeight;
begin
  if FChainPool.FSnippetChains.Count = 0 then
  begin
    Result := 0;
    Exit;
  end;
  // sortSnippets := copyMap(FChainPool.FSnippetChains);
  // sort.Sort(ByTailHeight(sortSnippets));

  vCur := CurrentChain;
  vHeadH := vCur.HeadHH.Height;
  vHead := vHeadH;

  Result := 0;
  vZero := 0;
  vPrev := vZero;

  for vW in vSortSnippets do
  begin
    vDiff := 0;
    vTailHeight := vW.FChain.mTailHeight;
    if vPrev > 0 then
      vDiff := vTailHeight - vPrev
    else
      vDiff := vTailHeight - vHead;

    if vDiff <= 0 then
      vDiff := vTailHeight - vHead;

    if vDiff <= 0 then
      vDiff := 100;

    vB := vW.GetBlock(vW.FChain.mTailHeight + 1);
    if (vB <> nil) and (not vB.ShouldFetch) then
      Continue;
    Inc(Result);
    vHash := THashHeight.Create(vW.FChain.mTailHeight, vW.FTailHash);
    FTools.FFetcher.Fetch(vHash, vDiff);

    vPrev := vW.FChain.mHeadHeight;
  end;
end;

function TBCPool.LoopGenSnippetChains(ParaReadyFilter: Boolean): Integer;
var
  vSortPending: TArray<ICommonBlock>;
  vChains: TArray<TSnippetChain>;
  vV: ICommonBlock;
  vSnippet: TSnippetChain;
  vHeadMap: TDictionary<THash, TSnippetChain>;
  vChain: TSnippetChain;
  vTail: THash;
  vOc: TSnippetChain;
  vFinal: TDictionary<string, TSnippetChain>;
begin
  if FBlockPool.FFreeBlocks.Count = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Result := 0;
  // sortPending := copyValuesFrom(FBlockPool.FFreeBlocks, FBlockPool.FPendingMu);
  // sort.Sort(sort.Reverse(ByHeight(sortPending)));

  // chains := copyMap(FChainPool.FSnippetChains);

  for vV in vSortPending do
  begin
    if ParaReadyFilter then
    begin
      if not vV.Ready then
        Continue;
    end;
    // if not tryInsert(chains, v) then
    // begin
    //   snippet := newSnippetChain(v, FChainPool.genChainID())
    //   chains = append(chains, snippet)
    // end
    Inc(Result);
    FBlockPool.Compound(vV);
  end;

  // headMap := splitToMap(chains);
  for vChain in vChains do
  begin
    while True do
    begin
      vTail := vChain.FTailHash;
      if vHeadMap.ContainsKey(vTail) then
      begin
        vOc := vHeadMap[vTail];
        if vChain.FChain.ID <> vOc.FChain.ID then
        begin
          vHeadMap.Remove(vTail);
          vChain.Merge(vOc);
        end
        else
          Break;
      end
      else
        Break;
    end;
  end;
  vFinal := TDictionary<string, TSnippetChain>.Create;
  for vV in vHeadMap.Values do
    vFinal.Add(vV.FChain.ID, vV);
  FChainPool.FSnippetChains := vFinal;
end;

function TBCPool.Printf(ParaBlocks: TArray<ICommonBlock>): string;
var
  vV: ICommonBlock;
begin
  Result := '';
  for vV in ParaBlocks do
    Result := Result + Format('[%d-%s-%s]', [vV.Height, vV.Hash.ToString, vV.PrevHash.ToString]);
end;

procedure TBCPool.RollbackCurrent(ParaBlocks: TArray<ICommonBlock>);
var
  vCur: IBranch;
  vCurTailHeight: UInt64;
  vCurTailHash: THash;
  vDisk: TBranchChain;
  vHeadHeight: UInt64;
  vHeadHash: THash;
  vH: Integer;
  vSmallest, vLongest: ICommonBlock;
  vMain: IBranch;
  vI: Integer;
begin
  if Length(ParaBlocks) <= 0 then
    Exit;
  vCur := CurrentChain;
  vCurTailHeight := vCur.TailHH.Height;
  vCurTailHash := vCur.TailHH.Hash;
  // sort.Sort(ByHeight(blocks));

  FLog.Info('rollbackCurrent', 'start', ParaBlocks[0].Height, 'end', ParaBlocks[High(ParaBlocks)].Height, 'size', Length(ParaBlocks),
    'currentId', vCur.ID);
  vDisk := FChainPool.FDiskChain;
  vHeadHeight := vDisk.HeadHH.Height;
  vHeadHash := vDisk.HeadHH.Hash;

  CheckChain(ParaBlocks);

  if vCur.Linked(vDisk) then
  begin
    FLog.Info('poolChain and db is connected.', 'headHeight', vHeadHeight, 'headHash', vHeadHash.ToString);
    Exit;
  end;

  vH := High(ParaBlocks);
  vSmallest := ParaBlocks[0];
  vLongest := ParaBlocks[vH];
  if (vHeadHeight + 1 <> vSmallest.Height) or (not vHeadHash.IsEqual(vSmallest.PrevHash)) then
    raise Exception.Create(FID + ' disk chain height hash check fail');

  if (vCurTailHeight <> vLongest.Height) or (not vCurTailHash.IsEqual(vLongest.Hash)) then
    raise Exception.Create(FID + ' current chain height hash check fail');

  vMain := FChainPool.FTree.Main;
  for vI := vH downto 0 do
    FChainPool.FTree.AddTail(vMain, ParaBlocks[vI]);

  FTree.CheckTree(FChainPool.FTree);
end;

end.
