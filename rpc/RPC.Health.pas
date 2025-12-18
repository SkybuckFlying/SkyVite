unit Rpc.Health;

interface

uses
  RPC.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Http,
  RPC.Http.Test,
  RPC.Inproc,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  RPC.Json,
  RPC.Json.Test,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.Net.HttpClient,
  System.Net.URL,
  System.SysUtils;

function IsHealthCheckRouter(const ParaUrl: TURI): Boolean;

implementation

uses
  System.StrUtils;

function IsHealthCheckRouter(const ParaUrl: TURI): Boolean;
begin
  Result := SameText(ParaUrl.Path, '/health');
end;

{
var
  TimeAlarmLimit: TTimeSpan = TTimeSpan.FromMinutes(5);

type
  THealthCheck = class
  private
    mClient: TJsonRpcClient;
    mLog: ILogger;
  public
    constructor Create(const ParaEndpointUrl: string);
    procedure HealthCheck(const ParaW: THTTPResponseWriter; const ParaReq: THTTPRequest);
  end;

function NewHealthCheckClient(const ParaEndpointUrl: string): THealthCheck;
var
  vClient: TJsonRpcClient;
begin
  vClient := TJsonRpcClient.Dial(ParaEndpointUrl);
  Result := THealthCheck.Create(vClient);
end;

constructor THealthCheck.Create(const ParaClient: TJsonRpcClient);
begin
  mClient := ParaClient;
  mLog := TLog15.New(['module', 'health']);
end;

procedure THealthCheck.HealthCheck(const ParaW: THTTPResponseWriter; const ParaReq: THTTPRequest);
var
  vSnapshotBlock: TSnapshotBlock;
  vErr: Exception;
begin
  try
    mClient.Call(vSnapshotBlock, 'ledger_getLatestSnapshotBlock', []);
    if (vSnapshotBlock = nil) or (not CheckTime(vSnapshotBlock.Timestamp)) then
    begin
      mLog.Info('[failure]check node height');
      ParaW.StatusCode := 503;
      ParaW.ReasonString := 'Service Unavailable';
      ParaW.WriteString('check node height failed');
      Exit;
    end;
    mLog.Info('[success]check node height');
    ParaW.StatusCode := 200;
    ParaW.ReasonString := 'OK';
  except
    on E: Exception do
    begin
      mLog.Info('[failure]check node height');
      ParaW.StatusCode := 503;
      ParaW.ReasonString := 'Service Unavailable';
      ParaW.WriteString('check node height failed');
    end;
  end;
end;

function CheckTime(const ParaSnapshotTime: Int64): Boolean;
var
  vNowTime: TDateTime;
  vSTime: TDateTime;
begin
  vNowTime := Now;
  vSTime := TDateTime.FromUnix(ParaSnapshotTime);
  if (vNowTime < (vSTime - TimeAlarmLimit)) or (vNowTime > (vSTime + TimeAlarmLimit)) then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;
}

end.
