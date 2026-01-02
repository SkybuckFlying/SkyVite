unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Enum;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  TEnumInfo = class(TInterfacedObject, IEnumType)
  private
    FGoReflectType: TRttiType;
    FDesc: IEnumDescriptor;
  public
    constructor Create(T: TRttiType; const D: IEnumDescriptor);
    function New_(N: TEnumNumber): IEnum;
    function Descriptor: IEnumDescriptor;
  end;

implementation

{ TEnumInfo }

constructor TEnumInfo.Create(T: TRttiType; const D: IEnumDescriptor);
begin
  FGoReflectType := T;
  FDesc := D;
end;

function TEnumInfo.New_(N: TEnumNumber): IEnum;
begin
  Result := TValue.From<TEnumNumber>(N).Cast(FGoReflectType.Handle).AsInterface as IEnum;
end;

function TEnumInfo.Descriptor: IEnumDescriptor;
begin
  Result := FDesc;
end;

end.
