unit RpcApi.Api.Mintage;

interface

uses
  Common.Config Vm.Db RpcApi.Api.LedgerModel,
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
  System.SysUtils System.Classes System.Generics.Collections,
  Vite Common.Types Common.BigInt Ledger.Chain Log15 Vm.Contracts.Abi;

type
  TMintageParams = record
    TokenName: string;
    TokenSymbol: string;
    TotalSupply: string;
    Decimals: Byte;
    IsReIssuable: Boolean;
    MaxSupply: string;
    OwnerBurnOnly: Boolean;
  end;

  TIssueParams = record
    TokenId: TTokenTypeId;
    Amount: string;
    Beneficial: TAddress;
  end;

  TTransferOwnerParams = record
    TokenId: TTokenTypeId;
    NewOwner: TAddress;
  end;

  TMintageAPI = class
  private
    FChain: IChain;
    FVite: TVite;
    FLog: ILogger;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function GetMintData(const Param: TMintageParams): TBytes;
    function GetIssueData(const Param: TIssueParams): TBytes;
    function GetBurnData: TBytes;
    function GetTransferOwnerData(const Param: TTransferOwnerParams): TBytes;
    function GetChangeTokenTypeData(const TokenId: TTokenTypeId): TBytes;
    // Deprecated
    function GetTokenInfoList(Index, Count: Integer): TTokenInfoList;
    function GetTokenInfoById(const TokenId: TTokenTypeId): TRpcTokenInfo;
    function GetTokenInfoListByOwner(const Owner: TAddress): TArray<TRpcTokenInfo>;
  end;

implementation

uses System.StrUtils;

function StringToBigInt(S: PString): TBigInteger;
begin
  Result := TBigInteger.Create;
  if S <> nil then
    Result.SetString(S^, 10);
end;

function GetVmDb(Chain: IChain; Addr: TAddress): IVmDb;
begin
  // Simplified
  Result := TVmDb.Create(Chain, @Addr, nil, nil);
end;

function CheckGenesisToken(Db: IVmDb; Owner: TAddress; GenesisTokenInfoMap: TDictionary<string, PTokenInfo>; TokenList: TArray<TRpcTokenInfo>): TArray<TRpcTokenInfo>;
var
  TidStr: string;
  Tid: TTokenTypeId;
  Info: PTokenInfo;
begin
  for TidStr in GenesisTokenInfoMap.Keys do
  begin
    Tid := TTokenTypeId.FromHex(TidStr);
    Info := TAbi.GetTokenByID(Db, Tid);
    if (Info <> nil) and (Info.Owner = Owner) then
      TokenList := TokenList + [RawTokenInfoToRpc(Info, Tid)];
  end;
  Result := TokenList;
end;

function GetRange(Index, Count, ListLen: Integer; out Start, &End: Integer): Boolean;
begin
  // Implementation needed
  Result := True;
end;

function ByNameSort(const A, B: TRpcTokenInfo): Integer;
begin
  if A.TokenName = B.TokenName then
    Result := CompareStr(A.TokenId.ToString, B.TokenId.ToString)
  else
    Result := CompareStr(A.TokenName, B.TokenName);
end;

{ TMintageAPI }

constructor TMintageAPI.Create(AVite: TVite);
begin
  FChain := AVite.Chain;
  FVite := AVite;
  FLog := TLog.New('module', 'rpc_api/mintage');
end;

function TMintageAPI.GetString: string;
begin
  Result := 'MintageApi';
end;

function TMintageAPI.GetMintData(const Param: TMintageParams): TBytes;
var
  TotalSupply, MaxSupply: TBigInteger;
begin
  TotalSupply := StringToBigInt(@Param.TotalSupply);
  MaxSupply := StringToBigInt(@Param.MaxSupply);
  Result := TAbiAsset.PackMethod(TAbi.MethodNameIssue, [Param.IsReIssuable, Param.TokenName, Param.TokenSymbol, TotalSupply, Param.Decimals, MaxSupply, Param.OwnerBurnOnly]);
end;

function TMintageAPI.GetIssueData(const Param: TIssueParams): TBytes;
var
  Amount: TBigInteger;
begin
  Amount := StringToBigInt(@Param.Amount);
  Result := TAbiAsset.PackMethod(TAbi.MethodNameReIssue, [Param.TokenId, Amount, Param.Beneficial]);
end;

function TMintageAPI.GetBurnData: TBytes;
begin
  Result := TAbiAsset.PackMethod(TAbi.MethodNameBurn, []);
end;

function TMintageAPI.GetTransferOwnerData(const Param: TTransferOwnerParams): TBytes;
begin
  Result := TAbiAsset.PackMethod(TAbi.MethodNameTransferOwnership, [Param.TokenId, Param.NewOwner]);
end;

function TMintageAPI.GetChangeTokenTypeData(const TokenId: TTokenTypeId): TBytes;
begin
  Result := TAbiAsset.PackMethod(TAbi.MethodNameDisableReIssue, [TokenId]);
end;

function TMintageAPI.GetTokenInfoList(Index, Count: Integer): TTokenInfoList;
var
  Db: IVmDb;
  TokenMap: TDictionary<TTokenTypeId, PTokenInfo>;
  ListLen: Integer;
  TokenList: TArray<TRpcTokenInfo>;
  TokenId: TTokenTypeId;
  TokenInfo: PTokenInfo;
  Start, &End: Integer;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  Db := GetVmDb(FChain, TAddress.Asset);
  TokenMap := TAbi.GetTokenMap(Db);
  ListLen := TokenMap.Count;
  SetLength(TokenList, 0);
  for TokenId in TokenMap.Keys do
  begin
    TokenInfo := TokenMap[TokenId];
    TokenList := TokenList + [RawTokenInfoToRpc(TokenInfo, TokenId)];
  end;
  TArray.Sort<TRpcTokenInfo>(TokenList, ByNameSort);
  GetRange(Index, Count, ListLen, Start, &End);
  Result.Count := ListLen;
  Result.List := Copy(TokenList, Start, &End - Start);
end;

function TMintageAPI.GetTokenInfoById(const TokenId: TTokenTypeId): TRpcTokenInfo;
var
  Db: IVmDb;
  TokenInfo: PTokenInfo;
begin
  Db := GetVmDb(FChain, TAddress.Asset);
  TokenInfo := TAbi.GetTokenByID(Db, TokenId);
  if TokenInfo <> nil then
    Result := RawTokenInfoToRpc(TokenInfo, TokenId);
end;

function TMintageAPI.GetTokenInfoListByOwner(const Owner: TAddress): TArray<TRpcTokenInfo>;
var
  Db: IVmDb;
  TokenMap: TDictionary<TTokenTypeId, PTokenInfo>;
  TokenList: TArray<TRpcTokenInfo>;
  TokenId: TTokenTypeId;
  TokenInfo: PTokenInfo;
begin
  Db := GetVmDb(FChain, TAddress.Asset);
  TokenMap := TAbi.GetTokenMapByOwner(Db, Owner);
  SetLength(TokenList, 0);
  for TokenId in TokenMap.Keys do
  begin
    TokenInfo := TokenMap[TokenId];
    TokenList := TokenList + [RawTokenInfoToRpc(TokenInfo, TokenId)];
  end;
  Result := CheckGenesisToken(Db, Owner, FVite.Config.AssetInfo.TokenInfoMap, TokenList);
end;

end.
