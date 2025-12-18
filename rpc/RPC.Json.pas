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

unit Vite.Rpc.Json;

interface

uses
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
  RPC.Json.Test,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.SysUtils System.Classes System.Json System.Rtti,
  Vite.Rpc.Server Vite.Rpc.Connection;

const
  JsonRpcVersion = '2.0';
  ServiceMethodSeparator = '_';
  SubscribeMethodSuffix = '_subscribe';
  UnsubscribeMethodSuffix = '_unsubscribe';
  NotificationMethodSuffix = '_subscription';

type
  TJsonCodec = class(TInterfacedObject, IServerCodec)
  private
    FConn: IConnection;
    FDecoder: TJsonTextReader;
    FEncoder: TJsonTextWriter;
    FClosed: TEvent;
    procedure Encode(Value: TObject);
    function Decode(Value: out TJsonValue): Boolean;
  public
    constructor Create(AConn: IConnection);
    destructor Destroy; override;
    function ReadRequestHeaders: TTuple<TArray<TRpcRequest>, Boolean, Exception>;
    function ParseRequestArguments(ArgTypes: TArray<TRttiType>;
      Params: TValue): TTuple<TArray<TValue>, Exception>;
    function CreateResponse(Id: TValue; Reply: TObject): TObject;
    function CreateErrorResponse(Id: TValue; Err: Exception): TObject;
    function CreateErrorResponseWithInfo(Id: TValue; Err: Exception;
      Info: TObject): TObject;
    function CreateNotification(SubId, Namespace: string; Event: TObject): TObject;
    procedure Write(Res: TObject);
    procedure Close;
    function Closed: THandle;
  end;

implementation

uses
  System.Threading, System.StrUtils, System.Generics.Collections;

type
  TConnectionStream = class(TStream)
  private
    FConn: IConnection;
  public
    constructor Create(AConn: IConnection);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

{ TConnectionStream }

constructor TConnectionStream.Create(AConn: IConnection);
begin
  FConn := AConn;
end;

function TConnectionStream.Read(var Buffer; Count: Longint): Longint;
var
  Buf: TBytes;
begin
  SetLength(Buf, Count);
  Result := FConn.Read(Buf, 0, Count);
  if Result > 0 then
    System.Move(Buf[0], Buffer, Result);
end;

function TConnectionStream.Write(const Buffer; Count: Longint): Longint;
var
  Buf: TBytes;
begin
  SetLength(Buf, Count);
  System.Move(Buffer, Buf[0], Count);
  Result := FConn.Write(Buf, 0, Count);
end;

{ TJsonCodec }

constructor TJsonCodec.Create(AConn: IConnection);
var
  Stream: TConnectionStream;
  Writer: TStreamWriter;
  Reader: TStreamReader;
begin
  FConn := AConn;
  Stream := TConnectionStream.Create(AConn);
  Writer := TStreamWriter.Create(Stream);
  Reader := TStreamReader.Create(Stream);
  FEncoder := TJsonTextWriter.Create(Writer);
  FDecoder := TJsonTextReader.Create(Reader);
  FClosed := TEvent.Create(nil, True, False, '');
end;

destructor TJsonCodec.Destroy;
begin
  FEncoder.Free;
  FDecoder.Free;
  FClosed.Free;
  inherited;
end;

procedure TJsonCodec.Encode(Value: TObject);
begin
  FEncoder.WriteRaw(TJson.ObjectToJsonString(Value));
end;

function TJsonCodec.Decode(out Value: TJsonValue): Boolean;
begin
  try
    Value := TJsonObject.Parse(FDecoder.ReadToEnd) as TJsonValue;
    Result := True;
  except
    Result := False;
  end;
end;

function TJsonCodec.ReadRequestHeaders: TTuple<TArray<TRpcRequest>, Boolean, Exception>;
var
  JsonValue: TJsonValue;
  JsonObj: TJsonObject;
  JsonArr: TJsonArray;
  Req: TRpcRequest;
  I: Integer;
  Elems: TArray<string>;
