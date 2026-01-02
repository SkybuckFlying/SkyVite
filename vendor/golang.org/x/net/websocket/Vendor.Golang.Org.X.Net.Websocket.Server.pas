unit Vendor.Golang.Org.X.Net.Websocket.Server;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

type
  TServer = class
  public
    Config: TConfig;
    // Handshake: TFunc<TConfig, TRequest, Exception>;
    // Handler: THandler;
  end;

implementation

end.
