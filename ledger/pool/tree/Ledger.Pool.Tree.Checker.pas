unit Ledger.Pool.Tree.Checker;

interface

uses
  Interfaces.Core,
  Ledger.Pool.Tree.Branch,
  Ledger.Pool.Tree.Branch.Base,
  Ledger.Pool.Tree.Branch.Test,
  Ledger.Pool.Tree.Mock.Knot,
  Ledger.Pool.Tree.Mock.Root.Branch,
  Ledger.Pool.Tree.Printer,
  Ledger.Pool.Tree.Tree,
  Ledger.Pool.Tree.Tree // For ITree,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Pool.Tree.Tree.Impl.Test,
  SysUtils Classes;

type
  TChecker = class
  private
    FChain: IChainReader;
    
  public
    constructor Create(Chain: IChainReader);
    function Check(Tree: ITree): Boolean;
  end;

implementation

{ TChecker }

constructor TChecker.Create(Chain: IChainReader);
begin
  inherited Create;
  FChain := Chain;
end;

function TChecker.Check(Tree: ITree): Boolean;
var
  root: IBranch;
  queue: TQueue<IBranch>;
  current: IBranch;
  child: IBranch;
begin
  // This is a simplified check. A real implementation would be more complex,
  // potentially involving recursion or a more sophisticated traversal algorithm.
  
  root := Tree.GetRoot;
  if root = nil then
    Exit(True); // An empty tree is valid
    
  // Use a breadth-first search to traverse the tree
  queue := TQueue<IBranch>.Create;
  try
    queue.Enqueue(root);
    
    while queue.Count > 0 do
    begin
      current := queue.Dequeue;
      
      // 1. Verify the transaction in the current branch
      // if not FChain.VerifyTransaction(current.GetTransaction) then
      //   Exit(False);
        
      // 2. Enqueue children for the next level
      for child in current.GetChildren do
      begin
        // 3. Check for valid parent-child relationship
        if child.GetParent <> current then
          Exit(False);
          
        queue.Enqueue(child);
      end;
    end;
    
  finally
    queue.Free;
  end;
  
  Result := True;
end;

end.
