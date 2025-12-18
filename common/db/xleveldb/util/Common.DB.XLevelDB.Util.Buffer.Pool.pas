unit common.db.xleveldb.util.buffer_pool;

interface

uses
  Common.DB.XLevelDB.Util.Buffer,
  Common.DB.XLevelDB.Util.Crc32,
  Common.DB.XLevelDB.Util.Hash,
  Common.DB.XLevelDB.Util.Range,
  Common.DB.XLevelDB.Util.Util,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading;

type
  TBufferPool = class
  private
    FPool: array [0 .. 5] of TThreadedQueue<TBytes>;
    FSize: array [0 .. 4] of Cardinal;
    FSizeMiss: array [0 .. 4] of Cardinal;
    FSizeHalf: array [0 .. 4] of Cardinal;
    FBaseline: array [0 .. 3] of Integer;
    FBaseline0: Integer;
    FMu: TRTLCriticalSection;
    FClosed: Boolean;
    FCloseC: TEvent;
    FGet, FPut, FHalf, FLess, FEqual, FGreater, FMiss: Cardinal;
    function PoolNum(N: Integer): Integer;
    procedure Drain;
  public
    constructor Create(ABaseline: Integer);
    destructor Destroy; override;
    function Get(N: Integer): TBytes;
    procedure Put(const B: TBytes);
    procedure Close;
    function ToString: string;
  end;

function NewBufferPool(ABaseline: Integer): TBufferPool;

implementation

{ TBufferPool }

constructor TBufferPool.Create(ABaseline: Integer);
var
  I: Integer;
  Caps: array [0 .. 5] of Integer;
begin
  inherited Create;
  if ABaseline <= 0 then
    raise Exception.Create('baseline can''t be <= 0');

  InitializeCriticalSection(FMu);
  FBaseline0 := ABaseline;
  FBaseline[0] := ABaseline div 4;
  FBaseline[1] := ABaseline div 2;
  FBaseline[2] := ABaseline * 2;
  FBaseline[3] := ABaseline * 4;
  FCloseC := TEvent.Create(nil, True, False, '');

  Caps[0] := 2;
  Caps[1] := 2;
  Caps[2] := 4;
  Caps[3] := 4;
  Caps[4] := 2;
  Caps[5] := 1;

  for I := 0 to 5 do
    FPool[I] := TThreadedQueue<TBytes>.Create(Caps[I]);

  TTask.Run(procedure
    begin
      Drain;
    end);
end;

destructor TBufferPool.Destroy;
var
  I: Integer;
begin
  Close;
  for I := 0 to 5 do
    FPool[I].Free;
  FCloseC.Free;
  DeleteCriticalSection(FMu);
  inherited;
end;

function TBufferPool.PoolNum(N: Integer): Integer;
var
  I: Integer;
begin
  if (N <= FBaseline0) and (N > FBaseline0 div 2) then
    Result := 0
  else
  begin
    Result := -1;
    for I := 0 to High(FBaseline) do
    begin
      if N <= FBaseline[I] then
      begin
        Result := I + 1;
        Exit;
      end;
    end;
    if Result = -1 then
      Result := Length(FBaseline) + 1;
  end;
end;

function TBufferPool.Get(N: Integer): TBytes;
var
  PoolNum: Integer;
  Pool: TThreadedQueue<TBytes>;
  B: TBytes;
  SizePtr: PCardinal;
  SizeHalfPtr: PCardinal;
  SizeMissPtr: PCardinal;
  Size: Cardinal;
begin
  EnterCriticalSection(FMu);
  try
    if FClosed then
    begin
      SetLength(Result, N);
      Exit;
    end;
  finally
    LeaveCriticalSection(FMu);
  end;

  TInterlocked.Increment(FGet);

  PoolNum := PoolNum(N);
  Pool := FPool[PoolNum];

  if Pool.PopItem(B) = TWaitResult.wrSignaled then
  begin
    if System.Capacity(B) > N then
    begin
      if System.Capacity(B) - N >= N then
      begin
        TInterlocked.Increment(FHalf);
        Pool.PushItem(B);
        SetLength(Result, N);
      end
      else
      begin
        TInterlocked.Increment(FLess);
        SetLength(B, N);
        Result := B;
      end;
    end
    else if System.Capacity(B) = N then
    begin
      TInterlocked.Increment(FEqual);
      SetLength(B, N);
      Result := B;
    end
    else
    begin
      TInterlocked.Increment(FGreater);
      if PoolNum > 0 then
      begin
        SizePtr := @FSize[PoolNum - 1];
        if System.Capacity(B) >= TInterlocked.Read(SizePtr^) then
          Pool.PushItem(B);
      end;
      SetLength(Result, N);
    end;
  end
  else
  begin
    TInterlocked.Increment(FMiss);
    if PoolNum = 0 then
      SetLength(Result, N, FBaseline0)
    else
    begin
      SizePtr := @FSize[PoolNum - 1];
      Size := TInterlocked.Read(SizePtr^);
      if Cardinal(N) > Size then
      begin
        if Size = 0 then
          TInterlocked.CompareExchange(SizePtr^, N, 0)
        else
        begin
          SizeMissPtr := @FSizeMiss[PoolNum - 1];
          if TInterlocked.Increment(SizeMissPtr^) = 20 then
          begin
            TInterlocked.Exchange(SizePtr^, N);
            TInterlocked.Exchange(SizeMissPtr^, 0);
          end;
        end;
        SetLength(Result, N);
      end
      else
        SetLength(Result, N, Size);
    end;
  end;
end;

procedure TBufferPool.Put(const B: TBytes);
var
  Pool: TThreadedQueue<TBytes>;
begin
  EnterCriticalSection(FMu);
  try
    if FClosed then
      Exit;
  finally
    LeaveCriticalSection(FMu);
  end;

  TInterlocked.Increment(FPut);
  Pool := FPool[PoolNum(System.Capacity(B))];
  Pool.PushItem(B);
end;

procedure TBufferPool.Close;
begin
  EnterCriticalSection(FMu);
  try
    if not FClosed then
    begin
      FClosed := True;
      FCloseC.SetEvent;
    end;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TBufferPool.ToString: string;
begin
  Result := Format('BufferPool{B·%d Z·%s Zm·%s Zh·%s G·%d P·%d H·%d <·%d =·%d >·%d M·%d}',
    [FBaseline0, '', '', '', FGet, FPut, FHalf, FLess, FEqual, FGreater, FMiss]);
end;

procedure TBufferPool.Drain;
var
  I: Integer;
  B: TBytes;
begin
  while True do
  begin
    if FCloseC.WaitFor(2000) = TWaitResult.wrSignaled then
    begin
      for I := 0 to 5 do
        FPool[I].Free;
      Exit;
    end;

    for I := 0 to 5 do
      FPool[I].PopItem(B);
  end;
end;

function NewBufferPool(ABaseline: Integer): TBufferPool;
begin
  Result := TBufferPool.Create(ABaseline);
end;

end.
