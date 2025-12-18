unit Ledger.Pool.Tree.Tree;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Tree.Branch,
  Ledger.Pool.Tree.Branch // For IBranch,
  Ledger.Pool.Tree.Branch.Base,
  Ledger.Pool.Tree.Branch.Test,
  Ledger.Pool.Tree.Checker,
  Ledger.Pool.Tree.Mock.Knot,
  Ledger.Pool.Tree.Mock.Root.Branch,
  Ledger.Pool.Tree.Printer,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Pool.Tree.Tree.Impl.Test,
  System.Generics.Collections,
  SysUtils Classes SyncObjs;

type
  ITree = interface
    ['{GUID-ITree}']
    function GetRoot: IBranch;
    procedure SetRoot(Root: IBranch);
    procedure AddBranch(Branch: IBranch);
    function GetBranch(Hash: THash): IBranch;
  end;

  TTree = class(TInterfacedObject, ITree)
  private
    FRoot: IBranch;
    FBranches: TDictionary<THash, IBranch>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    function GetRoot: IBranch;
    procedure SetRoot(Root: IBranch);
    procedure AddBranch(Branch: IBranch);
    function GetBranch(Hash: THash): IBranch;
  end;

implementation

{ TTree }

constructor TTree.Create;
begin
  inherited Create;
  FBranches := TDictionary<THash, IBranch>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TTree.Destroy;
begin
  FBranches.Free;
  FLock.Free;
  inherited;
end;

function TTree.GetRoot: IBranch;
begin
  FLock.BeginRead;
  try
    Result := FRoot;
  finally
    FLock.EndRead;
  end;
end;

procedure TTree.SetRoot(Root: IBranch);
begin
  FLock.BeginWrite;
  try
    FRoot := Root;
    if Root <> nil then
      FBranches.AddOrSetValue(Root.GetTransaction.Hash, Root);
  finally
    FLock.EndWrite;
  end;
end;

procedure TTree.AddBranch(Branch: IBranch);
begin
  FLock.BeginWrite;
  try
    if Branch.GetTransaction <> nil then
    begin
      FBranches.AddOrSetValue(Branch.GetTransaction.Hash, Branch);
    end;
  finally
    FLock.EndWrite;
  end;
end;

function TTree.GetBranch(Hash: THash): IBranch;
begin
  FLock.BeginRead;
  try
    FBranches.TryGetValue(Hash, Result);
  finally
    FLock.EndRead;
  end;
end;

end.
