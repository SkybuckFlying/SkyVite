unit Ledger.Pool.Tree.Branch;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Tree.Branch.Base,
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
  // Forward declaration
  ITree = interface;
  IBranch = interface;

  IBranch = interface
    ['{GUID-IBranch}']
    function GetParent: IBranch;
    function GetChildren: TArray<IBranch>;
    function GetTransaction: ITransaction;
    procedure AddChild(Child: IBranch);
  end;

  TBranch = class(TInterfacedObject, IBranch)
  private
    FParent: IBranch;
    FChildren: TList<IBranch>;
    FTransaction: ITransaction;
    FTree: ITree;
  public
    constructor Create(Tree: ITree; Parent: IBranch; Tx: ITransaction);
    destructor Destroy; override;
    
    function GetParent: IBranch;
    function GetChildren: TArray<IBranch>;
    function GetTransaction: ITransaction;
    procedure AddChild(Child: IBranch);
  end;
  
  ITree = interface
    // ...
  end;

implementation

{ TBranch }

constructor TBranch.Create(Tree: ITree; Parent: IBranch; Tx: ITransaction);
begin
  inherited Create;
  FTree := Tree;
  FParent := Parent;
  FTransaction := Tx;
  FChildren := TList<IBranch>.Create;
end;

destructor TBranch.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TBranch.GetParent: IBranch;
begin
  Result := FParent;
end;

function TBranch.GetChildren: TArray<IBranch>;
begin
  Result := FChildren.ToArray;
end;

function TBranch.GetTransaction: ITransaction;
begin
  Result := FTransaction;
end;

procedure TBranch.AddChild(Child: IBranch);
begin
  FChildren.Add(Child);
end;

end.
