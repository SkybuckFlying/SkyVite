unit Vm.Contracts.Contracts;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Common.Types.Address, Common.Types.Hash, Common.Types.TokenTypeId, Common.Upgrade,
  Interfaces.VmDb, Interfaces.Core.AccountBlock, Interfaces.Core.ContractMeta,
  Vm.Abi.Abi, Vm.Util.Util, Vm.Quota.Quota;

type
  TContractsParams = record
    // Define contract parameters here if needed
  end;

  TNodeConfigParams = record
    Params: TContractsParams;
  end;

  IVmEnvironment = interface
    ['{A7E4E2D8-338A-462E-A41E-2722816945D0}']
    function GlobalStatus: TGlobalStatus;
    function ConsensusReader: IConsensusReader;
  end;

  IBuiltinContractMethod = interface
    ['{A7E4E2D8-338A-462E-A41E-2722816945D1}']
    function GetFee(Block: TAccountBlock): TBigInteger;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
  end;

  TBuiltinContract = record
    M: TDictionary<string, IBuiltinContractMethod>;
    Abi: TAbiContract;
  end;

var
  SimpleContracts: TDictionary<TAddress, TBuiltinContract>;
  DexContracts: TDictionary<TAddress, TBuiltinContract>;
  DexAgentContracts: TDictionary<TAddress, TBuiltinContract>;
  LeafContracts: TDictionary<TAddress, TBuiltinContract>;
  EarthContracts: TDictionary<TAddress, TBuiltinContract>;
  DexRobotContracts: TDictionary<TAddress, TBuiltinContract>;
  DexStableMarketContracts: TDictionary<TAddress, TBuiltinContract>;
  DexEnrichOrderContracts: TDictionary<TAddress, TBuiltinContract>;
  DexCrossTransferContracts: TDictionary<TAddress, TBuiltinContract>;

procedure InitContractsConfig(IsTestParam: Boolean);
function GetBuiltinContractMethod(Addr: TAddress; MethodSelector: TBytes; SbHeight: UInt64): TPair<IBuiltinContractMethod, Boolean>;
function NewLog(C: TAbiContract; const Name: string; const Params: array of const): TVmLog;

implementation

uses
  Vm.Contracts.Abi.AbiMethods;

var
  NodeConfig: TNodeConfigParams;

procedure InitContractsConfig(IsTestParam: Boolean);
begin
  // Placeholder for contractsParamsTest and contractsParamsMainNet
  // if IsTestParam then
  //   NodeConfig.Params := contractsParamsTest
  // else
  //   NodeConfig.Params := contractsParamsMainNet;
end;

function NewSimpleContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
  BuiltinContract: TBuiltinContract;
begin
  Contracts := TDictionary<TAddress, TBuiltinContract>.Create;

  BuiltinContract.M := TDictionary<string, IBuiltinContractMethod>.Create;
  BuiltinContract.M.Add(MethodNameStake, TMethodStake.Create(MethodNameStake));
  BuiltinContract.M.Add(MethodNameCancelStake, TMethodCancelStake.Create(MethodNameCancelStake));
  BuiltinContract.Abi := ABIDataQuota;
  Contracts.Add(AddressQuota, BuiltinContract);

  BuiltinContract.M := TDictionary<string, IBuiltinContractMethod>.Create;
  BuiltinContract.M.Add(MethodNameRegister, TMethodRegister.Create(MethodNameRegister));
  BuiltinContract.M.Add(MethodNameRevoke, TMethodRevoke.Create(MethodNameRevoke));
  BuiltinContract.M.Add(MethodNameWithdrawReward, TMethodWithdrawReward.Create(MethodNameWithdrawReward));
  BuiltinContract.M.Add(MethodNameUpdateBlockProducingAddress, TMethodUpdateBlockProducingAddress.Create(MethodNameUpdateBlockProducingAddress));
  BuiltinContract.M.Add(MethodNameVote, TMethodVote.Create(MethodNameVote));
  BuiltinContract.M.Add(MethodNameCancelVote, TMethodCancelVote.Create(MethodNameCancelVote));
  BuiltinContract.Abi := ABIDataGovernance;
  Contracts.Add(AddressGovernance, BuiltinContract);

  BuiltinContract.M := TDictionary<string, IBuiltinContractMethod>.Create;
  BuiltinContract.M.Add(MethodNameIssue, TMethodIssue.Create(MethodNameIssue));
  BuiltinContract.M.Add(MethodNameReIssue, TMethodReIssue.Create(MethodNameReIssue));
  BuiltinContract.M.Add(MethodNameBurn, TMethodBurn.Create(MethodNameBurn));
  BuiltinContract.M.Add(MethodNameBurnV2, TMethodBurn2.Create(MethodNameBurnV2));
  BuiltinContract.M.Add(MethodNameTransferOwnership, TMethodTransferOwnership.Create(MethodNameTransferOwnership));
  BuiltinContract.M.Add(MethodNameDisableReIssue, TMethodDisableReIssue.Create(MethodNameDisableReIssue));
  BuiltinContract.Abi := ABIDataAsset;
  Contracts.Add(AddressAsset, BuiltinContract);

  Result := Contracts;
