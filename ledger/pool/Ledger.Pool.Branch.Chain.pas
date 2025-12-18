unit Ledger.Pool.BranchChain;

interface

uses
  Common.Types,
  Common.Version,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Chain.Pool,
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
  System.Classes,
  System.SysUtils;

type
  IChainRw = interface
    ['{A7B1C2D3-E4F5-A6B7-C8D9-E0F1A2B3C4D5}']
    procedure InsertBlock(ParaBlock: ICommonBlock);
    procedure InsertBlocks(ParaBlocks: TArray<ICommonBlock>);
    function Head: ICommonBlock;
    function GetBlock(ParaHeight: UInt64): ICommonBlock;
    function GetHash(ParaHeight: UInt64): THash;
  end;

  TBranchChain = class(TInterfacedObject, IBranch)
  private
    FRw: IChainRw;
    FChainID: string;
    FVersion: TVersion;
    FHead: THashHeight;
    FTree: ITree;
  public
    constructor Create(ParaRw: IChainRw; ParaChainID: string; ParaVersion: TVersion; ParaTree: ITree);
    function RemoveTail(ParaKnot: IKnot): Exception;
    function MatchHead(ParaHash: THash): Boolean;
    function Linked(ParaRoot: IBranch): Boolean;
    procedure AddTail(ParaKnot: IKnot);
    function SprintTail: string;
    function SprintHead: string;
    function GetKnotAndBranch(ParaHeight: UInt64): TPair<IKnot, IBranch>;
    function GetHashAndBranch(ParaHeight: UInt64): TPair<THash, IBranch>;
    function TailHH: THashHeight;
    function Size: UInt64;
    function AddHead(ParaKnot: IKnot): Exception;
    function GetKnot(ParaHeight: UInt64; ParaFlag: Boolean): IKnot;
    function GetHash(ParaHeight: UInt64; ParaFlag: Boolean): THash;
    function ContainsKnot(ParaHeight: UInt64; ParaHash: THash; ParaFlag: Boolean): Boolean;
    function Head: ICommonBlock;
    function UTime: Int64;
    function HeadHH: THashHeight;
    function Root: IBranch;
    function ID: string;
    function BranchType: TBranchType;
  end;

implementation

uses
  System.DateUtils;

{ TBranchChain }

constructor TBranchChain.Create(ParaRw: IChainRw; ParaChainID: string; ParaVersion: TVersion; ParaTree: ITree);
begin
  FRw := ParaRw;
  FChainID := ParaChainID;
  FVersion := ParaVersion;
  FTree := ParaTree;
end;

function TBranchChain.AddHead(ParaKnot: IKnot): Exception;
begin
  raise Exception.Create('not support');
end;

procedure TBranchChain.AddTail(ParaKnot: IKnot);
begin
  raise Exception.Create('not support');
end;

function TBranchChain.BranchType: TBranchType;
begin
  Result := TBranchType.Disk;
end;

function TBranchChain.ContainsKnot(ParaHeight: UInt64; ParaHash: THash; ParaFlag: Boolean): Boolean;
begin
  raise Exception.Create('implement me');
end;

function TBranchChain.GetHash(ParaHeight: UInt64; ParaFlag: Boolean): THash;
begin
  Result := FRw.GetHash(ParaHeight);
end;

function TBranchChain.GetHashAndBranch(ParaHeight: UInt64): TPair<THash, IBranch>;
var
  vHash: THash;
begin
  vHash := GetHash(ParaHeight, True);
  Result := TPair<THash, IBranch>.Create(vHash, Self);
end;

function TBranchChain.GetKnot(ParaHeight: UInt64; ParaFlag: Boolean): IKnot;
begin
  Result := FRw.GetBlock(ParaHeight);
end;

function TBranchChain.GetKnotAndBranch(ParaHeight: UInt64): TPair<IKnot, IBranch>;
var
  vKnot: IKnot;
begin
  vKnot := GetKnot(ParaHeight, True);
  Result := TPair<IKnot, IBranch>.Create(vKnot, Self);
end;

function TBranchChain.Head: ICommonBlock;
var
  vHead: ICommonBlock;
begin
  vHead := FRw.Head;
  if vHead = nil then
    Result := FRw.GetBlock(0) // hack implement
  else
    Result := vHead;
end;

function TBranchChain.HeadHH: THashHeight;
var
  vH: THashHeight;
  vHead: ICommonBlock;
begin
  vH := FHead;
  if vH = nil then
  begin
    vHead := Head;
    Result := THashHeight.Create(vHead.Height, vHead.Hash);
  end
  else
    Result := vH;
end;

function TBranchChain.ID: string;
begin
  Result := FChainID;
end;

function TBranchChain.Linked(ParaRoot: IBranch): Boolean;
begin
  raise Exception.Create('not support');
end;

function TBranchChain.MatchHead(ParaHash: THash): Boolean;
var
  vH: THash;
begin
  vH := HeadHH.Hash;
  Result := ParaHash.IsEqual(vH);
end;

function TBranchChain.RemoveTail(ParaKnot: IKnot): Exception;
begin
  raise Exception.Create('implement me');
end;

function TBranchChain.Root: IBranch;
begin
  raise Exception.Create('not support');
end;

function TBranchChain.Size: UInt64;
var
  vU: UInt64;
begin
  vU := HeadHH.Height;
  Result := vU;
end;

function TBranchChain.SprintHead: string;
var
  vH1: UInt64;
  vH2: THash;
begin
  vH1 := HeadHH.Height;
  vH2 := HeadHH.Hash;
  Result := Format('%d-%s', [vH1, vH2.ToString]);
end;

function TBranchChain.SprintTail: string;
begin
  Result := 'DISK TAIL';
end;

function TBranchChain.TailHH: THashHeight;
begin
  raise Exception.Create('not support');
end;

function TBranchChain.UTime: Int64;
begin
  Result := Now.ToUnix;
end;

end.
