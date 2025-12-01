unit Ledger.Consensus.ConsensusContractDpos.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  Common.Types,
  V2.Interfaces.Core,
  Ledger.Consensus.ConsensusContractDpos,
  Ledger.Consensus.Core,
  Ledger.Pool.Lock,
  Log15,
  Ledger.Test_Tools,
  Go.leveldb,
  Delphi.Mocks;

type
  [TestFixture]
  TContractDposCsTest = class(TObject)
  public
    [Test]
    procedure TestContractDposCs_ElectionIndex;
  end;

implementation

uses
  System.DateUtils,
  Ledger.Consensus.ChainRw,
  Common.Address;

{ TContractDposCsTest }

procedure TContractDposCsTest.TestContractDposCs_ElectionIndex;
var
  vMockChain: TMock<IChain>;
  vDb: TLevelDB;
  vGroup: IConsensusGroupInfo;
  vInfo: IGroupInfo;
  vB1: ISnapshotBlock;
  vRw: TChainRw;
  vCs: TContractDposCs;
  vVoteTime: TDateTime;
  vRegisters: TArray<IRegistration>;
  vReg1, vReg2: IRegistration;
  vVotes: TArray<IVoteInfo>;
  vVote1, vVote2, vVote3: IVoteInfo;
  vS1Balances, vS2Balances: TDictionary<TAddress, TBigInteger>;
  vResult: IElectionResult;
  vIndex: Integer;
  vSimpleGenesis: TDateTime;
  vErr: Exception;
begin
  vSimpleGenesis := EncodeDateTime(2018, 10, 24, 0, 0, 0, 0);
  vMockChain := TMock<IChain>.Create;
  vDb := NewDb(UnitTestDir);
  try
    vMockChain.Setup.WillReturn(TSnapshotBlock.Create(Timestamp: vSimpleGenesis)).When.GetGenesisSnapshotBlock;
    vMockChain.Setup.WillReturn(vDb).When.NewDb(It.IsAny<string>);

    vGroup := TConsensusGroupInfo.Create;
    vGroup.Gid := DELEGATE_GID;
    vGroup.NodeCount := 2;
    vGroup.Interval := 1;
    vGroup.PerCount := 3;
    vGroup.RandCount := 1;
    vGroup.RandRank := 100;
    vGroup.Repeat := 1;
    vGroup.CountingTokenId := ViteTokenId;

    vInfo := TGroupInfo.Create(vSimpleGenesis, vGroup);

    vB1 := GenSnapshotBlock(1, '3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200', Default(THash), vSimpleGenesis);

    vRw := TChainRw.Create(vMockChain.Instance, TLogger.Create, TEasyLock.Create);
    vCs := TContractDposCs.Create(vInfo, vRw, TLogger.Create);
    try
      vVoteTime := vCs.GenProofTime(0);
      vMockChain.Setup.WillReturn(vB1).When.GetSnapshotHeaderBeforeTime(vVoteTime);

      vReg1 := TRegistration.Create('s1', MockAddress(0), MockAddress(0));
      vReg2 := TRegistration.Create('s2', MockAddress(1), MockAddress(1));
      vRegisters := [vReg1, vReg2];

      vVote1 := TVoteInfo.Create(MockAddress(11), 's1');
      vVote2 := TVoteInfo.Create(MockAddress(12), 's1');
      vVote3 := TVoteInfo.Create(MockAddress(21), 's2');
      vVotes := [vVote1, vVote2, vVote3];

      vS1Balances := TDictionary<TAddress, TBigInteger>.Create;
      vS1Balances.Add(MockAddress(11), 11);
      vS1Balances.Add(MockAddress(12), 12);

      vS2Balances := TDictionary<TAddress, TBigInteger>.Create;
      vS2Balances.Add(MockAddress(21), 21);

      vMockChain.Setup.WillReturn(vRegisters).When.GetRegisterList(vB1.Hash, DELEGATE_GID);
      vMockChain.Setup.WillReturn(vVotes).When.GetVoteList(vB1.Hash, DELEGATE_GID);
      vMockChain.Setup.WillReturn(vS1Balances).When.GetConfirmedBalanceList([MockAddress(11), MockAddress(12)], ViteTokenId, vB1.Hash);
      vMockChain.Setup.WillReturn(vS2Balances).When.GetConfirmedBalanceList([MockAddress(21)], ViteTokenId, vB1.Hash);
      vMockChain.Setup.WillReturn(105).When.GetRandomSeed(vB1.Hash, 25);

      TValue.Make(vCs.ElectionIndex(0), vResult, vErr);
      Assert.IsNull(vErr);

      Assert.IsNotNull(vResult);
      Assert.AreEqual(vSimpleGenesis, vResult.STime);
      Assert.AreEqual(IncSecond(vSimpleGenesis, vInfo.PlanInterval), vResult.ETime);
      Assert.AreEqual(uint64(0), vResult.Index);
      Assert.AreEqual(6, Length(vResult.Plans));

      for vIndex := 0 to High(vResult.Plans) do
      begin
        Assert.AreEqual(IncSecond(vSimpleGenesis, vIndex * vInfo.Interval), vResult.Plans[vIndex].STime);
        Assert.AreEqual(IncSecond(vResult.Plans[vIndex].STime, 1), vResult.Plans[vIndex].ETime);
        Assert.AreEqual(MockAddress((vIndex div vInfo.PerCount) mod vInfo.NodeCount), vResult.Plans[vIndex].Member, Format('Plan index %d', [vIndex]));
      end;

    finally
      vCs.Free;
      vRw.Free;
    end;
  finally
    vDb.Free;
    ClearDb(UnitTestDir);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TContractDposCsTest);

end.