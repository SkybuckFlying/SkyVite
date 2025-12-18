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

unit Vite.Rpc.Server;

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
  RPC.Json,
  RPC.Json.Test,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.SysUtils System.Classes System.Generics.Collections System.Rtti,
  Vite.Rpc.Connection Vite.Rpc.Subscription Vite.Rpc.Utils;

type
  TCodecOption = (omMethodInvocation, omSubscriptions);
  TCodecOptions = set of TCodecOption;

  TRpcRequest = record
    Id: TValue;
    Service: string;
    Method: string;
    Params: TValue;
    IsPubSub: Boolean;
    IsUnsubscribe: Boolean;
    Err: Exception;
  end;

  IServerCodec = interface
    ['{A5A5A5A5-A5A5-A5A5-A5A5-A5A5A5A5A5A5}']
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

  TRpcService = class;
  TCallback = class;

  TRpcServer = class
  private
    FServices: TDictionary<string, TRpcService>;
    FCodecs: TObjectList<IServerCodec>;
    FRun: Integer;
    procedure ServeRequest(Ctx: TContext; Codec: IServerCodec;
      SingleShot: Boolean; Options: TCodecOptions);
    procedure Exec(Ctx: TContext; Codec: IServerCodec; Req: TRpcRequest);
    procedure ExecBatch(Ctx: TContext; Codec: IServerCodec; Reqs: TArray<TRpcRequest>);
    function Handle(Ctx: TContext; Codec: IServerCodec; Req: TRpcRequest): TPair<TObject, TProc>;
    function ReadRequest(Codec: IServerCodec): TTuple<TArray<TRpcRequest>, Boolean, Exception>;
  public
    constructor Create;
    destructor Destroy; override;
    function RegisterName(Name: string; Rcvr: TObject): Exception;
    procedure ServeCodec(Codec: IServerCodec; Options: TCodecOptions);
    procedure ServeSingleRequest(Ctx: TContext; Codec: IServerCodec;
      Options: TCodecOptions);
    procedure Stop;
  end;

  TCallback = class
  public
    Method: TRttiMethod;
    Receiver: TValue;
    ArgTypes: TArray<TRttiType>;
    HasCtx: Boolean;
    ErrPos: Integer;
    IsSubscribe: Boolean;
  end;

  TRpcService = class
  public
    Name: string;
    RttiType: TRttiType;
    Callbacks: TDictionary<string, TCallback>;
    Subscriptions: TDictionary<string, TCallback>;
  end;

implementation

uses
  System.Threading, System.StrUtils;

{ TRpcServer }

constructor TRpcServer.Create;
begin
  FServices := TDictionary<string, TRpcService>.Create;
  FCodecs := TObjectList<IServerCodec>.Create;
  FRun := 1;
end;

destructor TRpcServer.Destroy;
begin
  FServices.Free;
  FCodecs.Free;
  inherited;
end;

function TRpcServer.RegisterName(Name: string; Rcvr: TObject): Exception;
var
  Svc: TRpcService;
  Callbacks, Subscriptions: TDictionary<string, TCallback>;
  Pair: TPair<TDictionary<string, TCallback>, TDictionary<string, TCallback>>;
begin
  try
    if FServices.ContainsKey(Name) then
      Exit(Exception.CreateFmt('Service already registered: %s', [Name]));

    Svc := TRpcService.Create;
    Svc.Name := Name;
    Svc.RttiType := TRttiContext.Create.GetType(Rcvr.ClassType);

    Pair := SuitableCallbacks(TValue.From(Rcvr), Svc.RttiType);
    Callbacks := Pair.Key;
    Subscriptions := Pair.Value;

    if (Callbacks.Count = 0) and (Subscriptions.Count = 0) then
      Exit(Exception.Create('Service has no suitable methods'));

    Svc.Callbacks := Callbacks;
    Svc.Subscriptions := Subscriptions;
    FServices.Add(Name, Svc);
    Result := nil;
  except
    on E: Exception do
      Result := E;
  end;
end;

procedure TRpcServer.ServeCodec(Codec: IServerCodec; Options: TCodecOptions);
begin
  try
    ServeRequest(TContext.Create, Codec, False, Options);
  finally
    Codec.Close;
  end;
