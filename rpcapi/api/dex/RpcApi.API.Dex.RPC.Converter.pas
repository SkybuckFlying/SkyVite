unit RpcApi.Api.Dex.Converter;

interface

uses
  BigNumbers,
  Common.Types Interfaces.Core Ledger.Chain Vm.Contracts.Dex,
  RpcApi.API.Dex.Util,
  System.SysUtils System.Classes System.JSON System.Generics.Collections;

type
  TRpcDexTokenInfo = class
  private
    FTokenSymbol: string;
    FDecimals: Integer;
    FTokenId: TTokenTypeId;
    FIndex: Integer;
    FOwner: TAddress;
    FQuoteTokenType: Integer;
  public
    property TokenSymbol: string read FTokenSymbol write FTokenSymbol;
    property Decimals: Integer read FDecimals write FDecimals;
    property TokenId: TTokenTypeId read FTokenId write FTokenId;
    property Index: Integer read FIndex write FIndex;
    property Owner: TAddress read FOwner write FOwner;
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    function ToJSON: TJSONObject;
  end;

  TDividendPoolInfo = class
  private
    FAmount: string;
    FQuoteTokenType: Integer;
    FTokenInfo: TRpcDexTokenInfo;
  public
    property Amount: string read FAmount write FAmount;
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    property TokenInfo: TRpcDexTokenInfo read FTokenInfo write FTokenInfo;
    function ToJSON: TJSONObject;
  end;

  TRpcMarketInfo = class
  private
    FMarketId: Integer;
    FMarketSymbol: string;
    FTradeToken: string;
    FQuoteToken: string;
    FQuoteTokenType: Integer;
    FTradeTokenDecimals: Integer;
    FQuoteTokenDecimals: Integer;
    FTakerBrokerFeeRate: Integer;
    FMakerBrokerFeeRate: Integer;
    FAllowMine: Boolean;
    FValid: Boolean;
    FOwner: string;
    FCreator: string;
    FStopped: Boolean;
    FTimestamp: Int64;
  public
    property MarketId: Integer read FMarketId write FMarketId;
    property MarketSymbol: string read FMarketSymbol write FMarketSymbol;
    property TradeToken: string read FTradeToken write FTradeToken;
    property QuoteToken: string read FQuoteToken write FQuoteToken;
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    property TradeTokenDecimals: Integer read FTradeTokenDecimals write FTradeTokenDecimals;
    property QuoteTokenDecimals: Integer read FQuoteTokenDecimals write FQuoteTokenDecimals;
    property TakerBrokerFeeRate: Integer read FTakerBrokerFeeRate write FTakerBrokerFeeRate;
    property MakerBrokerFeeRate: Integer read FMakerBrokerFeeRate write FMakerBrokerFeeRate;
    property AllowMine: Boolean read FAllowMine write FAllowMine;
    property Valid: Boolean read FValid write FValid;
    property Owner: string read FOwner write FOwner;
    property Creator: string read FCreator write FCreator;
    property Stopped: Boolean read FStopped write FStopped;
    property Timestamp: Int64 read FTimestamp write FTimestamp;
    function ToJSON: TJSONObject;
  end;

  TNewRpcMarketInfo = class
  private
    FMarketId: Integer;
    FMarketSymbol: string;
    FTradeToken: string;
    FQuoteToken: string;
    FQuoteTokenType: Integer;
    FTradeTokenDecimals: Integer;
    FQuoteTokenDecimals: Integer;
    FTakerOperatorFeeRate: Integer;
    FMakerOperatorFeeRate: Integer;
    FAllowMining: Boolean;
    FValid: Boolean;
    FOwner: string;
    FCreator: string;
    FStopped: Boolean;
    FTimestamp: Int64;
    FStableMarket: Boolean;
  public
    property MarketId: Integer read FMarketId write FMarketId;
    property MarketSymbol: string read FMarketSymbol write FMarketSymbol;
    property TradeToken: string read FTradeToken write FTradeToken;
    property QuoteToken: string read FQuoteToken write FQuoteToken;
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    property TradeTokenDecimals: Integer read FTradeTokenDecimals write FTradeTokenDecimals;
    property QuoteTokenDecimals: Integer read FQuoteTokenDecimals write FQuoteTokenDecimals;
    property TakerOperatorFeeRate: Integer read FTakerOperatorFeeRate write FTakerOperatorFeeRate;
    property MakerOperatorFeeRate: Integer read FMakerOperatorFeeRate write FMakerOperatorFeeRate;
    property AllowMining: Boolean read FAllowMining write FAllowMining;
    property Valid: Boolean read FValid write FValid;
    property Owner: string read FOwner write FOwner;
    property Creator: string read FCreator write FCreator;
    property Stopped: Boolean read FStopped write FStopped;
    property Timestamp: Int64 read FTimestamp write FTimestamp;
    property StableMarket: Boolean read FStableMarket write FStableMarket;
    function ToJSON: TJSONObject;
  end;

  TRpcFeesForDividend = class
  private
    FToken: string;
    FDividendPoolAmount: string;
    FNotRoll: Boolean;
  public
    property Token: string read FToken write FToken;
    property DividendPoolAmount: string read FDividendPoolAmount write FDividendPoolAmount;
    property NotRoll: Boolean read FNotRoll write FNotRoll;
    function ToJSON: TJSONObject;
  end;

  TRpcFeesForMine = class
  private
    FQuoteTokenType: Integer;
    FBaseAmount: string;
    FInviteBonusAmount: string;
  public
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    property BaseAmount: string read FBaseAmount write FBaseAmount;
    property InviteBonusAmount: string read FInviteBonusAmount write FInviteBonusAmount;
    function ToJSON: TJSONObject;
  end;

  TRpcDexFeesByPeriod = class
  private
    FFeesForDividend: TArray<TRpcFeesForDividend>;
    FFeesForMine: TArray<TRpcFeesForMine>;
    FLastValidPeriod: UInt64;
    FFinishDividend: Boolean;
    FFinishMine: Boolean;
  public
    property FeesForDividend: TArray<TRpcFeesForDividend> read FFeesForDividend write FFeesForDividend;
    property FeesForMine: TArray<TRpcFeesForMine> read FFeesForMine write FFeesForMine;
    property LastValidPeriod: UInt64 read FLastValidPeriod write FLastValidPeriod;
    property FinishDividend: Boolean read FFinishDividend write FFinishDividend;
    property FinishMine: Boolean read FFinishMine write FFinishMine;
    function ToJSON: TJSONObject;
  end;

  TRpcOperatorMarketFee = class
  private
    FMarketId: Integer;
    FTakerOperatorFeeRate: Integer;
    FMakerOperatorFeeRate: Integer;
    FAmount: string;
  public
    property MarketId: Integer read FMarketId write FMarketId;
    property TakerOperatorFeeRate: Integer read FTakerOperatorFeeRate write FTakerOperatorFeeRate;
    property MakerOperatorFeeRate: Integer read FMakerOperatorFeeRate write FMakerOperatorFeeRate;
    property Amount: string read FAmount write FAmount;
    function ToJSON: TJSONObject;
  end;

  TRpcOperatorFeeAccount = class
  private
    FToken: string;
    FMarketFees: TArray<TRpcOperatorMarketFee>;
  public
    property Token: string read FToken write FToken;
    property MarketFees: TArray<TRpcOperatorMarketFee> read FMarketFees write FMarketFees;
    function ToJSON: TJSONObject;
  end;

  TRpcOperatorFeesByPeriod = class
  private
    FOperatorFees: TArray<TRpcOperatorFeeAccount>;
  public
    property OperatorFees: TArray<TRpcOperatorFeeAccount> read FOperatorFees write FOperatorFees;
    function ToJSON: TJSONObject;
  end;

  TRpcFeeAccount = class
  private
    FQuoteTokenType: Integer;
    FBaseAmount: string;
    FInviteBonusAmount: string;
  public
    property QuoteTokenType: Integer read FQuoteTokenType write FQuoteTokenType;
    property BaseAmount: string read FBaseAmount write FBaseAmount;
    property InviteBonusAmount: string read FInviteBonusAmount write FInviteBonusAmount;
    function ToJSON: TJSONObject;
  end;

  TRpcFeesByPeriod = class
  private
    FUserFees: TArray<TRpcFeeAccount>;
    FPeriod: UInt64;
  public
    property UserFees: TArray<TRpcFeeAccount> read FUserFees write FUserFees;
    property Period: UInt64 read FPeriod write FPeriod;
    function ToJSON: TJSONObject;
  end;

  TRpcUserFees = class
  private
    FFees: TArray<TRpcFeesByPeriod>;
  public
    property Fees: TArray<TRpcFeesByPeriod> read FFees write FFees;
    function ToJSON: TJSONObject;
  end;

  TRpcVxFundByPeriod = class
  private
    FAmount: string;
    FPeriod: UInt64;
  public
    property Amount: string read FAmount write FAmount;
    property Period: UInt64 read FPeriod write FPeriod;
    function ToJSON: TJSONObject;
  end;

  TRpcVxFunds = class
  private
    FFunds: TArray<TRpcVxFundByPeriod>;
  public
    property Funds: TArray<TRpcVxFundByPeriod> read FFunds write FFunds;
    function ToJSON: TJSONObject;
  end;

  TRpcThresholdForTradeAndMine = class
  private
    FTradeThreshold: string;
    FMineThreshold: string;
  public
    property TradeThreshold: string read FTradeThreshold write FTradeThreshold;
    property MineThreshold: string read FMineThreshold write FMineThreshold;
    function ToJSON: TJSONObject;
  end;

  TRpcMiningStakingByPeriod = class
  private
    FPeriod: UInt64;
    FAmount: string;
  public
    property Period: UInt64 read FPeriod write FPeriod;
    property Amount: string read FAmount write FAmount;
    function ToJSON: TJSONObject;
  end;

  TRpcMiningStakings = class
  private
    FPledges: TArray<TRpcMiningStakingByPeriod>;
  public
    property Pledges: TArray<TRpcMiningStakingByPeriod> read FPledges write FPledges;
    function ToJSON: TJSONObject;
  end;

  TSimpleAccountInfo = class
  private
    FToken: string;
    FAvailable: string;
    FLocked: string;
  public
    property Token: string read FToken write FToken;
    property Available: string read FAvailable write FAvailable;
    property Locked: string read FLocked write FLocked;
    function ToJSON: TJSONObject;
  end;

  TSimpleFund = class
  private
    FAddress: string;
    FAccounts: TArray<TSimpleAccountInfo>;
  public
    property Address: string read FAddress write FAddress;
    property Accounts: TArray<TSimpleAccountInfo> read FAccounts write FAccounts;
    function ToJSON: TJSONObject;
  end;

  TFunds = class
  private
    FFunds: TArray<TSimpleFund>;
  public
    property Funds: TArray<TSimpleFund> read FFunds write FFunds;
    function ToJSON: TJSONObject;
  end;

  TRpcVxMineInfo = class
  private
    FHistoryMinedSum: string;
    FTotal: string;
    FFeeMineTotal: string;
    FFeeMineDetail: TDictionary<Integer, string>;
    FPledgeMine: string;
    FMakerMine: string;
  public
    property HistoryMinedSum: string read FHistoryMinedSum write FHistoryMinedSum;
    property Total: string read FTotal write FTotal;
    property FeeMineTotal: string read FFeeMineTotal write FFeeMineTotal;
    property FeeMineDetail: TDictionary<Integer, string> read FFeeMineDetail write FFeeMineDetail;
    property PledgeMine: string read FPledgeMine write FPledgeMine;
    property MakerMine: string read FMakerMine write FMakerMine;
    function ToJSON: TJSONObject;
  end;

  TNewRpcVxMineInfo = class
  private
    FHistoryMinedSum: string;
    FTotal: string;
    FFeeMineTotal: string;
    FFeeMineDetail: TDictionary<Integer, string>;
    FStakingMine: string;
    FMakerMine: string;
  public
    property HistoryMinedSum: string read FHistoryMinedSum write FHistoryMinedSum;
    property Total: string read FTotal write FTotal;
    property FeeMineTotal: string read FFeeMineTotal write FFeeMineTotal;
    property FeeMineDetail: TDictionary<Integer, string> read FFeeMineDetail write FFeeMineDetail;
    property StakingMine: string read FStakingMine write FStakingMine;
    property MakerMine: string read FMakerMine write FMakerMine;
    function ToJSON: TJSONObject;
  end;

  TRpcOrder = class
  private
    FId: string;
    FAddress: string;
    FMarketId: Integer;
    FSide: Boolean;
    FType: Integer;
    FPrice: string;
    FTakerFeeRate: Integer;
    FMakerFeeRate: Integer;
    FTakerOperatorFeeRate: Integer;
    FMakerOperatorFeeRate: Integer;
    FQuantity: string;
    FAmount: string;
    FLockedBuyFee: string;
    FStatus: Integer;
    FCancelReason: Integer;
    FExecutedQuantity: string;
    FExecutedAmount: string;
    FExecutedBaseFee: string;
    FExecutedOperatorFee: string;
    FRefundToken: string;
    FRefundQuantity: string;
    FTimestamp: Int64;
    FAgent: string;
    FSendHash: string;
    FMarketOrderAmtThreshold: string;
  public
    property Id: string read FId write FId;
    property Address: string read FAddress write FAddress;
    property MarketId: Integer read FMarketId write FMarketId;
    property Side: Boolean read FSide write FSide;
    property &Type: Integer read FType write FType;
    property Price: string read FPrice write FPrice;
    property TakerFeeRate: Integer read FTakerFeeRate write FTakerFeeRate;
    property MakerFeeRate: Integer read FMakerFeeRate write FMakerFeeRate;
    property TakerOperatorFeeRate: Integer read FTakerOperatorFeeRate write FTakerOperatorFeeRate;
    property MakerOperatorFeeRate: Integer read FMakerOperatorFeeRate write FMakerOperatorFeeRate;
    property Quantity: string read FQuantity write FQuantity;
    property Amount: string read FAmount write FAmount;
    property LockedBuyFee: string read FLockedBuyFee write FLockedBuyFee;
    property Status: Integer read FStatus write FStatus;
    property CancelReason: Integer read FCancelReason write FCancelReason;
    property ExecutedQuantity: string read FExecutedQuantity write FExecutedQuantity;
    property ExecutedAmount: string read FExecutedAmount write FExecutedAmount;
    property ExecutedBaseFee: string read FExecutedBaseFee write FExecutedBaseFee;
    property ExecutedOperatorFee: string read FExecutedOperatorFee write FExecutedOperatorFee;
    property RefundToken: string read FRefundToken write FRefundToken;
    property RefundQuantity: string read FRefundQuantity write FRefundQuantity;
    property Timestamp: Int64 read FTimestamp write FTimestamp;
    property Agent: string read FAgent write FAgent;
    property SendHash: string read FSendHash write FSendHash;
    property MarketOrderAmtThreshold: string read FMarketOrderAmtThreshold write FMarketOrderAmtThreshold;
    function ToJSON: TJSONObject;
  end;

  TOrdersRes = class
  private
    FOrders: TArray<TRpcOrder>;
    FSize: Integer;
    FQueryStart: IHashHeight;
    FQueryEnd: IHashHeight;
  public
    property Orders: TArray<TRpcOrder> read FOrders write FOrders;
    property Size: Integer read FSize write FSize;
    property QueryStart: IHashHeight read FQueryStart write FQueryStart;
    property QueryEnd: IHashHeight read FQueryEnd write FQueryEnd;
    function ToJSON: TJSONObject;
  end;

  TStakeInfo = class
  private
    FAmount: string;
    FBeneficiary: string;
    FExpirationHeight: string;
    FExpirationTime: Int64;
    FIsDelegated: Boolean;
    FDelegateAddress: string;
    FStakeAddress: string;
    FBid: Byte;
    FId: string;
    FPrincipal: string;
  public
    property Amount: string read FAmount write FAmount;
    property Beneficiary: string read FBeneficiary write FBeneficiary;
    property ExpirationHeight: string read FExpirationHeight write FExpirationHeight;
    property ExpirationTime: Int64 read FExpirationTime write FExpirationTime;
    property IsDelegated: Boolean read FIsDelegated write FIsDelegated;
    property DelegateAddress: string read FDelegateAddress write FDelegateAddress;
    property StakeAddress: string read FStakeAddress write FStakeAddress;
    property Bid: Byte read FBid write FBid;
    property Id: string read FId write FId;
    property Principal: string read FPrincipal write FPrincipal;
    function ToJSON: TJSONObject;
  end;

  TStakeInfoList = class
  private
    FStakeAmount: string;
    FCount: Integer;
    FStakeList: TArray<TStakeInfo>;
  public
    property StakeAmount: string read FStakeAmount write FStakeAmount;
    property Count: Integer read FCount write FCount;
    property StakeList: TArray<TStakeInfo> read FStakeList write FStakeList;
    function ToJSON: TJSONObject;
  end;

  TVxUnlock = class
  private
    FAmount: string;
    FExpirationTime: Int64;
    FExpirationPeriod: UInt64;
  public
    property Amount: string read FAmount write FAmount;
    property ExpirationTime: Int64 read FExpirationTime write FExpirationTime;
    property ExpirationPeriod: UInt64 read FExpirationPeriod write FExpirationPeriod;
    function ToJSON: TJSONObject;
  end;

  TVxUnlockList = class
  private
    FUnlockingAmount: string;
    FCount: Integer;
    FUnlocks: TArray<TVxUnlock>;
  public
    property UnlockingAmount: string read FUnlockingAmount write FUnlockingAmount;
    property Count: Integer read FCount write FCount;
    property Unlocks: TArray<TVxUnlock> read FUnlocks write FUnlocks;
    function ToJSON: TJSONObject;
  end;

  TCancelStake = class
  private
    FAmount: string;
    FExpirationTime: Int64;
    FExpirationPeriod: UInt64;
  public
    property Amount: string read FAmount write FAmount;
    property ExpirationTime: Int64 read FExpirationTime write FExpirationTime;
    property ExpirationPeriod: UInt64 read FExpirationPeriod write FExpirationPeriod;
    function ToJSON: TJSONObject;
  end;

  TCancelStakeList = class
  private
    FCancellingAmount: string;
    FCount: Integer;
    FCancels: TArray<TCancelStake>;
  public
    property CancellingAmount: string read FCancellingAmount write FCancellingAmount;
    property Count: Integer read FCount write FCount;
    property Cancels: TArray<TCancelStake> read FCancels write FCancels;
    function ToJSON: TJSONObject;
  end;

  TPlaceOrderInfo = class
  private
    FAvailable: string;
    FMinTradeAmount: string;
    FFeeRate: Integer;
    FSide: Boolean;
    FIsVIP: Boolean;
    FIsSVIP: Boolean;
    FIsInvited: Boolean;
  public
    property Available: string read FAvailable write FAvailable;
    property MinTradeAmount: string read FMinTradeAmount write FMinTradeAmount;
    property FeeRate: Integer read FFeeRate write FFeeRate;
    property Side: Boolean read FSide write FSide;
    property IsVIP: Boolean read FIsVIP write FIsVIP;
    property IsSVIP: Boolean read FIsSVIP write FIsSVIP;
    property IsInvited: Boolean read FIsInvited write FIsInvited;
    function ToJSON: TJSONObject;
  end;

  TDelegateStakeInfo = class
  private
    FStakeType: Integer;
    FAddress: string;
    FPrincipal: string;
    FAmount: string;
    FStatus: Integer;
  public
    property StakeType: Integer read FStakeType write FStakeType;
    property Address: string read FAddress write FAddress;
    property Principal: string read FPrincipal write FPrincipal;
    property Amount: string read FAmount write FAmount;
    property Status: Integer read FStatus write FStatus;
    function ToJSON: TJSONObject;
  end;

  TVIPStakingRpc = class
  private
    FAmount: string;
    FExpirationHeight: string;
    FExpirationTime: Int64;
    FId: string;
  public
    property Amount: string read FAmount write FAmount;
    property ExpirationHeight: string read FExpirationHeight write FExpirationHeight;
    property ExpirationTime: Int64 read FExpirationTime write FExpirationTime;
    property Id: string read FId write FId;
    function ToJSON: TJSONObject;
  end;

