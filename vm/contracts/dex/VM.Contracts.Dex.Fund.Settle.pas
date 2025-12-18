unit VM.Contracts.Dex.Fund.Settle;

interface

uses
  System.BigInt, System.SysUtils, System.Generics.Collections,
  GoVite.Types, GoVite.Interfaces, GoVite.Log15, GoVite.VM.Util,
  VM.Contracts.Dex.Proto;

function DoSettleFund(const ADB: IVmDb; const AReader: TConsensusReader; AAction: TFundSettle; AMarketInfo: TMarketInfo; AFundLogger: ILogger): TErro;
procedure SettleFees(const ADB: IVmDb; const AReader: TConsensusReader; AAllowMining: Boolean; AFeeToken: TBytes; AFeeTokenDecimals, AQuoteTokenType: Int32; AFeeActions: TArray<TFeeSettle>; AFeeForDividend: TBigInteger; AInviteRelations: TDictionary<TAddress, TAddress>);
procedure SettleFeesWithTokenId(const ADB: IVmDb; const AReader: TConsensusReader; AAllowMining: Boolean; ATokenId: TTokenTypeId; AFeeTokenDecimals, AQuoteTokenType: Int32; AFeeActions: TArray<TFeeSettle>; AFeeForDividend: TBigInteger; AInviteRelations: TDictionary<TAddress, TAddress>);
procedure SettleOperatorFees(const ADB: IVmDb; const AReader: TConsensusReader; AFeeActions: TArray<TFeeSettle>; AMarketInfo: TMarketInfo);
function OnDepositVx(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; ADepositAmount: TBigInteger; AUpdatedVxAccount: TAccount): TError;
function OnWithdrawVx(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AWithdrawAmount: TBigInteger; AUpdatedVxAccount: TAccount): TError;
function OnSettleVx(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TBytes; AFundSettle: TAccountSettle; AUpdatedVxAccount: TAccount): TError;
function OnVxMined(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AAmount: TBigInteger): TError;
function DoSettleVxFunds(const ADB: IVmDb; const AReader: TConsensusReader; AAddressBytes: TBytes; AAmountChange: TBigInteger; AUpdatedVxAccount: TAccount): TError;

implementation

uses
  VM.Contracts.ABI, VM.Contracts.Dex.Storage;

function DoSettleFund(const ADB: IVmDb; const AReader: TConsensusReader; AAction: TFundSettle; AMarketInfo: TMarketInfo; AFundLogger: ILogger): TError;
var
  LAddress: TAddress;
  LDexFund: TDexFund;
  LToken: TBytes;
  LTokenId: TTokenTypeId;
  LAccount: TAccount;
  LExists: Boolean;
  LExceed: Boolean;
  LActualSub: TBytes;
begin
  Result := nil;
  LAddress := TAddress.FromBytes(AAction.Address);
  LDexFund := GetFund(ADB, LAddress);

  for var LAccountSettle in AAction.AccountSettles do
  begin
    if LAccountSettle.IsTradeToken then
      LToken := AMarketInfo.TradeToken
    else
      LToken := AMarketInfo.QuoteToken;

    try
      LTokenId := TTokenTypeId.FromBytes(LToken);
    except
      on E: Exception do
        Exit(E);
    end;
    if not Assigned(GetTokenInfo(ADB, LTokenId)) then
      raise Exception.Create(InvalidTokenErr);

    LAccount := GetAccountByToken(LDexFund, LTokenId, LExists);
    if CmpToBigZero(LAccountSettle.ReduceLocked) <> 0 then
    begin
      LAccount.Locked := SafeSubBigInt(LAccount.Locked, LAccountSettle.ReduceLocked, LExceed);
      if LExceed then
        if IsDexFeeFork(ADB) then
          AFundLogger.Error(MethodNameDexFundSettleOrdersV2 + ' DoSettleFund exceed for reduceLocked', ['locked', TBigInteger.FromBytes(LAccount.Locked).ToString, 'reduceLocked', TBigInteger.FromBytes(LAccountSettle.ReduceLocked).ToString])
        else
          raise Exception.Create(ExceedFundLockedErr);
    end;

    if CmpToBigZero(LAccountSettle.ReleaseLocked) <> 0 then
    begin
      LAccount.Locked := SafeSubBigInt(LAccount.Locked, LAccountSettle.ReleaseLocked, LActualSub, LExceed);
      if LExceed then
        if IsDexFeeFork(ADB) then
          AFundLogger.Error(MethodNameDexFundSettleOrdersV2 + ' DoSettleFund exceed for releaseLocked', ['locked', TBigInteger.FromBytes(LAccount.Locked).ToString, 'releaseLocked', TBigInteger.FromBytes(LAccountSettle.ReleaseLocked).ToString])
        else
          raise Exception.Create(ExceedFundLockedErr);
      LAccount.Available := AddBigInt(LAccount.Available, LActualSub);
    end;

    if CmpToBigZero(LAccountSettle.IncAvailable) <> 0 then
      LAccount.Available := AddBigInt(LAccount.Available, LAccountSettle.IncAvailable);

    if not LExists then
      LDexFund.Accounts.Add(LAccount);

    if BytesEqual(LToken, VxTokenId.Bytes) then
    begin
      Result := OnSettleVx(ADB, AReader, AAction.Address, LAccountSettle, LAccount);
      if Result <> nil then
        Exit;
    end;
  end;
  SaveFund(ADB, LAddress, LDexFund);
end;
// ... rest of the implementation would follow ...

end.
