unit Ledger.Pool.Tree.Tree.Impl;

interface

uses
  SysUtils, Classes, SyncObjs,
  System.Generics.Collections,
  Ledger.Pool.Tree.Tree, // For ITree
  Ledger.Pool.Tree.Branch,
  Common.Types,
  Interfaces.Core;

type
  TTreeImpl = class(TInterfacedObject, ITree)
  private
    FChain: IChainReader;
    FRoot: IBranch;
    FBranches: TDictionary<THash, IBranch>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
    
    procedure AddBranchToParent(Branch: IBranch);
    
  public
    constructor Create(Chain: IChainReader);
    destructor Destroy; override;
    
    function GetRoot: IBranch;
    procedure SetRoot(Root: IBranch);
    procedure AddBranch(Branch: IBranch);
    function GetBranch(Hash: THash): IBranch;
    
    procedure AddTransaction(Tx: ITransaction);
    procedure RemoveTransaction(Hash: THash);
  end;

implementation

{ TTreeImpl }

constructor TTreeImpl.Create(Chain: IChainReader);
begin
  inherited Create;
  FChain := Chain;
  FBranches := TDictionary<THash, IBranch>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TTreeImpl.Destroy;
begin
  FBranches.Free;
  FLock.Free;
  inherited;
end;

function TTreeImpl.GetRoot: IBranch;
begin
  Result := FRoot;
end;

procedure TTreeImpl.SetRoot(Root: IBranch);
begin
  FLock.BeginWrite;
  try
    FRoot := Root;
  finally
    FLock.EndWrite;
  end;
end;

procedure TTreeImpl.AddBranch(Branch: IBranch);
begin
  FLock.BeginWrite;
  try
    FBranches.AddOrSetValue(Branch.GetTransaction.Hash, Branch);
  finally
    FLock.EndWrite;
  end;
end;

function TTreeImpl.GetBranch(Hash: THash): IBranch;
begin
  FLock.BeginRead;
  try
    FBranches.TryGetValue(Hash, Result);
  finally
    FLock.EndRead;
  end;
end;

procedure TTreeImpl.AddTransaction(Tx: ITransaction);
var
  parentHash: THash;
  parentBranch: IBranch;
  newBranch: IBranch;
begin
  parentHash := Tx.ParentHash; // Assuming ITransaction has a ParentHash
  
  FLock.BeginWrite;
  try
    parentBranch := GetBranch(parentHash);
    
    if parentBranch = nil then
    begin
      // Handle orphan transaction
      // Maybe add to a separate list
      Exit;
    end;
    
    newBranch := TBranch.Create(Self, parentBranch, Tx);
    parentBranch.AddChild(newBranch);
    AddBranch(newBranch);
    
  finally
    FLock.EndWrite;
  end;
end;

procedure TTreeImpl.RemoveTransaction(Hash: THash);
var
  branch: IBranch;
  child: IBranch;
begin
  FLock.BeginWrite;
  try
    branch := GetBranch(Hash);
    if branch = nil then
      Exit;
      
    // Remove branch from its parent
    if branch.GetParent <> nil then
    begin
      // branch.GetParent.RemoveChild(branch); // Assumes this method exists
    end;
    
    // Reparent any children to this branch's parent
    for child in branch.GetChildren do
    begin
      // child.SetParent(branch.GetParent); // Assumes this method exists
    end;
    
    FBranches.Remove(Hash);
    
  finally
    FLock.EndWrite;
  end;
end;

end.