end;

procedure TRpcServer.ServeSingleRequest(Ctx: TContext; Codec: IServerCodec;
  Options: TCodecOptions);
begin
  ServeRequest(Ctx, Codec, True, Options);
end;

procedure TRpcServer.ServeRequest(Ctx: TContext; Codec: IServerCodec;
  SingleShot: Boolean; Options: TCodecOptions);
var
  Reqs: TArray<TRpcRequest>;
  Batch: Boolean;
  Err: Exception;
begin
  FCodecs.Add(Codec);
  try
    while AtomicCmpExchange(FRun, 1, 1) = 1 do
    begin
      Reqs := ReadRequest(Codec).Item1;
      Batch := ReadRequest(Codec).Item2;
      Err := ReadRequest(Codec).Item3;
      if Err <> nil then
      begin
        if not SameText(Err.Message, 'EOF') then
          Codec.Write(Codec.CreateErrorResponse(TValue.Empty, Err));
        Break;
      end;

      if AtomicCmpExchange(FRun, 1, 1) <> 1 then
      begin
        Err := Exception.Create('Server is shutting down');
        if Batch then
        begin
          // Batch error response
        end
        else
          Codec.Write(Codec.CreateErrorResponse(Reqs[0].Id, Err));
        Break;
      end;

      if SingleShot then
      begin
        if Batch then
          ExecBatch(Ctx, Codec, Reqs)
        else
          Exec(Ctx, Codec, Reqs[0]);
        Break;
      end;

      TTask.Run(procedure
      begin
        if Batch then
          ExecBatch(Ctx, Codec, Reqs)
        else
          Exec(Ctx, Codec, Reqs[0]);
      end);
    end;
  finally
    FCodecs.Remove(Codec);
  end;
end;

procedure TRpcServer.Exec(Ctx: TContext; Codec: IServerCodec; Req: TRpcRequest);
var
  Response: TObject;
  Callback: TProc;
  Pair: TPair<TObject, TProc>;
begin
  if Req.Err <> nil then
    Response := Codec.CreateErrorResponse(Req.Id, Req.Err)
  else
  begin
    Pair := Handle(Ctx, Codec, Req);
    Response := Pair.Key;
    Callback := Pair.Value;
  end;

  if Codec.Write(Response) <> nil then
    Codec.Close;

  if Assigned(Callback) then
    Callback;
end;

procedure TRpcServer.ExecBatch(Ctx: TContext; Codec: IServerCodec; Reqs: TArray<TRpcRequest>);
var
  Responses: TArray<TObject>;
  Callbacks: TArray<TProc>;
  I: Integer;
  Pair: TPair<TObject, TProc>;
begin
  SetLength(Responses, Length(Reqs));
  for I := 0 to High(Reqs) do
  begin
    if Reqs[I].Err <> nil then
      Responses[I] := Codec.CreateErrorResponse(Reqs[I].Id, Reqs[I].Err)
    else
    begin
      Pair := Handle(Ctx, Codec, Reqs[I]);
      Responses[I] := Pair.Key;
      if Assigned(Pair.Value) then
        Callbacks := Callbacks + [Pair.Value];
    end;
  end;

  if Codec.Write(Responses) <> nil then
    Codec.Close;

  for I := 0 to High(Callbacks) do
    Callbacks[I];
end;

function TRpcServer.Handle(Ctx: TContext; Codec: IServerCodec; Req: TRpcRequest): TPair<TObject, TProc>;
var
  Args: TArray<TValue>;
  Reply: TArray<TValue>;
  Svc: TRpcService;
  Callb: TCallback;
  Notifier: TNotifier;
  SubId: TSubscriptionId;
  Err: Exception;
