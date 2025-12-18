unit RpcApi.Api.Virtual;

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
  RpcApi.API.Net,
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
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes,
  Vite Ledger.Chain Ledger.Consensus Common.Upgrade;

type
  TVirtualApi = class
  private
    FVite: TVite;
    FChain: IChain;
    FCs: IConsensus;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    procedure Mine;
    procedure MineBatch(Number: UInt64);
    procedure AddUpgrade(Version: UInt32; Height: UInt64);
  end;

implementation

{ TVirtualApi }

constructor TVirtualApi.Create(AVite: TVite);
begin
  FVite := AVite;
  FChain := AVite.Chain;
  FCs := AVite.Consensus;
end;

function TVirtualApi.GetString: string;
begin
  Result := 'VirtualApi';
end;

procedure TVirtualApi.Mine;
begin
  FVite.Producer.SnapshotOnce;
end;

procedure TVirtualApi.MineBatch(Number: UInt64);
var
  I: UInt64;
begin
  if Number > 1000 then
    raise Exception.Create('number must be less than 1000');
  for I := 0 to Number - 1 do
    FVite.Producer.SnapshotOnce;
end;

procedure TVirtualApi.AddUpgrade(Version: UInt32; Height: UInt64);
begin
  TUpgrade.AddUpgradePoint(Version, Height);
end;

end.
