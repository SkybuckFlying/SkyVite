unit Vendor.Golang.Org.X.Net.Websocket.Client;

interface

uses
  System.SysUtils, System.Classes,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

type
  TDialError = class(Exception)
  public
    Config: PConfig;
    Err: Exception;
    constructor Create(AConfig: PConfig; AErr: Exception);
    function Error: string;
  end;

function NewConfig(AServer, AOrigin: string): TTuple<PConfig, Exception>;
function NewClient(AConfig: PConfig; ARwc: IReadWriteCloser): TTuple<PConn, Exception>;
function Dial(AUrl, AProtocol, AOrigin: string): TTuple<PConn, Exception>;
function DialConfig(AConfig: PConfig): TTuple<PConn, Exception>;

implementation

{ TDialError }

constructor TDialError.Create(AConfig: PConfig; AErr: Exception);
begin
  inherited Create(AErr.Message);
  Config := AConfig;
  Err := AErr;
end;

function TDialError.Error: string;
begin
  Result := 'websocket.Dial ' + Config.Location.ToString + ': ' + Err.Message;
end;

function NewConfig(AServer, AOrigin: string): TTuple<PConfig, Exception>;
begin
  // Implementation
  Result := Default(TTuple<PConfig, Exception>);
end;

function NewClient(AConfig: PConfig; ARwc: IReadWriteCloser): TTuple<PConn, Exception>;
begin
  // Implementation
  Result := Default(TTuple<PConn, Exception>);
end;

function Dial(AUrl, AProtocol, AOrigin: string): TTuple<PConn, Exception>;
begin
  // Implementation
  Result := Default(TTuple<PConn, Exception>);
end;

function DialConfig(AConfig: PConfig): TTuple<PConn, Exception>;
begin
  // Implementation
  Result := Default(TTuple<PConn, Exception>);
end;

end.
