unit Vm.Contracts.Abi.AbiQuota;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vm.Abi.Abi, Common.Types.Address, Common.Types.Hash, Common.Types.TokenTypeId,
  Interfaces.VmDb, Common.Types.Contracts, Vm.Util.Util;

const
  MethodNameStake = 'Pledge';
  MethodNameStakeV2 = 'Stake';
  MethodNameStakeV3 = 'StakeForQuota';
  MethodNameCancelStake = 'CancelPledge';
  MethodNameCancelStakeV2 = 'CancelStake';
  MethodNameCancelStakeV3 = 'CancelQuotaStaking';
  MethodNameDelegateStake = 'AgentPledge';
  MethodNameDelegateStakeV2 = 'DelegateStake';
  MethodNameCancelDelegateStake = 'AgentCancelPledge';
  MethodNameCancelDelegateStakeV2 = 'CancelDelegateStake';
  MethodNameStakeWithCallback = 'StakeForQuotaWithCallback';
  MethodNameCancelStakeWithCallback = 'CancelQuotaStakingWithCallback';
  VariableNameStakeInfo = 'stakeInfo';
  VariableNameStakeInfoV2 = 'stakeInfoV2';
  VariableNameStakeBeneficial = 'stakeBeneficial';

var
  ABIDataQuota: TAbiContract;

  StakeInfoKeySize: Integer;
  StakeInfoValueSize: Integer;

type
  TVariableStakeBeneficial = record
    Amount: TBigInteger;
  end;

  TParamCancelStake = record
    Beneficiary: TAddress;
    Amount: TBigInteger;
  end;

  TParamDelegateStake = record
    StakeAddress: TAddress;
    Beneficiary: TAddress;
    Bid: Byte;
    StakeHeight: UInt64;
  end;

  TParamStakeV3 = record
    StakeAddress: TAddress;
    Beneficiary: TAddress;
    StakeHeight: UInt64;
  end;

  TParamCancelDelegateStake = record
    StakeAddress: TAddress;
    Beneficiary: TAddress;
    Amount: TBigInteger;
    Bid: Byte;
  end;

function GetStakeBeneficialKey(Beneficial: TAddress): TBytes;
function GetStakeInfoKey(Addr: TAddress; Index: UInt64): TBytes;
function GetStakeInfoKeyPrefix(Addr: TAddress): TBytes;
function IsStakeInfoKey(Key: TBytes): Boolean;
function GetStakeAddrFromStakeInfoKey(Key: TBytes): TAddress;
function GetIndexFromStakeInfoKey(Key: TBytes): UInt64;
function GetStakeInfoList(Db: IVmDb; StakeAddr: TAddress): TPair<TArray<TStakeInfo>, TBigInteger>;
function GetStakeExpirationHeight(Db: IVmDb; List: TArray<TStakeInfo>): TArray<TStakeInfo>;
function GetStakeBeneficialAmount(Db: IVmDb; Beneficial: TAddress): TBigInteger;
function GetStakeInfo(Db: IVmDb; StakeAddr, Beneficiary, DelegateAddr: TAddress; IsDelegated: Boolean; Bid: Byte): TStakeInfo;
function GetStakeInfoByKey(Db: IVmDb; StakeInfoKey: TBytes): TStakeInfo;
function GetStakeInfoById(Db: IVmDb; Id: TBytes): TStakeInfo;
function UnpackStakeInfo(Value: TBytes): TStakeInfo;
function GetStakeListByPage(Db: IVmDb; LastKey: TBytes; Count: UInt64): TPair<TArray<TStakeInfo>, TBytes>;

implementation

uses
  Common.Helper;

function GetStakeBeneficialKey(Beneficial: TAddress): TBytes;
begin
  Result := Beneficial.Bytes;
end;

function GetStakeInfoKey(Addr: TAddress; Index: UInt64): TBytes;
begin
  Result := Addr.Bytes + LeftPadBytes(TBigInteger.Create(Index).ToByteArray, 8);
end;

function GetStakeInfoKeyPrefix(Addr: TAddress): TBytes;
begin
  Result := Addr.Bytes;
end;

function IsStakeInfoKey(Key: TBytes): Boolean;
begin
  Result := Length(Key) = StakeInfoKeySize;
end;

function GetStakeAddrFromStakeInfoKey(Key: TBytes): TAddress;
begin
  Result := BytesToAddress(Copy(Key, 0, AddressSize));
end;

function GetIndexFromStakeInfoKey(Key: TBytes): UInt64;
begin
  Result := TBigInteger.FromByteArray(Copy(Key, AddressSize, Length(Key) - AddressSize)).ToUInt64;
end;

