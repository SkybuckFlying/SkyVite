unit RpcApi.Api.Health;

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
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils,
  Vite;

const
  ConstInvalidSnapshotMinutes = 3;

type
  THealth = class
  private
    mVite: TVite;
  public
    constructor Create(ParaVite: TVite);
    procedure Health;
  end;

implementation

uses
  System.DateUtils;

{ THealth }

constructor THealth.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
end;

procedure THealth.Health;
var
  vSb: PSnapshotBlock;
  vNowTime: TDateTime;
begin
  vSb := mVite.Chain.GetLatestSnapshotBlock;
  if vSb = nil then
  begin
    raise Exception.Create('check node height failed, sb nil');
  end;
  vNowTime := Now;
  if vNowTime > IncMinute(TDateTime(vSb.Timestamp), ConstInvalidSnapshotMinutes) then
  begin
    raise Exception.Create('check node height failed, height invalid');
  end;
end;

end.
