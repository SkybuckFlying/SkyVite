unit Net.Discovery.Socket;

interface

uses
  Crypto.Ed25519,
  GoToDelphi.Helpers.TChannel,
  Log15,
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
  Net.VNode,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.Net.Sockets,
  System.SysUtils,
  System.Threading;

const
  ErrIncompleteMessage = 'incomplete message';
  ErrSocketIsRunning = 'udp socket is listening';
  ErrSocketIsNotRunning = 'udp socket is not running';
  SocketQueueLength = 1000;

type
  ISender = interface
    ['{C1D2E3F4-A5B6-C7D8-E9F0-A1B2C3D4E5F6}']
    procedure Ping(ParaN: TNode; ParaCallback: TProc<TNode, Exception>);
    function Pong(ParaEcho: TBytes; ParaN: TNode): Exception;
    function FindNode(ParaTarget: TVNodeID; ParaCount: Integer; ParaN: TNode): TChannel<TArray<TVNodeEndPoint>>;
    function SendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TSocketAddress): Exception;
  end;

  IReceiver = interface
    ['{F6E5D4C3-B2A1-0F9E-8D7C-6B5A49382716}']
    function Start: Exception;
    function Stop: Exception;
  end;

  ISocket = interface(ISender, IReceiver)
    ['{A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D}']
  end;

  TPacketHandler = reference to procedure(ParaPkt: TPacket);

  TAgent = class(TInterfacedObject, ISocket)
  private
    mNode: TVNode;
    mListenAddress: string;
    mSocket: TUDPServer;
    mPeerKey: TEd25519PrivateKey;
    mQueue: TChannel<TPacket>;
    mHandler: TPacketHandler;
    mPool: IRequestPool;
    mRunning: Integer;
    mTerm: TEvent;
    mReadWg: TThread;
    mHandleWg: TThread;
    mLog: ILogger;

    procedure ReadLoop;
    procedure HandleLoop;
    function Write(ParaMsg: TMessage; ParaAddr: TSocketAddress): TBytes;
  public
    constructor Create(ParaPeerKey: TEd25519PrivateKey; ParaSelfNode: TVNode; ParaListenAddress: string; ParaHandler: TPacketHandler);
    destructor Destroy; override;
    function Start: Exception;
    function Stop: Exception;
    procedure Ping(ParaN: TNode; ParaCallback: TProc<TNode, Exception>);
    function Pong(ParaEcho: TBytes; ParaN: TNode): Exception;
    function FindNode(ParaTarget: TVNodeID; ParaCount: Integer; ParaN: TNode): TChannel<TArray<TVNodeEndPoint>>;
    function SendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TSocketAddress): Exception;
  end;

function NewAgent(ParaPeerKey: TEd25519PrivateKey; ParaSelfNode: TVNode; ParaListenAddress: string; ParaHandler: TPacketHandler): ISocket;
function SplitEndPoints(ParaEps: TArray<TVNodeEndPoint>): TArray<TArray<TVNodeEndPoint>>;

implementation

uses
  System.Math,
  Winapi.Windows;

{ TAgent }

constructor TAgent.Create(ParaPeerKey: TEd25519PrivateKey; ParaSelfNode: TVNode; ParaListenAddress: string; ParaHandler: TPacketHandler);
begin
  inherited;
  mNode := ParaSelfNode;
  mListenAddress := ParaListenAddress;
  mPeerKey := ParaPeerKey;
  mHandler := ParaHandler;
  mPool := NewRequestPool;
  mLog := DiscvLog.New(['module', 'socket']);
  mTerm := TEvent.Create;
end;

destructor TAgent.Destroy;
begin
  Stop;
  mPool := nil;
  mTerm.Free;
  inherited;
end;

function TAgent.Start: Exception;
var
  vUDPAddr: TSocketAddress;
