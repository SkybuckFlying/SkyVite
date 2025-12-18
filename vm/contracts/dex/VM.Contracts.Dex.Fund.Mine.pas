unit VM.Contracts.Dex.Fund.Mine;

interface

uses
  System.BigInt GoVite.Types GoVite.Interfaces GoVite.Log15 GoVite.VM.Util,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

function DoMineVxForFee(const ADB: IVmDb; const AReader: TConsensusReader; APeriodId: UInt64; AAmtsForMarkets: TDictionary<Int32, TBigInteger>; AFundLogger: ILogger): TBigInteger;
function DoMineVxForStaking(const ADB: IVmDb; const AReader: TConsensusReader; APeriodId: UInt64; AAmountToMine: TBigInteger): TBigInteger;
procedure DoMineVxForMakerMineAndMaintainer(const ADB: IVmDb; APeriodId: UInt64; const AReader: TConsensusReader; AAmts: TDictionary<Int32, TBigInteger>);
function BurnExtraVx(const ADB: IVmDb): TArray<TAccountBlock>;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  GoVite.Ledger, VM.Contracts.ABI, VM.Contracts.Dex.Proto, VM.Contracts.Dex.Storage;

function DoMineVxForFee(const ADB: IVmDb; const AReader: TConsensusReader; APeriodId: UInt64; AAmtsForMarkets: TDictionary<Int32, TBigInteger>; AFundLogger: ILogger): TBigInteger;
var
  DexFeesByPeriod: TDexFeesByPeriod;
  FeeSumMap, DividedFeeMap, ToDivideVxLeaveAmtMap, MineThresholdMap: TDictionary<Int32, TBigInteger>;
  Iterator: IStorageIterator;
  UserFeesKey, UserFeesBytes: TBytes;
  AddressBytes: TBytes;
  Address: TAddress;
  UserFees: TUserFees;
  Truncated: Boolean;
  VXMinedForBase, VXMinedForInvite, MinedAmt: TBigInteger;
  Finished, FinishedForInvite: Boolean;
  VXDividend, VXDividendForInvite: TBigInteger;
