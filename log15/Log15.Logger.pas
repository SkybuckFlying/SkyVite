unit Log15.Logger;

interface

uses
  Log15 Log15.Handler,
  Log15.Doc,
  Log15.Format,
  Log15.Handler,
  Log15.Handler.Go13,
  Log15.Handler.Go14,
  Log15.Root,
  Log15.Syslog,
  System.SysUtils System.Classes System.SyncObjs System.Generics.Collections System.Rtti;

const
  ConstTimeKey = 't';
  ConstLvlKey = 'lvl';
  ConstMsgKey = 'msg';
  ConstErrorKey = 'LOG15_ERROR';

type
  TRecordKeyNames = record
    Time: string;
    Msg: string;
    Lvl: string;
  end;

  TLogRecord = class(TInterfacedObject, IRecord)
  private
    FTime: TDateTime;
    FLvl: TLvl;
    FMsg: string;
    FCtx: TArray<TValue>;
  public
    constructor Create(ATime: TDateTime; ALvl: TLvl; const AMsg: string; const ACtx: TArray<TValue>);
    function GetTime: TDateTime;
    function GetLvl: TLvl;
    function GetMsg: string;
    function GetCtx: TArray<TValue>;
    property Time: TDateTime read GetTime;
    property Lvl: TLvl read GetLvl;
    property Msg: string read GetMsg;
    property Ctx: TArray<TValue> read GetCtx;
  end;

  TCtx = class(TDictionary<string, TValue>)
  public
    function ToValueArray: TArray<TValue>;
  end;

  TLazy = record
    Fn: TFunc<TArray<TValue>>;
  end;

  TLogger = class(TInterfacedObject, ILogger)
  private
    mCtx: TArray<TValue>;
    mSwapHandler: ISwapHandler;
    procedure Write(Msg: string; Lvl: TLvl; Ctx: array of const);
    class function NewContext(const ParaPrefix, ParaSuffix: TArray<TValue>): TArray<TValue>;
    class function Normalize(const ParaCtx: TArray<TValue>): TArray<TValue>;
  public
    constructor Create;
    function New(Ctx: array of const): ILogger;
    function GetHandler: IHandler;
    procedure SetHandler(AHandler: IHandler);
    procedure Debug(Msg: string; Ctx: array of const);
    procedure Info(Msg: string; Ctx: array of const);
    procedure Warn(Msg: string; Ctx: array of const);
    procedure Error(Msg: string; Ctx: array of const);
    procedure Crit(Msg: string; Ctx: array of const);
  end;

implementation

uses System.Variants;

{ TLogRecord }

constructor TLogRecord.Create(ATime: TDateTime; ALvl: TLvl; const AMsg: string; const ACtx: TArray<TValue>);
begin
  inherited Create;
  FTime := ATime;
  FLvl := ALvl;
  FMsg := AMsg;
  FCtx := ACtx;
end;

function TLogRecord.GetTime: TDateTime;
begin
  Result := FTime;
end;

function TLogRecord.GetLvl: TLvl;
begin
  Result := FLvl;
end;

function TLogRecord.GetMsg: string;
begin
  Result := FMsg;
end;

function TLogRecord.GetCtx: TArray<TValue>;
begin
  Result := FCtx;
end;

{ TLogger }

constructor TLogger.Create;
begin
  inherited Create;
  mSwapHandler := SwapHandler(nil);
end;

procedure TLogger.Crit(Msg: string; Ctx: array of const);
begin
  Write(Msg, TLvl.LvlCrit, Ctx);
  Halt(1);
end;

procedure TLogger.Debug(Msg: string; Ctx: array of const);
begin
  Write(Msg, TLvl.LvlDebug, Ctx);
end;

procedure TLogger.Error(Msg: string; Ctx: array of const);
begin
  Write(Msg, TLvl.LvlError, Ctx);
end;

function TLogger.GetHandler: IHandler;
begin
  Result := mSwapHandler.Get();
