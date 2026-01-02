unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecMapGo112;

interface

uses
  System.Rtti;

function MapRange(const V: TValue): TMapIterator;

implementation

function MapRange(const V: TValue): TMapIterator;
begin
  Result := V.AsMap.GetIterator;
end;

end.