begin
  if not Decode(JsonValue) then
    Exit(TTuple.Create(nil, False, EJson.Create('Invalid JSON')));

  if JsonValue is TJsonArray then
  begin
    JsonArr := JsonValue as TJsonArray;
    SetLength(Result.Item1, JsonArr.Count);
    Result.Item2 := True;
    for I := 0 to JsonArr.Count - 1 do
    begin
      JsonObj := JsonArr.Items[I] as TJsonObject;
      Req.Id := JsonObj.GetValue('id').ToValue;
      Req.Method := JsonObj.GetValue('method').Value;
      Req.Params := JsonObj.GetValue('params').ToValue;
      Elems := Req.Method.Split([ServiceMethodSeparator]);
      if Length(Elems) = 2 then
      begin
        Req.Service := Elems[0];
        Req.Method := Elems[1];
      end;
      Result.Item1[I] := Req;
    end;
  end
  else if JsonValue is TJsonObject then
  begin
    JsonObj := JsonValue as TJsonObject;
    SetLength(Result.Item1, 1);
    Result.Item2 := False;
    Req.Id := JsonObj.GetValue('id').ToValue;
    Req.Method := JsonObj.GetValue('method').Value;
    Req.Params := JsonObj.GetValue('params').ToValue;
    Elems := Req.Method.Split([ServiceMethodSeparator]);
    if Length(Elems) = 2 then
    begin
      Req.Service := Elems[0];
      Req.Method := Elems[1];
    end;
    Result.Item1[0] := Req;
  end;
end;

function TJsonCodec.ParseRequestArguments(ArgTypes: TArray<TRttiType>;
  Params: TValue): TTuple<TArray<TValue>, Exception>;
var
  JsonArr: TJsonArray;
  I: Integer;
  Val: TValue;
begin
  if not Params.IsType<TJsonArray> then
    Exit(TTuple.Create(nil, EJson.Create('Params is not an array')));

  JsonArr := Params.AsType<TJsonArray>;
  if JsonArr.Count > Length(ArgTypes) then
    Exit(TTuple.Create(nil, EJson.Create('Too many arguments')));

  SetLength(Result.Item1, Length(ArgTypes));
  for I := 0 to JsonArr.Count - 1 do
  begin
    TJson.JsonToRtti(JsonArr.Items[I].ToString, ArgTypes[I], Val);
    Result.Item1[I] := Val;
  end;
end;

function TJsonCodec.CreateResponse(Id: TValue; Reply: TObject): TObject;
var
  JsonObj: TJsonObject;
begin
  JsonObj := TJsonObject.Create;
  JsonObj.AddPair('jsonrpc', TJsonString.Create(JsonRpcVersion));
  JsonObj.AddPair('id', TJsonValue.FromValue(Id));
  JsonObj.AddPair('result', TJson.ObjectToJsonObject(Reply));
  Result := JsonObj;
end;

function TJsonCodec.CreateErrorResponse(Id: TValue; Err: Exception): TObject;
var
  JsonObj, ErrObj: TJsonObject;
  Code: Integer;
begin
  if Err is ERpcError then
    Code := (Err as ERpcError).ErrorCode
  else
    Code := -32000;

  ErrObj := TJsonObject.Create;
  ErrObj.AddPair('code', TJsonNumber.Create(Code));
  ErrObj.AddPair('message', TJsonString.Create(Err.Message));

  JsonObj := TJsonObject.Create;
  JsonObj.AddPair('jsonrpc', TJsonString.Create(JsonRpcVersion));
  JsonObj.AddPair('id', TJsonValue.FromValue(Id));
  JsonObj.AddPair('error', ErrObj);
  Result := JsonObj;
end;

function TJsonCodec.CreateErrorResponseWithInfo(Id: TValue; Err: Exception;
  Info: TObject): TObject;
var
  JsonObj, ErrObj: TJsonObject;
  Code: Integer;
begin
  JsonObj := CreateErrorResponse(Id, Err) as TJsonObject;
  ErrObj := JsonObj.GetValue('error') as TJsonObject;
  ErrObj.AddPair('data', TJson.ObjectToJsonObject(Info));
  Result := JsonObj;
end;

function TJsonCodec.CreateNotification(SubId, Namespace: string;
  Event: TObject): TObject;
var
  JsonObj, ParamsObj: TJsonObject;
begin
  ParamsObj := TJsonObject.Create;
  ParamsObj.AddPair('subscription', TJsonString.Create(SubId));
  ParamsObj.AddPair('result', TJson.ObjectToJsonObject(Event));

  JsonObj := TJsonObject.Create;
  JsonObj.AddPair('jsonrpc', TJsonString.Create(JsonRpcVersion));
  JsonObj.AddPair('method', TJsonString.Create(Namespace + NotificationMethodSuffix));
  JsonObj.AddPair('params', ParamsObj);
  Result := JsonObj;
end;

procedure TJsonCodec.Write(Res: TObject);
begin
  Encode(Res);
end;

procedure TJsonCodec.Close;
begin
  FClosed.SetEvent;
  FConn.Close;
end;

function TJsonCodec.Closed: THandle;
begin
  Result := FClosed.Handle;
end;

end.
