unit Log15.Root;

interface

uses
  Log15 Log15.Logger Log15.Handler Log15.Format,
  Log15.Doc,
  Log15.Format,
  Log15.Handler,
  Log15.Handler.Go13,
  Log15.Handler.Go14,
  Log15.Logger,
  Log15.Syslog,
  System.SysUtils System.Classes;

function New(ctx: array of const): ILogger;
function Root: ILogger;
procedure Debug(msg: string; ctx: array of const);
procedure Info(msg: string; ctx: array of const);
procedure Warn(msg: string; ctx: array of const);
procedure Error(msg: string; ctx: array of const);
procedure Crit(msg: string; ctx: array of const);

implementation

uses
  Winapi.Windows;

var
  gRootLogger: ILogger;
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
  gRootLogger.Debug(msg, ctx);
end;

procedure Info(msg: string; ctx: array of const);
begin
  gRootLogger.Info(msg, ctx);
end;

procedure Warn(msg: string; ctx: array of const);
begin
  gRootLogger.Warn(msg, ctx);
end;

procedure Error(msg: string; ctx: array of const);
begin
  gRootLogger.Error(msg, ctx);
end;

procedure Crit(msg: string; ctx: array of const);
begin
  gRootLogger.Crit(msg, ctx);
end;

function GetStdOutHandle: THandle;
begin
  Result := GetStdHandle(STD_OUTPUT_HANDLE);
end;

function GetStdErrHandle: THandle;
begin
  Result := GetStdHandle(STD_ERROR_HANDLE);
end;

initialization
  if IsConsole then
  begin
    gStdoutHandler := StreamHandler(THandleStream.Create(GetStdOutHandle), TerminalFormat);
    gStderrHandler := StreamHandler(THandleStream.Create(GetStdErrHandle), TerminalFormat);
  end
  else
  begin
    // Fallback for non-console (e.g. GUI app), maybe just discard or write to file?
    // For now, we'll just use the same handles but with Logfmt
    gStdoutHandler := StreamHandler(THandleStream.Create(GetStdOutHandle), LogfmtFormat);
    gStderrHandler := StreamHandler(THandleStream.Create(GetStdErrHandle), LogfmtFormat);
  end;

  gRootLogger := TLogger.Create;
  gRootLogger.SetHandler(gStdoutHandler);

finalization
  gRootLogger := nil;

end.
