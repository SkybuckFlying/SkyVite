unit Vm.Contracts.Abi.AbiGovernance;

interface

uses
  Interfaces.VmDb Common.Types.Contracts Vm.Util.Util,
  System.SysUtils System.Classes System.Generics.Collections,
  Vm.Abi.Abi Common.Types.Address Common.Types.Gid Common.Types.TokenTypeId,
  VM.Contracts.ABI.ABI.Asset,
  VM.Contracts.ABI.ABI.Dex.Fund,
  VM.Contracts.ABI.ABI.Dex.Fund.Test,
  VM.Contracts.ABI.ABI.Dex.Trade,
  VM.Contracts.ABI.ABI.Quota,
  VM.Contracts.ABI.ABI.Test,
  VM.Contracts.ABI.Util;

const
  VariableNameConsensusGroupInfo = 'consensusGroupInfo';
  VariableNameRegisterStakeParam = 'registerStakeParam';

  MethodNameRegister = 'Register';
  MethodNameRegisterV3 = 'RegisterSBP';
  MethodNameRevoke = 'CancelRegister';
  MethodNameRevokeV2 = 'Revoke';
  MethodNameRevokeV3 = 'RevokeSBP';
  MethodNameWithdrawReward = 'Reward';
  MethodNameWithdrawRewardV2 = 'WithdrawReward';
  MethodNameWithdrawRewardV3 = 'WithdrawSBPReward';
  MethodNameUpdateBlockProducingAddress = 'UpdateRegistration';
  MethodNameUpdateBlockProducintAddressV2 = 'UpdateBlockProducingAddress';
  MethodNameUpdateBlockProducintAddressV3 = 'UpdateSBPBlockProducingAddress';
  MethodNameUpdateSBPRewardWithdrawAddress = 'UpdateSBPRewardWithdrawAddress';
  VariableNameRegistrationInfo = 'registrationInfo';
  VariableNameRegistrationInfoV2 = 'registrationInfoV2';
  VariableNameRegisteredHisName = 'registeredHisName';

  MethodNameVote = 'Vote';
  MethodNameVoteV3 = 'VoteForSBP';
  MethodNameCancelVote = 'CancelVote';
  MethodNameCancelVoteV3 = 'CancelSBPVoting';
  VariableNameVoteInfo = 'voteInfo';

  GroupInfoKeyPrefixSize = 1;
  VoteInfoKeyPrefixSize = 1;
  ConsensusGroupInfoKeySize = GroupInfoKeyPrefixSize + GidSize;
  RegistrationInfoKeySize = 30;
  VoteInfoKeySize = VoteInfoKeyPrefixSize + GidSize + AddressSize;

  WithdrawRewardAddressSeparation = ',';

var
  ABIDataGovernance: TAbiContract;

  GroupInfoKeyPrefix: TBytes;
  VoteInfoKeyPrefix: TBytes;

type
  TVariableRegisterStakeParam = record
    StakeAmount: TBigInteger;
    StakeToken: TTokenTypeId;
    StakeHeight: UInt64;
  end;

  TParamRegister = record
    Gid: TGid;
    SbpName: string;
    BlockProducingAddress: TAddress;
    RewardWithdrawAddress: TAddress;
  end;

  TParamCancelRegister = record
    Gid: TGid;
    SbpName: string;
  end;

  TParamReward = record
    Gid: TGid;
    SbpName: string;
    ReceiveAddress: TAddress;
  end;

  TParamVote = record
    Gid: TGid;
    SbpName: string;
  end;

function GetConsensusGroupInfoKey(Gid: TGid): TBytes;
function GetGidFromConsensusGroupInfoKey(Key: TBytes): TGid;
function IsConsensusGroupInfoKey(Key: TBytes): Boolean;
function GetRegistrationInfoKey(const Name: string; Gid: TGid): TBytes;
function IsRegistrationInfoKey(Key: TBytes): Boolean;
function GetHisNameKey(Addr: TAddress; Gid: TGid): TBytes;
function GetVoteInfoKey(Addr: TAddress; Gid: TGid): TBytes;
function GetVoteInfoKeyPerfixByGid(Gid: TGid): TBytes;
function IsVoteInfoKey(Key: TBytes): Boolean;
function GetAddrFromVoteInfoKey(Key: TBytes): TAddress;

