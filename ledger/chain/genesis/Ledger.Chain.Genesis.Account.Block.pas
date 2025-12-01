unit Ledger.Chain.Genesis.AccountBlock;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Numerics,
  GoToDelphi.Helpers.BigInt,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  VM.DB,
  VM.Contracts.Abi,
  VM.Contracts.Dex,
  VM.Util,
  Common.Config;

type
  TTokenInfoForSort = record
    TokenId: TTokenTypeId;
    TokenInfo: TTokenInfo;
  end;

  TByTokenId = class(TComparer<TTokenInfoForSort>)
  public
    function Compare(const Left, Right: TTokenInfoForSort): Integer; override;
  end;

function NewGenesisAccountBlocks(ParaConfig: TGenesisConfig): TArray<IVmAccountBlock>;
procedure UpdateDexFundOwner(ParaConfig: TGenesisConfig);

implementation

uses
  Common.HexUtil;

procedure DealWithError(ParaError: Exception);
begin
  if ParaError <> nil then
  begin
    raise ParaError;
  end;
end;

function NewGenesisAccountBlocks(ParaConfig: TGenesisConfig): TArray<IVmAccountBlock>;
var
  vList: TList<IVmAccountBlock>;
  vAddrSet: TDictionary<TAddress, Boolean>;
  vI: Integer;
  vVmAccountBlock: IVmAccountBlock;
begin
  vList := TList<IVmAccountBlock>.Create;
  vAddrSet := TDictionary<TAddress, Boolean>.Create;
  try
    // In Go, multiple return values are used. In Delphi, we can pass the list and dictionary as var parameters.
    // However, to keep the function signature similar to the Go version, we will create new functions
    // that return the modified list and dictionary.
    NewGenesisGovernanceContractBlocks(ParaConfig, vList, vAddrSet);
    NewGenesisAssetContractBlocks(ParaConfig, vList, vAddrSet);
    NewGenesisQuotaContractBlocks(ParaConfig, vList, vAddrSet);
    NewGenesisNormalAccountBlocks(ParaConfig, vList, vAddrSet);

    SetLength(Result, vList.Count);
    for vI := 0 to vList.Count - 1 do
    begin
      Result[vI] := vList[vI];
    end;
  finally
    vList.Free;
    vAddrSet.Free;
  end;
end;

procedure UpdateAccountBalanceMap(ParaConfig: TGenesisConfig; ParaAddr: TAddress; ParaVmDb: IVmDb);
var
  vTokenIdStr: string;
  vBalance: TBigInteger;
  vTokenId: TTokenTypeId;
  vError: Exception;
begin
  if ParaConfig.AccountBalanceMap = nil then
  begin
    Exit;
  end;
  if not ParaConfig.AccountBalanceMap.ContainsKey(ParaAddr.ToString) then
  begin
    Exit;
  end;

  for vTokenIdStr in ParaConfig.AccountBalanceMap[ParaAddr.ToString].Keys do
  begin
    vBalance := ParaConfig.AccountBalanceMap[ParaAddr.ToString][vTokenIdStr];
    try
      vTokenId := HexToTokenTypeId(vTokenIdStr);
      vError := nil;
    except
      on E: Exception do
      begin
        vError := E;
      end;
    end;
    DealWithError(vError);
    ParaVmDb.SetBalance(vTokenId, vBalance);
  end;
end;

procedure UpdateDexFundOwner(ParaConfig: TGenesisConfig);
begin
  if (ParaConfig.DexFundInfo <> nil) and (ParaConfig.DexFundInfo.Owner <> nil) then
  begin
    Dex.InitFundOwner(ParaConfig.DexFundInfo.Owner^);
  end;
end;

