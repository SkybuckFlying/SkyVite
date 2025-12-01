unit Log15.Root;

interface

uses
  System.SysUtils, System.Classes,
  Log15, Log15.Logger, Log15.Handler, Log15.Format;

function New(ctx: array of const): ILogger;
function Root: ILogger;
procedure Debug(msg: string; ctx: array of const);
procedure Info(msg: string; ctx: array of const);
procedure Warn(msg: string; ctx: array of const);
procedure Error(msg: string; ctx: array of const);
procedure Crit(msg: string; ctx: array of const);

implementation

var
  gRootLogger: TLogger;
  gStdoutHandler: IHandler;
  gStderrHandler: IHandler;

function New(ctx: array of const): ILogger;
begin
  Result := gRootLogger.New(ctx);
end;

function Root: ILogger;
begin
  Result := gRootLogger;
end;

procedure Debug(msg: string; ctx: array of const);
begin
  gRootLogger.Write(msg, TLvl.LvlDebug, ctx);
end;

procedure Info(msg: string; ctx: array of const);
begin
  gRootLogger.Write(msg, TLvl.LvlInfo, ctx);
end;

procedure Warn(msg: string; ctx: array of const);
begin
  gRootLogger.Write(msg, TLvl.LvlWarn, ctx);
end;

procedure Error(msg: string; ctx: array of const);
begin
  gRootLogger.Write(msg, TLvl.LvlError, ctx);
end;

procedure Crit(msg: string; ctx: array of const);
begin
  gRootLogger.Write(msg, TLvl.LvlCrit, ctx);
  Halt(1);
end;

initialization
  if TConsole.IsConsole then
  begin
    gStdoutHandler := TStreamHandler.Create(TFileStream.Create(TConsole.Handle), TTerminalFormat.Create);
    gStderrHandler := TStreamHandler.Create(TFileStream.Create(TConsole.ErrorHandle), TTerminalFormat.Create);
  end
  else
  begin
    gStdoutHandler := TStreamHandler.Create(TFileStream.Create(TConsole.Handle), TLogfmtFormat.Create);
    gStderrHandler := TStreamHandler.Create(TFileStream.Create(TConsole.ErrorHandle), TLogfmtFormat.Create);
  end;

  gRootLogger := TLogger.Create;
  gRootLogger.SetHandler(gStdoutHandler);

finalization
  gRootLogger := nil;

end.