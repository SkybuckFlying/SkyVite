unit VM.ABI.Numbers.Test;

interface

procedure RunNumbersTest;

implementation

uses
  System.SysUtils, System.BigInt,
  GoVite.VM, VM.ABI.Numbers, // Assumed units
  DUnitX.TestFramework;

procedure TestNumberTypes;
var
  ExpectedBytes: TBytes;
  Unsigned: TBytes;
  Value: TBigInteger;
begin
  // Create a 32-byte array with the last byte as 1
  SetLength(ExpectedBytes, 32);
  ExpectedBytes[31] := 1;

  // Call the U256 function
  Value := TBigInteger.One;
  Unsigned := U256(Value);

  // Assert that the result is as expected
  Assert.IsTrue(TBytes.Equals(ExpectedBytes, Unsigned), 'U256 padding failed');
end;

procedure RunNumbersTest;
begin
  TestNumberTypes;
end;

end.
