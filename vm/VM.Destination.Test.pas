unit destination_test;

interface

uses
  DUnitX.TestFramework,
  System.Math.BigInteger,
  System.NetEncoding,
  SysUtils,
  Vite.Common.Types,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  Vm.Destination,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Mock.DB,
  Vm.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TCodeAnalysisTestCase = record
    Code: TBytes;
    Result: TBytes;
  end;

  THasTestCase = record
    Code: TBytes;
    Dest: TBigInteger;
    Result: Boolean;
  end;

  TGetCodeWithoutAuxCodeAndParamsTestCase = record
    Name: string;
    Code: string;
    ResultCode: string;
  end;

  TContainsCertainStatusCodeTestCase = record
    Name: string;
    Code: string;
    Snapshot: Boolean;
    SnapshotWithSeed: Boolean;
  end;

  [TestFixture]
  TTestDestination = class
  public
    [Test]
    procedure TestCodeAnalysis;
    [Test]
    procedure TestHas;
    [Test]
    procedure TestContainsAuxCode;
    [Test]
    procedure TestContainsStatusCode2;
    [Test]
    procedure TestGetCodeWithoutAuxCodeAndParams;
    [Test]
    procedure TestContainsCertainStatusCode;
  end;

implementation

procedure TTestDestination.TestCodeAnalysis;
var
  Tests: TArray<TCodeAnalysisTestCase>;
  Test: TCodeAnalysisTestCase;
  Ret: TBytes;
begin
  SetLength(Tests, 18);
  Tests[0] := TCodeAnalysisTestCase.Create([Byte(PUSH1), $01, $01, $01], [$40, $00, $00, $00, $00]);
  Tests[1] := TCodeAnalysisTestCase.Create([Byte(PUSH1), Byte(PUSH1), Byte(PUSH1), Byte(PUSH1)], [$50, $00, $00, $00, $00]);
  Tests[2] := TCodeAnalysisTestCase.Create([Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), Byte(PUSH8), $01, $01, $01], [$7f, $80, $00, $00, $00, $00]);
  Tests[3] := TCodeAnalysisTestCase.Create([Byte(PUSH8), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$7f, $80, $00, $00, $00, $00]);
  Tests[4] := TCodeAnalysisTestCase.Create([$01, $01, $01, $01, $01, Byte(PUSH2), Byte(PUSH2), Byte(PUSH2), $01, $01, $01], [$03, $00, $00, $00, $00, $00]);
  Tests[5] := TCodeAnalysisTestCase.Create([$01, $01, $01, $01, $01, Byte(PUSH2), $01, $01, $01, $01, $01], [$03, $00, $00, $00, $00, $00]);
  Tests[6] := TCodeAnalysisTestCase.Create([Byte(PUSH3), $01, $01, $01, Byte(PUSH1), $01, $01, $01, $01, $01, $01], [$74, $00, $00, $00, $00, $00]);
  Tests[7] := TCodeAnalysisTestCase.Create([Byte(PUSH3), $01, $01, $01, Byte(PUSH1), $01, $01, $01, $01, $01, $01], [$74, $00, $00, $00, $00, $00]);
  Tests[8] := TCodeAnalysisTestCase.Create([$01, Byte(PUSH8), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$3f, $c0, $00, $00, $00, $00]);
  Tests[9] := TCodeAnalysisTestCase.Create([$01, Byte(PUSH8), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$3f, $c0, $00, $00, $00, $00]);
  Tests[10] := TCodeAnalysisTestCase.Create([Byte(PUSH16), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$7f, $ff, $80, $00, $00, $00]);
  Tests[11] := TCodeAnalysisTestCase.Create([Byte(PUSH16), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$7f, $ff, $80, $00, $00, $00]);
  Tests[12] := TCodeAnalysisTestCase.Create([Byte(PUSH16), $01, $01, $01, $01, $01, $01, $01, $01, $01, $01], [$7f, $ff, $80, $00, $00, $00]);
  Tests[13] := TCodeAnalysisTestCase.Create([Byte(PUSH8), $01, $02, $03, $04, $05, $06, $07, $08, Byte(PUSH1), $01], [$7f, $a0, $00, $00, $00, $00]);
  Tests[14] := TCodeAnalysisTestCase.Create([Byte(PUSH8), $01, $02, $03, $04, $05, $06, $07, $08, Byte(PUSH1), $01], [$7f, $a0, $00, $00, $00, $00]);
  Tests[15] := TCodeAnalysisTestCase.Create([Byte(PUSH32)], [$7f, $ff, $ff, $ff, $80]);
  Tests[16] := TCodeAnalysisTestCase.Create([Byte(PUSH32)], [$7f, $ff, $ff, $ff, $80]);
  Tests[17] := TCodeAnalysisTestCase.Create([Byte(PUSH32)], [$7f, $ff, $ff, $ff, $80]);

  for Test in Tests do
  begin
    Ret := CodeBitmap(Test.Code);
    Assert.AreEqual(Test.Result, Ret, 'analysis fail');
  end;
end;

procedure TTestDestination.TestHas;
var
  Tests: TArray<THasTestCase>;
  Test: THasTestCase;
  D: TDestinations;
  Result: Boolean;
begin
  SetLength(Tests, 4);
  Tests[0] := THasTestCase.Create([Byte(PUSH1), Byte(JUMPDEST)], TBigInteger.Create(1), False);
  Tests[1] := THasTestCase.Create([Byte(PUSH1), 0, Byte(JUMPDEST)], TBigInteger.Create(2), True);
  Tests[2] := THasTestCase.Create([Byte(PUSH1), 0, Byte(JUMPDEST)], TBigInteger.Create(1), False);
  Tests[3] := THasTestCase.Create([Byte(PUSH32), 0, Byte(JUMPDEST)], TBigInteger.Create(2), False);

  for Test in Tests do
  begin
    D := TDestinations.Create;
    try
      Result := D.Has(TAddress.Empty, Test.Code, Test.Dest);
      Assert.AreEqual(Test.Result, Result, 'analysis result error');
    finally
      D.Free;
    end;
  end;
