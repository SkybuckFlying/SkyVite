unit RpcApi.Apis;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vite,
  Rpc,
  RpcApi.Api,
  RpcApi.Api.Filters;

type
  TApiType = (
    HEALTH,
    WALLET,
    PRIVATE_ONROAD,
    POW,
    DEBUG,
    CONSENSUSGROUP,
    LEDGER,
    PUBLIC_ONROAD,
    NET,
    CONTRACT,
    REGISTER,
    VOTE,
    MINTAGE,
    PLEDGE,
    DEXFUND,
    DEXTRADE,
    DEX,
    PRIVATE_DEX,
    TX,
    DASHBOARD,
    SUBSCRIBE,
    SBPSTATS,
    UTIL,
    DATA,
    LEDGERDEBUG,
    VIRTUAL,
    apiTypeLimit
  );

  TApiTypeHelper = record helper for TApiType
  public
    function Name: string;
    function Ordinal: Integer;
    class function Values: TArray<string>; static;
  end;

const
  ConstApiTypeStrings: array[TApiType] of string = (
    'health',
    'wallet',
    'private_onroad',
    'pow',
    'debug',
    'consensusGroup',
    'ledger',
    'public_onroad',
    'net',
    'contract',
    'register',
    'vote',
    'mintage',
    'pledge',
    'dexfund',
    'dextrade',
    'dex',
    'private_dex',
    'tx',
    'dashboard',
    'subscribe',
    'sbpstats',
    'util',
    'data',
    'ledgerdebug',
    'virtual'
  );

procedure Init(ParaDir: string; ParaLvl: string; ParaTestApiPrikey: string; ParaTestApiTti: string; ParaNetId: Cardinal; ParaDexAvailable: PBoolean);
function GetApi(ParaVite: TVite; ParaApiModule: string): TRpcAPI;
function GetApis(ParaVite: TVite; ParaApiModules: array of string): TDictionary<string, TRpcAPI>;
function MergeApis(ParaFirst: TDictionary<string, TRpcAPI>; ParaSecond: TDictionary<string, TRpcAPI>): TArray<TRpcAPI>;
function GetPublicApis(ParaVite: TVite): TDictionary<string, TRpcAPI>;

implementation

uses
  System.Rtti;

{ TApiTypeHelper }

function TApiTypeHelper.Name: string;
begin
  Result := ConstApiTypeStrings[Self];
end;

function TApiTypeHelper.Ordinal: Integer;
begin
  Result := System.Ord(Self);
end;

class function TApiTypeHelper.Values: TArray<string>;
var
  vIndex: Integer;
  vApiType: TApiType;
begin
  SetLength(Result, System.Ord(apiTypeLimit));
  vIndex := 0;
  for vApiType := Low(TApiType) to High(TApiType) do
  begin
    if vApiType = apiTypeLimit then
    begin
      break;
    end;
    Result[vIndex] := ConstApiTypeStrings[vApiType];
    Inc(vIndex);
  end;
end;

procedure Init(ParaDir: string; ParaLvl: string; ParaTestApiPrikey: string; ParaTestApiTti: string; ParaNetId: Cardinal; ParaDexAvailable: PBoolean);
begin
  TApi.InitLog(ParaDir, ParaLvl);
  TApi.InitTestAPIParams(ParaTestApiPrikey, ParaTestApiTti);
  TApi.InitConfig(ParaNetId, ParaDexAvailable);
end;

