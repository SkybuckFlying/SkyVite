unit Ledger.Consensus.Consensus.Test;

interface

uses
  Common.Config,
  Common.Types,
  DUnitX.TestFramework,
  Interfaces.Core,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
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
  System.SysUtils;

type
  [TestFixture]
  TConsensusTest = class(TObject)
  private
    mChain: IChain;
    mTempDir: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestContractDposCs_ElectionIndexReader;
    [Test]
    procedure TestConsensus;
    [Test]
    procedure TestChainSnapshot;
    [Test]
    procedure TestChainAcc;
    [Test]
    procedure TestChainAll;
  end;

implementation

uses
  System.DateUtils,
  Ledger.Consensus.Core,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.ContractDPoS,
  Ledger.Consensus.Snapshot;

{ TConsensusTest }

procedure TConsensusTest.Setup;
begin
  mChain := NewTestChainInstance('ConsensusTest', True, MockGenesis, mTempDir);
end;

procedure TConsensusTest.TearDown;
begin
  ClearChain(mChain, mTempDir);
end;

procedure TConsensusTest.TestContractDposCs_ElectionIndexReader;
var
  vRW: TChainRw;
  vGroupInfo: IGroupInfo;
  vCS: TContractDposCs;
  vProof: TRollbackProof;
  vIndex, vI: TUInt64;
  vETime: TDateTime;
  vHashes: THash;
  vResult: IElectionResult;
  vVS: string;
  vV: IPlan;
  vErr: Exception;
begin
  vRW := TChainRw.Create(mChain, TLogger.Create, TEasyLock.Create);
  try
    TValue.Make(vRW.GetMemberInfo(DELEGATE_GID), vGroupInfo, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vGroupInfo);

    vCS := TContractDposCs.Create(vGroupInfo, vRW, TLogger.Create);
    try
      vProof := TRollbackProof.Create(vRW.RW);
      try
        vIndex := vCS.Time2Index(Now);
        for vI := vIndex downto 1 do
        begin
          vETime := vCS.Index2Time(vI).ETime;
          TValue.Make(vProof.ProofHash(vETime), vHashes, vErr);
          Assert.IsNull(vErr);
          if vRW.RW.IsGenesisSnapshotBlock(vHashes) then
          begin
            Break;
          end;

          TValue.Make(vCS.ElectionIndex(vI), vResult, vErr);
          Assert.IsNull(vErr);
          Assert.IsNotNull(vResult);

          vVS := #13#10;
          for vV in vResult.Plans do
          begin
            vVS := vVS + Format('		[%s][%s][%s]'#13#10, [FormatDateTime('yyyy-mm-dd hh:nn:ss', vV.STime), FormatDateTime('yyyy-mm-dd hh:nn:ss', vV.ETime), vV.Member.ToString]);
          end;
          WriteLn(Format('%d %d %s %s %s %s', [vI, Length(vResult.Plans), vHashes.ToString, FormatDateTime('yyyy-mm-dd hh:nn:ss', vResult.STime), FormatDateTime('yyyy-mm-dd hh:nn:ss', vResult.ETime), vVS]));
        end;
      finally
        vProof.Free;
      end;
    finally
      vCS.Free;
    end;
  finally
    vRW.Free;
  end;
end;

procedure TConsensusTest.TestConsensus;
var
  vIndex: TUInt64;
  vCS: IConsensus;
  vSTime, vETime: TDateTime;
  vResult: IElectionResult;
  vV: IPlan;
  vAddresses: TAddress;
  vErr: Exception;
begin
  vIndex := 291471;
  vCS := NewConsensus(mChain, TEasyLock.Create);
  vCS.Init(nil);
  vCS.Start;
  try
    TValue.Make(vCS.VoteIndexToTime(SNAPSHOT_GID, vIndex), vSTime, vETime, vErr);
    Assert.IsNull(vErr);
    WriteLn(Format('%s %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', vSTime), FormatDateTime('yyyy-mm-dd hh:nn:ss', vETime)]));

    TValue.Make((vCS.SBPReader as TSnapshotCs).ElectionIndex(vIndex), vResult, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vResult);

    for vV in vResult.Plans do
    begin
      WriteLn(vV.ToString);
    end;

    vAddresses := PubkeyToAddress([59, 245, 248, 162, 33, 219, 95, 240, 171, 227, 160, 56, 42, 147, 223, 34, 252, 232, 23, 156, 236, 11, 73, 135, 153, 172, 56, 81, 90, 193, 39, 82]);
    WriteLn(vAddresses.ToString);
  finally
    vCS.Stop;
  end;
end;

procedure TConsensusTest.TestChainSnapshot;
var
  vPrev: ISnapshotBlock;
  vI: TUInt64;
  vBlock: ISnapshotBlock;
  vInfos: TArray<IRegistration>;
  vVS: string;
  vV: IRegistration;
  vErr: Exception;
