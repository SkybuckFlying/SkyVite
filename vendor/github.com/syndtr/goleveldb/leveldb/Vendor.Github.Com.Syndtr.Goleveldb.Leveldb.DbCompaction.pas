unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.TimeSpan,
  System.DateUtils;

type
  TcStatStaging = record
    start: TDateTime;
    duration: TTimeSpan;
    on_: Boolean;
    read: Int64;
    write: Int64;
    procedure StartTimer;
    procedure StopTimer;
  end;
  PcStatStaging = ^TcStatStaging;

  TcStat = record
    duration: TTimeSpan;
    read: Int64;
    write: Int64;
    procedure Add(n: PcStatStaging);
    procedure Get(out vDuration: TTimeSpan; out vRead, vWrite: Int64);
  end;

  TcStats = class
  private
    mLk: TCriticalSection;
    mStats: TArray<TcStat>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddStat(level: Integer; n: PcStatStaging);
    procedure GetStat(level: Integer; out vDuration: TTimeSpan; out vRead, vWrite: Int64);
  end;

  TCompactionTransactCounter = type Integer;
  PCompactionTransactCounter = ^TCompactionTransactCounter;

  ICompactionTransact = interface
    ['{8E4E5868-9F31-4BD3-9D1B-5E7981577134}']
    function Run(cnt: PCompactionTransactCounter): Exception;
    function Revert: Exception;
  end;

implementation

{ TcStatStaging }

procedure TcStatStaging.StartTimer;
begin
  if not on_ then
  begin
    start := Now;
    on_ := True;
  end;
end;

procedure TcStatStaging.StopTimer;
begin
  if on_ then
  begin
    duration := duration + TTimeSpan.Subtract(Now, start);
    on_ := False;
  end;
end;

{ TcStat }

procedure TcStat.Add(n: PcStatStaging);
begin
  duration := duration + n.duration;
  read := read + n.read;
  write := write + n.write;
end;

procedure TcStat.Get(out vDuration: TTimeSpan; out vRead, vWrite: Int64);
begin
  vDuration := duration;
  vRead := read;
  vWrite := write;
end;

{ TcStats }

constructor TcStats.Create;
begin
  mLk := TCriticalSection.Create;
end;

destructor TcStats.Destroy;
begin
  mLk.Free;
  inherited;
end;

procedure TcStats.AddStat(level: Integer; n: PcStatStaging);
var
  vNewStats: TArray<TcStat>;
begin
  mLk.Enter;
  try
    if level >= Length(mStats) then
    begin
      SetLength(vNewStats, level + 1);
      if Length(mStats) > 0 then
        Move(mStats[0], vNewStats[0], Length(mStats) * SizeOf(TcStat));
      mStats := vNewStats;
    end;
    mStats[level].Add(n);
  finally
    mLk.Leave;
  end;
end;

procedure TcStats.GetStat(level: Integer; out vDuration: TTimeSpan; out vRead, vWrite: Int64);
begin
  mLk.Enter;
  try
    if level < Length(mStats) then
      mStats[level].Get(vDuration, vRead, vWrite)
    else
    begin
      vDuration := TTimeSpan.Zero;
      vRead := 0;
      vWrite := 0;
    end;
  finally
    mLk.Leave;
  end;
end;

end.