function MarketInfoToRpc(MkInfo: TDexMarketInfo): TRpcMarketInfo;
function MarketInfoToNewRpc(MkInfo: TDexMarketInfo): TNewRpcMarketInfo;
function TokenInfoToRpc(TInfo: TDexTokenInfo; Tti: TTokenTypeId): TRpcDexTokenInfo;
function DexFeesByPeriodToRpc(DexFeesByPeriod: TDexFeesByPeriod): TRpcDexFeesByPeriod;
function OperatorFeesByPeriodToRpc(OperatorFees: TOperatorFeesByPeriod): TRpcOperatorFeesByPeriod;
function UserFeesToRpc(UserFees: TUserFees): TRpcUserFees;
function VxFundsToRpc(Funds: TVxFunds): TRpcVxFunds;
function MiningStakingsToRpc(MiningStakings: TMiningStakings): TRpcMiningStakings;
function OrderToRpc(Order: TDexOrder): TRpcOrder;
function OrdersToRpc(Orders: TArray<TDexOrder>): TArray<TRpcOrder>;
function UnlockListToRpc(Unlocks: TVxUnlocks; PageIndex, PageSize: Integer; Chain: IChain): TVxUnlockList;
function CancelStakeListToRpc(CancelStakes: TCancelStakes; PageIndex, PageSize: Integer; Chain: IChain): TCancelStakeList;
function DelegateStakeInfoToRpc(Info: TDelegateStakeInfo): TDelegateStakeInfo;

