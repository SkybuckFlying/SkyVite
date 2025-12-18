unit Ledger.Consensus.Core.Vote.Algo;

interface

uses
  BigNumbers,
  Common.Types,
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
  Ledger.Consensus.Core.Vote.Algo.Test,
  System.Generics.Collections,
  System.SysUtils;

type
  TVoteAlgoContext = class
  public
    Votes: TArray<TVote>;
    HashH: IHashHeight;
    SuccessRate: TDictionary<TAddress, Integer>;
    Seeds: TSeedInfo;
    SBPs: TArray<TVote>; // TopN SBPs
    constructor Create(AVotes: TArray<TVote>; AHashH: IHashHeight; ASuccessRate: TDictionary<TAddress, Integer>; ASeeds: TSeedInfo);
    destructor Destroy; override;
  end;

  IAlgo = interface
    ['{E3A2E8B9-A2C3-4B8D-9B1A-2A8E5C1B4A5E}']
    function ShuffleVotes(AVotes: TArray<TVote>; AHashH: IHashHeight; AInfo: TSeedInfo): TArray<TVote>;
    function FilterVotes(AContext: TVoteAlgoContext): TArray<TVote>;
    procedure FilterSimple(AVotes: TArray<TVote>; out AGroupA, AGroupB: TArray<TVote>);
  end;

  TSeedInfo = class
  public
    Seeds: UInt64;
    constructor Create(ASeed: UInt64);
  end;

  TAlgo = class(TInterfacedObject, IAlgo)
  private
    FInfo: TGroupInfo;
    function FindSeedTmp(AVotes: TArray<TVote>; ASHeight: UInt64; AInfo: TSeedInfo; ASuccessRate: TDictionary<TAddress, Integer>): Int64;
    function FindSeed(AVotes: TArray<TVote>; ASHeight: UInt64; AInfo: TSeedInfo): Int64;
    function CalRandCnt(ATotal, ARandNum: Integer): Integer;
    function FilterRand(AVotes: TArray<TVote>; AHashH: IHashHeight; ASeedInfo: TSeedInfo): TArray<TVote>;
    function FilterRandV2(AGroupA, AGroupB: TArray<TVote>; AHashH: IHashHeight; ASeedInfo: TSeedInfo; ASuccessRate: TDictionary<TAddress, Integer>): TArray<TVote>;
    procedure FilterBySuccessRate(var AGroupA, AGroupB: TArray<TVote>; AHeight: IHashHeight; ASuccessRate: TDictionary<TAddress, Integer>);
    function CheckValid(AGroupA, AGroupB: TArray<TVote>): Boolean;
  public
    constructor Create(AInfo: TGroupInfo);
    function ShuffleVotes(AVotes: TArray<TVote>; AHashH: IHashHeight; AInfo: TSeedInfo): TArray<TVote>;
    function FilterVotes(AContext: TVoteAlgoContext): TArray<TVote>;
    procedure FilterSimple(AVotes: TArray<TVote>; out AGroupA, AGroupB: TArray<TVote>);
  end;

  TSuccessRateVote = class
  public
    Vote: TVote;
    Rate: Integer;
  end;

function MergeGroup(AGroupA, AGroupB: TArray<TVote>): TArray<TVote>;

const
  Line = 800000;
  RANDOM_PROMOTION = 1;
  SUCCESS_RATE_PROMOTION = 2;
  SUCCESS_RATE_DEMOTION = 3;

implementation

uses
  System.Math,
  System.Classes;

{ TVoteAlgoContext }

constructor TVoteAlgoContext.Create(AVotes: TArray<TVote>; AHashH: IHashHeight; ASuccessRate: TDictionary<TAddress, Integer>; ASeeds: TSeedInfo);
begin
  Self.Votes := AVotes;
  Self.HashH := AHashH;
  if ASuccessRate <> nil then
    Self.SuccessRate := ASuccessRate
  else
    Self.SuccessRate := TDictionary<TAddress, Integer>.Create;
  Self.Seeds := ASeeds;
end;

destructor TVoteAlgoContext.Destroy;
begin
  if SuccessRate.Owner then
    SuccessRate.Free;
  inherited;
end;

