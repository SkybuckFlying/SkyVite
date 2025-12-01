unit net.connector.connector;

interface

uses
  System.SysUtils, System.Classes, System.Net.Sockets, System.Threading,
  Log15, net.vnode;

type
  IFinder = interface
    ['{YOUR_GUID_HERE}']
    function Nodes: TArray<TVNode>;
  end;

  TOnNodeHandler = reference to function(Node: TVNode): Boolean;
  TOnConnectionHandler = reference to procedure(Conn: TSocket; Inbound: Boolean);

  TConnector = class
  private
    FListenAddress: string;
    FServer: TSocket;
    FFinder: IFinder;
    FOnNode: TOnNodeHandler;
    FOnConnection: TOnConnectionHandler;
    FTerm: TEvent;
    FLog: ILogger;
    FListenerThread: TThread;
    FFindLoopThread: TThread;

    procedure DoListen;
    procedure DoFindLoop;

  public
    constructor Create(ListenAddress: string; Finder: IFinder; OnNodeHandler: TOnNodeHandler; OnConnectionHandler: TOnConnectionHandler);
    destructor Destroy; override;
    function Start: Exception;
    procedure Stop;
    function ConnectNode(Node: TVNode): Exception;
  end;

function NewConnector(ListenAddress: string; Finder: IFinder; OnNodeHandler: TOnNodeHandler; OnConnectionHandler: TOnConnectionHandler): TConnector;

implementation

uses
  Winapi.Windows; // For Sleep

{ TConnector }

constructor TConnector.Create(ListenAddress: string; Finder: IFinder; OnNodeHandler: TOnNodeHandler; OnConnectionHandler: TOnConnectionHandler);
begin
  FListenAddress := ListenAddress;
  FFinder := Finder;
  FOnNode := OnNodeHandler;
  FOnConnection := OnConnectionHandler;
  FLog := Log15.New(['module', 'connector']);
  FTerm := TEvent.Create(nil, True, False, ''); // Manual-reset, initially non-signaled
end;

destructor TConnector.Destroy;
begin
  Stop;
  FTerm.Free;
  inherited;
end;

function TConnector.Start: Exception;
var
  Addr: TSocketAddress;
begin
  Result := nil;
  try
    Addr := TSocketAddress.Create(FListenAddress);
    FServer := TSocket.Create(Addr.Family, sock_STREAM, IPPROTO_TCP);
    FServer.Bind(Addr);
    FServer.Listen(SOMAXCONN);

    FListenerThread := TThread.CreateAnonymousThread(DoListen);
    FListenerThread.Start;

    FFindLoopThread := TThread.CreateAnonymousThread(DoFindLoop);
    FFindLoopThread.Start;

  except
    on E: Exception do
      Result := E;
  end;
end;

procedure TConnector.Stop;
begin
  if Assigned(FServer) then
  begin
    FServer.Close;
    FServer.Free;
    FServer := nil;
  end;
  FTerm.SetEvent; // Signal termination
  if Assigned(FListenerThread) then
  begin
    FListenerThread.WaitFor;
    FreeAndNil(FListenerThread);
  end;
  if Assigned(FFindLoopThread) then
  begin
    FFindLoopThread.WaitFor;
    FreeAndNil(FFindLoopThread);
  end;
end;

procedure TConnector.DoListen;
var
  Conn: TSocket;
  TempDelay: Cardinal;
  MaxDelay: Cardinal;
  Err: Integer;
begin
  TempDelay := 0;
  MaxDelay := 1000; // 1 second

  while not FTerm.WaitFor(0) = wrSignaled do
  begin
    try
      Conn := FServer.Accept;
      TempDelay := 0; // Reset delay on successful accept
      TThread.CreateAnonymousThread(procedure
      begin
        FOnConnection(Conn, True);
      end).Start;
    except
      on E: ESocketError do
      begin
        Err := E.ErrorCode;
        // Check for temporary errors (e.g., WSAEINTR, WSAEWOULDBLOCK)
        if (Err = WSAEINTR) or (Err = WSAEWOULDBLOCK) then // These are common temporary errors on Windows
        begin
          if TempDelay = 0 then
            TempDelay := 5;
          TempDelay := TempDelay * 2;
          if TempDelay > MaxDelay then
            TempDelay := MaxDelay;
          Sleep(TempDelay);
          Continue;
        end;
        FLog.Error(Format('Accept error: %s', [E.Message]));
        Break; // Break on non-temporary errors
      end;
      on E: Exception do
      begin
        FLog.Error(Format('Unexpected error in DoListen: %s', [E.Message]));
        Break;
      end;
    end;
  end;
end;

procedure TConnector.DoFindLoop;
const
  InitDuration = 10000; // 10 seconds
  MaxDuration = 160000; // 160 seconds
var
  Duration: Cardinal;
  Nodes: TArray<TVNode>;
  Node: TVNode;
begin
  Duration := InitDuration;

  while not FTerm.WaitFor(Duration) = wrSignaled do
  begin
    Nodes := FFinder.Nodes;

    if Length(Nodes) > 0 then
    begin
      for Node in Nodes do
      begin
        if FOnNode(Node) then
        begin
          // ConnectNode runs in its own goroutine in Go, so we'll do the same here.
          TThread.CreateAnonymousThread(procedure
          begin
            ConnectNode(Node);
          end).Start;
        end;
      end;
      Duration := InitDuration; // Reset duration after finding nodes
    end
    else
    begin
      if Duration < MaxDuration then
        Duration := Duration * 2
      else
        Duration := InitDuration;
    end;
  end;
end;

function TConnector.ConnectNode(Node: TVNode): Exception;
var
  Addr: TSocketAddress;
  Conn: TSocket;
begin
  Result := nil;
  try
    Addr := TSocketAddress.Create(Node.Address);
    Conn := TSocket.Create(Addr.Family, sock_STREAM, IPPROTO_TCP);
    Conn.Connect(Addr);
    FOnConnection(Conn, False);
  except
    on E: Exception do
    begin
      Result := E;
      FLog.Error(Format('Failed to connect to node %s: %s', [Node.Address, E.Message]));
    end;
  end;
end;

function NewConnector(ListenAddress: string; Finder: IFinder; OnNodeHandler: TOnNodeHandler; OnConnectionHandler: TOnConnectionHandler): TConnector;
begin
  Result := TConnector.Create(ListenAddress, Finder, OnNodeHandler, OnConnectionHandler);
end;

end.
