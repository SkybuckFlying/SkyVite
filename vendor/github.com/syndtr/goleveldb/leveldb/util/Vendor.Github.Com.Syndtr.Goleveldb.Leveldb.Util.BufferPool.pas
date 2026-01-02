unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.BufferPool;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes, System.Threading;

type
  TBuffer = record
    B: TBytes;
    Miss: Integer;
  end;

  /// <summary>
  /// BufferPool is a 'buffer pool'.
  /// </summary>
  TBufferPool = class
  private
    FPool: array [0 .. 5] of TThreadedQueue<TBytes>;
    FSize: array [0 .. 4] of UInt32;
    FSizeMiss: array [0 .. 4] of UInt32;
    FSizeHalf: array [0 .. 4] of UInt32;
    FBaseline: array [0 .. 3] of Integer;
    FBaseline0: Integer;

    FMu: TLightweightMREW;
    FClosed: Boolean;
    FCloseC: TThreadedQueue<Pointer>;

    FGet: UInt32;
    FPut: UInt32;
    FHalf: UInt32;
    FLess: UInt32;
    FEqual: UInt32;
    FGreater: UInt32;
    FMiss: UInt32;

    procedure Drain;
    function PoolNum(N: Integer): Integer;
  public
    constructor Create(ABaseline: Integer);
    destructor Destroy; override;

    function Get(N: Integer): TBytes;
    procedure Put(B: TBytes);
    procedure Close;
    function ToString: string; override;
  end;

implementation

{ TBufferPool }

constructor TBufferPool.Create(ABaseline: Integer);
var
  I: Integer;
  Caps: array [0 .. 5] of Integer;
begin
  if ABaseline <= 0 then
    raise Exception.Create('baseline can''t be <= 0');

  FBaseline0 := ABaseline;
  FBaseline[0] := ABaseline div 4;
  FBaseline[1] := ABaseline div 2;
  FBaseline[2] := ABaseline * 2;
  FBaseline[3] := ABaseline * 4;

  FCloseC := TThreadedQueue<Pointer>.Create(1);

  Caps[0] := 2; Caps[1] := 2; Caps[2] := 4; Caps[3] := 4; Caps[4] := 2; Caps[5] := 1;
  for I := 0 to 5 do
    FPool[I] := TThreadedQueue<TBytes>.Create(Caps[I]);

  TTask.Run(procedure
    begin
      Drain;
    end);
end;

destructor TBufferPool.Destroy;
begin
  Close;
  inherited;
end;

procedure TBufferPool.Close;
begin
  FMu.BeginWrite;
  try
    if not FClosed then
    begin
      FClosed := True;
      FCloseC.PushItem(nil);
    end;
  finally
    FMu.EndWrite;
  end;
end;

procedure TBufferPool.Drain;
var
  Ch: TThreadedQueue<TBytes>;
  I: Integer;
  B: TBytes;
  P: Pointer;
begin
  while True do
  begin
    if FCloseC.PopItem(P) = TWaitResult.wrSignaled then
    begin
      for I := 0 to 5 do
        FPool[I].Free;
      FCloseC.Free;
      Exit;
    end;

    // Sleep 2 seconds as in Go ticker
    TThread.Sleep(2000);

    for I := 0 to 5 do
    begin
      Ch := FPool[I];
      if Ch.PopItem(B) = TWaitResult.wrSignaled then
        // Just discard
        ;
    end;
  end;
end;

function TBufferPool.PoolNum(N: Integer): Integer;
var
  I: Integer;
begin
  if (N <= FBaseline0) and (N > FBaseline0 div 2) then
    Exit(0);
  for I := 0 to High(FBaseline) do
  begin
    if N <= FBaseline[I] then
      Exit(I + 1);
  end;
  Result := Length(FBaseline) + 1;
end;

function TBufferPool.Get(N: Integer): TBytes;
var
  Num: Integer;
  Pool: TThreadedQueue<TBytes>;
  B: TBytes;
  SizePtr, SizeHalfPtr, SizeMissPtr: PUInt32;
  CurrentSize: UInt32;
