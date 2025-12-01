unit Common.HexUtil.JSON;

interface

uses
  System.SysUtils, System.Json, GoToDelphi.Helpers.BigInt, Common.HexUtil, System.Classes;

type
  Bytes = type TBytes;
  Big = type TBigInt;
  Uint64 = type System.UInt64;
  Uint = type System.UIntPtr;

  // Custom exception for JSON unmarshal errors
  EJsonUnmarshalType = class(Exception)
  public
    Value: string;
    Typ: TClass;
    constructor Create(AValue: string; ATyp: TClass);
  end;

  // Bytes marshals/unmarshals as a JSON string with 0x prefix.
  TBytesHelper = record helper for Bytes
    function MarshalText: TBytes;
    function UnmarshalJSON(input: TBytes): Exception;
    function UnmarshalText(input: TBytes): Exception;
    function ToString: string;
  end;

  // Big marshals/unmarshals as a JSON string with 0x prefix.
  TBigHelper = record helper for Big
    function MarshalText: TBytes;
    function UnmarshalJSON(input: TBytes): Exception;
    function UnmarshalText(input: TBytes): Exception;
    function ToInt: PBigInt;
    function ToString: string;
  end;

  // Uint64 marshals/unmarshals as a JSON string with 0x prefix.
  TUint64Helper = record helper for Uint64
    function MarshalText: TBytes;
    function UnmarshalJSON(input: TBytes): Exception;
    function UnmarshalText(input: TBytes): Exception;
    function ToString: string;
  end;

  // Uint marshals/unmarshals as a JSON string with 0x prefix.
  TUintHelper = record helper for Uint
    function MarshalText: TBytes;
    function UnmarshalJSON(input: TBytes): Exception;
    function UnmarshalText(input: TBytes): Exception;
    function ToString: string;
  end;

  TJsonHexUtil = class
  public
    class function UnmarshalFixedJSON(ParaTyp: TClass; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
    class function UnmarshalFixedText(ParaTypename: string; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
    class function UnmarshalFixedUnprefixedText(ParaTypename: string; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
  end;

implementation

uses
  System.Rtti, System.TypInfo, GoToDelphi.Helpers.BigInt;

{ EJsonUnmarshalType }

constructor EJsonUnmarshalType.Create(AValue: string; ATyp: TClass);
begin
  inherited CreateFmt('json: cannot unmarshal %s into Go value of type %s', [AValue, ATyp.ClassName]);
  Value := AValue;
  Typ := ATyp;
end;

function isString(ParaInput: TBytes): Boolean;
begin
  Result := (Length(ParaInput) >= 2) and (ParaInput[0] = Ord('"')) and (ParaInput[Length(ParaInput) - 1] = Ord('"'));
end;

function bytesHave0xPrefix(ParaInput: TBytes): Boolean;
begin
  Result := (Length(ParaInput) >= 2) and (ParaInput[0] = Ord('0')) and ((ParaInput[1] = Ord('x')) or (ParaInput[1] = Ord('X')));
end;

function checkText(ParaInput: TBytes; ParaWantPrefix: Boolean; out ParaOutput: TBytes): Exception;
begin
  Result := nil;
  if Length(ParaInput) = 0 then
  begin
    SetLength(ParaOutput, 0);
    Exit;
  end;
  if bytesHave0xPrefix(ParaInput) then
  begin
    SetLength(ParaOutput, Length(ParaInput) - 2);
    System.Move(ParaInput[2], ParaOutput[0], Length(ParaOutput));
  end
  else if ParaWantPrefix then
  begin
    Result := ErrMissingPrefix;
    Exit;
  end
  else
  begin
    ParaOutput := ParaInput;
  end;

  if Length(ParaOutput) mod 2 <> 0 then
  begin
    Result := ErrOddLength;
  end;
end;

function checkNumberText(ParaInput: TBytes; out ParaRaw: TBytes): Exception;
begin
  Result := nil;
  if Length(ParaInput) = 0 then
  begin
    SetLength(ParaRaw, 0);
    Exit;
  end;
  if not bytesHave0xPrefix(ParaInput) then
  begin
    Result := ErrMissingPrefix;
    Exit;
  end;
  SetLength(ParaRaw, Length(ParaInput) - 2);
  System.Move(ParaInput[2], ParaRaw[0], Length(ParaRaw));
  if Length(ParaRaw) = 0 then
  begin
    Result := ErrEmptyNumber;
    Exit;
  end;
  if (Length(ParaRaw) > 1) and (ParaRaw[0] = Ord('0')) then
  begin
    Result := ErrLeadingZero;
    Exit;
  end;
end;

function wrapTypeError(ParaErr: Exception; ParaTyp: TClass): Exception;
begin
  if ParaErr is EDecError then
  begin
    Result := EJsonUnmarshalType.Create(ParaErr.Message, ParaTyp);
  end
  else
  begin
    Result := ParaErr;
  end;
end;

function errNonString(ParaTyp: TClass): Exception;
begin
  Result := EJsonUnmarshalType.Create('non-string', ParaTyp);
end;

{ TBytesHelper }

function TBytesHelper.MarshalText: TBytes;
begin
  SetLength(Result, Length(Self) * 2 + 2);
  Result[0] := Ord('0');
  Result[1] := Ord('x');
  BinToHex(Self, PChar(Result) + 2, Length(Self));
end;

function TBytesHelper.UnmarshalJSON(input: TBytes): Exception;
begin
  if not isString(input) then
    Exit(errNonString(TBytes));
  Result := wrapTypeError(UnmarshalText(Copy(input, 1, Length(input) - 2)), TBytes);
end;

function TBytesHelper.UnmarshalText(input: TBytes): Exception;
var
  raw: TBytes;
  err: Exception;
begin
  err := checkText(input, true, raw);
  if err <> nil then
    Exit(err);
  SetLength(Self, Length(raw) div 2);
  try
    HexToBin(raw, Self[0], Length(Self));
    Result := nil;
  except
    on E: Exception do
      Result := E;
  end;
end;

function TBytesHelper.ToString: string;
begin
  Result := Encode(Self);
end;

{ TBigHelper }

function TBigHelper.MarshalText: TBytes;
begin
  Result := TEncoding.ASCII.GetBytes(EncodeBig(Self));
end;

function TBigHelper.UnmarshalJSON(input: TBytes): Exception;
begin
  if not isString(input) then
    Exit(errNonString(TBigInt));
  Result := wrapTypeError(UnmarshalText(Copy(input, 1, Length(input) - 2)), TBigInt);
end;

function TBigHelper.UnmarshalText(input: TBytes): Exception;
var
  raw: TBytes;
  err: Exception;
  dec: TBigInt;
begin
  err := checkNumberText(input, raw);
  if err <> nil then
    Exit(err);
  if Length(raw) > 64 then
    Exit(ErrBig256Range);
  dec := TBigInt.Create;
  dec.SetString(string(raw), 16);
  Self := dec;
  Result := nil;
end;

function TBigHelper.ToInt: PBigInt;
begin
  Result := @Self;
end;

function TBigHelper.ToString: string;
begin
  Result := EncodeBig(Self);
end;

{ TUint64Helper }

function TUint64Helper.MarshalText: TBytes;
var
  s: string;
begin
  s := '0x' + UInt64(Self).ToString(16);
  Result := TEncoding.ASCII.GetBytes(s);
end;

function TUint64Helper.UnmarshalJSON(input: TBytes): Exception;
begin
  if not isString(input) then
    Exit(errNonString(TValue.From<Uint64>(Self).TypeInfo.GetClass));
  Result := wrapTypeError(UnmarshalText(Copy(input, 1, Length(input) - 2)), TValue.From<Uint64>(Self).TypeInfo.GetClass);
end;

function TUint64Helper.UnmarshalText(input: TBytes): Exception;
var
  raw: TBytes;
  err: Exception;
  dec: UInt64;
  i: Integer;
  nib: UInt64;
begin
  err := checkNumberText(input, raw);
  if err <> nil then
    Exit(err);
  if Length(raw) > 16 then
    Exit(ErrUint64Range);
  dec := 0;
  for i := 0 to Length(raw) - 1 do
  begin
    nib := DecodeNibble(char(raw[i]));
    if nib = $FFFFFFFFFFFFFFFF then
      Exit(ErrSyntax);
    dec := dec * 16;
    dec := dec + nib;
  end;
  Self := dec;
  Result := nil;
end;

function TUint64Helper.ToString: string;
begin
  Result := EncodeUint64(Self);
end;

{ TUintHelper }

function TUintHelper.MarshalText: TBytes;
begin
  Result := TUint64Helper(Self).MarshalText;
end;

function TUintHelper.UnmarshalJSON(input: TBytes): Exception;
begin
  if not isString(input) then
    Exit(errNonString(TValue.From<Uint>(Self).TypeInfo.GetClass));
  Result := wrapTypeError(UnmarshalText(Copy(input, 1, Length(input) - 2)), TValue.From<Uint>(Self).TypeInfo.GetClass);
end;

function TUintHelper.UnmarshalText(input: TBytes): Exception;
var
  u64: Uint64;
  err: Exception;
begin
  err := TUint64Helper(u64).UnmarshalText(input);
  if (u64 > High(Uint)) or (err = ErrUint64Range) then
    Exit(ErrUintRange);
  if err <> nil then
    Exit(err);
  Self := Uint(u64);
  Result := nil;
end;

function TUintHelper.ToString: string;
begin
  Result := EncodeUint64(Self);
end;

{ TJsonHexUtil }

class function TJsonHexUtil.UnmarshalFixedJSON(ParaTyp: TClass; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
var
  vErr: Exception;
begin
  Result := nil;
  if not isString(ParaInput) then
  begin
    Result := errNonString(ParaTyp);
    Exit;
  end;
  vErr := UnmarshalFixedText(ParaTyp.ClassName, Copy(ParaInput, 1, Length(ParaInput) - 2), ParaOutBytes);
  Result := wrapTypeError(vErr, ParaTyp);
end;

class function TJsonHexUtil.UnmarshalFixedText(ParaTypename: string; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
var
  vRaw: TBytes;
  vErr: Exception;
  vIndex: Integer;
  vNibble: UInt64;
begin
  Result := nil;
  vErr := checkText(ParaInput, true, vRaw);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;
  if Length(vRaw) div 2 <> Length(ParaOutBytes) then
  begin
    Result := Exception.Create(Format('hex string has length %d, want %d for %s', [Length(vRaw), Length(ParaOutBytes) * 2, ParaTypename]));
    Exit;
  end;
  for vIndex := 0 to High(vRaw) do
  begin
    vNibble := THexUtil.DecodeNibble(Chr(vRaw[vIndex]));
    if vNibble = High(UInt64) then
    begin
      Result := ErrSyntax;
      Exit;
    end;
  end;
  HexToBin(vRaw, ParaOutBytes, Length(vRaw) div 2);
end;

class function TJsonHexUtil.UnmarshalFixedUnprefixedText(ParaTypename: string; ParaInput: TBytes; out ParaOutBytes: TBytes): Exception;
var
  vRaw: TBytes;
  vErr: Exception;
  vIndex: Integer;
  vNibble: UInt64;
begin
  Result := nil;
  vErr := checkText(ParaInput, false, vRaw);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;
  if Length(vRaw) div 2 <> Length(ParaOutBytes) then
  begin
    Result := Exception.Create(Format('hex string has length %d, want %d for %s', [Length(vRaw), Length(ParaOutBytes) * 2, ParaTypename]));
    Exit;
  end;
  for vIndex := 0 to High(vRaw) do
  begin
    vNibble := THexUtil.DecodeNibble(Chr(vRaw[vIndex]));
    if vNibble = High(UInt64) then
    begin
      Result := ErrSyntax;
      Exit;
    end;
  end;
  HexToBin(vRaw, ParaOutBytes, Length(vRaw) div 2);
end;

end.