begin
  if (AAmtsForMarkets = nil) or (AAmtsForMarkets.Count = 0) then
    Exit(nil);

  DexFeesByPeriod := GetDexFeesByPeriodId(ADB, APeriodId);
  if not Assigned(DexFeesByPeriod) then
    Exit(AccumulateAmountFromMap(AAmtsForMarkets));

  FeeSumMap := TDictionary<Int32, TBigInteger>.Create;
  DividedFeeMap := TDictionary<Int32, TBigInteger>.Create;
  ToDivideVxLeaveAmtMap := TDictionary<Int32, TBigInteger>.Create;
  MineThresholdMap := TDictionary<Int32, TBigInteger>.Create;

  try
    for var FeeForMine in DexFeesByPeriod.FeesForMine do
    begin
      FeeSumMap.Add(FeeForMine.QuoteTokenType, TBigInteger.FromBytes(AddBigInt(FeeForMine.BaseAmount, FeeForMine.InviteBonusAmount)));
      DividedFeeMap.Add(FeeForMine.QuoteTokenType, TBigInteger.Zero);
    end;

    for var I := TViteTokenType to TUsdTokenType do
    begin
      MineThresholdMap.Add(I, GetMineThreshold(ADB, I));
      ToDivideVxLeaveAmtMap.Add(I, AAmtsForMarkets[I].Copy);
    end;

    MarkDexFeesFinishMine(ADB, DexFeesByPeriod, APeriodId);

    Iterator := ADB.NewStorageIterator(userFeeKeyPrefix);
    try
      while Iterator.Next do
      begin
        UserFeesKey := Iterator.Key;
        UserFeesBytes := Iterator.Value;
        if Length(UserFeesBytes) = 0 then Continue;

        AddressBytes := Copy(UserFeesKey, Length(userFeeKeyPrefix) + 1, Length(UserFeesKey) - Length(userFeeKeyPrefix));
        Address := TAddress.FromBytes(AddressBytes);
        UserFees := TUserFees.Create;
        try
          UserFees.DeSerialize(UserFeesBytes);
          Truncated := TruncateUserFeesToPeriod(UserFees, APeriodId);

          if Truncated then
          begin
            if Length(UserFees.Fees) = 0 then
            begin
              DeleteUserFees(ADB, AddressBytes);
              Continue;
            end
            else if UserFees.Fees[0].Period <> APeriodId then
            begin
              SaveUserFees(ADB, AddressBytes, UserFees);
              Continue;
            end;
          end;

          if UserFees.Fees[0].Period <> APeriodId then Continue;

          if Length(UserFees.Fees[0].Fees) > 0 then
          begin
            VXMinedForBase := TBigInteger.Zero;
            VXMinedForInvite := TBigInteger.Zero;
            for var FeeAccount in UserFees.Fees[0].Fees do
            begin
              if not IsValidFeeForMine(FeeAccount, MineThresholdMap[FeeAccount.QuoteTokenType]) then Continue;

              if not FeeSumMap.ContainsKey(FeeAccount.QuoteTokenType) then
              begin
                AFundLogger.Error('DoMineVxForFee encountered error: user with valid feeAccount, but no valid feeSum', ['periodId', APeriodId, 'address', Address.ToString]);
                Continue;
              end;

              var FeeSumAmt := FeeSumMap[FeeAccount.QuoteTokenType];
              if Length(FeeAccount.BaseAmount) > 0 then
              begin
                DivideByProportion(FeeSumAmt, TBigInteger.FromBytes(FeeAccount.BaseAmount), DividedFeeMap[FeeAccount.QuoteTokenType], AAmtsForMarkets[FeeAccount.QuoteTokenType], ToDivideVxLeaveAmtMap[FeeAccount.QuoteTokenType], VXDividend, Finished);
                VXMinedForBase := VXMinedForBase + VXDividend;
                AddMinedVxForTradeFeeEvent(ADB, Address, FeeAccount.QuoteTokenType, FeeAccount.BaseAmount, VXDividend);
              end;

              if Finished then
                FeeSumMap.Remove(FeeAccount.QuoteTokenType)
              else
              begin
                if Length(FeeAccount.InviteBonusAmount) > 0 then
                begin
                  DivideByProportion(FeeSumAmt, TBigInteger.FromBytes(FeeAccount.InviteBonusAmount), DividedFeeMap[FeeAccount.QuoteTokenType], AAmtsForMarkets[FeeAccount.QuoteTokenType], ToDivideVxLeaveAmtMap[FeeAccount.QuoteTokenType], VXDividendForInvite, FinishedForInvite);
                  VXMinedForInvite := VXMinedForInvite + VXDividendForInvite;
                  AddMinedVxForInviteeFeeEvent(ADB, Address, FeeAccount.QuoteTokenType, FeeAccount.InviteBonusAmount, VXDividendForInvite);
                  if FinishedForInvite then
                    FeeSumMap.Remove(FeeAccount.QuoteTokenType);
                end;
              end;
            end;

            MinedAmt := VXMinedForBase + VXMinedForInvite;
            if MinedAmt.Sign > 0 then
            begin
              if not OnVxMined(ADB, AReader, Address, MinedAmt) then
                Exit(nil); // Error occurred in OnVxMined
            end;
          end;

          if Length(UserFees.Fees) = 1 then
            DeleteUserFees(ADB, AddressBytes)
          else
          begin
            System.Delete(UserFees.Fees, 0, 1);
            SaveUserFees(ADB, AddressBytes, UserFees);
          end;
        finally
          UserFees.Free;
        end;
      end;
    finally
      // Iterator is managed by ARC
    end;

    Result := AccumulateAmountFromMap(ToDivideVxLeaveAmtMap);
  finally
    FeeSumMap.Free;
    DividedFeeMap.Free;
    ToDivideVxLeaveAmtMap.Free;
    MineThresholdMap.Free;
  end;
end;

// ... (Implementations for DoMineVxForStaking, DoMineVxForMakerMineAndMaintainer, BurnExtraVx etc. would follow) ...

end.
