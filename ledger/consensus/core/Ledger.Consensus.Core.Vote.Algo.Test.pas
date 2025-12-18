unit Ledger.Consensus.Core.Vote.Algo.Test;

interface

uses
  BigNumbers,
  Common,
  Common.Types,
  DUnitX.TestFramework,
  Interfaces.Core,
  Ledger.Consensus.Core.Consensus,
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader.Test,
  Ledger.Consensus.Core.State.Reader,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.Time.Index.Test,
  Ledger.Consensus.Core.Utils,
  Ledger.Consensus.Core.Vote.Algo,
  System.Generics.Collections,
  System.SysUtils;

type
  [TestFixture]
  TAlgoTest = class(TObject)
  public
    [Test]
    procedure TestAlgo_FilterVotes;
    [Test]
    procedure TestAlgo_FilterVotes2;
    [Test]
    procedure TestAlgo_FilterVotes3;
    [Test]
    procedure TestAlgo_FilterBySuccessRate;
  end;

procedure PrintResult(AAG: IAlgo; ATotal: UInt64; ACnt: Integer);

implementation

uses
  System.DateUtils;

procedure PrintResult(AAG: IAlgo; ATotal: UInt64; ACnt: Integer);
var
  vVotes: TArray<TVote>;
  I: Integer;
  J: UInt64;
  vResult: TDictionary<string, UInt64>;
  vHashH: IHashHeight;
  vTmp: TArray<TVote>;
  vVote: TVote;
  vValue: UInt64;
begin
  Writeln(Format('----------------------- %d %d --------------------------------------------------', [ATotal, ACnt]));
  SetLength(vVotes, ACnt);
  for I := 0 to ACnt - 1 do
  begin
    vVotes[I] := TVote.Create;
    vVotes[I].Name := 'wj_' + IntToStr(I);
    vVotes[I].Balance := TBigInteger.Create(I);
  end;
  vResult := TDictionary<string, UInt64>.Create;
  try
    for J := 0 to ATotal - 1 do
    begin
      vHashH := THashHeight.Create(J, THash.Empty);
      vTmp := AAG.FilterVotes(TVoteAlgoContext.Create(vVotes, vHashH, nil, TSeedInfo.Create(0)));
      for vVote in vTmp do
      begin
        if vResult.TryGetValue(vVote.Name, vValue) then
          vResult[vVote.Name] := vValue + 1
        else
          vResult.Add(vVote.Name, 1);
      end;
    end;
    TArray.Sort<TVote>(vVotes, TComparer<TVote>.Construct(
      function(const L, R: TVote): Integer
      begin
        Result := R.Balance.CompareTo(L.Balance);
      end));
    for vVote in vVotes do
    begin
      if vResult.TryGetValue(vVote.Name, vValue) then
        Writeln(vVote.Name, (vValue * 10000) / ATotal)
      else
        Writeln(vVote.Name, 0);
    end;
  finally
    vResult.Free;
  end;
  Writeln('-------------------------------------------------------------------------');
end;

{ TAlgoTest }

procedure TAlgoTest.TestAlgo_FilterVotes;
var
  vNow: TDateTime;
  vInfo: TGroupInfo;
  vAG: IAlgo;