end;

function NewDexContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
  BuiltinContract: TBuiltinContract;
begin
  Contracts := NewSimpleContracts;

  Contracts[AddressQuota].M.Add(MethodNameDelegateStake, TMethodDelegateStake.Create(MethodNameDelegateStake));
  Contracts[AddressQuota].M.Add(MethodNameCancelDelegateStake, TMethodCancelDelegateStake.Create(MethodNameCancelDelegateStake));
  Contracts[AddressAsset].M.Add(MethodNameGetTokenInfo, TMethodGetTokenInfo.Create(MethodNameGetTokenInfo));

  BuiltinContract.M := TDictionary<string, IBuiltinContractMethod>.Create;
  BuiltinContract.M.Add(MethodNameDexFundUserDeposit, TMethodDexFundDeposit.Create(MethodNameDexFundUserDeposit));
  BuiltinContract.M.Add(MethodNameDexFundUserWithdraw, TMethodDexFundWithdraw.Create(MethodNameDexFundUserWithdraw));
  BuiltinContract.M.Add(MethodNameDexFundNewMarket, TMethodDexFundOpenNewMarket.Create(MethodNameDexFundNewMarket));
  BuiltinContract.M.Add(MethodNameDexFundNewOrder, TMethodDexFundPlaceOrder.Create(MethodNameDexFundNewOrder));
  BuiltinContract.M.Add(MethodNameDexFundSettleOrders, TMethodDexFundSettleOrders.Create(MethodNameDexFundSettleOrders));
  BuiltinContract.M.Add(MethodNameDexFundPeriodJob, TMethodDexFundTriggerPeriodJob.Create(MethodNameDexFundPeriodJob));
  BuiltinContract.M.Add(MethodNameDexFundPledgeForVx, TMethodDexFundStakeForMining.Create(MethodNameDexFundPledgeForVx));
  BuiltinContract.M.Add(MethodNameDexFundPledgeForVip, TMethodDexFundStakeForVIP.Create(MethodNameDexFundPledgeForVip));
  BuiltinContract.M.Add(MethodNameDexFundPledgeCallback, TMethodDexFundDelegateStakeCallback.Create(MethodNameDexFundPledgeCallback));
  BuiltinContract.M.Add(MethodNameDexFundCancelPledgeCallback, TMethodDexFundCancelDelegateStakeCallback.Create(MethodNameDexFundCancelPledgeCallback));
  BuiltinContract.M.Add(MethodNameDexFundGetTokenInfoCallback, TMethodDexFundGetTokenInfoCallback.Create(MethodNameDexFundGetTokenInfoCallback));
  BuiltinContract.M.Add(MethodNameDexFundOwnerConfig, TMethodDexFundDexAdminConfig.Create(MethodNameDexFundOwnerConfig));
  BuiltinContract.M.Add(MethodNameDexFundOwnerConfigTrade, TMethodDexFundTradeAdminConfig.Create(MethodNameDexFundOwnerConfigTrade));
  BuiltinContract.M.Add(MethodNameDexFundMarketOwnerConfig, TMethodDexFundMarketAdminConfig.Create(MethodNameDexFundMarketOwnerConfig));
  BuiltinContract.M.Add(MethodNameDexFundTransferTokenOwner, TMethodDexFundTransferTokenOwnership.Create(MethodNameDexFundTransferTokenOwner));
  BuiltinContract.M.Add(MethodNameDexFundNotifyTime, TMethodDexFundNotifyTime.Create(MethodNameDexFundNotifyTime));
  BuiltinContract.M.Add(MethodNameDexFundNewInviter, TMethodDexFundCreateNewInviter.Create(MethodNameDexFundNewInviter));
  BuiltinContract.M.Add(MethodNameDexFundBindInviteCode, TMethodDexFundBindInviteCode.Create(MethodNameDexFundBindInviteCode));
  BuiltinContract.M.Add(MethodNameDexFundEndorseVxMinePool, TMethodDexFundEndorseVx.Create(MethodNameDexFundEndorseVxMinePool));
  BuiltinContract.M.Add(MethodNameDexFundSettleMakerMinedVx, TMethodDexFundSettleMakerMinedVx.Create(MethodNameDexFundSettleMakerMinedVx));
  BuiltinContract.Abi := ABIDataDexFund;
  Contracts.Add(AddressDexFund, BuiltinContract);

  BuiltinContract.M := TDictionary<string, IBuiltinContractMethod>.Create;
  BuiltinContract.M.Add(MethodNameDexTradeNewOrder, TMethodDexTradePlaceOrder.Create(MethodNameDexTradeNewOrder));
  BuiltinContract.M.Add(MethodNameDexTradeCancelOrder, TMethodDexTradeCancelOrder.Create(MethodNameDexTradeCancelOrder));
  BuiltinContract.M.Add(MethodNameDexTradeNotifyNewMarket, TMethodDexTradeSyncNewMarket.Create(MethodNameDexTradeNotifyNewMarket));
  BuiltinContract.M.Add(MethodNameDexTradeCleanExpireOrders, TMethodDexTradeClearExpiredOrders.Create(MethodNameDexTradeCleanExpireOrders));
  BuiltinContract.Abi := ABIDataDexTrade;
  Contracts.Add(AddressDexTrade, BuiltinContract);

  Result := Contracts;