procedure NewGenesisGovernanceContractBlocks(ParaConfig: TGenesisConfig; ParaList: TList<IVmAccountBlock>; ParaAddrSet: TDictionary<TAddress, Boolean>);
var
  vContractAddr: TAddress;
  vBlock: TAccountBlock;
  vVmDb: IVmDb;
  vGidStr: string;
  vGroupInfo: TConsensusGroupInfo;
  vGid: TGid;
  vError: Exception;
  vRegisterConditionParam: TBytes;
  vValue: TBytes;
  vGroupRegistrationInfoMap: TDictionary<string, TRegistrationInfo>;
  vName: string;
  vRegistrationInfo: TRegistrationInfo;
  vBlockProducingAddrStr: string;
  vBlockProducingAddr: TAddress;
  vVoteAddrStr: string;
  vVoteAddr: TAddress;
  vSbpName: string;
begin
  if ParaConfig.GovernanceInfo <> nil then
  begin
    vContractAddr := AddressGovernance;
    FillChar(vBlock, SizeOf(TAccountBlock), 0);
    vBlock.BlockType := TBlockType.GenesisReceive;
    vBlock.Height := 1;
    vBlock.AccountAddress := vContractAddr;
    vBlock.Amount := TBigInteger.Zero;
    vBlock.Fee := TBigInteger.Zero;

    vVmDb := TGenesisVmDB.Create(@vContractAddr);

    for vGidStr in ParaConfig.GovernanceInfo.ConsensusGroupInfoMap.Keys do
    begin
      vGroupInfo := ParaConfig.GovernanceInfo.ConsensusGroupInfoMap[vGidStr];
      try
        vGid := HexToGid(vGidStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      vRegisterConditionParam := nil;
      if vGroupInfo.RegisterConditionId = 1 then
      begin
        try
          vRegisterConditionParam := ABIGovernance.PackVariable(VariableNameRegisterStakeParam,
            [vGroupInfo.RegisterConditionParam.StakeAmount, vGroupInfo.RegisterConditionParam.StakeToken, vGroupInfo.RegisterConditionParam.StakeHeight]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
      end;

      try
        vValue := ABIGovernance.PackVariable(VariableNameConsensusGroupInfo,
          [vGroupInfo.NodeCount, vGroupInfo.Interval, vGroupInfo.PerCount, vGroupInfo.RandCount, vGroupInfo.RandRank, vGroupInfo.Repeat,
          vGroupInfo.CheckLevel, vGroupInfo.CountingTokenId, vGroupInfo.RegisterConditionId, vRegisterConditionParam,
          vGroupInfo.VoteConditionId, TBytes.Create(), vGroupInfo.Owner, vGroupInfo.StakeAmount, vGroupInfo.ExpirationHeight]);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);
      Util.SetValue(vVmDb, GetConsensusGroupInfoKey(vGid), vValue);
    end;

    for vGidStr in ParaConfig.GovernanceInfo.RegistrationInfoMap.Keys do
    begin
      vGroupRegistrationInfoMap := ParaConfig.GovernanceInfo.RegistrationInfoMap[vGidStr];
      try
        vGid := HexToGid(vGidStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      for vName in vGroupRegistrationInfoMap.Keys do
      begin
        vRegistrationInfo := vGroupRegistrationInfoMap[vName];
        if Length(vRegistrationInfo.HistoryAddressList) = 0 then
        begin
          SetLength(vRegistrationInfo.HistoryAddressList, 1);
          vRegistrationInfo.HistoryAddressList[0] := vRegistrationInfo.BlockProducingAddress^;
        end;

        try
          vValue := ABIGovernance.PackVariable(VariableNameRegistrationInfo,
            [vName, vRegistrationInfo.BlockProducingAddress, vRegistrationInfo.StakeAddress, vRegistrationInfo.Amount,
            vRegistrationInfo.ExpirationHeight, vRegistrationInfo.RewardTime, vRegistrationInfo.RevokeTime, vRegistrationInfo.HistoryAddressList]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        Util.SetValue(vVmDb, GetRegistrationInfoKey(vName, vGid), vValue);

        if (ParaConfig.GovernanceInfo.HisNameMap = nil) or
           (not ParaConfig.GovernanceInfo.HisNameMap.ContainsKey(vGidStr)) or
           (not ParaConfig.GovernanceInfo.HisNameMap[vGidStr].ContainsKey(vRegistrationInfo.BlockProducingAddress.ToString)) then
        begin
          try
            vValue := ABIGovernance.PackVariable(VariableNameRegisteredHisName, [vName]);
            vError := nil;
          except
            on E: Exception do
            begin
              vError := E;
            end;
          end;
          DealWithError(vError);
          Util.SetValue(vVmDb, GetHisNameKey(vRegistrationInfo.BlockProducingAddress^, vGid), vValue);
        end;
      end;
    end;

    for vGidStr in ParaConfig.GovernanceInfo.HisNameMap.Keys do
    begin
      try
        vGid := HexToGid(vGidStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      for vBlockProducingAddrStr in ParaConfig.GovernanceInfo.HisNameMap[vGidStr].Keys do
      begin
        vName := ParaConfig.GovernanceInfo.HisNameMap[vGidStr][vBlockProducingAddrStr];
        try
          vBlockProducingAddr := HexToAddress(vBlockProducingAddrStr);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);

        try
          vValue := ABIGovernance.PackVariable(VariableNameRegisteredHisName, [vName]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        Util.SetValue(vVmDb, GetHisNameKey(vBlockProducingAddr, vGid), vValue);
      end;
    end;

    for vGidStr in ParaConfig.GovernanceInfo.VoteStatusMap.Keys do
    begin
      try
        vGid := HexToGid(vGidStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      for vVoteAddrStr in ParaConfig.GovernanceInfo.VoteStatusMap[vGidStr].Keys do
      begin
        vSbpName := ParaConfig.GovernanceInfo.VoteStatusMap[vGidStr][vVoteAddrStr];
        try
          vVoteAddr := HexToAddress(vVoteAddrStr);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);

        try
          vValue := ABIGovernance.PackVariable(VariableNameVoteInfo, [vSbpName]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        Util.SetValue(vVmDb, GetVoteInfoKey(vVoteAddr, vGid), vValue);
      end;
    end;

    UpdateAccountBalanceMap(ParaConfig, vContractAddr, vVmDb);

    vBlock.Hash := vBlock.ComputeHash;
    ParaList.Add(TVmAccountBlock.Create(@vBlock, vVmDb));
    ParaAddrSet.Add(vContractAddr, True);
  end;
end;

{ TByTokenId }

function TByTokenId.Compare(const Left, Right: TTokenInfoForSort): Integer;
begin
  Result := CompareStr(Left.TokenId.Hex, Right.TokenId.Hex);
  if Result = 0 then
    Result := 0
  else if Result > 0 then
    Result := 1
  else
    Result := -1;
end;

procedure NewGenesisAssetContractBlocks(ParaConfig: TGenesisConfig; ParaList: TList<IVmAccountBlock>; ParaAddrSet: TDictionary<TAddress, Boolean>);
var
  vNextIndexMap: TDictionary<string, Word>;
  vContractAddr: TAddress;
  vBlock: TAccountBlock;
  vVmDb: IVmDb;
  vTokenList: TList<TTokenInfoForSort>;
  vTokenIdStr: string;
  vTokenInfo: TTokenInfo;
  vTokenId: TTokenTypeId;
  vError: Exception;
  vTokenInfoForSort: TTokenInfoForSort;
  vNextIndex: Word;
  vValue: TBytes;
  vNextIndexValue: TBytes;
  vLog: TVmLog;
  vDataBytes: TBytes;
begin
  if ParaConfig.AssetInfo <> nil then
  begin
    vNextIndexMap := TDictionary<string, Word>.Create;
    vTokenList := TList<TTokenInfoForSort>.Create;
    try
      vContractAddr := AddressAsset;
      FillChar(vBlock, SizeOf(TAccountBlock), 0);
      vBlock.BlockType := TBlockType.GenesisReceive;
      vBlock.Height := 1;
      vBlock.AccountAddress := vContractAddr;
      vBlock.Amount := TBigInteger.Zero;
      vBlock.Fee := TBigInteger.Zero;

      vVmDb := TGenesisVmDB.Create(@vContractAddr);

      for vTokenIdStr in ParaConfig.AssetInfo.TokenInfoMap.Keys do
      begin
        vTokenInfo := ParaConfig.AssetInfo.TokenInfoMap[vTokenIdStr];
        try
          vTokenId := HexToTokenTypeId(vTokenIdStr);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        vTokenInfoForSort.TokenId := vTokenId;
        vTokenInfoForSort.TokenInfo := vTokenInfo;
        vTokenList.Add(vTokenInfoForSort);
      end;

      vTokenList.Sort(TByTokenId.Create);

      for vTokenInfoForSort in vTokenList do
      begin
        vNextIndex := 0;
        if vNextIndexMap.ContainsKey(vTokenInfoForSort.TokenInfo.TokenSymbol) then
        begin
          vNextIndex := vNextIndexMap[vTokenInfoForSort.TokenInfo.TokenSymbol];
        end;

        try
          vValue := ABIAsset.PackVariable(VariableNameTokenInfo,
            [vTokenInfoForSort.TokenInfo.TokenName, vTokenInfoForSort.TokenInfo.TokenSymbol, vTokenInfoForSort.TokenInfo.TotalSupply,
            vTokenInfoForSort.TokenInfo.Decimals, vTokenInfoForSort.TokenInfo.Owner, vTokenInfoForSort.TokenInfo.IsReIssuable,
            vTokenInfoForSort.TokenInfo.MaxSupply, vTokenInfoForSort.TokenInfo.IsOwnerBurnOnly, vNextIndex]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);

        vNextIndex := vNextIndex + 1;
        vNextIndexMap.AddOrSetValue(vTokenInfoForSort.TokenInfo.TokenSymbol, vNextIndex);

        try
          vNextIndexValue := ABIAsset.PackVariable(VariableNameTokenIndex, [vNextIndex]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        Util.SetValue(vVmDb, GetNextTokenIndexKey(vTokenInfoForSort.TokenInfo.TokenSymbol), vNextIndexValue);
        Util.SetValue(vVmDb, GetTokenInfoKey(vTokenInfoForSort.TokenId), vValue);
      end;

      if Length(ParaConfig.AssetInfo.LogList) > 0 then
      begin
        for vLog in ParaConfig.AssetInfo.LogList do
        begin
          try
            vDataBytes := DecodeString(vLog.Data);
            vError := nil;
          except
            on E: Exception do
            begin
              vError := E;
            end;
          end;
          DealWithError(vError);
          vVmDb.AddLog(TVmLog.Create(vDataBytes, vLog.Topics));
        end;
      end;

      vBlock.LogHash := vVmDb.GetLogListHash;
      UpdateAccountBalanceMap(ParaConfig, vContractAddr, vVmDb);
      vBlock.Hash := vBlock.ComputeHash;
      ParaList.Add(TVmAccountBlock.Create(@vBlock, vVmDb));
      ParaAddrSet.Add(vContractAddr, True);
    finally
      vNextIndexMap.Free;
      vTokenList.Free;
    end;
  end;
end;

procedure NewGenesisQuotaContractBlocks(ParaConfig: TGenesisConfig; ParaList: TList<IVmAccountBlock>; ParaAddrSet: TDictionary<TAddress, Boolean>);
var
  vContractAddr: TAddress;
  vBlock: TAccountBlock;
  vVmDb: IVmDb;
  vStakeAddrStr: string;
  vStakeInfoList: TArray<TStakeInfo>;
  vStakeAddr: TAddress;
  vError: Exception;
  vI: Integer;
  vStakeInfo: TStakeInfo;
  vValue: TBytes;
  vBeneficiaryStr: string;
  vAmount: TBigInteger;
  vBeneficiary: TAddress;
begin
  if ParaConfig.QuotaInfo <> nil then
  begin
    vContractAddr := AddressQuota;
    FillChar(vBlock, SizeOf(TAccountBlock), 0);
    vBlock.BlockType := TBlockType.GenesisReceive;
    vBlock.Height := 1;
    vBlock.AccountAddress := vContractAddr;
    vBlock.Amount := TBigInteger.Zero;
    vBlock.Fee := TBigInteger.Zero;

    vVmDb := TGenesisVmDB.Create(@vContractAddr);

    for vStakeAddrStr in ParaConfig.QuotaInfo.StakeInfoMap.Keys do
    begin
      vStakeInfoList := ParaConfig.QuotaInfo.StakeInfoMap[vStakeAddrStr];
      try
        vStakeAddr := HexToAddress(vStakeAddrStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      for vI := 0 to High(vStakeInfoList) do
      begin
        vStakeInfo := vStakeInfoList[vI];
        try
          vValue := ABIQuota.PackVariable(VariableNameStakeInfo,
            [vStakeInfo.Amount, vStakeInfo.ExpirationHeight, vStakeInfo.Beneficiary, False, ZERO_ADDRESS, Byte(0)]);
          vError := nil;
        except
          on E: Exception do
          begin
            vError := E;
          end;
        end;
        DealWithError(vError);
        Util.SetValue(vVmDb, GetStakeInfoKey(vStakeAddr, vI), vValue);
      end;
    end;

    for vBeneficiaryStr in ParaConfig.QuotaInfo.StakeBeneficialMap.Keys do
    begin
      vAmount := ParaConfig.QuotaInfo.StakeBeneficialMap[vBeneficiaryStr];
      try
        vBeneficiary := HexToAddress(vBeneficiaryStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);

      try
        vValue := ABIQuota.PackVariable(VariableNameStakeBeneficial, [vAmount]);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);
      Util.SetValue(vVmDb, GetStakeBeneficialKey(vBeneficiary), vValue);
    end;

    UpdateAccountBalanceMap(ParaConfig, vContractAddr, vVmDb);
    vBlock.Hash := vBlock.ComputeHash;
    ParaList.Add(TVmAccountBlock.Create(@vBlock, vVmDb));
    ParaAddrSet.Add(vContractAddr, True);
  end;
end;

procedure NewGenesisNormalAccountBlocks(ParaConfig: TGenesisConfig; ParaList: TList<IVmAccountBlock>; ParaAddrSet: TDictionary<TAddress, Boolean>);
var
  vAddrStr: string;
  vBalanceMap: TDictionary<string, TBigInteger>;
  vAddr: TAddress;
  vError: Exception;
  vBlock: TAccountBlock;
  vVmDb: IVmDb;
  vTokenIdStr: string;
  vBalance: TBigInteger;
  vTokenId: TTokenTypeId;
begin
  for vAddrStr in ParaConfig.AccountBalanceMap.Keys do
  begin
    vBalanceMap := ParaConfig.AccountBalanceMap[vAddrStr];
    try
      vAddr := HexToAddress(vAddrStr);
      vError := nil;
    except
      on E: Exception do
      begin
        vError := E;
      end;
    end;
    DealWithError(vError);

    if ParaAddrSet.ContainsKey(vAddr) then
    begin
      Continue;
    end;

    FillChar(vBlock, SizeOf(TAccountBlock), 0);
    vBlock.BlockType := TBlockType.GenesisReceive;
    vBlock.Height := 1;
    vBlock.AccountAddress := vAddr;
    vBlock.Amount := TBigInteger.Zero;
    vBlock.Fee := TBigInteger.Zero;

    vVmDb := TGenesisVmDB.Create(@vAddr);

    for vTokenIdStr in vBalanceMap.Keys do
    begin
      vBalance := vBalanceMap[vTokenIdStr];
      try
        vTokenId := HexToTokenTypeId(vTokenIdStr);
        vError := nil;
      except
        on E: Exception do
        begin
          vError := E;
        end;
      end;
      DealWithError(vError);
      vVmDb.SetBalance(vTokenId, vBalance);
    end;

    vBlock.Hash := vBlock.ComputeHash;
    ParaList.Add(TVmAccountBlock.Create(@vBlock, vVmDb));
  end;
end;

end.
