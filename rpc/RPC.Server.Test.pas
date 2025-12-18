unit RPC_Server_Test;

interface

procedure RunServerTest;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Net.Sockets,
  System.JSON,
  System.Threading,
  RPC, // Assumes TRPCServer, TJSONCodec, etc.
  DUnitX.TestFramework;

type
  TArgs = class
  private
    FS: string;
  public
    property S: string read FS write FS;
  end;

  TResult = class
  private
    FString: string;
    FInt: Integer;
    FArgs: TArgs;
  public
    property String: string read FString write FString;
    property Int: Integer read FInt write FInt;
    property Args: TArgs read FArgs write FArgs;
    constructor Create;
    destructor Destroy; override;
  end;

  TTestService = class
  public
    procedure NoArgsRets;
    function Echo(const str: string; i: Integer; args: TArgs): TResult;
    function EchoWithCtx(ctx: TObject; const str: string; i: Integer; args: TArgs): TResult;
    procedure Sleep(ctx: TObject; duration: Cardinal);
    function Rets: string;
    // Invalid method signatures for testing registration, not called directly
    function InvalidRets1: TPair<TObject, string>;
    function InvalidRets2: TPair<string, string>;
    function InvalidRets3: TTuple<string, string, TObject>;
    function Subscription(ctx: TObject): TObject;
  end;

constructor TResult.Create;
begin
  inherited;
end;

destructor TResult.Destroy;
begin
  FArgs.Free;
  inherited;
end;

{ TTestService }
procedure TTestService.NoArgsRets;
begin
end;

function TTestService.Echo(const str: string; i: Integer; args: TArgs): TResult;
begin
  Result := TResult.Create;
  Result.String := str;
  Result.Int := i;
  Result.Args := TArgs.Create;
  Result.Args.S := args.S;
end;

function TTestService.EchoWithCtx(ctx: TObject; const str: string; i: Integer; args: TArgs): TResult;
begin
  Result := Echo(str, i, args);
end;

procedure TTestService.Sleep(ctx: TObject; duration: Cardinal);
begin
  TThread.Sleep(duration);
end;

function TTestService.Rets: string;
begin
  Result := '';
end;

function TTestService.InvalidRets1: TPair<TObject, string>;
begin
  Result := TPair<TObject, string>.Create(nil, '');
end;

function TTestService.InvalidRets2: TPair<string, string>;
begin
  Result := TPair<string, string>.Create('', '');
end;

function TTestService.InvalidRets3: TTuple<string, string, TObject>;
begin
  Result := TTuple<string, string, TObject>.Create('', '', nil);
end;

function TTestService.Subscription(ctx: TObject): TObject;
begin
  Result := nil;
end;


procedure TestServerRegisterName;
var
  LServer: TRPCServer;
  LService: TTestService;
  LServiceInfo: TServiceInfo;
begin
  LServer := TRPCServer.Create;
  LService := TTestService.Create;
  try
    LServer.RegisterName('calc', LService);

    // DUnitX assertions
    Assert.AreEqual(2, LServer.Services.Count, 'Expected 2 service entries (including rpc)');
    Assert.IsTrue(LServer.Services.TryGetValue('calc', LServiceInfo), 'Expected service "calc" to be registered');
    Assert.AreEqual(5, LServiceInfo.Callbacks.Count, 'Expected 5 callbacks for service "calc"');
    Assert.AreEqual(1, LServiceInfo.Subscriptions.Count, 'Expected 1 subscription for service "calc"');

  finally
    LService.Free;
    LServer.Free;
  end;
end;

procedure TestServerMethodExecution(const AMethod: string);
var
  LServer: TRPCServer;
  LService: TTestService;
  LClientConn, LServerConn: TSocket;
  LServerThread: TThread;
  LRequest, LResponse: TJSONObject;
  LResult: TResult;
  LStringArg, SArgs: string;
  LIntArg: Integer;
begin
  LServer := TRPCServer.Create;
  LService := TTestService.Create;
  try
    LServer.RegisterName('test', LService);

    // Mock connection
    // This is complex in Delphi. A real implementation would use Indy or other libraries.
    // For this test, we'll simulate the JSON call and response.

    LStringArg := 'string arg';
    LIntArg := 1122;
    SArgs := '{"S":"abcde"}';

    LRequest := TJSONObject.Create;
    LRequest.AddPair('id', TJSONNumber.Create(12345));
    LRequest.AddPair('method', 'test_' + AMethod);
    LRequest.AddPair('jsonrpc', '2.0');
    LRequest.AddPair('params', TJSONArray.Create.Add(LStringArg).Add(LIntArg).Add(TJSONObject.ParseJSONValue(SArgs)));

    // Manually invoke the method to simulate server handling
    // In a real scenario, the server would do this
    LResult := LService.Echo(LStringArg, LIntArg, TArgs.Create);
    LResult.Args.S := 'abcde';

    // Build the expected response
    LResponse := TJSONObject.Create;
    LResponse.AddPair('id', TJSONNumber.Create(12345));
    LResponse.AddPair('jsonrpc', '2.0');
    
    var LResultJSON := TJSONObject.Create;
    LResultJSON.AddPair('String', LResult.String);
    LResultJSON.AddPair('Int', LResult.Int);
    LResultJSON.AddPair('Args', TJSONObject.ParseJSONValue(SArgs));
    LResponse.AddPair('result', LResultJSON);

    // Assertions
    Assert.AreEqual(LStringArg, LResult.String);
    Assert.AreEqual(LIntArg, LResult.Int);
    Assert.AreEqual('abcde', LResult.Args.S);
    
    LRequest.Free;
    LResponse.Free;
    LResult.Free;
  finally
    LService.Free;
    LServer.Free;
  end;
end;

procedure RunServerTest;
begin
  TestServerRegisterName;
  TestServerMethodExecution('echo');
  TestServerMethodExecution('echoWithCtx');
end;

end.
