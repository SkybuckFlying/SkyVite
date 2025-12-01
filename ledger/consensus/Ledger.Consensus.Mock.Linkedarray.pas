unit consensus.mock_linked_array;

interface

uses
  System.SysUtils,
  System.Classes,
  Vite.Types,
  consensus.cdb,
  consensus.point_array;

type
  TMockLinkedArray = class(TInterfacedObject, ILinkedArray)
  public
    function GetByIndex(Index: UInt64): TPoint;
    function GetByIndexWithProof(Index: UInt64; const ProofHash: THash): TPoint;
    function Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
    function Time2Index(T: TDateTime): UInt64;
  end;

implementation

{ TMockLinkedArray }

function TMockLinkedArray.GetByIndex(Index: UInt64): TPoint;
begin
  // Mock implementation
  Result := nil;
end;

function TMockLinkedArray.GetByIndexWithProof(Index: UInt64; const ProofHash: THash): TPoint;
begin
  // Mock implementation
  Result := nil;
end;

function TMockLinkedArray.Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
begin
  // Mock implementation
  Result := TTuple<TDateTime, TDateTime>.Create(0, 0);
end;

function TMockLinkedArray.Time2Index(T: TDateTime): UInt64;
begin
  // Mock implementation
  Result := 0;
end;

end.
