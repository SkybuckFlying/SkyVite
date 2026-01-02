unit Vendor.Golang.Org.X.Net.Websocket.Dial;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

function DialWithDialer(ADialer: IDialer; AConfig: PConfig): TTuple<IConn, Exception>;

implementation

function DialWithDialer(ADialer: IDialer; AConfig: PConfig): TTuple<IConn, Exception>;
begin
  // Implementation
  Result := Default(TTuple<IConn, Exception>);
end;

end.