implementation

uses
  System.StrUtils, System.NetEncoding,
  Common.HexUtil, RpcApi.Api.Dex.Util;

function MarketInfoToRpc(MkInfo: TDexMarketInfo): TRpcMarketInfo;
var
  TradeToken, QuoteToken: TTokenTypeId;
  Owner, Creator: TAddress;
begin
  Result := nil;
  if MkInfo <> nil then
  begin
    Result := TRpcMarketInfo.Create;
    TradeToken := TTokenTypeId.FromBytes(MkInfo.TradeToken);
    QuoteToken := TTokenTypeId.FromBytes(MkInfo.QuoteToken);
    Owner := TAddress.FromBytes(MkInfo.Owner);
    Creator := TAddress.FromBytes(MkInfo.Creator);
    Result.MarketId := MkInfo.MarketId;
    Result.MarketSymbol := MkInfo.MarketSymbol;
    Result.TradeToken := TradeToken.ToString;
    Result.QuoteToken := QuoteToken.ToString;
    Result.QuoteTokenType := MkInfo.QuoteTokenType;
    Result.TradeTokenDecimals := MkInfo.TradeTokenDecimals;
    Result.QuoteTokenDecimals := MkInfo.QuoteTokenDecimals;
    Result.TakerBrokerFeeRate := MkInfo.TakerOperatorFeeRate;
    Result.MakerBrokerFeeRate := MkInfo.MakerOperatorFeeRate;
    Result.AllowMine := MkInfo.AllowMining;
    Result.Valid := MkInfo.Valid;
    Result.Owner := Owner.ToString;
    Result.Creator := Creator.ToString;
    Result.Stopped := MkInfo.Stopped;
    Result.Timestamp := MkInfo.Timestamp;
  end;
