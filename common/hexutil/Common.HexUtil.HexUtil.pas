unit Common.HexUtil;

interface

uses
  System.SysUtils, GoToDelphi.Helpers.BigInt;

type
  EDecodeError = class(Exception);

var
  ErrEmptyString: EDecodeError;
  ErrSyntax: EDecodeError;
  ErrMissingPrefix: EDecodeError;
  ErrOddLength: EDecodeError;
  ErrEmptyNumber: EDecodeError;
  ErrLeadingZero: EDecodeError;
  ErrUint64Range: EDecodeError;
  ErrUintRange: EDecodeError;
  ErrBig256Range: EDecodeError;

type
  THexUtil = class
  public
    class function Decode(const ParaInput: string): TBytes;
    class function MustDecode(const ParaInput: string): TBytes;
    class function Encode(ParaB: TBytes): string;
    class function DecodeUint64(const ParaInput: string): UInt64;
    class function MustDecodeUint64(const ParaInput: string): UInt64;
    class function EncodeUint64(ParaI: UInt64): string;
    class function DecodeBig(const ParaInput: string): TBigInt;
    class function MustDecodeBig(const ParaInput: string): TBigInt;
    class function EncodeBig(ParaBigint: TBigInt): string;
  end;

implementation

uses
  System.StrUtils, System.Classes, System.Math, System.BigNumbers;

const
  ConstUintBits = 32 shl (UInt64(not System.UIntPtr(0)) shr 63);
  ConstBadNibble = High(UInt64);

var
  gBigWordNibbles: Integer;

function has0xPrefix(const ParaInput: string): Boolean;
begin
  Result := (Length(ParaInput) >= 2) and (ParaInput[1] = '0') and ((ParaInput[2] = 'x') or (ParaInput[2] = 'X'));
end;

function mapError(ParaErr: Exception): Exception;
begin
  if ParaErr is EConvertError then
  begin
    if Pos('range', ParaErr.Message) > 0 then
      Result := ErrUint64Range
    else
      Result := ErrSyntax;
  end
  else if Pos('invalid byte', ParaErr.Message) > 0 then
    Result := ErrSyntax
  else if Pos('odd length', ParaErr.Message) > 0 then
    Result := ErrOddLength
  else
    Result := ParaErr;
end;

function checkNumber(const ParaInput: string; out ParaRaw: string): Exception;
begin
  Result := nil;
  if Length(ParaInput) = 0 then
  begin
    Result := ErrEmptyString;
    Exit;
  end;
  if not has0xPrefix(ParaInput) then
  begin
    Result := ErrMissingPrefix;
    Exit;
  end;
  ParaRaw := Copy(ParaInput, 3, Length(ParaInput));
  if Length(ParaRaw) = 0 then
  begin
    Result := ErrEmptyNumber;
    Exit;
  end;
  if (Length(ParaRaw) > 1) and (ParaRaw[1] = '0') then
  begin
    Result := ErrLeadingZero;
    Exit;
  end;
end;

function decodeNibble(ParaInByte: Char): UInt64;
begin
  case ParaInByte of
    '0'..'9': Result := Ord(ParaInByte) - Ord('0');
    'A'..'F': Result := Ord(ParaInByte) - Ord('A') + 10;
    'a'..'f': Result := Ord(ParaInByte) - Ord('a') + 10;
  else
    Result := ConstBadNibble;
  end;
end;

{ THexUtil }

// Decode decodes a hex string with 0x prefix.
class function THexUtil.Decode(const ParaInput: string): TBytes;
var
  vErr: Exception;
  vHex: string;
  vLen: Integer;
begin
  if Length(ParaInput) = 0 then
  begin
    raise ErrEmptyString;
  end;
  if not has0xPrefix(ParaInput) then
  begin
    raise ErrMissingPrefix;
  end;
  vHex := Copy(ParaInput, 3, Length(ParaInput));
  vLen := Length(vHex) div 2;
  SetLength(Result, vLen);
  try
    HexToBin(PChar(vHex), Result, vLen);
  except
    on E: Exception do
    begin
      vErr := mapError(E);
      raise vErr;
    end;
  end;
end;

// MustDecode decodes a hex string with 0x prefix. It panics for invalid input.
class function THexUtil.MustDecode(const ParaInput: string): TBytes;
begin
  Result := Decode(ParaInput);
end;

// Encode encodes b as a hex string with 0x prefix.
class function THexUtil.Encode(ParaB: TBytes): string;
var
  vHex: AnsiString;