end;

procedure TLogger.Info(Msg: string; Ctx: array of const);
begin
  Write(Msg, TLvl.LvlInfo, Ctx);
end;

function TLogger.New(Ctx: array of const): ILogger;
var
  vNewLogger: TLogger;
  vNewCtx: TArray<TValue>;
  vValue: TValue;
  vConst: TVarRec;
begin
  vNewLogger := TLogger.Create;
  SetLength(vNewCtx, Length(Ctx));
  for vConst in Ctx do
  begin
    TValue.Make(@vConst, TypeInfo(TVarRec), vValue);
    vNewCtx[System.Low(vNewCtx)] := vValue;
  end;

  vNewLogger.mCtx := NewContext(Self.mCtx, vNewCtx);
  vNewLogger.SetHandler(mSwapHandler);
  Result := vNewLogger;
end;

class function TLogger.NewContext(const ParaPrefix, ParaSuffix: TArray<TValue>): TArray<TValue>;
var
  vNormalizedSuffix: TArray<TValue>;
  vNewCtx: TArray<TValue>;
  vIndex: Integer;
begin
  vNormalizedSuffix := Normalize(ParaSuffix);
  SetLength(vNewCtx, Length(ParaPrefix) + Length(vNormalizedSuffix));
  for vIndex := 0 to High(ParaPrefix) do
    vNewCtx[vIndex] := ParaPrefix[vIndex];
  for vIndex := 0 to High(vNormalizedSuffix) do
    vNewCtx[Length(ParaPrefix) + vIndex] := vNormalizedSuffix[vIndex];
  Result := vNewCtx;
end;


class function TLogger.Normalize(const ParaCtx: TArray<TValue>): TArray<TValue>;
var
  vCtxMap: TCtx;
  vResult: TArray<TValue>;
begin
  Result := ParaCtx;
  // if the caller passed a Ctx object, then expand it
  if (Length(Result) = 1) and (Result[0].IsObject) then
  begin
    if Result[0].AsObject is TCtx then
    begin
      vCtxMap := Result[0].AsObject as TCtx;
      Result := vCtxMap.ToValueArray;
    end;
  end;

  // ctx needs to be even because it's a series of key/value pairs
  if Length(Result) mod 2 <> 0 then
  begin
    SetLength(Result, Length(Result) + 2);
    Result[High(Result) - 1] := TValue.Empty;
    Result[High(Result)] := TValue.From<string>('Normalized odd number of arguments by adding nil');
  end;
end;

procedure TLogger.SetHandler(AHandler: IHandler);
begin
  mSwapHandler.Swap(AHandler);
end;

procedure TLogger.Warn(Msg: string; Ctx: array of const);
begin
  Write(Msg, TLvl.LvlWarn, Ctx);
end;

procedure TLogger.Write(Msg: string; Lvl: TLvl; Ctx: array of const);
var
  vRecord: IRecord;
  vIndex: Integer;
  vConst: TVarRec;
  vValue: TValue;
  vCtxArray: TArray<TValue>;
begin
  if mSwapHandler <> nil then
  begin
    SetLength(vCtxArray, Length(Ctx));
    for vConst in Ctx do
    begin
        TValue.Make(@vConst, TypeInfo(TVarRec), vValue);
        vCtxArray[System.Low(vCtxArray)] := vValue;
    end;

    vRecord := TLogRecord.Create(Now, Lvl, Msg, NewContext(mCtx, vCtxArray));
    mSwapHandler.Log(vRecord);
  end;
end;

{ TCtx }

function TCtx.ToValueArray: TArray<TValue>;
var
  vPair: TPair<string, TValue>;
  vIndex: Integer;
begin
  SetLength(Result, Self.Count * 2);
  vIndex := 0;
  for vPair in Self do
  begin
    Result[vIndex] := vPair.Key;
    Result[vIndex + 1] := vPair.Value;
    Inc(vIndex, 2);
  end;
end;

end.