{ TSeedInfo }

constructor TSeedInfo.Create(ASeed: UInt64);
begin
  Self.Seeds := ASeed;
end;

{ TAlgo }

constructor TAlgo.Create(AInfo: TGroupInfo);
begin
  FInfo := AInfo;
end;

function TAlgo.FindSeedTmp(AVotes: TArray<TVote>; ASHeight: UInt64; AInfo: TSeedInfo; ASuccessRate: TDictionary<TAddress, Integer>): Int64;
var
  vResult: TBigInteger;
  vVote: TVote;
  vRate: Integer;
begin
  vResult := TBigInteger.Create(ASHeight);
  if AInfo.Seeds = 0 then
  begin
    for vVote in AVotes do
      vResult := vResult + vVote.Balance;
  end;
  if ASuccessRate <> nil then
  begin
    for vRate in ASuccessRate.Values do
      vResult := vResult + TBigInteger.Create(vRate);
  end;
  vResult := vResult + TBigInteger.Create(AInfo.Seeds);
  vResult := vResult + FInfo.Seed;
  Result := vResult.AsInt64;
end;

function TAlgo.FindSeed(AVotes: TArray<TVote>; ASHeight: UInt64; AInfo: TSeedInfo): Int64;
var
  vResult: TBigInteger;
  vVote: TVote;
begin
  if AInfo.Seeds = 0 then
  begin
    vResult := TBigInteger.Zero;
    for vVote in AVotes do
      vResult := vResult + vVote.Balance;
    vResult := vResult + TBigInteger.Create(ASHeight);
    Result := (vResult + FInfo.Seed).AsInt64;
  end
  else
  begin
    vResult := TBigInteger.Create(AInfo.Seeds);
    vResult := vResult + TBigInteger.Create(ASHeight);
    Result := (vResult + FInfo.Seed).AsInt64;
  end;
end;

function TAlgo.ShuffleVotes(AVotes: TArray<TVote>; AHashH: IHashHeight; AInfo: TSeedInfo): TArray<TVote>;
var
  vSeed: Int64;
  L, I, V: Integer;
  vPerm: TArray<Integer>;
begin
  vSeed := FindSeed(AVotes, AHashH.Height, AInfo);
  L := Length(AVotes);
  Randomize(vSeed);
  vPerm := TArray<Integer>.Create;
  SetLength(vPerm, L);
  for I := 0 to L - 1 do vPerm[I] := I;
  for I := L - 1 downto 1 do
  begin
    V := Random(I + 1);
    vPerm[I] := vPerm[V];
    vPerm[V] := I;
  end;

  SetLength(Result, L);
  for I := 0 to L - 1 do
    Result[I] := AVotes[vPerm[I]];
end;

function TAlgo.FilterVotes(AContext: TVoteAlgoContext): TArray<TVote>;
var
  vGroupA, vGroupB: TArray<TVote>;
begin
  FilterSimple(AContext.Votes, vGroupA, vGroupB);
  AContext.SBPs := MergeGroup(vGroupA, vGroupB);

  if Length(vGroupB) = 0 then
  begin
    TArray.Sort<TVote>(vGroupA, TComparer<TVote>.Construct(
      function(const L, R: TVote): Integer
      begin
        Result := R.Balance.CompareTo(L.Balance);
        if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
      end));
    Result := vGroupA;
    Exit;
  end;

  if AContext.SuccessRate <> nil then
    FilterBySuccessRate(vGroupA, vGroupB, AContext.HashH, AContext.SuccessRate);

  Result := FilterRandV2(vGroupA, vGroupB, AContext.HashH, AContext.Seeds, AContext.SuccessRate);
  TArray.Sort<TVote>(Result, TComparer<TVote>.Construct(
    function(const L, R: TVote): Integer
    begin
      Result := R.Balance.CompareTo(L.Balance);
      if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
    end));
end;

