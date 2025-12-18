unit VM.ABI.Pack;

interface

uses
  GoVite.Types GoVite.Common.Helper,
  System.SysUtils System.BigInt,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.ABI.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Types,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

function PackBytesSlice(const ABytes: TBytes; ALen: Integer): TBytes;
function PackElement(const AType: TAbiType; const AValue: TValue): TBytes;
function PackNum(const AValue: TValue): TBytes;

implementation

uses
  System.Rtti;

function PackBytesSlice(const ABytes: TBytes; ALen: Integer): TBytes;
var
  LLenBytes: TBytes;
  LRightPaddedBytes: TBytes;
begin
  LLenBytes := PackNum(TValue.From<Integer>(ALen));
  LRightPaddedBytes := RightPadBytes(ABytes, (ALen + WordSize - 1) div WordSize * WordSize);
  Result := Concat(LLenBytes, LRightPaddedBytes);
end;

function PackElement(const AType: TAbiType; const AValue: TValue): TBytes;
begin
  case AType.T of
    TTypeEnum.IntTy, TTypeEnum.UintTy:
      Result := PackNum(AValue);
    TTypeEnum.StringTy:
      Result := PackBytesSlice(TEncoding.UTF8.GetBytes(AValue.AsString), AValue.ToString.Length);
    TTypeEnum.AddressTy:
      begin
        // Assuming TAddress can be represented as TBytes
        var LAddrBytes := AValue.AsType<TBytes>;
        Result := LeftPadBytes(LAddrBytes, WordSize);
      end;
    TTypeEnum.GidTy:
      begin
        var LGidBytes := AValue.AsType<TBytes>;
        Result := LeftPadBytes(LGidBytes, WordSize);
      end;
    TTypeEnum.TokenIdTy:
      begin
        var LTokenIdBytes := AValue.AsType<TBytes>;
        Result := LeftPadBytes(LTokenIdBytes, WordSize);
      end;
    TTypeEnum.BoolTy:
      if AValue.AsBoolean then
        Result := PaddedBigBytes(TBigInteger.One, WordSize)
      else
        Result := PaddedBigBytes(TBigInteger.Zero, WordSize);
    TTypeEnum.BytesTy:
      begin
        var LBytes := AValue.AsType<TBytes>;
        Result := PackBytesSlice(LBytes, Length(LBytes));
      end;
    TTypeEnum.FixedBytesTy:
       begin
        var LBytes := AValue.AsType<TBytes>;
        Result := RightPadBytes(LBytes, WordSize);
      end;
  else
    raise Exception.Create('pack failed');
  end;
end;

function PackNum(const AValue: TValue): TBytes;
var
  LBigInt: TBigInteger;
begin
  case AValue.Kind of
    tkUin, tkInteger:
      LBigInt := AValue.AsInteger;
    tkInt64:
      LBigInt := AValue.AsInt64;
  else
    if AValue.IsObject and (AValue.AsObject is TBigInteger) then
      LBigInt := TBigInteger(AValue.AsObject)
    else
      raise Exception.Create('pack failed');
  end;

  Result := U256(LBigInt);
end;

end.
