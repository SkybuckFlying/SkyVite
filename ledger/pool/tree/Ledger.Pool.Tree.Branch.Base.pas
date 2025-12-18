unit Ledger.Pool.Tree.Branch.Base;

interface

uses
  SysUtils, Classes,
  System.Generics.Collections,
  Ledger.Pool.Tree.Branch, // For IBranch
  Common.Types,
  Interfaces.Core;

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
