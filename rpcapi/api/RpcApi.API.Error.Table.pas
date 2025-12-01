unit RpcApi.Api.ErrorTable;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Common.Errors, Ledger.Verifier, Vm.Util, Vm.Contracts.Dex;

type
  EJsonRpc2 = class(Exception)
  private
    FCode: Integer;
  public
    constructor Create(AMessage: string; ACode: Integer);
    property Code: Integer read FCode;
  end;

var
  IllegalNodeTime: Exception;
  ErrDecryptKey: EJsonRpc2;
  ErrBalanceNotEnough: EJsonRpc2;
  ErrQuotaNotEnough: EJsonRpc2;
  ErrVmIdCollision: EJsonRpc2;
  ErrVmInvaildBlockData: EJsonRpc2;
  ErrVmCalPoWTwice: EJsonRpc2;
  ErrVmMethodNotFound: EJsonRpc2;
  ErrVmInvalidResponseLatency: EJsonRpc2;
  ErrVmContractNotExists: EJsonRpc2;
  ErrVmNoReliableStatus: EJsonRpc2;
  ErrVmInvalidQuotaMultiplier: EJsonRpc2;
  ErrVmPoWNotSupported: EJsonRpc2;
  ErrVmQuotaLimitReached: EJsonRpc2;
  ErrVmInvalidRandomDegree: EJsonRpc2;
  ErrVerifyAccountAddr: EJsonRpc2;
  ErrVerifyHash: EJsonRpc2;
  ErrVerifySignature: EJsonRpc2;
  ErrVerifyNonce: EJsonRpc2;
  ErrVerifyPrevBlock: EJsonRpc2;
  ErrVerifyRPCBlockIsPending: EJsonRpc2;
  ErrVerifyDependentSendBlockNotExists: EJsonRpc2;
  ErrVerifyPowQualificationNotEnough: EJsonRpc2;
  ErrVerifyProducerIllegal: EJsonRpc2;
  ErrVerifyBlockFieldData: EJsonRpc2;
  ErrVerifyIsAlreadyReceived: EJsonRpc2;
  ErrVerifyVmResultInconsistent: EJsonRpc2;
  ErrComposeOrderIdFail: EJsonRpc2;
  ErrDexInvalidOrderType: EJsonRpc2;
  ErrDexInvalidOrderPrice: EJsonRpc2;
  ErrDexInvalidOrderQuantity: EJsonRpc2;
  ErrDexOrderAmountTooSmall: EJsonRpc2;
  ErrDexTradeMarketExists: EJsonRpc2;
  ErrDexTradeMarketNotExists: EJsonRpc2;
  ErrDexTradeOrderNotExistsErr: EJsonRpc2;
  ErrDexCancelOrderOwnerInvalid: EJsonRpc2;
  ErrDexCancelOrderInvalidStatus: EJsonRpc2;
  ErrDexTradeMarketInvalidQuoteToken: EJsonRpc2;
  ErrDexTradeMarketInvalidTokenPair: EJsonRpc2;
  ErrDexFundUserNotExists: EJsonRpc2;

function TryMakeConcernedError(Err: Exception): TPair<Exception, Boolean>;

implementation

var
  ConcernedErrorMap: TDictionary<string, EJsonRpc2>;

{ EJsonRpc2 }

constructor EJsonRpc2.Create(AMessage: string; ACode: Integer);
begin
  inherited Create(AMessage);
  FCode := ACode;
end;

function TryMakeConcernedError(Err: Exception): TPair<Exception, Boolean>;
var
  Rerr: EJsonRpc2;
begin
  if Err = nil then
    Exit(TPair.Create(nil, False));
  if ConcernedErrorMap.TryGetValue(Err.Message, Rerr) then
    Result := TPair.Create(Rerr as Exception, True)
  else
    Result := TPair.Create(Err, False);
end;

