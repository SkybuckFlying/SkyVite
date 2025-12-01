unit Log15.Logger;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, System.Rtti,
  Log15, Log15.Handler;

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

  TLogRecord = record
    Time: TDateTime;
    Lvl: TLvl;
    Msg: string;
    Ctx: TArray<TValue>;
    // Call: TStackFrame; // Missing stack trace implementation
    KeyNames: TRecordKeyNames;
  end;

  TCtx = class(TDictionary<string, TValue>)
  public
    function ToArray: TArray<TValue>;
  end;

  TLazy = record
    Fn: TFunc<TArray<TValue>>;
  end;

  ILogger = interface(Log15.ILogger)
    ['{4B3B7E6C-82A3-4A7B-8AF3-24D897E65E5D}']
    function New(Ctx: array of const): ILogger;
    function GetHandler: IHandler;
    procedure SetHandler(AHandler: IHandler);
    procedure Debug(Msg: string; Ctx: array of const);
    procedure Info(Msg: string; Ctx: array of const);
    procedure Warn(Msg: string; Ctx: array of const);
    procedure Error(Msg: string; Ctx: array of const);
    procedure Crit(Msg: string; Ctx: array of const);
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

{ TLogger }

constructor TLogger.Create;
begin
  inherited Create;
  mSwapHandler := TSwapHandler.Create(nil);
end;

procedure TLogger.Crit(Msg: string; Ctx: array of const);
begin
  Write(Msg, Tlvl.LvlCrit, Ctx);
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
      Result := vCtxMap.ToArray;
    end;
  end;

  // ctx needs to be even because it's a series of key/value pairs
  // no one wants to check for errors on logging functions,
  // so instead of erroring on bad input, we'll just make sure
  // that things are the right length and users can fix bugs
  // when they see the output looks wrong
  if Length(Result) mod 2 <> 0 then
  begin
    SetLength(Result, Length(Result) + 2);
    Result[High(Result) - 1] := nil;
    Result[High(Result)] := TValue.From<string>(ConstErrorKey, 'Normalized odd number of arguments by adding nil');
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
  vRecord: TLogRecord;
  vIndex: Integer;
  vConst: TVarRec;
  vValue: TValue;
  vCtxArray: TArray<TValue>;
begin
  if mSwapHandler <> nil then
  begin
    vRecord.Time := Now;
    vRecord.Lvl := Lvl;
    vRecord.Msg := Msg;
    vRecord.KeyNames.Time := ConstTimeKey;
    vRecord.KeyNames.Msg := ConstMsgKey;
    vRecord.KeyNames.Lvl := ConstLvlKey;

    SetLength(vCtxArray, Length(Ctx));
    for vConst in Ctx do
    begin
        TValue.Make(@vConst, TypeInfo(TVarRec), vValue);
        vCtxArray[System.Low(vCtxArray)] := vValue;
    end;

    vRecord.Ctx := NewContext(mCtx, vCtxArray);
    mSwapHandler.Log(vRecord);
  end;
end;

{ TCtx }

function TCtx.ToArray: TArray<TValue>;
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