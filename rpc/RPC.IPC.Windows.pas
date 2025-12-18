unit RPC_IPC_Windows;

interface

uses
  SysUtils, Classes;

type
  THandleWrapper = class(TObject)
  private
    FHandle: THandle;
  public
    constructor Create(AHandle: THandle);
    property Handle: THandle read FHandle;
  end;

function ipcListen(const endpoint: string): THandleWrapper;
function newIPCConnection(const endpoint: string): THandleWrapper;

implementation

uses
  Windows, Synchapi;

const
  defaultPipeDialTimeout = 2000; // 2 seconds

{ THandleWrapper }

constructor THandleWrapper.Create(AHandle: THandle);
begin
  inherited Create;
  FHandle := AHandle;
end;

{ Functions }

function ipcListen(const endpoint: string): THandleWrapper;
var
  Pipe: THandle;
begin
  Pipe := CreateNamedPipe(
    PChar(endpoint),
    PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT,
    PIPE_UNLIMITED_INSTANCES,
    4096,
    4096,
    0,
    nil
  );
  if Pipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  Result := THandleWrapper.Create(Pipe);
end;

function newIPCConnection(const endpoint: string): THandleWrapper;
var
  Pipe: THandle;
  Timeout: DWord;
begin
  Timeout := defaultPipeDialTimeout;

  Pipe := CreateFile(
    PChar(endpoint),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  if Pipe = INVALID_HANDLE_VALUE then
  begin
    if GetLastError() <> ERROR_PIPE_BUSY then
      RaiseLastOSError;

    if not WaitNamedPipe(PChar(endpoint), Timeout) then
      RaiseLastOSError;

    Pipe := CreateFile(
      PChar(endpoint),
      GENERIC_READ or GENERIC_WRITE,
      0,
      nil,
      OPEN_EXISTING,
      0,
      0
    );
  end;

  if Pipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  Result := THandleWrapper.Create(Pipe);
end;

end.