end;

procedure TTestDestination.TestContainsAuxCode;
var
  Code: string;
  CodeB: TBytes;
begin
  Code := '608060405260043610604c576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680632d16c91a146052578063ba3d93d614609f57604c565b60006000fd5b348015605e5760006000fd5b5060896004803603602081101560745760006000fd5b810190808035906020019092919050505060c8565b6040518082815260200191505060405180910390f35b34801560ab5760006000fd5b5060b260dd565b6040518082815260200191505060405180910390f35b60008160006000505401905060d8565b919050565b6000600060005054905060eb565b9056fea165627a7a72305820614b83ac7ad21936973699f9740d3cdc61d467686393dccfdda77dc053f21b7c0029';
  CodeB := TNetEncoding.Base16.Decode(Code);
  Assert.IsTrue(Vm.Destination.ContainsAuxCode(CodeB), 'check contains aux code failed');
end;

procedure TTestDestination.TestContainsStatusCode2;
var
  Code: TBytes;
begin
  Code := [Byte(HEIGHT), Byte(PUSH1), 0];
  Assert.IsTrue(ContainsStatusCode(Code), 'check contains status code failed');
  Code := [Byte(PUSH1), Byte(HEIGHT)];
  Assert.IsFalse(ContainsStatusCode(Code), 'check contains status code failed');
end;

procedure TTestDestination.TestGetCodeWithoutAuxCodeAndParams;
var
  TestCases: TArray<TGetCodeWithoutAuxCodeAndParamsTestCase>;
  TestCase: TGetCodeWithoutAuxCodeAndParamsTestCase;
  CodeB, ResultCode: TBytes;
  ResultCodeStr: string;
begin
  SetLength(TestCases, 7);
  TestCases[0] := TGetCodeWithoutAuxCodeAndParamsTestCase.Create('normal_auxcode_noparams', '608060405234801561001057600080fd5b50610141806100206000396000f3fe608060405260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fea165627a7a7230582017ef8aba505f3b1f219622dd9c54e93003fb280d0d7c48364215f545da9575b20029', '608060405234801561001057600080fd5b50610141806100206000396000f3fe608060405260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fe');
  // ... (rest of the test cases)

  for TestCase in TestCases do
  begin
    CodeB := TNetEncoding.Base16.Decode(TestCase.Code);
    ResultCode := GetCodeWithoutAuxCodeAndParams(CodeB);
    ResultCodeStr := TNetEncoding.Base16.Encode(ResultCode);
    Assert.AreEqual(TestCase.ResultCode, ResultCodeStr, 'name: ' + TestCase.Name + ', get code without auxCode and params failed');
  end;
end;

procedure TTestDestination.TestContainsCertainStatusCode;
var
  TestCases: TArray<TContainsCertainStatusCodeTestCase>;
  TestCase: TContainsCertainStatusCodeTestCase;
  CodeB: TBytes;
  RequireSnapshot, RequireSnapshotWithSeed: Boolean;
begin
  SetLength(TestCases, 4);
  TestCases[0] := TContainsCertainStatusCodeTestCase.Create('normal_contains_confirmtimes', '608060405234801561001057600080fd5b50610141806100206000396000f3fe60806040435260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fea165627a7a7230582017ef8aba505f3b1f219622dd9c54e93003fb280d0d7c48364215f545da9575b20029', True, False);
  TestCases[1] := TContainsCertainStatusCodeTestCase.Create('normal_contains_seedcount', '608060405234801561001057600080fd5b50610141806100206000396000f3fe608060404a5260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fea165627a7a7230582017ef8aba505f3b1f219622dd9c54e93003fb280d0d7c48364215f545da9575b20029', False, True);
  TestCases[2] := TContainsCertainStatusCodeTestCase.Create('normal_contains_seedcount_and_confirmtimes', '608060405234801561001057600080fd5b50610141806100206000396000f3fe60806040434a5260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fea165627a7a7230582017ef8aba505f3b1f219622dd9c54e93003fb280d0d7c48364215f545da9575b20029', True, True);
  TestCases[3] := TContainsCertainStatusCodeTestCase.Create('normal_contains_none', '608060405234801561001057600080fd5b50610141806100206000396000f3fe608060405260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806391a6cb4b14610046575b600080fd5b6100896004803603602081101561005c57600080fd5b81019080803574ffffffffffffffffffffffffffffffffffffffffff16906020019092919050505061008b565b005b8074ffffffffffffffffffffffffffffffffffffffffff164669ffffffffffffffffffff163460405160405180820390838587f1505050508074ffffffffffffffffffffffffffffffffffffffffff167faa65281f5df4b4bd3c71f2ba25905b907205fce0809a816ef8e04b4d496a85bb346040518082815260200191505060405180910390a25056fea165627a7a7230582017ef8aba505f3b1f219622dd9c54e93003fb280d0d7c48364215f545da9575b20029', False, False);

  for TestCase in TestCases do
  begin
    CodeB := TNetEncoding.Base16.Decode(TestCase.Code);
    ContainsCertainStatusCode(CodeB, RequireSnapshot, RequireSnapshotWithSeed);
    Assert.AreEqual(TestCase.Snapshot, RequireSnapshot, 'name: ' + TestCase.Name + ', snapshot mismatch');
    Assert.AreEqual(TestCase.SnapshotWithSeed, RequireSnapshotWithSeed, 'name: ' + TestCase.Name + ', snapshot with seed mismatch');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDestination);
end.
