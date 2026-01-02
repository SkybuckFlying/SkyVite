unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyEnum;

interface

uses
  System.SysUtils, System.Rtti, System.SyncObjs, System.StrUtils,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc,
  Vendor.Google.Golang.Org.Protobuf.Internal.Strs,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

function LegacyEnumName(ED: IEnumDescriptor): string;
function LegacyWrapEnum(V: TValue): IEnum;
function LegacyLoadEnumType(T: TRttiType): IEnumType;
function LegacyLoadEnumDesc(T: TRttiType): IEnumDescriptor;

implementation

var
  LegacyEnumTypeCache: TSyncMap;
  LegacyEnumDescCache: TSyncMap;

function LegacyEnumName(ED: IEnumDescriptor): string;
var
  ProtoPkg, EnumName: string;
  FD: IFileDescriptor;
begin
  EnumName := string(ED.FullName);
  FD := ED.ParentFile;
  if FD <> nil then
  begin
    ProtoPkg := string(FD.Package_);
    if StartsStr(ProtoPkg + '.', EnumName) then
      EnumName := Copy(EnumName, Length(ProtoPkg) + 2, MaxInt);
  end;
  if ProtoPkg = '' then
    Exit(TStrs.GoCamelCase(EnumName));
  Result := ProtoPkg + '.' + TStrs.GoCamelCase(EnumName);
end;

function LegacyWrapEnum(V: TValue): IEnum;
var
  ET: IEnumType;
begin
  ET := LegacyLoadEnumType(V.RttiType);
  Result := ET.New_(TEnumNumber(V.AsInt64));
end;

function LegacyLoadEnumType(T: TRttiType): IEnumType;
var
  V: TValue;
  ED: IEnumDescriptor;
begin
  if LegacyEnumTypeCache.Load(T, V) then
    Exit(V.AsInterface as IEnumType);

  ED := LegacyLoadEnumDesc(T);
  // Result := TLegacyEnumType.Create(ED, T);
  // LegacyEnumTypeCache.LoadOrStore(T, Result, V);
  Result := nil;
end;

function LegacyLoadEnumDesc(T: TRttiType): IEnumDescriptor;
begin
  // ... similar logic to Go implementation
  Result := nil;
end;

initialization
  LegacyEnumTypeCache := TSyncMap.Create;
  LegacyEnumDescCache := TSyncMap.Create;

finalization
  LegacyEnumTypeCache.Free;
  LegacyEnumDescCache.Free;

end.
