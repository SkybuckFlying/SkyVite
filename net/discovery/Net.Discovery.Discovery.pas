unit net.discovery.discovery;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading,
  Log15, net.vnode, net.database.database, common.bytes;

const
  SeedMaxAge = 7 * 24 * 3600; // 7d
  TRefresh = 24 * 3600 * 1000; // 24 hours in milliseconds
  StoreInterval = 5 * 60 * 1000; // 5 minutes in milliseconds
  CheckInterval = 10 * 1000; // 10 seconds in milliseconds
  CheckExpiration = 3600; // 1 hour in seconds
  StayInTable = 300; // 300 seconds
  DbCleanInterval = 3600 * 1000; // 1 hour in milliseconds

type
  TNode = class(TVNode)
  public
    checkAt: Int64;
    activeAt: Int64;
    constructor Create(ANode: TVNode);
    function NeedCheck: Boolean;
    procedure Update(ANode: TNode);
    function ToString: string; override;
  end;

  ENetDiscoveryError = class(Exception);

var
  ErrDiscoveryIsRunning: ENetDiscoveryError;
  ErrDiscoveryIsStopped: ENetDiscoveryError;
  ErrDifferentNet: ENetDiscoveryError;
  DiscvLog: ILogger;

type
  INodeDB = interface
    ['{YOUR_GUID_HERE}']
    function StoreNode(Node: TVNode): Exception;
    procedure RemoveNode(Id: TVNodeID);
    function ReadNodes(Expiration: Int64): TArray<TVNode>;
    function RetrieveActiveAt(Id: TVNodeID): Int64;
    procedure StoreActiveAt(Id: TVNodeID; V: Int64);
    function RetrieveCheckAt(Id: TVNodeID): Int64;
    procedure StoreCheckAt(Id: TVNodeID; V: Int64);
    procedure Close;
    procedure Clean(Expiration: Int64);
  end;

  TDiscvDB = class(TInterfacedObject, INodeDB)
  private
    FNodeDB: INodeDB;
  public
    constructor Create(ANodeDB: INodeDB);
    function StoreNode(Node: TVNode): Exception;
    procedure RemoveNode(Id: TVNodeID);
    function ReadNodes(Expiration: Int64): TArray<TVNode>;
    function RetrieveActiveAt(Id: TVNodeID): Int64;
    procedure StoreActiveAt(Id: TVNodeID; V: Int64);
    function RetrieveCheckAt(Id: TVNodeID): Int64;
    procedure StoreCheckAt(Id: TVNodeID; V: Int64);
    procedure Close;
    procedure Clean(Expiration: Int64);
  end;

type
  TPingStatus = (PingIng, PingSuccess, PingFailed);

  TCheckEndPointResult = class
  public
    Time: Int64;
    Status: TPingStatus;
    Node: TNode;
    Err: Exception;
    Callbacks: TList<TProc<Exception>>;
    constructor Create;
    destructor Destroy; override;
  end;

