unit Log15.Format;

interface

uses
  System.SysUtils, System.Classes, Log15;

function TerminalFormat: Log15.IFormat;
function LogfmtFormat: Log15.IFormat;
function JsonFormat: Log15.IFormat;
function JsonFormatEx(pretty, lineSeparated: Boolean): Log15.IFormat;

type
  IFormat = interface
    ['{55E3E3E3-3E3E-4E3E-8E3E-3E3E3E3E3E3E}']
    function Format(r: IRecord): TBytes;
  end;

implementation

uses
  System.JSON, System.SysConst, System.StrUtils, System.DateUtils, System.Rtti;

const
  timeFormat = 'yyyy-mm-dd"T"hh:nn:ss.zzzZ';
  termTimeFormat = 'mm-dd|hh:nn:ss';
  floatFormat = 'f';
  termMsgJust = 40;

type
  TFormatFunc = class(TInterfacedObject, Log15.IFormat)
  private
    fFunc: TFunc<IRecord, TBytes>;
  public
    constructor Create(aFunc: TFunc<IRecord, TBytes>);
    function Format(r: IRecord): TBytes;
  end;

constructor TFormatFunc.Create(aFunc: TFunc<IRecord, TBytes>);
begin
  fFunc := aFunc;
end;

function TFormatFunc.Format(r: IRecord): TBytes;
begin
  Result := fFunc(r);
end;

function formatLogfmtValue(const v: TValue): string;
begin
  if v.IsEmpty then
    Result := 'nil'
  else if v.IsType<string> then
    Result := '"' + v.AsString + '"'
  else
    Result := v.ToString;
end;

function formatJSONValue(const v: TValue): TJSONValue;
begin
  if v.IsEmpty then
    Result := TJSONNull.Create
  else if v.IsType<string> then
    Result := TJSONString.Create(v.AsString)
  else if v.IsType<Integer> then
    Result := TJSONNumber.Create(v.AsInteger)
  else if v.IsType<Boolean> then
  begin
    if v.AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
    Result := TJSONString.Create(v.ToString);
end;

procedure logfmt(buf: TStringBuilder; ctx: TArray<TValue>; color: Integer);
var
  i: Integer;
  k: string;
  v: string;
begin
  for i := 0 to High(ctx) div 2 do
  begin
    if i <> 0 then
      buf.Append(' ');

    if ctx[i*2].IsType<string> then
      k := ctx[i*2].AsString
    else
      k := 'errorKey';
    v := formatLogfmtValue(ctx[i*2+1]);

    if color > 0 then
      buf.AppendFormat(#27'[%dm%s'#27'[0m=%s', [color, k, v])
    else
    begin
      buf.Append(k);
      buf.Append('=');
      buf.Append(v);
    end;
  end;
  buf.Append(sLineBreak);
end;

function TerminalFormat: Log15.IFormat;
begin
  Result := TFormatFunc.Create(
    function(r: IRecord): TBytes
    var
      color: Integer;
      b: TStringBuilder;
      lvl: string;
    begin
      color := 0;
      case r.Lvl of
        LvlCrit: color := 35;
        LvlError: color := 31;
        LvlWarn: color := 33;
        LvlInfo: color := 32;
        LvlDebug: color := 36;
      end;

      b := TStringBuilder.Create;
      try
        lvl := UpperCase(LvlToString(r.Lvl));
        if color > 0 then
          b.AppendFormat(#27'[%dm%s'#27'[0m[%s] %s ', [color, lvl, FormatDateTime(termTimeFormat, r.Time), r.Msg])
        else
          b.AppendFormat('[%s] [%s] %s ', [lvl, FormatDateTime(termTimeFormat, r.Time), r.Msg]);

        if (Length(r.Ctx) > 0) and (Length(r.Msg) < termMsgJust) then
          b.Append(' ', termMsgJust - Length(r.Msg));

        logfmt(b, r.Ctx, color);
        Result := TEncoding.UTF8.GetBytes(b.ToString);
      finally
        b.Free;
      end;
    end);
end;

function LogfmtFormat: Log15.IFormat;
begin
  Result := TFormatFunc.Create(
    function(r: IRecord): TBytes
    var
      buf: TStringBuilder;
    begin
      buf := TStringBuilder.Create;
      try
        logfmt(buf, r.Ctx, 0);
        Result := TEncoding.UTF8.GetBytes(buf.ToString);
      finally
        buf.Free;
      end;
    end);
end;

function JsonFormat: Log15.IFormat;
begin
  Result := JsonFormatEx(False, True);
end;

function JsonFormatEx(pretty, lineSeparated: Boolean): Log15.IFormat;
begin
  Result := TFormatFunc.Create(
    function(r: IRecord): TBytes
    var
      props: TJSONObject;
      i: Integer;
      k: string;
      b: TBytes;
    begin
      props := TJSONObject.Create;
      try
        i := 0;
        while i < Length(r.Ctx) do
        begin
          if r.Ctx[i].IsType<string> then
            k := r.Ctx[i].AsString
          else
            k := 'errorKey';
          
          if i + 1 < Length(r.Ctx) then
            props.AddPair(k, formatJSONValue(r.Ctx[i+1]))
          else
            props.AddPair(k, TJSONNull.Create);

          Inc(i, 2);
        end;

        if pretty then
          b := TEncoding.UTF8.GetBytes(props.Format)
        else
          b := TEncoding.UTF8.GetBytes(props.ToJSON);

        if lineSeparated then
          b := b + TBytes(TEncoding.UTF8.GetBytes(sLineBreak));
        Result := b;
      finally
        props.Free;
      end;
    end);
end;

end.