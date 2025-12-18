unit Vm.Contracts.ContractsGovernance;

interface

uses
  Common.Types.Address Common.Types.Hash Common.Types.TokenTypeId Common.Helper Common.Upgrade,
  Interfaces.VmDb Interfaces.Core.AccountBlock Interfaces.Core.ContractMeta Interfaces.Core.SnapshotBlock,
  Ledger.Consensus.Core,
  System.SysUtils System.Classes System.Generics.Collections,
  Vm.Abi.Abi Vm.Contracts.Abi.AbiGovernance Vm.Contracts.Contracts Vm.Util.Util Vm.Quota.Quota,
  VM.Contracts.Contracts,
  VM.Contracts.Contracts.Asset,
  VM.Contracts.Contracts.Dex.Fund,
  VM.Contracts.Contracts.Dex.Trade,
  VM.Contracts.Contracts.Quota,
  VM.Contracts.Contracts.Test,
  VM.Contracts.Params,
  VM.Contracts.Reward.Test;

const
  RegistrationNameLengthMax = 10;

var
  SbpStakeAmountPreMainnet: TBigInteger;
  SbpStakeAmountMainnet: TBigInteger;
  RewardPerBlock: TBigInteger;
  RewardTimeLimit: Int64;

type
  TMethodRegister = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodRevoke = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodWithdrawReward = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TReward = record
    VoteReward: TBigInteger;
    BlockReward: TBigInteger;
    TotalReward: TBigInteger;
    BlockNum: UInt64;
    ExpectedBlockNum: UInt64;
    function Add(A: TReward): TReward;
  end;

  TMethodUpdateBlockProducingAddress = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodUpdateRewardWithdrawAddress = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodVote = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodCancelVote = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

function CheckRegisterAndVoteParam(Gid: TGid; const Name: string): Boolean;
function CheckRewardDrained(Reader: IConsensusReader; Db: IVmDb; Old: TRegistration; Current: TSnapshotBlock): Boolean;
function RewardDrained(Reward: TReward; Drained: Boolean): Boolean;
function CalcReward(Reader: IConsensusReader; Db: IVmDb; Old: TRegistration; Current: TSnapshotBlock): TTuple<Int64, Int64, TReward, Boolean>;
function CalcRewardByCycle(Db: IVmDb; Reader: IConsensusReader; Timestamp: Int64): TPair<TDictionary<string, TReward>, UInt64>;
function CalcRewardByIndex(Db: IVmDb; Reader: IConsensusReader; Index: UInt64): TDictionary<string, TReward>;

implementation

uses
  System.DateUtils;

{ TMethodRegister }

constructor TMethodRegister.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodRegister.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodRegister.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodRegister.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.RegisterQuota;
end;

function TMethodRegister.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodRegister.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamRegister;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, Block.Data);
  if FMethodName = MethodNameRegisterV3 then
    Param.Gid := SNAPSHOT_GID;
  if not CheckRegisterAndVoteParam(Param.Gid, Param.SbpName) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameRegisterV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName, Param.BlockProducingAddress, Param.RewardWithdrawAddress])
  else
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.Gid, Param.SbpName, Param.BlockProducingAddress]);
  Result := nil;
end;

function CheckRegisterAndVoteParam(Gid: TGid; const Name: string): Boolean;
var
  RegEx: TRegEx;
begin
  if Util.IsDelegateGid(Gid) or (Length(Name) = 0) or (Length(Name) > RegistrationNameLengthMax) then
    Exit(False);
  RegEx := TRegEx.Create('^([0-9a-zA-Z_.]+[ ]?)*[0-9a-zA-Z_.]$');
  Result := RegEx.IsMatch(Name);
end;

