unit VM.Contracts.Dex.Fund.Storage;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Interfaces, GoVite.Ledger, GoVite.VM.Util,
  VM.Contracts.Dex.Proto;

type
  TQuoteTokenTypeInfo = record
    Decimals: Int32;
    DefaultTradeThreshold: TBigInteger;
    DefaultMineThreshold: TBigInteger;
    DefaultMarketOrderAmtThreshold: TBigInteger;
  end;

  TSerializableDex = interface
    ['{B4A7E5F1-7C3B-4E7B-8B7C-6E6A7D8E7F6A}']
    function Serialize: TBytes;
    procedure DeSerialize(const AData: TBytes);
  end;

  TUpdateAccFunc = reference to function(AAccount: TAccount; AAmount: TBigInteger): TAccount;

var
  ownerKey, dexStoppedKey, fundKeyPrefix, minTradeAmountKeyPrefix,
  mineThresholdKeyPrefix, marketOrderAmtThresholdKeyPrefix, dexTimestampKey,
  userFeeKeyPrefix, dexFeesKeyPrefix, lastDexFeesPeriodIdKey,
  operatorFeesKeyPrefix, pendingNewMarketActionsKey, pendingSetQuoteActionsKey,
  pendingTransferTokenOwnerActionsKey, marketIdKey, orderIdSerialNoKey,
  vxUnlocksKeyPrefix, cancelStakesKeyPrefix, timeOracleKey, periodJobTriggerKey,
  vxFundKeyPrefix, vxSumFundsKey, autoLockMinedVxKeyPrefix, vxLockedFundsKeyPrefix,
  vxLockedSumFundsKey, lastJobPeriodIdWithBizTypeKey, normalMineStartedKey,
  firstMinedVxPeriodIdKey, marketInfoKeyPrefix, vipStakingKeyPrefix,
  superVIPStakingKeyPrefix, delegateStakeInfoPrefix, delegateStakeAddressIndexPrefix,
  delegateStakeIndexSerialNoPrefix, miningStakingsKeyPrefix, dexMiningStakingsKey,
  miningStakedAmountKeyPrefix, miningStakedAmountV2KeyPrefix, tokenInfoKeyPrefix,
  vxMinePoolKey, vxBurnAmountKey, codeByInviterKeyPrefix, inviterByCodeKeyPrefix,
  inviterByInviteeKeyPrefix, maintainerKey, makerMiningAdminKey,
  makerMiningPoolByPeriodKey, lastSettledMakerMinedVxPeriodKey,
  lastSettledMakerMinedVxPageKey, viteOwnerInitiated, grantedMarketToAgentKeyPrefix: TBytes;

  commonTokenPow: TBigInteger;
  VxTokenId: TTokenTypeId;
  PreheatMinedAmtPerPeriod, VxMinedAmtFirstPeriod, VxDividendThreshold,
  NewMarketFeeAmount, NewMarketFeeMineAmount, NewMarketFeeDonateAmount,
  NewMarketFeeBurnAmount, NewInviterFeeAmount, NewInviterFeeAmountForVersion10,
  VxLockThreshold: TBigInteger;
  SchedulePeriods: Integer;
  StakeForMiningMinAmount, StakeForVIPAmount, StakeForMiningThreshold,
  StakeForSuperVIPAmount: TBigInteger;
  viteMinAmount, ethMinAmount, bitcoinMinAmount, usdMinAmount,
  viteMineThreshold, ethMineThreshold, bitcoinMineThreshold, usdMineThreshold,
  viteMarketOrderAmtThreshold, ethMarketOrderAmtThreshold,
  bitcoinMarketOrderAmtThreshold, usdMarketOrderAmtThreshold,
  vxMineDust: TBigInteger;
  ViteTokenDecimals: Int32;
  QuoteTokenTypeInfos: TDictionary<Int32, TQuoteTokenTypeInfo>;
  initOwner, initViteTokenOwner: TAddress;
  newOrderMethodId: TBytes;


procedure InitFundOwner(const AOwner: TAddress);
function GetAccountByToken(const AFund: TDexFund; const AToken: TTokenTypeId; out AExists: Boolean): TAccount;
function GetAccounts(const AFund: TDexFund; const ATokenId: TTokenTypeId): TArray<TAccount>;
function GetFund(const ADB: IVmDb; const AAddress: TAddress): TDexFund;
procedure SaveFund(const ADB: IVmDb; const AAddress: TAddress; const AFund: TDexFund);
function ReduceAccount(const ADB: IVmDb; const AAddress: TAddress; const ATokenId: TBytes; const AAmount: TBigInteger): TAccount;
// ... other functions ...
procedure deserializeFromDb(const ADB: IVmDb; const AKey: TBytes; ASerializable: TSerializableDex);
procedure serializeToDb(const ADB: IVmDb; const AKey: TBytes; ASerializable: TSerializableDex);


implementation

// Initialization of variables
initialization
  // ... Initialize all the global variables like ownerKey, VxTokenId, etc.
  ownerKey := TEncoding.UTF8.GetBytes('own:');
  // ... and so on for all byte array constants
  VxTokenId := TTokenTypeId.FromHex('tti_564954455820434f494e69b5');
  commonTokenPow := TBigInteger.Pow(10, 18);
  // ... and so on for all BigInteger constants
  ViteTokenDecimals := 18;
  // ... Initialize QuoteTokenTypeInfos dictionary
finalization
  // Finalize if needed

procedure InitFundOwner(const AOwner: TAddress);
begin
  initOwner := AOwner;
end;

function GetAccountByToken(const AFund: TDexFund; const AToken: TTokenTypeId; out AExists: Boolean): TAccount;
begin
  for var LAccount in AFund.Accounts do
  begin
    if BytesEqual(AToken.Bytes, LAccount.Token) then
    begin
      Result := LAccount;
      AExists := True;
      Exit;
    end;
  end;
  Result := TAccount.Create;
  Result.Token := AToken.Bytes;
  Result.Available := TBigInteger.Zero.ToBytes;
  Result.Locked := TBigInteger.Zero.ToBytes;
  AExists := False;
end;
// ... Implementations for all other functions
function GetAccounts(const AFund: TDexFund; const ATokenId: TTokenTypeId): TArray<TAccount>;
begin
  // Implementation
end;

function GetFund(const ADB: IVmDb; const AAddress: TAddress): TDexFund;
begin
  // Implementation
end;

procedure SaveFund(const ADB: IVmDb; const AAddress: TAddress; const AFund: TDexFund);
begin
  // Implementation
end;

function ReduceAccount(const ADB: IVmDb; const AAddress: TAddress; const ATokenId: TBytes; const AAmount: TBigInteger): TAccount;
begin
  // Implementation
end;


procedure deserializeFromDb(const ADB: IVmDb; const AKey: TBytes; ASerializable: TSerializableDex);
var
  LData: TBytes;
begin
  LData := getValueFromDb(ADB, AKey);
  if Length(LData) > 0 then
    ASerializable.DeSerialize(LData);
end;

procedure serializeToDb(const ADB: IVmDb; const AKey: TBytes; ASerializable: TSerializableDex);
var
  LData: TBytes;
begin
  LData := ASerializable.Serialize;
  setValueToDb(ADB, AKey, LData);
end;

end.