begin
  Result := nil;
  if TInterlocked.CompareExchange(mRunning, 1, 0) = 0 then
  begin
    try
      vUDPAddr.Port := StrToInt(SplitString(mListenAddress, ':')[1]);
      mSocket := TUDPServer.Create(nil);
      mSocket.Bindings.Add.Port := vUDPAddr.Port;
      mSocket.OnUDPRead := procedure(Sender: TObject; AData: TBytes; ABinding: TIdSocketHandle)
      var
        vPkt: TPacket;
        vErr: Exception;
      begin
        vPkt := RetrievePacket;
        vPkt.from := ABinding.Peer;
        vErr := Unpack(AData, vPkt);
        if vErr <> nil then
        begin
          mLog.Warn(Format('Failed to unpack message from %s: %s', [vPkt.from.ToString, vErr.Message]));
          Exit;
        end;
        if vPkt.Expired then
        begin
          mLog.Warn(Format('Message %d from %s expired', [vPkt.c, vPkt.from.ToString]));
          Exit;
        end;
        if (vPkt.c = TCode.Pong) or (vPkt.c = TCode.Neighbors) then
        begin
          if not mPool.Rec(vPkt) then
            Exit;
        end;
        mQueue.Send(vPkt);
      end;
      mSocket.Active := True;

      mTerm.ResetEvent;
      mQueue := TChannel<TPacket>.Create(SocketQueueLength);
      mPool.Start;

      mReadWg := TThread.CreateAnonymousThread(ReadLoop);
      mReadWg.Start;
      mHandleWg := TThread.CreateAnonymousThread(HandleLoop);
      mHandleWg.Start;
    except
      on E: Exception do
      begin
        Result := E;
        TInterlocked.Exchange(mRunning, 0);
      end;
    end;
  end
  else
    Result := Exception.Create(ErrSocketIsRunning);
end;

function TAgent.Stop: Exception;
begin
  Result := nil;
  if TInterlocked.CompareExchange(mRunning, 0, 1) = 1 then
  begin
    try
      mSocket.Active := False;
      mSocket.Free;
      mSocket := nil;
      mTerm.SetEvent;
      mReadWg.WaitFor;
      mHandleWg.WaitFor;
      mPool.Stop;
      mQueue.Close;
    except
      on E: Exception do
        Result := E;
    end;
  end
  else
    Result := Exception.Create(ErrSocketIsNotRunning);
end;

procedure TAgent.Ping(ParaN: TNode; ParaCallback: TProc<TNode, Exception>);
var
  vUDPAddr: TSocketAddress;
  vNow: TDateTime;
  vHash: TBytes;
  vErr: Exception;
  vMsg: TMessage;
  vPingBody: TPingPacketBody;
begin
  try
    vUDPAddr := ParaN.udpAddr;
  except
    on E: Exception do
    begin
      ParaCallback(nil, E);
      Exit;
    end;
  end;

  vNow := Now;
  vMsg := TMessage.Create;
  vMsg.c := TCode.Ping;
  vMsg.id := mNode.ID;
  vPingBody := TPingPacketBody.Create;
  vPingBody.from := mNode.EndPoint;
  vPingBody.to_ := ParaN.EndPoint;
  vPingBody.net := mNode.Net;
  vPingBody.ext := mNode.Ext;
  vPingBody.time := vNow;
  vMsg.body := vPingBody;

  vHash := Write(vMsg, vUDPAddr);
  if Length(vHash) = 0 then
  begin
    ParaCallback(nil, Exception.Create('Failed to send ping'));
    Exit;
  end;

  mPool.Add(TRequest.Create(
    vUDPAddr.ToString,
    ParaN.ID,
    TCode.Pong,
    TPingRequest.Create(vHash, ParaCallback),
    IncSecond(vNow, 2 * Expiration)
  ));
end;

function TAgent.Pong(ParaEcho: TBytes; ParaN: TNode): Exception;
var
  vUDPAddr: TSocketAddress;
  vMsg: TMessage;
  vPongBody: TPongPacketBody;
begin
  Result := nil;
  try
    vUDPAddr := ParaN.udpAddr;
  except
    on E: Exception do
    begin
      Result := E;
      Exit;
    end;
  end;

  vMsg := TMessage.Create;
  vMsg.c := TCode.Pong;
  vMsg.id := mNode.ID;
  vPongBody := TPongPacketBody.Create;
  vPongBody.from := mNode.EndPoint;
  vPongBody.to_ := ParaN.EndPoint;
  vPongBody.net := mNode.Net;
  vPongBody.ext := mNode.Ext;
  vPongBody.echo := ParaEcho;
  vPongBody.time := Now;
  vMsg.body := vPongBody;

  Write(vMsg, vUDPAddr);
end;