function TMethodRegister.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamRegister;
  SnapshotBlock: TSnapshotBlock;
  IsLeafFork: Boolean;
  RewardTime: Int64;
  Old: TRegistration;
  HisAddrList: TArray<TAddress>;
  OldWithdrawRewardAddress: TAddress;
  HisNameKey: TBytes;
  HisName: string;
  V: TBytes;
  GroupInfo: TConsensusGroupInfo;
  StakeParam: TVariableRegisterStakeParam;
  RegisterInfo: TBytes;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameRegisterV3 then
    Param.Gid := SNAPSHOT_GID
  else
    Param.RewardWithdrawAddress := SendBlock.AccountAddress;

  SnapshotBlock := Vm.GlobalStatus.SnapshotBlock;
  IsLeafFork := IsLeafUpgrade(Db.LatestSnapshotBlock.Height);
  if (not IsLeafFork and (SendBlock.Amount.Compare(SbpStakeAmountPreMainnet) <> 0)) or
     (IsLeafFork and (SendBlock.Amount.Compare(SbpStakeAmountMainnet) <> 0)) or
     (SendBlock.TokenId.Compare(ViteTokenId) <> 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  RewardTime := 0;
  if Util.IsSnapshotGid(Param.Gid) then
    RewardTime := SnapshotBlock.Timestamp.ToUnix;

  Old := GetRegistration(Db, Param.Gid, Param.SbpName);
  if Old.Name <> '' then
  begin
    if Old.IsActive or (Old.StakeAddress.Compare(SendBlock.AccountAddress) <> 0) then
      Exit(nil); // Should be util.ErrInvalidMethodParam

    if not CheckRewardDrained(Vm.ConsensusReader, Db, Old, SnapshotBlock) then
      Exit(nil); // Should be util.ErrRewardIsNotDrained

    HisAddrList := Old.HisAddrList;
    OldWithdrawRewardAddress := Old.RewardWithdrawAddress;
  end;

  HisNameKey := GetHisNameKey(Param.BlockProducingAddress, Param.Gid);
  V := Util.GetValue(Db, HisNameKey);
  if Length(V) = 0 then
  begin
    HisAddrList := HisAddrList + [Param.BlockProducingAddress];
    HisName := Param.SbpName;
    Util.SetValue(Db, HisNameKey, ABIDataGovernance.PackVariable(VariableNameRegisteredHisName, [HisName]));
  end
  else
  begin
    ABIDataGovernance.UnpackVariable(TValue.From<string>(HisName), VariableNameRegisteredHisName, V);
    if HisName <> Param.SbpName then
      Exit(nil); // Should be util.ErrInvalidMethodParam
  end;

  GroupInfo := GetConsensusGroup(Db, Param.Gid);
  if GroupInfo.Gid.Bytes = nil then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  StakeParam := GetRegisterStakeParamOfConsensusGroup(GroupInfo.RegisterConditionParam);

  if IsEarthUpgrade(Db.LatestSnapshotBlock.Height) then
  begin
    SaveWithdrawRewardAddress(Db, OldWithdrawRewardAddress, Param.RewardWithdrawAddress, SendBlock.AccountAddress, Param.SbpName);
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfoV2, [Param.SbpName, Param.BlockProducingAddress, Param.RewardWithdrawAddress, SendBlock.AccountAddress, SendBlock.Amount, SnapshotBlock.Height + StakeParam.StakeHeight, RewardTime, Int64(0), HisAddrList]);
  end
  else
  begin
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfo, [Param.SbpName, Param.BlockProducingAddress, SendBlock.AccountAddress, SendBlock.Amount, SnapshotBlock.Height + StakeParam.StakeHeight, RewardTime, Int64(0), HisAddrList]);
  end;
  Util.SetValue(Db, GetRegistrationInfoKey(Param.SbpName, Param.Gid), RegisterInfo);
  Result := nil;
end;

procedure SaveWithdrawRewardAddress(Db: IVmDb; OldAddr: TAddress; NewAddr, Owner: TAddress; const SbpName: string);
var
  Value: TBytes;
  ValueStr: string;
  Index: Integer;
begin
  if OldAddr.Compare(TAddress.Zero) = 0 then
  begin
    if NewAddr.Compare(Owner) = 0 then
      Exit;
    AddWithdrawRewardAddress(Db, NewAddr, SbpName);
    Exit;
  end;

  if OldAddr.Compare(NewAddr) = 0 then
    Exit;

  if OldAddr.Compare(Owner) = 0 then
  begin
    AddWithdrawRewardAddress(Db, NewAddr, SbpName);
    Exit;
  end;

  if NewAddr.Compare(Owner) = 0 then
  begin
    DeleteWithdrawRewardAddress(Db, OldAddr, SbpName);
    Exit;
  end;

  DeleteWithdrawRewardAddress(Db, OldAddr, SbpName);
  AddWithdrawRewardAddress(Db, NewAddr, SbpName);
end;

procedure AddWithdrawRewardAddress(Db: IVmDb; Addr: TAddress; const SbpName: string);
var
  Value: TBytes;
begin
  Value := Util.GetValue(Db, Addr.Bytes);
  if Length(Value) = 0 then
    Value := TEncoding.UTF8.GetBytes(SbpName)
  else
    Value := TEncoding.UTF8.GetBytes(TEncoding.UTF8.GetString(Value) + WithdrawRewardAddressSeparation + SbpName);
  Util.SetValue(Db, Addr.Bytes, Value);
end;

