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
  System.SysUtils, System.Classes, System.Net.URL, System.Net.HttpClient,
  IdHTTP, IdWebsocket, IdWebsocketClient,
  Vite.Rpc.Server, Vite.Rpc.Client, Vite.Rpc.Json, Vite.Rpc.Connection;

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