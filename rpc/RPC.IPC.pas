unit Rpc.Ipc;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  Rpc.Listener;

type
  TIpcListener = class(TInterfacedObject, IListener)
  private
    mPipe: THandle;
    mEndpoint: string;
  public
    constructor Create(const ParaEndpoint: string);
    destructor Destroy; override;
    function Accept: IConnection;
    procedure Close;
    function Addr: string;
  end;

  TIpcConnection = class(TInterfacedObject, IConnection)
  private
    mPipe: THandle;
  public
    constructor Create(const ParaPipe: THandle);
    destructor Destroy; override;
    function Read(ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
    function Write(const ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
    procedure Close;
    function RemoteAddr: string;
  end;

implementation

uses
  System.IOUtils;

{ TIpcListener }

constructor TIpcListener.Create(const ParaEndpoint: string);
begin
  inherited Create;
  mEndpoint := ParaEndpoint;
  mPipe := CreateNamedPipe(
    PChar(mEndpoint),
    PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_BYTE or PIPE_READMODE_BYTE or PIPE_WAIT,
    PIPE_UNLIMITED_INSTANCES,
    4096,
    4096,
    0,
    nil
  );
  if mPipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
end;

destructor TIpcListener.Destroy;
begin
  Close;
  inherited;
end;

function TIpcListener.Accept: IConnection;
begin
  if ConnectNamedPipe(mPipe, nil) or (GetLastError = ERROR_PIPE_CONNECTED) then
    Result := TIpcConnection.Create(mPipe)
  else
    RaiseLastOSError;
end;

procedure TIpcListener.Close;
begin
  if mPipe <> INVALID_HANDLE_VALUE then
  begin
    DisconnectNamedPipe(mPipe);
    CloseHandle(mPipe);
    mPipe := INVALID_HANDLE_VALUE;
  end;
end;

function TIpcListener.Addr: string;
begin
  Result := mEndpoint;
end;

{ TIpcConnection }

constructor TIpcConnection.Create(const ParaPipe: THandle);
begin
  inherited Create;
  mPipe := ParaPipe;
end;

destructor TIpcConnection.Destroy;
begin
  Close;
  inherited;
end;

function TIpcConnection.Read(ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
var
  vBytesRead: DWord;
begin
  if not ReadFile(mPipe, ParaBuffer[ParaOffset], ParaCount, vBytesRead, nil) then
    RaiseLastOSError;
  Result := vBytesRead;
end;

function TIpcConnection.Write(const ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
var
  vBytesWritten: DWord;
begin
  if not WriteFile(mPipe, ParaBuffer[ParaOffset], ParaCount, vBytesWritten, nil) then
    RaiseLastOSError;
  Result := vBytesWritten;
end;

procedure TIpcConnection.Close;
begin
  if mPipe <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(mPipe);
    mPipe := INVALID_HANDLE_VALUE;
  end;
end;

function TIpcConnection.RemoteAddr: string;
begin
  Result := '';
end;

end.