unit Vm.Contracts.Dex.DexFundDividend;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Common.Types.Address, Common.Types.Hash, Common.Types.TokenTypeId, Common.Helper,
  Interfaces.VmDb, Interfaces.Core.AccountBlock, Interfaces.Core.ContractMeta,
  Vm.Abi.Abi, Vm.Contracts.Abi.AbiDexFund, Vm.Contracts.Contracts, Vm.Util.Util,
  Vm.Contracts.Dex.DexErrors, Vm.Contracts.Dex.DexAccount, Vm.Contracts.Dex.DexCalculator,
  Vm.Contracts.Dex.Proto.DexProto, Vm.Contracts.Dex.DexFundStorage, Vm.Contracts.Dex.DexEvents;

function DoFeesDividend(Db: IVmDb; PeriodId: UInt64): TArray<TAccountBlock>;
function DoOperatorFeesDividend(Db: IVmDb; PeriodId: UInt64): Exception;
function DivideByProportion(TotalReferAmt, PartReferAmt, DividedReferAmt, ToDivideTotalAmt, ToDivideLeaveAmt: TBigInteger): TPair<TBigInteger, Boolean>;

implementation

uses
  System.Math;

function DoFeesDividend(Db: IVmDb; PeriodId: UInt64): TArray<TAccountBlock>;
var
  DexFeesByPeriodMap: TDictionary<UInt64, TDexFeesByPeriod>;
  VxSumFunds: TVxFunds;
  Ok: Boolean;
  FoundVxSumFunds, NeedUpdateVxSum: Boolean;
  VxSumAmtBytes: TBytes;
  FeeSumMap: TDictionary<TTokenTypeId, TBigInteger>;
  PId: UInt64;
  Fee: TDexFeesByPeriod;
  FeeAccount: TDexProtoFeeAccount;
  TokenId: TTokenTypeId;
  ToDividendAmt: TBigInteger;
  Amt: TBigInteger;
  Blocks: TArray<TAccountBlock>;
  UserVxFundKeyPrefix: TBytes;
  Iterator: IStorageIterator;
  UserVxFundsKey, UserVxFundsBytes: TBytes;
  AddressBytes: TBytes;
  Address: TAddress;
  UserVxFunds: TVxFunds;
  UserFeeDividend: TDictionary<TTokenTypeId, TBigInteger>;
  UserVxAmtBytes: TBytes;
  NeedDeleteVxFunds: Boolean;
  UserVxAmount: TBigInteger;
  Finished: Boolean;
  FeeSumWtTk: TAmountWithToken;
  FeeSumLeavedMap: TDictionary<TTokenTypeId, TBigInteger>;
  DividedVxAmtMap: TDictionary<TTokenTypeId, TBigInteger>;