begin
  if Self = nil then
    Exit(TBytes.Create(N));

  FMu.BeginRead;
  try
    if FClosed then
      Exit(TBytes.Create(N));

    TInterlocked.Increment(FGet);

    Num := PoolNum(N);
    Pool := FPool[Num];

    if Num = 0 then
    begin
      if Pool.PopItem(B) = TWaitResult.wrSignaled then
      begin
        if Length(B) > N then
        begin
          if Length(B) - N >= N then
          begin
            TInterlocked.Increment(FHalf);
            Pool.PushItem(B);
            Exit(TBytes.Create(N));
          end
          else
          begin
            TInterlocked.Increment(FLess);
            SetLength(B, N);
            Exit(B);
          end;
        end
        else if Length(B) = N then
        begin
          TInterlocked.Increment(FEqual);
          Exit(B);
        end
        else
        begin
          TInterlocked.Increment(FGreater);
        end;
      end
      else
      begin
        TInterlocked.Increment(FMiss);
      end;

      SetLength(Result, N);
      // Capacity is not explicitly handled in Delphi TBytes, so we just use N
      // but in Go it was make([]byte, n, p.baseline0)
      Exit(Result);
    end
    else
    begin
      SizePtr := @FSize[Num - 1];

      if Pool.PopItem(B) = TWaitResult.wrSignaled then
      begin
        if Length(B) > N then
        begin
          if Length(B) - N >= N then
          begin
            TInterlocked.Increment(FHalf);
            SizeHalfPtr := @FSizeHalf[Num - 1];
            if TInterlocked.Increment(SizeHalfPtr^) = 20 then
            begin
              TInterlocked.Exchange(SizePtr^, Length(B) div 2);
              TInterlocked.Exchange(SizeHalfPtr^, 0);
            end
            else
            begin
              Pool.PushItem(B);
            end;
            Exit(TBytes.Create(N));
          end
          else
          begin
            TInterlocked.Increment(FLess);
            SetLength(B, N);
            Exit(B);
          end;
        end
        else if Length(B) = N then
        begin
          TInterlocked.Increment(FEqual);
          Exit(B);
        end
        else
        begin
          TInterlocked.Increment(FGreater);
          if UInt32(Length(B)) >= TInterlocked.Read(SizePtr^) then
          begin
            Pool.PushItem(B);
          end;
        end;
      end
      else
      begin
        TInterlocked.Increment(FMiss);
      end;

      CurrentSize := TInterlocked.Read(SizePtr^);
      if UInt32(N) > CurrentSize then
      begin
        if CurrentSize = 0 then
        begin
          TInterlocked.CompareExchange(SizePtr^, UInt32(N), 0);
        end
        else
        begin
          SizeMissPtr := @FSizeMiss[Num - 1];
          if TInterlocked.Increment(SizeMissPtr^) = 20 then
          begin
            TInterlocked.Exchange(SizePtr^, UInt32(N));
            TInterlocked.Exchange(SizeMissPtr^, 0);
          end;
        end;
        Exit(TBytes.Create(N));
      end
      else
      begin
        // In Go: make([]byte, n, size)
        Exit(TBytes.Create(N));
      end;
    end;
  finally
    FMu.EndRead;
  end;
end;

procedure TBufferPool.Put(B: TBytes);
var
  Num: Integer;
  Pool: TThreadedQueue<TBytes>;
begin
  if Self = nil then
    Exit;

  FMu.BeginRead;
  try
    if FClosed then
      Exit;

    TInterlocked.Increment(FPut);

    Num := PoolNum(Length(B));
    Pool := FPool[Num];
    Pool.PushItem(B);
  finally
    FMu.EndRead;
  end;
end;

function TBufferPool.ToString: string;
begin
  if Self = nil then
    Exit('<nil>');

  FMu.BeginRead;
  try
    Result := Format('BufferPool{B·%d Z·[%d, %d, %d, %d, %d] Zm·[%d, %d, %d, %d, %d] Zh·[%d, %d, %d, %d, %d] G·%d P·%d H·%d <·%d =·%d >·%d M·%d}',
      [FBaseline0, FSize[0], FSize[1], FSize[2], FSize[3], FSize[4],
       FSizeMiss[0], FSizeMiss[1], FSizeMiss[2], FSizeMiss[3], FSizeMiss[4],
       FSizeHalf[0], FSizeHalf[1], FSizeHalf[2], FSizeHalf[3], FSizeHalf[4],
       FGet, FPut, FHalf, FLess, FEqual, FGreater, FMiss]);
  finally
    FMu.EndRead;
  end;
end;

end.
