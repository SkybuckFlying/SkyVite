unit net.finder;

interface

uses
  common.types crypto.ed25519 net.database net.discovery net.vnode,
  ledger.consensus net.interface,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
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
  System.SysUtils System.Classes System.Generics.Collections System.SyncObjs;

const
  ExtLen = 32 + 64;

type
  IConnector = interface
    ['{C1D2E3F4-A5B6-C7D8-E9F0-A1B2C3D4E5F6}']
    function ConnectNode(Node: IVNode): Exception;
  end;

  IFinder = interface
    ['{D1E2F3A4-B5C6-D7E8-F9A0-B1C2D3E4F5A6}']
    procedure Start;
    procedure Stop;
    procedure Clean;
    function SelfIsSBP: Boolean;
    function IsSBP(Addr: TAddress): Boolean;
    procedure Sub(Sub: TDiscoverySubscriber);
    procedure UnSub(Sub: TDiscoverySubscriber);
    procedure SetResolver(Discv: IResolver);
    function FindNeighbors(FromId, Target: TVNodeId; Count: Integer): TArray<TEndPoint>;
  end;

  TFinder = class(TInterfacedObject, IFinder)
  private
    FSelf: TAddress;
    FSelfIsSBP: Boolean;
    FDb: IDB;
    FRW: TMultiReadSingleWrite;
    FTargets: TDictionary<TAddress, IVNode>;
    FSubId: Integer;
    FMinPeers: Integer;
    FStaticNodes: TArray<IVNode>;
    FResolver: IResolver;
    FPeers: IPeerSet;
    FConnect: IConnector;
    FConsensus: IConsensus;
    FDialing: TDictionary<TPeerId, Boolean>;
    FSBPs: TDictionary<TAddress, Int64>;
    FSubIdObserver: Integer;
    FObservers: TDictionary<Integer, TProc<Boolean>>;
    FTerm: TEvent;
    procedure ReceiveNode(Node: IVNode);
    procedure ReceiveProducers(Event: TProducersEvent);
    procedure Dial(Node: IVNode);
    procedure DoDial(Node: IVNode);
    function Total: Integer;
    procedure Loop;
    procedure Notify;
  public
    constructor Create(Self: TAddress; Peers: IPeerSet; MinPeers: Integer; StaticNodes: TArray<string>; Db: IDB; Connect: IConnector; Consensus: IConsensus);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Clean;
    function SelfIsSBP: Boolean;
    function IsSBP(Addr: TAddress): Boolean;
    procedure Sub(Sub: TDiscoverySubscriber);
    procedure UnSub(Sub: TDiscoverySubscriber);
    procedure SetResolver(Discv: IResolver);
    function FindNeighbors(FromId, Target: TVNodeId; Count: Integer): TArray<TEndPoint>;
  end;

function NewFinder(Self: TAddress; Peers: IPeerSet; MinPeers: Integer; StaticNodes: TArray<string>; Db: IDB; Connect: IConnector; Consensus: IConsensus): IFinder;
procedure SetNodeExt(MineKey: TPrivateKey; Node: IVNode);
function ParseNodeExt(Node: IVNode; out Addr: TAddress): Boolean;

implementation

uses
  System.Threading, System.DateUtils;

{ TFinder }

constructor TFinder.Create(Self: TAddress; Peers: IPeerSet; MinPeers: Integer; StaticNodes: TArray<string>; Db: IDB; Connect: IConnector; Consensus: IConsensus);
var
  Str: string;
  Node: IVNode;
  Err: Exception;
  I: Integer;
begin
  FSelf := Self;
  FDb := Db;
  FRW.Create;
  FTargets := TDictionary<TAddress, IVNode>.Create;
  FMinPeers := MinPeers;
  FPeers := Peers;
  FConnect := Connect;
  FConsensus := Consensus;
  FDialing := TDictionary<TPeerId, Boolean>.Create;
  FSBPs := TDictionary<TAddress, Int64>.Create;
  FObservers := TDictionary<Integer, TProc<Boolean>>.Create;
  SetLength(FStaticNodes, Length(StaticNodes));
  for I := 0 to High(StaticNodes) do
  begin
    Node := VNode.ParseNode(StaticNodes[I], Err);
    if Err <> nil then
      raise Err;
    FStaticNodes[I] := Node;
  end;
  Consensus.SubscribeProducers(SNAPSHOT_GID, 'sbpn', ReceiveProducers);
end;

destructor TFinder.Destroy;
begin
  FRW.Free;
  FTargets.Free;
  FDialing.Free;
  FSBPs.Free;
  FObservers.Free;
  inherited;
end;

procedure TFinder.Start;
var
  Details: TArray<TVoteDetails>;
  Now: Int64;
  D: TVoteDetails;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  Details := FConsensus.API.ReadVoteMap(Now);
  Now := Now.ToUnix;
  FRW.BeginWrite;
  try
    for D in Details do
    begin
      FSBPs.Add(D.CurrentAddr, Now);
      if D.CurrentAddr.IsEqual(FSelf) then
        FSelfIsSBP := True;
    end;
  finally
    FRW.EndWrite;
  end;
  TTask.Run(procedure begin Loop; end);
end;

procedure TFinder.Stop;
begin
  if FTerm <> nil then
    FTerm.SetEvent;
end;

procedure TFinder.Clean;
begin
  FConsensus.UnSubscribe(SNAPSHOT_GID, 'sbpn');
end;

function TFinder.SelfIsSBP: Boolean;
begin
  Result := FSelfIsSBP;
end;

function TFinder.IsSBP(Addr: TAddress): Boolean;
begin
  FRW.BeginRead;
  try
    Result := FSBPs.ContainsKey(Addr);
  finally
    FRW.EndRead;
  end;
end;