function GetConsensusGroupList(Db: IVmDb): TArray<TConsensusGroupInfo>;
function GetConsensusGroup(Db: IVmDb; Gid: TGid): TConsensusGroupInfo;
function GetRegisterStakeParamOfConsensusGroup(Data: TBytes): TVariableRegisterStakeParam;
function IsActiveRegistration(Db: IVmDb; const Name: string; Gid: TGid): Boolean;
function GetAllRegistrationList(Db: IVmDb; Gid: TGid): TArray<TRegistration>;
function GetCandidateList(Db: IVmDb; Gid: TGid): TArray<TRegistration>;
function GetRegistrationList(Db: IVmDb; Gid: TGid; StakeAddr: TAddress): TArray<TRegistration>;
function GetRegistrationListByRewardWithdrawAddr(Db: IVmDb; Gid: TGid; RewardWithdrawAddr: TAddress): TArray<TRegistration>;
function GetRegistration(Db: IVmDb; Gid: TGid; const Name: string): TRegistration;
function UnpackRegistration(Value: TBytes): TRegistration;
function GetVote(Db: IVmDb; Gid: TGid; Addr: TAddress): TVoteInfo;
function GetVoteList(Db: IVmDb; Gid: TGid): TArray<TVoteInfo>;

implementation

function ParseConsensusGroup(Data: TBytes; Gid: TGid): TConsensusGroupInfo;
var
  ConsensusGroupInfo: TConsensusGroupInfo;
begin
  if Length(Data) = 0 then
  begin
    FillChar(Result, SizeOf(TConsensusGroupInfo), 0);
    Exit;
  end;
  ABIDataGovernance.UnpackVariable(TValue.From<TConsensusGroupInfo>(ConsensusGroupInfo), VariableNameConsensusGroupInfo, Data);
  ConsensusGroupInfo.Gid := Gid;
  Result := ConsensusGroupInfo;
end;

function GetConsensusGroupInfoKey(Gid: TGid): TBytes;
begin
  Result := GroupInfoKeyPrefix + Gid.Bytes;
end;

function GetGidFromConsensusGroupInfoKey(Key: TBytes): TGid;
begin
  Result := BytesToGid(Copy(Key, GroupInfoKeyPrefixSize, GidSize));
end;

function IsConsensusGroupInfoKey(Key: TBytes): Boolean;
begin
  Result := Length(Key) = ConsensusGroupInfoKeySize;
end;

function GetRegistrationInfoKey(const Name: string; Gid: TGid): TBytes;
begin
  Result := Gid.Bytes + DataHash(TEncoding.UTF8.GetBytes(Name)).Bytes;
  SetLength(Result, RegistrationInfoKeySize);
end;

function IsRegistrationInfoKey(Key: TBytes): Boolean;
begin
  Result := Length(Key) = RegistrationInfoKeySize;
end;

function GetHisNameKey(Addr: TAddress; Gid: TGid): TBytes;
begin
  Result := Addr.Bytes + Gid.Bytes;
end;

function GetVoteInfoKey(Addr: TAddress; Gid: TGid): TBytes;
begin
  Result := VoteInfoKeyPrefix + Gid.Bytes + Addr.Bytes;
end;

function GetVoteInfoKeyPerfixByGid(Gid: TGid): TBytes;
begin
  Result := VoteInfoKeyPrefix + Gid.Bytes;
end;

function IsVoteInfoKey(Key: TBytes): Boolean;
begin
  Result := Length(Key) = VoteInfoKeySize;
end;

function GetAddrFromVoteInfoKey(Key: TBytes): TAddress;
begin
  Result := BytesToAddress(Copy(Key, 1 + GidSize, AddressSize));
end;

function GetConsensusGroupList(Db: IVmDb): TArray<TConsensusGroupInfo>;
var
  Iterator: IStorageIterator;
  Info: TConsensusGroupInfo;
