unit Common.Types.TokenTypeId;

interface

uses
  Common.HexUtil,
  Common.Json,
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID.Test,
  Crypto.Hash,
  GoToDelphi.Helpers.BigInt,
  System.Classes,
  System.Generics.Defaults,
  System.Net.Encoding,
  System.SysUtils;

const
  ConstTokenTypeIdPrefix = 'tti_';
  ConstTokenTypeIdSize = 10;
  ConstTokenTypeIdChecksumSize = 2;
  ConstTokenTypeIdPrefixLen = Length(ConstTokenTypeIdPrefix);
  ConstHexTokenTypeIdLength = ConstTokenTypeIdPrefixLen + 2 * ConstTokenTypeIdSize + 2 * ConstTokenTypeIdChecksumSize;

type
  TTokenTypeId = array[0..ConstTokenTypeIdSize - 1] of Byte;

  TTokenTypeIdHelper = record helper for TTokenTypeId
  public
    function SetBytes(const ParaBytes: TBytes): Boolean;
    function Hex: string;
    function Bytes: TBytes;
    function ToString: string;
    function UnmarshalJSON(const ParaInput: TBytes): Boolean;
    function MarshalText: TBytes;
    function UnmarshalText(const ParaInput: TBytes): Boolean;
  end;

var
  ConstZeroTokenId: TTokenTypeId;

function BytesToTokenTypeId(const ParaBytes: TBytes): TTokenTypeId;
function BigToTokenTypeId(const ParaBigInt: TBigInteger): TTokenTypeId;
function HexToTokenTypeId(const ParaHexStr: string): TTokenTypeId;
function IsValidHexTokenTypeId(const ParaHexStr: string): Boolean;
function CreateTokenTypeId(const ParaData: array of TBytes): TTokenTypeId;

implementation

function GetTokenTypeIdFromHex(const ParaHexStr: string; out ParaTokenTypeId: TTokenTypeId): Boolean;
var
  vBytes: TBytes;
begin
  Result := False;
  try
    vBytes := TNetEncoding.Base16.Decode(ParaHexStr.Substring(ConstTokenTypeIdPrefixLen, 2 * ConstTokenTypeIdSize));
    if Length(vBytes) = ConstTokenTypeIdSize then
    begin
      Move(vBytes[0], ParaTokenTypeId, ConstTokenTypeIdSize);
      Result := True;
    end;
  except
    on E: Exception do
    begin
      // Ignore exception, result is false
    end;
  end;
end;

function GetTtiChecksumFromHex(const ParaHexStr: string; out ParaChecksum: TBytes): Boolean;
begin
  Result := False;
  try
    SetLength(ParaChecksum, ConstTokenTypeIdChecksumSize);
    ParaChecksum := TNetEncoding.Base16.Decode(ParaHexStr.Substring(ConstTokenTypeIdPrefixLen + 2 * ConstTokenTypeIdSize));
    Result := Length(ParaChecksum) = ConstTokenTypeIdChecksumSize;
  except
    on E: Exception do
    begin
      // Ignore exception, result is false
    end;
  end;
end;

{ TTokenTypeIdHelper }

function TTokenTypeIdHelper.SetBytes(const ParaBytes: TBytes): Boolean;
begin
  Result := False;
  if Length(ParaBytes) <> ConstTokenTypeIdSize then
  begin
    Exit;
  end;
  Move(ParaBytes[0], Self, ConstTokenTypeIdSize);
  Result := True;
end;

function TTokenTypeIdHelper.Hex: string;
var
  vChecksum: TBytes;
begin
  vChecksum := THash.Hash(ConstTokenTypeIdChecksumSize, [Self.Bytes]);
  Result := ConstTokenTypeIdPrefix + TNetEncoding.Base16.Encode(Self.Bytes) + TNetEncoding.Base16.Encode(vChecksum);
end;

function TTokenTypeIdHelper.Bytes: TBytes;
begin
  SetLength(Result, ConstTokenTypeIdSize);
  Move(Self, Result[0], ConstTokenTypeIdSize);
end;

function TTokenTypeIdHelper.ToString: string;
begin
  Result := Self.Hex;
end;

function TTokenTypeIdHelper.UnmarshalJSON(const ParaInput: TBytes): Boolean;
var
  vTrimmedString: string;
  vTokenTypeId: TTokenTypeId;
begin
  Result := False;
  if not IsString(ParaInput) then
  begin
    Exit;
  end;
  vTrimmedString := TrimLeftRightQuotation(ParaInput);
  try
    vTokenTypeId := HexToTokenTypeId(vTrimmedString);
    Self.SetBytes(vTokenTypeId.Bytes);
    Result := True;
  except
    on E: Exception do
    begin
      // Conversion failed
    end;
  end;
end;

function TTokenTypeIdHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Self.ToString);
end;

function TTokenTypeIdHelper.UnmarshalText(const ParaInput: TBytes): Boolean;
begin
  // Re-use the JSON logic as it's identical
  Result := Self.UnmarshalJSON(ParaInput);
end;

function BytesToTokenTypeId(const ParaBytes: TBytes): TTokenTypeId;
begin
  if not Result.SetBytes(ParaBytes) then
  begin
    raise Exception.CreateFmt('error tokentypeid size error %d', [Length(ParaBytes)]);
  end;
end;

function BigToTokenTypeId(const ParaBigInt: TBigInteger): TTokenTypeId;
begin
  Result := BytesToTokenTypeId(TBigIntHelper.LeftPadBytes(ParaBigInt, ConstTokenTypeIdSize));
end;

function HexToTokenTypeId(const ParaHexStr: string): TTokenTypeId;
begin
  if not IsValidHexTokenTypeId(ParaHexStr) then
  begin
    raise Exception.Create('Not valid hex TokenTypeId');
  end;
  if not GetTokenTypeIdFromHex(ParaHexStr, Result) then
  begin
    // This should ideally not be reached if IsValidHexTokenTypeId passed
    raise Exception.Create('Failed to decode hex for TokenTypeId');
  end;
end;

function IsValidHexTokenTypeId(const ParaHexStr: string): Boolean;
var
  vTokenTypeId: TTokenTypeId;
  vChecksumFromHex: TBytes;
  vCalculatedChecksum: TBytes;
begin
  Result := False;
  if (Length(ParaHexStr) <> ConstHexTokenTypeIdLength) or (not ParaHexStr.StartsWith(ConstTokenTypeIdPrefix)) then
  begin
    Exit;
  end;

  if not GetTokenTypeIdFromHex(ParaHexStr, vTokenTypeId) then
  begin
    Exit;
  end;

  if not GetTtiChecksumFromHex(ParaHexStr, vChecksumFromHex) then
  begin
    Exit;
  end;

  vCalculatedChecksum := THash.Hash(ConstTokenTypeIdChecksumSize, [vTokenTypeId.Bytes]);

  Result := TEqualityComparer<TBytes>.Default.Equals(vCalculatedChecksum, vChecksumFromHex);
end;

function CreateTokenTypeId(const ParaData: array of TBytes): TTokenTypeId;
var
  vHashedBytes: TBytes;
begin
  vHashedBytes := THash.Hash(ConstTokenTypeIdSize, ParaData);
  Result := BytesToTokenTypeId(vHashedBytes);
end;

initialization
  FillChar(ConstZeroTokenId, SizeOf(TTokenTypeId), 0);
end.
