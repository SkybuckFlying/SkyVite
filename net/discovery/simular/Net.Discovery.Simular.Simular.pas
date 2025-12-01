program simular;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.Net.Sockets,
  System.Net.HttpClient,
  System.Net.HttpClient.Win.Utils,
  System.DateUtils,
  crypto.ed25519,
  net.vnode,
  net.discovery.discovery;

type
  TConfig = record
    PeerKey: TBytes;
    Node: TVNode;
    BootNodes: TArray<string>;
    ListenAddress: string;
  end;

procedure StartDiscovery(D: IDiscovery);
var
  Err: Exception;
begin
  Err := D.Start;
  if Assigned(Err) then
  begin
    Writeln(Format('Failed to start discovery: %s', [Err.Message]));
    // In a real application, you might want to handle this more gracefully
    Exit;
  end;
end;

var
  Port: Integer;
  Total: Integer;
  Err: Exception;
  Configs: TArray<TConfig>;
  I, J: Integer;
  Pub, Prv: TBytes;
  Id: TVNodeID;
  Cfg: TConfig;
  Discovers: TArray<IDiscovery>;
  D: IDiscovery;
  Count: Integer;
  Ticker: TTimer;
  HTTPServer: TIdHTTPServer; // For http.ListenAndServe equivalent
begin
  Port := 9000;
  Total := 100;

  SetLength(Configs, 0);
  for I := 0 to Total - 1 do
  begin
    GenerateKey(Pub, Prv);
    Id := TVNodeID.FromBytes(Pub);

    Cfg.PeerKey := Prv;
    Cfg.Node := TVNode.Create;
    Cfg.Node.ID := Id;
    Cfg.Node.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
    Cfg.Node.EndPoint.Port := Port;
    Cfg.Node.EndPoint.Typ := HostIPv4;
    Cfg.Node.Net := 0;
    Cfg.Node.Ext := nil;
    Cfg.ListenAddress := '127.0.0.1:' + IntToStr(Port);

    SetLength(Cfg.BootNodes, 0);
    for J := 1 to 1 do // Equivalent to Go's j < 2
    begin
      if (I - J >= 0) and (I - J < Length(Configs)) then
      begin
        Cfg.BootNodes := Cfg.BootNodes + [Configs[I - J].Node.ToString];
      end;
    end;

    Inc(Port);
    Configs := Configs + [Cfg];
  end;

  SetLength(Discovers, 0);
  for Cfg in Configs do
  begin
    D := NewDiscovery(Cfg.PeerKey, Cfg.Node, Cfg.BootNodes, nil, Cfg.ListenAddress, nil);
    Discovers := Discovers + [D];
    TThread.CreateAnonymousThread(procedure
    begin
      StartDiscovery(D);
    end).Start;
  end;

  Writeln('start');

  Count := 0;
  Ticker := TTimer.Create(nil);
  Ticker.Interval := 10 * 1000; // 10 seconds
  Ticker.OnTimer := procedure
  var
    I: Integer;
    Disc: IDiscovery;
  begin
    for I := 0 to High(Discovers) do
    begin
      Disc := Discovers[I];
      Writeln(Format('%d %d %d', [Count, I, Disc.NodesCount]));
    end;
    Writeln('------------');
    Inc(Count);
  end;
  Ticker.Enabled := True;

  // Simulate http.ListenAndServe("0.0.0.0:8080", nil)
  // This requires a separate HTTP server component, e.g., Indy's TIdHTTPServer
  // For a simple simulation, we'll just keep the console app running.
  // In a real scenario, you'd integrate a proper HTTP server.
  HTTPServer := TIdHTTPServer.Create(nil);
  try
    HTTPServer.DefaultPort := 8080;
    HTTPServer.Bindings.Add.IP := '0.0.0.0';
    HTTPServer.Bindings.Items[0].Port := 8080;
    HTTPServer.Active := True;
    Writeln('HTTP server listening on 0.0.0.0:8080 (dummy)');

    // Keep the application running indefinitely
    Readln; // Wait for user input to terminate

  finally
    HTTPServer.Active := False;
    HTTPServer.Free;
    Ticker.Free;
    for D in Discovers do
      D.Stop;
  end;
end.
