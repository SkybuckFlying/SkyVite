unit Ledger.Pool.Tree.Mock.Root.Branch;

interface

uses
  SysUtils, Classes,
  Ledger.Pool.Tree.Branch, // For IBranch
  Common.Types,
  Interfaces.Core;

type
  // Mock implementation of a root branch for testing
  TMockRootBranch = class(TInterfacedObject, IBranch)
  private
    FTransaction: ITransaction;
    FChildren: TList<IBranch>;
    
    function GetParent: IBranch;
    function GetChildren: TArray<IBranch>;
    function GetTransaction: ITransaction;
    procedure AddChild(Child: IBranch);
    
  public
    constructor Create(RootTx: ITransaction);
    destructor Destroy; override;
  end;

implementation

{ TMockRootBranch }

constructor TMockRootBranch.Create(RootTx: ITransaction);
begin
  inherited Create;
  FTransaction := RootTx;
  FChildren := TList<IBranch>.Create;
end;

destructor TMockRootBranch.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TMockRootBranch.GetParent: IBranch;
begin
  Result := nil; // Root has no parent
end;

function TMockRootBranch.GetChildren: TArray<IBranch>;
begin
  Result := FChildren.ToArray;
end;

function TMockRootBranch.GetTransaction: ITransaction;
begin
  Result := FTransaction;
end;

procedure TMockRootBranch.AddChild(Child: IBranch);
begin
  FChildren.Add(Child);
end;

end.
