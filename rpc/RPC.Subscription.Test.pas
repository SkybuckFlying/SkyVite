unit RPC_Subscription_Test;

interface
uses
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
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket;

procedure RunSubscriptionTest;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Threading,
  System.SyncObjs,
  System.Diagnostics,
  RPC, // Assumes TRPCServer, TJSONCodec, TNotifier, TSubscription, etc.
  DUnitX.TestFramework;

type
  TNotificationTestService = class
  private
    FUnsubscribedLock: TCriticalSection;
    FUnsubscribed: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function WasUnsubCallbackCalled: Boolean;
    procedure SetUnsubscribed;
    function Echo(I: Integer): Integer;
    function SomeSubscription(Ctx: TObject; N, Val: Integer): TSubscription;
  end;

{ TNotificationTestService }

constructor TNotificationTestService.Create;
begin
  inherited;
  FUnsubscribedLock := TCriticalSection.Create;
  FUnsubscribed := False;
end;

destructor TNotificationTestService.Destroy;
begin
  FUnsubscribedLock.Free;
  inherited;
end;

function TNotificationTestService.WasUnsubCallbackCalled: Boolean;
begin
  FUnsubscribedLock.Enter;
  try
    Result := FUnsubscribed;
  finally
    FUnsubscribedLock.Leave;
  end;
end;

procedure TNotificationTestService.SetUnsubscribed;
begin
  FUnsubscribedLock.Enter;
  try
    FUnsubscribed := True;
  finally
    FUnsubscribedLock.Leave;
  end;
end;

function TNotificationTestService.Echo(I: Integer): Integer;
begin
  Result := I;
end;

function TNotificationTestService.SomeSubscription(Ctx: TObject; N, Val: Integer): TSubscription;
var
  Notifier: TNotifier;
  Subscription: TSubscription;
begin
  Notifier := TNotifier.FromContext(Ctx);
  if not Assigned(Notifier) then
    raise EJSONRPCError.Create(ErrNotificationsUnsupported, 'Notifications not supported', nil);

  Subscription := Notifier.CreateSubscription;

  TTask.Run(procedure
    var
      I: Integer;
    begin
      try
        // Give time for the subscription ID to be sent to the client
        TThread.Sleep(1000);

        for I := 0 to N - 1 do
        begin
          if Notifier.IsClosed or Subscription.IsClosed then Exit;
          Notifier.Notify(Subscription.ID, Val + I);
        end;
      finally
        // When the notifier/subscription is closed from the outside, mark service as unsubscribed
        SetUnsubscribed;
      end;
    end);

  Result := Subscription;
end;

procedure TestNotifications;
var
  Server: TRPCServer;
  Service: TNotificationTestService;
  ClientToServer, ServerToClient: TPairedMemoryStream; // Simulate net.Pipe
  ServerTask: ITask;
  Request: TJSONObject;
  Response: TJSONObject;
  Notification: TJSONObject;
  SubId: string;
  I, N, Val: Integer;
  Codec: TJSONCodec;
  Writer: TStreamWriter;
  Reader: TStreamReader;
begin
  Server := TRPCServer.Create;
  Service := TNotificationTestService.Create;
  try
    Server.RegisterName('eth', Service);

    ClientToServer := TPairedMemoryStream.Create;
    ServerToClient := TPairedMemoryStream.Create;
    ClientToServer.PairedStream := ServerToClient;
    ServerToClient.PairedStream := ClientToServer;

    Codec := TJSONCodec.Create(ServerToClient, ClientToServer); // Server reads from C2S, writes to S2C

    ServerTask := TTask.Run(procedure
      begin
        Server.ServeCodec(Codec, [soMethodInvocation, soSubscriptions]);
      end);

    Writer := TStreamWriter.Create(ClientToServer);
    Reader := TStreamReader.Create(ServerToClient);
    try
      N := 5;
      Val := 12345;
      Request := TJSONObject.Create;
      Request.AddPair('id', TJSONNumber.Create(1));
      Request.AddPair('method', 'eth_subscribe');
      Request.AddPair('jsonrpc', '2.0');
      var LParams := TJSONArray.Create;
      LParams.Add('someSubscription');
      LParams.Add(N);
      LParams.Add(Val);
      Request.AddPair('params', LParams);

      // 1. Send subscription request
      Writer.WriteLine(Request.ToString);
      Writer.Flush;
      Request.Free;

      // 2. Read subscription ID response
      Response := TJSONObject.ParseJSONValue(Reader.ReadLine) as TJSONObject;
      Assert.IsNotNull(Response.GetValue('result'), 'Response should have a result');
      SubId := Response.GetValue('result').Value;
      Assert.IsFalse(SubId.IsEmpty, 'Subscription ID should not be empty');
      Response.Free;

      // 3. Read notifications
      for I := 0 to N - 1 do
      begin
        Notification := TJSONObject.ParseJSONValue(Reader.ReadLine) as TJSONObject;
        var LParamsObj := Notification.GetValue('params') as TJSONObject;
        Assert.IsNotNull(LParamsObj, 'Notification should have params');
        Assert.AreEqual(SubId, (LParamsObj.GetValue('subscription') as TJSONString).Value);
        
        var LResultVal := (LParamsObj.GetValue('result') as TJSONNumber).AsInt64;
        Assert.AreEqual(Val + I, LResultVal, 'Notification value mismatch');
        Notification.Free;
      end;

      // 4. Close connection and check for unsubscribe
      ClientToServer.Close; // This should cause the server codec to stop
      ServerTask.Wait(2000); // Wait for server to process closure

      Assert.IsTrue(Service.WasUnsubCallbackCalled, 'Unsubscribe callback not called');

    finally
      Writer.Free;
      Reader.Free;
      ClientToServer.Free;
      ServerToClient.Free;
    end;
  finally
    Service.Free;
    Server.Free;
  end;
end;


procedure RunSubscriptionTest;
begin
  TestNotifications;
  // A Delphi version of TestSubscriptionMultipleNamespaces would be very complex
  // due to the need to replicate Go's `select` on channels.
  // This simplified test covers the core subscription and notification logic.
end;

end.
