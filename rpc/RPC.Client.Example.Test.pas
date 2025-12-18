unit RPC.Client.Example.Test;

interface

uses
  SysUtils, Classes,
  RPC.Client; // Assuming the RPC client is in this unit

type
  TRPCClientExample = class
  public
    procedure ShowUsage;
  end;

implementation

{ TRPCClientExample }

procedure TRPCClientExample.ShowUsage;
var
  client: TRPCClient;
  response: TJSONValue; // Assuming response is JSON
  params: TArray<string>;
begin
  // 1. Create and connect the client
  // This assumes an HTTP-based RPC client, but others are possible
  client := TRPCClient.Create('http://localhost:8080');
  
  try
    // 2. Prepare the parameters for the RPC call
    SetLength(params, 2);
    params[0] := 'param1';
    params[1] := '123';
    
    // 3. Make the RPC call
    // The 'eth_getBalance' is an example method name
    response := client.Call('eth_getBalance', params);
    
    // 4. Process the response
    if response <> nil then
    begin
      Writeln('Received response: ' + response.ToString);
      // Here you would parse the JSON and use the result
    end
    else
    begin
      Writeln('No response received or an error occurred.');
    end;
    
  finally
    client.Free;
  end;
end;

end.
