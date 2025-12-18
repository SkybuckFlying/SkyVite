unit Monitor.Monitor;

interface

uses
  Log15 Ring,
  Monitor.Monitor.Test,
  Monitor.Ntp,
  Monitor.Ring,
  Monitor.Ring.Test,
  System.SysUtils System.Classes System.Generics.Collections System.Diagnostics System.Threading;

type
  TMsg = class
  private
    mCnt: Int64;
    mSum: Int64;
  public
    constructor Create;
    procedure Add(ParaI: Int64);
    procedure Merge(ParaMs: TMsg);
    function ToString: string;
    procedure Reset;
    function Snapshot: TMsg;
    property Cnt: Int64 read mCnt;
    property Sum: Int64 read mSum;
  end;

  TStat = class
  public
    Cnt: Int64;
    Avg: Double;
  end;

  TMonitor = class
  private
    mMs: TThreadedDictionary<string, TMsg>;
    mRing: TRing;
    mLogger: ILogger;
    mLoopTask: ITask;
    procedure Loop;
    procedure Log(ParaT, ParaName: string; ParaI: Int64);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LogEvent(ParaT, ParaName: string);
    procedure LogEventNum(ParaT, ParaName: string; ParaNum: Integer);
    procedure LogTime(ParaT, ParaName: string; ParaTm: TStopwatch);
    procedure LogDuration(ParaT, ParaName: string; ParaDuration: Int64);
    function Stat: TDictionary<string, TMsg>;
    function StatJson: string;
  end;

function Monitor: TMonitor;

implementation

uses
  System.Json;

var
  gMonitor: TMonitor;

function Monitor: TMonitor;
begin
  Result := gMonitor;
end;

{ TMsg }

constructor TMsg.Create;
begin
  inherited Create;
  mCnt := 0;
  mSum := 0;
end;

procedure TMsg.Add(ParaI: Int64);
begin
  TInterlocked.Add(mCnt, 1);
  TInterlocked.Add(mSum, ParaI);
end;

procedure TMsg.Merge(ParaMs: TMsg);
begin
  TInterlocked.Add(mCnt, ParaMs.mCnt);
  TInterlocked.Add(mSum, ParaMs.mSum);
end;

function TMsg.ToString: string;
begin
  Result := '{"Cnt":' + IntToStr(mCnt) + ',"Sum":' + IntToStr(mSum) + '}';
end;

procedure TMsg.Reset;
begin
  TInterlocked.Exchange(mSum, 0);
  TInterlocked.Exchange(mCnt, 0);
end;

function TMsg.Snapshot: TMsg;
begin
  Result := TMsg.Create;
  Result.mCnt := mCnt;
  Result.mSum := mSum;
end;

{ TMonitor }

constructor TMonitor.Create;
begin
  inherited Create;
  mMs := TThreadedDictionary<string, TMsg>.Create;
  mRing := TRing.Create(60);
  mLogger := Log15.Root;
  mLoopTask := TTask.Run(Loop);
end;

destructor TMonitor.Destroy;
begin
  if mLoopTask <> nil then
  begin
    mLoopTask.Cancel;
    mLoopTask.Wait;
  end;
  mMs.Free;
  mRing.Free;
  inherited Destroy;
end;

procedure TMonitor.Loop;
var
  vSnapshot: TDictionary<string, TMsg>;
  vPair: TPair<string, TMsg>;
  vSm: TMsg;
begin
  while not TTask.Current.IsCanceled do
  begin
    TThread.Sleep(1000);
    vSnapshot := TDictionary<string, TMsg>.Create;
    try
      for vPair in mMs do
      begin
        mLogger.Info('', 'group', vPair.Key, 'interval', 1, 'name', vPair.Key,
          'metric-cnt', vPair.Value.Cnt,
          'metric-sum', vPair.Value.Sum);
        vSm := vPair.Value.Snapshot;
        vSnapshot.Add(vPair.Key, vSm);
        vPair.Value.Reset;
      end;
      mRing.Add(vSnapshot);
    except
      vSnapshot.Free;
      raise;
    end;
  end;
end;

procedure TMonitor.Log(ParaT, ParaName: string; ParaI: Int64);
var
  vKey: string;
  vValue: TMsg;
