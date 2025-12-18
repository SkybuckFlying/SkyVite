unit VM.ABI.Unpack.Test;

interface

procedure RunUnpackTests;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt, System.Rtti,
  GoVite.Types, GoVite.VM, VM.ABI.ABI, VM.ABI.Argument, // Assumed units
  DUnitX.TestFramework;

type
  TUnpackTestCase = record
    Def: string;
    Enc: string;
    Want: TValue;
    ErrMsg: string;
  end;

procedure TestUnpack;
var
  Tests: TArray<TUnpackTestCase>;
  Test: TUnpackTestCase;
  ABI: TAbiContract;
  Def, Enc: string;
  EncB: TBytes;
  OutPtr: TValue;
  Err: Exception;
  I: Integer;
begin
  Tests := [
    TUnpackTestCase.Create('[{"type":"bool"}]', '0000000000000000000000000000000000000000000000000000000000000001', TValue.From<Boolean>(True), ''),
    TUnpackTestCase.Create('[{"type":"bool"}]', '0000000000000000000000000000000000000000000000000000000000000000', TValue.From<Boolean>(False), ''),
    TUnpackTestCase.Create('[{"type":"bool"}]', '0000000000000000000000000000000000000000000000000000000000000003', TValue.From<Boolean>(False), 'abi: improperly encoded boolean value'),
    TUnpackTestCase.Create('[{"type":"uint32"}]', '0000000000000000000000000000000000000000000000000000000000000001', TValue.From<UInt32>(1), ''),
    TUnpackTestCase.Create('[{"type":"uint32"}]', '0000000000000000000000000000000000000000000000000000000000000001', TValue.From<UInt16>(0), 'abi: cannot unmarshal uint32 in to uint16'),
    TUnpackTestCase.Create('[{"type":"address"}]', '0000000000000000000000010000000000000000000000000000000000000000', TValue.From<TAddress>(TAddress.FromBytes(TBytes.Create($1))), ''),
    TUnpackTestCase.Create('[{"type":"bytes32"}]', '0100000000000000000000000000000000000000000000000000000000000000', TValue.From<TBytes32>(TBytes32.Create($1)), ''),
    TUnpackTestCase.Create('[{"type":"uint8[]"}]', '0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002', TValue.From<TArray<Byte>>([1, 2]), '')
  ];

  for I := 0 to High(Tests) do
  begin
    Test := Tests[I];
    Def := Format('[{ "name" : "event", "type" : "event", "inputs": %s}]', [Test.Def]);
    ABI := TAbiContract.Create(Def);
    try
      EncB := THex.Decode(Test.Enc);
      OutPtr := TValue.Make(Test.Want.TypeInfo, Test.Want);
      
      Err := nil;
      try
        ABI.UnpackEvent(OutPtr, 'event', EncB);
      except
        on E: Exception do Err := E;
      end;
      
      if Test.ErrMsg = '' then
        Assert.IsNull(Err, 'Test ' + I.ToString + ' should not fail')
      else
        Assert.AreEqual(Test.ErrMsg, Err.Message, 'Test ' + I.ToString + ' error message mismatch');

      if Test.ErrMsg = '' then
        Assert.AreEqual(Test.Want.ToString, OutPtr.ToString, 'Test ' + I.ToString + ' value mismatch');

    finally
      ABI.Free;
    end;
  end;
end;

procedure RunUnpackTests;
begin
  TestUnpack;
end;

end.