begin
  DexFeesByPeriodMap := GetNotFinishDividendDexFeesByPeriodMap(Db, PeriodId);
  if DexFeesByPeriodMap.Count = 0 then
  begin
    Result := nil;
    Exit;
  end;

  VxSumFunds := GetVxSumFundsWithForkCheck(Db);
  Ok := VxSumFunds.VxFunds.Count > 0;
  if not Ok then
  begin
    Result := nil;
    Exit;
  end;

  FoundVxSumFunds := MatchVxFundsByPeriod(VxSumFunds, PeriodId, False).Item1;
  VxSumAmtBytes := MatchVxFundsByPeriod(VxSumFunds, PeriodId, False).Item2;
  NeedUpdateVxSum := MatchVxFundsByPeriod(VxSumFunds, PeriodId, False).Item3;

  if not FoundVxSumFunds then
  begin
    Result := nil;
    Exit;
  end;

  if NeedUpdateVxSum then
    SaveVxSumFundsWithForkCheck(Db, VxSumFunds);

  if TBigInteger.FromByteArray(VxSumAmtBytes).Sign <= 0 then
  begin
    Result := nil;
    Exit;
  end;

  FeeSumMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  for PId in DexFeesByPeriodMap.Keys do
  begin
    Fee := DexFeesByPeriodMap[PId];
    for FeeAccount in Fee.FeesForDividend do
    begin
      TokenId := BytesToTokenTypeId(FeeAccount.Token);
      ToDividendAmt := SplitDividendPool(FeeAccount).Item1;
      if FeeSumMap.TryGetValue(TokenId, Amt) then
        FeeSumMap.Add(TokenId, TBigInteger.Add(Amt, ToDividendAmt))
      else
        FeeSumMap.Add(TokenId, ToDividendAmt);
    end;
    MarkDexFeesFinishDividend(Db, Fee, PId);
  end;

  Blocks := TryBurnVite(Db, FeeSumMap);

  if IsEarthFork(Db) then
    UserVxFundKeyPrefix := VxLockedFundsKeyPrefix
  else
    UserVxFundKeyPrefix := VxFundKeyPrefix;

  Iterator := Db.NewStorageIterator(UserVxFundKeyPrefix);
  try
    FeeSumLeavedMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
    DividedVxAmtMap := TDictionary<TTokenTypeId, TBigInteger>.Create;

    while True do
    begin
      if FeeSumMap.Count = 0 then
        Break;

      if not Iterator.Next then
      begin
        if Iterator.GetError <> nil then
          raise Iterator.GetError;
        Break;
      end;

      UserVxFundsKey := Iterator.Key;
      UserVxFundsBytes := Iterator.Value;
      if Length(UserVxFundsBytes) = 0 then
        Continue;

      AddressBytes := Copy(UserVxFundsKey, Length(UserVxFundKeyPrefix), Length(UserVxFundsKey) - Length(UserVxFundKeyPrefix));
      Address := BytesToAddress(AddressBytes);
      UserVxFunds := TVxFunds.Create;
      UserVxFunds.Deserialize(UserVxFundsBytes);

      FoundVxSumFunds := MatchVxFundsByPeriod(UserVxFunds, PeriodId, True).Item1;
      UserVxAmtBytes := MatchVxFundsByPeriod(UserVxFunds, PeriodId, True).Item2;
      NeedUpdateVxSum := MatchVxFundsByPeriod(UserVxFunds, PeriodId, True).Item3;
      NeedDeleteVxFunds := MatchVxFundsByPeriod(UserVxFunds, PeriodId, True).Item4;

      if not FoundVxSumFunds then
        Continue;

      if NeedDeleteVxFunds then
        DeleteVxFundsWithForkCheck(Db, Address.Bytes)
      else if NeedUpdateVxSum then
        SaveVxFundsWithForkCheck(Db, Address.Bytes, UserVxFunds);

      UserVxAmount := TBigInteger.FromByteArray(UserVxAmtBytes);
      if not IsValidVxAmountForDividend(UserVxAmount) then
        Continue;

      UserFeeDividend := TDictionary<TTokenTypeId, TBigInteger>.Create;
      for FeeSumWtTk in MapToAmountWithTokens(FeeSumMap) do
      begin
        if FeeSumWtTk.Deleted then
          Continue;

        if not FeeSumLeavedMap.ContainsKey(FeeSumWtTk.Token) then
        begin
          FeeSumLeavedMap.Add(FeeSumWtTk.Token, TBigInteger.Create(FeeSumWtTk.Amount));
          DividedVxAmtMap.Add(FeeSumWtTk.Token, TBigInteger.Create(0));
        end;

        UserFeeDividend.Add(FeeSumWtTk.Token, DivideByProportion(TBigInteger.FromByteArray(VxSumAmtBytes), UserVxAmount, DividedVxAmtMap[FeeSumWtTk.Token], FeeSumWtTk.Amount, FeeSumLeavedMap[FeeSumWtTk.Token]).Item1);
        Finished := DivideByProportion(TBigInteger.FromByteArray(VxSumAmtBytes), UserVxAmount, DividedVxAmtMap[FeeSumWtTk.Token], FeeSumWtTk.Amount, FeeSumLeavedMap[FeeSumWtTk.Token]).Item2;

        if Finished then
        begin
          FeeSumWtTk.Deleted := True;
          FeeSumMap.Remove(FeeSumWtTk.Token);
        end;
        AddFeeDividendEvent(Db, Address, FeeSumWtTk.Token, UserVxAmount, UserFeeDividend[FeeSumWtTk.Token]);
      end;
      if BatchUpdateFund(Db, Address, UserFeeDividend) <> nil then
        raise Exception.Create('BatchUpdateFund failed');
    end;
  finally
    Iterator.Release;
  end;
  Result := Blocks;
end;

function DoOperatorFeesDividend(Db: IVmDb; PeriodId: UInt64): Exception;
var
  Iterator: IStorageIterator;
  OperatorFeesKey, OperatorFeesBytes: TBytes;
  OperatorFeesByPeriod: TDexOperatorFeesByPeriod;
  Addr: TAddress;
  UserFund: TDictionary<TTokenTypeId, TBigInteger>;
  FeeAcc: TDexProtoFeeAccount;
  TokenId: TTokenTypeId;
  MkFee: TDexProtoMarketFee;
  Fd: TBigInteger;
