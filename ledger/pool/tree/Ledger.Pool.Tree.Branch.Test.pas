unit Ledger.Pool.Tree.Branch.Test;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Tree.Branch,
  Ledger.Pool.Tree.Branch.Base,
  Ledger.Pool.Tree.Checker,
  Ledger.Pool.Tree.Mock.Knot,
  Ledger.Pool.Tree.Mock.Root.Branch,
  Ledger.Pool.Tree.Printer,
  Ledger.Pool.Tree.Tree,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Pool.Tree.Tree.Impl.Test,
  SysUtils Classes;

type
  TBranchTest = class
  private
    procedure TestParentChildRelationships;
  public
    procedure RunAllTests;
  end;

implementation

{ TBranchTest }

procedure TBranchTest.TestParentChildRelationships;
var
  tree: ITree; // Mock tree
  root, child1, child2: IBranch;
  txRoot, txChild1, txChild2: ITransaction;
begin
  // 1. Setup
  tree := nil; // A mock ITree might be needed if TBranch uses it
  
  txRoot := TTransaction.Create;
  txChild1 := TTransaction.Create;
  txChild2 := TTransaction.Create;

  root := TBranch.Create(tree, nil, txRoot);
  child1 := TBranch.Create(tree, root, txChild1);
  child2 := TBranch.Create(tree, root, txChild2);
  
  try
    // 2. Add children to root
    root.AddChild(child1);
    root.AddChild(child2);
    
    // 3. Verify relationships
    if child1.GetParent <> root then
      raise Exception.Create('Child1 has incorrect parent');
      
    if child2.GetParent <> root then
      raise Exception.Create('Child2 has incorrect parent');
      
    var children := root.GetChildren;
    if (Length(children) <> 2) or (children[0] <> child1) or (children[1] <> child2) then
      raise Exception.Create('Root has incorrect children');

  finally
    // Freeing is tricky with interfaced objects, but assuming manual free for test
    (root as TObject).Free;
    (child1 as TObject).Free;
    (child2 as TObject).Free;
    txRoot.Free;
    txChild1.Free;
    txChild2.Free;
  end;
end;

procedure TBranchTest.RunAllTests;
begin
  TestParentChildRelationships;
end;

end.