begin
  SetLength(vHex, Length(ParaB) * 2);
  BinToHex(ParaB, PAnsiChar(vHex), Length(ParaB));
  Result := '0x' + string(vHex);
end;

// DecodeUint64 decodes a hex string with 0x prefix as chain quantity.
class function THexUtil.DecodeUint64(const ParaInput: string): UInt64;
var
  vRaw: string;
  vErr: Exception;
begin
  vErr := checkNumber(ParaInput, vRaw);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  try
    Result := StrToInt64Def('$' + vRaw, -1);
  except
    on E: EConvertError do
    begin
      vErr := mapError(E);
      raise vErr;
    end;
  end;
end;

// MustDecodeUint64 decodes a hex string with 0x prefix as chain quantity.
// It panics for invalid input.
class function THexUtil.MustDecodeUint64(const ParaInput: string): UInt64;
begin
  Result := DecodeUint64(ParaInput);
end;

// EncodeUint64 encodes i as a hex string with 0x prefix.
class function THexUtil.EncodeUint64(ParaI: UInt64): string;
begin
  Result := '0x' + IntToHex(ParaI);
end;

// DecodeBig decodes a hex string with 0x prefix as chain quantity.
// Numbers larger than 256 bits are not accepted.
class function THexUtil.DecodeBig(const ParaInput: string): TBigInt;
var
  vRaw: string;
  vErr: Exception;
  vWords: TArray<TBigWord>;
  vWordIndex, vStart, vEnd, vRi: Integer;
  vNib: UInt64;
begin
  vErr := checkNumber(ParaInput, vRaw);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vRaw) > 64 then
  begin
    raise ErrBig256Range;
  end;

  SetLength(vWords, Length(vRaw) div gBigWordNibbles + 1);
  vEnd := Length(vRaw);
  for vWordIndex := 0 to High(vWords) do
  begin
    vStart := vEnd - gBigWordNibbles;
    if vStart < 0 then
    begin
      vStart := 0;
    end;
    for vRi := vStart to vEnd - 1 do
    begin
      vNib := decodeNibble(vRaw[vRi + 1]);
      if vNib = ConstBadNibble then
      begin
        raise ErrSyntax;
      end;
      vWords[vWordIndex] := vWords[vWordIndex] * 16;
      vWords[vWordIndex] := vWords[vWordIndex] + vNib;
    end;
    vEnd := vStart;
  end;
  Result := TBigInt.Create(vWords);
end;

// MustDecodeBig decodes a hex string with 0x prefix as chain quantity.
// It panics for invalid input.
class function THexUtil.MustDecodeBig(const ParaInput: string): TBigInt;
begin
  Result := DecodeBig(ParaInput);
end;

// EncodeBig encodes bigint as a hex string with 0x prefix.
// The sign of the integer is ignored.
class function THexUtil.EncodeBig(ParaBigint: TBigInt): string;
begin
  if ParaBigint.IsZero then
  begin
    Result := '0x0';
  end
  else
  begin
    Result := '0x' + ParaBigint.ToHexString;
  end;
end;

initialization
  ErrEmptyString := EDecodeError.Create('empty hex string');
  ErrSyntax := EDecodeError.Create('invalid hex string');
  ErrMissingPrefix := EDecodeError.Create('hex string without 0x prefix');
  ErrOddLength := EDecodeError.Create('hex string of odd length');
  ErrEmptyNumber := EDecodeError.Create('hex string "0x"');
  ErrLeadingZero := EDecodeError.Create('hex number with leading zero digits');
  ErrUint64Range := EDecodeError.Create('hex number > 64 bits');
  ErrUintRange := EDecodeError.Create(Format('hex number > %d bits', [ConstUintBits]));
  ErrBig256Range := EDecodeError.Create('hex number > 256 bits');

  if SizeOf(TBigWord) = 8 then
    gBigWordNibbles := 16
  else if SizeOf(TBigWord) = 4 then
    gBigWordNibbles := 8
  else
    raise Exception.Create('weird big.Word size');
finalization
  ErrEmptyString.Free;
  ErrSyntax.Free;
  ErrMissingPrefix.Free;
  ErrOddLength.Free;
  ErrEmptyNumber.Free;
  ErrLeadingZero.Free;
  ErrUint64Range.Free;
  ErrUintRange.Free;
  ErrBig256Range.Free;
end.