begin
  if Req.Err <> nil then
    Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, Req.Err), nil));

  if Req.IsUnsubscribe then
  begin
    // Unsubscribe logic
    Exit;
  end;

  if not FServices.TryGetValue(Req.Service, Svc) then
    Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, EMethodNotFoundError.Create(Req.Service, Req.Method, Req.Id)), nil));

  if Req.IsPubSub then
  begin
    if not Svc.Subscriptions.TryGetValue(Req.Method, Callb) then
      Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, EMethodNotFoundError.Create(Req.Service, Req.Method, Req.Id)), nil));
  end
  else
  begin
    if not Svc.Callbacks.TryGetValue(Req.Method, Callb) then
      Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, EMethodNotFoundError.Create(Req.Service, Req.Method, Req.Id)), nil));
  end;

  // Parse arguments
  Args := Codec.ParseRequestArguments(Callb.ArgTypes, Req.Params).Item1;
  Err := Codec.ParseRequestArguments(Callb.ArgTypes, Req.Params).Item2;
  if Err <> nil then
    Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, Err), nil));

  if Callb.IsSubscribe then
  begin
    // Create subscription
    Notifier := NotifierFromContext(Ctx);
    if Notifier = nil then
      Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, ESubscriptionError.Create('Notifications not supported')), nil));

    // Call subscription method
    Args := [TValue.From<TContext>(Ctx)] + Args;
    Reply := Callb.Method.Invoke(Callb.Receiver, Args);
    if not Reply[1].IsNil then
      Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, Reply[1].AsType<Exception>), nil));

    SubId := Reply[0].AsType<TSubscription>.Id;
    Result := TPair.Create(Codec.CreateResponse(Req.Id, TValue.From<string>(SubId)),
      procedure
      begin
        Notifier.Activate(SubId, Svc.Name);
      end);
  end
  else
  begin
    // Regular RPC call
    if Callb.HasCtx then
      Args := [TValue.From<TContext>(Ctx)] + Args;

    Reply := Callb.Method.Invoke(Callb.Receiver, Args);
    if Length(Reply) > 0 then
    begin
      if (Callb.ErrPos >= 0) and (not Reply[Callb.ErrPos].IsNil) then
        Exit(TPair.Create(Codec.CreateErrorResponse(Req.Id, Reply[Callb.ErrPos].AsType<Exception>), nil));
      Result := TPair.Create(Codec.CreateResponse(Req.Id, Reply[0].AsObject), nil);
    end
    else
      Result := TPair.Create(Codec.CreateResponse(Req.Id, nil), nil);
  end;
end;

function TRpcServer.ReadRequest(Codec: IServerCodec): TTuple<TArray<TRpcRequest>, Boolean, Exception>;
var
  Reqs: TArray<TRpcRequest>;
  Batch: Boolean;
  Err: Exception;
  I: Integer;
  Svc: TRpcService;
  Callb: TCallback;
begin
  Reqs := Codec.ReadRequestHeaders.Item1;
  Batch := Codec.ReadRequestHeaders.Item2;
  Err := Codec.ReadRequestHeaders.Item3;
  if Err <> nil then
    Exit(TTuple.Create(nil, False, Err));

  for I := 0 to High(Reqs) do
  begin
    if Reqs[I].Err <> nil then
      Continue;

    if Reqs[I].IsUnsubscribe then
      Continue;

    if not FServices.TryGetValue(Reqs[I].Service, Svc) then
    begin
      Reqs[I].Err := EMethodNotFoundError.Create(Reqs[I].Service, Reqs[I].Method, Reqs[I].Id);
      Continue;
    end;

    if Reqs[I].IsPubSub then
    begin
      if not Svc.Subscriptions.TryGetValue(Reqs[I].Method, Callb) then
        Reqs[I].Err := EMethodNotFoundError.Create(Reqs[I].Service, Reqs[I].Method, Reqs[I].Id);
    end
    else
    begin
      if not Svc.Callbacks.TryGetValue(Reqs[I].Method, Callb) then
        Reqs[I].Err := EMethodNotFoundError.Create(Reqs[I].Service, Reqs[I].Method, Reqs[I].Id);
    end;
  end;

  Result := TTuple.Create(Reqs, Batch, nil);
end;

procedure TRpcServer.Stop;
var
  I: Integer;
begin
  if AtomicCmpExchange(FRun, 0, 1) = 1 then
  begin
    for I := 0 to FCodecs.Count - 1 do
      FCodecs[I].Close;
  end;
end;

end.