procedure DeleteWithdrawRewardAddress(Db: IVmDb; Addr: TAddress; const SbpName: string);
var
  Value: TBytes;
  ValueStr: string;
  StartIndex: Integer;
begin
  Value := Util.GetValue(Db, Addr.Bytes);
  ValueStr := TEncoding.UTF8.GetString(Value);

  if ValueStr = SbpName then
    Util.SetValue(Db, Addr.Bytes, nil)
  else if StartsText(SbpName + WithdrawRewardAddressSeparation, ValueStr) then
    Util.SetValue(Db, Addr.Bytes, TEncoding.UTF8.GetBytes(Copy(ValueStr, Length(SbpName) + Length(WithdrawRewardAddressSeparation) + 1, Length(ValueStr))))
  else if EndsText(WithdrawRewardAddressSeparation + SbpName, ValueStr) then
    Util.SetValue(Db, Addr.Bytes, TEncoding.UTF8.GetBytes(Copy(ValueStr, 1, Length(ValueStr) - Length(SbpName) - Length(WithdrawRewardAddressSeparation))))
  else
  begin
    StartIndex := Pos(WithdrawRewardAddressSeparation + SbpName + WithdrawRewardAddressSeparation, ValueStr);
    if StartIndex > 0 then
      Util.SetValue(Db, Addr.Bytes, TEncoding.UTF8.GetBytes(Copy(ValueStr, 1, StartIndex - 1) + Copy(ValueStr, StartIndex + Length(SbpName) + Length(WithdrawRewardAddressSeparation), Length(ValueStr))));
  end;
end;

{ TMethodRevoke }

constructor TMethodRevoke.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodRevoke.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodRevoke.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodRevoke.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.RevokeQuota;
end;

function TMethodRevoke.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodRevoke.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamCancelRegister;
  Gid: TGid;
begin
  if Block.Amount.Sign <> 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameRevokeV3 then
  begin
    ABIDataGovernance.UnpackMethod(TValue.From<TParamCancelRegister>(Param), FMethodName, Block.Data);
    Param.Gid := SNAPSHOT_GID;
  end
  else
  begin
    ABIDataGovernance.UnpackMethod(TValue.From<TGid>(Gid), FMethodName, Block.Data);
    Param.Gid := Gid;
  end;

  if not CheckRegisterAndVoteParam(Param.Gid, Param.SbpName) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameRevokeV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName])
  else
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.Gid, Param.SbpName]);
  Result := nil;
end;

function TMethodRevoke.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamCancelRegister;
  SnapshotBlock: TSnapshotBlock;
  Old: TRegistration;
  RewardTime: Int64;
  RevokeTime: Int64;
  Drained: Boolean;
  RegisterInfo: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamCancelRegister>(Param), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameRevokeV3 then
    Param.Gid := SNAPSHOT_GID;

  SnapshotBlock := Vm.GlobalStatus.SnapshotBlock;
  Old := GetRegistration(Db, Param.Gid, Param.SbpName);
  if (Old.Name = '') or (not Old.IsActive) or (Old.StakeAddress.Compare(SendBlock.AccountAddress) <> 0) or (Old.ExpirationHeight > SnapshotBlock.Height) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  RewardTime := Old.RewardTime;
  RevokeTime := SnapshotBlock.Timestamp.ToUnix;
  Drained := CheckRewardDrained(Vm.ConsensusReader, Db, Old, SnapshotBlock);
  if Drained then
    RewardTime := -1;

  if IsEarthUpgrade(SnapshotBlock.Height) then
  begin
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfoV2, [Old.Name, Old.BlockProducingAddress, Old.RewardWithdrawAddress, Old.StakeAddress, TBigInteger.Create(0), UInt64(0), RewardTime, RevokeTime, Old.HisAddrList]);
  end
  else
  begin
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfo, [Old.Name, Old.BlockProducingAddress, Old.StakeAddress, TBigInteger.Create(0), UInt64(0), RewardTime, RevokeTime, Old.HisAddrList]);
  end;
  Util.SetValue(Db, GetRegistrationInfoKey(Param.SbpName, Param.Gid), RegisterInfo);

  if Old.Amount.Sign > 0 then
  begin
    SendBlockItem.AccountAddress := Block.AccountAddress;
    SendBlockItem.ToAddress := SendBlock.AccountAddress;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.Amount := Old.Amount;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Data := [];
    Result := [SendBlockItem];
  end
  else
    Result := nil;
end;

{ TMethodWithdrawReward }

constructor TMethodWithdrawReward.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodWithdrawReward.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodWithdrawReward.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodWithdrawReward.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.WithdrawRewardQuota;
end;

