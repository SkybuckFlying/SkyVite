unit Common.Log;

interface

uses
  System.SysUtils,
  System.Classes,
  Log15;

// LogHandler creates a log15 handler with file rotation, mirroring the Go implementation.
function LogHandler(
  const ParaPath: string;
  const ParaSubDir: string;
  const ParaFilename: string;
  const ParaLvl: string
  ): IHandler;

implementation

uses
  System.IOUtils,
  GoToDelphi.Helpers.Lumberjack;

// makeDefaultLogger creates a stream writer with file rotation capabilities
// using the TLumberjackStream helper, which mimics gopkg.in/natefinch/lumberjack.v2.
function makeDefaultLogger(const ParaAbsFilePath: string): TStream;
var
  vLogger: TLumberjackStream;
begin
  try
    vLogger := TLumberjackStream.Create(ParaAbsFilePath);
    vLogger.MaxSize := 100; // megabytes
    vLogger.MaxBackups := 14;
    vLogger.MaxAge := 14; // days
    vLogger.Compress := True;
    vLogger.LocalTime := True;
    Result := vLogger;
  except
    on E: Exception do
    begin
      // If file logging can't be set up, this is a critical configuration error.
      WriteLn('FATAL: Failed to create lumberjack logger for path ' + ParaAbsFilePath + '. Error: ' + E.Message);
      raise;
    end;
  end;
end;

function LogHandler(
  const ParaPath: string;
  const ParaSubDir: string;
  const ParaFilename: string;
  const ParaLvl: string
  ): IHandler;
var
  vLogLevel: TLvl;
  vAbsFilename: string;
  vOutStream: TStream;
  vLogDir: string;
begin
  try
    vLogLevel := LvlFromString(ParaLvl);
  except
    // Default to Info level if the provided string is invalid.
    vLogLevel := LvlInfo;
  end;

  vLogDir := TPath.Combine(ParaPath, ParaSubDir);

  // Ensure the directory exists before trying to create the log file.
  try
    TDirectory.CreateDirectory(vLogDir);
  except
    on E: Exception do
    begin
      WriteLn('FATAL: Failed to create log directory ' + vLogDir + '. Error: ' + E.Message);
      raise;
    end;
  end;

  vAbsFilename := TPath.Combine(vLogDir, ParaFilename);
  vOutStream := makeDefaultLogger(vAbsFilename);

  // The handler will take ownership of the stream.
  // The structure is LvlFilterHandler -> StreamHandler -> Formatter.
  Result := LvlFilterHandler(vLogLevel, StreamHandler(vOutStream, LogfmtFormat, True));
end;

end.
