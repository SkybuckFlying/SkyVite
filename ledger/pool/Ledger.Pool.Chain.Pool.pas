unit Ledger.Pool.ChainPool;

interface

uses
  Common.Types,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.BranchChain,
  Ledger.Pool.Chain.Pool.Test,
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
  TChainPool = class
  private
    FPoolID: string;
    FLog: ILog;
    FLastestChainIdx: Int32;
    FSnippetChains: TDictionary<string, TSnippetChain>;
    FTree: ITree;
    FDiskChain: TBranchChain;
    FChainMu: TCriticalSection;
    function ForkChain(ParaForked: IBranch; ParaSnippet: TSnippetChain): IBranch;
    function ForkFrom(ParaForked: IBranch; ParaHeight: UInt64; ParaHash: THash): IBranch;
    function GenChainID: string;
    function IncChainIdx: Integer;
    function Fork2(ParaSnippet: TSnippetChain; ParaChains: TDictionary<string, IBranch>; ParaBp: TBlockPool): TTuple<Boolean, Boolean, IBranch, Exception>;
    procedure InsertSnippet(ParaC: IBranch; ParaSnippet: TSnippetChain);
    procedure Insert(ParaC: IBranch; ParaWrapper: ICommonBlock);
  public
    constructor Create(ParaPoolID: string; ParaLog: ILog);
    destructor Destroy; override;
    procedure Init;
    procedure InsertNotify(ParaHead: ICommonBlock);
    procedure WriteBlockToChain(ParaBlock: ICommonBlock);
    function AllChain: TDictionary<string, IBranch>;
  end;

implementation

uses
  System.StrUtils;

{ TChainPool }

constructor TChainPool.Create(ParaPoolID: string; ParaLog: ILog);
begin
  inherited Create;
  FPoolID := ParaPoolID;
  FLog := ParaLog;
  InitializeCriticalSection(FChainMu);
end;

destructor TChainPool.Destroy;
begin
  DeleteCriticalSection(FChainMu);
  inherited;
end;

function TChainPool.AllChain: TDictionary<string, IBranch>;
begin
  Result := FTree.Branches;
end;

function TChainPool.Fork2(ParaSnippet: TSnippetChain; ParaChains: TDictionary<string, IBranch>; ParaBp: TBlockPool): TTuple<Boolean, Boolean, IBranch, Exception>;
var
  vForky, vInsertable: Boolean;
  vResult: IBranch;
  vHr: IBranch;
  vErr: Exception;
  vTrace: string;
  vC: IBranch;
  vTh: UInt64;
  vTHash: THash;
  vHash: THash;
  vReader: IBranch;
  vI: UInt64;
  vB2: THash;
  vR2: IBranch;
  vSb: ICommonBlock;
  vRHeight: UInt64;
  vRHash: THash;
  vMHeight: UInt64;
  vMHash: THash;
begin
  vForky := False;
  vInsertable := False;
  vResult := nil;
  vHr := nil;
  vErr := nil;
  vTrace := '';

  for vC in ParaChains.Values do
  begin
    vTh := ParaSnippet.TailHeight;
    vTHash := ParaSnippet.TailHash;
    vHash := vC.GetHashAndBranch(vTh).Key;
    vReader := vC.GetHashAndBranch(vTh).Value;
    if (vHash = nil) or (not vHash.IsEqual(vTHash)) then
      Continue;

    for vI := vTh + 1 to ParaSnippet.HeadHeight do
    begin
      vTrace := '';
      vB2 := vC.GetHashAndBranch(vI).Key;
      vR2 := vC.GetHashAndBranch(vI).Value;
      vSb := ParaSnippet.GetBlock(vI);
      if vB2 = nil then
      begin
        vForky := False;
        vInsertable := True;
        vHr := vReader;
        vTrace := vTrace + '[1]';
        Break;
      end;
      if not vB2.IsEqual(vSb.Hash) then
      begin
        if vR2.ID = vReader.ID then
        begin
          vForky := True;
          vInsertable := False;
          vHr := vReader;
          vTrace := vTrace + '[2]';
          Break;
        end;

        vRHeight := vReader.HeadHH.Height;
        vRHash := vReader.HeadHH.Hash;
        if (vRHeight = vTh) and (vRHash.IsEqual(vTHash)) then
        begin
          vForky := False;
          vInsertable := True;
          vHr := vReader;
          vTrace := vTrace + '[3]';
          Break;
        end;
        Break;
      end
      else
      begin
        vReader := vR2;
        vHash := vB2;
        FLog.Debug(Format('block[%s-%d] exists. del from tail.', [vSb.Hash.ToString, vSb.Height]));
        // not implemented
        // tail := snippet.remTail()
        // if tail == nil then
        // begin
        //   delete(cp.snippetChains, snippet.id())
        //   hr = nil
        //   trace += "[4]"
        //   err = errors.Errorf("snippet rem nil. size:%d", snippet.size())
        //   break LOOP
        // end
        // bp.delHashFromCompound(tail.Hash())
        // if snippet.size() == 0 then
        // begin
        //   delete(cp.snippetChains, snippet.id())
        //   hr = nil
        //   trace += "[5]"
        //   err = errors.New("snippet is empty")
        //   break LOOP
        // end
        // tH = tail.Height()
        // tHash = tail.Hash()
      end;
    end;
  end;

  if vErr <> nil then
  begin
    Result := TTuple.Create(False, False, nil, vErr);
    Exit;
  end;

  if vHr = nil then
  begin
    Result := TTuple.Create(False, False, nil, nil);
    Exit;
  end;

  case vHr.BranchType of
    TBranchType.Disk:
      begin
        vResult := FTree.Main;
        if vInsertable then
        begin
          vMHeight := FTree.Main.HeadHH.Height;
          vMHash := FTree.Main.HeadHH.Hash;
          if (vMHeight = ParaSnippet.TailHeight) and (vMHash.IsEqual(ParaSnippet.TailHash)) then
          begin
            vForky := False;
            vInsertable := True;
            vResult := FTree.Main;
            vTrace := vTrace + '[5]';
          end
          else
          begin
            vForky := True;
            vInsertable := False;
            vResult := FTree.Main;
            vTrace := vTrace + '[6]';
          end;
        end;
      end;
    TBranchType.Normal:
      begin
        vTrace := vTrace + '[7]';
        vResult := vHr;
      end;
  end;
  Result := TTuple.Create(vForky, vInsertable, vResult, nil);