procedure TAlgo.FilterSimple(AVotes: TArray<TVote>; out AGroupA, AGroupB: TArray<TVote>);
begin
  TArray.Sort<TVote>(AVotes, TComparer<TVote>.Construct(
    function(const L, R: TVote): Integer
    begin
      Result := R.Balance.CompareTo(L.Balance);
      if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
    end));
  if Length(AVotes) <= FInfo.ConsensusGroupInfo.NodeCount then
  begin
    AGroupA := AVotes;
    AGroupB := nil;
  end
  else
  begin
    AGroupA := TArray<TVote>.Copy(AVotes, 0, FInfo.ConsensusGroupInfo.NodeCount);
    if Length(AVotes) <= FInfo.ConsensusGroupInfo.RandRank then
      AGroupB := TArray<TVote>.Copy(AVotes, FInfo.ConsensusGroupInfo.NodeCount, Length(AVotes) - FInfo.ConsensusGroupInfo.NodeCount)
    else
      AGroupB := TArray<TVote>.Copy(AVotes, FInfo.ConsensusGroupInfo.NodeCount, FInfo.ConsensusGroupInfo.RandRank - FInfo.ConsensusGroupInfo.NodeCount);
  end;
end;

function TAlgo.CalRandCnt(ATotal, ARandNum: Integer): Integer;
begin
  if ATotal div 3 > ARandNum then
    Result := ARandNum
  else
    Result := ATotal div 3;
end;

function TAlgo.FilterRand(AVotes: TArray<TVote>; AHashH: IHashHeight; ASeedInfo: TSeedInfo): TArray<TVote>;
var
  vTotal, vLength, vRandCnt, vTopTotal, vLeftTotal, I, R: Integer;
  vSeed: Int64;
  vRandMembers: TArray<Boolean>;
begin
  vTotal := FInfo.ConsensusGroupInfo.NodeCount;
  TArray.Sort<TVote>(AVotes, TComparer<TVote>.Construct(
    function(const L, R: TVote): Integer
    begin
      Result := R.Balance.CompareTo(L.Balance);
      if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
    end));
  vLength := Length(AVotes);
  if vLength < vTotal then
  begin
    Result := AVotes;
    Exit;
  end;
  vSeed := FindSeed(AVotes, AHashH.Height, ASeedInfo);
  vRandCnt := CalRandCnt(vTotal, FInfo.ConsensusGroupInfo.RandCount);
  vTopTotal := vTotal - vRandCnt;
  vLeftTotal := vLength - vTopTotal;
  SetLength(vRandMembers, vLeftTotal);
  Randomize(vSeed);
  I := 0;
  while I < vRandCnt do
  begin
    R := Random(vLeftTotal);
    if not vRandMembers[R] then
    begin
      vRandMembers[R] := True;
      Inc(I);
    end;
  end;
  Result := TArray<TVote>.Copy(AVotes, 0, vTopTotal);
  for I := 0 to vLeftTotal - 1 do
    if vRandMembers[I] then
      Result := Result + [AVotes[I + vTopTotal]];
end;

function TAlgo.FilterRandV2(AGroupA, AGroupB: TArray<TVote>; AHashH: IHashHeight; ASeedInfo: TSeedInfo; ASuccessRate: TDictionary<TAddress, Integer>): TArray<TVote>;
var
  vTotal, vLength, vRandCnt, vTopTotal, v, I: Integer;
  vSeed: Int64;
  vPerm1, vPerm2: TArray<Integer>;
