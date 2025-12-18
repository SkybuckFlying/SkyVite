unit Ledger.Chain.BuiltinContract;

interface

uses
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  Ledger.Consensus.Core,
  System.SysUtils System.Generics.Collections Math.BigInt,
  VM.Contracts.Abi,
  VM.Contracts.Dex,
  VM.Quota,
  VM_DB;

type
  TChainBuiltinContractHelper = class helper for TChain
  public
    function GetRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IRegistration>;
    function GetAllRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IRegistration>;
    function GetConsensusGroup(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): IConsensusGroupInfo;
    function GetConsensusGroupList(const ParaSnapshotHash: THash; out ParaError: Exception): TArray<IConsensusGroupInfo>;
    function GetVoteList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IVoteInfo>;
    function GetStakeBeneficialAmount(const ParaAddr: TAddress; out ParaError: Exception): TBigInt;
    function GetStakeQuota(const ParaAddr: TAddress; out ParaAmount: TBigInt; out ParaError: Exception): IQuota;
    function GetStakeQuotas(const ParaAddrList: TArray<TAddress>; out ParaError: Exception): TDictionary<TAddress, IQuota>;
    function GetTokenInfoById(const ParaTokenId: TTokenTypeId; out ParaError: Exception): ITokenInfo;
    function GetAllTokenInfo(out ParaError: Exception): TDictionary<TTokenTypeId, ITokenInfo>;
    function CalVoteDetails(const ParaGid: TGid; const ParaInfo: IGroupInfo; const ParaSnapshotBlock: THashHeight; out ParaError: Exception): TArray<IVoteDetails>;
    function GetStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: TUInt64; out ParaNextKey: TBytes; out ParaError: Exception): TArray<IStakeInfo>;
    function GetDexFundsByPage(const ParaSnapshotHash: THash; const ParaLastAddress: TAddress; ParaCount: Integer; out ParaError: Exception): TArray<IDexFund>;
    function GetDexStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<IDelegateStakeInfo>;
    function GetDexFundByAddress(const ParaSnapshotHash: THash; const ParaAddress: TAddress; out ParaError: Exception): IDexFund;
    function GetDexFundStakeForMiningV1ListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<TAddress>;
    function GetDexFundStakeForMiningV2ListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<TAddress>;
  private
    function GenVoteDetails(const ParaSnapshotHash: THash; const ParaRegistration: IRegistration; const ParaInfos: TArray<IVoteInfo>; const ParaId: TTokenTypeId): IVoteDetails;
  end;

implementation

{ TChainBuiltinContractHelper }

