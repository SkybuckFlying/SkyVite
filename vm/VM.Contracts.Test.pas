unit VM.Contracts.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Vite.VM,
  VM.Contracts.Dex.Fund.Test.Database,
  Vite.Common.Types,
  GoToDelphi.Helpers.BigInt,
  Vite.Interfaces.Core,
  Vite.Ledger;

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
