unit Vendor.Google.Golang.Org.Protobuf.Proto.Wrappers;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils;

// Bool stores v in a new bool value and returns a pointer to it.
function Bool(ParaV: Boolean): PBoolean;

// Int32 stores v in a new int32 value and returns a pointer to it.
function Int32(ParaV: Integer): PInteger;

// Int64 stores v in a new int64 value and returns a pointer to it.
function Int64(ParaV: Int64): PInt64;

// Float32 stores v in a new float32 value and returns a pointer to it.
function Float32(ParaV: Single): PSingle;

// Float64 stores v in a new float64 value and returns a pointer to it.
function Float64(ParaV: Double): PDouble;

// Uint32 stores v in a new uint32 value and returns a pointer to it.
function Uint32(ParaV: Cardinal): PCardinal;

// Uint64 stores v in a new uint64 value and returns a pointer to it.
function Uint64(ParaV: UInt64): PUInt64;

// String stores v in a new string value and returns a pointer to it.
function String_(ParaV: string): PString;

implementation

function Bool(ParaV: Boolean): PBoolean;
begin
  New(Result);
  Result^ := ParaV;
end;

function Int32(ParaV: Integer): PInteger;
begin
  New(Result);
  Result^ := ParaV;
end;

function Int64(ParaV: Int64): PInt64;
begin
  New(Result);
  Result^ := ParaV;
end;

function Float32(ParaV: Single): PSingle;
begin
  New(Result);
  Result^ := ParaV;
end;

function Float64(ParaV: Double): PDouble;
begin
  New(Result);
  Result^ := ParaV;
end;

function Uint32(ParaV: Cardinal): PCardinal;
begin
  New(Result);
  Result^ := ParaV;
end;

function Uint64(ParaV: UInt64): PUInt64;
begin
  New(Result);
  Result^ := ParaV;
end;

function String_(ParaV: string): PString;
begin
  New(Result);
  Result^ := ParaV;
end;

end.
