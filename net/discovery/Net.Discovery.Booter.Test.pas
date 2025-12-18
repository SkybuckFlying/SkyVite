unit net.discovery.booter.test;

interface

uses
  IdBaseComponent,
  IdComponent,
  IdContext,
  IdCustomHTTPServer,
  IdHTTPServer,
  net.discovery.booter,
  Net.Discovery.Bucket.Test,
  net.discovery.discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  net.vnode,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils,
  TestFramework;

type
  TMockHandler = class
  private
    FRequest: TRequest;
    FNodes: TArray<string>;
    FTest: TTestFrameworkTest;
  public
    constructor Create(ARequest: TRequest; ANodes: TArray<string>; ATest: TTestFrameworkTest);
    destructor Destroy; override;
    procedure HandleRequest(AContext: TIdContext; ARequest: TIdHTTPRequest; AResponse: TIdHTTPResponse);
  end;

  [TestFixture]
  TBooterTest = class(TObject)
  public
    [Test]
    procedure TestNetBooter;
  end;

implementation

uses
  System.Net.HttpClient, System.Net.HttpClient.Win.Utils, System.Threading;

{ TMockHandler }

constructor TMockHandler.Create(ARequest: TRequest; ANodes: TArray<string>; ATest: TTestFrameworkTest);
begin
  FRequest := ARequest;
  FNodes := ANodes;
  FTest := ATest;
end;

destructor TMockHandler.Destroy;
begin
  FRequest.Free;
  inherited;
end;

procedure TMockHandler.HandleRequest(AContext: TIdContext; ARequest: TIdHTTPRequest; AResponse: TIdHTTPResponse);
var
  LStream: TStringStream;
  LBytes: TBytes;
  LRequest: TRequest;
  LResult: TResult;
begin
  if ARequest.Method = 'POST' then
  begin
    LStream := TStringStream.Create(ARequest.RawContent, TEncoding.UTF8);
    try
      LBytes := TBytes(LStream.Bytes);
      LRequest := TRequest.Create(nil, 0); // Create dummy for parsing
      try
        LRequest.Node := TVNode.Create; // Initialize Node
        LRequest.Node.FromJSONObject(TJSONObject.ParseJSONValue(TEncoding.UTF8.GetString(LBytes)).GetValue<TJSONObject>('node'));
        LRequest.Count := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetString(LBytes)).GetValue<Integer>('count');

        FTest.Assert.IsTrue(LRequest.Node.IsEqual(FRequest.Node), Format('Node not equal: %s %s', [LRequest.Node.ToString, FRequest.Node.ToString]));
        FTest.Assert.AreEqual(FRequest.Count, LRequest.Count, Format('Count not equal: %d %d', [FRequest.Count, LRequest.Count]));

        LResult := TResult.Create;
        try
          LResult.Code := 0;
          LResult.Message := '';
          LResult.Data := FNodes;

          AResponse.ContentType := 'application/json';
          AResponse.ContentText := LResult.ToJSON;
        finally
          LResult.Free;
        end;
      finally
        LRequest.Free;
      end;
    finally
      LStream.Free;
    end;
  end
  else
  begin
    FTest.Assert.Fail(Format('Unknown request method: %s', [ARequest.Method]));
  end;
end;

{ TBooterTest }

procedure TBooterTest.TestNetBooter;
var
  BootNodes: TArray<string>;
  Node: TVNode;
  Count: Integer;
  Boot: IBooter;
  HTTPServer: TIdHTTPServer;
  MockHandler: TMockHandler;
  ReceivedNodes: TArray<TNode>;
  I: Integer;
begin
  BootNodes := [
    '1111111111111111111111111111111111111111111111111111111111111111@111.111.111.111/10',
    '1111111111111111111111111111111111111111111111111111111111111110@111.111.111.112/10'
  ];

  Node := TVNode.Create;
  Node.ID := TVNodeID.ZERO;
  Node.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
  Node.EndPoint.Port := 8888;
  Node.EndPoint.Typ := HostIPv4;
  Node.Net := 10;
  Node.Ext := TBytes.Create(1, 2, 3);

  Count := 2;

  Boot := NewNetBooter(Node, ['http://127.0.0.1:8080']);

  HTTPServer := TIdHTTPServer.Create(nil);
  try
    HTTPServer.DefaultPort := 8080;
    HTTPServer.Bindings.Add.IP := '127.0.0.1';
    HTTPServer.Bindings.Items[0].Port := 8080;

    MockHandler := TMockHandler.Create(TRequest.Create(Node, Count), BootNodes, Self);
    HTTPServer.OnCommandGet := MockHandler.HandleRequest;

    HTTPServer.Active := True;

    TThread.Sleep(1000); // Give server time to start

    ReceivedNodes := Boot.GetBootNodes(Count);

    Assert.AreEqual(Length(BootNodes), Length(ReceivedNodes), 'Wrong bootnodes count');

    for I := 0 to High(ReceivedNodes) do
    begin
      Assert.AreEqual(BootNodes[I], ReceivedNodes[I].ToString, Format('Different bootNode: %s %s', [ReceivedNodes[I].ToString, BootNodes[I]]));
    end;

  finally
    HTTPServer.Active := False;
    HTTPServer.Free;
    MockHandler.Free;
  end;
end;

initialization
  RegisterTest(TBooterTest.Suite);
end.