end;

function MarketInfoToNewRpc(MkInfo: TDexMarketInfo): TNewRpcMarketInfo;
var
  TradeToken, QuoteToken: TTokenTypeId;
  Owner, Creator: TAddress;
begin
  Result := nil;
  if MkInfo <> nil then
  begin
    Result := TNewRpcMarketInfo.Create;
    TradeToken := TTokenTypeId.FromBytes(MkInfo.TradeToken);
    QuoteToken := TTokenTypeId.FromBytes(MkInfo.QuoteToken);
    Owner := TAddress.FromBytes(MkInfo.Owner);
    Creator := TAddress.FromBytes(MkInfo.Creator);
    Result.MarketId := MkInfo.MarketId;
    Result.MarketSymbol := MkInfo.MarketSymbol;
    Result.TradeToken := TradeToken.ToString;
    Result.QuoteToken := QuoteToken.ToString;
    Result.QuoteTokenType := MkInfo.QuoteTokenType;
    Result.TradeTokenDecimals := MkInfo.TradeTokenDecimals;
    Result.QuoteTokenDecimals := MkInfo.QuoteTokenDecimals;
    Result.TakerOperatorFeeRate := MkInfo.TakerOperatorFeeRate;
    Result.MakerOperatorFeeRate := MkInfo.MakerOperatorFeeRate;
    Result.AllowMining := MkInfo.AllowMining;
    Result.Valid := MkInfo.Valid;
    Result.Owner := Owner.ToString;
    Result.Creator := Creator.ToString;
    Result.Stopped := MkInfo.Stopped;
    Result.Timestamp := MkInfo.Timestamp;
    Result.StableMarket := MkInfo.StableMarket;
    if MkInfo.GetStableMarket then
    begin
      Result.TakerOperatorFeeRate := 0;
      Result.MakerOperatorFeeRate := 0;
    end;
  end;
end;

function TokenInfoToRpc(TInfo: TDexTokenInfo; Tti: TTokenTypeId): TRpcDexTokenInfo;
var
  Owner: TAddress;
begin
  Result := nil;
  if TInfo <> nil then
  begin
    Result := TRpcDexTokenInfo.Create;
    Owner := TAddress.FromBytes(TInfo.Owner);
    Result.TokenSymbol := TInfo.Symbol;
    Result.Decimals := TInfo.Decimals;
    Result.TokenId := Tti;
    Result.Index := TInfo.Index;
    Result.Owner := Owner;
    Result.QuoteTokenType := TInfo.QuoteTokenType;
  end;
end;

function DexFeesByPeriodToRpc(DexFeesByPeriod: TDexFeesByPeriod): TRpcDexFeesByPeriod;
var
  Dividend: TDexFeesForDividend;
  RpcDividend: TRpcFeesForDividend;
  Mine: TDexFeesForMine;
  RpcMine: TRpcFeesForMine;
  I: Integer;
begin
  Result := nil;
  if DexFeesByPeriod <> nil then
  begin
    Result := TRpcDexFeesByPeriod.Create;
    SetLength(Result.FeesForDividend, Length(DexFeesByPeriod.FeesForDividend));
    for I := 0 to High(DexFeesByPeriod.FeesForDividend) do
    begin
      Dividend := DexFeesByPeriod.FeesForDividend[I];
      RpcDividend := TRpcFeesForDividend.Create;
      RpcDividend.Token := TokenBytesToString(Dividend.Token);
      RpcDividend.DividendPoolAmount := AmountBytesToString(Dividend.DividendPoolAmount);
      RpcDividend.NotRoll := Dividend.NotRoll;
      Result.FeesForDividend[I] := RpcDividend;
    end;
    SetLength(Result.FeesForMine, Length(DexFeesByPeriod.FeesForMine));
    for I := 0 to High(DexFeesByPeriod.FeesForMine) do
    begin
      Mine := DexFeesByPeriod.FeesForMine[I];
      RpcMine := TRpcFeesForMine.Create;
      RpcMine.QuoteTokenType := Mine.QuoteTokenType;
      RpcMine.BaseAmount := AmountBytesToString(Mine.BaseAmount);
      RpcMine.InviteBonusAmount := AmountBytesToString(Mine.InviteBonusAmount);
      Result.FeesForMine[I] := RpcMine;
    end;
    Result.LastValidPeriod := DexFeesByPeriod.LastValidPeriod;
    Result.FinishDividend := DexFeesByPeriod.FinishDividend;
    Result.FinishMine := DexFeesByPeriod.FinishMine;
  end;