type
  ISocket = interface
    ['{YOUR_GUID_HERE}']
    function Start: Exception;
    function Stop: Exception;
    procedure Ping(Node: TNode; Callback: TProc<TNode, Exception>);
    function Pong(Hash: THash; Node: TNode): Exception;
    function SendNodes(Endpoints: TArray<TVNodeEndPoint>; ToNode: TVNode): Exception;
    function FindNode(Target: TVNodeID; Count: Integer; Node: TNode): TChannel<TArray<TVNodeEndPoint>>;
  end;

  INodeTable = interface
    ['{YOUR_GUID_HERE}']
    function Nodes(Count: Integer): TArray<TNode>;
    function Size: Integer;
    function Sub(Receiver: TProc<TVNode>): Integer;
    procedure UnSub(SubId: Integer);
    procedure Remove(Id: TVNodeID);
    function Resolve(Id: TVNodeID): TNode;
    function ResolveAddr(Addr: string): TNode;
    procedure Add(Node: TNode);
    function Oldest: TArray<TNode>;
    procedure Store(DB: INodeDB);
    function SubTreeToFind: Cardinal;
    function FindNeighbors(Target: TVNodeID; Count: Integer): TArray<TNode>;
    function FindSource(Target: TVNodeID; Count: Integer): TArray<TNode>;
    function Bubble(Id: TVNodeID): Boolean;
  end;

  IFinder = interface
    ['{YOUR_GUID_HERE}']
    function FindNeighbors(Id: TVNodeID; Target: TVNodeID; Count: Integer): TArray<TVNodeEndPoint>;
    procedure SetResolver(Resolver: IDiscovery);
    procedure Sub(Table: INodeTable);
    procedure UnSub(Table: INodeTable);
  end;

  IDiscovery = interface
    ['{YOUR_GUID_HERE}']
    function Nodes: TArray<TVNode>;
    function NodesCount: Integer;
    function SubscribeNode(Receiver: TProc<TVNode>): Integer;
    procedure Unsubscribe(SubId: Integer);
    function GetNodes(Count: Integer): TArray<TVNode>;
    procedure SetFinder(F: IFinder);
    procedure Delete(Id: TVNodeID; Reason: Exception);
    function Start: Exception;
    function Stop: Exception;
    procedure Ping(N: TNode; Callback: TProc<Exception>);
    procedure PingDelete(N: TNode);
    procedure Handle(Pkt: TPacket);
    procedure ReceiveNode(N: TNode);
    function ReceiveEndPoint(E: TVNodeEndPoint): Boolean;
  end;

  TDiscovery = class(TInterfacedObject, IDiscovery)
  private
    FNode: TVNode;
    FBootNodes: TArray<string>;
    FBootSeeds: TArray<string>;
    FBooters: TArray<IBooter>;
    FTable: INodeTable;
    FFinder: IFinder;
    FStage: TDictionary<string, TCheckEndPointResult>;
    FMu: TCriticalSection;
    FSocket: ISocket;
    FDB: TDiscvDB;
    FRunning: Integer;
    FTerm: TEvent;
    FLooking: Integer;
    FRefreshing: Boolean;
    FWG: TLightweightEvent;
    FLog: ILogger;

    procedure TableLoop;
    procedure FindLoop;
    procedure Init;
    function LoadBootNodes: Boolean;
    function GetBootNodes(Num: Integer): TArray<TNode>;
    procedure FindSubTree(Distance: Cardinal);
    procedure Refresh;
    procedure Lookup(Target: TVNodeID; Count: Integer);
    function FindNode(Target: TVNodeID; Count: Integer; N: TNode; Curr: TChannel<TObject>): Double;
    procedure ReceiveEndPointCurr(EP: TVNodeEndPoint; Ch: TChannel<TObject>; ValidCount: PInteger);

  public
    constructor Create(PeerKey: TBytes; Node: TVNode; BootNodes, BootSeeds: TArray<string>; ListenAddress: string; DB: INodeDB);
    destructor Destroy; override;

    function Nodes: TArray<TVNode>;
    function NodesCount: Integer;
    function SubscribeNode(Receiver: TProc<TVNode>): Integer;
    procedure Unsubscribe(SubId: Integer);
    function GetNodes(Count: Integer): TArray<TVNode>;
    procedure SetFinder(F: IFinder);
    procedure Delete(Id: TVNodeID; Reason: Exception);
    function Start: Exception;
    function Stop: Exception;
    procedure Ping(N: TNode; Callback: TProc<Exception>);
    procedure PingDelete(N: TNode);
    procedure Handle(Pkt: TPacket);
    procedure ReceiveNode(N: TNode);
    function ReceiveEndPoint(E: TVNodeEndPoint): Boolean;
  end;

function NewDiscovery(PeerKey: TBytes; Node: TVNode; BootNodes, BootSeeds: TArray<string>; ListenAddress: string; DB: INodeDB): IDiscovery;

implementation

uses
  System.DateUtils, System.Math, System.Random,
  net.discovery.booter, net.discovery.socket, net.discovery.table;

{ Global Variables }

initialization
  ErrDiscoveryIsRunning := ENetDiscoveryError.Create('discovery is running');
  ErrDiscoveryIsStopped := ENetDiscoveryError.Create('discovery is stopped');
  ErrDifferentNet := ENetDiscoveryError.Create('different net');
  DiscvLog := Log15.New(['module', 'discovery']);