function TMethodWithdrawReward.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodWithdrawReward.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamReward;
begin
  if Block.Amount.Sign <> 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataGovernance.UnpackMethod(TValue.From<TParamReward>(Param), FMethodName, Block.Data);
  if FMethodName = MethodNameWithdrawRewardV3 then
    Param.Gid := SNAPSHOT_GID;

  if not Util.IsSnapshotGid(Param.Gid) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameWithdrawRewardV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName, Param.ReceiveAddress])
  else
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.Gid, Param.SbpName, Param.ReceiveAddress]);
  Result := nil;
end;

function TMethodWithdrawReward.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamReward;
  Old: TRegistration;
  Sb: TSnapshotBlock;
  EndTime: Int64;
  Reward: TReward;
  Drained: Boolean;
  RegisterInfo: TBytes;
  MethodName: string;
  ReIssueData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamReward>(Param), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameWithdrawRewardV3 then
    Param.Gid := SNAPSHOT_GID;

  Old := GetRegistration(Db, Param.Gid, Param.SbpName);
  Sb := Db.LatestSnapshotBlock;
  if (Old.Name = '') or (Old.RewardTime = -1) or
     ((SendBlock.AccountAddress.Compare(Old.StakeAddress) <> 0) and (SendBlock.AccountAddress.Compare(Old.RewardWithdrawAddress) <> 0)) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  EndTime := CalcReward(Vm.ConsensusReader, Db, Old, Vm.GlobalStatus.SnapshotBlock).Item2;
  Reward := CalcReward(Vm.ConsensusReader, Db, Old, Vm.GlobalStatus.SnapshotBlock).Item3;
  Drained := CalcReward(Vm.ConsensusReader, Db, Old, Vm.GlobalStatus.SnapshotBlock).Item4;

  if Drained then
    EndTime := -1;

  if EndTime <> Old.RewardTime then
  begin
    if IsEarthUpgrade(Sb.Height) then
    begin
      RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfoV2, [Old.Name, Old.BlockProducingAddress, Old.RewardWithdrawAddress, Old.StakeAddress, Old.Amount, Old.ExpirationHeight, EndTime, Old.RevokeTime, Old.HisAddrList]);
    end
    else
    begin
      RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfo, [Old.Name, Old.BlockProducingAddress, Old.StakeAddress, Old.Amount, Old.ExpirationHeight, EndTime, Old.RevokeTime, Old.HisAddrList]);
    end;
    Util.SetValue(Db, GetRegistrationInfoKey(Param.SbpName, Param.Gid), RegisterInfo);

    if (Reward.TotalReward <> nil) and (Reward.TotalReward.Sign > 0) then
    begin
      if not Util.CheckFork(Db, IsLeafUpgrade) then
        MethodName := MethodNameReIssue
      else
        MethodName := MethodNameReIssueV2;

      ReIssueData := ABIDataAsset.PackMethod(MethodName, [ViteTokenId, Reward.TotalReward, Param.ReceiveAddress]);
      SendBlockItem.AccountAddress := Block.AccountAddress;
      SendBlockItem.ToAddress := AddressAsset;
      SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
      SendBlockItem.Amount := TBigInteger.Create(0);
      SendBlockItem.TokenId := ViteTokenId;
      SendBlockItem.Data := ReIssueData;
      Result := [SendBlockItem];
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function CheckRewardDrained(Reader: IConsensusReader; Db: IVmDb; Old: TRegistration; Current: TSnapshotBlock): Boolean;
var
  Reward: TReward;
  Drained: Boolean;
begin
  Reward := CalcReward(Reader, Db, Old, Current).Item3;
  Drained := CalcReward(Reader, Db, Old, Current).Item4;
  Result := RewardDrained(Reward, Drained);
end;

function RewardDrained(Reward: TReward; Drained: Boolean): Boolean;
begin
  Result := Drained and ((Reward.TotalReward = nil) or (Reward.TotalReward.Sign = 0));
end;

function NewZeroReward: TReward;
begin
  Result.VoteReward := TBigInteger.Create(0);
  Result.BlockReward := TBigInteger.Create(0);
  Result.TotalReward := TBigInteger.Create(0);
  Result.BlockNum := 0;
  Result.ExpectedBlockNum := 0;
end;

function TReward.Add(A: TReward): TReward;
begin
  Result.VoteReward := TBigInteger.Add(Self.VoteReward, A.VoteReward);
  Result.BlockReward := TBigInteger.Add(Self.BlockReward, A.BlockReward);
  Result.TotalReward := TBigInteger.Add(Self.TotalReward, A.TotalReward);
  Result.BlockNum := Self.BlockNum + A.BlockNum;
  Result.ExpectedBlockNum := Self.ExpectedBlockNum + A.ExpectedBlockNum;