end;

function OperatorFeesByPeriodToRpc(OperatorFees: TOperatorFeesByPeriod): TRpcOperatorFeesByPeriod;
var
  Fee: TOperatorFeeAccount;
  RpcFee: TRpcOperatorFeeAccount;
  Acc: TOperatorMarketFee;
  RpcAcc: TRpcOperatorMarketFee;
  I, J: Integer;
begin
  Result := nil;
  if OperatorFees <> nil then
  begin
    Result := TRpcOperatorFeesByPeriod.Create;
    SetLength(Result.OperatorFees, Length(OperatorFees.OperatorFees));
    for I := 0 to High(OperatorFees.OperatorFees) do
    begin
      Fee := OperatorFees.OperatorFees[I];
      RpcFee := TRpcOperatorFeeAccount.Create;
      RpcFee.Token := TokenBytesToString(Fee.Token);
      SetLength(RpcFee.MarketFees, Length(Fee.MarketFees));
      for J := 0 to High(Fee.MarketFees) do
      begin
        Acc := Fee.MarketFees[J];
        RpcAcc := TRpcOperatorMarketFee.Create;
        RpcAcc.MarketId := Acc.MarketId;
        RpcAcc.TakerOperatorFeeRate := Acc.TakerOperatorFeeRate;
        RpcAcc.MakerOperatorFeeRate := Acc.MakerOperatorFeeRate;
        RpcAcc.Amount := AmountBytesToString(Acc.Amount);
        RpcFee.MarketFees[J] := RpcAcc;
      end;
      Result.OperatorFees[I] := RpcFee;
    end;
  end;
end;

function UserFeesToRpc(UserFees: TUserFees): TRpcUserFees;
var
  Fee: TUserFeesByPeriod;
  RpcFee: TRpcFeesByPeriod;
  Acc: TUserFeeAccount;
  RpcAcc: TRpcFeeAccount;
  I, J: Integer;
begin
  Result := nil;
  if UserFees <> nil then
  begin
    Result := TRpcUserFees.Create;
    SetLength(Result.Fees, Length(UserFees.Fees));
    for I := 0 to High(UserFees.Fees) do
    begin
      Fee := UserFees.Fees[I];
      RpcFee := TRpcFeesByPeriod.Create;
      SetLength(RpcFee.UserFees, Length(Fee.Fees));
      for J := 0 to High(Fee.Fees) do
      begin
        Acc := Fee.Fees[J];
        RpcAcc := TRpcFeeAccount.Create;
        RpcAcc.QuoteTokenType := Acc.QuoteTokenType;
        RpcAcc.BaseAmount := AmountBytesToString(Acc.BaseAmount);
        RpcAcc.InviteBonusAmount := AmountBytesToString(Acc.InviteBonusAmount);
        RpcFee.UserFees[J] := RpcAcc;
      end;
      RpcFee.Period := Fee.Period;
      Result.Fees[I] := RpcFee;
    end;
  end;
end;

function VxFundsToRpc(Funds: TVxFunds): TRpcVxFunds;
var
  Fund: TVxFundByPeriod;
  RpcFund: TRpcVxFundByPeriod;
  I: Integer;
begin
  Result := nil;
  if Funds <> nil then
  begin
    Result := TRpcVxFunds.Create;
    SetLength(Result.Funds, Length(Funds.Funds));
    for I := 0 to High(Funds.Funds) do
    begin
      Fund := Funds.Funds[I];
      RpcFund := TRpcVxFundByPeriod.Create;
      RpcFund.Period := Fund.Period;
      RpcFund.Amount := AmountBytesToString(Fund.Amount);
      Result.Funds[I] := RpcFund;
    end;
  end;
end;

function MiningStakingsToRpc(MiningStakings: TMiningStakings): TRpcMiningStakings;
var
  Staking: TMiningStakingByPeriod;
  RpcStaking: TRpcMiningStakingByPeriod;
  I: Integer;
begin
  Result := TRpcMiningStakings.Create;
  SetLength(Result.Pledges, Length(MiningStakings.Stakings));
  for I := 0 to High(MiningStakings.Stakings) do
  begin
    Staking := MiningStakings.Stakings[I];
    RpcStaking := TRpcMiningStakingByPeriod.Create;
    RpcStaking.Period := Staking.Period;
    RpcStaking.Amount := AmountBytesToString(Staking.Amount);
    Result.Pledges[I] := RpcStaking;
  end;
end;

function OrderToRpc(Order: TDexOrder): TRpcOrder;
var
  Address, Agent: TAddress;
  Tk: TTokenTypeId;
  SendHash: THash;
begin
  Result := nil;
  if Order <> nil then
  begin
    Result := TRpcOrder.Create;
    Address := TAddress.FromBytes(Order.Address);
    Result.Id := THex.EncodeToString(Order.Id);
    Result.Address := Address.ToString;
    Result.MarketId := Order.MarketId;
    Result.Side := Order.Side;
    Result.&Type := Order.&Type;
    Result.Price := TDex.BytesToPrice(Order.Price);
    Result.TakerFeeRate := Order.TakerFeeRate;
    Result.MakerFeeRate := Order.MakerFeeRate;
    Result.TakerOperatorFeeRate := Order.TakerOperatorFeeRate;
    Result.MakerOperatorFeeRate := Order.MakerOperatorFeeRate;
    Result.Quantity := AmountBytesToString(Order.Quantity);
    Result.Amount := AmountBytesToString(Order.Amount);
    if Length(Order.LockedBuyFee) > 0 then
      Result.LockedBuyFee := AmountBytesToString(Order.LockedBuyFee);
    Result.Status := Order.Status;
    Result.CancelReason := Order.CancelReason;
    if Length(Order.ExecutedQuantity) > 0 then
      Result.ExecutedQuantity := AmountBytesToString(Order.ExecutedQuantity);
    if Length(Order.ExecutedAmount) > 0 then
      Result.ExecutedAmount := AmountBytesToString(Order.ExecutedAmount);
    if Length(Order.ExecutedBaseFee) > 0 then
      Result.ExecutedBaseFee := AmountBytesToString(Order.ExecutedBaseFee);
    if Length(Order.ExecutedOperatorFee) > 0 then
      Result.ExecutedOperatorFee := AmountBytesToString(Order.ExecutedOperatorFee);
    if Length(Order.RefundToken) > 0 then
    begin
      Tk := TTokenTypeId.FromBytes(Order.RefundToken);
      Result.RefundToken := Tk.ToString;
    end;
    if Length(Order.RefundQuantity) > 0 then
      Result.RefundQuantity := AmountBytesToString(Order.RefundQuantity);
    if Length(Order.Agent) > 0 then
    begin
      Agent := TAddress.FromBytes(Order.Agent);
      Result.Agent := Agent.ToString;
    end;
    if Length(Order.SendHash) > 0 then
    begin
      SendHash := THash.FromBytes(Order.SendHash);
      Result.SendHash := SendHash.ToString;
    end;
    if Length(Order.MarketOrderAmtThreshold) > 0 then
      Result.MarketOrderAmtThreshold := AmountBytesToString(Order.MarketOrderAmtThreshold);
    Result.Timestamp := Order.Timestamp;
  end;
