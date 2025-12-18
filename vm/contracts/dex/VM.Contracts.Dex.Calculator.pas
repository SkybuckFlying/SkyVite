unit Vm.Contracts.Dex.DexCalculator;

interface

uses
  Common.Helper Vm.Contracts.Dex.DexErrors,
  System.SysUtils System.Classes,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

function AddBigInt(A, B: TBytes): TBytes;
function SubBigIntAbs(A, B: TBytes): TBytes;
function SafeSubBigInt(Amt, Sub: TBytes): TTuple<TBytes, TBytes, Boolean>;
function SubBigInt(A, B: TBytes): TBigInteger;
function MinBigInt(A, B: TBytes): TBytes;
function CmpToBigZero(A: TBytes): Integer;
function CmpForBigInt(A, B: TBytes): Integer;
function GetAbs(V: Int32): TPair<Int32, Int32>;
function AdjustForDecimalsDiff(SourceAmountF: TBigFloat; DecimalsDiff: Int32): TBigFloat;
function AdjustAmountForDecimalsDiff(Amount: TBytes; DecimalsDiff: Int32): TBigInteger;
function NormalizeToQuoteTokenTypeAmount(Amount: TBytes; TokenDecimals, QuoteTokenType: Int32): TBytes;
function RoundAmount(AmountF: TBigFloat): TBigInteger;
function RoundQuantity(QuantityF: TBigFloat): TBigInteger;
function FloorQuantity(QuantityF: TBigFloat): TBigInteger;
function NegativeAmount(Amount: TBytes): TBigInteger;

implementation

uses
  System.Math;

const
  BigFloatPrec = 256;

function AddBigInt(A, B: TBytes): TBytes;
begin
  Result := TBigInteger.Add(TBigInteger.FromByteArray(A), TBigInteger.FromByteArray(B)).ToByteArray;
end;

function SubBigIntAbs(A, B: TBytes): TBytes;
begin
  Result := TBigInteger.Subtract(TBigInteger.FromByteArray(A), TBigInteger.FromByteArray(B)).ToByteArray;
end;

function SafeSubBigInt(Amt, Sub: TBytes): TTuple<TBytes, TBytes, Boolean>;
var
  Res, ActualSub: TBytes;
  Exceed: Boolean;
begin
  if CmpForBigInt(Sub, Amt) > 0 then
  begin
    Res := nil;
    ActualSub := Amt;
    Exceed := True;
  end
  else
  begin
    Res := SubBigIntAbs(Amt, Sub);
    ActualSub := Sub;
    Exceed := False;
  end;
  Result := TTuple<TBytes, TBytes, Boolean>.Create(Res, ActualSub, Exceed);
end;

function SubBigInt(A, B: TBytes): TBigInteger;
begin
  Result := TBigInteger.Subtract(TBigInteger.FromByteArray(A), TBigInteger.FromByteArray(B));
end;

function MinBigInt(A, B: TBytes): TBytes;
begin
  if TBigInteger.FromByteArray(A).Compare(TBigInteger.FromByteArray(B)) > 0 then
    Result := B
  else
    Result := A;
end;

function CmpToBigZero(A: TBytes): Integer;
begin
  Result := TBigInteger.FromByteArray(A).Sign;
end;

function CmpForBigInt(A, B: TBytes): Integer;
begin
  if (Length(A) = 0) and (Length(B) = 0) then
    Result := 0
  else if Length(A) = 0 then
    Result := -1
  else if Length(B) = 0 then
    Result := 1
  else
    Result := TBigInteger.FromByteArray(A).Compare(TBigInteger.FromByteArray(B));
end;

function GetAbs(V: Int32): TPair<Int32, Int32>;
begin
  if V < 0 then
    Result := TPair<Int32, Int32>.Create(-V, -1)
  else
    Result := TPair<Int32, Int32>.Create(V, 1);
end;

function AdjustForDecimalsDiff(SourceAmountF: TBigFloat; DecimalsDiff: Int32): TBigFloat;
var
  DcDiffAbs, DcDiffSign: Int32;
  DecimalDiffInt: TBigInteger;
  DecimalDiffFloat: TBigFloat;
begin
  if DecimalsDiff = 0 then
  begin
    Result := SourceAmountF;
    Exit;
  end;

  DcDiffAbs := GetAbs(DecimalsDiff).Item1;
  DcDiffSign := GetAbs(DecimalsDiff).Item2;

  DecimalDiffInt := TBigInteger.Power(TBigInteger.Create(10), DcDiffAbs);
  DecimalDiffFloat := TBigFloat.Create(BigFloatPrec).SetInt(DecimalDiffInt);

  if DcDiffSign > 0 then
    Result := SourceAmountF.Divide(DecimalDiffFloat)
  else
    Result := SourceAmountF.Multiply(DecimalDiffFloat);
end;

function AdjustAmountForDecimalsDiff(Amount: TBytes; DecimalsDiff: Int32): TBigInteger;
begin
  Result := RoundAmount(AdjustForDecimalsDiff(TBigFloat.Create(BigFloatPrec).SetInt(TBigInteger.FromByteArray(Amount)), DecimalsDiff));
end;

function NormalizeToQuoteTokenTypeAmount(Amount: TBytes; TokenDecimals, QuoteTokenType: Int32): TBytes;
var
  Info: TDexQuoteTokenTypeInfo;
  Ok: Boolean;
begin
  if (Length(Amount) = 0) or (CmpToBigZero(Amount) = 0) then
  begin
    Result := nil;
    Exit;
  end;

  Info := QuoteTokenTypeInfos.Items[QuoteTokenType];
  Ok := QuoteTokenTypeInfos.ContainsKey(QuoteTokenType);
  if not Ok then
    raise EDexInvalidQuoteTokenType.Create('invalid quote token type');

  Result := AdjustAmountForDecimalsDiff(Amount, TokenDecimals - Info.Decimals).ToByteArray;
end;

function RoundAmount(AmountF: TBigFloat): TBigInteger;
begin
  Result := TBigInteger.Create(Round(AmountF.ToExtended));
end;

function RoundQuantity(QuantityF: TBigFloat): TBigInteger;
begin
  Result := TBigInteger.Create(Round(QuantityF.ToExtended));
end;

function FloorQuantity(QuantityF: TBigFloat): TBigInteger;
begin
  Result := TBigInteger.Create(Floor(QuantityF.ToExtended));
end;

function NegativeAmount(Amount: TBytes): TBigInteger;
begin
  Result := TBigInteger.Negate(TBigInteger.FromByteArray(Amount));
end;

end.
