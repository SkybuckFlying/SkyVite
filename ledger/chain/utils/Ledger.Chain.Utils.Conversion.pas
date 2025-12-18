unit Ledger.Chain.Utils.Conversion;

interface

uses
  Ledger.Chain.File.Manager,
  Ledger.Chain.Utils.Generate.Key,
  Ledger.Chain.Utils.Generate.Key.Test,
  Ledger.Chain.Utils.Key.Prefix,
  Ledger.Chain.Utils.Keys,
  Ledger.Chain.Utils.Keys.Index.DB,
  Ledger.Chain.Utils.Keys.State.DB,
  Ledger.Chain.Utils.Keys.State.Redo.DB,
  System.SysUtils;

function SerializeLocation(const aLocation: ILocation): TBytes;
function DeserializeLocation(const aBytes: TBytes): ILocation;
function Uint64ToBytes(const aHeight: UInt64): TBytes;
procedure Uint64Put(var aBytes: TBytes; const aHeight: UInt64);
function BytesToUint64(const aBytes: TBytes): UInt64;

implementation

uses
  System.Net.Sockets; // For HostToNetwork and NetworkToHost byte order conversions

function SerializeLocation(const aLocation: ILocation): TBytes;
var
  vFileIdBytes, vOffsetBytes: TBytes;
begin
  SetLength(Result, 12);
  // Delphi's TLocation might have FileId as UInt64 and Offset as Int64
  // We'll use HostToNetwork to ensure Big Endian byte order.
  PUInt64(@Result[0])^ := HToN(aLocation.FileId);
  PUInt32(@Result[8])^ := HToN(Cardinal(aLocation.Offset));
end;

function DeserializeLocation(const aBytes: TBytes): ILocation;
var
  vFileId: UInt64;
  vOffset: Int64;
begin
  if Length(aBytes) < 12 then
    raise Exception.Create('Invalid byte array length for location deserialization.');

  vFileId := NToH(PUInt64(@aBytes[0])^);
  vOffset := NToH(PUInt32(@aBytes[8])^);
  Result := TLocation.Create(vFileId, vOffset);
end;

function Uint64ToBytes(const aHeight: UInt64): TBytes;
begin
  SetLength(Result, 8);
  PUInt64(@Result[0])^ := HToN(aHeight);
end;

procedure Uint64Put(var aBytes: TBytes; const aHeight: UInt64);
begin
  if Length(aBytes) < 8 then
    SetLength(aBytes, 8);
  PUInt64(@aBytes[0])^ := HToN(aHeight);
end;

function BytesToUint64(const aBytes: TBytes): UInt64;
begin
  if Length(aBytes) < 8 then
    raise Exception.Create('Invalid byte array length for UInt64 conversion.');
  Result := NToH(PUInt64(@aBytes[0])^);
end;

end.
