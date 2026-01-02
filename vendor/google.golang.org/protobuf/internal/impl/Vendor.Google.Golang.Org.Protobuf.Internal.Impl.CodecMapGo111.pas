unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecMapGo111;

interface

uses
  System.SysUtils, System.Rtti;

type
  TMapIter = class
  private
    FV: TValue;
    FKeys: TArray<TValue>;
    FIndex: Integer;
  public
    constructor Create(const V: TValue);
    function Next: Boolean;
    function Key: TValue;
    function Value: TValue;
  end;

function MapRange(const V: TValue): TMapIter;

implementation

constructor TMapIter.Create(const V: TValue);
begin
  FV := V;
  FIndex := -1;
end;

function TMapIter.Next: Boolean;
begin
  if FKeys = nil then
    FKeys := FV.AsMap.GetKeys;
  Inc(FIndex);
  Result := FIndex < Length(FKeys);
end;

function TMapIter.Key: TValue;
begin
  Result := FKeys[FIndex];
end;

function TMapIter.Value: TValue;
begin
  Result := FV.AsMap.GetValue(FKeys[FIndex]);
end;

function MapRange(const V: TValue): TMapIter;
begin
  Result := TMapIter.Create(V);
end;

end.