begin
  Result := [];
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  Iterator := Db.NewStorageIterator(GroupInfoKeyPrefix);
  try
    while Iterator.Next do
    begin
      if IsConsensusGroupInfoKey(Iterator.Key) then
      begin
        Info := ParseConsensusGroup(Iterator.Value, GetGidFromConsensusGroupInfoKey(Iterator.Key));
        if Info.IsActive then
          Result := Result + [Info];
      end;
    end;
  finally
    Iterator.Release;
  end;
end;

function GetConsensusGroup(Db: IVmDb; Gid: TGid): TConsensusGroupInfo;
var
  Data: TBytes;
begin
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Data := Db.GetValue(GetConsensusGroupInfoKey(Gid));
  Result := ParseConsensusGroup(Data, Gid);
end;

function GetRegisterStakeParamOfConsensusGroup(Data: TBytes): TVariableRegisterStakeParam;
var
  StakeParam: TVariableRegisterStakeParam;
begin
  ABIDataGovernance.UnpackVariable(TValue.From<TVariableRegisterStakeParam>(StakeParam), VariableNameRegisterStakeParam, Data);
  StakeParam.StakeAmount := nil;
  Result := StakeParam;
end;

function IsActiveRegistration(Db: IVmDb; const Name: string; Gid: TGid): Boolean;
var
  Value: TBytes;
  Registration: TRegistration;
begin
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Value := Db.GetValue(GetRegistrationInfoKey(Name, Gid));
  if Length(Value) > 0 then
  begin
    Registration := UnpackRegistration(Value);
    Result := Registration.IsActive;
  end
  else
    Result := False;
end;

function GetRegistrationList(Db: IVmDb; Gid: TGid; Filter: Boolean): TArray<TRegistration>;
var
  Iterator: IStorageIterator;
  Registration: TRegistration;
begin
  Result := [];
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  if Gid.Compare(DELEGATE_GID) = 0 then
    Iterator := Db.NewStorageIterator(SNAPSHOT_GID.Bytes)
  else
    Iterator := Db.NewStorageIterator(Gid.Bytes);

  try
    while Iterator.Next do
    begin
      if IsRegistrationInfoKey(Iterator.Key) then
      begin
        Registration := UnpackRegistration(Iterator.Value);
        if Filter then
        begin
          if Registration.IsActive then
            Result := Result + [Registration];
        end
        else
          Result := Result + [Registration];
      end;
    end;
  finally
    Iterator.Release;
  end;
end;

function GetAllRegistrationList(Db: IVmDb; Gid: TGid): TArray<TRegistration>;
begin
  Result := GetRegistrationList(Db, Gid, False);
end;

function GetCandidateList(Db: IVmDb; Gid: TGid): TArray<TRegistration>;
begin
  Result := GetRegistrationList(Db, Gid, True);
end;

function GetRegistrationList(Db: IVmDb; Gid: TGid; StakeAddr: TAddress): TArray<TRegistration>;
var
  Iterator: IStorageIterator;
  Registration: TRegistration;
begin
  Result := [];
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  if Gid.Compare(DELEGATE_GID) = 0 then
    Iterator := Db.NewStorageIterator(SNAPSHOT_GID.Bytes)
  else
    Iterator := Db.NewStorageIterator(Gid.Bytes);

  try
    while Iterator.Next do
    begin
      if IsRegistrationInfoKey(Iterator.Key) then
      begin
        Registration := UnpackRegistration(Iterator.Value);
        if Registration.StakeAddress.Compare(StakeAddr) = 0 then
          Result := Result + [Registration];
      end;
    end;
  finally
    Iterator.Release;
  end;
end;

function GetRegistrationListByRewardWithdrawAddr(Db: IVmDb; Gid: TGid; RewardWithdrawAddr: TAddress): TArray<TRegistration>;
var
  Names: TBytes;
  NameList: TArray<string>;
  SbpName: string;
  R: TRegistration;
