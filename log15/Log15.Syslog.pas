unit Log15.Syslog;

{$IFNDEF MSWINDOWS}
interface

uses
  Log15, Log15.Format, Log15.Handler;

type
  TSyslogPriority = (
    LOG_EMERG,
    LOG_ALERT,
    LOG_CRIT,
    LOG_ERR,
    LOG_WARNING,
    LOG_NOTICE,
    LOG_INFO,
    LOG_DEBUG
  );

function SyslogHandler(priority: TSyslogPriority; tag: string; fmtr: IFormat): IHandler;
function SyslogNetHandler(net, addr: string; priority: TSyslogPriority; tag: string; fmtr: IFormat): IHandler;

implementation

function SharedSyslog(fmtr: IFormat; sysWr: TObject; err: Pointer): IHandler;
begin
  if err <> nil then
  begin
    Result := nil;
    Exit;
  end;

  Result := TFuncHandler.Create(
    function(r: TLogRecord): Pointer;
    var
      syslogFn: procedure(s: string);
      s: string;
    begin
      case r.Lvl of
        LvlCrit: syslogFn := procedure(s: string) begin end; // sysWr.Crit(s);
        LvlError: syslogFn := procedure(s: string) begin end; // sysWr.Err(s);
        LvlWarn: syslogFn := procedure(s: string) begin end; // sysWr.Warning(s);
        LvlInfo: syslogFn := procedure(s: string) begin end; // sysWr.Info(s);
        LvlDebug: syslogFn := procedure(s: string) begin end; // sysWr.Debug(s);
      else
        syslogFn := procedure(s: string) begin end; // sysWr.Info(s);
      end;

      s := Trim(string(fmtr.Format(r)));
      syslogFn(s);
      Result := nil;
    end
  );
  // Result := TLazyHandler.Create(TClosingHandler.Create(sysWr, Result));
end;

function SyslogHandler(priority: TSyslogPriority; tag: string; fmtr: IFormat): IHandler;
var
  wr: TObject;
  err: Pointer;
begin
  // wr, err := syslog.New(priority, tag)
  Result := SharedSyslog(fmtr, wr, err);
end;

function SyslogNetHandler(net, addr: string; priority: TSyslogPriority; tag: string; fmtr: IFormat): IHandler;
var
  wr: TObject;
  err: Pointer;
begin
  // wr, err := syslog.Dial(net, addr, priority, tag)
  Result := SharedSyslog(fmtr, wr, err);
end;

end.
{$ENDIF}
