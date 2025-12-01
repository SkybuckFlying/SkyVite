unit Ledger.Consensus.Snapshot.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  Common,
  Common.Types,
  Interfaces.Core,
  Ledger.Consensus,
  Ledger.Consensus.Core,
  Ledger.Pool.Lock,
  Log15,
  Mock.Interfaces.Core;

type
  [TestFixture]
  TSnapshotCsTest = class(TObject)
  public
    [Test]
    procedure TestSnapshotCs_ElectionIndex;
    [Test]
    procedure TestSnapshotCs_Tools;
    [Test]
    procedure TestNumber;
    [Test]
    procedure TestChainSnapshotAAAA;
  end;

implementation

uses
  System.DateUtils,
  Ledger.Test_Tools;

{ TSnapshotCsTest }

procedure TSnapshotCsTest.TestSnapshotCs_ElectionIndex;
var
  MockChain: TMockChain;
  DB: ILevelDB;
  Group: IConsensusGroupInfo;
  Info: IGroupInfo;
  B1: ISnapshotBlock;
  RW: TChainRw;
  CS: TSnapshotCs;
  VoteTime: TDateTime;
  Registers: TArray<IRegistration>;
  Reg1, Reg2, Reg3: IRegistration;
  Votes: TArray<IVoteInfo>;
  Vote: IVoteInfo;
  S1Balances, S2Balances, S3Balances: TDictionary<TAddress, BigInt>;
  Result: IElectionResult;
  I: Integer;
  SimpleGenesis: TDateTime;
  TempDir: string;
begin
  SimpleGenesis := EncodeDateTime(2018, 10, 24, 0, 0, 0, 0);
  TempDir := 'TestSnapshotCs_ElectionIndex';

  // 1. Create Mock and dependencies
  MockChain := TMockChain.Create;
  DB := NewDb(TempDir); // Assumes test helper
  try
    // 2. Setup expectations
    MockChain.Setup.WillReturn(TSnapshotBlock.Create(SimpleGenesis)).When.GetGenesisSnapshotBlock;
    MockChain.Setup.WillReturn(DB).When.NewDb(Arg.IsAny<string>);

    Group := TConsensusGroupInfo.Create;
    Group.Gid := SNAPSHOT_GID;
    Group.NodeCount := 3;
    Group.Interval := 1;
    Group.PerCount := 3;
    Group.RandCount := 1;
    Group.RandRank := 100;
    Group.Repeat := 1;
    Group.CountingTokenId := ViteTokenId;

    Info := TGroupInfo.Create(SimpleGenesis, Group);

    B1 := GenSnapshotBlock(1, '3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200', Default(THash), SimpleGenesis);

    MockChain.Setup.WillReturn([Group]).When.GetConsensusGroupList(B1.Hash);
    MockChain.Setup.WillReturn(B1).When.GetLatestSnapshotBlock;

    RW := TChainRw.Create(MockChain, TLogger.Create, TEasyLock.Create);
    CS := TSnapshotCs.Create(RW, TLogger.Create);
    try
      VoteTime := CS.GenProofTime(0);
      MockChain.Setup.WillReturn(B1).When.GetSnapshotHeaderBeforeTime(VoteTime);

      Reg1 := TRegistration.Create('s1', MockAddress(0));
      Reg2 := TRegistration.Create('s2', MockAddress(1));
      Reg3 := TRegistration.Create('s3', MockAddress(2));
      Registers := [Reg1, Reg2, Reg3];

      Votes := [];
      Vote := TVoteInfo.Create(MockAddress(11), 's1'); Votes := Concat(Votes, [Vote]);
      Vote := TVoteInfo.Create(MockAddress(12), 's1'); Votes := Concat(Votes, [Vote]);
      Vote := TVoteInfo.Create(MockAddress(21), 's2'); Votes := Concat(Votes, [Vote]);
      Vote := TVoteInfo.Create(MockAddress(31), 's3'); Votes := Concat(Votes, [Vote]);
      Vote := TVoteInfo.Create(MockAddress(32), 's3'); Votes := Concat(Votes, [Vote]);

      S1Balances := TDictionary<TAddress, BigInt>.Create;
      S1Balances.Add(MockAddress(11), 11);
      S1Balances.Add(MockAddress(12), 12);

      S2Balances := TDictionary<TAddress, BigInt>.Create;
      S2Balances.Add(MockAddress(21), 21);

      S3Balances := TDictionary<TAddress, BigInt>.Create;
      S3Balances.Add(MockAddress(31), 31);
      S3Balances.Add(MockAddress(32), 32);

      MockChain.Setup.WillReturn(Registers).When.GetRegisterList(B1.Hash, SNAPSHOT_GID);
      MockChain.Setup.WillReturn(Votes).When.GetVoteList(B1.Hash, SNAPSHOT_GID);
      MockChain.Setup.WillReturn(S1Balances).When.GetConfirmedBalanceList([MockAddress(11), MockAddress(12)], ViteTokenId, B1.Hash);
      MockChain.Setup.WillReturn(S2Balances).When.GetConfirmedBalanceList([MockAddress(21)], ViteTokenId, B1.Hash);
      MockChain.Setup.WillReturn(S3Balances).When.GetConfirmedBalanceList([MockAddress(31), MockAddress(32)], ViteTokenId, B1.Hash);
      MockChain.Setup.WillReturn(TUInt64(105)).When.GetRandomSeed(B1.Hash, 25);

      // 3. Execute
      Result := CS.ElectionIndex(0);

      // 4. Assert
      Assert.IsNotNull(Result);
      Assert.AreEqual(SimpleGenesis, Result.STime);
      Assert.AreEqual(IncSecond(SimpleGenesis, Info.PlanInterval), Result.ETime);
      Assert.AreEqual(TUInt64(0), Result.Index);
      Assert.AreEqual(9, Length(Result.Plans));

      for I := 0 to High(Result.Plans) do
      begin
        Assert.AreEqual(IncSecond(SimpleGenesis, I * Info.Interval), Result.Plans[I].STime);
        Assert.AreEqual(IncSecond(Result.Plans[I].STime, 1), Result.Plans[I].ETime);
        Assert.AreEqual(MockAddress((I div Info.PerCount) mod Info.NodeCount), Result.Plans[I].Member, Format('Plan index %d', [I]));
      end;

    finally
      CS.Free;
      RW.Free;
    end;
  finally
    DB.Free;
    ClearDb(TempDir); // Assumes test helper
  end;
end;

procedure TSnapshotCsTest.TestSnapshotCs_Tools;
begin
  Assert.Ignore('Skipped by default. This test can be used to inspect ledger data.');
end;

procedure TSnapshotCsTest.TestNumber;
var
  I: TUInt64;
begin
  I := (25 div 3 * 2) + 1;
  Assert.AreEqual(TUInt64(17), I);
end;

procedure TSnapshotCsTest.TestChainSnapshotAAAA;
begin
  Assert.Ignore('Skipped by default. This test can be used to inspect ledger data.');
end;

initialization
  RegisterTest(TSnapshotCsTest.Suite);

end.
