unit Rpc.Http;

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
  Rpc.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  Rpc.Connection,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Health,
  RPC.Http.Test,
  RPC.Inproc,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  Rpc.Json,
  RPC.Json.Test,
  Rpc.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.Classes,
  System.Json,
  System.Net.HttpClient,
  System.Net.HttpServer,
  System.Net.URL,
  System.SysUtils;

const
  ConstContentType = 'application/json';
  ConstMaxRequestContentLength = 1024 * 128;

type
  THttpTimeouts = record
    ReadTimeout: Cardinal;
    WriteTimeout: Cardinal;
    IdleTimeout: Cardinal;
  end;

  THttpConn = class(TInterfacedObject, IConnection)
  private
    mClient: TNetHTTPClient;
    mReq: TNetHTTPRequest;
    mResp: IHTTPResponse;
    mClosed: TEvent;
    function DoRequest(const ParaMsg: TObject): TStream;
  public
    constructor Create(const ParaClient: TNetHTTPClient; const ParaReq: TNetHTTPRequest);
    destructor Destroy; override;
    // IConnection
    function Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    function Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    procedure Close;
    function GetRemoteAddress: string;
    // Http-specific methods
    procedure Send(const ParaOp: TRequestOp; const ParaMsg: TObject);
    procedure SendBatch(const ParaOp: TRequestOp; const ParaMsgs: TArray<TJsonRpcMessage>);
  end;

  THttpServer = class(TNetHTTPServer)
  private
    mServer: TRpcServer;
    mCors: TArray<string>;
    mVhosts: TArray<string>;
    mTimeouts: THttpTimeouts;
    procedure CommandGet(const ParaContext: TNetHTTPContext);
  public
    constructor Create(const ParaCors, ParaVhosts: TArray<string>; const ParaTimeouts: THttpTimeouts;
      const ParaServer: TRpcServer);
  end;

function DialHttp(const ParaEndpoint: string): TRpcClient;
function DialHttpWithClient(const ParaEndpoint: string;
  const ParaClient: TNetHTTPClient): TRpcClient;

implementation

uses
  System.Rtti,
  System.Net.Mime,
  System.Threading,
  System.StrUtils;

{ THttpConn }

constructor THttpConn.Create(const ParaClient: TNetHTTPClient; const ParaReq: TNetHTTPRequest);
begin
  mClient := ParaClient;
  mReq := ParaReq;
  mClosed := TEvent.Create(nil, True, False, '');
end;

destructor THttpConn.Destroy;
begin
  mClosed.Free;
  inherited;
end;

function THttpConn.Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  mClosed.WaitFor(INFINITE);
  Result := 0; // Read is not supported for HTTP connections
end;

function THttpConn.Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  // Write is handled by DoRequest
  raise ENetException.Create('Write called on HTTP connection');
end;

procedure THttpConn.Close;
begin
  mClosed.SetEvent;
end;

function THttpConn.GetRemoteAddress: string;
begin
  Result := '';
end;

function THttpConn.DoRequest(const ParaMsg: TObject): TStream;
var
  vBody: TBytes;
  vReq: TNetHTTPRequest;
  vJsonStr: string;
begin
  vJsonStr := TJson.ObjectToJsonString(ParaMsg);
  vBody := TEncoding.UTF8.GetBytes(vJsonStr);
  vReq := mReq.Clone;
  vReq.Body.LoadFromBytes(vBody);
  vReq.ContentLength := Length(vBody);
  mResp := vReq.Execute;
  if (mResp.StatusCode < 200) or (mResp.StatusCode >= 300) then
  begin
    raise ENetException.Create(mResp.StatusText);
  end;
  Result := mResp.ContentStream;
end;

procedure THttpConn.Send(const ParaOp: TRequestOp; const ParaMsg: TObject);
var
  vRespStream: TStream;
  vRespMsg: TJsonRpcMessage;