begin
  Result := [];
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  if Gid.Compare(DELEGATE_GID) = 0 then
    Gid := SNAPSHOT_GID;

  Names := Db.GetValue(RewardWithdrawAddr.Bytes);
  if Length(Names) > 0 then
  begin
    NameList := TEncoding.UTF8.GetString(Names).Split([WithdrawRewardAddressSeparation]);
    for SbpName in NameList do
    begin
      R := GetRegistration(Db, Gid, SbpName);
      if R.Name <> '' then // Check if registration is valid
        Result := Result + [R];
    end;
  end;
end;

var RegisterInfoValuePrefix: TBytes;

function GetRegistration(Db: IVmDb; Gid: TGid; const Name: string): TRegistration;
var
  Value: TBytes;
begin
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Value := Db.GetValue(GetRegistrationInfoKey(Name, Gid));
  if Length(Value) = 0 then
  begin
    FillChar(Result, SizeOf(TRegistration), 0);
    Exit;
  end;
  Result := UnpackRegistration(Value);
end;

function UnpackRegistration(Value: TBytes): TRegistration;
var
  Registration: TRegistration;
begin
  if CompareMem(Pointer(Value), Pointer(RegisterInfoValuePrefix), Length(RegisterInfoValuePrefix)) then
  begin
    ABIDataGovernance.UnpackVariable(TValue.From<TRegistration>(Registration), VariableNameRegistrationInfo, Value);
    Registration.RewardWithdrawAddress := Registration.StakeAddress;
    Result := Registration;
  end
  else
  begin
    ABIDataGovernance.UnpackVariable(TValue.From<TRegistration>(Registration), VariableNameRegistrationInfoV2, Value);
    Result := Registration;
  end;
end;

function GetVote(Db: IVmDb; Gid: TGid; Addr: TAddress): TVoteInfo;
var
  Data: TBytes;
  SbpName: string;
begin
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  Data := Db.GetValue(GetVoteInfoKey(Addr, Gid));
  if Length(Data) > 0 then
  begin
    ABIDataGovernance.UnpackVariable(TValue.From<string>(SbpName), VariableNameVoteInfo, Data);
    Result.VoteAddr := Addr;
    Result.SbpName := SbpName;
  end
  else
  begin
    FillChar(Result, SizeOf(TVoteInfo), 0);
  end;
end;

function GetVoteList(Db: IVmDb; Gid: TGid): TArray<TVoteInfo>;
var
  Iterator: IStorageIterator;
  VoteAddr: TAddress;
  SbpName: string;
begin
  Result := [];
  if Db.Address.Compare(AddressGovernance) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  if Gid.Compare(DELEGATE_GID) = 0 then
    Iterator := Db.NewStorageIterator(GetVoteInfoKeyPerfixByGid(SNAPSHOT_GID))
  else
    Iterator := Db.NewStorageIterator(GetVoteInfoKeyPerfixByGid(Gid));

  try
    while Iterator.Next do
    begin
      if IsVoteInfoKey(Iterator.Key) then
      begin
        VoteAddr := GetAddrFromVoteInfoKey(Iterator.Key);
        ABIDataGovernance.UnpackVariable(TValue.From<string>(SbpName), VariableNameVoteInfo, Iterator.Value);
        Result := Result + [TVoteInfo.Create(VoteAddr, SbpName)];
      end;
    end;
  finally
    Iterator.Release;
  end;
end;