end.

{ TNode }

constructor TNode.Create(ANode: TVNode);
begin
  inherited Create;
  Self.ID := ANode.ID;
  Self.EndPoint := ANode.EndPoint;
  Self.Net := ANode.Net;
  Self.Ext := ANode.Ext;
  Self.Signature := ANode.Signature;
  Self.PublicKey := ANode.PublicKey;
  Self.Hash := ANode.Hash;
  Self.Seq := ANode.Seq;
  Self.Signature := ANode.Signature;
  Self.PublicKey := ANode.PublicKey;
end;

function TNode.NeedCheck: Boolean;
begin
  Result := (UnixToDateTime(Self.checkAt) + (1 / 24)) < Now; // checkExpiration is 3600 seconds (1 hour)
end;

procedure TNode.Update(ANode: TNode);
begin
  Self.EndPoint := ANode.EndPoint;
  Self.Net := ANode.Net;
  Self.Ext := ANode.Ext;
  Self.Signature := ANode.Signature;
  Self.PublicKey := ANode.PublicKey;
  Self.Hash := ANode.Hash;
  Self.Seq := ANode.Seq;
  Self.Signature := ANode.Signature;
  Self.PublicKey := ANode.PublicKey;
end;

function TNode.ToString: string;
begin
  Result := Format('%s@%s', [Self.ID.ToString, Self.EndPoint.ToString]);
end;

{ TDiscvDB }

constructor TDiscvDB.Create(ANodeDB: INodeDB);
begin
  FNodeDB := ANodeDB;
end;

function TDiscvDB.StoreNode(Node: TVNode): Exception;
var
  Err: Exception;
begin
  Err := FNodeDB.StoreNode(Node);
  if Err = nil then
  begin
    FNodeDB.StoreActiveAt(Node.ID, DateTimeToUnix(Now)); // Assuming activeAt is current time
    FNodeDB.StoreCheckAt(Node.ID, DateTimeToUnix(Now)); // Assuming checkAt is current time
  end;
  Result := Err;
end;

procedure TDiscvDB.RemoveNode(Id: TVNodeID);
begin
  FNodeDB.RemoveNode(Id);
end;

function TDiscvDB.ReadNodes(Expiration: Int64): TArray<TVNode>;
var
  VNodes: TArray<TVNode>;
  I: Integer;
  N: TVNode;
  Node: TNode;
begin
  VNodes := FNodeDB.ReadNodes(Expiration);
  SetLength(Result, Length(VNodes));
  for I := 0 to High(VNodes) do
  begin
    N := VNodes[I];
    Node := TNode.Create(N);
    Node.checkAt := FNodeDB.RetrieveCheckAt(N.ID);
    Node.activeAt := FNodeDB.RetrieveActiveAt(N.ID);
    Result[I] := Node;
  end;
end;

function TDiscvDB.RetrieveActiveAt(Id: TVNodeID): Int64;
begin
  Result := FNodeDB.RetrieveActiveAt(Id);
end;

procedure TDiscvDB.StoreActiveAt(Id: TVNodeID; V: Int64);
begin
  FNodeDB.StoreActiveAt(Id, V);
end;

function TDiscvDB.RetrieveCheckAt(Id: TVNodeID): Int64;
begin
  Result := FNodeDB.RetrieveCheckAt(Id);
end;

procedure TDiscvDB.StoreCheckAt(Id: TVNodeID; V: Int64);
begin
  FNodeDB.StoreCheckAt(Id, V);
end;

procedure TDiscvDB.Close;
begin
  FNodeDB.Close;
end;

procedure TDiscvDB.Clean(Expiration: Int64);
begin
  FNodeDB.Clean(Expiration);
end;

{ TCheckEndPointResult }

constructor TCheckEndPointResult.Create;
begin
  Callbacks := TList<TProc<Exception>>.Create;
end;

destructor TCheckEndPointResult.Destroy;
begin
  Callbacks.Free;
  inherited;
end;

{ TDiscovery }