end;

function NewDexAgentContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewDexContracts;
  Contracts[AddressDexFund].M.Add(MethodNameDexFundStakeForSuperVip, TMethodDexFundStakeForSVIP.Create(MethodNameDexFundStakeForSuperVip));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundConfigMarketsAgent, TMethodDexFundConfigMarketAgents.Create(MethodNameDexFundConfigMarketsAgent));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundNewAgentOrder, TMethodDexFundPlaceAgentOrder.Create(MethodNameDexFundNewAgentOrder));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeCancelOrderByHash, TMethodDexTradeCancelOrderByTransactionHash.Create(MethodNameDexTradeCancelOrderByHash));
  Result := Contracts;
end;

function NewLeafContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewDexAgentContracts;

  Contracts[AddressQuota].M.Add(MethodNameStakeV2, TMethodStake.Create(MethodNameStakeV2));
  Contracts[AddressQuota].M.Add(MethodNameCancelStakeV2, TMethodCancelStake.Create(MethodNameCancelStakeV2));
  Contracts[AddressQuota].M.Add(MethodNameDelegateStakeV2, TMethodDelegateStake.Create(MethodNameDelegateStakeV2));
  Contracts[AddressQuota].M.Add(MethodNameCancelDelegateStakeV2, TMethodCancelDelegateStake.Create(MethodNameCancelDelegateStakeV2));

  Contracts[AddressGovernance].M.Add(MethodNameUpdateBlockProducintAddressV2, TMethodUpdateBlockProducingAddress.Create(MethodNameUpdateBlockProducintAddressV2));
  Contracts[AddressGovernance].M.Add(MethodNameRevokeV2, TMethodRevoke.Create(MethodNameRevokeV2));
  Contracts[AddressGovernance].M.Add(MethodNameWithdrawRewardV2, TMethodWithdrawReward.Create(MethodNameWithdrawRewardV2));

  Contracts[AddressAsset].M.Add(MethodNameIssueV2, TMethodIssue.Create(MethodNameIssueV2));
  Contracts[AddressAsset].M.Add(MethodNameReIssueV2, TMethodReIssue.Create(MethodNameReIssueV2));
  Contracts[AddressAsset].M.Add(MethodNameDisableReIssueV2, TMethodDisableReIssue.Create(MethodNameDisableReIssueV2));
  Contracts[AddressAsset].M.Add(MethodNameTransferOwnershipV2, TMethodTransferOwnership.Create(MethodNameTransferOwnershipV2));

  Contracts[AddressDexFund].M.Add(MethodNameDexFundDeposit, TMethodDexFundDeposit.Create(MethodNameDexFundDeposit));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundWithdraw, TMethodDexFundWithdraw.Create(MethodNameDexFundWithdraw));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundOpenNewMarket, TMethodDexFundOpenNewMarket.Create(MethodNameDexFundOpenNewMarket));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundPlaceOrder, TMethodDexFundPlaceOrder.Create(MethodNameDexFundPlaceOrder));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundSettleOrdersV2, TMethodDexFundSettleOrders.Create(MethodNameDexFundSettleOrdersV2));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundTriggerPeriodJob, TMethodDexFundTriggerPeriodJob.Create(MethodNameDexFundTriggerPeriodJob));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundStakeForMining, TMethodDexFundStakeForMining.Create(MethodNameDexFundStakeForMining));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundStakeForVIP, TMethodDexFundStakeForVIP.Create(MethodNameDexFundStakeForVIP));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundDelegateStakeCallback, TMethodDexFundDelegateStakeCallback.Create(MethodNameDexFundDelegateStakeCallback));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCancelDelegateStakeCallback, TMethodDexFundCancelDelegateStakeCallback.Create(MethodNameDexFundCancelDelegateStakeCallback));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundDexAdminConfig, TMethodDexFundDexAdminConfig.Create(MethodNameDexFundDexAdminConfig));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundTradeAdminConfig, TMethodDexFundTradeAdminConfig.Create(MethodNameDexFundTradeAdminConfig));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundMarketAdminConfig, TMethodDexFundMarketAdminConfig.Create(MethodNameDexFundMarketAdminConfig));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundTransferTokenOwner, TMethodDexFundTransferTokenOwnership.Create(MethodNameDexFundTransferTokenOwner));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCreateNewInviter, TMethodDexFundCreateNewInviter.Create(MethodNameDexFundCreateNewInviter));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundBindInviteCodeV2, TMethodDexFundBindInviteCode.Create(MethodNameDexFundBindInviteCodeV2));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundEndorseVxV2, TMethodDexFundEndorseVx.Create(MethodNameDexFundEndorseVxV2));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundSettleMakerMinedVxV2, TMethodDexFundSettleMakerMinedVx.Create(MethodNameDexFundSettleMakerMinedVxV2));

  Contracts[AddressDexTrade].M.Add(MethodNameDexTradePlaceOrder, TMethodDexTradePlaceOrder.Create(MethodNameDexTradePlaceOrder));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeCancelOrderV2, TMethodDexTradeCancelOrder.Create(MethodNameDexTradeCancelOrderV2));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeSyncNewMarket, TMethodDexTradeSyncNewMarket.Create(MethodNameDexTradeSyncNewMarket));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeCleanExpireOrders, TMethodDexTradeClearExpiredOrders.Create(MethodNameDexTradeCleanExpireOrders));

  Contracts[AddressDexFund].M.Add(MethodNameDexFundStakeForSuperVip, TMethodDexFundStakeForSVIP.Create(MethodNameDexFundStakeForSuperVip));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundConfigMarketsAgent, TMethodDexFundConfigMarketAgents.Create(MethodNameDexFundConfigMarketsAgent));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundNewAgentOrder, TMethodDexFundPlaceAgentOrder.Create(MethodNameDexFundNewAgentOrder));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeCancelOrderByHash, TMethodDexTradeCancelOrderByTransactionHash.Create(MethodNameDexTradeCancelOrderByHash));

  Result := Contracts;
