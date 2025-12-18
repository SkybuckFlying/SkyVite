unit Ledger.Pool.Tree.Tree.Impl.Test;

interface

uses
  SysUtils, Classes,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Mock.Chain,
  Common.Types,
  Interfaces.Core;

type
  TTreeImplTest = class
  private
    procedure TestAddAndRemove;
  public
    procedure RunAllTests;
  end;

implementation

{ TTreeImplTest }

procedure TTreeImplTest.TestAddAndRemove;
var
  tree: TTreeImpl;
  chain: TMockChain;
  txRoot, txChild1, txChild2: ITransaction;
  rootBranch, child1Branch: IBranch;
begin
  // 1. Setup
  chain := TMockChain.Create;
  tree := TTreeImpl.Create(chain);
  
  txRoot := TTransaction.Create;
  txRoot.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('root'));
  
  txChild1 := TTransaction.Create;
  txChild1.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('child1'));
  // txChild1.ParentHash := txRoot.Hash;
  
  txChild2 := TTransaction.Create;
  txChild2.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('child2'));
  // txChild2.ParentHash := txRoot.Hash;
  
  try
    // 2. Add transactions
    // The root needs to be set manually first
    rootBranch := TBranch.Create(tree, nil, txRoot);
    tree.SetRoot(rootBranch);
    tree.AddBranch(rootBranch);
    
    tree.AddTransaction(txChild1);
    tree.AddTransaction(txChild2);
    
    // 3. Verify tree structure
    child1Branch := tree.GetBranch(txChild1.Hash);
    if (child1Branch = nil) or (child1Branch.GetParent <> rootBranch) then
      raise Exception.Create('Child1 was not added correctly');
      
    if rootBranch.GetChildren.Length <> 2 then
      raise Exception.Create('Root does not have the correct number of children');
      
    // 4. Test removal
    tree.RemoveTransaction(txChild1.Hash);
    
    if tree.GetBranch(txChild1.Hash) <> nil then
      raise Exception.Create('Child1 was not removed');
      
    if rootBranch.GetChildren.Length <> 1 then
      raise Exception.Create('Child was not removed from parent');
      
  finally
    tree.Free;
    chain.Free;
    txRoot.Free;
    txChild1.Free;
    txChild2.Free;
  end;
end;

procedure TTreeImplTest.RunAllTests;
begin
  TestAddAndRemove;
end;

end.
