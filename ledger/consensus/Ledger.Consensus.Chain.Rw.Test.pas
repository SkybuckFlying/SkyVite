unit Ledger.Consensus.ChainRw.Test;

interface

uses
  Common.Config,
  Common.Types,
  Delphi.Mocks,
  DUnitX.TestFramework,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  Ledger.Pool.Lock,
  Ledger.Test_Tools,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  V2.Interfaces.Core;

type
  [TestFixture]
  TChainRWTest = class(TObject)
  private
    FChainInstance: IChain;
    FTempDir: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestChainRw_Simple;
    [Test]
    procedure TestChainRw_GetMemberInfo;
    [Test]
    procedure TestChainRw_GetMemberInfo2;
    [Test]
    procedure TestChainRw_GenLruKey;
  end;

function GetConsensusGroupList: TArray<IConsensusGroupInfo>;

implementation

uses
  System.IOUtils,
  Ledger.Consensus.DB,
  Ledger.Consensus.Core,
  System.DateUtils,
  Go.leveldb;

function GetConsensusGroupList: TArray<IConsensusGroupInfo>;
var
  vInfo: IConsensusGroupInfo;
begin
  vInfo := TConsensusGroupInfo.Create;
  vInfo.Gid := SNAPSHOT_GID;
  vInfo.NodeCount := 10;
  vInfo.Interval := 1;
  vInfo.PerCount := 3;
  vInfo.RandCount := 2;
  vInfo.RandRank := 100;
  vInfo.Repeat := 1;
  vInfo.CheckLevel := 0;
  vInfo.CountingTokenId := Default(TTokenTypeId);
  vInfo.RegisterConditionId := 0;
  vInfo.RegisterConditionParam := nil;
  vInfo.VoteConditionId := 0;
  vInfo.VoteConditionParam := nil;
  vInfo.Owner := Default(TAddress);
  vInfo.StakeAmount := nil;
  vInfo.ExpirationHeight := 0;
  Result := [vInfo];
end;

{ TChainRWTest }

procedure TChainRWTest.Setup;
begin
  // Default setup can be empty if tests do their own.
end;

procedure TChainRWTest.TearDown;
begin
  if (FChainInstance <> nil) and (FTempDir <> '') then
  begin
    ClearChain(FChainInstance, FTempDir);
  end;
end;

procedure TChainRWTest.TestChainRw_Simple;
begin
  FChainInstance := NewTestChainInstance('TestChainRw_Simple', True, nil, FTempDir);
  Assert.IsNotNull(FChainInstance);
end;

procedure TChainRWTest.TestChainRw_GetMemberInfo;
var
  vMockChain: TMock<IChain>;
  vGenesisBlock: ISnapshotBlock;
  vInfos: TArray<IConsensusGroupInfo>;
  vRw: TChainRw;
  vBlock: ISnapshotBlock;
  vGroupInfo: IGroupInfo;
  vSimpleGenesis: TDateTime;
  vDb: TLevelDB;
begin
  vSimpleGenesis := EncodeDateTime(2018, 10, 24, 0, 0, 0, 0);
  FTempDir := TPath.Combine(TPath.GetTempPath, 'TestChainRw_GetMemberInfo');
  if TDirectory.Exists(FTempDir) then
  begin
    TDirectory.Delete(FTempDir, True);
  end;
  TDirectory.CreateDirectory(FTempDir);

  vMockChain := TMock<IChain>.Create;

  vGenesisBlock := TSnapshotBlock.Create;
  vGenesisBlock.Height := 1;
  vGenesisBlock.Timestamp := vSimpleGenesis;
  vGenesisBlock.ComputeHash;

  vMockChain.Setup.WillReturn(vGenesisBlock).When.GetLatestSnapshotBlock;
  vMockChain.Setup.WillReturn(vGenesisBlock).When.GetGenesisSnapshotBlock;
  vMockChain.Setup.WillReturn(NewDb(FTempDir)).When.NewDb(It.IsAny<string>);
  vInfos := GetConsensusGroupList;
  vMockChain.Setup.WillReturn(vInfos).When.GetConsensusGroupList(vGenesisBlock.Hash);

  vRw := TChainRw.Create(vMockChain.Instance, TLogger.Create('unittest', 'chainrw'), TEasyLock.Create);
  try
    vBlock := vRw.GetLatestSnapshotBlock;
    Assert.AreEqual(vGenesisBlock.Timestamp, vBlock.Timestamp);

    vGroupInfo := vRw.GetMemberInfo(SNAPSHOT_GID);
    Assert.IsNotNull(vGroupInfo);
    Assert.AreEqual(uint64(30), vGroupInfo.PlanInterval);

    var vSTime: TDateTime;
    vSTime := vGroupInfo.Index2Time(0);
    Assert.AreEqual(vSimpleGenesis, vSTime);
  finally
    vRw.Free;
    ClearDb(FTempDir);
  end;
end;

procedure TChainRWTest.TestChainRw_GetMemberInfo2;
var
  vGenesis: ISnapshotBlock;
  vInfos: TArray<IConsensusGroupInfo>;
  vInfo: IConsensusGroupInfo;
  vFoundSnapshot, vFoundDelegate: Boolean;
begin
  FChainInstance := NewTestChainInstance('TestChainRw_GetMemberInfo2', True, MockGenesis, FTempDir);
  vGenesis := FChainInstance.GetGenesisSnapshotBlock;
  vInfos := FChainInstance.GetConsensusGroupList(vGenesis.Hash);

  Assert.AreEqual(2, Length(vInfos));
  vFoundSnapshot := False;
  vFoundDelegate := False;
  for vInfo in vInfos do
  begin
    if vInfo.Gid.IsEqual(SNAPSHOT_GID) then
    begin
      vFoundSnapshot := True;
      Assert.AreEqual(uint8(0), vInfo.CheckLevel);
      Assert.AreEqual(uint16(1), vInfo.Repeat);
    end
    else if vInfo.Gid.IsEqual(DELEGATE_GID) then
    begin
      vFoundDelegate := True;
      Assert.AreEqual(uint8(1), vInfo.CheckLevel);
      Assert.AreEqual(uint16(48), vInfo.Repeat);
    end;
  end;
  Assert.IsTrue(vFoundSnapshot, 'Snapshot GID not found');
  Assert.IsTrue(vFoundDelegate, 'Delegate GID not found');
end;

procedure TChainRWTest.TestChainRw_GenLruKey;
var
  vGid: TGid;
  vHash: THash;
  vRw: TChainRw;
  vKey: TBytes;
  vResult: TDictionary<TBytes, string>;
begin
  vGid := SNAPSHOT_GID;
  vHash := Default(THash); // Zero hash

  vRw := TChainRw.Create(nil, nil, nil); // Not calling methods that need dependencies
  try
    vKey := vRw.GenLruKey(vGid, vHash);
    vResult := TDictionary<TBytes, string>.Create(TBytesComparer.Instance);
    try
      vResult.Add(vKey, '1');
      Assert.AreEqual(1, vResult.Count);
      Assert.IsTrue(vResult.ContainsKey(vKey));
    finally
      vResult.Free;
    end;
  finally
    vRw.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TChainRWTest);

end.
