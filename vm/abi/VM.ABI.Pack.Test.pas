unit VM.ABI.Pack.Test;

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
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

procedure RunPackTests;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt, System.Rtti,
  GoVite.Types, GoVite.VM, VM.ABI.ABI, VM.ABI.Argument, VM.ABI.Type, // Assumed units
  DUnitX.TestFramework;

type
  TPackTestCase = record
    Typ: string;
    Input: TValue;
    Output: TBytes;
  end;

procedure TestPack;
var
  Tests: TArray<TPackTestCase>;
  Test: TPackTestCase;
  Typ: TAbiType;
  Packed: TBytes;
  I: Integer;
begin
  Tests := [
    TPackTestCase.Create('uint8', TValue.From<Byte>(2), THex.Decode('0000000000000000000000000000000000000000000000000000000000000002')),
    TPackTestCase.Create('uint256', TValue.From<TBigInteger>(2), THex.Decode('0000000000000000000000000000000000000000000000000000000000000002')),
    TPackTestCase.Create('bytes1', TValue.From<TBytes>(TBytes.Create($01)), THex.Decode('0100000000000000000000000000000000000000000000000000000000000000')),
    TPackTestCase.Create('string', TValue.From<string>('foobar'), THex.Decode('0000000000000000000000000000000000000000000000000000000000000020' + // offset
                                                                        '0000000000000000000000000000000000000000000000000000000000000006' + // length
                                                                        '666f6f6261720000000000000000000000000000000000000000000000000000')), // value
    TPackTestCase.Create('uint8[]', TValue.From<TArray<Byte>>([1, 2]), THex.Decode('0000000000000000000000000000000000000000000000000000000000000020' + // offset
                                                                            '0000000000000000000000000000000000000000000000000000000000000002' + // length
                                                                            '0000000000000000000000000000000000000000000000000000000000000001' + // value 1
                                                                            '0000000000000000000000000000000000000000000000000000000000000002')) // value 2
  ];

  for I := 0 to High(Tests) do
  begin
    Test := Tests[I];
    Typ := TAbiType.NewType(Test.Typ);
    Packed := Typ.Pack(Test.Input);

    Assert.AreEqual(THex.Encode(Test.Output), THex.Encode(Packed), Format('Test Case %d (%s) failed', [I, Test.Typ]));
  end;
end;

procedure TestMethodPack;
const
  JSON_DATA2 = '[{"type":"function","name":"slice","inputs":[{"name":"inputs","type":"uint32[2]"}]}]';
var
  ABI: TAbiContract;
  Packed, Expected: TBytes;
  Slice: TArray<UInt32>;
begin
  ABI := TAbiContract.Create(JSON_DATA2);
  try
    SetLength(Slice, 2);
    Slice[0] := 1;
    Slice[1] := 2;

    Packed := ABI.PackMethod('slice', [TValue.From<TArray<UInt32>>(Slice)]);

    Expected := ABI.Methods['slice'].ID;
    Expected := Expected + TArgument.PadBytes(TBytes.Create($01), 32);
    Expected := Expected + TArgument.PadBytes(TBytes.Create($02), 32);

    Assert.AreEqual(THex.Encode(Expected), THex.Encode(Packed), 'Method packing for "slice" failed');
  finally
    ABI.Free;
  end;
end;

procedure RunPackTests;
begin
  TestPack;
  TestMethodPack;
end;

end.
