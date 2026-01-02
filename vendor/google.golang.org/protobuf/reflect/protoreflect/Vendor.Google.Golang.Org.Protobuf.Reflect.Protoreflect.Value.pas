unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Value;

{$MODE DELPHIUNICODE}

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Proto;

function ValueOf(ParaV: TProtoValue): TProtoValue; // Helpers?
function ValueOfBool(ParaV: Boolean): TProtoValue;
function ValueOfInt32(ParaV: Int32): TProtoValue;
function ValueOfInt64(ParaV: Int64): TProtoValue;
function ValueOfUint32(ParaV: UInt32): TProtoValue;
function ValueOfUint64(ParaV: UInt64): TProtoValue;
function ValueOfFloat32(ParaV: Single): TProtoValue;
function ValueOfFloat64(ParaV: Double): TProtoValue;
function ValueOfString(const ParaV: string): TProtoValue;
function ValueOfBytes(const ParaV: TBytes): TProtoValue;
function ValueOfEnum(ParaV: TEnumNumber): TProtoValue;
function ValueOfMessage(ParaV: IMessage): TProtoValue;
function ValueOfList(ParaV: IList): TProtoValue;
function ValueOfMap(ParaV: IMap): TProtoValue;

implementation

function ValueOf(ParaV: TProtoValue): TProtoValue;
begin
  Result := ParaV;
end;

function ValueOfBool(ParaV: Boolean): TProtoValue;
begin
  Result := TProtoValue.OfBool(ParaV);
end;

function ValueOfInt32(ParaV: Int32): TProtoValue;
begin
  Result := TProtoValue.OfInt32(ParaV);
end;

function ValueOfInt64(ParaV: Int64): TProtoValue;
begin
  Result := TProtoValue.OfInt64(ParaV);
end;

function ValueOfUint32(ParaV: UInt32): TProtoValue;
begin
  Result.FType := pvtUint32;
  Result.FNum := ParaV;
end;

function ValueOfUint64(ParaV: UInt64): TProtoValue;
begin
  Result.FType := pvtUint64;
  Result.FNum := ParaV;
end;

function ValueOfFloat32(ParaV: Single): TProtoValue;
begin
  Result.FType := pvtFloat32;
  PDouble(@Result.FNum)^ := ParaV; // Simplistic cast
end;

function ValueOfFloat64(ParaV: Double): TProtoValue;
begin
  Result.FType := pvtFloat64;
  PDouble(@Result.FNum)^ := ParaV;
end;

function ValueOfString(const ParaV: string): TProtoValue;
begin
  Result.FType := pvtString;
  Result.FStr := ParaV;
end;

function ValueOfBytes(const ParaV: TBytes): TProtoValue;
begin
  Result.FType := pvtBytes;
  Result.FBytes := ParaV;
end;

function ValueOfEnum(ParaV: TEnumNumber): TProtoValue;
begin
  Result.FType := pvtEnum;
  Result.FNum := ParaV;
end;

function ValueOfMessage(ParaV: IMessage): TProtoValue;
begin
  Result.FType := pvtIface;
  Result.FIface := ParaV;
end;

function ValueOfList(ParaV: IList): TProtoValue;
begin
  Result.FType := pvtIface;
  Result.FIface := ParaV;
end;

function ValueOfMap(ParaV: IMap): TProtoValue;
begin
  Result.FType := pvtIface;
  Result.FIface := ParaV;
end;

end.
