unit VM.Contracts.Reward.Test;

interface

procedure RunRewardTests;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Ledger, GoVite.VM, GoVite.Consensus, // Assumed units
  VM.Contracts.Reward, // Assumed unit with reward calculation logic
  DUnitX.TestFramework;

// Mock implementations from the Go test
type
  TConsensusDetail = record
    BlockNum: UInt64;
    ExpectedBlockNum: UInt64;
    VoteCount: TBigInteger;
  end;

  TTimeIndex = class(TInterfacedObject, ITimeIndex)
  private
    FGenesisTime: TDateTime;
    FInterval: TTimeSpan;
  public
    constructor Create(AGenesisTime: Int64; AInterval: Int64);
    function Index2Time(AIndex: UInt64): TPair<TDateTime, TDateTime>;
    function Time2Index(ATime: TDateTime): UInt64;
  end;

  TConsensusReaderTest = class(TInterfacedObject, IVmConsensusReader)
  private
    FDetailMap: TDictionary<UInt64, TDictionary<string, TConsensusDetail>>;
    FTimeIndex: ITimeIndex;
  public
    constructor Create(AGenesisTime, AInterval: Int64; ADetailMap: TDictionary<UInt64, TDictionary<string, TConsensusDetail>>);
    destructor Destroy; override;
    function DayStats(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
    function GetDayTimeIndex: ITimeIndex;
  end;
  
// ... Implementation of mock objects ...

procedure TestCalcRewardByDay;
var
  // ... Test setup code similar to Go test ...
begin
  // ... Implementation of the test case iteration and assertions ...
end;

procedure TestCalcRewardSingle;
var
  // ... Variable declarations ...
begin
  // ... Implementation of the single reward calculation and assertions ...
end;

procedure TestGetIndexByStartTime;
var
  // ... Test setup ...
begin
  // ... Implementation of the test cases and assertions for GetIndexByStartTime ...
end;

procedure TestGetIndexByEndTime;
var
  // ... Test setup ...
begin
  // ... Implementation of the test cases and assertions for GetIndexByEndTime ...
end;

procedure RunRewardTests;
begin
  TestCalcRewardByDay;
  TestCalcRewardSingle;
  TestGetIndexByStartTime;
  TestGetIndexByEndTime;
end;

{ TTimeIndex }
constructor TTimeIndex.Create(AGenesisTime, AInterval: Int64);
begin
  FGenesisTime := TDateTime.FromUnix(AGenesisTime);
  FInterval := TTimeSpan.FromSeconds(AInterval);
end;

function TTimeIndex.Index2Time(AIndex: UInt64): TPair<TDateTime, TDateTime>;
var
  StartTime, EndTime: TDateTime;
begin
  StartTime := FGenesisTime + (FInterval * AIndex);
  EndTime := StartTime + FInterval;
  Result := TPair<TDateTime, TDateTime>.Create(StartTime, EndTime);
end;

function TTimeIndex.Time2Index(ATime: TDateTime): UInt64;
var
  SubSec: Int64;
begin
  SubSec := Round((ATime - FGenesisTime) * SecsPerDay);
  Result := SubSec div Round(FInterval.TotalSeconds);
end;

{ TConsensusReaderTest }
constructor TConsensusReaderTest.Create(AGenesisTime, AInterval: Int64; ADetailMap: TDictionary<UInt64, TDictionary<string, TConsensusDetail>>);
begin
  FTimeIndex := TTimeIndex.Create(AGenesisTime, AInterval);
  FDetailMap := ADetailMap;
end;

destructor TConsensusReaderTest.Destroy;
begin
  FDetailMap.Free;
  inherited;
end;

function TConsensusReaderTest.DayStats(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
var
  I: UInt64;
  StatsMap: TDictionary<string, TSbpStats>;
  // ... other vars ...
begin
  // Mock implementation to return canned data from FDetailMap
end;

function TConsensusReaderTest.GetDayTimeIndex: ITimeIndex;
begin
  Result := FTimeIndex;
end;


end.
