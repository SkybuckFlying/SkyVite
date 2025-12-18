unit vm.util.quota;

interface

uses
  common.helper,
  common.upgrade,
  interfaces.core,
  SysUtils,
  VM.Util.Common,
  VM.Util.Consensus.Reader,
  VM.Util.DB.Helper,
  VM.Util.Errors,
  VM.Util.IntPool,
  VM.Util.Intpool.Test,
  VM.Util.Quota.Test,
  VM.Util.Types;

const
  CommonQuotaMultiplier = 10;
  quotaMultiplierDivision = 10;
  QuotaAccumulationBlockCount = 75;

type
  TQuotaTable = record
    AddQuota: UInt64;
    MulQuota: UInt64;
    SubQuota: UInt64;
    DivQuota: UInt64;
    SDivQuota: UInt64;
    ModQuota: UInt64;
    SModQuota: UInt64;
    AddModQuota: UInt64;
    MulModQuota: UInt64;
    ExpQuota: UInt64;
    ExpByteQuota: UInt64;
    SignExtendQuota: UInt64;
    LtQuota: UInt64;
    GtQuota: UInt64;
    SltQuota: UInt64;
    SgtQuota: UInt64;
    EqQuota: UInt64;
    IsZeroQuota: UInt64;
    AndQuota: UInt64;
    OrQuota: UInt64;
    XorQuota: UInt64;
    NotQuota: UInt64;
    ByteQuota: UInt64;
    ShlQuota: UInt64;
    ShrQuota: UInt64;
    SarQuota: UInt64;
    Blake2bQuota: UInt64;
    Blake2bWordQuota: UInt64;
    AddressQuota: UInt64;
    BalanceQuota: UInt64;
    CallerQuota: UInt64;
    CallValueQuota: UInt64;
    CallDataLoadQuota: UInt64;
    CallDataSizeQuota: UInt64;
    CallDataCopyQuota: UInt64;
    MemCopyWordQuota: UInt64;
    CodeSizeQuota: UInt64;
    CodeCopyQuota: UInt64;
    ReturnDataSizeQuota: UInt64;
    ReturnDataCopyQuota: UInt64;
    TimestampQuota: UInt64;
    HeightQuota: UInt64;
    TokenIDQuota: UInt64;
    AccountHeightQuota: UInt64;
    PreviousHashQuota: UInt64;
    FromBlockHashQuota: UInt64;
    SeedQuota: UInt64;
    RandomQuota: UInt64;
    PopQuota: UInt64;
    MloadQuota: UInt64;
    MstoreQuota: UInt64;
    Mstore8Quota: UInt64;
    SloadQuota: UInt64;
    SstoreResetQuota: UInt64;
    SstoreInitQuota: UInt64;
    SstoreCleanQuota: UInt64;
    SstoreNoopQuota: UInt64;
    SstoreMemQuota: UInt64;
    JumpQuota: UInt64;
    JumpiQuota: UInt64;
    PcQuota: UInt64;
    MsizeQuota: UInt64;
    JumpdestQuota: UInt64;
    PushQuota: UInt64;
    DupQuota: UInt64;
    SwapQuota: UInt64;
    LogQuota: UInt64;
    LogTopicQuota: UInt64;
    LogDataQuota: UInt64;
    CallMinusQuota: UInt64;
    MemQuotaDivision: UInt64;
    SnapshotQuota: UInt64;
    CodeQuota: UInt64;
    MemQuota: UInt64;
    TxQuota: UInt64;
    TxDataQuota: UInt64;
    CreateTxRequestQuota: UInt64;
    CreateTxResponseQuota: UInt64;
    RegisterQuota: UInt64;
    UpdateBlockProducingAddressQuota: UInt64;
    UpdateRewardWithdrawAddressQuota: UInt64;
    RevokeQuota: UInt64;
    WithdrawRewardQuota: UInt64;
    VoteQuota: UInt64;
    CancelVoteQuota: UInt64;
    StakeQuota: UInt64;
    CancelStakeQuota: UInt64;
    DelegateStakeQuota: UInt64;
    CancelDelegateStakeQuota: UInt64;
    IssueQuota: UInt64;
    ReIssueQuota: UInt64;
    BurnQuota: UInt64;
    TransferOwnershipQuota: UInt64;
    DisableReIssueQuota: UInt64;
    GetTokenInfoQuota: UInt64;
    DexFundDepositQuota: UInt64;
    DexFundWithdrawQuota: UInt64;
    DexFundOpenNewMarketQuota: UInt64;
    DexFundPlaceOrderQuota: UInt64;
    DexFundSettleOrdersQuota: UInt64;
    DexFundTriggerPeriodJobQuota: UInt64;
    DexFundStakeForMiningQuota: UInt64;
    DexFundStakeForVipQuota: UInt64;
    DexFundStakeForSuperVIPQuota: UInt64;
    DexFundDelegateStakeCallbackQuota: UInt64;
    DexFundCancelDelegateStakeCallbackQuota: UInt64;
    DexFundGetTokenInfoCallbackQuota: UInt64;
    DexFundAdminConfigQuota: UInt64;
    DexFundTradeAdminConfigQuota: UInt64;
    DexFundMarketAdminConfigQuota: UInt64;
    DexFundTransferTokenOwnershipQuota: UInt64;
    DexFundNotifyTimeQuota: UInt64;
    DexFundCreateNewInviterQuota: UInt64;
    DexFundBindInviteCodeQuota: UInt64;
    DexFundEndorseVxQuota: UInt64;
    DexFundSettleMakerMinedVxQuota: UInt64;
    DexFundConfigMarketAgentsQuota: UInt64;
    DexFundPlaceAgentOrderQuota: UInt64;
    DexFundLockVxForDividendQuota: UInt64;
    DexFundSwitchConfigQuota: UInt64;
    DexFundStakeForPrincipalSuperVIPQuota: UInt64;
    DexFundCancelStakeByIdQuota: UInt64;
    DexFundDelegateStakeCallbackV2Quota: UInt64;
    DexFundDelegateCancelStakeCallbackV2Quota: UInt64;
    DexFundCancelOrderBySendHashQuota: UInt64;
    DexFundCommonAdminConfigQuota: UInt64;
    DexFundTransferQuota: UInt64;
    DexFundAgentDepositQuota: UInt64;
    DexFundAssignedWithdrawQuota: UInt64;
  end;

