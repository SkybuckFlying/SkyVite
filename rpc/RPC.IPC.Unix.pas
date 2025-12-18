unit RPC_IPC_Unix;

interface

uses
  SysUtils;

function ipcListen(const endpoint: string): TObject;
function newIPCConnection(const endpoint: string): TObject;

implementation

uses
  IdBaseComponent, IdComponent, IdRaw, IdRawClient, IdRawServer, IdStack;

function ipcListen(const endpoint: string): TObject;
var
  Server: TIdRawServer;
begin
  // Ensure the IPC path exists and remove any previous leftover
  ForceDirectories(ExtractFileDir(endpoint));
  DeleteFile(endpoint);

  Server := TIdRawServer.Create(nil);
  Server.Bindings.Add.IP := endpoint;
  Server.Bindings.Add.Port := 0; // Unix socket doesn't use a port
  Server.Active := True;

  // Set file permissions
  {$IFDEF UNIX}
  chmod(endpoint, S_IRUSR or S_IWUSR);
  {$ENDIF}

  Result := Server;
end;

function newIPCConnection(const endpoint: string): TObject;
var
  Client: TIdRawClient;
begin
  Client := TIdRawClient.Create(nil);
  Client.Host := endpoint;
  Client.Port := 0; // Unix socket doesn't use a port
  Client.Connect;
  Result := Client;
end;

end.