constructor TDiscovery.Create(PeerKey: TBytes; Node: TVNode; BootNodes, BootSeeds: TArray<string>; ListenAddress: string; DB: INodeDB);
begin
  FNode := Node;
  FBootNodes := BootNodes;
  FBootSeeds := BootSeeds;
  FBooters := TArray<IBooter>.Create;
  FStage := TDictionary<string, TCheckEndPointResult>.Create;
  FMu := TCriticalSection.Create;
  FRunning := 0;
  FLooking := 0;
  FRefreshing := False;
  FWG := TLightweightEvent.Create(False);
  FLog := DiscvLog;

  if Assigned(DB) then
    FDB := TDiscvDB.Create(DB);

  FSocket := NewAgent(PeerKey, FNode, ListenAddress, Handle);
  FTable := NewTable(FNode.ID, FNode.Net, nil, Self); // newListBucket is a function, needs to be passed or implemented
end;

destructor TDiscovery.Destroy;
begin
  Stop;
  FMu.Free;
  FStage.Free;
  FWG.Free;
  inherited;
end;

function TDiscovery.Nodes: TArray<TVNode>;
var
  Nodes: TArray<TNode>;
  I: Integer;
begin
  Nodes := FTable.Nodes(0);
  SetLength(Result, Length(Nodes));
  for I := 0 to High(Nodes) do
    Result[I] := Nodes[I];
end;

function TDiscovery.NodesCount: Integer;
begin
  Result := FTable.Size;
end;

function TDiscovery.SubscribeNode(Receiver: TProc<TVNode>): Integer;
begin
  Result := FTable.Sub(Receiver);
end;

procedure TDiscovery.Unsubscribe(SubId: Integer);
begin
  FTable.UnSub(SubId);
end;

function TDiscovery.GetNodes(Count: Integer): TArray<TVNode>;
var
  Nodes: TArray<TNode>;
  I: Integer;
begin
  SetLength(Result, 0);
  Nodes := FTable.Nodes(Count);
  for I := 0 to High(Nodes) do
    Result := Result + [Nodes[I]];
end;

procedure TDiscovery.SetFinder(F: IFinder);
begin
  if Assigned(FFinder) then
    FFinder.UnSub(FTable);

  F.SetResolver(Self);
  FFinder := F;
  FFinder.Sub(FTable);
end;

procedure TDiscovery.Delete(Id: TVNodeID; Reason: Exception);
begin
  FTable.Remove(Id);

  if Assigned(FDB) then
    FDB.RemoveNode(Id);

  FLog.Info(Format('remove node %s from table: %s', [Id.ToString, Reason.Message]));
end;

function TDiscovery.Start: Exception;
var
  Bt: IBooter;
  Err: Exception;
begin
  Result := nil;
  if not TInterlocked.CompareExchange(FRunning, 1, 0) = 0 then
    Exit(ErrDiscoveryIsRunning);

  // Retrieve boot nodes
  if Assigned(FDB) then
    FBooters := FBooters + [NewDBBooter(FDB)];

  if Length(FBootSeeds) > 0 then
    FBooters := FBooters + [NewNetBooter(FNode, FBootSeeds)];

  if Length(FBootNodes) > 0 then
  begin
    try
      Bt := NewCfgBooter(FBootNodes, FNode);
      FBooters := FBooters + [Bt];
    except
      on E: Exception do
        Exit(E);
    end;
  end;

  // Open socket
  Err := FSocket.Start;
  if Err <> nil then
    Exit(Exception.Create(Format('failed to start udp server: %s', [Err.Message])));

  FTerm := TEvent.Create(nil, True, False, '');

  // Maintain node table
  TThread.CreateAnonymousThread(TableLoop).Start;

  // Find more nodes
  TThread.CreateAnonymousThread(FindLoop).Start;
end;