begin
  if Length(AGroupB) = 0 then
  begin
    Result := AGroupA;
    Exit;
  end;

  vTotal := FInfo.ConsensusGroupInfo.NodeCount;
  TArray.Sort<TVote>(AGroupA, TComparer<TVote>.Construct(
    function(const L, R: TVote): Integer
    begin
      Result := R.Balance.CompareTo(L.Balance);
      if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
    end));
  TArray.Sort<TVote>(AGroupB, TComparer<TVote>.Construct(
    function(const L, R: TVote): Integer
    begin
      Result := R.Balance.CompareTo(L.Balance);
      if Result = 0 then Result := AnsiCompareStr(L.Name, R.Name);
    end));

  vLength := Length(AGroupA) + Length(AGroupB);
  vSeed := FindSeed(MergeGroup(AGroupA, AGroupB), AHashH.Height, ASeedInfo);
  vRandCnt := CalRandCnt(vTotal, FInfo.ConsensusGroupInfo.RandCount);
  vTopTotal := vTotal - vRandCnt;

  SetLength(Result, 0);
  if (vTopTotal * (vLength - vTotal)) > (vRandCnt * vTotal) then
  begin
    Randomize(vSeed);
    vPerm1 := TArray<Integer>.Create;
    SetLength(vPerm1, vTotal);
    for I := 0 to vTotal - 1 do vPerm1[I] := I;
    for I := vTotal - 1 downto 1 do
    begin
      v := Random(I + 1);
      vPerm1[I] := vPerm1[v];
      vPerm1[v] := I;
    end;

    Randomize(vSeed + 1);
    vPerm2 := TArray<Integer>.Create;
    SetLength(vPerm2, vLength - vTotal);
    for I := 0 to (vLength - vTotal) - 1 do vPerm2[I] := I;
    for I := (vLength - vTotal) - 1 downto 1 do
    begin
      v := Random(I + 1);
      vPerm2[I] := vPerm2[v];
      vPerm2[v] := I;
    end;

    for I := 0 to vTopTotal - 1 do
      Result := Result + [AGroupA[vPerm1[I]]];

    for I := 0 to vRandCnt - 1 do
    begin
      AGroupB[vPerm2[I]].Type := AGroupB[vPerm2[I]].Type + [RANDOM_PROMOTION];
      Result := Result + [AGroupB[vPerm2[I]]];
    end;
  end
  else
  begin
    Randomize(vSeed);
    vPerm1 := TArray<Integer>.Create;
    SetLength(vPerm1, vLength);
    for I := 0 to vLength - 1 do vPerm1[I] := I;
    for I := vLength - 1 downto 1 do
    begin
      v := Random(I + 1);
      vPerm1[I] := vPerm1[v];
      vPerm1[v] := I;
    end;

    for I := 0 to vTotal - 1 do
    begin
      v := vPerm1[I];
      if v >= vTotal then
      begin
        AGroupB[v - vTotal].Type := AGroupB[v - vTotal].Type + [RANDOM_PROMOTION];
        Result := Result + [AGroupB[v - vTotal]];
      end
      else
        Result := Result + [AGroupA[v]];
    end;
  end;
end;

procedure TAlgo.FilterBySuccessRate(var AGroupA, AGroupB: TArray<TVote>; AHeight: IHashHeight; ASuccessRate: TDictionary<TAddress, Integer>);
var
  vObsoletedNum, I, lenA: Integer;
  vGroupA1, vDeleteGroupA, vImprovementGroupB, vGroupB1: TList<TSuccessRateVote>;
  vVote: TVote;
  vRate: Integer;
  vSRVote: TSuccessRateVote;
  vDemotion, vPromotion: TSuccessRateVote;