function MultipleCost(cost: UInt64; quotaMultiplier: Byte): UInt64;
function UseQuota(quotaLeft, cost: UInt64): UInt64;
function UseQuotaWithFlag(quotaLeft, cost: UInt64; flag: Boolean): UInt64;
function BlockGasCost(data: TBytes; baseGas: UInt64; snapshotCount: Byte; quotaTable: PQuotaTable): UInt64;
function DataQuotaCost(data: TBytes; quotaTable: PQuotaTable): UInt64;
function RequestQuotaCost(data: TBytes; quotaTable: PQuotaTable): UInt64;
procedure CalcQuotaUsed(useQuota: Boolean; quotaTotal, quotaAddition, quotaLeft: UInt64; err: Exception; out qStakeUsed, qUsed: UInt64);
function IsPoW(block: TAccountBlock): Boolean;
function QuotaTableByHeight(sbHeight: UInt64): PQuotaTable;

implementation

uses
  vm.util.errors;

var
  initQuotaTable: TQuotaTable;
  viteQuotaTable: TQuotaTable;
  dexAgentQuotaTable: TQuotaTable;
  earthQuotaTable: TQuotaTable;
  dexRobotQuotaTable: TQuotaTable;
  dexStableMarketQuotaTable: TQuotaTable;
  version10QuotaTable: TQuotaTable;
  version11QuotaTable: TQuotaTable;
  versionXQuotaTable: TQuotaTable;

function MultipleCost(cost: UInt64; quotaMultiplier: Byte): UInt64;
var
  ratioUint64: UInt64;
begin
  if quotaMultiplier < CommonQuotaMultiplier then
    raise ErrInvalidQuotaMultiplier;
  if quotaMultiplier = CommonQuotaMultiplier then
    Exit(cost);
  ratioUint64 := quotaMultiplier;
  if cost > High(UInt64) div ratioUint64 then
    raise ErrGasUintOverflow;
  Result := cost * ratioUint64 div quotaMultiplierDivision;
