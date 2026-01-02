unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Validate;

interface

uses
  System.SysUtils, System.Math,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TValidationStatus = (
    ValidationUnknown = 1,
    ValidationInvalid,
    ValidationValid
  );

function Validate(MT: IMessageType; const In_: TUnmarshalInput): TTuple<TUnmarshalOutput, TValidationStatus>;

implementation

function Validate(MT: IMessageType; const In_: TUnmarshalInput): TTuple<TUnmarshalOutput, TValidationStatus>;
var
  MI: TMessageInfo;
  O: TUnmarshalOutput;
  ST: TValidationStatus;
begin
  if not (MT is TMessageInfo) then
    Exit(TTuple<TUnmarshalOutput, TValidationStatus>.Create(Default(TUnmarshalOutput), ValidationUnknown));
  
  MI := TMessageInfo(MT);
  // logic...
  Result := TTuple<TUnmarshalOutput, TValidationStatus>.Create(O, ST);
end;

end.