end;

function CalcReward(Reader: IConsensusReader; Db: IVmDb; Old: TRegistration; Current: TSnapshotBlock): TTuple<Int64, Int64, TReward, Boolean>;
var
  GenesisTime: Int64;
  StartIndex, EndIndex: UInt64;
  StartTime, EndTime: Int64;
  Drained: Boolean;
  WithinOneDayFlag: Boolean;
  TimeLimit: Int64;
  Details: TArray<TDayStats>;
  Reward: TReward;
  ForkIndex: UInt64;
  StakeAmount: TBigInteger;
  Detail: TDayStats;
  DayDetail: TReward;
begin
  GenesisTime := Db.GetGenesisSnapshotBlock.Timestamp.ToUnix;
  StartIndex := Reader.GetIndexByStartTime(Old.RewardTime, GenesisTime).Item1;
  StartTime := Reader.GetIndexByStartTime(Old.RewardTime, GenesisTime).Item2;
  Drained := Reader.GetIndexByStartTime(Old.RewardTime, GenesisTime).Item3;

  if Drained then
  begin
    Result := TTuple<Int64, Int64, TReward, Boolean>.Create(0, 0, NewZeroReward, True);
    Exit;
  end;

  TimeLimit := GetRewardTimeLimit(Current);
  if not Old.IsActive then
  begin
    EndIndex := Reader.GetIndexByEndTime(Old.RevokeTime, GenesisTime).Item1;
    EndTime := Reader.GetIndexByEndTime(Old.RevokeTime, GenesisTime).Item2;
    WithinOneDayFlag := Reader.GetIndexByEndTime(Old.RevokeTime, GenesisTime).Item3;
    if EndTime <= TimeLimit then
      Drained := True
    else
    begin
      EndIndex := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item1;
      EndTime := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item2;
      WithinOneDayFlag := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item3;
    end;
  end
  else
  begin
    EndIndex := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item1;
    EndTime := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item2;
    WithinOneDayFlag := Reader.GetIndexByEndTime(TimeLimit, GenesisTime).Item3;
  end;

  if WithinOneDayFlag or (StartIndex > EndIndex) then
  begin
    Result := TTuple<Int64, Int64, TReward, Boolean>.Create(StartTime, EndTime, NewZeroReward, Drained);
    Exit;
  end;

  Details := Reader.GetConsensusDetailByDay(StartIndex, EndIndex);
  Reward := NewZeroReward;
  ForkIndex := 0;
  for Detail in Details do
  begin
    StakeAmount := GetSnapshotGroupStakeAmount(Db, Reader, GenesisTime, Detail.Index, ForkIndex).Item1;
    ForkIndex := GetSnapshotGroupStakeAmount(Db, Reader, GenesisTime, Detail.Index, ForkIndex).Item2;
    DayDetail := CalcRewardByDayDetail(Detail, Old.Name, StakeAmount);
    Reward := Reward.Add(DayDetail);
  end;
  Result := TTuple<Int64, Int64, TReward, Boolean>.Create(StartTime, EndTime, Reward, Drained);
end;

function GetRewardTimeLimit(Current: TSnapshotBlock): Int64;
begin
  Result := Current.Timestamp.ToUnix - RewardTimeLimit;
end;

function GetSnapshotGroupStakeAmount(Db: IVmDb; Reader: IConsensusReader; GenesisTime: Int64; Index: UInt64; ForkIndex: UInt64): TPair<TBigInteger, UInt64>;
var
  Sb: TSnapshotBlock;
begin
  Sb := Db.LatestSnapshotBlock;
  if not IsLeafUpgrade(Sb.Height) then
  begin
    Result := TPair<TBigInteger, UInt64>.Create(SbpStakeAmountPreMainnet, 0);
    Exit;
  end;

  if ForkIndex = 0 then
  begin
    Sb := Db.GetSnapshotBlockByHeight(GetLeafUpgradePoint.Height);
    ForkIndex := Reader.GetIndexByTime(Sb.Timestamp.ToUnix, GenesisTime);
  end;

  if Index <= ForkIndex then
    Result := TPair<TBigInteger, UInt64>.Create(SbpStakeAmountPreMainnet, ForkIndex)
  else
    Result := TPair<TBigInteger, UInt64>.Create(SbpStakeAmountMainnet, ForkIndex);
end;