end;

function UseQuota(quotaLeft, cost: UInt64): UInt64;
begin
  if quotaLeft < cost then
    raise ErrOutOfQuota;
  Result := quotaLeft - cost;
end;

function UseQuotaWithFlag(quotaLeft, cost: UInt64; flag: Boolean): UInt64;
begin
  if flag then
    Result := UseQuota(quotaLeft, cost)
  else
    Result := quotaLeft + cost;
end;

function BlockGasCost(data: TBytes; baseGas: UInt64; snapshotCount: Byte; quotaTable: PQuotaTable): UInt64;
var
  gas, gasData, confirmGas: UInt64;
begin
  gas := baseGas;
  gasData := DataQuotaCost(data, quotaTable);
  if High(UInt64) - gas < gasData then
    raise ErrGasUintOverflow;
  gas := gas + gasData;
  if snapshotCount = 0 then
    Exit(gas);
  confirmGas := UInt64(snapshotCount) * quotaTable^.SnapshotQuota;
  if High(UInt64) - gas < confirmGas then
    raise ErrGasUintOverflow;
  Result := gas + confirmGas;
end;

function DataQuotaCost(data: TBytes; quotaTable: PQuotaTable): UInt64;
var
  l: UInt64;
begin
  Result := 0;
  l := Length(data);
  if l > 0 then
  begin
    if High(UInt64) div quotaTable^.TxDataQuota < l then
      raise ErrGasUintOverflow;
    Result := l * quotaTable^.TxDataQuota;
  end;
end;

function RequestQuotaCost(data: TBytes; quotaTable: PQuotaTable): UInt64;
var
  dataCost, totalCost: UInt64;
  overflow: Boolean;
begin
  dataCost := DataQuotaCost(data, quotaTable);
  totalCost := SafeAdd(quotaTable^.TxQuota, dataCost, overflow);
  if overflow then
    raise ErrGasUintOverflow;
  Result := totalCost;
end;

procedure CalcQuotaUsed(useQuota: Boolean; quotaTotal, quotaAddition, quotaLeft: UInt64; err: Exception; out qStakeUsed, qUsed: UInt64);
begin
  if not useQuota then
  begin
    qStakeUsed := 0;
    qUsed := 0;
    Exit;
  end;
  if (err <> nil) and (err.ClassName = ErrOutOfQuota.ClassName) then
  begin
    qStakeUsed := 0;
    qUsed := 0;
    Exit;
  end;
  qUsed := quotaTotal - quotaLeft;
  if qUsed < quotaAddition then
  begin
    qStakeUsed := 0;
    Exit;
  end;
  qStakeUsed := qUsed - quotaAddition;
end;

function IsPoW(block: TAccountBlock): Boolean;
begin
  Result := Length(block.Nonce) > 0;
end;

function QuotaTableByHeight(sbHeight: UInt64): PQuotaTable;
begin
  if IsVersionXUpgrade(sbHeight) then
    Result := @versionXQuotaTable
  else if IsVersion11Upgrade(sbHeight) then
    Result := @version11QuotaTable
  else if IsVersion10Upgrade(sbHeight) then
    Result := @version10QuotaTable
  else if IsDexStableMarketUpgrade(sbHeight) then
    Result := @dexStableMarketQuotaTable
  else if IsDexRobotUpgrade(sbHeight) then
    Result := @dexRobotQuotaTable
  else if IsEarthUpgrade(sbHeight) then
    Result := @earthQuotaTable
  else if IsStemUpgrade(sbHeight) then
    Result := @dexAgentQuotaTable
  else if IsDexUpgrade(sbHeight) then
    Result := @viteQuotaTable
  else
    Result := @initQuotaTable;
end;

initialization
  initQuotaTable := TQuotaTable.Create(
    AddQuota: 3,
    MulQuota: 5,
    // ... (fill in all the values from the Go code)
  );
  // ... (initialize all other quota tables)
end.
