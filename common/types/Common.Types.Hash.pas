unit Common.Types.Hash;

interface

uses
  System.SysUtils,
  System.Math.BigInts,
  Common.Bytes,
  Common.HexUtil,
  Crypto.Hash;

const
  ConstHashSize = 32;

type
  THash = array[0..ConstHashSize - 1] of Byte;

  THashHelper = record helper for THash
    procedure SetBytes(const ParaB: TBytes);
    function ToBytes: TBytes;
    function ToHex: string;
    function ToString: string;
    function ToBigInt: TBigInteger;
    function IsZero: Boolean;
    function Cmp(const ParaA: THash): Integer;
    procedure UnmarshalJSON(const ParaInput: TBytes);
    function MarshalText: TBytes;
  end;

var
  ZERO_HASH: THash;

function BytesToHash(const ParaB: TBytes): THash;
function HexToHash(const ParaHexStr: string): THash;
function HexToHashPanic(const ParaHexStr: string): THash;
function BigToHash(const ParaB: TBigInteger): THash;
function DataHash(const ParaData: TBytes): THash;
function DataListHash(const ParaData: array of TBytes): THash;

implementation

uses
  System.StrUtils,
  Common.Helper,
  Common.Types.Error,
  Common.Math.Big;

{ THashHelper }

procedure THashHelper.SetBytes(const ParaB: TBytes);
begin
  if Length(ParaB) <> ConstHashSize then
  begin
    raise Exception.CreateFmt('error hash size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Self[0], ConstHashSize);
end;

function THashHelper.ToBytes: TBytes;
begin
  SetLength(Result, ConstHashSize);
  Move(Self[0], Result[0], ConstHashSize);
end;

function THashHelper.ToHex: string;
begin
  Result := THexUtil.Encode(Self);
end;

function THashHelper.ToString: string;
begin
  Result := Self.ToHex;
end;

function THashHelper.ToBigInt: TBigInteger;
var
  vBytes: TBytes;
begin
  vBytes := Self.ToBytes;
  Result := TBigInteger.Create(vBytes);
end;

function THashHelper.IsZero: Boolean;
begin
  Result := CompareMem(@Self, @ZERO_HASH, ConstHashSize) = 0;
end;

function THashHelper.Cmp(const ParaA: THash): Integer;
begin
  Result := CompareMem(@Self, @ParaA, ConstHashSize);
end;

procedure THashHelper.UnmarshalJSON(const ParaInput: TBytes);
var
  vHash: THash;
  vTrimmed: TBytes;
  vHex: string;
begin
  if not isString(ParaInput) then
  begin
    raise EJsonError.Create(ConstErrJsonNotString);
  end;
  try
    vTrimmed := trimLeftRightQuotation(ParaInput);
    vHex := TEncoding.UTF8.GetString(vTrimmed);
    vHash := HexToHash(vHex);
    Self.SetBytes(vHash.ToBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to unmarshal Hash from JSON: ' + E.Message);
    end;
  end;
end;

function THashHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Self.ToString);
end;

{ Standalone Functions }

function BytesToHash(const ParaB: TBytes): THash;
begin
  if Length(ParaB) <> ConstHashSize then
  begin
    raise Exception.CreateFmt('error hash size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Result[0], ConstHashSize);
end;

function HexToHash(const ParaHexStr: string): THash;
var
  vBytes: TBytes;
begin
  if Length(ParaHexStr) <> 2 * ConstHashSize then
  begin
    raise Exception.CreateFmt('error hex hash size %d', [Length(ParaHexStr)]);
  end;
  try
    vBytes := THexUtil.Decode(ParaHexStr);
    Result := BytesToHash(vBytes);
  except
    on E: Exception do
    begin
      raise Exception.Create('Not valid hex hash: ' + E.Message);
    end;
  end;
end;

function HexToHashPanic(const ParaHexStr: string): THash;
begin
  try
    Result := HexToHash(ParaHexStr);
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
end;

function BigToHash(const ParaB: TBigInteger): THash;
var
  vBytes: TBytes;
begin
  vBytes := TBigMath.PaddedBigBytes(ParaB, ConstHashSize);
  Result := BytesToHash(vBytes);
end;

function DataHash(const ParaData: TBytes): THash;
var
  vHashed: TBytes;
begin
  vHashed := THash256.Hash(ParaData);
  Result := BytesToHash(vHashed);
end;

function DataListHash(const ParaData: array of TBytes): THash;
var
  vHashed: TBytes;
begin
  vHashed := THash256.Hash(ParaData);
  Result := BytesToHash(vHashed);
end;

initialization
  FillChar(ZERO_HASH, ConstHashSize, 0);
end.