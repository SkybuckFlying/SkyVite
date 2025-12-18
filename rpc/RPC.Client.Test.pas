unit RPC.Client.Test;

interface

uses
  SysUtils, Classes,
  RPC.Client,
  IdContext, IdCustomHTTPServer, IdHTTPServer; // For mock server

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
