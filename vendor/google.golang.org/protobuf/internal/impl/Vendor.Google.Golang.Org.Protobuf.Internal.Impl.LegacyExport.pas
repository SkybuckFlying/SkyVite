unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyExport;

interface

uses
  System.SysUtils, System.Rtti, System.JSON,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TExportHelper = class helper for TExport
  public
    function LegacyEnumName(ED: IEnumDescriptor): string;
    function LegacyMessageTypeOf(M: IMessageV1; Name: TFullName): IMessageType;
    function UnmarshalJSONEnum(ED: IEnumDescriptor; B: TBytes): TTuple<TEnumNumber, Error>;
    function CompressGZIP(In_: TBytes): TBytes;
  end;

implementation

{ TExportHelper }

function TExportHelper.LegacyEnumName(ED: IEnumDescriptor): string;
begin
  Result := Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyEnum.LegacyEnumName(ED);
end;

function TExportHelper.LegacyMessageTypeOf(M: IMessageV1; Name: TFullName): IMessageType;
var
  MV: IMessage;
begin
  MV := Self.ProtoMessageV2Of(M);
  if MV <> nil then
    Exit(MV.ProtoReflect.Type_);
  Result := LegacyLoadMessageType(TRttiType.TypeOf(M), Name);
end;

function TExportHelper.UnmarshalJSONEnum(ED: IEnumDescriptor; B: TBytes): TTuple<TEnumNumber, Error>;
var
  S: string;
  Name: TName;
  EV: IEnumValueDescriptor;
  Num: TEnumNumber;
begin
  if (Length(B) > 0) and (B[0] = ord('"')) then
  begin
    S := TEncoding.UTF8.GetString(B);
    // Simplified JSON unmarshal
    Name := TName(S.Trim(['"']));
    EV := ED.Values.ByName(Name);
    if EV = nil then
      Exit(TTuple<TEnumNumber, Error>.Create(0, TErrors.New('invalid value for enum %s: %s', [ED.FullName, Name])));
    Result := TTuple<TEnumNumber, Error>.Create(EV.Number, nil);
  end
  else
  begin
    S := TEncoding.UTF8.GetString(B);
    Num := TEnumNumber(StrToInt64(S));
    Result := TTuple<TEnumNumber, Error>.Create(Num, nil);
  end;
end;

function TExportHelper.CompressGZIP(In_: TBytes): TBytes;
begin
  // Placeholder implementation as per Go code (no compression)
  Result := In_;
end;

end.