function TChainBuiltinContractHelper.GetRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IRegistration>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressGovernance, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetCandidateList(vSd, ParaGid, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error(Format('c.stateDB.NewStorageDatabase failed, snapshotHash is %s', [ParaSnapshotHash.ToString]), 'method', 'GetRegisterList');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetAllRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IRegistration>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressGovernance, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetAllRegistrationList(vSd, ParaGid, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error(Format('c.stateDB.NewStorageDatabase failed, snapshotHash is %s', [ParaSnapshotHash.ToString]), 'method', 'GetAllRegisterList');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetConsensusGroup(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): IConsensusGroupInfo;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressGovernance, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetConsensusGroup(vSd, ParaGid, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error(Format('c.stateDB.NewStorageDatabase failed, snapshotHash is %s', [ParaSnapshotHash.ToString]), 'method', 'GetConsensusGroup');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetConsensusGroupList(const ParaSnapshotHash: THash; out ParaError: Exception): TArray<IConsensusGroupInfo>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressGovernance, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetConsensusGroupList(vSd, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error(Format('c.stateDB.NewStorageDatabase failed, snapshotHash is %s', [ParaSnapshotHash.ToString]), 'method', 'GetConsensusGroupList');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetVoteList(const ParaSnapshotHash: THash; const ParaGid: TGid; out ParaError: Exception): TArray<IVoteInfo>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressGovernance, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetVoteList(vSd, ParaGid, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error(Format('c.stateDB.NewStorageDatabase failed, snapshotHash is %s', [ParaSnapshotHash.ToString]), 'method', 'GetVoteList');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetStakeBeneficialAmount(const ParaAddr: TAddress; out ParaError: Exception): TBigInt;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(Self.GetLatestSnapshotBlock.Hash, TAddressQuota, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetStakeBeneficialAmount(vSd, ParaAddr, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetStakeBeneficialAmount');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetStakeQuota(const ParaAddr: TAddress; out ParaAmount: TBigInt; out ParaError: Exception): IQuota;
var
  vVmDb: IVmDb;
begin
  Result := nil;
  ParaAmount := Self.GetStakeBeneficialAmount(ParaAddr, ParaError);
  if ParaError <> nil then
    Exit;
  vVmDb := TVmDb.NewVmDbByAddr(Self, ParaAddr);
  Result := TQuota.GetQuota(vVmDb, ParaAddr, ParaAmount, Self.GetLatestSnapshotBlock.Height, ParaError);
end;

function TChainBuiltinContractHelper.GetStakeQuotas(const ParaAddrList: TArray<TAddress>; out ParaError: Exception): TDictionary<TAddress, IQuota>;
var
  vSb: ISnapshotBlock;
  vSd: IStorageDatabase;
  vAddr: TAddress;
  vAmount: TBigInt;
  vVmDb: IVmDb;
  vQuota: IQuota;
begin
  Result := TDictionary<TAddress, IQuota>.Create;
  vSb := Self.GetLatestSnapshotBlock;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(vSb.Hash, TAddressQuota, ParaError);
    if ParaError <> nil then
      raise ParaError;

    for vAddr in ParaAddrList do
    begin
      vAmount := TABI.GetStakeBeneficialAmount(vSd, vAddr, ParaError);
      if ParaError <> nil then
      begin
        Self.mLog.Error(Format('abi.GetStakeBeneficialAmount failed, Addr is %s. Error: %s', [vAddr.ToString, ParaError.Message]), 'method', 'GetStakeQuotas');
        raise ParaError;
      end;

      vVmDb := TVmDb.NewVmDbByAddr(Self, vAddr);
      vQuota := TQuota.GetQuota(vVmDb, vAddr, vAmount, vSb.Height, ParaError);
      if ParaError <> nil then
      begin
        Self.mLog.Error(Format('quota.GetQuota failed. Error: %s', [ParaError.Message]), 'method', 'GetStakeQuotas');
        raise ParaError;
      end;
      Result.Add(vAddr, vQuota);
    end;
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetStakeBeneficialAmount');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetTokenInfoById(const ParaTokenId: TTokenTypeId; out ParaError: Exception): ITokenInfo;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(Self.GetLatestSnapshotBlock.Hash, TAddressAsset, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetTokenByID(vSd, ParaTokenId, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetTokenInfoById');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetAllTokenInfo(out ParaError: Exception): TDictionary<TTokenTypeId, ITokenInfo>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(Self.GetLatestSnapshotBlock.Hash, TAddressAsset, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetTokenMap(vSd, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetAllTokenInfo');
    end;
  end;
end;

type
  TByBalance = class(TComparer<IVoteDetails>)
  public
    function Compare(const Left, Right: IVoteDetails): Integer; override;
  end;

function TByBalance.Compare(const Left, Right: IVoteDetails): Integer;
var
  vCmp: Integer;
begin
  vCmp := Right.Balance.CompareTo(Left.Balance);
  if vCmp = 0 then
    Result := AnsiCompareStr(Left.Name, Right.Name)
  else
    Result := vCmp;
end;

function TChainBuiltinContractHelper.CalVoteDetails(const ParaGid: TGid; const ParaInfo: IGroupInfo; const ParaSnapshotBlock: THashHeight; out ParaError: Exception): TArray<IVoteDetails>;
var
  vRegisterList: TArray<IRegistration>;
  vVotes: TArray<IVoteInfo>;
  vRegisters: TArray<IVoteDetails>;
  vV: IRegistration;
begin
  Result := nil;
  vRegisterList := Self.GetRegisterList(ParaSnapshotBlock.Hash, ParaGid, ParaError);
  if ParaError <> nil then
    Exit;
  vVotes := Self.GetVoteList(ParaSnapshotBlock.Hash, ParaGid, ParaError);
  if ParaError <> nil then
    Exit;
  SetLength(vRegisters, Length(vRegisterList));
  for vV in vRegisterList do
    vRegisters := vRegisters + [Self.GenVoteDetails(ParaSnapshotBlock.Hash, vV, vVotes, ParaInfo.CountingTokenId)];
  TArray.Sort<IVoteDetails>(vRegisters, TByBalance.Create);
  Result := vRegisters;
end;

function TChainBuiltinContractHelper.GenVoteDetails(const ParaSnapshotHash: THash; const ParaRegistration: IRegistration; const ParaInfos: TArray<IVoteInfo>; const ParaId: TTokenTypeId): IVoteDetails;
var
  vAddrs: TArray<TAddress>;
  vV: IVoteInfo;
  vBalanceMap: TDictionary<TAddress, TBigInt>;
  vBalanceTotal: TBigInt;
  vBalance: TBigInt;
  vError: Exception;
begin
  for vV in ParaInfos do
  begin
    if vV.SbpName = ParaRegistration.Name then
      vAddrs := vAddrs + [vV.VoteAddr];
  end;
  vBalanceMap := Self.GetConfirmedBalanceList(vAddrs, ParaId, ParaSnapshotHash, vError);
  vBalanceTotal := TBigInt.Create(0);
  for vBalance in vBalanceMap.Values do
    vBalanceTotal := vBalanceTotal + vBalance;

  Result := TIVoteDetails.Create;
  Result.Vote.Name := ParaRegistration.Name;
  Result.Vote.Addr := ParaRegistration.BlockProducingAddress;
  Result.Vote.Balance := vBalanceTotal;
  Result.CurrentAddr := ParaRegistration.BlockProducingAddress;
  Result.RegisterList := ParaRegistration.HisAddrList;
  Result.Addr := vBalanceMap;
end;

function TChainBuiltinContractHelper.GetStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: TUInt64; out ParaNextKey: TBytes; out ParaError: Exception): TArray<IStakeInfo>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressQuota, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TABI.GetStakeListByPage(vSd, ParaLastKey, ParaCount, ParaNextKey, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetStakeAmountByPage');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetDexFundsByPage(const ParaSnapshotHash: THash; const ParaLastAddress: TAddress; ParaCount: Integer; out ParaError: Exception): TArray<IDexFund>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressDexFund, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TDEX.GetUserFundsByPage(vSd, ParaLastAddress, ParaCount, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetStakeAmountByPage');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetDexStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<IDelegateStakeInfo>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressDexFund, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TDEX.GetStakeListByPage(vSd, ParaLastKey, ParaCount, ParaNextKey, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetDexStakeListByPage');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetDexFundByAddress(const ParaSnapshotHash: THash; const ParaAddress: TAddress; out ParaError: Exception): IDexFund;
var
  vSd: IStorageDatabase;
  vV: TBytes;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressDexFund, ParaError);
    if ParaError <> nil then
      raise ParaError;
    vV := vSd.GetValue(TDEX.GetFundKey(ParaAddress), ParaError);
    if ParaError <> nil then
      raise ParaError;
    if Length(vV) > 0 then
    begin
      Result := TDexFund.Create;
      ParaError := Result.DeSerialize(vV);
    end;
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetDexFundByAddress');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetDexFundStakeForMiningV1ListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<TAddress>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressDexFund, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TDEX.GetStakeForMiningV1ByPage(vSd, ParaLastKey, ParaCount, ParaNextKey, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetDexFundStakeForMiningV1ListByPage');
    end;
  end;
end;

function TChainBuiltinContractHelper.GetDexFundStakeForMiningV2ListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes; out ParaError: Exception): TArray<TAddress>;
var
  vSd: IStorageDatabase;
begin
  Result := nil;
  ParaError := nil;
  try
    vSd := Self.mStateDB.NewStorageDatabase(ParaSnapshotHash, TAddressDexFund, ParaError);
    if ParaError <> nil then
      raise ParaError;
    Result := TDEX.GetStakeForMiningV2ByPage(vSd, ParaLastKey, ParaCount, ParaNextKey, ParaError);
  except
    on E: Exception do
    begin
      ParaError := E;
      Self.mLog.Error('c.stateDB.NewStorageDatabase failed', 'method', 'GetDexFundStakeForMiningV2ListByPage');
    end;
  end;
end;

end.