function CalcRewardByCycle(Db: IVmDb; Reader: IConsensusReader; Timestamp: Int64): TPair<TDictionary<string, TReward>, UInt64>;
var
  GenesisTime: Int64;
  Index: UInt64;
  EndTime: Int64;
  Current: TSnapshotBlock;
  TimeLimit: Int64;
  StakeAmount: TBigInteger;
  M: TDictionary<string, TReward>;
begin
  GenesisTime := Db.GetGenesisSnapshotBlock.Timestamp.ToUnix;
  if Timestamp < GenesisTime then
    raise EUtilInvalidMethodParam.Create('invalid method param');

  Index := Reader.GetIndexByTime(Timestamp, GenesisTime);
  EndTime := Reader.GetEndTimeByIndex(Index);
  Current := Db.LatestSnapshotBlock;
  TimeLimit := GetRewardTimeLimit(Current);

  if EndTime > TimeLimit then
    raise EUtilRewardNotDue.Create('reward not due');

  StakeAmount := GetSnapshotGroupStakeAmount(Db, Reader, GenesisTime, Index, 0).Item1;
  M := CalcRewardByDay(Reader, Index, StakeAmount);
  Result := TPair<TDictionary<string, TReward>, UInt64>.Create(M, Index);
end;

function CalcRewardByIndex(Db: IVmDb; Reader: IConsensusReader; Index: UInt64): TDictionary<string, TReward>;
var
  EndTime: Int64;
  Current: TSnapshotBlock;
  TimeLimit: Int64;
  GenesisTime: Int64;
  StakeAmount: TBigInteger;
begin
  EndTime := Reader.GetEndTimeByIndex(Index);
  Current := Db.LatestSnapshotBlock;
  TimeLimit := GetRewardTimeLimit(Current);

  if EndTime > TimeLimit then
    raise EUtilRewardNotDue.Create('reward not due');

  GenesisTime := Db.GetGenesisSnapshotBlock.Timestamp.ToUnix;
  StakeAmount := GetSnapshotGroupStakeAmount(Db, Reader, GenesisTime, Index, 0).Item1;
  Result := CalcRewardByDay(Reader, Index, StakeAmount);
end;

function CalcRewardByDay(Reader: IConsensusReader; Index: UInt64; StakeAmount: TBigInteger): TDictionary<string, TReward>;
var
  DetailList: TArray<TDayStats>;
  RewardMap: TDictionary<string, TReward>;
  Name: string;
begin
  DetailList := Reader.GetConsensusDetailByDay(Index, Index);
  if Length(DetailList) = 0 then
  begin
    Result := TDictionary<string, TReward>.Create;
    Exit;
  end;

  RewardMap := TDictionary<string, TReward>.Create;
  for Name in DetailList[0].Stats.Keys do
    RewardMap.Add(Name, CalcRewardByDayDetail(DetailList[0], Name, StakeAmount));
  Result := RewardMap;
end;

function CalcRewardByDayDetail(Detail: TDayStats; const Name: string; StakeAmount: TBigInteger): TReward;
var
  SelfDetail: TConsensusStat;
  Ok: Boolean;
  Tmp1, Tmp2: TBigInteger;
begin
  Ok := Detail.Stats.TryGetValue(Name, SelfDetail);
  if (not Ok) or (SelfDetail.ExceptedBlockNum = 0) then
  begin
    Result := NewZeroReward;
    Exit;
  end;

  Result := NewZeroReward;

  Tmp1 := TBigInteger.Create(SelfDetail.VoteCnt);
  Tmp1 := TBigInteger.Add(Tmp1, StakeAmount);
  Tmp2 := TBigInteger.Create(Detail.BlockTotal);
  Tmp1 := TBigInteger.Multiply(Tmp1, Tmp2);
  Tmp1 := TBigInteger.Multiply(Tmp1, TBigInteger.Create(50));
  Tmp1 := TBigInteger.Multiply(Tmp1, RewardPerBlock);
  Tmp2 := TBigInteger.Create(SelfDetail.BlockNum);
  Tmp1 := TBigInteger.Multiply(Tmp1, Tmp2);
  Tmp2 := TBigInteger.Create(Length(Detail.Stats));
  Tmp2 := TBigInteger.Multiply(Tmp2, StakeAmount);
  Tmp2 := TBigInteger.Add(Tmp2, Detail.VoteSum);
  Tmp1 := TBigInteger.Divide(Tmp1, Tmp2);
  Tmp2 := TBigInteger.Create(SelfDetail.ExceptedBlockNum);
  Tmp1 := TBigInteger.Divide(Tmp1, Tmp2);
  Tmp1 := TBigInteger.Divide(Tmp1, TBigInteger.Create(100));
  Result.VoteReward := Tmp1;

  Tmp2 := TBigInteger.Create(SelfDetail.BlockNum);
  Tmp2 := TBigInteger.Multiply(Tmp2, TBigInteger.Create(50));
  Tmp2 := TBigInteger.Multiply(Tmp2, RewardPerBlock);
  Tmp2 := TBigInteger.Divide(Tmp2, TBigInteger.Create(100));
  Result.BlockReward := Tmp2;

  Result.TotalReward := TBigInteger.Add(Tmp1, Tmp2);
  Result.BlockNum := SelfDetail.BlockNum;
  Result.ExpectedBlockNum := SelfDetail.ExceptedBlockNum;
