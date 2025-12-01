unit Node.Errors;

interface

uses
  System.SysUtils;

var
  ErrDataDirUsed: Exception;
  ErrNodeStopped: Exception;
  ErrNodeRunning: Exception;
  ErrWalletConfigNil: Exception;

function ConvertFileLockError(const ParaErr: Exception): Exception;

implementation

uses
  System.Classes,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  Posix.Errno,
  {$ENDIF}
  GoToDelphi.Helpers.TChannel;

function ConvertFileLockError(const ParaErr: Exception): Exception;
var
  vErrorCode: Cardinal;
begin
  Result := ParaErr;
  {$IFDEF MSWINDOWS}
  if ParaErr is EOSError then
  begin
    vErrorCode := Cardinal(EOSError(ParaErr).ErrorCode);
    // ERROR_SHARING_VIOLATION = 32
    // ERROR_LOCK_VIOLATION = 33
    if (vErrorCode = ERROR_SHARING_VIOLATION) or (vErrorCode = ERROR_LOCK_VIOLATION) then
    begin
      Result := ErrDataDirUsed;
    end;
  end;
  {$ENDIF}
  {$IFDEF LINUX}
  if ParaErr is EOSError then
  begin
    vErrorCode := Cardinal(EOSError(ParaErr).ErrorCode);
    // EWOULDBLOCK = 11
    // EAGAIN = 11
    if (vErrorCode = EWOULDBLOCK) or (vErrorCode = EAGAIN) then
    begin
      Result := ErrDataDirUsed;
    end;
  end;
  {$ENDIF}
end;

initialization
  ErrDataDirUsed := Exception.Create('dataDir already used by another process');
  ErrNodeStopped := Exception.Create('node not started');
  ErrNodeRunning := Exception.Create('node already running');
  ErrWalletConfigNil := Exception.Create('wallet config is nil');
end.