begin
  vPrev := mChain.GetLatestSnapshotBlock;
  for vI := 1 to vPrev.Height do
  begin
    TValue.Make(mChain.GetSnapshotBlockByHeight(vI), vBlock, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vBlock);
    TValue.Make(mChain.GetRegisterList(vBlock.Hash, SNAPSHOT_GID), vInfos, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vInfos);

    vVS := '';
    for vV in vInfos do
    begin
      vVS := vVS + Format('[%s],', [vV.Name]);
    end;
    WriteLn(Format('height:%d, hash:%s, producer:%s, t:%s, vs:%s', [vBlock.Height, vBlock.Hash.ToString, vBlock.Producer.ToString, FormatDateTime('yyyy-mm-dd hh:nn:ss', vBlock.Timestamp), vVS]));
  end;
end;

procedure TConsensusTest.TestChainAcc;
var
  vAddr: TAddress;
  vPrev: IAccountBlock;
  vI: TUInt64;
  vBlock: IAccountBlock;
  vU: IHashHeight;
  vErr: Exception;
begin
  vAddr := HexToAddressPanic('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  TValue.Make(mChain.GetLatestAccountBlock(vAddr), vPrev, vErr);
  Assert.IsNull(vErr);
  Assert.IsNotNull(vPrev);
  WriteLn(vPrev.ToString);
  WriteLn(Format('prev.Height: %d', [vPrev.Height]));

  for vI := 1 to vPrev.Height do
  begin
    TValue.Make(mChain.GetAccountBlockByHeight(vAddr, vI), vBlock, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vBlock);
    TValue.Make(mChain.GetConfirmSnapshotHeaderByAbHash(vBlock.Hash), vU, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vU);

    WriteLn(Format('height:%d, producer:%s, hash:%s, %s, %d', [vBlock.Height, vBlock.Producer.ToString, vBlock.Hash.ToString, vU.Hash.ToString, vU.Height]));
    if vI > 3000 then
    begin
      Break;
    end;
  end;
end;

procedure TConsensusTest.TestChainAll;
var
  vPrev: ISnapshotBlock;
  vI: TUInt64;
  vBlock: ISnapshotBlock;
  vAccM: TDictionary<TAddress, TArray<IAccountBlock>>;
  vK: TAddress;
  vV: IHashHeight;
  vJ: TUInt64;
  vTmpAB: IAccountBlock;
  vSB: IHashHeight;
  vVS, vBS, vDetailBs: string;
  vB: IAccountBlock;
  vErr: Exception;
begin
  vPrev := mChain.GetLatestSnapshotBlock;
  Assert.IsNotNull(vPrev);

  for vI := 1 to vPrev.Height do
  begin
    TValue.Make(mChain.GetSnapshotBlockByHeight(vI), vBlock, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vBlock);
    vAccM := TDictionary<TAddress, TArray<IAccountBlock>>.Create;
    try
      for vK in vBlock.SnapshotContent.Keys do
      begin
        vV := vBlock.SnapshotContent[vK];
        for vJ := vV.Height downto 1 do
        begin
          TValue.Make(mChain.GetAccountBlockByHeight(vK, vJ), vTmpAB, vErr);
          Assert.IsNull(vErr);
          Assert.IsNotNull(vTmpAB);
          TValue.Make(mChain.GetConfirmSnapshotHeaderByAbHash(vTmpAB.Hash), vSB, vErr);
          Assert.IsNull(vErr);
          if vSB.Hash.IsEqual(vBlock.Hash) then
          begin
            if not vAccM.ContainsKey(vK) then
            begin
              vAccM.Add(vK, []);
            end;
            vAccM[vK] := Concat(vAccM[vK], [vTmpAB]);
          end
          else
          begin
            Break;
          end;
        end;
      end;

      vVS := Format('snapshot[%d][%s][%s]'#13#10, [vBlock.Height, vBlock.Hash.ToString, vBlock.PrevHash.ToString]);
      for vK in vAccM.Keys do
      begin
        vBS := '';
        vDetailBs := '';
        for vB in vAccM[vK] do
        begin
          vBS := vBS + Format('%d,', [vB.Height]);
          vDetailBs := vDetailBs + Format('[%d-%s]', [vB.Height, vB.Hash.ToString]);
        end;
        vVS := vVS + Format('	account[%s][%s][%d]'#13#10, [vK.ToString, vBS, vBlock.SnapshotContent[vK].Height]);
        vVS := vVS + Format('		details[%s]'#13#10, [vDetailBs]);
      end;
      WriteLn(vVS);
    finally
      vAccM.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TConsensusTest);

end.