function TDiscovery.Stop: Exception;
begin
  Result := nil;
  if TInterlocked.CompareExchange(FRunning, 0, 1) = 1 then
  begin
    FTerm.SetEvent;
    // Wait for threads to finish (not directly supported by TLightweightEvent for multiple threads)
    // You might need to manage a counter or use a TMonitor for proper waiting.
    // For simplicity, we'll just close the socket and DB.

    Result := FSocket.Stop;

    if Assigned(FDB) then
    begin
      try
        FDB.Close;
      except
        on E: Exception do
        begin
          if Result = nil then
            Result := E
          else
            Result := Exception.Create(Result.Message + '; ' + E.Message);
        end;
      end;
    end;

    FTerm.Free;
    FTerm := nil;
  end
  else
    Result := ErrDiscoveryIsStopped;
end;

procedure TDiscovery.Ping(N: TNode; Callback: TProc<Exception>);
var
  Address: string;
  Now: Int64;
  R: TCheckEndPointResult;
  Ok: Boolean;
  Callbacks: TList<TProc<Exception>>;
begin
  Address := N.Address;
  Now := DateTimeToUnix(Now);

  FMu.Acquire;
  try
    if FStage.TryGetValue(Address, R) then
    begin
      if R.Status = PingIng then
      begin
        R.Callbacks.Add(Callback);
        Exit;
      end
      else if (R.Status = PingFailed) and (Now - R.Time < 10 * 60) then
      begin
        FMu.Release;
        Callback(R.Err);
        Exit;
      end
      else if (R.Status = PingSuccess) and (Now - R.Time < 10 * 60) then
      begin
        N.Update(R.Node);
        FMu.Release;
        Callback(nil);
        Exit;
      end;
    end;

    R := TCheckEndPointResult.Create;
    R.Time := Now;
    R.Status := PingIng;
    R.Node := N;
    R.Callbacks.Add(Callback);
    FStage.AddOrSetValue(Address, R);
  finally
    FMu.Release;
  end;

  FSocket.Ping(N, procedure(Node: TNode; Err: Exception)
  var
    R: TCheckEndPointResult;
    Ok: Boolean;
    Callbacks: TList<TProc<Exception>>;
  begin
    FMu.Acquire;
    try
      if not FStage.TryGetValue(Address, R) then
      begin
        R := TCheckEndPointResult.Create;
        FStage.AddOrSetValue(Address, R);
      end;

      R.Time := DateTimeToUnix(Now);
      if Assigned(Err) then
      begin
        R.Status := PingFailed;
        R.Err := Err;
        R.Node := N;
      end
      else
      begin
        N.Update(Node);
        R.Status := PingSuccess;
        R.Node := Node;
      end;

      Callbacks := R.Callbacks;
      R.Callbacks := TList<TProc<Exception>>.Create; // Clear for next use
    finally
      FMu.Release;
    end;

    for var CB in Callbacks do
      CB(R.Err);

    Callbacks.Free;
  end);
end;

procedure TDiscovery.PingDelete(N: TNode);
begin
  Ping(N, procedure(Err: Exception)
  begin
    if Assigned(Err) then
      FTable.Remove(N.ID);
  end);
end;

procedure TDiscovery.TableLoop;
var
  CheckTicker: TTimer;
  RefreshTimer: TTimer;
  StoreTimer: TTimer;
  CleanTimer: TTimer;
  Nodes: TArray<TNode>;
  Node: TNode;
begin
  Init;

  CheckTicker := TTimer.Create(nil);
  CheckTicker.Interval := CheckInterval;
  CheckTicker.OnTimer := procedure
  begin
    Nodes := FTable.Oldest;
    for Node in Nodes do
      TThread.CreateAnonymousThread(procedure(ANode: TNode) begin PingDelete(ANode); end, Node).Start;
  end;
  CheckTicker.Enabled := True;

  RefreshTimer := TTimer.Create(nil);
  RefreshTimer.Interval := TRefresh;
  RefreshTimer.OnTimer := procedure
  begin
    TThread.CreateAnonymousThread(Init).Start;
  end;
  RefreshTimer.Enabled := True;

  if Assigned(FDB) then
  begin
    StoreTimer := TTimer.Create(nil);
    StoreTimer.Interval := StoreInterval;
    StoreTimer.OnTimer := procedure
    begin
      FTable.Store(FDB);
    end;
    StoreTimer.Enabled := True;

    CleanTimer := TTimer.Create(nil);
    CleanTimer.Interval := DbCleanInterval;
    CleanTimer.OnTimer := procedure
    begin
      FDB.Clean(SeedMaxAge);
    end;
    CleanTimer.Enabled := True;
  end;

  FTerm.WaitFor;

  CheckTicker.Free;
  RefreshTimer.Free;
  if Assigned(StoreTimer) then StoreTimer.Free;
  if Assigned(CleanTimer) then CleanTimer.Free;

  if Assigned(FDB) then
    FTable.Store(FDB);
