unit Ledger.Pool.Batch.Mock.Item;

interface

uses
  SysUtils, Classes,
  Common.Types,
  Interfaces.Core; // Assuming IBatchItem is defined here

type
  // Mock implementation of IBatchItem for testing
  TMockItem = class(TInterfacedObject, IBatchItem)
  private
    FHash: THash;
    // ... other mock properties
  public
    constructor Create(const AHash: THash);
    
    // Implement IBatchItem interface
    function GetHash: THash;
    // ... other interface methods
  end;

implementation

{ TMockItem }

constructor TMockItem.Create(const AHash: THash);
begin
  inherited Create;
  FHash := AHash;
end;

function TMockItem.GetHash: THash;
begin
  Result := FHash;
end;

// ... implementation of other IBatchItem methods

end.