begin
  vKey := ParaT + '-' + ParaName;
  if not mMs.TryGetValue(vKey, vValue) then
  begin
    vValue := TMsg.Create;
    if mMs.TryAdd(vKey, vValue) then
    begin
      // Successfully added
    end
    else
    begin
      // Another thread added it, so get the existing one
      vValue := mMs.Items[vKey];
    end;
  end;
  vValue.Add(ParaI);
end;

procedure TMonitor.LogEvent(ParaT, ParaName: string);
begin
  Log(ParaT, ParaName, 1);
end;

procedure TMonitor.LogEventNum(ParaT, ParaName: string; ParaNum: Integer);
begin
  Log(ParaT, ParaName, ParaNum);
end;

procedure TMonitor.LogTime(ParaT, ParaName: string; ParaTm: TStopwatch);
begin
  Log(ParaT, ParaName, ParaTm.Elapsed.Ticks);
end;

procedure TMonitor.LogDuration(ParaT, ParaName: string; ParaDuration: Int64);
begin
  Log(ParaT, ParaName, ParaDuration);
end;

function TMonitor.Stat: TDictionary<string, TMsg>;
var
  vAll: TArray<TObject>;
  vMsgs: TDictionary<string, TMsg>;
  vValue: TObject;
  vMsgM: TDictionary<string, TMsg>;
  vKey: string;
  vMsg, vTmpMsg: TMsg;
begin
  vAll := mRing.All;
  vMsgs := TDictionary<string, TMsg>.Create;
  try
    for vValue in vAll do
    begin
      vMsgM := vValue as TDictionary<string, TMsg>;
      for vKey in vMsgM.Keys do
      begin
        vMsg := vMsgM[vKey];
        if vMsgs.TryGetValue(vKey, vTmpMsg) then
          vTmpMsg.Merge(vMsg)
        else
          vMsgs.Add(vKey, vMsg);
      end;
    end;
    Result := vMsgs;
  finally
    vMsgs.Free;
  end;
end;

function TMonitor.StatJson: string;
var
  vAll: TArray<TObject>;
  vMsgs: TDictionary<string, TMsg>;
  vValue: TObject;
  vMsgM: TDictionary<string, TMsg>;
  vKey: string;
  vMsg, vTmpMsg: TMsg;
  vS: TMsg;
  vRes: TObjectDictionary<string, TStat>;
  vStat: TStat;
  vJsonObj: TJsonObject;
begin
  vAll := mRing.All;
  vMsgs := TDictionary<string, TMsg>.Create;
  try
    for vValue in vAll do
    begin
      vMsgM := vValue as TDictionary<string, TMsg>;
      for vKey in vMsgM.Keys do
      begin
        vMsg := vMsgM[vKey];
        if vMsgs.TryGetValue(vKey, vTmpMsg) then
          vTmpMsg.Merge(vMsg)
        else
        begin
          vS := vMsg.Snapshot;
          vMsgs.Add(vKey, vS);
        end;
      end;
    end;

    vRes := TObjectDictionary<string, TStat>.Create([doOwnsValues]);
    try
      for vKey in vMsgs.Keys do
      begin
        vMsg := vMsgs[vKey];
        if vMsg.Cnt <> 0 then
        begin
          vStat := TStat.Create;
          vStat.Cnt := vMsg.Cnt;
          vStat.Avg := vMsg.Sum / vMsg.Cnt;
          vRes.Add(vKey, vStat);
        end;
      end;

      vJsonObj := TJsonObject.Create;
      try
        for vKey in vRes.Keys do
        begin
          vStat := vRes[vKey];
          vJsonObj.AddPair(vKey, TJsonObject.Create([
            TJSONPair.Create('Cnt', TJSONNumber.Create(vStat.Cnt)),
            TJSONPair.Create('Avg', TJSONNumber.Create(vStat.Avg))
          ]));
        end;
        Result := vJsonObj.ToString;
      finally
        vJsonObj.Free;
      end;
    finally
      vRes.Free;
    end;
  finally
    vMsgs.Free;
  end;
end;

initialization
  gMonitor := TMonitor.Create;
finalization
  gMonitor.Free;
end.
