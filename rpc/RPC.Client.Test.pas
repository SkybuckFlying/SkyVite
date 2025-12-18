unit RPC.Client.Test;

interface

uses
  IdContext IdCustomHTTPServer IdHTTPServer // For mock server,
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
  RPC.Websocket,
  SysUtils Classes;

type
  // Mock HTTP server to act as RPC endpoint
  TMockRPCServer = class(TIdHTTPServer)
  private
    FExpectedMethod: string;
    FResponse: string;
    procedure HTTPServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create;
    procedure SetResponse(const AMethod, AResponse: string);
  end;

  TRPCClientTest = class
  private
    procedure TestSimpleCall;
  public
    procedure RunAllTests;
  end;

implementation

{ TMockRPCServer }

constructor TMockRPCServer.Create;
begin
  inherited Create(nil);
  OnCommandGet := HTTPServerCommandGet;
end;

procedure TMockRPCServer.SetResponse(const AMethod, AResponse: string);
begin
  FExpectedMethod := AMethod;
  FResponse := AResponse;
end;

procedure TMockRPCServer.HTTPServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  requestBody: string;
begin
  // A real implementation would parse the JSON-RPC request
  // For this test, we'll just check if the method is in the raw post data
  requestBody := ARequestInfo.RawPostData;
  if requestBody.Contains(FExpectedMethod) then
  begin
    AResponseInfo.ResponseText := FResponse;
  end
  else
  begin
    AResponseInfo.ResponseText := '{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":1}';
  end;
end;


{ TRPCClientTest }

procedure TRPCClientTest.TestSimpleCall;
var
  server: TMockRPCServer;
  client: TRPCClient;
  response: TJSONValue;
begin
  // 1. Setup mock server
  server := TMockRPCServer.Create;
  server.DefaultPort := 8545;
  server.SetResponse('test_method', '{"jsonrpc":"2.0","result":"test_success","id":1}');
  server.Active := True;
  
  // 2. Setup client
  client := TRPCClient.Create('http://localhost:8545');
  
  try
    // 3. Make the call
    response := client.Call('test_method', []);
    
    // 4. Verify the response
    if (response = nil) or (response.GetValue<string>('result') <> 'test_success') then
      raise Exception.Create('RPC call failed or returned incorrect result');
      
  finally
    client.Free;
    server.Active := False;
    server.Free;
  end;
end;

procedure TRPCClientTest.RunAllTests;
begin
  TestSimpleCall;
end;

end.
