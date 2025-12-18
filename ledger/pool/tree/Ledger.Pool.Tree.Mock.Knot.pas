unit Ledger.Pool.Tree.Mock.Knot;

interface

uses
  SysUtils, Classes,
  Common.Types,
  Interfaces.Core; // Assuming IKnot is defined here

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
