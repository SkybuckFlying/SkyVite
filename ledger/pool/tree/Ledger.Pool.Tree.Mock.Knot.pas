unit Ledger.Pool.Tree.Mock.Knot;

interface

uses
  Common.Types,
  Interfaces.Core // Assuming IKnot is defined here,
  Ledger.Pool.Tree.Branch,
  Ledger.Pool.Tree.Branch.Base,
  Ledger.Pool.Tree.Branch.Test,
  Ledger.Pool.Tree.Checker,
  Ledger.Pool.Tree.Mock.Root.Branch,
  Ledger.Pool.Tree.Printer,
  Ledger.Pool.Tree.Tree,
  Ledger.Pool.Tree.Tree.Impl,
  Ledger.Pool.Tree.Tree.Impl.Test,
  SysUtils Classes;

type
  // Mock implementation of IKnot for testing the tree structure
  TMockKnot = class(TInterfacedObject, IKnot)
  private
    FHash: THash;
    FParentHash: THash;
  public
    constructor Create(const AHash, AParentHash: THash);
    
    // Implement IKnot interface
    function GetHash: THash;
    function GetParentHash: THash;
  end;

implementation

{ TMockKnot }

constructor TMockKnot.Create(const AHash, AParentHash: THash);
begin
  inherited Create;
  FHash := AHash;
  FParentHash := AParentHash;
end;

function TMockKnot.GetHash: THash;
begin
  Result := FHash;
end;

function TMockKnot.GetParentHash: THash;
begin
  Result := FParentHash;
end;

end.
