unit RpcApi.Api.OnRoad;

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
  Vite Common.Types RpcApi.Api.Ledger RpcApi.Api.LedgerModel;

type
  TOnroadPagingQuery = record
    Addr: TAddress;
    PageNum: UInt64;
    PageCount: UInt64;
  end;

  TPrivateOnroadApi = class
  private
    FLedgerApi: TLedgerApi;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    // Deprecated
    function GetOnroadBlocksByAddress(const Address: TAddress; Index, Count: UInt64): TArray<TAccountBlock>;
    function GetOnroadInfoByAddress(const Address: TAddress): TRpcAccountInfo;
    function GetOnroadBlocksInBatch(const QueryList: TArray<TOnroadPagingQuery>): TDictionary<TAddress, TArray<TAccountBlock>>;
    function GetOnroadInfoInBatch(const AddrList: TArray<TAddress>): TArray<TRpcAccountInfo>;
  end;

  TPublicOnroadApi = class
  private
    FApi: TPrivateOnroadApi;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
  end;

implementation

{ TPrivateOnroadApi }

constructor TPrivateOnroadApi.Create(AVite: TVite);
begin
  FLedgerApi := TLedgerApi.Create(AVite);
end;

function TPrivateOnroadApi.GetString: string;
begin
  Result := 'PrivateOnroadApi';
end;

function TPrivateOnroadApi.GetOnroadBlocksByAddress(const Address: TAddress; Index, Count: UInt64): TArray<TAccountBlock>;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FLedgerApi.FVite);
  Result := ApiV2.GetUnreceivedBlocksByAddress(Address, Index, Count);
end;

function TPrivateOnroadApi.GetOnroadInfoByAddress(const Address: TAddress): TRpcAccountInfo;
var
  Info: PAccountInfo;
begin
  Info := FLedgerApi.FChain.GetAccountOnRoadInfo(Address);
  if Info = nil then
    Exit;
  Result := ToRpcAccountInfo(FLedgerApi.FChain, Info);
end;

function TPrivateOnroadApi.GetOnroadBlocksInBatch(const QueryList: TArray<TOnroadPagingQuery>): TDictionary<TAddress, TArray<TAccountBlock>>;
var
  Queries: TArray<TPagingQueryBatch>;
  V: TOnroadPagingQuery;
  ApiV2: TLedgerApiV2;
begin
  SetLength(Queries, Length(QueryList));
  for V in QueryList do
    Queries := Queries + [TPagingQueryBatch.Create(V.Addr, V.PageNum, V.PageCount)];
  ApiV2 := TLedgerApiV2.Create(FLedgerApi.FVite);
  Result := ApiV2.GetUnreceivedBlocksInBatch(Queries);
end;

function TPrivateOnroadApi.GetOnroadInfoInBatch(const AddrList: TArray<TAddress>): TArray<TRpcAccountInfo>;
var
  AddrMap: TDictionary<TAddress, Boolean>;
  V, Addr: TAddress;
  ResultList: TArray<TRpcAccountInfo>;
  Info: PAccountInfo;
begin
  AddrMap := TDictionary<TAddress, Boolean>.Create;
  for V in AddrList do
    AddrMap.Add(V, True);
  SetLength(ResultList, 0);
  for Addr in AddrMap.Keys do
  begin
    Info := FLedgerApi.FChain.GetAccountOnRoadInfo(Addr);
    if Info = nil then
      Continue;
    ResultList := ResultList + [ToRpcAccountInfo(FLedgerApi.FChain, Info)];
  end;
  Result := ResultList;
end;

{ TPublicOnroadApi }

constructor TPublicOnroadApi.Create(AVite: TVite);
begin
  FApi := TPrivateOnroadApi.Create(AVite);
end;

function TPublicOnroadApi.GetString: string;
begin
  Result := 'PublicOnroadApi';
end;

end.
