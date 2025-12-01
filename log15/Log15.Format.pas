unit Log15Format;

interface

uses
  SysUtils, Classes, Log15;

function TerminalFormat: IFormat;
function LogfmtFormat: IFormat;
function JsonFormat: IFormat;
function JsonFormatEx(pretty, lineSeparated: Boolean): IFormat;

type
  IFormat = interface
    ['{55E3E3E3-3E3E-4E3E-8E3E-3E3E3E3E3E3E}']
    function Format(r: IRecord): TBytes;
  end;

implementation

uses
  System.JSON, System.SysConst, System.StrUtils, System.DateUtils;

const
  timeFormat = 'yyyy-mm-dd"T"hh:nn:ss.zzzZ';
  termTimeFormat = 'mm-dd|hh:nn:ss';
  floatFormat = 'f';
  termMsgJust = 40;

type
  TFormatFunc = class(TInterfacedObject, IFormat)
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

function TerminalFormat: IFormat;
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
      lvl := UpperCase(r.Lvl.ToString);
      if color > 0 then
        b.AppendFormat(#27'[%dm%s'#27'[0m[%s] %s ', [color, lvl, FormatDateTime(termTimeFormat, r.Time), r.Msg])
      else
        b.AppendFormat('[%s] [%s] %s ', [lvl, FormatDateTime(termTimeFormat, r.Time), r.Msg]);

      if (Length(r.Ctx) > 0) and (Length(r.Msg) < termMsgJust) then
        b.Append(' ', termMsgJust - Length(r.Msg));

      // logfmt(b, r.Ctx, color);
      logfmt(b, r.Ctx, color);
      Result := TEncoding.UTF8.GetBytes(b.ToString);
    end);
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

function LogfmtFormat: IFormat;
begin
  Result := TFormatFunc.Create(
    function(r: IRecord): TBytes
    var
      // common: TArray<TVar>;
      buf: TStringBuilder;
    begin
      // common := [r.KeyNames.Time, r.Time, r.KeyNames.Lvl, r.Lvl, r.KeyNames.Msg, r.Msg];
      buf := TStringBuilder.Create;
      // logfmt(buf, common + r.Ctx, 0);
      logfmt(buf, r.Ctx, 0);
      Result := TEncoding.UTF8.GetBytes(buf.ToString);
    end);
end;

function JsonFormat: IFormat;
begin
  Result := JsonFormatEx(False, True);
end;

function JsonFormatEx(pretty, lineSeparated: Boolean): IFormat;
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
        // props.AddPair(r.KeyNames.Time, TJSONValue.Create(r.Time));
        // props.AddPair(r.KeyNames.Lvl, TJSONValue.Create(r.Lvl.ToString));
        // props.AddPair(r.KeyNames.Msg, TJSONValue.Create(r.Msg));

        i := 0;
        while i < Length(r.Ctx) do
        begin
          if r.Ctx[i].IsType<string> then
            k := r.Ctx[i]
          else
            k := 'errorKey'; // or handle error appropriately
          // props.AddPair(k, formatJSONValue(r.Ctx[i+1]));
          props.AddPair(k, formatJSONValue(r.Ctx[i+1]));
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