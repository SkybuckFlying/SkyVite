unit hash_test;

interface

uses
  Crypto.Crypto,
  Crypto.Crypto.Test,
  Crypto.Hash,
  DUnitX.TestFramework;

type
  [TestFixture]
  THashTest = class(TObject)
  public
    [Test]
    procedure TestHash;
    [Benchmark]
    procedure BenchmarkHash256;
  end;

implementation

uses
  SysUtils, Classes, common.crypto, System.Net.Encodings, System.Diagnostics;

{ THashTest }

procedure THashTest.TestHash;
var
  data: string;
  hash0, hash1, a, b, h1, h2: TBytes;
begin
  data := '12343';
  hash0 := Hash(20, [TEncoding.UTF8.GetBytes(data)]);
  hash1 := Hash(32, [TEncoding.UTF8.GetBytes(data)]);
  WriteLn(TNetEncoding.Base16.EncodeBytesToString(hash0));
  WriteLn(TNetEncoding.Base16.EncodeBytesToString(hash1));

  a := [1, 2];
  b := [3, 4];
  h1 := Hash256([a, b]);
  h2 := Hash256([[1, 2, 3, 4]]);
  WriteLn(TNetEncoding.Base16.EncodeBytesToString(h1));
  WriteLn(TNetEncoding.Base16.EncodeBytesToString(h2));

  Assert.AreEqual<TBytes>(h1, h2);
end;

procedure THashTest.BenchmarkHash256;
var
  buf: TBytes;
  stopwatch: TStopwatch;
  i: Integer;
begin
  SetLength(buf, 4096);
  TEd25519.GetRandomBytes(buf);
  stopwatch := TStopwatch.StartNew;
  for i := 0 to 1000 do
  begin
    Hash256([buf]);
  end;
  stopwatch.Stop;
  WriteLn(Format('BenchmarkHash256: %d ms', [stopwatch.ElapsedMilliseconds]));
end;

initialization
  RegisterTestFixture(THashTest);
end.
