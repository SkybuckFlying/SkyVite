unit VM.Contracts.Dex.Fund.Verifier;

interface

uses
  GoVite.Types GoVite.Interfaces GoVite.VM.Util,
  System.SysUtils System.Generics.Collections System.BigInt,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

type
  TFundVerifyItem = record
    TokenId: TTokenTypeId;
    Balance: string;
    Amount: string;
    UserAmount: string;
    FeeAmount: string;
    FeeOccupy: string;
    BalanceMatched: Boolean;
  end;

  TFundVerifyRes = record
    UserCount: Integer;
    BalanceMatched: Boolean;
    VerifyItems: TDictionary<TTokenTypeId, TFundVerifyItem>;
  end;

function VerifyDexFundBalance(const ADB: IVmDb; const AReader: TVMConsensusReader): TFundVerifyRes;

implementation

uses
  GoVite.Ledger,
  VM.Contracts.Dex.Storage, VM.Contracts.Dex.Proto, VM.Contracts.Dex.Utils;

procedure accAccount(ATokenId: TTokenTypeId; AAmount: TBytes; AAccumulateRes: TDictionary<TTokenTypeId, TBigInteger>);
var
  LAcc, LAmount: TBigInteger;
begin
  if not Assigned(AAmount) or (Length(AAmount) = 0) then
    Exit;

  LAmount := TBigInteger.FromBytes(AAmount);
  if LAmount.IsZero then
    Exit;

  if AAccumulateRes.TryGetValue(ATokenId, LAcc) then
  begin
    LAcc := LAcc + LAmount;
    AAccumulateRes[ATokenId] := LAcc;
  end
  else
  begin
    AAccumulateRes.Add(ATokenId, LAmount);
  end;
end;

function accumulateUserAccount(const ADB: IVmDb; AAccumulateRes: TDictionary<TTokenTypeId, TBigInteger>): Integer;
var
  LIterator: IStorageIterator;
  LUserAccountValue: TBytes;
  LUserFund: TDexFund;
  LTokenId: TTokenTypeId;
  LTotal: TBytes;
begin
  Result := 0;
  LIterator := ADB.NewStorageIterator(fundKeyPrefix);
  try
    while LIterator.Next do
    begin
      LUserAccountValue := LIterator.Value;
      if Length(LUserAccountValue) = 0 then
        Continue;

      LUserFund := TDexFund.Create;
      try
        LUserFund.DeSerialize(LUserAccountValue);
        for var LAcc in LUserFund.Accounts do
        begin
          LTokenId := TTokenTypeId.FromBytes(LAcc.Token);
          LTotal := AddBigInt(LAcc.Available, LAcc.Locked);
          if IsEarthFork(ADB) then
          begin
            if LTokenId.Equals(VxTokenId) then
            begin
              var LVxLocked := AddBigInt(LAcc.VxLocked, LAcc.VxUnlocking);
              LTotal := AddBigInt(LTotal, LVxLocked);
            end
            else if LTokenId.Equals(ViteTokenId) and (Length(LAcc.CancellingStake) > 0) then
            begin
              LTotal := AddBigInt(LTotal, LAcc.CancellingStake);
            end;
          end;
          accAccount(LTokenId, LTotal, AAccumulateRes);
        end;
        Inc(Result);
      finally
        LUserFund.Free;
      end;
    end;
  finally
    // LIterator is an interface, automatically managed
  end;
end;

function splitDividendPool(ADividend: TFeeForDividend): TPair<TBigInteger, TBigInteger>;
var
  LToDividendAmt, LRolledAmount: TBigInteger;
begin
  if not ADividend.NotRoll then
  begin
    LToDividendAmt := CalculateAmountForRate(ADividend.DividendPoolAmount, PerPeriodDividendRate);
    LRolledAmount := TBigInteger.FromBytes(ADividend.DividendPoolAmount) - LToDividendAmt;
  end
  else
  begin
    LToDividendAmt := TBigInteger.FromBytes(ADividend.DividendPoolAmount);
    LRolledAmount := TBigInteger.Zero;
  end;
  Result := TPair<TBigInteger, TBigInteger>.Create(LToDividendAmt, LRolledAmount);
end;

procedure accumulateFeeDividendPool(const ADB: IVmDb; const AReader: TVMConsensusReader; AAccumulateRes: TDictionary<TTokenTypeId, TBigInteger>);
var
  LIterator: IStorageIterator;
  LDexFeesBytes, LDexFeesKey: TBytes;
  LDexFeesByPeriod: TDexFeesByPeriod;
  LPeriodId, LCurrentPeriodId: UInt64;
  LTokenId: TTokenTypeId;
  LToDividend: TBigInteger;
begin
  LCurrentPeriodId := GetCurrentPeriodId(ADB, AReader);
  LIterator := ADB.NewStorageIterator(dexFeesKeyPrefix);
  try
    while LIterator.Next do
    begin
      LDexFeesKey := LIterator.Key;
      LDexFeesBytes := LIterator.Value;
      if Length(LDexFeesBytes) = 0 then
        Continue;

      LPeriodId := BytesToUInt64(Copy(LDexFeesKey, Length(dexFeesKeyPrefix) + 1, 8));
      LDexFeesByPeriod := TDexFeesByPeriod.Create;
      try
        LDexFeesByPeriod.DeSerialize(LDexFeesBytes);
        if not LDexFeesByPeriod.FinishDividend then
        begin
          for var LFee in LDexFeesByPeriod.FeesForDividend do
          begin
            LTokenId := TTokenTypeId.FromBytes(LFee.Token);
            if LCurrentPeriodId <> LPeriodId then
            begin
              LToDividend := splitDividendPool(LFee).Key;
              accAccount(LTokenId, LToDividend.ToBytes, AAccumulateRes);
            end
            else
            begin
              accAccount(LTokenId, LFee.DividendPoolAmount, AAccumulateRes);
            end;
          end;
        end;
      finally
        LDexFeesByPeriod.Free;
      end;
    end;
  finally
    // LIterator
  end;
