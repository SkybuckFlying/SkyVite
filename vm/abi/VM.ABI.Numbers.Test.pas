unit VM.ABI.Numbers.Test;

interface
uses
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.ABI.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

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
