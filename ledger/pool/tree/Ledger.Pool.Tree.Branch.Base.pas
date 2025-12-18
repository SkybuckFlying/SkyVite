unit Ledger.Pool.Tree.Branch.Base;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Tree.Branch,
  Ledger.Pool.Tree.Branch // For IBranch,
  Ledger.Pool.Tree.Branch.Test,
  Ledger.Pool.Tree.Checker,
  Ledger.Pool.Tree.Mock.Knot,
  Ledger.Pool.Tree.Mock.Root.Branch,
  Ledger.Pool.Tree.Printer,
  Ledger.Pool.Tree.Tree,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Pool.Tree.Tree.Impl.Test,
  System.Generics.Collections,
  SysUtils Classes;

type
  TBranchBase = class(TInterfacedObject, IBranch)
  private
    FParent: IBranch;
    FChildren: TList<IBranch>;
    FTransaction: ITransaction;
    FTree: ITree;
    
  protected
    function GetParent: IBranch;
    function GetChildren: TArray<IBranch>;
    function GetTransaction: ITransaction;
    procedure AddChild(Child: IBranch);
    
  public
    constructor Create(Tree: ITree; Parent: IBranch; Tx: ITransaction);
    destructor Destroy; override;
  end;

implementation

{ TBranchBase }

constructor TBranchBase.Create(Tree: ITree; Parent: IBranch; Tx: ITransaction);
begin
  inherited Create;
  FTree := Tree;
  FParent := Parent;
  FTransaction := Tx;
  FChildren := TList<IBranch>.Create;
end;

destructor TBranchBase.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TBranchBase.GetParent: IBranch;
begin
  Result := FParent;
end;

function TBranchBase.GetChildren: TArray<IBranch>;
begin
  Result := FChildren.ToArray;
end;

function TBranchBase.GetTransaction: ITransaction;
begin
  Result := FTransaction;
end;

procedure TBranchBase.AddChild(Child: IBranch);
begin
  FChildren.Add(Child);
end;

end.