end;

{ TMethodUpdateBlockProducingAddress }

constructor TMethodUpdateBlockProducingAddress.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodUpdateBlockProducingAddress.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodUpdateBlockProducingAddress.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodUpdateBlockProducingAddress.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.UpdateBlockProducingAddressQuota;
end;

function TMethodUpdateBlockProducingAddress.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodUpdateBlockProducingAddress.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamRegister;
begin
  if Block.Amount.Sign <> 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, Block.Data);
  if FMethodName = MethodNameUpdateBlockProducintAddressV3 then
    Param.Gid := SNAPSHOT_GID;

  if not CheckRegisterAndVoteParam(Param.Gid, Param.SbpName) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameUpdateBlockProducintAddressV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName, Param.BlockProducingAddress])
  else
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.Gid, Param.SbpName, Param.BlockProducingAddress]);
  Result := nil;
end;

function TMethodUpdateBlockProducingAddress.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamRegister;
  Old: TRegistration;
  HisNameKey: TBytes;
  HisName: string;
  V: TBytes;
  RegisterInfo: TBytes;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameUpdateBlockProducintAddressV3 then
    Param.Gid := SNAPSHOT_GID;

  Old := GetRegistration(Db, Param.Gid, Param.SbpName);
  if (Old.Name = '') or (not Old.IsActive) or
     (Old.StakeAddress.Compare(SendBlock.AccountAddress) <> 0) or
     (Old.BlockProducingAddress.Compare(Param.BlockProducingAddress) = 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  HisNameKey := GetHisNameKey(Param.BlockProducingAddress, Param.Gid);
  V := Util.GetValue(Db, HisNameKey);
  if Length(V) = 0 then
  begin
    Old.HisAddrList := Old.HisAddrList + [Param.BlockProducingAddress];
    HisName := Param.SbpName;
    Util.SetValue(Db, HisNameKey, ABIDataGovernance.PackVariable(VariableNameRegisteredHisName, [HisName]));
  end
  else
  begin
    ABIDataGovernance.UnpackVariable(TValue.From<string>(HisName), VariableNameRegisteredHisName, V);
    if HisName <> Param.SbpName then
      Exit(nil); // Should be util.ErrInvalidMethodParam
  end;

  if Util.CheckFork(Db, IsEarthUpgrade) then
  begin
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfoV2, [Old.Name, Param.BlockProducingAddress, Old.RewardWithdrawAddress, Old.StakeAddress, Old.Amount, Old.ExpirationHeight, Old.RewardTime, Old.RevokeTime, Old.HisAddrList]);
  end
  else
  begin
    RegisterInfo := ABIDataGovernance.PackVariable(VariableNameRegistrationInfo, [Old.Name, Param.BlockProducingAddress, Old.StakeAddress, Old.Amount, Old.ExpirationHeight, Old.RewardTime, Old.RevokeTime, Old.HisAddrList]);
  end;
  Util.SetValue(Db, GetRegistrationInfoKey(Param.SbpName, Param.Gid), RegisterInfo);
  Result := nil;
end;

{ TMethodUpdateRewardWithdrawAddress }

constructor TMethodUpdateRewardWithdrawAddress.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodUpdateRewardWithdrawAddress.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodUpdateRewardWithdrawAddress.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodUpdateRewardWithdrawAddress.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.UpdateRewardWithdrawAddressQuota;
end;

function TMethodUpdateRewardWithdrawAddress.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodUpdateRewardWithdrawAddress.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamRegister;
begin
  if Block.Amount.Sign <> 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, Block.Data);
  Param.Gid := SNAPSHOT_GID;

  if not CheckRegisterAndVoteParam(Param.Gid, Param.SbpName) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName, Param.RewardWithdrawAddress]);
  Result := nil;
end;