end;

function NewEarthContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewLeafContracts;
  Contracts[AddressAsset].M.Add(MethodNameGetTokenInfoV3, TMethodGetTokenInfo.Create(MethodNameGetTokenInfoV3));
  Contracts[AddressGovernance].M.Add(MethodNameRegisterV3, TMethodRegister.Create(MethodNameRegisterV3));
  Contracts[AddressGovernance].M.Add(MethodNameUpdateBlockProducintAddressV3, TMethodUpdateBlockProducingAddress.Create(MethodNameUpdateBlockProducintAddressV3));
  Contracts[AddressGovernance].M.Add(MethodNameUpdateSBPRewardWithdrawAddress, TMethodUpdateRewardWithdrawAddress.Create(MethodNameUpdateSBPRewardWithdrawAddress));
  Contracts[AddressGovernance].M.Add(MethodNameRevokeV3, TMethodRevoke.Create(MethodNameRevokeV3));
  Contracts[AddressGovernance].M.Add(MethodNameWithdrawRewardV3, TMethodWithdrawReward.Create(MethodNameWithdrawRewardV3));
  Contracts[AddressGovernance].M.Add(MethodNameVoteV3, TMethodVote.Create(MethodNameVoteV3));
  Contracts[AddressGovernance].M.Add(MethodNameCancelVoteV3, TMethodCancelVote.Create(MethodNameCancelVoteV3));

  Contracts[AddressDexFund].M.Add(MethodNameDexFundLockVxForDividend, TMethodDexFundLockVxForDividend.Create(MethodNameDexFundLockVxForDividend));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundSwitchConfig, TMethodDexFundSwitchConfig.Create(MethodNameDexFundSwitchConfig));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundStakeForPrincipalSVIP, TMethodDexFundStakeForPrincipalSVIP.Create(MethodNameDexFundStakeForPrincipalSVIP));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCancelStakeById, TMethodDexFundCancelStakeById.Create(MethodNameDexFundCancelStakeById));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundDelegateStakeCallbackV2, TMethodDexFundDelegateStakeCallbackV2.Create(MethodNameDexFundDelegateStakeCallbackV2));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCancelDelegateStakeCallbackV2, TMethodDexFundCancelDelegateStakeCallbackV2.Create(MethodNameDexFundCancelDelegateStakeCallbackV2));

  Contracts[AddressQuota].M.Add(MethodNameStakeV3, TMethodStakeV3.Create(MethodNameStakeV3));
  Contracts[AddressQuota].M.Add(MethodNameCancelStakeV3, TMethodCancelStakeV3.Create(MethodNameCancelStakeV3));
  Contracts[AddressQuota].M.Add(MethodNameStakeWithCallback, TMethodStakeV3.Create(MethodNameStakeWithCallback));
  Contracts[AddressQuota].M.Add(MethodNameCancelStakeWithCallback, TMethodCancelStakeV3.Create(MethodNameCancelStakeWithCallback));
  Result := Contracts;