function TAgent.FindNode(ParaTarget: TVNodeID; ParaCount: Integer; ParaN: TNode): TChannel<TArray<TVNodeEndPoint>>;
var
  vUDPAddr: TSocketAddress;
  vNow: TDateTime;
  vMsg: TMessage;
  vFindNodeBody: TFindNodePacketBody;
  vCh2: TChannel<TArray<TVNodeEndPoint>>;
begin
  Result := nil;
  try
    vUDPAddr := ParaN.udpAddr;
  except
    on E: Exception do
      Exit;
  end;

  vNow := Now;
  vMsg := TMessage.Create;
  vMsg.c := TCode.FindNode;
  vMsg.id := mNode.ID;
  vFindNodeBody := TFindNodePacketBody.Create;
  vFindNodeBody.target := ParaTarget;
  vFindNodeBody.count := ParaCount;
  vFindNodeBody.time := vNow;
  vMsg.body := vFindNodeBody;

  Write(vMsg, vUDPAddr);

  vCh2 := TChannel<TArray<TVNodeEndPoint>>.Create(1);
  mPool.Add(TRequest.Create(
    vUDPAddr.ToString,
    ParaN.ID,
    TCode.Neighbors,
    TFindNodeRequest.Create(ParaCount, vCh2),
    IncSecond(vNow, 2 * Expiration)
  ));
  Result := vCh2;
end;

function TAgent.SendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TSocketAddress): Exception;
var
  vN: TNeighborsPacketBody;
  vMsg: TMessage;
  vEpt: TArray<TArray<TVNodeEndPoint>>;
  vEpl: TArray<TVNodeEndPoint>;
  vIndex: Integer;
begin
  Result := nil;
  vN := TNeighborsPacketBody.Create;
  vN.last := False;
  vN.time := Now;

  vMsg := TMessage.Create;
  vMsg.c := TCode.Neighbors;
  vMsg.id := mNode.ID;
  vMsg.body := vN;

  vEpt := SplitEndPoints(ParaEps);
  for vIndex := 0 to High(vEpt) do
  begin
    vEpl := vEpt[vIndex];
    vN.endpoints := vEpl;
    vN.last := (vIndex = High(vEpt));
    Write(vMsg, ParaAddr);
  end;
end;

function SplitEndPoints(ParaEps: TArray<TVNodeEndPoint>): TArray<TArray<TVNodeEndPoint>>;
var
  vSent, vBytes, vIndex: Integer;
  vEp: TVNodeEndPoint;
begin
  SetLength(Result, 0);
  vSent := 0;
  vBytes := 0;
  for vIndex := 0 to High(ParaEps) do
  begin
    vEp := ParaEps[vIndex];
    vBytes := vBytes + vEp.Length;
    if (vBytes + 300) > MaxPayloadLength then
    begin
      Result := Result + [Copy(ParaEps, vSent, vIndex - vSent)];
      vBytes := 0;
      vSent := vIndex;
    end;
  end;
  if vSent < Length(ParaEps) then
    Result := Result + [Copy(ParaEps, vSent, Length(ParaEps) - vSent)];
end;

procedure TAgent.ReadLoop;
begin
  while not mTerm.WaitFor(INFINITE) = wrSignaled do
  begin
    // Using OnUDPRead event, so this loop is just for waiting
  end;
end;

procedure TAgent.HandleLoop;
var
  vPkt: TPacket;
begin
  while mQueue.Receive(vPkt) do
  begin
    try
      mHandler(vPkt);
    finally
      RecyclePacket(vPkt);
    end;
  end;
end;

function TAgent.Write(ParaMsg: TMessage; ParaAddr: TSocketAddress): TBytes;
var
  vData, vHash: TBytes;
  vN: Integer;
begin
  Result := nil;
  vData := ParaMsg.Pack(mPeerKey, vHash);
  try
    mSocket.Send(ParaAddr.IP, ParaAddr.Port, vData);
    Result := vHash;
  except
    on E: Exception do
      mLog.Warn(Format('Failed to write message to %s: %s', [ParaAddr.ToString, E.Message]));
  end;
end;

function NewAgent(ParaPeerKey: TEd25519PrivateKey; ParaSelfNode: TVNode; ParaListenAddress: string; ParaHandler: TPacketHandler): ISocket;
begin
  Result := TAgent.Create(ParaPeerKey, ParaSelfNode, ParaListenAddress, ParaHandler);
end;

end.
