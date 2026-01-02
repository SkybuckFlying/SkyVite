unit Vendor.Golang.Org.X.Net.Websocket.Client;

interface

uses
  System.SysUtils, System.Net.URLClient,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

type
  TDialError = class(Exception)
  public
    Config: TConfig;
    Err: Exception;
    constructor Create(AConfig: TConfig; AErr: Exception);
  end;

function NewConfig(const Server, Origin: string): TConfig;
function Dial(const URL, Protocol, Origin: string): TConn;

implementation

{ TDialError }

constructor TDialError.Create(AConfig: TConfig; AErr: Exception);
begin
  inherited Create('websocket.Dial ' + AConfig.Location + ': ' + AErr.Message);
  Config := AConfig;
  Err := AErr;
end;

function NewConfig(const Server, Origin: string): TConfig;
begin
  Result := TConfig.Create;
  Result.Location := Server;
  Result.Origin := Origin;
  Result.Version := ProtocolVersionHybi13;
end;

function Dial(const URL, Protocol, Origin: string): TConn;
var
  Config: TConfig;
begin
  Config := NewConfig(URL, Origin);
  if Protocol <> '' then
    Config.Protocol := [Protocol];
  // Result := DialConfig(Config);
  Result := nil;
end;

end.