end;

function NewDexRobotContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewEarthContracts;
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCancelOrderBySendHash, TMethodDexCancelOrderBySendHash.Create(MethodNameDexFundCancelOrderBySendHash));
  Contracts[AddressDexTrade].M.Add(MethodNameDexTradeInnerCancelOrderBySendHash, TMethodDexTradeInnerCancelOrderBySendHash.Create(MethodNameDexTradeInnerCancelOrderBySendHash));
  Result := Contracts;
end;

function NewDexStableMarketContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewDexRobotContracts;
  Contracts[AddressDexFund].M.Add(MethodNameDexFundCommonAdminConfig, TMethodDexCommonAdminConfig.Create(MethodNameDexFundCommonAdminConfig));
  Result := Contracts;
end;

function NewDexEnrichOrderContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewDexStableMarketContracts;
  Contracts[AddressDexFund].M.Add(MethodNameDexFundTransfer, TMethodDexTransfer.Create(MethodNameDexFundTransfer));
  Result := Contracts;
end;

function NewDexCrossTransferContracts: TDictionary<TAddress, TBuiltinContract>;
var
  Contracts: TDictionary<TAddress, TBuiltinContract>;
begin
  Contracts := NewDexEnrichOrderContracts;
  Contracts[AddressDexFund].M.Add(MethodNameDexFundAgentDeposit, TMethodDexAgentDeposit.Create(MethodNameDexFundAgentDeposit));
  Contracts[AddressDexFund].M.Add(MethodNameDexFundAssignedWithdraw, TMethodDexAssignedWithdraw.Create(MethodNameDexAssignedWithdraw));
  Result := Contracts;
