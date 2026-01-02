unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Convert;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  IUnwrapper = interface
    ['{B9B8806A-4D3B-49A3-8C9B-7D9A588B8C6A}']
    function ProtoUnwrap: TValue;
  end;

  IConverter = interface
    ['{8A9C8D7E-6F5D-4E3D-BCBA-987654321098}']
    function PBValueOf(V: TValue): TValue;
    function GoValueOf(V: TValue): TValue;
    function IsValidPB(V: TValue): Boolean;
    function IsValidGo(V: TValue): Boolean;
    function New_: TValue;
    function Zero: TValue;
  end;

function NewConverter(T: TRttiType; FD: IFieldDescriptor): IConverter;

implementation

type
  TBoolConverter = class(TInterfacedObject, IConverter)
  private
    FGoType: TRttiType;
    FDef: TValue;
  public
    constructor Create(T: TRttiType; const Def: TValue);
    function PBValueOf(V: TValue): TValue;
    function GoValueOf(V: TValue): TValue;
    function IsValidPB(V: TValue): Boolean;
    function IsValidGo(V: TValue): Boolean;
    function New_: TValue;
    function Zero: TValue;
  end;

{ TBoolConverter }

constructor TBoolConverter.Create(T: TRttiType; const Def: TValue);
begin
  FGoType := T;
  FDef := Def;
end;

function TBoolConverter.PBValueOf(V: TValue): TValue;
begin
  if V.RttiType <> FGoType then
    raise Exception.CreateFmt('invalid type: got %s, want %s', [V.RttiType.Name, FGoType.Name]);
  Result := TValue.From<Boolean>(V.AsBoolean);
end;

function TBoolConverter.GoValueOf(V: TValue): TValue;
begin
  Result := TValue.From<Boolean>(V.AsBoolean).Cast(FGoType.Handle);
end;

function TBoolConverter.IsValidPB(V: TValue): Boolean;
begin
  Result := V.IsType<Boolean>;
end;

function TBoolConverter.IsValidGo(V: TValue): Boolean;
begin
  Result := V.IsValid and (V.RttiType = FGoType);
end;

function TBoolConverter.New_: TValue; begin Result := FDef; end;
function TBoolConverter.Zero: TValue; begin Result := FDef; end;

function NewConverter(T: TRttiType; FD: IFieldDescriptor): IConverter;
begin
  if FD.IsList then
    Exit(NewListConverter(T, FD));
  if FD.IsMap then
    Exit(NewMapConverter(T, FD));
  Result := NewSingularConverter(T, FD);
end;

// ... other converters would be implemented here

end.
