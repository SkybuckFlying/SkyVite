unit Vendor.Golang.Org.X.Net.Websocket.Server;

interface

uses
  System.SysUtils, System.Classes,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

type
  TServer = class
  public
    Config: TConfig;
    Handshake: TFunc<PConfig, IRequest, Exception>;
    Handler: TProc<PConn>;
    procedure ServeHTTP(AW: IResponseWriter; AReq: IRequest);
  end;

implementation

procedure TServer.ServeHTTP(AW: IResponseWriter; AReq: IRequest);
begin
  // Implementation
end;

end.