end;

function OrdersToRpc(Orders: TArray<TDexOrder>): TArray<TRpcOrder>;
var
  I: Integer;
begin
  if Length(Orders) = 0 then
    Result := nil
  else
  begin
    SetLength(Result, Length(Orders));
    for I := 0 to High(Orders) do
      Result[I] := OrderToRpc(Orders[I]);
  end;
end;

function UnlockListToRpc(Unlocks: TVxUnlocks; PageIndex, PageSize: Integer; Chain: IChain): TVxUnlockList;
var
  GenesisTime: Int64;
  Total: TBigInteger;
  I: Integer;
  Ul: TVxUnlockByPeriod;
  Amt: TBigInteger;
  Unlock: TVxUnlock;
begin
  Result := TVxUnlockList.Create;
  GenesisTime := Chain.GetGenesisSnapshotBlock.Timestamp;
  Total := TBigInteger.Create(0);
  SetLength(Result.Unlocks, 0);
  for I := 0 to High(Unlocks.Unlocks) do
  begin
    Ul := Unlocks.Unlocks[I];
    Amt := TBigInteger.Create(Ul.Amount);
    if (I >= PageIndex * PageSize) and (I < (PageIndex + 1) * PageSize) then
    begin
      Unlock := TVxUnlock.Create;
      Unlock.Amount := Amt.ToString;
      Unlock.ExpirationTime := GenesisTime + (Ul.PeriodId + 1 + TDex.SchedulePeriods) * 3600 * 24;
      Unlock.ExpirationPeriod := Ul.PeriodId + 1 + TDex.SchedulePeriods;
      SetLength(Result.Unlocks, Length(Result.Unlocks) + 1);
      Result.Unlocks[High(Result.Unlocks)] := Unlock;
    end;
    Total := Total + Amt;
  end;
  Result.UnlockingAmount := Total.ToString;
  Result.Count := Length(Unlocks.Unlocks);
end;

function CancelStakeListToRpc(CancelStakes: TCancelStakes; PageIndex, PageSize: Integer; Chain: IChain): TCancelStakeList;
var
  GenesisTime: Int64;
  Total: TBigInteger;
  I: Integer;
  Ul: TCancelStakeByPeriod;
  Amt: TBigInteger;
  Cancel: TCancelStake;
begin
  Result := TCancelStakeList.Create;
  GenesisTime := Chain.GetGenesisSnapshotBlock.Timestamp;
  Total := TBigInteger.Create(0);
  SetLength(Result.Cancels, 0);
  for I := 0 to High(CancelStakes.Cancels) do
  begin
    Ul := CancelStakes.Cancels[I];
    Amt := TBigInteger.Create(Ul.Amount);
    if (I >= PageIndex * PageSize) and (I < (PageIndex + 1) * PageSize) then
    begin
      Cancel := TCancelStake.Create;
      Cancel.Amount := Amt.ToString;
      Cancel.ExpirationTime := GenesisTime + (Ul.PeriodId + 1 + TDex.SchedulePeriods) * 3600 * 24 + 1200;
      Cancel.ExpirationPeriod := Ul.PeriodId + 1 + TDex.SchedulePeriods;
      SetLength(Result.Cancels, Length(Result.Cancels) + 1);
      Result.Cancels[High(Result.Cancels)] := Cancel;
    end;
    Total := Total + Amt;
  end;
  Result.CancellingAmount := Total.ToString;
  Result.Count := Length(CancelStakes.Cancels);
end;

function DelegateStakeInfoToRpc(Info: TDelegateStakeInfo): TDelegateStakeInfo;
var
  Addr, PrAddr: TAddress;
begin
  Result := TDelegateStakeInfo.Create;
  Result.StakeType := Info.StakeType;
  Addr := TAddress.FromBytes(Info.Address);
  Result.Address := Addr.ToString;
  if Length(Info.Principal) > 0 then
  begin
    PrAddr := TAddress.FromBytes(Info.Principal);
    Result.Principal := PrAddr.ToString;
  end;
  Result.Amount := AmountBytesToString(Info.Amount);
  Result.Status := Info.Status;
end;

{ TCancelStake.ToJSON }

function TCancelStake.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('amount', FAmount);
  Result.AddPair('expirationTime', TJSONNumber.Create(FExpirationTime));
  Result.AddPair('expirationPeriod', TJSONNumber.Create(FExpirationPeriod));
end;

{ TCancelStakeList.ToJSON }

function TCancelStakeList.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TCancelStake;
begin
  Result := TJSONObject.Create;
  Result.AddPair('cancellingAmount', FCancellingAmount);
  Result.AddPair('count', TJSONNumber.Create(FCount));
  JsonArray := TJSONArray.Create;
  for Item in FCancels do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('cancels', JsonArray);
end;

{ TDelegateStakeInfo.ToJSON }

function TDelegateStakeInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('stakeType', TJSONNumber.Create(FStakeType));
  Result.AddPair('address', FAddress);
  Result.AddPair('principal', FPrincipal);
  Result.AddPair('amount', FAmount);
  Result.AddPair('status', TJSONNumber.Create(FStatus));
end;

{ TDividendPoolInfo.ToJSON }

function TDividendPoolInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('amount', FAmount);
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
  if FTokenInfo <> nil then
    Result.AddPair('tokenInfo', FTokenInfo.ToJSON);
end;

{ TFunds.ToJSON }

function TFunds.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TSimpleFund;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FFunds do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('funds', JsonArray);
end;

{ TNewRpcMarketInfo.ToJSON }

function TNewRpcMarketInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('marketId', TJSONNumber.Create(FMarketId));
  Result.AddPair('marketSymbol', FMarketSymbol);
  Result.AddPair('tradeToken', FTradeToken);
  Result.AddPair('quoteToken', FQuoteToken);
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
  Result.AddPair('tradeTokenDecimals', TJSONNumber.Create(FTradeTokenDecimals));
  Result.AddPair('quoteTokenDecimals', TJSONNumber.Create(FQuoteTokenDecimals));
  Result.AddPair('takerOperatorFeeRate', TJSONNumber.Create(FTakerOperatorFeeRate));
  Result.AddPair('makerOperatorFeeRate', TJSONNumber.Create(FMakerOperatorFeeRate));
  Result.AddPair('allowMining', TJSONBool.Create(FAllowMining));
  Result.AddPair('valid', TJSONBool.Create(FValid));
  Result.AddPair('owner', FOwner);
  Result.AddPair('creator', FCreator);
  Result.AddPair('stopped', TJSONBool.Create(FStopped));
  Result.AddPair('timestamp', TJSONNumber.Create(FTimestamp));
  Result.AddPair('stableMarket', TJSONBool.Create(FStableMarket));