procedure TFinder.Sub(Sub: TDiscoverySubscriber);
begin
  FSubId := Sub.Sub(ReceiveNode);
end;

procedure TFinder.UnSub(Sub: TDiscoverySubscriber);
begin
  Sub.UnSub(FSubId);
end;

procedure TFinder.SetResolver(Discv: IResolver);
begin
  FResolver := Discv;
end;

function TFinder.FindNeighbors(FromId, Target: TVNodeId; Count: Integer): TArray<TEndPoint>;
var
  N: IVNode;
begin
  FRW.BeginRead;
  try
    SetLength(Result, FTargets.Count);
    var I := 0;
    for N in FTargets.Values do
    begin
      Result[I] := N.EndPoint;
      Inc(I);
    end;
  finally
    FRW.EndRead;
  end;
end;

procedure TFinder.ReceiveNode(Node: IVNode);
var
  Addr: TAddress;
  Ok: Boolean;
begin
  Ok := ParseNodeExt(Node, Addr);
  if Ok then
  begin
    FRW.BeginWrite;
    try
      FTargets.Add(Addr, Node);
    finally
      FRW.EndWrite;
    end;
  end;
  if Total < FMinPeers then
  begin
    FRW.BeginWrite;
    try
      Dial(Node);
    finally
      FRW.EndWrite;
    end;
  end;
end;

procedure TFinder.ReceiveProducers(Event: TProducersEvent);
var
  Now: Int64;
  SelfIsSBP: Boolean;
  Addr: TAddress;
  Node: IVNode;
  P: IPeer;
begin
  Now := Now.ToUnix;
  FRW.BeginWrite;
  try
    SelfIsSBP := False;
    for Addr in Event.Addrs do
      if Addr.IsEqual(FSelf) then
        SelfIsSBP := True;
    FSelfIsSBP := SelfIsSBP;
    for Addr in Event.Addrs do
    begin
      FSBPs.Add(Addr, Now);
      if FTargets.TryGetValue(Addr, Node) then
      begin
        P := FPeers.Get(Node.Id);
        if P <> nil then
        begin
          P.SetSuperior(True);
          Continue;
        end;
        if FSelfIsSBP then
          Dial(Node);
      end;
    end;
  finally
    FRW.EndWrite;
  end;
  Notify;
end;

procedure TFinder.Dial(Node: IVNode);
begin
  if FDialing.ContainsKey(Node.Id) then
    Exit;
  FDialing.Add(Node.Id, True);
  TTask.Run(procedure begin DoDial(Node); end);
end;

procedure TFinder.DoDial(Node: IVNode);
begin
  FConnect.ConnectNode(Node);
  FRW.BeginWrite;
  try
    FDialing.Remove(Node.Id);
  finally
    FRW.EndWrite;
  end;
end;

function TFinder.Total: Integer;
begin
  FRW.BeginRead;
  try
    Result := FPeers.CountWithoutSBP + FDialing.Count;
  finally
    FRW.EndRead;
  end;
end;

procedure TFinder.Loop;
var
  Nodes: TArray<IVNode>;
  Node: IVNode;
  N: IVNode;
  T: IVNode;
  Total: Integer;
begin
  FRW.BeginWrite;
  try
    Nodes := FDb.ReadMarkNodes(30);
    for Node in Nodes do
      Dial(Node);
  finally
    FRW.EndWrite;
  end;

  while not FTerm.WaitFor(5000) do
  begin
    FRW.BeginWrite;
    try
      for N in FStaticNodes do
        Dial(N);
      if FSelfIsSBP then
        for T in FTargets.Values do
          Dial(T);
    finally
      FRW.EndWrite;
    end;
    if FResolver <> nil then
    begin
      Total := Self.Total;
      if Total < FMinPeers then
      begin
        Nodes := FResolver.GetNodes((FMinPeers - Total) * 2);
        FRW.BeginWrite;
        try
          for Node in Nodes do
            Dial(Node);
        finally
          FRW.EndWrite;
        end;
      end;
    end;
  end;
end;

procedure TFinder.Notify;
var
  Fn: TProc<Boolean>;
begin
  FRW.BeginRead;
  try
    for Fn in FObservers.Values do
      Fn(FSelfIsSBP);
  finally
    FRW.EndRead;
  end;
end;

function NewFinder(Self: TAddress; Peers: IPeerSet; MinPeers: Integer; StaticNodes: TArray<string>; Db: IDB; Connect: IConnector; Consensus: IConsensus): IFinder;
begin
  Result := TFinder.Create(Self, Peers, MinPeers, StaticNodes, Db, Connect, Consensus);
end;

procedure SetNodeExt(MineKey: TPrivateKey; Node: IVNode);
var
  Sign: TBytes;
begin
  SetLength(Node.Ext, ExtLen);
  TBuffer.BlockCopy(MineKey.PubByte, 0, Node.Ext, 0, 32);
  Sign := TEd25519.Sign(MineKey, Node.Id.Bytes);
  TBuffer.BlockCopy(Sign, 0, Node.Ext, 32, Length(Sign));
end;

function ParseNodeExt(Node: IVNode; out Addr: TAddress): Boolean;
var
  Pub: TBytes;
  Sign: TBytes;
begin
  if Length(Node.Ext) < ExtLen then
    Exit(False);
  SetLength(Pub, 32);
  TBuffer.BlockCopy(Node.Ext, 0, Pub, 0, 32);
  SetLength(Sign, Length(Node.Ext) - 32);
  TBuffer.BlockCopy(Node.Ext, 32, Sign, 0, Length(Sign));
  Result := TEd25519.Verify(Pub, Node.Id.Bytes, Sign);
  if Result then
    Addr := TAddress.PubkeyToAddress(Pub);
end;

end.
