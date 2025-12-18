unit RpcApi.Api.Stats;

interface

uses
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite Ledger.Consensus Log15 Ledger.Consensus.Core Common.Types;

type
  TPeriodStats = record
    PeriodStats: TCorePeriodStats;
    Stime: TDateTime;
    Etime: TDateTime;
  end;

  TStatsApi = class
  private
    FCs: IConsensus;
    FLog: ILogger;
    function ReIndex(TimeIndex: ITimeIndex): TPair<UInt64, UInt64>;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function Time2Index(T: PDateTime; Level: Integer): UInt64;
    function Index2Time(I: UInt64; Level: Integer): TDictionary<string, TDateTime>;
    function GetHourSBPStats(StartIdx, EndIdx: UInt64): TArray<TDictionary<string, TValue>>;
    function GetPeriodSBPStats(StartIdx, EndIdx: UInt64): TArray<TPeriodStats>;
    function GetDaySBPStats(StartIdx, EndIdx: UInt64): TArray<TDictionary<string, TValue>>;
    function GetSBP(Idx: UInt64): TObject;
  end;

implementation

uses System.DateUtils;

{ TStatsApi }

constructor TStatsApi.Create(AVite: TVite);
begin
  FCs := AVite.Consensus;
  FLog := TLog.New('module', 'rpc_api/stats_api');
end;

function TStatsApi.GetString: string;
begin
  Result := 'StatsApi';
end;

function TStatsApi.Time2Index(T: PDateTime; Level: Integer): UInt64;
var
  NowTime: TDateTime;
  Index: ITimeIndex;
begin
  if T = nil then
  begin
    NowTime := Now;
    T := @NowTime;
  end;
  case Level of
    0: Index := FCs.SBPReader.GetPeriodTimeIndex;
    1: Index := FCs.SBPReader.GetHourTimeIndex;
    2: Index := FCs.SBPReader.GetDayTimeIndex;
  else
    Exit(0);
  end;
  Result := Index.Time2Index(T^);
end;

function TStatsApi.Index2Time(I: UInt64; Level: Integer): TDictionary<string, TDateTime>;
var
  Index: ITimeIndex;
  Stime, Etime: TDateTime;
begin
  Result := TDictionary<string, TDateTime>.Create;
  case Level of
    0: Index := FCs.SBPReader.GetPeriodTimeIndex;
    1: Index := FCs.SBPReader.GetHourTimeIndex;
    2: Index := FCs.SBPReader.GetDayTimeIndex;
  else
    Exit(nil);
  end;
  Index.Index2Time(I, Stime, Etime);
  Result.Add('stime', Stime);
  Result.Add('etime', Etime);
end;

function TStatsApi.GetHourSBPStats(StartIdx, EndIdx: UInt64): TArray<TDictionary<string, TValue>>;
var
  Reader: ISBPReader;
  TimeIndex: ITimeIndex;
  Stats: TArray<TCoreHourStats>;
  V: TCoreHourStats;
  R: TDictionary<string, TValue>;
  Stime, Etime: TDateTime;
begin
  Reader := FCs.SBPReader;
  TimeIndex := Reader.GetHourTimeIndex;
  if StartIdx > EndIdx then
  begin
    var Pair := ReIndex(TimeIndex);
    StartIdx := Pair.Key;
    EndIdx := Pair.Value;
  end;
  Stats := Reader.HourStats(StartIdx, EndIdx);
  SetLength(Result, Length(Stats));
  var I := 0;
  for V in Stats do
  begin
    R := TDictionary<string, TValue>.Create;
    TimeIndex.Index2Time(V.Index, Stime, Etime);
    R.Add('stime', Stime.ToString);
    R.Add('etime', Etime.ToString);
    R.Add('stat', TValue.From<TCoreHourStats>(V));
    Result[I] := R;
    Inc(I);
  end;
end;

function TStatsApi.GetPeriodSBPStats(StartIdx, EndIdx: UInt64): TArray<TPeriodStats>;
var
  Reader: ISBPReader;
  TimeIndex: ITimeIndex;
  Stats: TArray<TCorePeriodStats>;
  V: TCorePeriodStats;
  Stime, Etime: TDateTime;
begin
  if (EndIdx > StartIdx) and (EndIdx - StartIdx > 48) then
    raise Exception.Create('max step is 48');
  Reader := FCs.SBPReader;
  TimeIndex := Reader.GetPeriodTimeIndex;
  if StartIdx > EndIdx then
  begin
    var Pair := ReIndex(TimeIndex);
    StartIdx := Pair.Key;
    EndIdx := Pair.Value;
  end;
  Stats := Reader.PeriodStats(StartIdx, EndIdx);
  SetLength(Result, Length(Stats));
  var I := 0;
  for V in Stats do
  begin
    TimeIndex.Index2Time(V.Index, Stime, Etime);
    Result[I].PeriodStats := V;
    Result[I].Stime := Stime;
    Result[I].Etime := Etime;
    Inc(I);
  end;
end;

function TStatsApi.GetDaySBPStats(StartIdx, EndIdx: UInt64): TArray<TDictionary<string, TValue>>;
var
  Reader: ISBPReader;
  TimeIndex: ITimeIndex;
  Stats: TArray<TCoreDayStats>;
  V: TCoreDayStats;
  R: TDictionary<string, TValue>;
  Stime, Etime: TDateTime;
begin
  Reader := FCs.SBPReader;
  TimeIndex := Reader.GetDayTimeIndex;
  if StartIdx > EndIdx then
  begin
    var Pair := ReIndex(TimeIndex);
    StartIdx := Pair.Key;
    EndIdx := Pair.Value;
  end;
  Stats := Reader.DayStats(StartIdx, EndIdx);
  SetLength(Result, Length(Stats));
  var I := 0;
  for V in Stats do
  begin
    R := TDictionary<string, TValue>.Create;
    TimeIndex.Index2Time(V.Index, Stime, Etime);
    R.Add('stime', Stime.ToString);
    R.Add('etime', Etime.ToString);
    R.Add('stat', TValue.From<TCoreDayStats>(V));
    Result[I] := R;
    Inc(I);
  end;
end;

function TStatsApi.ReIndex(TimeIndex: ITimeIndex): TPair<UInt64, UInt64>;
var
  StartIdx, EndIdx, N: UInt64;
begin
  StartIdx := 0;
  EndIdx := TimeIndex.Time2Index(Now);
  N := 5;
  if EndIdx >= N then
    StartIdx := EndIdx - N;
  Result := TPair.Create(StartIdx, EndIdx);
end;

function TStatsApi.GetSBP(Idx: UInt64): TObject;
var
  Events: TObject;
  Gid: TGid;
begin
  Gid := TTypes.SNAPSHOT_GID;
  Events := FCs.API.ReadByIndex(Gid, Idx);
  Result := Events;
end;

end.
