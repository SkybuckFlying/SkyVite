unit Vm.Contracts.Dex.DexErrors;

interface

uses
  System.SysUtils;

type
  EDexInvalidInputParam = class(Exception);
  EDexInvalidOrderId = class(Exception);
  EDexInvalidOrderHash = class(Exception);
  EDexInvalidOrderType = class(Exception);
  EDexInvalidOrderPrice = class(Exception);
  EDexInvalidOrderQuantity = class(Exception);
  EDexOrderNotExists = class(Exception);
  EDexOrderAmountTooSmall = class(Exception);
  EDexStopped = class(Exception);
  EDexTradeMarketExists = class(Exception);
  EDexTradeMarketNotExists = class(Exception);
  EDexTradeMarkets = class(Exception);
  EDexTradeMarketStopped = class(Exception);
  EDexTradeMarketNotGranted = class(Exception);
  EDexComposeOrderIdFail = class(Exception);
  EDexDeComposeOrderIdFail = class(Exception);
  EDexTradeMarketInvalidQuoteToken = class(Exception);
  EDexTradeMarketInvalidTokenPair = class(Exception);
  EDexTradeMarketAllowMine = class(Exception);
  EDexTradeMarketNotAllowMine = class(Exception);
  EDexTradeMarketStableMarket = class(Exception);
  EDexTradeMarketNotStableMarket = class(Exception);
  EDexCancelOrderOwnerInvalid = class(Exception);
  EDexCancelOrderInvalidStatus = class(Exception);
  EDexOnlyOwnerAllow = class(Exception);
  EDexInvalidOperation = class(Exception);
  EDexExceedFundAvailable = class(Exception);
  EDexExceedFundLocked = class(Exception);
  EDexInvalidStakeAmount = class(Exception);
  EDexInvalidStakeActionType = class(Exception);
  EDexExceedStakedAvailable = class(Exception);
  EDexStakingAmountLeavedNotValid = class(Exception);
  EDexVIPStakingExists = class(Exception);
  EDexVIPStakingNotExists = class(Exception);
  EDexSuperVipStakingExists = class(Exception);
  EDexSuperVIPStakingNotExists = class(Exception);
  EDexStakingInfoByIdNotExists = class(Exception);
  EDexInvalidSourceAddress = class(Exception);
  EDexInvalidAmountForStakeCallback = class(Exception);
  EDexInvalidIdForStakeCallback = class(Exception);
  EDexInvalidToken = class(Exception);
  EDexPendingNewMarketInnerConflict = class(Exception);
  EDexGetTokenInfoCallbackInnerConflict = class(Exception);
  EDexInvalidTimestampFromTimeOracle = class(Exception);
  EDexOracleTimestampExceedPeriodGap = class(Exception);
  EDexInvalidOperatorFeeRate = class(Exception);
  EDexNoDexFeesFoundForValidPeriod = class(Exception);
  EDexNotSetTimestamp = class(Exception);
  EDexIterateVmDbFailed = class(Exception);
  EDexNotSetMaintainer = class(Exception);
  EDexNotSetMakerMiningAdmin = class(Exception);
  EDexAlreadyIsInviter = class(Exception);
  EDexInvalidInviteCode = class(Exception);
  EDexNotBindInviter = class(Exception);
  EDexAlreadyBindInviter = class(Exception);
  EDexNewInviteCodeFail = class(Exception);
  EDexAlreadyQuoteType = class(Exception);
  EDexInvalidQuoteTokenType = class(Exception);
  EDexFundOwnerNotConfig = class(Exception);
  EDexMultiMarketsInOneAction = class(Exception);
  EDexFundUserNotExists = class(Exception);
  EDexLockedVxAmountLeavedNotValid = class(Exception);
  EDexInternal = class(Exception);

implementation

end.