end;

{ TNewRpcVxMineInfo.ToJSON }

function TNewRpcVxMineInfo.ToJSON: TJSONObject;
var
  DetailJson: TJSONObject;
  Pair: TPair<Integer, string>;
begin
  Result := TJSONObject.Create;
  Result.AddPair('historyMinedSum', FHistoryMinedSum);
  Result.AddPair('total', FTotal);
  Result.AddPair('feeMineTotal', FFeeMineTotal);
  DetailJson := TJSONObject.Create;
  for Pair in FFeeMineDetail do
    DetailJson.AddPair(IntToStr(Pair.Key), Pair.Value);
  Result.AddPair('feeMineDetail', DetailJson);
  Result.AddPair('stakingMine', FStakingMine);
  Result.AddPair('makerMine', FMakerMine);
end;

{ TOrdersRes.ToJSON }

function TOrdersRes.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcOrder;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FOrders do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('orders', JsonArray);
  Result.AddPair('size', TJSONNumber.Create(FSize));
  if FQueryStart <> nil then
    Result.AddPair('queryStart', FQueryStart.ToJSON);
  if FQueryEnd <> nil then
    Result.AddPair('queryEnd', FQueryEnd.ToJSON);
end;

{ TPlaceOrderInfo.ToJSON }

function TPlaceOrderInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('available', FAvailable);
  Result.AddPair('minTradeAmount', FMinTradeAmount);
  Result.AddPair('feeRate', TJSONNumber.Create(FFeeRate));
  Result.AddPair('side', TJSONBool.Create(FSide));
  Result.AddPair('isVIP', TJSONBool.Create(FIsVIP));
  Result.AddPair('isSVIP', TJSONBool.Create(FIsSVIP));
  Result.AddPair('isInvited', TJSONBool.Create(FIsInvited));
end;

{ TRpcDexFeesByPeriod.ToJSON }

function TRpcDexFeesByPeriod.ToJSON: TJSONObject;
var
  DividendArray, MineArray: TJSONArray;
  Item: TObject;
begin
  Result := TJSONObject.Create;
  DividendArray := TJSONArray.Create;
  for Item in FFeesForDividend do
    DividendArray.Add((Item as TRpcFeesForDividend).ToJSON);
  Result.AddPair('feesForDividend', DividendArray);
  MineArray := TJSONArray.Create;
  for Item in FFeesForMine do
    MineArray.Add((Item as TRpcFeesForMine).ToJSON);
  Result.AddPair('feesForMine', MineArray);
  Result.AddPair('lastValidPeriod', TJSONNumber.Create(FLastValidPeriod));
  Result.AddPair('finishDividend', TJSONBool.Create(FFinishDividend));
  Result.AddPair('finishMine', TJSONBool.Create(FFinishMine));
end;

{ TRpcDexTokenInfo.ToJSON }

function TRpcDexTokenInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('tokenSymbol', FTokenSymbol);
  Result.AddPair('decimals', TJSONNumber.Create(FDecimals));
  Result.AddPair('tokenId', FTokenId.ToString);
  Result.AddPair('index', TJSONNumber.Create(FIndex));
  Result.AddPair('owner', FOwner.ToString);
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
end;

{ TRpcFeeAccount.ToJSON }

function TRpcFeeAccount.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
  Result.AddPair('baseAmount', FBaseAmount);
  Result.AddPair('inviteBonusAmount', FInviteBonusAmount);
end;

{ TRpcFeesByPeriod.ToJSON }

function TRpcFeesByPeriod.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcFeeAccount;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FUserFees do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('userFees', JsonArray);
  Result.AddPair('period', TJSONNumber.Create(FPeriod));
end;

{ TRpcFeesForDividend.ToJSON }

function TRpcFeesForDividend.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('token', FToken);
  Result.AddPair('dividendPoolAmount', FDividendPoolAmount);
  Result.AddPair('notRoll', TJSONBool.Create(FNotRoll));
end;

{ TRpcFeesForMine.ToJSON }

function TRpcFeesForMine.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
  Result.AddPair('baseAmount', FBaseAmount);
  Result.AddPair('inviteBonusAmount', FInviteBonusAmount);
end;

{ TRpcMarketInfo.ToJSON }

function TRpcMarketInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('marketId', TJSONNumber.Create(FMarketId));
  Result.AddPair('marketSymbol', FMarketSymbol);
  Result.AddPair('tradeToken', FTradeToken);
  Result.AddPair('quoteToken', FQuoteToken);
  Result.AddPair('quoteTokenType', TJSONNumber.Create(FQuoteTokenType));
  Result.AddPair('tradeTokenDecimals', TJSONNumber.Create(FTradeTokenDecimals));
  Result.AddPair('quoteTokenDecimals', TJSONNumber.Create(FQuoteTokenDecimals));
  Result.AddPair('takerBrokerFeeRate', TJSONNumber.Create(FTakerBrokerFeeRate));
  Result.AddPair('makerBrokerFeeRate', TJSONNumber.Create(FMakerBrokerFeeRate));
  Result.AddPair('allowMine', TJSONBool.Create(FAllowMine));
  Result.AddPair('valid', TJSONBool.Create(FValid));
  Result.AddPair('owner', FOwner);
  Result.AddPair('creator', FCreator);
  Result.AddPair('stopped', TJSONBool.Create(FStopped));
  Result.AddPair('timestamp', TJSONNumber.Create(FTimestamp));
end;

{ TRpcMiningStakingByPeriod.ToJSON }

function TRpcMiningStakingByPeriod.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('period', TJSONNumber.Create(FPeriod));
  Result.AddPair('amount', FAmount);
end;

{ TRpcMiningStakings.ToJSON }

function TRpcMiningStakings.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcMiningStakingByPeriod;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FPledges do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('Pledges', JsonArray);
end;

{ TRpcOperatorFeeAccount.ToJSON }

function TRpcOperatorFeeAccount.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcOperatorMarketFee;
begin
  Result := TJSONObject.Create;
  Result.AddPair('token', FToken);
  JsonArray := TJSONArray.Create;
  for Item in FMarketFees do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('marketFees', JsonArray);
end;

{ TRpcOperatorFeesByPeriod.ToJSON }

function TRpcOperatorFeesByPeriod.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcOperatorFeeAccount;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FOperatorFees do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('operatorFees', JsonArray);
end;

{ TRpcOperatorMarketFee.ToJSON }

function TRpcOperatorMarketFee.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('marketId', TJSONNumber.Create(FMarketId));
  Result.AddPair('takerOperatorFeeRate', TJSONNumber.Create(FTakerOperatorFeeRate));
  Result.AddPair('makerOperatorFeeRate', TJSONNumber.Create(FMakerOperatorFeeRate));
  Result.AddPair('amount', FAmount);