initialization
  ABIDataGovernance := TAbiContract.JSONToABIContract(TStringStream.Create(
    '[' +
    '{"type":"variable","name":"consensusGroupInfo","inputs":[{"name":"nodeCount","type":"uint8"},{"name":"interval","type":"int64"},{"name":"perCount","type":"int64"},{"name":"randCount","type":"uint8"},{"name":"randRank","type":"uint8"},{"name":"repeat","type":"uint16"},{"name":"checkLevel","type":"uint8"},{"name":"countingTokenId","type":"tokenId"},{"name":"registerConditionId","type":"uint8"},{"name":"registerConditionParam","type":"bytes"},{"name":"voteConditionId","type":"uint8"},{"name":"voteConditionParam","type":"bytes"},{"name":"owner","type":"address"},{"name":"stakeAmount","type":"uint256"},{"name":"expirationHeight","type":"uint64"}]},' +
    '{"type":"variable","name":"registerStakeParam","inputs":[{"name":"stakeAmount","type":"uint256"},{"name":"stakeToken","type":"tokenId"},{"name":"stakeHeight","type":"uint64"}]},' +
    '{"type":"function","name":"Register", "inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"},{"name":"blockProducingAddress","type":"address"}]},' +
    '{"type":"function","name":"RegisterSBP", "inputs":[{"name":"sbpName","type":"string"},{"name":"blockProducingAddress","type":"address"},{"name":"rewardWithdrawAddress","type":"address"}]},' +
    '{"type":"function","name":"UpdateRegistration", "inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"},{"name":"blockProducingAddress","type":"address"}]},' +
    '{"type":"function","name":"UpdateBlockProducingAddress", "inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"},{"name":"blockProducingAddress","type":"address"}]},' +
    '{"type":"function","name":"UpdateSBPBlockProducingAddress", "inputs":[{"name":"sbpName","type":"string"},{"name":"blockProducingAddress","type":"address"}]},' +
    '{"type":"function","name":"UpdateSBPRewardWithdrawAddress", "inputs":[{"name":"sbpName","type":"string"},{"name":"rewardWithdrawAddress","type":"address"}]},' +
    '{"type":"function","name":"CancelRegister","inputs":[{"name":"gid","type":"gid"}, {"name":"sbpName","type":"string"}]},' +
    '{"type":"function","name":"Revoke","inputs":[{"name":"gid","type":"gid"}, {"name":"sbpName","type":"string"}]},' +
    '{"type":"function","name":"RevokeSBP","inputs":[{"name":"sbpName","type":"string"}]},' +
    '{"type":"function","name":"Reward","inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"},{"name":"receiveAddress","type":"address"}]},' +
    '{"type":"function","name":"WithdrawReward","inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"},{"name":"receiveAddress","type":"address"}]},' +
    '{"type":"function","name":"WithdrawSBPReward","inputs":[{"name":"sbpName","type":"string"},{"name":"receiveAddress","type":"address"}]},' +
    '{"type":"variable","name":"registrationInfo","inputs":[{"name":"name","type":"string"},{"name":"blockProducingAddress","type":"address"},{"name":"stakeAddress","type":"address"},{"name":"amount","type":"uint256"},{"name":"expirationHeight","type":"uint64"},{"name":"rewardTime","type":"int64"},{"name":"revokeTime","type":"int64"},{"name":"hisAddrList","type":"address[]"}]},' +
    '{"type":"variable","name":"registrationInfoV2","inputs":[{"name":"name","type":"string"},{"name":"blockProducingAddress","type":"address"},{"name":"rewardWithdrawAddress","type":"address"},{"name":"stakeAddress","type":"address"},{"name":"amount","type":"uint256"},{"name":"expirationHeight","type":"uint64"},{"name":"rewardTime","type":"int64"},{"name":"revokeTime","type":"int64"},{"name":"hisAddrList","type":"address[]"}]},' +
    '{"type":"variable","name":"registeredHisName","inputs":[{"name":"name","type":"string"}]},' +
    '{"type":"function","name":"Vote", "inputs":[{"name":"gid","type":"gid"},{"name":"sbpName","type":"string"}]},' +
    '{"type":"function","name":"VoteForSBP", "inputs":[{"name":"sbpName","type":"string"}]},' +
    '{"type":"function","name":"CancelVote","inputs":[{"name":"gid","type":"gid"}]},' +
    '{"type":"function","name":"CancelSBPVoting","inputs":[]},' +
    '{"type":"variable","name":"voteInfo","inputs":[{"name":"sbpName","type":"string"}]}' +
    ']'));

  SetLength(GroupInfoKeyPrefix, 1);
  GroupInfoKeyPrefix[0] := 1;

  SetLength(VoteInfoKeyPrefix, 1);
  VoteInfoKeyPrefix[0] := 0;

  SetLength(RegisterInfoValuePrefix, 32);
  RegisterInfoValuePrefix[30] := 1;
end.
