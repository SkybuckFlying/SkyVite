unit Log15.Handler;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.Threading, System.Generics.Collections, Log15, Log15.Format;

type
  ISwapHandler = interface(IHandler)
    ['{E5D4F3C2-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    procedure Swap(h: IHandler);
    function Get: IHandler;
  end;

function FuncHandler(fn: TFunc<IRecord, Boolean>): IHandler;
function StreamHandler(wr: TStream; fmtr: Log15.IFormat): IHandler;
function SyncHandler(h: IHandler): IHandler;
function FileHandler(path: string; fmtr: Log15.IFormat): IHandler;
function NetHandler(network, addr: string; fmtr: Log15.IFormat): IHandler;
function CallerFileHandler(h: IHandler): IHandler;
function CallerFuncHandler(h: IHandler): IHandler;
function CallerStackHandler(format: string; h: IHandler): IHandler;
function FilterHandler(fn: TFunc<IRecord, Boolean>; h: IHandler): IHandler;
function MatchFilterHandler(key: string; value: TValue; h: IHandler): IHandler;
function LvlFilterHandler(maxLvl: TLvl; h: IHandler): IHandler;
function MultiHandler(hs: array of IHandler): IHandler;
function FailoverHandler(hs: array of IHandler): IHandler;
function ChannelHandler(recs: TThreadedQueue<IRecord>): IHandler;
function BufferedHandler(bufSize: Integer; h: IHandler): IHandler;
function LazyHandler(h: IHandler): IHandler;
function DiscardHandler: IHandler;
function SwapHandler(h: IHandler): ISwapHandler;

implementation

uses
  System.SyncObjs, System.Generics.Defaults;

type
  TFuncHandler = class(TInterfacedObject, IHandler)
  private
    fFunc: TFunc<IRecord, Boolean>;
  public
    constructor Create(aFunc: TFunc<IRecord, Boolean>);
    procedure Log(r: IRecord);
  end;

constructor TFuncHandler.Create(aFunc: TFunc<IRecord, Boolean>);
begin
  fFunc := aFunc;
end;

procedure TFuncHandler.Log(r: IRecord);
begin
  if not fFunc(r) then
    raise Exception.Create('Failed to log record');
end;

function FuncHandler(fn: TFunc<IRecord, Boolean>): IHandler;
begin
  Result := TFuncHandler.Create(fn);
end;

function StreamHandler(wr: TStream; fmtr: Log15.IFormat): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    var
      bytes: TBytes;
    begin
      bytes := fmtr.Format(r);
      Result := wr.Write(bytes, 0, Length(bytes)) = Length(bytes);
    end);
end;

function SyncHandler(h: IHandler): IHandler;
var
  mu: TCriticalSection;
begin
  mu := TCriticalSection.Create;
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      mu.Enter;
      try
        h.Log(r);
        Result := True;
      finally
        mu.Leave;
      end;
    end);
end;

function FileHandler(path: string; fmtr: Log15.IFormat): IHandler;
var
  f: TFileStream;
begin
  f := TFileStream.Create(path, fmOpenWrite or fmCreate or fmShareDenyNone);
  f.Seek(0, soEnd);
  Result := StreamHandler(f, fmtr);
end;

function NetHandler(network, addr: string; fmtr: Log15.IFormat): IHandler;
begin
  // Stubbed to avoid System.Net.Sockets dependency for now
  Result := DiscardHandler;
end;

function DiscardHandler: IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      Result := True;
    end);
end;

function LvlFilterHandler(maxLvl: TLvl; h: IHandler): IHandler;
begin
  Result := FilterHandler(
    function(r: IRecord): Boolean
    begin
      Result := r.Lvl <= maxLvl;
    end, h);
end;

function FilterHandler(fn: TFunc<IRecord, Boolean>; h: IHandler): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      if fn(r) then
        h.Log(r);
      Result := True;
    end);
end;

function MultiHandler(hs: array of IHandler): IHandler;
var
  handlers: TArray<IHandler>;
  i: Integer;
begin
  SetLength(handlers, Length(hs));
  for i := 0 to High(hs) do
    handlers[i] := hs[i];

  Result := FuncHandler(
    function(r: IRecord): Boolean
    var
      h: IHandler;
    begin
      for h in handlers do
        h.Log(r);
      Result := True;
    end);
end;

function FailoverHandler(hs: array of IHandler): IHandler;
var
  handlers: TArray<IHandler>;
  i: Integer;
begin
  SetLength(handlers, Length(hs));
  for i := 0 to High(hs) do
    handlers[i] := hs[i];

  Result := FuncHandler(
    function(r: IRecord): Boolean
    var
      h: IHandler;
      err: Exception;
      i: Integer;
    begin
      err := nil;
      i := 0;
      for h in handlers do
      begin
        try
          h.Log(r);
          Exit(True);
        except
          on E: Exception do
          begin
            err := E;
            // r.Ctx := r.Ctx + ['failover_err_' + IntToStr(i), err];
            Inc(i);
          end;
        end;
      end;
      if err <> nil then
        raise err;
      Result := True;
    end);
end;

type
  TSwapHandler = class(TInterfacedObject, ISwapHandler)
  private
    FHandler: IHandler;
    FMu: TMutex;
  public
    constructor Create(h: IHandler);
    destructor Destroy; override;
    procedure Log(r: IRecord);
    procedure Swap(h: IHandler);
    function Get: IHandler;
  end;

constructor TSwapHandler.Create(h: IHandler);
begin
  inherited Create;
  FHandler := h;
  FMu := TMutex.Create;
end;

destructor TSwapHandler.Destroy;
begin
  FMu.Free;
  inherited;
end;

procedure TSwapHandler.Log(r: IRecord);
begin
  FMu.Acquire;
  try
    FHandler.Log(r);
  finally
    FMu.Release;
  end;
end;

procedure TSwapHandler.Swap(h: IHandler);
begin
  FMu.Acquire;
  try
    FHandler := h;
  finally
    FMu.Release;
  end;
end;

function TSwapHandler.Get: IHandler;
begin
  FMu.Acquire;
  try
    Result := FHandler;
  finally
    FMu.Release;
  end;
end;

function SwapHandler(h: IHandler): ISwapHandler;
begin
  Result := TSwapHandler.Create(h);
end;

function CallerFileHandler(h: IHandler): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      h.Log(r);
      Result := True;
    end);
end;

function CallerFuncHandler(h: IHandler): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      h.Log(r);
      Result := True;
    end);
end;

function CallerStackHandler(format: string; h: IHandler): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      h.Log(r);
      Result := True;
    end);
end;

function MatchFilterHandler(key: string; value: TValue; h: IHandler): IHandler;
begin
  Result := FilterHandler(
    function(r: IRecord): Boolean
    begin
      Result := False; // Stub
    end, h);
end;

function ChannelHandler(recs: TThreadedQueue<IRecord>): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      recs.PushItem(r);
      Result := True;
    end);
end;

function BufferedHandler(bufSize: Integer; h: IHandler): IHandler;
var
  recs: TThreadedQueue<IRecord>;
begin
  recs := TThreadedQueue<IRecord>.Create(bufSize, 1000, 1000);
  TThread.CreateAnonymousThread(
    procedure
    var
      r: IRecord;
    begin
      while True do
      begin
        r := recs.PopItem;
        h.Log(r);
      end;
    end).Start;
  Result := ChannelHandler(recs);
end;

function LazyHandler(h: IHandler): IHandler;
begin
  Result := FuncHandler(
    function(r: IRecord): Boolean
    begin
      h.Log(r);
      Result := True;
    end);
end;

end.