begin
  if Length(AGroupB) = 0 then Exit;
  vObsoletedNum := 2;
  if ASuccessRate.Count < vObsoletedNum then Exit;

  vGroupA1 := TList<TSuccessRateVote>.Create;
  vDeleteGroupA := TList<TSuccessRateVote>.Create;
  vImprovementGroupB := TList<TSuccessRateVote>.Create;
  vGroupB1 := TList<TSuccessRateVote>.Create;
  try
    var vSuccessRateGroupA: TList<TSuccessRateVote> := TList<TSuccessRateVote>.Create;
    try
      for vVote in AGroupA do
      begin
        if not ASuccessRate.TryGetValue(vVote.Addr, vRate) then vRate := -1;
        vSRVote := TSuccessRateVote.Create;
        vSRVote.Vote := vVote;
        vSRVote.Rate := vRate;
        vSuccessRateGroupA.Add(vSRVote);
      end;
      vSuccessRateGroupA.Sort(TComparer<TSuccessRateVote>.Construct(
        function(const L, R: TSuccessRateVote): Integer
        begin
          Result := R.Rate - L.Rate;
          if Result = 0 then
          begin
            Result := R.Vote.Balance.CompareTo(L.Vote.Balance);
            if Result = 0 then Result := AnsiCompareStr(L.Vote.Name, R.Vote.Name);
          end;
        end));

      for I := 0 to vSuccessRateGroupA.Count - 1 - vObsoletedNum do
        vGroupA1.Add(vSuccessRateGroupA[I]);

      for I := vSuccessRateGroupA.Count - vObsoletedNum to vSuccessRateGroupA.Count - 1 do
      begin
        if (vSuccessRateGroupA[I].Rate >= 0) and (vSuccessRateGroupA[I].Rate < Line) then
          vDeleteGroupA.Add(vSuccessRateGroupA[I])
        else
          vGroupA1.Add(vSuccessRateGroupA[I]);
      end;
    finally
      vSuccessRateGroupA.Free;
    end;

    var vSuccessRateGroupB: TList<TSuccessRateVote> := TList<TSuccessRateVote>.Create;
    try
      for vVote in AGroupB do
      begin
        if not ASuccessRate.TryGetValue(vVote.Addr, vRate) then vRate := -1;
        vSRVote := TSuccessRateVote.Create;
        vSRVote.Vote := vVote;
        vSRVote.Rate := vRate;
        vSuccessRateGroupB.Add(vSRVote);
      end;
      vSuccessRateGroupB.Sort(TComparer<TSuccessRateVote>.Construct(
        function(const L, R: TSuccessRateVote): Integer
        begin
          Result := R.Rate - L.Rate;
          if Result = 0 then
          begin
            Result := R.Vote.Balance.CompareTo(L.Vote.Balance);
            if Result = 0 then Result := AnsiCompareStr(L.Vote.Name, R.Vote.Name);
          end;
        end));

      for vSRVote in vSuccessRateGroupB do
      begin
        if vImprovementGroupB.Count >= vObsoletedNum then
        begin
          vGroupB1.Add(vSRVote);
          Continue;
        end;
        if vSRVote.Rate > Line then
          vImprovementGroupB.Add(vSRVote)
        else
          vGroupB1.Add(vSRVote);
      end;
    finally
      vSuccessRateGroupB.Free;
    end;

    for I := 1 to vObsoletedNum do
    begin
      lenA := vDeleteGroupA.Count;
      if (lenA < I) or (vImprovementGroupB.Count < I) then Break;
      vDemotion := vDeleteGroupA[lenA - I];
      vPromotion := vImprovementGroupB[I - 1];
      vPromotion.Vote.Type := vPromotion.Vote.Type + [SUCCESS_RATE_PROMOTION];
      vDemotion.Vote.Type := vDemotion.Vote.Type + [SUCCESS_RATE_DEMOTION];
      vDeleteGroupA[lenA - I] := vPromotion;
      vImprovementGroupB[I - 1] := vDemotion;
    end;

    SetLength(AGroupA, 0);
    SetLength(AGroupB, 0);
    for vSRVote in vGroupA1 do AGroupA := AGroupA + [vSRVote.Vote];
    for vSRVote in vDeleteGroupA do AGroupA := AGroupA + [vSRVote.Vote];
    for vSRVote in vGroupB1 do AGroupB := AGroupB + [vSRVote.Vote];
    for vSRVote in vImprovementGroupB do AGroupB := AGroupB + [vSRVote.Vote];

  finally
    vGroupA1.Free;
    vDeleteGroupA.Free;
    vImprovementGroupB.Free;
    vGroupB1.Free;
  end;
end;

function TAlgo.CheckValid(AGroupA, AGroupB: TArray<TVote>): Boolean;
var
  lenA, lenB: Integer;
begin
  lenA := Length(AGroupA);
  lenB := Length(AGroupB);
  if lenA > FInfo.ConsensusGroupInfo.NodeCount then Exit(False);
  if (lenA < FInfo.ConsensusGroupInfo.NodeCount) and (lenB > 0) then Exit(False);
  if (lenB + lenA) > FInfo.ConsensusGroupInfo.RandRank then Exit(False);
  Result := True;
end;

function MergeGroup(AGroupA, AGroupB: TArray<TVote>): TArray<TVote>;
var
  lenA: Integer;
  I: Integer;
begin
  lenA := Length(AGroupA);
  SetLength(Result, lenA + Length(AGroupB));
  for I := 0 to lenA - 1 do Result[I] := AGroupA[I];
  for I := 0 to Length(AGroupB) - 1 do Result[I + lenA] := AGroupB[I];
end;

end.