end;

procedure TDiscovery.FindLoop;
var
  Duration: Cardinal;
  Ticker: TTimer;
  Distance: Cardinal;
begin
  Duration := 30 * 1000; // 30 seconds

  Ticker := TTimer.Create(nil);
  Ticker.Interval := Duration;
  Ticker.OnTimer := procedure
  begin
    if FTable.Size = 0 then
      Init
    else
    begin
      Distance := FTable.SubTreeToFind;
      if Distance > 0 then
        FindSubTree(Distance);
    end;
  end;
  Ticker.Enabled := True;

  FTerm.WaitFor;

  Ticker.Free;
end;

procedure TDiscovery.Handle(Pkt: TPacket);
var
  Exist: Boolean;
  N: TNode;
  Find: TFindNodePacketBody;
  Eps: TArray<TVNodeEndPoint>;
  Node: TNode;
begin
  Exist := FTable.Bubble(Pkt.Id);

  case Pkt.Code of
    CodePing:
      begin
        N := TNode.FromPing(Pkt);
        if N.Net = FNode.Net then
          FSocket.Pong(Pkt.Hash, N);

        if not Exist then
          FTable.Add(N);
      end;
    CodePong:
      begin
        // Handled by requestPool in socket
      end;
    CodeFindnode:
      begin
        Find := Pkt.Body as TFindNodePacketBody;
        SetLength(Eps, 0);
        if Assigned(FFinder) then
          Eps := FFinder.FindNeighbors(Pkt.Id, Find.Target, Find.Count div 2);

        if Length(Eps) < Find.Count then
        begin
          Nodes := FTable.FindNeighbors(Find.Target, Find.Count - Length(Eps));
          for Node in Nodes do
            Eps := Eps + [Node.EndPoint];
        end;

        FSocket.SendNodes(Eps, Pkt.From);
      end;
    CodeNeighbors:
      begin
        // Nothing
      end;
  end;
end;

procedure TDiscovery.ReceiveNode(N: TNode);
var
  Addr: string;
  Err: Exception;
begin
  if N.Net <> FNode.Net then
    Exit;

  if Assigned(FTable.Resolve(N.ID)) then
    Exit;

  Addr := N.UDPAddress;
  if Assigned(FTable.ResolveAddr(Addr)) then
    Exit;

  if N.NeedCheck then
  begin
    Ping(N, procedure(Err: Exception)
    begin
      if not Assigned(Err) then
        FTable.Add(N);
    end);
  end
  else
    FTable.Add(N);
end;

function TDiscovery.ReceiveEndPoint(E: TVNodeEndPoint): Boolean;
var
  Addr: string;
  Node: TNode;
  Err: Exception;
begin
  Result := False;
  Addr := E.ToString;
  if Assigned(FTable.ResolveAddr(Addr)) then
    Exit;

  Node := TNode.FromEndPoint(E);
  if Node = nil then
    Exit;

  Ping(Node, procedure(Err: Exception)
  begin
    if not Assigned(Err) then
      FTable.Add(Node);
  end);

  Result := True;
end;

function TDiscovery.GetBootNodes(Num: Integer): TArray<TNode>;
var
  Btr: IBooter;
begin
  SetLength(Result, 0);
  for Btr in FBooters do
    Result := Result + Btr.GetBootNodes(Num);
end;

procedure TDiscovery.Init;
var
  FailedCount: Integer;
  BootNodes: TArray<TNode>;
  Node: TNode;
begin
  DiscvLog.Info('init');
  FailedCount := 0;
