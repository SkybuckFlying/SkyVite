unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyMessage;

interface

uses
  System.SysUtils, System.Rtti, System.SyncObjs, System.StrUtils,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

function LegacyWrapMessage(V: TValue): IMessage;
function LegacyLoadMessageType(T: TRttiType; Name: TFullName): IMessageType;
function LegacyLoadMessageInfo(T: TRttiType; Name: TFullName): TMessageInfo;
function LegacyLoadMessageDesc(T: TRttiType; Name: TFullName): IMessageDescriptor;

implementation

var
  LegacyMessageTypeCache: TSyncMap;
  LegacyMessageDescCache: TSyncMap;

function LegacyWrapMessage(V: TValue): IMessage;
var
  T: TRttiType;
  MI: TMessageInfo;
begin
  T := V.RttiType;
  if (T.Kind <> tkPointer) or (T.AsInstance.MetaclassType.ClassNameIs('TStruct') = False) then // Simplified
  begin
    // return aberrantMessage
    Exit(nil);
  end;
  MI := LegacyLoadMessageInfo(T, '');
  Result := MI.MessageOf(V);
end;

function LegacyLoadMessageType(T: TRttiType; Name: TFullName): IMessageType;
begin
  Result := LegacyLoadMessageInfo(T, Name);
end;

function LegacyLoadMessageInfo(T: TRttiType; Name: TFullName): TMessageInfo;
var
  V: TValue;
begin
  if LegacyMessageTypeCache.Load(T, V) then
    Exit(V.AsObject as TMessageInfo);

  Result := TMessageInfo.Create;
  Result.Desc := LegacyLoadMessageDesc(T, Name);
  Result.GoReflectType := T;

  // Marshaler/Unmarshaler detection logic...

  LegacyMessageTypeCache.LoadOrStore(T, Result, V);
end;

function LegacyLoadMessageDesc(T: TRttiType; Name: TFullName): IMessageDescriptor;
begin
  // ... implementation of LegacyLoadMessageDesc
  Result := nil;
end;

initialization
  LegacyMessageTypeCache := TSyncMap.Create;
  LegacyMessageDescCache := TSyncMap.Create;

finalization
  LegacyMessageTypeCache.Free;
  LegacyMessageDescCache.Free;

end.