begin
  try
    vRespStream := DoRequest(ParaMsg);
    try
      vRespMsg := TJson.JsonToObject<TJsonRpcMessage>(vRespStream);
      ParaOp.Resp.Send(vRespMsg);
    finally
      vRespStream.Free;
    end;
  except
    on E: Exception do
    begin
      ParaOp.Err := E;
    end;
  end;
end;

procedure THttpConn.SendBatch(const ParaOp: TRequestOp; const ParaMsgs: TArray<TJsonRpcMessage>);
var
  vRespStream: TStream;
  vRespMsgs: TArray<TJsonRpcMessage>;
  vIndex: Integer;
begin
  try
    vRespStream := DoRequest(ParaMsgs);
    try
      vRespMsgs := TJson.JsonToObject<TArray<TJsonRpcMessage>>(vRespStream);
      for vIndex := 0 to High(vRespMsgs) do
      begin
        ParaOp.Resp.Send(vRespMsgs[vIndex]);
      end;
    finally
      vRespStream.Free;
    end;
  except
    on E: Exception do
    begin
      ParaOp.Err := E;
    end;
  end;
end;

{ THttpServer }

constructor THttpServer.Create(const ParaCors, ParaVhosts: TArray<string>;
  const ParaTimeouts: THttpTimeouts; const ParaServer: TRpcServer);
begin
  inherited Create(nil);
  mServer := ParaServer;
  mCors := ParaCors;
  mVhosts := ParaVhosts;
  mTimeouts := ParaTimeouts;
  OnCommandGet := CommandGet;
end;

procedure THttpServer.CommandGet(const ParaContext: TNetHTTPContext);
var
  vCodec: TJsonCodec;
  vBody: TStream;
  vCtx: TContext;
begin
  if (ParaContext.Request.ContentLength = 0) and (ParaContext.Request.URL.RawPath = '') then
  begin
    // Health check
    Exit;
  end;
  if (ParaContext.Request.ContentLength > ConstMaxRequestContentLength) then
  begin
    ParaContext.Response.StatusCode := 413;
    ParaContext.Response.ReasonString := 'Request Entity Too Large';
    Exit;
  end;
  if not SameText(ParaContext.Request.ContentType, ConstContentType) then
  begin
    ParaContext.Response.StatusCode := 415;
    ParaContext.Response.ReasonString := 'Unsupported Media Type';
    Exit;
  end;
  vBody := TMemoryStream.Create;
  ParaContext.Request.Body.Position := 0;
  vBody.CopyFrom(ParaContext.Request.Body, ParaContext.Request.Body.Size);
  vBody.Position := 0;
  vCodec := TJsonCodec.Create(vBody, ParaContext.Response.Body);
  try
    vCtx := TContext.Create;
    vCtx.SetValue('remote', ParaContext.Request.RemoteAddress);
    vCtx.SetValue('scheme', ParaContext.Request.URL.Scheme);
    vCtx.SetValue('local', ParaContext.Request.URL.Host);
    mServer.ServeSingleRequest(vCtx, vCodec, [omMethodInvocation]);
  finally
    vCodec.Free;
  end;
end;

{ DialFunctions }

function DialHttp(const ParaEndpoint: string): TRpcClient;
begin
  Result := DialHttpWithClient(ParaEndpoint, TNetHTTPClient.Create(nil));
end;

function DialHttpWithClient(const ParaEndpoint: string;
  const ParaClient: TNetHTTPClient): TRpcClient;
var
  vReq: TNetHTTPRequest;
begin
  vReq := TNetHTTPRequest.Create(nil);
  vReq.MethodString := 'POST';
  vReq.URL := ParaEndpoint;
  vReq.ContentType := ConstContentType;
  vReq.Accept := ConstContentType;
  Result := TRpcClient.Create(
    function: IConnection
    begin
      Result := THttpConn.Create(ParaClient, vReq);
    end);
end;

end.