begin
  Iterator := Db.NewStorageIterator(OperatorFeesKeyPrefix + UInt64ToBytes(PeriodId));
  try
    while Iterator.Next do
    begin
      OperatorFeesKey := Iterator.Key;
      OperatorFeesBytes := Iterator.Value;
      if Length(OperatorFeesBytes) = 0 then
        Continue;

      if Length(OperatorFeesKey) <> 32 then
        raise Exception.Create('invalid opearator fees key type');

      DeleteOperatorFeesByKey(Db, OperatorFeesKey);
      OperatorFeesByPeriod := TDexOperatorFeesByPeriod.Create;
      OperatorFeesByPeriod.Deserialize(OperatorFeesBytes);

      Addr := BytesToAddress(Copy(OperatorFeesKey, 11, Length(OperatorFeesKey) - 11));

      UserFund := TDictionary<TTokenTypeId, TBigInteger>.Create;
      for FeeAcc in OperatorFeesByPeriod.OperatorFees do
      begin
        TokenId := BytesToTokenTypeId(FeeAcc.Token);
        for MkFee in FeeAcc.MarketFees do
        begin
          if UserFund.TryGetValue(TokenId, Fd) then
            UserFund.Add(TokenId, TBigInteger.Add(Fd, TBigInteger.FromByteArray(MkFee.Amount)))
          else
            UserFund.Add(TokenId, TBigInteger.FromByteArray(MkFee.Amount));
          AddOperatorFeeDividendEvent(Db, Addr, MkFee);
        end;
      end;
      BatchUpdateFund(Db, Addr, UserFund);
    end;
  finally
    Iterator.Release;
  end;
  Result := nil;
end;

function DivideByProportion(TotalReferAmt, PartReferAmt, DividedReferAmt, ToDivideTotalAmt, ToDivideLeaveAmt: TBigInteger): TPair<TBigInteger, Boolean>;
var
  Proportion: TBigFloat;
  ProportionAmt: TBigInteger;
  ToDivideLeaveNewAmt: TBigInteger;
  Finished: Boolean;
begin
  DividedReferAmt := TBigInteger.Add(DividedReferAmt, PartReferAmt);
  Proportion := TBigFloat.Create(BigFloatPrec).Divide(TBigFloat.Create(BigFloatPrec).SetInt(PartReferAmt), TBigFloat.Create(BigFloatPrec).SetInt(TotalReferAmt));
  ProportionAmt := RoundAmount(TBigFloat.Create(BigFloatPrec).Multiply(TBigFloat.Create(BigFloatPrec).SetInt(ToDivideTotalAmt), Proportion));
  ToDivideLeaveNewAmt := TBigInteger.Subtract(ToDivideLeaveAmt, ProportionAmt);

  if (ToDivideLeaveNewAmt.Sign <= 0) or (DividedReferAmt.Compare(TotalReferAmt) >= 0) then
  begin
    ProportionAmt := ToDivideLeaveAmt;
    Finished := True;
    ToDivideLeaveAmt := TBigInteger.Create(0);
  end
  else
  begin
    ToDivideLeaveAmt := ToDivideLeaveNewAmt;
    Finished := False;
  end;
  Result := TPair<TBigInteger, Boolean>.Create(ProportionAmt, Finished);
end;

function TryBurnVite(Db: IVmDb; FeeSumMap: TDictionary<TTokenTypeId, TBigInteger>): TArray<TAccountBlock>;
var
  Token: TTokenTypeId;
  Amt: TBigInteger;
  BurnData: TBytes;
  BurnBlock: TAccountBlock;
begin
  if IsEarthFork(Db) then
  begin
    for Token in FeeSumMap.Keys do
    begin
      Amt := FeeSumMap[Token];
      if Token.Compare(ViteTokenId) = 0 then
      begin
        if Amt.Sign = 0 then
        begin
          Result := nil;
          Exit;
        end;
        FeeSumMap.Remove(Token);
        BurnData := ABIDataAsset.PackMethod(MethodNameBurn, []);
        BurnBlock.AccountAddress := AddressDexFund;
        BurnBlock.ToAddress := AddressAsset;
        BurnBlock.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
        BurnBlock.TokenId := ViteTokenId;
        BurnBlock.Amount := Amt;
        BurnBlock.Data := BurnData;
        AddBurnViteEvent(Db, BurnForDexViteFee, Amt);
        Result := [BurnBlock];
        Exit;
      end;
    end;
  end;
  Result := nil;
end;

initialization
  FundLogger := TLogger.Create;

end.
