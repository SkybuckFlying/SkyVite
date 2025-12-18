{
  Copyright 2022 The Delphi-Vite Authors
  This file is part of the Delphi-Vite library.

  The Delphi-Vite library is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The Delphi-Vite library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with the Delphi-Vite library. If not, see <http://www.gnu.org/licenses/>.
}

unit Vite.Rpc.Websocket;

interface

uses
  IdHTTP IdWebsocket IdWebsocketClient,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Connector.Connector,
  Net.Database.Database,
  Net.Database.Database.Test,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Protos.Message.PB,
  Net.Discovery.Simular.Simular,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  Net.Netool.Net.Test,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  RPC.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Health,
  RPC.Http,
  RPC.Http.Test,
  RPC.Inproc,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  RPC.Json,
  RPC.Json.Test,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  System.SysUtils System.Classes System.Net.URL System.Net.HttpClient,
  Vite.Rpc.Server Vite.Rpc.Client Vite.Rpc.Json Vite.Rpc.Connection;

type
  TWebsocketConn = class(TInterfacedObject, IConnection)
  private
    FClient: TIdWebsocketClient;
    FBuffer: TMemoryStream;
    FBufferLock: TMutex;
  public
    constructor Create(AClient: TIdWebsocketClient);
    destructor Destroy; override;
    // IConnection
    function Read(Buffer: TBytes; Offset, Count: Integer): Integer;
    function Write(const Buffer: TBytes; Offset, Count: Integer): Integer;
    procedure Close;
    function GetRemoteAddress: string;
  end;

  TWsServer = class(TIdHTTP)
  private
    FServer: TRpcServer;
    FAllowedOrigins: TArray<string>;
    procedure DoWebsocketConnect(AThread: TIdContext; ARequest: TIdHTTPRequestInfo;
      AResponse: TIdHTTPResponseInfo);
  public
    constructor Create(AAllowedOrigins: TArray<string>; AServer: TRpcServer);
  end;

function DialWebsocket(const Endpoint, Origin: string): TRpcClient;

implementation

uses
  System.Threading, System.StrUtils, System.Json;

{ TWebsocketConn }

constructor TWebsocketConn.Create(AClient: TIdWebsocketClient);
begin
  FClient := AClient;
  FBuffer := TMemoryStream.Create;
  FBufferLock := TMutex.Create;
  FClient.OnFrame := procedure(Sender: TObject; AFrame: TIdWebsocketFrame)
  begin
    FBufferLock.Acquire;
    try
      FBuffer.Write(AFrame.Payload, Length(AFrame.Payload));
    finally
      FBufferLock.Release;
    end;
  end;
end;

destructor TWebsocketConn.Destroy;
begin
  FClient.Free;
  FBuffer.Free;
  FBufferLock.Free;
  inherited;
end;

function TWebsocketConn.Read(Buffer: TBytes; Offset, Count: Integer): Integer;
begin
  FBufferLock.Acquire;
  try
    FBuffer.Position := 0;
    Result := FBuffer.Read(Buffer, Offset, Count);
    FBuffer.Delete(0, Result);
  finally
    FBufferLock.Release;
  end;
end;

function TWebsocketConn.Write(const Buffer: TBytes; Offset, Count: Integer): Integer;
var
  Frame: TIdWebsocketFrame;
begin
  Frame := TIdWebsocketFrame.Create;
  try
    SetLength(Frame.Payload, Count);
    System.Move(Buffer[Offset], Frame.Payload[0], Count);
    FClient.WriteFrame(Frame);
    Result := Count;
  finally
    Frame.Free;
  end;
end;

procedure TWebsocketConn.Close;
begin
  FClient.Disconnect;
end;

function TWebsocketConn.GetRemoteAddress: string;
begin
  Result := FClient.Host + ':' + IntToStr(FClient.Port);
end;

{ TWsServer }

constructor TWsServer.Create(AAllowedOrigins: TArray<string>; AServer: TRpcServer);
begin
  inherited Create(nil);
  FServer := AServer;
  FAllowedOrigins := AAllowedOrigins;
  OnWebsocketConnect := DoWebsocketConnect;
end;

procedure TWsServer.DoWebsocketConnect(AThread: TIdContext;
  ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
var
  Origin: string;
  Allowed: Boolean;
  I: Integer;
  Conn: IConnection;
  Ws: TIdHTTPWebsocketConnection;
begin
  Origin := ARequest.Other['Origin'];
  Allowed := False;
  for I := 0 to High(FAllowedOrigins) do
    if (FAllowedOrigins[I] = '*') or SameText(FAllowedOrigins[I], Origin) then
    begin
      Allowed := True;
      Break;
    end;

  if not Allowed then
  begin
    AResponse.ResponseNo := 403;
    AResponse.ResponseText := 'Forbidden';
    Exit;
  end;

  Ws := TIdHTTPWebsocketConnection.Create(AThread.Connection);
  // Conn := TWebsocketConn.Create(Ws); // Need to adapt TIdHTTPWebsocketConnection to TIdWebsocketClient
  // FServer.ServeCodec(TJsonCodec.Create(Conn), [omMethodInvocation, omSubscriptions]);
end;

{ DialWebsocket }

function DialWebsocket(const Endpoint, Origin: string): TRpcClient;
var
  Client: TIdWebsocketClient;
begin
  Client := TIdWebsocketClient.Create(nil);
  Client.URL := Endpoint;
  Client.Request.Other['Origin'] := Origin;
  Client.Connect;

  Result := TRpcClient.Create(
    function: IConnection
    begin
      Result := TWebsocketConn.Create(Client);
    end);
end;

end.