end;

function GetBuiltinContractMethod(Addr: TAddress; MethodSelector: TBytes; SbHeight: UInt64): TPair<IBuiltinContractMethod, Boolean>;
var
  ContractsMap: TDictionary<TAddress, TBuiltinContract>;
  P: TBuiltinContract;
  Method: TMethod;
  C: IBuiltinContractMethod;
begin
  if IsVersionXUpgrade(SbHeight) then
    ContractsMap := DexCrossTransferContracts
  else if IsVersion11Upgrade(SbHeight) then
    ContractsMap := DexEnrichOrderContracts
  else if IsDexStableMarketUpgrade(SbHeight) then
    ContractsMap := DexStableMarketContracts
  else if IsDexRobotUpgrade(SbHeight) then
    ContractsMap := DexRobotContracts
  else if IsEarthUpgrade(SbHeight) then
    ContractsMap := EarthContracts
  else if IsLeafUpgrade(SbHeight) then
    ContractsMap := LeafContracts
  else if IsStemUpgrade(SbHeight) then
    ContractsMap := DexAgentContracts
  else if IsDexUpgrade(SbHeight) then
    ContractsMap := DexContracts
  else
    ContractsMap := SimpleContracts;

  if ContractsMap.TryGetValue(Addr, P) then
  begin
    try
      Method := P.Abi.MethodById(MethodSelector);
      if P.M.TryGetValue(Method.Name, C) then
        Result := TPair<IBuiltinContractMethod, Boolean>.Create(C, True)
      else
        Result := TPair<IBuiltinContractMethod, Boolean>.Create(nil, True); // Method not found, but address exists
    except
      on E: Exception do
        Result := TPair<IBuiltinContractMethod, Boolean>.Create(nil, True); // Error in MethodById, but address exists
    end;
  end
  else
    Result := TPair<IBuiltinContractMethod, Boolean>.Create(nil, False); // Address not found
end;

function NewLog(C: TAbiContract; const Name: string; const Params: array of const): TVmLog;
var
  Topics: TArray<THash>;
  Data: TBytes;
begin
  Topics := C.PackEvent(Name, Params).Item1;
  Data := C.PackEvent(Name, Params).Item2;
  Result.Topics := Topics;
  Result.Data := Data;
end;

initialization
  SimpleContracts := NewSimpleContracts;
  DexContracts := NewDexContracts;
  DexAgentContracts := NewDexAgentContracts;
  LeafContracts := NewLeafContracts;
  EarthContracts := NewEarthContracts;
  DexRobotContracts := NewDexRobotContracts;
  DexStableMarketContracts := NewDexStableMarketContracts;
  DexEnrichOrderContracts := NewDexEnrichOrderContracts;
  DexCrossTransferContracts := NewDexCrossTransferContracts;

end.
