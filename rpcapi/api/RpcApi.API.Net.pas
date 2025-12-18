unit RpcApi.Api.Net;

interface

uses
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite Log15 Net Net.VNode;

type
  TSyncInfo = record
    From: string;
    To: string;
    Current: string;
    State: Cardinal;
    Status: string;
  end;

  TNodes = record
    Count: Integer;
    Nodes: TArray<TNode>;
  end;

  TNetApi = class
  private
    FNet: INet;
    FLog: ILogger;
  public
    constructor Create(AVite: TVite);
    function SyncInfo: TSyncInfo;
    function SyncDetail: TSyncDetail;
    function Peers: TNodeInfo;
    function PeerCount: Integer;
    function NodeInfo: TNodeInfo;
    function Nodes: TNodes;
  end;

implementation

uses System.StrUtils;

{ TNetApi }

constructor TNetApi.Create(AVite: TVite);
begin
  FNet := AVite.Net;
  FLog := TLog.New('module', 'rpc_api/net_api');
end;

function TNetApi.SyncInfo: TSyncInfo;
var
  S: TStatus;
begin
  S := FNet.Status;
  Result.From := IntToStr(S.From);
  Result.To := IntToStr(S.To);
  Result.Current := IntToStr(S.Current);
  Result.State := Cardinal(S.State);
  Result.Status := S.State.ToString;
end;

function TNetApi.SyncDetail: TSyncDetail;
begin
  Result := FNet.Detail;
end;

function TNetApi.Peers: TNodeInfo;
begin
  Result := FNet.Info;
end;

function TNetApi.PeerCount: Integer;
begin
  Result := FNet.PeerCount;
end;

function TNetApi.NodeInfo: TNodeInfo;
begin
  Result := FNet.Info;
end;

function TNetApi.Nodes: TNodes;
var
  Nodes: TArray<TNode>;
begin
  Nodes := FNet.Nodes;
  Result.Nodes := Nodes;
  Result.Count := Length(Nodes);
end;

end.
