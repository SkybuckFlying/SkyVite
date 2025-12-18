unit VM.Contracts.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.BigInt,
  System.SysUtils,
  Vite.Common.Types,
  Vite.Interfaces.Core,
  Vite.Ledger,
  Vite.VM,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Fund.Test.Database,
  VM.Contracts.Dex.Trade.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
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
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  [TestFixture]
  TContractsTest = class
  public
    [Test]
    procedure TestContractsRefund;
    [Test]
    procedure TestContractsRegister;
    [Test]
    procedure TestContractsVote;
    [Test]
    procedure TestContractsStake;
    [Test]
    procedure TestContractsAssetV2;
    [Test]
    procedure TestCheckTokenName;
  private
    function PrepareDb(ParaViteTotalSupply: TBigInt): TTestDatabase;
    function NewTestGlobalStatus(ParaTime: Int64; ParaSnapshotBlock: ISnapshotBlock): IGlobalStatus;
    function NewConsensusReaderTest(ParaGenesisTime: Int64; ParaInterval: Int64; ParaDetailMap: TDictionary<UInt64, TDictionary<string, TConsensusDetail>>): IConsensusReader;
  end;

  TConsensusDetail = record
    BlockNum: UInt64;
    ExpectedBlockNum: UInt64;
    VoteCount: TBigInt;
  end;

implementation

procedure TContractsTest.TestContractsRefund;
begin
  // Implementation to be added
end;

procedure TContractsTest.TestContractsRegister;
begin
  // Implementation to be added
end;

procedure TContractsTest.TestContractsVote;
begin
  // Implementation to be added
end;

procedure TContractsTest.TestContractsStake;
begin
  // Implementation to be added
end;

procedure TContractsTest.TestContractsAssetV2;
begin
  // Implementation to be added
end;

procedure TContractsTest.TestCheckTokenName;
begin
  // Implementation to be added
end;

function TContractsTest.PrepareDb(ParaViteTotalSupply: TBigInt): TTestDatabase;
begin
  // Implementation to be added
end;

function TContractsTest.NewTestGlobalStatus(ParaTime: Int64; ParaSnapshotBlock: ISnapshotBlock): IGlobalStatus;
begin
  // Implementation to be added
end;

function TContractsTest.NewConsensusReaderTest(ParaGenesisTime: Int64; ParaInterval: Int64; ParaDetailMap: TDictionary<UInt64, TDictionary<string, TConsensusDetail>>): IConsensusReader;
begin
  // Implementation to be added
end;

initialization
  RegisterTestFixture(TContractsTest);
end.