function GetStakeInfoList(Db: IVmDb; StakeAddr: TAddress): TPair<TArray<TStakeInfo>, TBigInteger>;
var
  StakeAmount: TBigInteger;
  Iterator: IStorageIterator;
  StakeInfo: TStakeInfo;
begin
  Result := TPair<TArray<TStakeInfo>, TBigInteger>.Create([], TBigInteger.Create(0));
  if Db.Address.Compare(AddressQuota) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  StakeAmount := TBigInteger.Create(0);
  Iterator := Db.NewStorageIterator(GetStakeInfoKeyPrefix(StakeAddr));
  try
    while Iterator.Next do
    begin
      if IsStakeInfoKey(Iterator.Key) then
      begin
        StakeInfo := UnpackStakeInfo(Iterator.Value);
        if (StakeInfo.Amount <> nil) and (StakeInfo.Amount.Sign > 0) and (not StakeInfo.IsDelegated) then
        begin
          Result.Item1 := Result.Item1 + [StakeInfo];
          StakeAmount := TBigInteger.Add(StakeAmount, StakeInfo.Amount);
        end;
      end;
    end;
  finally
    Iterator.Release;
  end;
  Result.Item2 := StakeAmount;
end;

function GetStakeExpirationHeight(Db: IVmDb; List: TArray<TStakeInfo>): TArray<TStakeInfo>;
var
  S: TStakeInfo;
  StakeInfo: TStakeInfo;
begin
  Result := List;
  if Db.Address.Compare(AddressQuota) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  for S in Result do
  begin
    if S.Id.Bytes = nil then
      StakeInfo := GetStakeInfo(Db, S.StakeAddress, S.Beneficiary, S.DelegateAddress, S.IsDelegated, S.Bid)
    else
      StakeInfo := GetStakeInfoById(Db, S.Id.Bytes);

    if StakeInfo.Amount = nil then // Check if stakeInfo is valid
      raise EUtilChainForked.Create('chain forked')
    else
      S.ExpirationHeight := StakeInfo.ExpirationHeight;
  end;
end;

function GetStakeBeneficialAmount(Db: IVmDb; Beneficial: TAddress): TBigInteger;
var
  V: TBytes;
  Amount: TVariableStakeBeneficial;
begin
  if Db.Address.Compare(AddressQuota) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');
  V := Db.GetValue(GetStakeBeneficialKey(Beneficial));
  if Length(V) = 0 then
    Result := TBigInteger.Create(0)
  else
  begin
    ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(Amount), VariableNameStakeBeneficial, V);
    Result := Amount.Amount;
  end;
end;

function GetStakeInfo(Db: IVmDb; StakeAddr, Beneficiary, DelegateAddr: TAddress; IsDelegated: Boolean; Bid: Byte): TStakeInfo;
var
  Iterator: IStorageIterator;
  StakeInfo: TStakeInfo;
begin
  if Db.Address.Compare(AddressQuota) <> 0 then
    raise EUtilAddressNotMatch.Create('address not match');

  Iterator := Db.NewStorageIterator(GetStakeInfoKeyPrefix(StakeAddr));
  try
    while Iterator.Next do
    begin
      if IsStakeInfoKey(Iterator.Key) then
      begin
        StakeInfo := UnpackStakeInfo(Iterator.Value);
        if (StakeInfo.Beneficiary.Compare(Beneficiary) = 0) and (StakeInfo.IsDelegated = IsDelegated) and
           (StakeInfo.DelegateAddress.Compare(DelegateAddr) = 0) and (StakeInfo.Bid = Bid) then
        begin
          Result := StakeInfo;
          Exit;
        end;
      end;
    end;
  finally
    Iterator.Release;
  end;
  FillChar(Result, SizeOf(TStakeInfo), 0);
end;

function GetStakeInfoByKey(Db: IVmDb; StakeInfoKey: TBytes): TStakeInfo;
var
  Value: TBytes;
begin
  Value := Db.GetValue(StakeInfoKey);
  if Length(Value) = 0 then
  begin
    FillChar(Result, SizeOf(TStakeInfo), 0);
    Exit;
  end;
  Result := UnpackStakeInfo(Value);
end;

function GetStakeInfoById(Db: IVmDb; Id: TBytes): TStakeInfo;
var
  StoreKey: TBytes;
  Value: TBytes;
begin
  if Length(Id) <> HashSize then
    raise EUtilInvalidMethodParam.Create('invalid method param');

  StoreKey := Db.GetValue(Id);
  if Length(StoreKey) = 0 then
    raise EUtilDataNotExist.Create('data not exist');

  Value := Db.GetValue(StoreKey);
  if Length(Value) = 0 then
    raise EUtilDataNotExist.Create('data not exist');

  Result := UnpackStakeInfo(Value);
end;

function UnpackStakeInfo(Value: TBytes): TStakeInfo;
var
  StakeInfo: TStakeInfo;
