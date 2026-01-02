unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.ConvertMap;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  TMapConverter = class(TInterfacedObject, IConverter)
  private
    FGoType: TRttiType;
    FKeyConv, FValConv: IConverter;
  public
    constructor Create(T: TRttiType; FD: IFieldDescriptor);
    function PBValueOf(V: TValue): TValue;
    function GoValueOf(V: TValue): TValue;
    function IsValidPB(V: TValue): Boolean;
    function IsValidGo(V: TValue): Boolean;
    function New_: TValue;
    function Zero: TValue;
  end;

implementation

type
  TMapReflect = class(TInterfacedObject, IMap, IUnwrapper)
  private
    FV: TValue; // TDictionary or similar
    FKeyConv, FValConv: IConverter;
  public
    constructor Create(const V: TValue; const KConv, VConv: IConverter);
    function Len: Integer;
    function Has(K: IMapKey): Boolean;
    function Get(K: IMapKey): TValue;
    procedure Set_(K: IMapKey; const V: TValue);
    procedure Clear(K: IMapKey);
    function Mutable(K: IMapKey): TValue;
    procedure Range(const F: TFunc<IMapKey, TValue, Boolean>);
    function NewValue: TValue;
    function IsValid: Boolean;
    function ProtoUnwrap: TValue;
  end;

{ TMapConverter }

constructor TMapConverter.Create(T: TRttiType; FD: IFieldDescriptor);
begin
  FGoType := T;
  FKeyConv := NewSingularConverter(T.AsMap.KeyType, FD.MapKey);
  FValConv := NewSingularConverter(T.AsMap.ValueType, FD.MapValue);
end;

function TMapConverter.PBValueOf(V: TValue): TValue;
begin
  Result := TValue.From<IMap>(TMapReflect.Create(V, FKeyConv, FValConv));
end;

function TMapConverter.GoValueOf(V: TValue): TValue;
begin
  Result := (V.AsInterface as TMapReflect).FV;
end;

function TMapConverter.IsValidPB(V: TValue): Boolean;
begin
  Result := V.IsType<IMap> and (V.AsInterface as TMapReflect).FV.RttiType = FGoType;
end;

function TMapConverter.IsValidGo(V: TValue): Boolean;
begin
  Result := V.IsValid and (V.RttiType = FGoType);
end;

function TMapConverter.New_: TValue;
begin
  Result := PBValueOf(TValue.From(FGoType.AsMap.CreateInstance));
end;

function TMapConverter.Zero: TValue;
begin
  Result := PBValueOf(TValue.Empty);
end;

{ TMapReflect }

constructor TMapReflect.Create(const V: TValue; const KConv, VConv: IConverter);
begin
  FV := V;
  FKeyConv := KConv;
  FValConv := VConv;
end;

function TMapReflect.Len: Integer;
begin
  Result := FV.AsMap.Len;
end;

function TMapReflect.Has(K: IMapKey): Boolean;
begin
  Result := FV.AsMap.Has(FKeyConv.GoValueOf(K.Value));
end;

function TMapReflect.Get(K: IMapKey): TValue;
var
  RV: TValue;
begin
  if FV.AsMap.TryGetValue(FKeyConv.GoValueOf(K.Value), RV) then
    Result := FValConv.PBValueOf(RV)
  else
    Result := TValue.Empty;
end;

procedure TMapReflect.Set_(K: IMapKey; const V: TValue);
begin
  FV.AsMap.Set_(FKeyConv.GoValueOf(K.Value), FValConv.GoValueOf(V));
end;

procedure TMapReflect.Clear(K: IMapKey);
begin
  FV.AsMap.Remove(FKeyConv.GoValueOf(K.Value));
end;

function TMapReflect.Mutable(K: IMapKey): TValue;
begin
  Result := Get(K);
  if not Result.IsValid then
  begin
    Result := NewValue;
    Set_(K, Result);
  end;
end;

procedure TMapReflect.Range(const F: TFunc<IMapKey, TValue, Boolean>);
begin
  // Implementation of map range
end;

function TMapReflect.NewValue: TValue;
begin
  Result := FValConv.New_;
end;

function TMapReflect.IsValid: Boolean;
begin
  Result := not FV.IsNil;
end;

function TMapReflect.ProtoUnwrap: TValue;
begin
  Result := FV;
end;

end.