function TMethodUpdateRewardWithdrawAddress.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamRegister;
  Old: TRegistration;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamRegister>(Param), FMethodName, SendBlock.Data);
  Param.Gid := SNAPSHOT_GID;

  Old := GetRegistration(Db, Param.Gid, Param.SbpName);
  if (Old.Name = '') or (not Old.IsActive) or
     (Old.StakeAddress.Compare(SendBlock.AccountAddress) <> 0) or
     (Old.RewardWithdrawAddress.Compare(Param.RewardWithdrawAddress) = 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  SaveWithdrawRewardAddress(Db, Old.RewardWithdrawAddress, Param.RewardWithdrawAddress, Old.StakeAddress, Old.Name);
  Util.SetValue(Db, GetRegistrationInfoKey(Param.SbpName, Param.Gid), ABIDataGovernance.PackVariable(VariableNameRegistrationInfoV2, [Old.Name, Old.BlockProducingAddress, Param.RewardWithdrawAddress, Old.StakeAddress, Old.Amount, Old.ExpirationHeight, Old.RewardTime, Old.RevokeTime, Old.HisAddrList]));
  Result := nil;
end;

{ TMethodVote }

constructor TMethodVote.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodVote.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodVote.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodVote.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.VoteQuota;
end;

function TMethodVote.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodVote.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  LatestSb: TSnapshotBlock;
  Param: TParamVote;
begin
  LatestSb := Db.LatestSnapshotBlock;
  if (Block.Amount.Sign <> 0) or (IsContractAddr(Block.AccountAddress) and (not IsStemUpgrade(LatestSb.Height))) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataGovernance.UnpackMethod(TValue.From<TParamVote>(Param), FMethodName, Block.Data);
  if FMethodName = MethodNameVoteV3 then
    Param.Gid := SNAPSHOT_GID;

  if not CheckRegisterAndVoteParam(Param.Gid, Param.SbpName) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameVoteV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.SbpName])
  else
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Param.Gid, Param.SbpName]);
  Result := nil;
end;

function TMethodVote.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamVote;
  ConsensusGroupInfo: TConsensusGroupInfo;
  Active: Boolean;
  VoteKey: TBytes;
  VoteStatus: TBytes;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TParamVote>(Param), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameVoteV3 then
    Param.Gid := SNAPSHOT_GID;

  ConsensusGroupInfo := GetConsensusGroup(Db, Param.Gid);
  if ConsensusGroupInfo.Gid.Bytes = nil then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  Active := IsActiveRegistration(Db, Param.SbpName, Param.Gid);
  if not Active then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  VoteKey := GetVoteInfoKey(SendBlock.AccountAddress, Param.Gid);
  VoteStatus := ABIDataGovernance.PackVariable(VariableNameVoteInfo, [Param.SbpName]);
  Util.SetValue(Db, VoteKey, VoteStatus);
  Result := nil;
end;

{ TMethodCancelVote }

constructor TMethodCancelVote.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodCancelVote.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodCancelVote.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodCancelVote.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.CancelVoteQuota;
end;

function TMethodCancelVote.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodCancelVote.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  LatestSb: TSnapshotBlock;
  Gid: TGid;
begin
  LatestSb := Db.LatestSnapshotBlock;
  if (Block.Amount.Sign <> 0) or (IsContractAddr(Block.AccountAddress) and (not IsStemUpgrade(LatestSb.Height))) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  if FMethodName = MethodNameCancelVoteV3 then
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [])
  else
  begin
    ABIDataGovernance.UnpackMethod(TValue.From<TGid>(Gid), FMethodName, Block.Data);
    if Util.IsDelegateGid(Gid) then
      Exit(EUtilInvalidMethodParam.Create('invalid method param'));
    Block.Data := ABIDataGovernance.PackMethod(FMethodName, [Gid]);
  end;
  Result := nil;
end;

function TMethodCancelVote.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Gid: TGid;
begin
  ABIDataGovernance.UnpackMethod(TValue.From<TGid>(Gid), FMethodName, SendBlock.Data);
  if FMethodName = MethodNameCancelVoteV3 then
    Gid := SNAPSHOT_GID;

  Util.SetValue(Db, GetVoteInfoKey(SendBlock.AccountAddress, Gid), nil);
  Result := nil;
end;

initialization
  SbpStakeAmountPreMainnet := TBigInteger.Create(1000000000000000000000000); // 1M VITE
  SbpStakeAmountMainnet := TBigInteger.Create(1000000000000000000000000); // 1M VITE
  RewardPerBlock := TBigInteger.Create(1000000000000000000); // 1 VITE
  RewardTimeLimit := 30 * SecsPerDay; // 30 days

end.