begin
  if Length(Value) = StakeInfoValueSize then
  begin
    ABIDataQuota.UnpackVariable(TValue.From<TStakeInfo>(StakeInfo), VariableNameStakeInfo, Value);
  end
  else
  begin
    StakeInfo.Id := THash.Zero;
    ABIDataQuota.UnpackVariable(TValue.From<TStakeInfo>(StakeInfo), VariableNameStakeInfoV2, Value);
  end;
  Result := StakeInfo;
end;

function GetStakeListByPage(Db: IVmDb; LastKey: TBytes; Count: UInt64): TPair<TArray<TStakeInfo>, TBytes>;
var
  Iterator: IStorageIterator;
  StakeInfo: TStakeInfo;
begin
  Result := TPair<TArray<TStakeInfo>, TBytes>.Create([], []);
  Iterator := Db.NewStorageIterator([]);
  try
    if Length(LastKey) > 0 then
    begin
      if not Iterator.Seek(LastKey) then
        Exit;
    end;

    while Iterator.Next do
    begin
      if IsStakeInfoKey(Iterator.Key) then
      begin
        StakeInfo := UnpackStakeInfo(Iterator.Value);
        StakeInfo.StakeAddress := GetStakeAddrFromStakeInfoKey(Iterator.Key);
        Result.Item1 := Result.Item1 + [StakeInfo];
        Dec(Count);
        if Count = 0 then
          Break;
      end;
    end;
    Result.Item2 := Iterator.Key;
  finally
    Iterator.Release;
  end;
end;

initialization
  ABIDataQuota := TAbiContract.JSONToABIContract(TStringStream.Create(
    '[' +
    '{"type":"function","name":"Pledge", "inputs":[{"name":"beneficiary","type":"address"}]},' +
    '{"type":"function","name":"Stake", "inputs":[{"name":"beneficiary","type":"address"}]},' +
    '{"type":"function","name":"StakeForQuota", "inputs":[{"name":"beneficiary","type":"address"}]},' +
    '{"type":"function","name":"CancelPledge","inputs":[{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"}]},' +
    '{"type":"function","name":"CancelStake","inputs":[{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"}]},' +
    '{"type":"function","name":"CancelQuotaStaking","inputs":[{"name":"id","type":"bytes32"}]},' +
    '{"type":"function","name":"AgentPledge", "inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"bid","type":"uint8"},{"name":"stakeHeight","type":"uint64"}]},' +
    '{"type":"function","name":"DelegateStake", "inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"bid","type":"uint8"},{"name":"stakeHeight","type":"uint64"}]},' +
    '{"type":"function","name":"StakeForQuotaWithCallback", "inputs":[{"name":"beneficiary","type":"address"},{"name":"stakeHeight","type":"uint64"}]},' +
    '{"type":"function","name":"AgentCancelPledge","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"}]},' +
    '{"type":"function","name":"CancelDelegateStake","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"}]},' +
    '{"type":"function","name":"CancelQuotaStakingWithCallback","inputs":[{"name":"id","type":"bytes32"}]},' +
    '{"type":"callback","name":"AgentPledge","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"},{"name":"success","type":"bool"}]},' +
    '{"type":"callback","name":"DelegateStake","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"},{"name":"success","type":"bool"}]},' +
    '{"type":"callback","name":"StakeForQuotaWithCallback", "inputs":[{"name":"id","type":"bytes32"},{"name":"success","type":"bool"}]},' +
    '{"type":"callback","name":"AgentCancelPledge","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"},{"name":"success","type":"bool"}]},' +
    '{"type":"callback","name":"CancelDelegateStake","inputs":[{"name":"stakeAddress","type":"address"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"bid","type":"uint8"},{"name":"success","type":"bool"}]},' +
    '{"type":"callback","name":"CancelQuotaStakingWithCallback", "inputs":[{"name":"id","type":"bytes32"},{"name":"success","type":"bool"}]},' +
    '{"type":"variable","name":"stakeInfo","inputs":[{"name":"amount","type":"uint256"},{"name":"expirationHeight","type":"uint64"},{"name":"beneficiary","type":"address"},{"name":"isDelegated","type":"bool"},{"name":"delegateAddress","type":"address"},{"name":"bid","type":"uint8"}]},' +
    '{"type":"variable","name":"stakeInfoV2","inputs":[{"name":"amount","type":"uint256"},{"name":"expirationHeight","type":"uint64"},{"name":"beneficiary","type":"address"},{"name":"id","type":"bytes32"}]},' +
    '{"type":"variable","name":"stakeBeneficial","inputs":[{"name":"amount","type":"uint256"}]}' +
    ']'));

  StakeInfoKeySize := AddressSize + 8;
  StakeInfoValueSize := 192;
end.