end;

{ TRpcOrder.ToJSON }

function TRpcOrder.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Id', FId);
  Result.AddPair('Address', FAddress);
  Result.AddPair('MarketId', TJSONNumber.Create(FMarketId));
  Result.AddPair('Side', TJSONBool.Create(FSide));
  Result.AddPair('Type', TJSONNumber.Create(FType));
  Result.AddPair('Price', FPrice);
  Result.AddPair('TakerFeeRate', TJSONNumber.Create(FTakerFeeRate));
  Result.AddPair('MakerFeeRate', TJSONNumber.Create(FMakerFeeRate));
  Result.AddPair('TakerOperatorFeeRate', TJSONNumber.Create(FTakerOperatorFeeRate));
  Result.AddPair('MakerOperatorFeeRate', TJSONNumber.Create(FMakerOperatorFeeRate));
  Result.AddPair('Quantity', FQuantity);
  Result.AddPair('Amount', FAmount);
  if not FLockedBuyFee.IsEmpty then
    Result.AddPair('LockedBuyFee', FLockedBuyFee);
  Result.AddPair('Status', TJSONNumber.Create(FStatus));
  if FCancelReason <> 0 then
    Result.AddPair('CancelReason', TJSONNumber.Create(FCancelReason));
  if not FExecutedQuantity.IsEmpty then
    Result.AddPair('ExecutedQuantity', FExecutedQuantity);
  if not FExecutedAmount.IsEmpty then
    Result.AddPair('ExecutedAmount', FExecutedAmount);
  if not FExecutedBaseFee.IsEmpty then
    Result.AddPair('ExecutedBaseFee', FExecutedBaseFee);
  if not FExecutedOperatorFee.IsEmpty then
    Result.AddPair('ExecutedOperatorFee', FExecutedOperatorFee);
  if not FRefundToken.IsEmpty then
    Result.AddPair('RefundToken', FRefundToken);
  if not FRefundQuantity.IsEmpty then
    Result.AddPair('RefundQuantity', FRefundQuantity);
  Result.AddPair('Timestamp', TJSONNumber.Create(FTimestamp));
  if not FAgent.IsEmpty then
    Result.AddPair('Agent', FAgent);
  if not FSendHash.IsEmpty then
    Result.AddPair('SendHash', FSendHash);
  if not FMarketOrderAmtThreshold.IsEmpty then
    Result.AddPair('MarketOrderAmtThreshold', FMarketOrderAmtThreshold);
end;

{ TRpcThresholdForTradeAndMine.ToJSON }

function TRpcThresholdForTradeAndMine.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('tradeThreshold', FTradeThreshold);
  Result.AddPair('mineThreshold', FMineThreshold);
end;

{ TRpcUserFees.ToJSON }

function TRpcUserFees.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcFeesByPeriod;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FFees do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('fees', JsonArray);
end;

{ TRpcVxFundByPeriod.ToJSON }

function TRpcVxFundByPeriod.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('amount', FAmount);
  Result.AddPair('period', TJSONNumber.Create(FPeriod));
end;

{ TRpcVxFunds.ToJSON }

function TRpcVxFunds.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TRpcVxFundByPeriod;
begin
  Result := TJSONObject.Create;
  JsonArray := TJSONArray.Create;
  for Item in FFunds do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('funds', JsonArray);
end;

{ TRpcVxMineInfo.ToJSON }

function TRpcVxMineInfo.ToJSON: TJSONObject;
var
  DetailJson: TJSONObject;
  Pair: TPair<Integer, string>;
begin
  Result := TJSONObject.Create;
  Result.AddPair('historyMinedSum', FHistoryMinedSum);
  Result.AddPair('total', FTotal);
  Result.AddPair('feeMineTotal', FFeeMineTotal);
  DetailJson := TJSONObject.Create;
  for Pair in FFeeMineDetail do
    DetailJson.AddPair(IntToStr(Pair.Key), Pair.Value);
  Result.AddPair('feeMineDetail', DetailJson);
  Result.AddPair('pledgeMine', FPledgeMine);
  Result.AddPair('makerMine', FMakerMine);
end;

{ TSimpleAccountInfo.ToJSON }

function TSimpleAccountInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('token', FToken);
  Result.AddPair('available', FAvailable);
  Result.AddPair('locked', FLocked);
end;

{ TSimpleFund.ToJSON }

function TSimpleFund.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TSimpleAccountInfo;
begin
  Result := TJSONObject.Create;
  Result.AddPair('address', FAddress);
  JsonArray := TJSONArray.Create;
  for Item in FAccounts do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('accounts', JsonArray);
end;

{ TStakeInfo.ToJSON }

function TStakeInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('stakeAmount', FAmount);
  Result.AddPair('beneficiary', FBeneficiary);
  Result.AddPai('expirationHeight', FExpirationHeight);
  Result.AddPair('expirationTime', TJSONNumber.Create(FExpirationTime));
  Result.AddPair('isDelegated', TJSONBool.Create(FIsDelegated));
  Result.AddPair('delegateAddress', FDelegateAddress);
  Result.AddPair('stakeAddress', FStakeAddress);
  Result.AddPair('bid', TJSONNumber.Create(FBid));
  if not FId.IsEmpty then
    Result.AddPair('id', FId);
  if not FPrincipal.IsEmpty then
    Result.AddPair('principal', FPrincipal);
end;

{ TStakeInfoList.ToJSON }

function TStakeInfoList.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TStakeInfo;
begin
  Result := TJSONObject.Create;
  Result.AddPair('totalStakeAmount', FStakeAmount);
  Result.AddPair('totalStakeCount', TJSONNumber.Create(FCount));
  JsonArray := TJSONArray.Create;
  for Item in FStakeList do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('stakeList', JsonArray);
end;

{ TVIPStakingRpc.ToJSON }

function TVIPStakingRpc.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('stakeAmount', FAmount);
  Result.AddPair('expirationHeight', FExpirationHeight);
  Result.AddPair('expirationTime', TJSONNumber.Create(FExpirationTime));
  if not FId.IsEmpty then
    Result.AddPair('id', FId);
end;

{ TVxUnlock.ToJSON }

function TVxUnlock.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('amount', FAmount);
  Result.AddPair('expirationTime', TJSONNumber.Create(FExpirationTime));
  Result.AddPair('expirationPeriod', TJSONNumber.Create(FExpirationPeriod));
end;

{ TVxUnlockList.ToJSON }

function TVxUnlockList.ToJSON: TJSONObject;
var
  JsonArray: TJSONArray;
  Item: TVxUnlock;
begin
  Result := TJSONObject.Create;
  Result.AddPair('unlockingAmount', FUnlockingAmount);
  Result.AddPair('count', TJSONNumber.Create(FCount));
  JsonArray := TJSONArray.Create;
  for Item in FUnlocks do
    JsonArray.Add(Item.ToJSON);
  Result.AddPair('unlocks', JsonArray);
end;

end.
