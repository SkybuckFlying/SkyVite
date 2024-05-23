unit unit_pow;

interface

{



This is a Go implementation of the proof-of-work (PoW) algorithm used in cryptocurrencies like Bitcoin and Ethereum. The PoW algorithm is designed to be computationally intensive, requiring significant processing power to solve the puzzle.

Here's a breakdown of the code:

1. `MapPowNonce` function: This function finds a nonce that satisfies the PoW condition, i.e., the hash of the block header (including the nonce) is less than or equal to a target value.
2. `powHash256` function: This function calculates the hash of the input data using the Blake2b hash algorithm.
3. `CheckPowNonce` function: This function checks whether a given nonce satisfies the PoW condition by comparing its hash with the target value.
4. `QuickInc` function: This function increments the nonce by 1, wrapping around to 0 when it reaches the maximum value.
5. `QuickGreater` function: This function compares two byte arrays and returns true i (``) they are not equal.
6. `Uint64ToByteArray` function: This function converts a uint64 value to a byte array.
7. `bigFloatToBigInt` function: This function converts a big float value to a big integer value.
8. `DifficultyToTarget` and `TargetToDifficulty` functions: These functions convert between the difficulty and target values used in the PoW algorithm.

The code also defines some constants:
1. `prec`: The precision of the floating-point operations, set to 64.
2. `floatTwo256`: A big float value representing 2^256.
3. `float1`: A big float value representing 1.

These functions are used together to find a nonce that satisfies the PoW condition. The process involves repeatedly incrementing the nonce and checking its hash against the target value until a valid nonce is found.




}



implementation

uses
  Math,
  SysUtils;

type
  TBigInt = record
    Value: Int64;
  end;

function PowHash256(Nonce, Data: array of Byte): array of Byte;
var
  Hash: TSHA256;
begin
  Hash := TSHA256.Create();
  try
    Hash.UpdateBytes(Nonce);
    Hash.UpdateBytes(Data);
    Result := Hash.Finalize();
  finally
    FreeAndNil(Hash);
  end;
end;

function CheckPowNonce(Difficulty, Nonce, Data: array of Byte): Boolean;
var
  Target: TBigInt;
begin
  if VMTestParamEnabled then
    Target.Value := defaultTarget.Value
  else
    Target.Value := DifficultyToTarget(Difficulty).Value;

  if Target.Value > 0 then
  begin
    Result := QuickGreater(PowHash256(Nonce, Data), PadBytes(Target.Bytes(), 32));
  end;
end;

function QuickInc(var X: array of Byte): array of Byte;
var
  I: Integer;
begin
  for I := High(X) downto Low(X) do
  begin
    Inc(X[I]);
    if X[I] <> 0 then
      Exit;
  end;

  Result := X;
end;

function QuickGreater(X, Y: array of Byte): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Y) do
  begin
    if X[I] > Y[I] then
      Exit(True)
    else if X[I] < Y[I] then
      Exit(False);
  end;

  Result := True;
end;

function Uint64ToByteArray(Value: UInt64): array of Byte;
begin
  SetLength(Result, SizeOf(UInt64));
  System.Move(Value, Result[0]);
end;

function BigFloatToBigInt(F: TBigFloat): TBigInt;
var
  B: TBigFloat;
begin
  B := F;
  Result.Value := B.AsInteger;
end;

function DifficultyToTarget(Difficulty: TBigInt): TBigInt;
var
  Ftmp, F1: TBigFloat;
begin
  Ftmp := TBigFloat.Create();
  try
    Ftmp.AsFloat := Difficulty.Value / 10.0;
    F1 := 1.0;

    Ftmp.Add(Ftmp, F1);
    Ftmp.Divide(2.0^256, Ftmp);

    Result.Value := Ftmp.AsInteger;
  finally
    FreeAndNil(Ftmp);
  end;
end;

function TargetToDifficulty(Target: TBigInt): TBigInt;
var
  Ftmp, F1: TBigFloat;
begin
  Ftmp := TBigFloat.Create();
  try
    Ftmp.AsFloat := Target.Value / (2.0^256 - 1.0);
    F1 := 1.0;

    Ftmp.Add(F1, Ftmp);
    Ftmp.Divide(2.0^256, Ftmp);

    Result.Value := Ftmp.AsInteger;
  finally
    FreeAndNil(Ftmp);
  end;
end;

var
  defaultTarget: TBigInt;

begin
  defaultTarget.Value := 10000000000; // Replace with your target value

  while true do
  begin
    Nonce := QuickInc(Nonce);
    if CheckPowNonce(defaultTarget, Nonce, Data) then
      Exit;
  end;
end.