begin
  vNow := UnixToDateTime(1541640427);
  vInfo := TGroupInfo.Create(vNow, TConsensusGroupInfo.Create(SNAPSHOT_GID, 25, 1, 3, 2, 100, 1, 1, ViteTokenId, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vAG := TAlgo.Create(vInfo);
    PrintResult(vAG, 1000, 25);
  finally
    vInfo.Free;
  end;
end;

procedure TAlgoTest.TestAlgo_FilterVotes2;
var
  vNow: TDateTime;
  vInfo: TGroupInfo;
  vAG: IAlgo;
  vVotes: TArray<TVote>;
  I: Integer;
  vHashH: IHashHeight;
  vActual: TArray<TVote>;
  vExpected: TArray<string>;
begin
  vNow := UnixToDateTime(1541640427);
  vInfo := TGroupInfo.Create(vNow, TConsensusGroupInfo.Create(SNAPSHOT_GID, 25, 1, 3, 2, 100, 1, 1, ViteTokenId, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vAG := TAlgo.Create(vInfo);
    SetLength(vVotes, 100);
    for I := 0 to 99 do
    begin
      vVotes[I] := TVote.Create;
      vVotes[I].Name := 'wj_' + IntToStr(I);
      vVotes[I].Balance := TBigInteger.Create(I);
    end;
    vHashH := THashHeight.Create(1, THash.Empty);
    vActual := vAG.FilterVotes(TVoteAlgoContext.Create(vVotes, vHashH, nil, TSeedInfo.Create(0)));
    vExpected := ['wj_99', 'wj_98', 'wj_97', 'wj_96', 'wj_95', 'wj_94', 'wj_92', 'wj_91', 'wj_90', 'wj_89', 'wj_88', 'wj_87', 'wj_86', 'wj_85', 'wj_84', 'wj_83', 'wj_82', 'wj_81', 'wj_80', 'wj_79', 'wj_78', 'wj_77', 'wj_75', 'wj_49', 'wj_27'];

    Assert.AreEqual(Length(vExpected), Length(vActual));
    for I := 0 to High(vActual) do
    begin
      Assert.AreEqual(vExpected[I], vActual[I].Name, Format('Mismatch at index %d', [I]));
    end;

  finally
    vInfo.Free;
  end;
end;

procedure TAlgoTest.TestAlgo_FilterVotes3;
var
  vNow: TDateTime;
  vInfo: TGroupInfo;
  vAG: IAlgo;
  vVotes: TArray<TVote>;
  I: Integer;
  vHashH: IHashHeight;
  vActual: TArray<TVote>;
begin
  vNow := UnixToDateTime(1541640427);
  vInfo := TGroupInfo.Create(vNow, TConsensusGroupInfo.Create(SNAPSHOT_GID, 25, 1, 3, 2, 100, 1, 1, ViteTokenId, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vAG := TAlgo.Create(vInfo);
    SetLength(vVotes, 100);
    for I := 0 to 99 do
    begin
      vVotes[I] := TVote.Create;
      vVotes[I].Name := 'wj_' + IntToStr(I);
      vVotes[I].Balance := TBigInteger.Create(100 - I);
    end;
    vHashH := THashHeight.Create(1, THash.Empty);
    vActual := vAG.FilterVotes(TVoteAlgoContext.Create(vVotes, vHashH, nil, TSeedInfo.Create(0)));
    TArray.Sort<TVote>(vActual, TComparer<TVote>.Construct(
      function(const L, R: TVote): Integer
      begin
        Result := R.Balance.CompareTo(L.Balance);
      end));

    for var vVote in vActual do
    begin
      TestFramework.Log(Format('"%s" %s,', [vVote.Name, vVote.Balance.ToString]));
    end;

  finally
    vInfo.Free;
  end;
end;

procedure TAlgoTest.TestAlgo_FilterBySuccessRate;
var
  vA: IAlgo;
  vGroupA, vGroupB, vResultA, vResultB: TArray<TVote>;
  I: Integer;
  vVote: TVote;
  vSuccessRate: TDictionary<TAddress, Integer>;
  vNameA, vNameB: TArray<string>;
begin
  vA := TAlgo.Create(nil); // Info is not used in filterBySuccessRate
  SetLength(vGroupA, 26);
  for I := 10 to 35 do
  begin
    vVote := TVote.Create;
    vVote.Name := Format('s%d', [I]);
    vVote.Addr := TCommon.MockAddress(I);
    vVote.Balance := TBigInteger.Create(10);
    vGroupA[I - 10] := vVote;
  end;
  SetLength(vGroupB, 10);
  for I := 40 to 49 do
  begin
    vVote := TVote.Create;
    vVote.Name := Format('s%d', [I]);
    vVote.Addr := TCommon.MockAddress(I);
    vVote.Balance := TBigInteger.Create(10);
    vGroupB[I - 40] := vVote;
  end;

  vSuccessRate := TDictionary<TAddress, Integer>.Create;
  try
    for vVote in vGroupA do vSuccessRate.Add(vVote.Addr, 1000000);
    for vVote in vGroupB do vSuccessRate.Add(vVote.Addr, 800001);

    vSuccessRate[TCommon.MockAddress(24)] := 0;
    (vA as TAlgo).FilterBySuccessRate(vGroupA, vGroupB, nil, vSuccessRate);
    vResultA := vGroupA;
    vResultB := vGroupB;

    vNameA := ['s10', 's11', 's12', 's13', 's14', 's15', 's16', 's17', 's18', 's19', 's20', 's21', 's22', 's23', 's25', 's26', 's27', 's28', 's29', 's30', 's31', 's32', 's33', 's34', 's35', 's40'];
    Assert.AreEqual(Length(vNameA), Length(vResultA));
    for I := 0 to High(vResultA) do Assert.AreEqual(vNameA[I], vResultA[I].Name);

    vNameB := ['s42', 's43', 's44', 's45', 's46', 's47', 's48', 's49', 's24', 's41'];
    Assert.AreEqual(Length(vNameB), Length(vResultB));
    for I := 0 to High(vResultB) do Assert.AreEqual(vNameB[I], vResultB[I].Name);

  finally
    vSuccessRate.Free;
  end;
end;

end.