Load:
  BootNodes := GetBootNodes(BucketSize);

  if Length(BootNodes) = 0 then
  begin
    Inc(FailedCount);
    if FailedCount > 5 then
    begin
      // TODO: Handle this case, maybe log a critical error or stop discovery
      Exit;
    end;
    Sleep(1000); // Wait a bit before retrying
    goto Load;
  end;

  DiscvLog.Info(Format('load %d bootNodes', [Length(BootNodes)]));

  for Node in BootNodes do
    ReceiveNode(Node);

  Refresh;
end;

procedure TDiscovery.FindSubTree(Distance: Cardinal);
begin
  FMu.Acquire;
  try
    if FRefreshing then
      Exit;
  finally
    FMu.Release;
  end;

  Lookup(TVNodeID.RandFromDistance(FNode.ID, Distance), BucketSize);
end;

procedure TDiscovery.Refresh;
var
  I: Cardinal;
  Id: TVNodeID;
begin
  FMu.Acquire;
  try
    if FRefreshing then
      Exit;
    FRefreshing := True;
  finally
    FMu.Release;
  end;

  for I := 0 to TVNodeID.IDBits - 1 do
  begin
    Id := TVNodeID.RandFromDistance(FNode.ID, I);
    Lookup(Id, BucketSize);
  end;

  FMu.Acquire;
  try
    FRefreshing := False;
  finally
    FMu.Release;
  end;
end;

procedure TDiscovery.Lookup(Target: TVNodeID; Count: Integer);
var
  Nodes: TArray<TNode>;
  I: Integer;
  Ratio: Double;
  CurrChannel: TChannel<TObject>;
begin
  if not TInterlocked.CompareExchange(FLooking, 1, 0) = 0 then
    Exit;

  try
    Nodes := FTable.FindSource(Target, Count);
    if Length(Nodes) = 0 then
      Exit;

    CurrChannel := TChannel<TObject>.Create;
    try
      for I := 0 to High(Nodes) do
      begin
        Ratio := FindNode(Target, Count, Nodes[I], CurrChannel);
        if Ratio < 0.3 then
        begin
          if Random(10) < 5 then
            Break;
        end;
      end;
    finally
      CurrChannel.Free;
    end;
  finally
    TInterlocked.Exchange(FLooking, 0);
  end;
end;

function TDiscovery.FindNode(Target: TVNodeID; Count: Integer; N: TNode; Curr: TChannel<TObject>): Double;
var
  EPChannel: TChannel<TArray<TVNodeEndPoint>>;
  Err: Exception;
  Total: Integer;
  Valid: Integer;
  Eps: TArray<TVNodeEndPoint>;
  EP: TVNodeEndPoint;
begin
  Total := 0;
  Valid := 0;

  EPChannel := FSocket.FindNode(Target, Count, N);
  try
    while EPChannel.Receive(Eps) do
    begin
      Total := Total + Length(Eps);
      if Length(Eps) > 0 then
      begin
        for EP in Eps do
        begin
          Curr.Send(nil); // Send a dummy object to signal a slot taken
          TThread.CreateAnonymousThread(procedure(AEP: TVNodeEndPoint; AChannel: TChannel<TObject>; AValidCount: PInteger)
          begin
            ReceiveEndPointCurr(AEP, AChannel, AValidCount);
          end, EP, Curr, @Valid).Start;
        end;
      end;
    end;
  finally
    EPChannel.Free;
  end;

  N.FindDone; // Assuming TNode has a FindDone method

  if Total = 0 then
    Result := 0
  else
    Result := Valid / Total;
end;

procedure TDiscovery.ReceiveEndPointCurr(EP: TVNodeEndPoint; Ch: TChannel<TObject>; ValidCount: PInteger);
begin
  if ReceiveEndPoint(EP) then
    TInterlocked.Increment(ValidCount);

  Ch.Receive; // Receive the dummy object to free the slot
end;

function NewDiscovery(PeerKey: TBytes; Node: TVNode; BootNodes, BootSeeds: TArray<string>; ListenAddress: string; DB: INodeDB): IDiscovery;
begin
  Result := TDiscovery.Create(PeerKey, Node, BootNodes, BootSeeds, ListenAddress, DB);
end;