end;

procedure accumulateOperatorFeeAccount(const ADB: IVmDb; AAccumulateRes: TDictionary<TTokenTypeId, TBigInteger>);
var
  LIterator: IStorageIterator;
  LOperatorFeesBytes: TBytes;
  LOperatorFeesByPeriod: TOperatorFeesByPeriod;
  LTokenId: TTokenTypeId;
begin
  LIterator := ADB.NewStorageIterator(operatorFeesKeyPrefix);
  try
    while LIterator.Next do
    begin
      LOperatorFeesBytes := LIterator.Value;
      if Length(LOperatorFeesBytes) = 0 then
        Continue;

      LOperatorFeesByPeriod := TOperatorFeesByPeriod.Create;
      try
        LOperatorFeesByPeriod.DeSerialize(LOperatorFeesBytes);
        for var LFee in LOperatorFeesByPeriod.OperatorFees do
        begin
          LTokenId := TTokenTypeId.FromBytes(LFee.Token);
          for var LMarketFee in LFee.MarketFees do
          begin
            accAccount(LTokenId, LMarketFee.Amount, AAccumulateRes);
          end;
        end;
      finally
        LOperatorFeesByPeriod.Free;
      end;
    end;
  finally
    // LIterator
  end;
end;

procedure accumulateVx(const ADB: IVmDb; var AVxAmount: TBigInteger);
var
  LIterator: IStorageIterator;
  LAmtBytes: TBytes;
  LAmt: TBigInteger;
begin
  AVxAmount := AVxAmount + GetVxMinePool(ADB);
  LIterator := ADB.NewStorageIterator(makerMiningPoolByPeriodKey);
  try
    while LIterator.Next do
    begin
      LAmtBytes := LIterator.Value;
      if Length(LAmtBytes) = 0 then
        Continue;

      LAmt := TBigInteger.FromBytes(LAmtBytes);
      AVxAmount := AVxAmount + LAmt;
    end;
  finally
    // LIterator
  end;
end;

function VerifyDexFundBalance(const ADB: IVmDb; const AReader: TVMConsensusReader): TFundVerifyRes;
var
  LUserAmountMap, LFeeAmountMap: TDictionary<TTokenTypeId, TBigInteger>;
  LVxAmount: TBigInteger;
  LAllBalanceMatched, LFoundVx, LBalanceMatched: Boolean;
  LBalance, LAmount, LUserAmount, LFeeAmount: TBigInteger;
  LFeeOccupy: string;
begin
  LUserAmountMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  LFeeAmountMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  LVxAmount := TBigInteger.Zero;
  Result.VerifyItems := TDictionary<TTokenTypeId, TFundVerifyItem>.Create;

  try
    Result.UserCount := accumulateUserAccount(ADB, LUserAmountMap);
    LAllBalanceMatched := True;
    accumulateFeeDividendPool(ADB, AReader, LFeeAmountMap);
    accumulateOperatorFeeAccount(ADB, LFeeAmountMap);
    accumulateVx(LVxAmount);

    LFoundVx := False;

    for var LPair in LUserAmountMap do
    begin
      var LTokenId := LPair.Key;
      LUserAmount := LPair.Value;

      if LFeeAmountMap.TryGetValue(LTokenId, LFeeAmount) then
      begin
        LAmount := LUserAmount + LFeeAmount;
        if LAmount.IsZero then
          LFeeOccupy := '0'
        else
          // Using floating point for display purposes. Precision issues are not critical here.
          LFeeOccupy := Format('%f', [StrToFloat(LFeeAmount.ToString) / StrToFloat(LAmount.ToString)]);
      end
      else
      begin
        LAmount := LUserAmount;
        LFeeAmount := TBigInteger.Zero;
        LFeeOccupy := '0';
      end;

      if LTokenId.Equals(VxTokenId) then
      begin
        LFoundVx := True;
        LAmount := LAmount + LVxAmount;
      end;

      LBalance := ADB.GetBalance(LTokenId);
      LBalanceMatched := LAmount.CompareTo(LBalance) = 0;
      if not LBalanceMatched then
        LAllBalanceMatched := False;

      var LItem: TFundVerifyItem;
      LItem.TokenId := LTokenId;
      LItem.Balance := LBalance.ToString;
      LItem.Amount := LAmount.ToString;
      LItem.UserAmount := LUserAmount.ToString;
      LItem.FeeAmount := LFeeAmount.ToString;
      LItem.FeeOccupy := LFeeOccupy;
      LItem.BalanceMatched := LBalanceMatched;
      Result.VerifyItems.Add(LTokenId, LItem);
    end;

    if (not LFoundVx) and (LVxAmount.Sign > 0) then
    begin
      LBalance := ADB.GetBalance(VxTokenId);
      LBalanceMatched := LVxAmount.CompareTo(LBalance) = 0;
      if not LBalanceMatched then
        LAllBalanceMatched := False;

      var LItem: TFundVerifyItem;
      LItem.TokenId := VxTokenId;
      LItem.Balance := LBalance.ToString;
      LItem.Amount := LVxAmount.ToString;
      LItem.UserAmount := '0';
      LItem.FeeAmount := '0';
      LItem.FeeOccupy := '0';
      LItem.BalanceMatched := LBalanceMatched;
      Result.VerifyItems.Add(VxTokenId, LItem);
    end;

    Result.BalanceMatched := LAllBalanceMatched;

  finally
    LUserAmountMap.Free;
    LFeeAmountMap.Free;
  end;
end;

end.
