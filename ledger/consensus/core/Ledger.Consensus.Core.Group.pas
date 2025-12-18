unit Ledger.Consensus.Core.Group;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  BigNumbers,
  Common.Types,
  Ledger.Consensus.Core.TimeIndex;

type
  TMemberPlan = record
    STime: TDateTime;
    ETime: TDateTime;
    Member: TAddress;
    Name: string;
  end;

  TGroupInfo = class
  private
    FTimeIndex: ITimeIndex;
    FConsensusGroupInfo: TConsensusGroupInfo;
    FGenesisTime: TDateTime;
    FSeed: TBigInteger;
    FPlanInterval: UInt64;

    function GetPlanInterval: UInt64;
    class function CalculatePlanInterval(const AInfo: TConsensusGroupInfo): UInt64;
  public
    constructor Create(const AGenesisTime: TDateTime; const AInfo: TConsensusGroupInfo);
    function GenPlan(AIndex: UInt64; const AMembers: TArray<TVote>): TArray<TMemberPlan>;
    function GenPlanByAddress(AIndex: UInt64; const AMembers: TArray<TAddress>): TArray<TMemberPlan>;
    function ToString: string; override;

    property TimeIndex: ITimeIndex read FTimeIndex;
    property ConsensusGroupInfo: TConsensusGroupInfo read FConsensusGroupInfo;
    property GenesisTime: TDateTime read FGenesisTime;
    property Seed: TBigInteger read FSeed;
    property PlanInterval: UInt64 read GetPlanInterval;
  end;

implementation

{ TGroupInfo }

constructor TGroupInfo.Create(const AGenesisTime: TDateTime; const AInfo: TConsensusGroupInfo);
begin
  FConsensusGroupInfo := AInfo;
  FGenesisTime := AGenesisTime;
  FSeed := TBigInteger.Create(AInfo.Gid.Bytes);
  FPlanInterval := CalculatePlanInterval(AInfo);
  FTimeIndex := TTimeIndex.Create(AGenesisTime, TTimeSpan.FromSeconds(FPlanInterval));
end;

function TGroupInfo.GetPlanInterval: UInt64;
begin
  Result := FPlanInterval;
end;

class function TGroupInfo.CalculatePlanInterval(const AInfo: TConsensusGroupInfo): UInt64;
begin
  Result := AInfo.Interval * AInfo.NodeCount * AInfo.PerCount * AInfo.Repeat;
end;

function TGroupInfo.GenPlan(AIndex: UInt64; const AMembers: TArray<TVote>): TArray<TMemberPlan>;
var
  vSTime, vETime: TDateTime;
  vMember: TVote;
  I: Integer;
begin
  vSTime := FTimeIndex.Index2Time(AIndex);
  SetLength(Result, 0);
  for vMember in AMembers do
  begin
    for I := 1 to Self.FConsensusGroupInfo.PerCount do
    begin
      vETime := vSTime + TTimeSpan.FromSeconds(Self.FConsensusGroupInfo.Interval);
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := TMemberPlan.Create(vSTime, vETime, vMember.Addr, vMember.Name);
      vSTime := vETime;
    end;
  end;
end;

function TGroupInfo.GenPlanByAddress(AIndex: UInt64; const AMembers: TArray<TAddress>): TArray<TMemberPlan>;
var
  vSTime, vETime: TDateTime;
  vMember: TAddress;
  I: Integer;
  J: Word;
begin
  if Length(AMembers) > Self.FConsensusGroupInfo.NodeCount then
  begin
    // Error condition
    Result := nil;
    Exit;
  end;

  vSTime := FTimeIndex.Index2Time(AIndex);
  SetLength(Result, 0);
  for J := 1 to Self.FConsensusGroupInfo.Repeat do
  begin
    for vMember in AMembers do
    begin
      for I := 1 to Self.FConsensusGroupInfo.PerCount do
      begin
        vETime := vSTime + TTimeSpan.FromSeconds(Self.FConsensusGroupInfo.Interval);
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := TMemberPlan.Create(vSTime, vETime, vMember, '');
        vSTime := vETime;
      end;
    end;
    if Length(AMembers) < Self.FConsensusGroupInfo.NodeCount then
    begin
      vSTime := vSTime + TTimeSpan.FromSeconds(Self.FConsensusGroupInfo.Interval * Self.FConsensusGroupInfo.PerCount * (Self.FConsensusGroupInfo.NodeCount - Length(AMembers)));
    end;
  end;
end;

function TGroupInfo.ToString: string;
begin
  Result := Format('genesisTime:%s, memberCnt:%d, interval:%d, perCnt:%d, randCnt:%d, randRange:%d, seed:%s, countingTokenId:%s',
    [DateTimeToStr(FGenesisTime), FConsensusGroupInfo.NodeCount, FConsensusGroupInfo.Interval, FConsensusGroupInfo.PerCount, FConsensusGroupInfo.RandCount, FConsensusGroupInfo.RandRank, FSeed.ToString, FConsensusGroupInfo.CountingTokenId.ToString]);
end;

end.