end;

function TChainPool.ForkChain(ParaForked: IBranch; ParaSnippet: TSnippetChain): IBranch;
var
  vNew: IBranch;
  vI: UInt64;
  vV: ICommonBlock;
begin
  vNew := FTree.ForkBranch(ParaForked, ParaSnippet.TailHeight, ParaSnippet.TailHash);
  for vI := ParaSnippet.TailHeight + 1 to ParaSnippet.HeadHeight do
  begin
    vV := ParaSnippet.GetBlock(vI);
    vNew.AddHead(vV);
  end;
  Result := vNew;
end;

function TChainPool.ForkFrom(ParaForked: IBranch; ParaHeight: UInt64; ParaHash: THash): IBranch;
var
  vForkedHeight: UInt64;
  vForkedHash: THash;
  vNew: IBranch;
begin
  vForkedHeight := ParaForked.HeadHH.Height;
  vForkedHash := ParaForked.HeadHH.Hash;
  if (vForkedHash.IsEqual(ParaHash)) and (vForkedHeight = ParaHeight) then
  begin
    Result := ParaForked;
    Exit;
  end;

  vNew := FTree.ForkBranch(ParaForked, ParaHeight, ParaHash);
  Result := vNew;
end;

function TChainPool.GenChainID: string;
begin
  Result := FPoolID + '-' + IntToStr(IncChainIdx);
end;

function TChainPool.IncChainIdx: Integer;
begin
  Result := AtomicIncrement(FLastestChainIdx);
end;

procedure TChainPool.Init;
begin
  FSnippetChains := TDictionary<string, TSnippetChain>.Create;
  FTree.Init(FPoolID, FDiskChain);
end;

procedure TChainPool.Insert(ParaC: IBranch; ParaWrapper: ICommonBlock);
var
  vHeight: UInt64;
  vHash: THash;
begin
  if FTree.Main.ID = ParaC.ID then
    FLog.Debug(Format('insert to current[%s]:[%s-%d]%s', [ParaC.ID, ParaWrapper.Hash.ToString, ParaWrapper.Height, ParaWrapper.Latency]))
  else
    FLog.Debug(Format('insert to chain[%s]:[%s-%d]%s', [ParaC.ID, ParaWrapper.Hash.ToString, ParaWrapper.Height, ParaWrapper.Latency]));

  vHeight := ParaC.HeadHH.Height;
  vHash := ParaC.HeadHH.Hash;
  if ParaWrapper.Height = vHeight + 1 then
  begin
    if vHash.IsEqual(ParaWrapper.PrevHash) then
    begin
      ParaC.AddHead(ParaWrapper);
      Exit;
    end;
    raise Exception.CreateFmt('forkedChain fork, fork point height[%d],hash[%s], but next block[%s]''s preHash is [%s]',
      [vHeight, vHash.ToString, ParaWrapper.Hash.ToString, ParaWrapper.PrevHash.ToString]);
  end;
  raise Exception.CreateFmt('forkedChain fork, fork point height[%d],hash[%s], but next block[%s]''s preHash[%s]-[%d]',
    [vHeight, vHash.ToString, ParaWrapper.Hash.ToString, ParaWrapper.PrevHash.ToString, ParaWrapper.Height]);
end;

procedure TChainPool.InsertNotify(ParaHead: ICommonBlock);
begin
  FTree.RootHeadAdd(ParaHead);
end;

procedure TChainPool.InsertSnippet(ParaC: IBranch; ParaSnippet: TSnippetChain);
var
  vI: UInt64;
  vW: ICommonBlock;
begin
  for vI := ParaSnippet.TailHeight + 1 to ParaSnippet.HeadHeight do
  begin
    vW := ParaSnippet.GetBlock(vI);
    Insert(ParaC, vW);
  end;
end;

procedure TChainPool.WriteBlockToChain(ParaBlock: ICommonBlock);
begin
  FDiskChain.FRw.InsertBlock(ParaBlock);
  FTree.RootHeadAdd(ParaBlock);
end;

end.