function GetApi(ParaVite: TVite; ParaApiModule: string): TRpcAPI;
begin
  if ParaApiModule = ConstApiTypeStrings[TApiType.HEALTH] then
  begin
    Result := TRpcAPI.Create('health', '1.0', THealthApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.WALLET] then
  begin
    Result := TRpcAPI.Create('wallet', '1.0', TWalletApi.Create(ParaVite), False);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.PRIVATE_ONROAD] then
  begin
    Result := TRpcAPI.Create('onroad', '1.0', TPrivateOnroadApi.Create(ParaVite), False);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.POW] then
  begin
    Result := TRpcAPI.Create('pow', '1.0', TPow.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DEBUG] then
  begin
    Result := TRpcAPI.Create('debug', '1.0', TDeprecated.Create, True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.CONSENSUSGROUP] then
  begin
    Result := TRpcAPI.Create('debug', '1.0', TDeprecated.Create, True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.LEDGER] then
  begin
    Result := TRpcAPI.Create('ledger', '1.0', TLedgerApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.PUBLIC_ONROAD] then
  begin
    Result := TRpcAPI.Create('onroad', '1.0', TPublicOnroadApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.NET] then
  begin
    Result := TRpcAPI.Create('net', '1.0', TNetApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.CONTRACT] then
  begin
    Result := TRpcAPI.Create('contract', '1.0', TContractApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.REGISTER] then
  begin
    Result := TRpcAPI.Create('register', '1.0', TRegisterApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.VOTE] then
  begin
    Result := TRpcAPI.Create('vote', '1.0', TVoteApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.MINTAGE] then
  begin
    Result := TRpcAPI.Create('mintage', '1.0', TMintageAPI.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.PLEDGE] then
  begin
    Result := TRpcAPI.Create('pledge', '1.0', TQuotaApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DEXFUND] then
  begin
    Result := TRpcAPI.Create('dexfund', '1.0', TDexFundApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DEXTRADE] then
  begin
    Result := TRpcAPI.Create('dextrade', '1.0', TDexTradeApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DEX] then
  begin
    Result := TRpcAPI.Create('dex', '1.0', TDexApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.PRIVATE_DEX] then
  begin
    Result := TRpcAPI.Create('dex', '1.0', TDexPrivateApi.Create(ParaVite), False);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.TX] then
  begin
    Result := TRpcAPI.Create('tx', '1.0', TTxApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DASHBOARD] then
  begin
    Result := TRpcAPI.Create('dashboard', '1.0', TDashboardApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.SUBSCRIBE] then
  begin
    Result := TRpcAPI.Create('subscribe', '1.0', TSubscribeApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.SBPSTATS] then
  begin
    Result := TRpcAPI.Create('sbpstats', '1.0', TStatsApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.UTIL] then
  begin
    Result := TRpcAPI.Create('util', '1.0', TUtilApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.DATA] then
  begin
    Result := TRpcAPI.Create('data', '1.0', TDataApi.Create(ParaVite), True);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.LEDGERDEBUG] then
  begin
    Result := TRpcAPI.Create('ledgerdebug', '1.0', TLedgerDebugApi.Create(ParaVite), False);
  end
  else if ParaApiModule = ConstApiTypeStrings[TApiType.VIRTUAL] then
  begin
    Result := TRpcAPI.Create('virtual', '1.0', TVirtualApi.Create(ParaVite), False);
  end
  else
  begin
    Result := TRpcAPI.Create(ParaApiModule, '', nil, False);
  end;
end;

function GetApis(ParaVite: TVite; ParaApiModules: array of string): TDictionary<string, TRpcAPI>;
var
  vModule: string;
begin
  Result := TDictionary<string, TRpcAPI>.Create;
  for vModule in ParaApiModules do
  begin
    Result.Add(vModule, GetApi(ParaVite, vModule));
  end;
end;

function MergeApis(ParaFirst: TDictionary<string, TRpcAPI>; ParaSecond: TDictionary<string, TRpcAPI>): TArray<TRpcAPI>;
var
  vResultMap: TDictionary<string, TRpcAPI>;
  vKey: string;
  vApi: TRpcAPI;
  vIndex: Integer;
begin
  vResultMap := TDictionary<string, TRpcAPI>.Create;
  try
    for vKey in ParaFirst.Keys do
    begin
      vApi := ParaFirst[vKey];
      vResultMap.Add(vKey, vApi);
    end;
    for vKey in ParaSecond.Keys do
    begin
      vApi := ParaSecond[vKey];
      if not vResultMap.ContainsKey(vKey) then
      begin
        vResultMap.Add(vKey, vApi);
      end;
    end;
    SetLength(Result, vResultMap.Count);
    vIndex := 0;
    for vApi in vResultMap.Values do
    begin
      Result[vIndex] := vApi;
      Inc(vIndex);
    end;
  finally
    vResultMap.Free;
  end;
end;

function GetPublicApis(ParaVite: TVite): TDictionary<string, TRpcAPI>;
begin
  Result := GetApis(
    ParaVite,
    [
      TApiType.LEDGER.Name,
      TApiType.NET.Name,
      TApiType.CONTRACT.Name,
      TApiType.UTIL.Name,
      TApiType.HEALTH.Name
    ]
  );
end;

end.