initialization
  IllegalNodeTime := Exception.Create('The node time is inaccurate, quite different from the time of latest snapshot block.');
  ErrDecryptKey := EJsonRpc2.Create(EErrDecryptEntropy.Message, -34001);
  ErrBalanceNotEnough := EJsonRpc2.Create(EErrInsufficientBalance.Message, -35001);
  ErrQuotaNotEnough := EJsonRpc2.Create(EErrOutOfQuota.Message, -35002);
  ErrVmIdCollision := EJsonRpc2.Create(EErrIDCollision.Message, -35003);
  ErrVmInvaildBlockData := EJsonRpc2.Create(EErrInvalidMethodParam.Message, -35004);
  ErrVmCalPoWTwice := EJsonRpc2.Create(EErrCalcPoWTwice.Message, -35005);
  ErrVmMethodNotFound := EJsonRpc2.Create(EErrAbiMethodNotFound.Message, -35006);
  ErrVmInvalidResponseLatency := EJsonRpc2.Create(EErrInvalidResponseLatency.Message, -35007);
  ErrVmContractNotExists := EJsonRpc2.Create(EErrContractNotExists.Message, -35008);
  ErrVmNoReliableStatus := EJsonRpc2.Create(EErrNoReliableStatus.Message, -35009);
  ErrVmInvalidQuotaMultiplier := EJsonRpc2.Create(EErrInvalidQuotaMultiplier.Message, -35010);
  ErrVmPoWNotSupported := EJsonRpc2.Create(EErrPoWNotSupportedUnderCongestion.Message, -35011);
  ErrVmQuotaLimitReached := EJsonRpc2.Create(EErrBlockQuotaLimitReached.Message, -35012);
  ErrVmInvalidRandomDegree := EJsonRpc2.Create(EErrInvalidRandomDegree.Message, -35013);
  ErrVerifyAccountAddr := EJsonRpc2.Create(EErrVerifyAccountNotInvalid.Message, -36001);
  ErrVerifyHash := EJsonRpc2.Create(EErrVerifyHashFailed.Message, -36002);
  ErrVerifySignature := EJsonRpc2.Create(EErrVerifySignatureFailed.Message, -36003);
  ErrVerifyNonce := EJsonRpc2.Create(EErrVerifyNonceFailed.Message, -36004);
  ErrVerifyPrevBlock := EJsonRpc2.Create(EErrVerifyPrevBlockFailed.Message, -36005);
  ErrVerifyRPCBlockIsPending := EJsonRpc2.Create(EErrVerifyRPCBlockPendingState.Message, -36006);
  ErrVerifyDependentSendBlockNotExists := EJsonRpc2.Create(EErrVerifyDependentSendBlockNotExists.Message, -36007);
  ErrVerifyPowQualificationNotEnough := EJsonRpc2.Create(EErrVerifyPowNotEligible.Message, -36008);
  ErrVerifyProducerIllegal := EJsonRpc2.Create(EErrVerifyProducerIllegal.Message, -36009);
  ErrVerifyBlockFieldData := EJsonRpc2.Create(EErrVerifyBlockFieldData.Message, -36010);
  ErrVerifyIsAlreadyReceived := EJsonRpc2.Create(EErrVerifySendIsAlreadyReceived.Message, -36011);
  ErrVerifyVmResultInconsistent := EJsonRpc2.Create(EErrVerifyVmResultInconsistent.Message, -36012);
  ErrComposeOrderIdFail := EJsonRpc2.Create(EComposeOrderIdFailErr.Message, -37001);
  ErrDexInvalidOrderType := EJsonRpc2.Create(EInvalidOrderTypeErr.Message, -37002);
  ErrDexInvalidOrderPrice := EJsonRpc2.Create(EInvalidOrderPriceErr.Message, -37003);
  ErrDexInvalidOrderQuantity := EJsonRpc2.Create(EInvalidOrderQuantityErr.Message, -37004);
  ErrDexOrderAmountTooSmall := EJsonRpc2.Create(EOrderAmountTooSmallErr.Message, -37005);
  ErrDexTradeMarketExists := EJsonRpc2.Create(ETradeMarketExistsErr.Message, -37006);
  ErrDexTradeMarketNotExists := EJsonRpc2.Create(ETradeMarketNotExistsErr.Message, -37007);
  ErrDexTradeOrderNotExistsErr := EJsonRpc2.Create(EOrderNotExistsErr.Message, -37008);
  ErrDexCancelOrderOwnerInvalid := EJsonRpc2.Create(ECancelOrderOwnerInvalidErr.Message, -37009);
  ErrDexCancelOrderInvalidStatus := EJsonRpc2.Create(ECancelOrderInvalidStatusErr.Message, -37010);
  ErrDexTradeMarketInvalidQuoteToken := EJsonRpc2.Create(ETradeMarketInvalidQuoteTokenErr.Message, -37011);
  ErrDexTradeMarketInvalidTokenPair := EJsonRpc2.Create(ETradeMarketInvalidTokenPairErr.Message, -37012);
  ErrDexFundUserNotExists := EJsonRpc2.Create(EDexFundUserNotExists.Message, -37013);

  ConcernedErrorMap := TDictionary<string, EJsonRpc2>.Create;
  ConcernedErrorMap.Add(ErrDecryptKey.Message, ErrDecryptKey);
  ConcernedErrorMap.Add(ErrBalanceNotEnough.Message, ErrBalanceNotEnough);
  ConcernedErrorMap.Add(ErrQuotaNotEnough.Message, ErrQuotaNotEnough);
  ConcernedErrorMap.Add(ErrVmIdCollision.Message, ErrVmIdCollision);
  ConcernedErrorMap.Add(ErrVmInvaildBlockData.Message, ErrVmInvaildBlockData);
  ConcernedErrorMap.Add(ErrVmCalPoWTwice.Message, ErrVmCalPoWTwice);
  ConcernedErrorMap.Add(ErrVmMethodNotFound.Message, ErrVmMethodNotFound);
  ConcernedErrorMap.Add(ErrVmInvalidResponseLatency.Message, ErrVmInvalidResponseLatency);
  ConcernedErrorMap.Add(ErrVmContractNotExists.Message, ErrVmContractNotExists);
  ConcernedErrorMap.Add(ErrVmNoReliableStatus.Message, ErrVmNoReliableStatus);
  ConcernedErrorMap.Add(ErrVmInvalidQuotaMultiplier.Message, ErrVmInvalidQuotaMultiplier);
  ConcernedErrorMap.Add(ErrVmPoWNotSupported.Message, ErrVmPoWNotSupported);
  ConcernedErrorMap.Add(ErrVmQuotaLimitReached.Message, ErrVmQuotaLimitReached);
  ConcernedErrorMap.Add(ErrVmInvalidRandomDegree.Message, ErrVmInvalidRandomDegree);
  ConcernedErrorMap.Add(ErrVerifyAccountAddr.Message, ErrVerifyAccountAddr);
  ConcernedErrorMap.Add(ErrVerifyHash.Message, ErrVerifyHash);
  ConcernedErrorMap.Add(ErrVerifySignature.Message, ErrVerifySignature);
  ConcernedErrorMap.Add(ErrVerifyNonce.Message, ErrVerifyNonce);
  ConcernedErrorMap.Add(ErrVerifyPrevBlock.Message, ErrVerifyPrevBlock);
  ConcernedErrorMap.Add(ErrVerifyRPCBlockIsPending.Message, ErrVerifyRPCBlockIsPending);
  ConcernedErrorMap.Add(ErrVerifyDependentSendBlockNotExists.Message, ErrVerifyDependentSendBlockNotExists);
  ConcernedErrorMap.Add(ErrVerifyPowQualificationNotEnough.Message, ErrVerifyPowQualificationNotEnough);
  ConcernedErrorMap.Add(ErrVerifyProducerIllegal.Message, ErrVerifyProducerIllegal);
  ConcernedErrorMap.Add(ErrVerifyBlockFieldData.Message, ErrVerifyBlockFieldData);
  ConcernedErrorMap.Add(ErrVerifyIsAlreadyReceived.Message, ErrVerifyIsAlreadyReceived);
  ConcernedErrorMap.Add(ErrVerifyVmResultInconsistent.Message, ErrVerifyVmResultInconsistent);
  ConcernedErrorMap.Add(ErrComposeOrderIdFail.Message, ErrComposeOrderIdFail);
  ConcernedErrorMap.Add(ErrDexInvalidOrderType.Message, ErrDexInvalidOrderType);
  ConcernedErrorMap.Add(ErrDexInvalidOrderPrice.Message, ErrDexInvalidOrderPrice);
  ConcernedErrorMap.Add(ErrDexInvalidOrderQuantity.Message, ErrDexInvalidOrderQuantity);
  ConcernedErrorMap.Add(ErrDexOrderAmountTooSmall.Message, ErrDexOrderAmountTooSmall);
  ConcernedErrorMap.Add(ErrDexTradeMarketExists.Message, ErrDexTradeMarketExists);
  ConcernedErrorMap.Add(ErrDexTradeMarketNotExists.Message, ErrDexTradeMarketNotExists);
  ConcernedErrorMap.Add(ErrDexTradeOrderNotExistsErr.Message, ErrDexTradeOrderNotExistsErr);
  ConcernedErrorMap.Add(ErrDexCancelOrderOwnerInvalid.Message, ErrDexCancelOrderOwnerInvalid);
  ConcernedErrorMap.Add(ErrDexCancelOrderInvalidStatus.Message, ErrDexCancelOrderInvalidStatus);
  ConcernedErrorMap.Add(ErrDexTradeMarketInvalidQuoteToken.Message, ErrDexTradeMarketInvalidQuoteToken);
  ConcernedErrorMap.Add(ErrDexTradeMarketInvalidTokenPair.Message, ErrDexTradeMarketInvalidTokenPair);
  ConcernedErrorMap.Add(ErrDexFundUserNotExists.Message, ErrDexFundUserNotExists);
end.
