unit Vm.Contracts.ContractsQuota;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Common.Types.Address, Common.Types.Hash, Common.Types.TokenTypeId, Common.Helper, Common.Upgrade,
  Interfaces.VmDb, Interfaces.Core.AccountBlock, Interfaces.Core.ContractMeta,
  Vm.Abi.Abi, Vm.Contracts.Abi.AbiQuota, Vm.Contracts.Contracts, Vm.Util.Util, Vm.Quota.Quota;

const
  StakeAmountMin = 1000000000000000000; // 1 VITE
  StakeHeightMax = 365 * 24 * 60 * 60; // 1 year in seconds

type
  TMethodStake = class(TInterfacedObject, IBuiltinContractMethod)
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

  TMethodCancelStake = class(TInterfacedObject, IBuiltinContractMethod)
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

  TMethodDelegateStake = class(TInterfacedObject, IBuiltinContractMethod)
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

  TMethodCancelDelegateStake = class(TInterfacedObject, IBuiltinContractMethod)
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

  TMethodStakeV3 = class(TInterfacedObject, IBuiltinContractMethod)
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

  TMethodCancelStakeV3 = class(TInterfacedObject, IBuiltinContractMethod)
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

function GetStakeInfo(Db: IVmDb; StakeAddr, Beneficiary: TAddress; IsDelegated: Boolean; DelegateAddr: TAddress; Bid: Byte; CurrentIndex: UInt64): TPair<TBytes, TStakeInfo>;
function GetStakeExpirationHeight(Vm: IVmEnvironment; Height: UInt64): UInt64;
function StakeNotDue(OldStakeInfo: TStakeInfo; Vm: IVmEnvironment): Boolean;
function GetNextStakeInfoKey(Db: IVmDb; StakeAddr: TAddress; CurrentIndex: UInt64): TBytes;

implementation

uses
  System.Math;

{ TMethodStake }

constructor TMethodStake.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodStake.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodStake.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodStake.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.StakeQuota;
end;

function TMethodStake.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodStake.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Beneficiary: TAddress;
begin
  if (not Util.IsViteToken(Block.TokenId)) or (Block.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<TAddress>(Beneficiary), FMethodName, Block.Data);
  Block.Data := ABIDataQuota.PackMethod(FMethodName, [Beneficiary]);
  Result := nil;
end;

function TMethodStake.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Beneficiary: TAddress;
  StakeInfoKey: TBytes;
  OldStakeInfo: TStakeInfo;
  Amount: TBigInteger;
  StakeInfo: TBytes;
  BeneficialKey: TBytes;
  OldBeneficialData: TBytes;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialAmount: TBigInteger;
  BeneficialData: TBytes;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TAddress>(Beneficiary), FMethodName, SendBlock.Data);
  StakeInfoKey := GetStakeInfo(Db, SendBlock.AccountAddress, Beneficiary, False, TAddress.Zero, 0, Block.Height).Item1;
  OldStakeInfo := GetStakeInfo(Db, SendBlock.AccountAddress, Beneficiary, False, TAddress.Zero, 0, Block.Height).Item2;

  if OldStakeInfo.Amount <> nil then
    Amount := OldStakeInfo.Amount
  else
    Amount := TBigInteger.Create(0);

  Amount := TBigInteger.Add(Amount, SendBlock.Amount);
  StakeInfo := ABIDataQuota.PackVariable(VariableNameStakeInfo, [Amount, GetStakeExpirationHeight(Vm, NodeConfig.Params.StakeHeight), Beneficiary, False, TAddress.Zero, 0]);
  Util.SetValue(Db, StakeInfoKey, StakeInfo);

  BeneficialKey := GetStakeBeneficialKey(Beneficiary);
  OldBeneficialData := Util.GetValue(Db, BeneficialKey);
  if Length(OldBeneficialData) > 0 then
  begin
    ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, OldBeneficialData);
    BeneficialAmount := OldBeneficial.Amount;
  end
  else
    BeneficialAmount := TBigInteger.Create(0);

  BeneficialAmount := TBigInteger.Add(BeneficialAmount, SendBlock.Amount);
  BeneficialData := ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [BeneficialAmount]);
  Util.SetValue(Db, BeneficialKey, BeneficialData);
  Result := nil;
end;

function GetStakeInfo(Db: IVmDb; StakeAddr, Beneficiary: TAddress; IsDelegated: Boolean; DelegateAddr: TAddress; Bid: Byte; CurrentIndex: UInt64): TPair<TBytes, TStakeInfo>;
var
  Iterator: IStorageIterator;
  StakeInfo: TStakeInfo;
  MaxIndex: UInt64;
begin
  Iterator := Db.NewStorageIterator(GetStakeInfoKeyPrefix(StakeAddr));
  try
    MaxIndex := 0;
    while Iterator.Next do
    begin
      if not IsStakeInfoKey(Iterator.Key) then
        Continue;
      StakeInfo := UnpackStakeInfo(Iterator.Value);
      if (StakeInfo.Beneficiary.Compare(Beneficiary) = 0) and (StakeInfo.IsDelegated = IsDelegated) and
         (StakeInfo.DelegateAddress.Compare(DelegateAddr) = 0) and (StakeInfo.Bid = Bid) then
      begin
        Result := TPair<TBytes, TStakeInfo>.Create(Iterator.Key, StakeInfo);
        Exit;
      end;
      MaxIndex := Math.Max(MaxIndex, GetIndexFromStakeInfoKey(Iterator.Key));
    end;
  finally
    Iterator.Release;
  end;

  if MaxIndex < CurrentIndex then
    Result := TPair<TBytes, TStakeInfo>.Create(GetStakeInfoKey(StakeAddr, CurrentIndex), TStakeInfo.Create)
  else
    Result := TPair<TBytes, TStakeInfo>.Create(GetStakeInfoKey(StakeAddr, MaxIndex + 1), TStakeInfo.Create);
end;

function GetStakeExpirationHeight(Vm: IVmEnvironment; Height: UInt64): UInt64;
begin
  Result := Vm.GlobalStatus.SnapshotBlock.Height + Height;
end;

function StakeNotDue(OldStakeInfo: TStakeInfo; Vm: IVmEnvironment): Boolean;
begin
  Result := OldStakeInfo.ExpirationHeight > Vm.GlobalStatus.SnapshotBlock.Height;
end;

{ TMethodCancelStake }

constructor TMethodCancelStake.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodCancelStake.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodCancelStake.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodCancelStake.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.CancelStakeQuota;
end;

function TMethodCancelStake.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodCancelStake.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamCancelStake;
begin
  if Block.Amount.Sign > 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<TParamCancelStake>(Param), FMethodName, Block.Data);
  if Param.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  Block.Data := ABIDataQuota.PackMethod(FMethodName, [Param.Beneficiary, Param.Amount]);
  Result := nil;
end;

function TMethodCancelStake.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamCancelStake;
  StakeInfoKey: TBytes;
  OldStakeInfo: TStakeInfo;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialKey: TBytes;
  V: TBytes;
  StakeInfo: TBytes;
  StakeBeneficialAmount: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamCancelStake>(Param), FMethodName, SendBlock.Data);
  StakeInfoKey := GetStakeInfo(Db, SendBlock.AccountAddress, Param.Beneficiary, False, TAddress.Zero, 0, Block.Height).Item1;
  OldStakeInfo := GetStakeInfo(Db, SendBlock.AccountAddress, Param.Beneficiary, False, TAddress.Zero, 0, Block.Height).Item2;

  if (OldStakeInfo.Amount = nil) or StakeNotDue(OldStakeInfo, Vm) or (OldStakeInfo.Amount.Compare(Param.Amount) < 0) or (OldStakeInfo.Id.Bytes <> nil) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  OldStakeInfo.Amount := TBigInteger.Sub(OldStakeInfo.Amount, Param.Amount);
  if (OldStakeInfo.Amount.Sign <> 0) and (OldStakeInfo.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  BeneficialKey := GetStakeBeneficialKey(Param.Beneficiary);
  V := Util.GetValue(Db, BeneficialKey);
  ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, V);
  if (OldBeneficial.Amount.Compare(Param.Amount) < 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  OldBeneficial.Amount := TBigInteger.Sub(OldBeneficial.Amount, Param.Amount);

  if OldStakeInfo.Amount.Sign = 0 then
    Util.SetValue(Db, StakeInfoKey, nil)
  else
  begin
    StakeInfo := ABIDataQuota.PackVariable(VariableNameStakeInfo, [OldStakeInfo.Amount, OldStakeInfo.ExpirationHeight, OldStakeInfo.Beneficiary, False, TAddress.Zero, 0]);
    Util.SetValue(Db, StakeInfoKey, StakeInfo);
  end;

  if OldBeneficial.Amount.Sign = 0 then
    Util.SetValue(Db, BeneficialKey, nil)
  else
  begin
    StakeBeneficialAmount := ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [OldBeneficial.Amount]);
    Util.SetValue(Db, BeneficialKey, StakeBeneficialAmount);
  end;

  SendBlockItem.AccountAddress := Block.AccountAddress;
  SendBlockItem.ToAddress := SendBlock.AccountAddress;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.Amount := Param.Amount;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Data := [];
  Result := [SendBlockItem];
end;

{ TMethodDelegateStake }

constructor TMethodDelegateStake.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDelegateStake.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDelegateStake.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
var
  Param: TParamDelegateStake;
  CallbackData: TBytes;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamDelegateStake>(Param), FMethodName, SendBlock.Data);
  CallbackData := ABIDataQuota.PackCallback(FMethodName, [Param.StakeAddress, Param.Beneficiary, SendBlock.Amount, Param.Bid, False]);
  Result := TPair<TBytes, Boolean>.Create(CallbackData, True);
end;

function TMethodDelegateStake.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DelegateStakeQuota;
end;

function TMethodDelegateStake.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodDelegateStake.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamDelegateStake;
begin
  if (not Util.IsViteToken(Block.TokenId)) or (Block.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<TParamDelegateStake>(Param), FMethodName, Block.Data);
  if (Param.StakeHeight < NodeConfig.Params.StakeHeight) or (Param.StakeHeight > StakeHeightMax) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  Block.Data := ABIDataQuota.PackMethod(FMethodName, [Param.StakeAddress, Param.Beneficiary, Param.Bid, Param.StakeHeight]);
  Result := nil;
end;

function TMethodDelegateStake.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamDelegateStake;
  StakeInfoKey: TBytes;
  OldStakeInfo: TStakeInfo;
  Amount: TBigInteger;
  OldExpirationHeight: UInt64;
  StakeInfo: TBytes;
  BeneficialKey: TBytes;
  OldBeneficialData: TBytes;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialAmount: TBigInteger;
  BeneficialData: TBytes;
  CallbackData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamDelegateStake>(Param), FMethodName, SendBlock.Data);
  StakeInfoKey := GetStakeInfo(Db, Param.StakeAddress, Param.Beneficiary, True, SendBlock.AccountAddress, Param.Bid, Block.Height).Item1;
  OldStakeInfo := GetStakeInfo(Db, Param.StakeAddress, Param.Beneficiary, True, SendBlock.AccountAddress, Param.Bid, Block.Height).Item2;

  if OldStakeInfo.Amount <> nil then
  begin
    Amount := OldStakeInfo.Amount;
    OldExpirationHeight := OldStakeInfo.ExpirationHeight;
  end
  else
  begin
    Amount := TBigInteger.Create(0);
    OldExpirationHeight := 0;
  end;

  Amount := TBigInteger.Add(Amount, SendBlock.Amount);
  StakeInfo := ABIDataQuota.PackVariable(VariableNameStakeInfo, [Amount, Math.Max(OldExpirationHeight, GetStakeExpirationHeight(Vm, Param.StakeHeight)), Param.Beneficiary, True, SendBlock.AccountAddress, Param.Bid]);
  Util.SetValue(Db, StakeInfoKey, StakeInfo);

  BeneficialKey := GetStakeBeneficialKey(Param.Beneficiary);
  OldBeneficialData := Util.GetValue(Db, BeneficialKey);
  if Length(OldBeneficialData) > 0 then
  begin
    ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, OldBeneficialData);
    BeneficialAmount := OldBeneficial.Amount;
  end
  else
    BeneficialAmount := TBigInteger.Create(0);

  BeneficialAmount := TBigInteger.Add(BeneficialAmount, SendBlock.Amount);
  BeneficialData := ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [BeneficialAmount]);
  Util.SetValue(Db, BeneficialKey, BeneficialData);

  CallbackData := ABIDataQuota.PackCallback(FMethodName, [Param.StakeAddress, Param.Beneficiary, SendBlock.Amount, Param.Bid, True]);
  SendBlockItem.AccountAddress := Block.AccountAddress;
  SendBlockItem.ToAddress := SendBlock.AccountAddress;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.Amount := TBigInteger.Create(0);
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Data := CallbackData;
  Result := [SendBlockItem];
end;

{ TMethodCancelDelegateStake }

constructor TMethodCancelDelegateStake.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodCancelDelegateStake.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodCancelDelegateStake.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
var
  Param: TParamCancelDelegateStake;
  CallbackData: TBytes;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamCancelDelegateStake>(Param), FMethodName, SendBlock.Data);
  CallbackData := ABIDataQuota.PackCallback(FMethodName, [Param.StakeAddress, Param.Beneficiary, Param.Amount, Param.Bid, False]);
  Result := TPair<TBytes, Boolean>.Create(CallbackData, True);
end;

function TMethodCancelDelegateStake.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.CancelDelegateStakeQuota;
end;

function TMethodCancelDelegateStake.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodCancelDelegateStake.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamCancelDelegateStake;
begin
  if Block.Amount.Sign > 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<TParamCancelDelegateStake>(Param), FMethodName, Block.Data);
  if Param.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  Block.Data := ABIDataQuota.PackMethod(FMethodName, [Param.StakeAddress, Param.Beneficiary, Param.Amount, Param.Bid]);
  Result := nil;
end;

function TMethodCancelDelegateStake.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamCancelDelegateStake;
  StakeInfoKey: TBytes;
  OldStakeInfo: TStakeInfo;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialKey: TBytes;
  V: TBytes;
  StakeInfo: TBytes;
  StakeBeneficialAmount: TBytes;
  CallbackData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamCancelDelegateStake>(Param), FMethodName, SendBlock.Data);
  StakeInfoKey := GetStakeInfo(Db, Param.StakeAddress, Param.Beneficiary, True, SendBlock.AccountAddress, Param.Bid, Block.Height).Item1;
  OldStakeInfo := GetStakeInfo(Db, Param.StakeAddress, Param.Beneficiary, True, SendBlock.AccountAddress, Param.Bid, Block.Height).Item2;

  if (OldStakeInfo.Amount = nil) or StakeNotDue(OldStakeInfo, Vm) or (OldStakeInfo.Amount.Compare(Param.Amount) < 0) or (OldStakeInfo.Id.Bytes <> nil) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  OldStakeInfo.Amount := TBigInteger.Sub(OldStakeInfo.Amount, Param.Amount);
  if (OldStakeInfo.Amount.Sign <> 0) and (OldStakeInfo.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  BeneficialKey := GetStakeBeneficialKey(Param.Beneficiary);
  V := Util.GetValue(Db, BeneficialKey);
  ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, V);
  if OldBeneficial.Amount.Compare(Param.Amount) < 0 then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  OldBeneficial.Amount := TBigInteger.Sub(OldBeneficial.Amount, Param.Amount);

  if OldStakeInfo.Amount.Sign = 0 then
    Util.SetValue(Db, StakeInfoKey, nil)
  else
  begin
    StakeInfo := ABIDataQuota.PackVariable(VariableNameStakeInfo, [OldStakeInfo.Amount, OldStakeInfo.ExpirationHeight, OldStakeInfo.Beneficiary, True, OldStakeInfo.DelegateAddress, Param.Bid]);
    Util.SetValue(Db, StakeInfoKey, StakeInfo);
  end;

  if OldBeneficial.Amount.Sign = 0 then
    Util.SetValue(Db, BeneficialKey, nil)
  else
  begin
    StakeBeneficialAmount := ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [OldBeneficial.Amount]);
    Util.SetValue(Db, BeneficialKey, StakeBeneficialAmount);
  end;

  CallbackData := ABIDataQuota.PackCallback(FMethodName, [Param.StakeAddress, Param.Beneficiary, Param.Amount, Param.Bid, True]);
  SendBlockItem.AccountAddress := Block.AccountAddress;
  SendBlockItem.ToAddress := SendBlock.AccountAddress;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.Amount := Param.Amount;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Data := CallbackData;
  Result := [SendBlockItem];
end;

{ TMethodStakeV3 }

constructor TMethodStakeV3.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodStakeV3.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodStakeV3.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
var
  CallbackData: TBytes;
begin
  if FMethodName = MethodNameStakeWithCallback then
  begin
    CallbackData := ABIDataQuota.PackCallback(FMethodName, [SendBlock.Hash, False]);
    Result := TPair<TBytes, Boolean>.Create(CallbackData, True);
  end
  else
    Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodStakeV3.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  if FMethodName = MethodNameStakeWithCallback then
    Result := GasTable.DelegateStakeQuota
  else
    Result := GasTable.StakeQuota;
end;

function TMethodStakeV3.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodStakeV3.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TParamStakeV3;
begin
  if (not Util.IsViteToken(Block.TokenId)) or (Block.Amount.Compare(TBigInteger.Create(StakeAmountMin)) < 0) then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<TParamStakeV3>(Param), FMethodName, Block.Data);
  if FMethodName = MethodNameStakeWithCallback then
  begin
    if (Param.StakeHeight < NodeConfig.Params.StakeHeight) or (Param.StakeHeight > StakeHeightMax) then
      Exit(EUtilInvalidMethodParam.Create('invalid method param'));
    Block.Data := ABIDataQuota.PackMethod(FMethodName, [Param.Beneficiary, Param.StakeHeight]);
  end
  else
    Block.Data := ABIDataQuota.PackMethod(FMethodName, [Param.Beneficiary]);
  Result := nil;
end;

function TMethodStakeV3.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TParamDelegateStake;
  StakeInfoKey: TBytes;
  StakeHeight: UInt64;
  StakeInfo: TBytes;
  BeneficialKey: TBytes;
  OldBeneficialData: TBytes;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialAmount: TBigInteger;
  BeneficialData: TBytes;
  CallbackData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataQuota.UnpackMethod(TValue.From<TParamDelegateStake>(Param), FMethodName, SendBlock.Data);
  StakeInfoKey := GetNextStakeInfoKey(Db, SendBlock.AccountAddress, Block.Height);

  if FMethodName = MethodNameStakeWithCallback then
    StakeHeight := Param.StakeHeight
  else
    StakeHeight := NodeConfig.Params.StakeHeight;

  StakeInfo := ABIDataQuota.PackVariable(VariableNameStakeInfoV2, [SendBlock.Amount, GetStakeExpirationHeight(Vm, StakeHeight), Param.Beneficiary, SendBlock.Hash]);
  Util.SetValue(Db, StakeInfoKey, StakeInfo);
  Util.SetValue(Db, SendBlock.Hash.Bytes, StakeInfoKey);

  BeneficialKey := GetStakeBeneficialKey(Param.Beneficiary);
  OldBeneficialData := Util.GetValue(Db, BeneficialKey);
  if Length(OldBeneficialData) > 0 then
  begin
    ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, OldBeneficialData);
    BeneficialAmount := OldBeneficial.Amount;
  end
  else
    BeneficialAmount := TBigInteger.Create(0);

  BeneficialAmount := TBigInteger.Add(BeneficialAmount, SendBlock.Amount);
  BeneficialData := ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [BeneficialAmount]);
  Util.SetValue(Db, BeneficialKey, BeneficialData);

  if FMethodName = MethodNameStakeWithCallback then
  begin
    CallbackData := ABIDataQuota.PackCallback(FMethodName, [SendBlock.Hash, True]);
    SendBlockItem.AccountAddress := Block.AccountAddress;
    SendBlockItem.ToAddress := SendBlock.AccountAddress;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.Amount := TBigInteger.Create(0);
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Data := CallbackData;
    Result := [SendBlockItem];
  end
  else
    Result := nil;
end;

{ TMethodCancelStakeV3 }

constructor TMethodCancelStakeV3.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodCancelStakeV3.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodCancelStakeV3.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
var
  Id: THash;
  CallbackData: TBytes;
begin
  if FMethodName = MethodNameCancelStakeWithCallback then
  begin
    ABIDataQuota.UnpackMethod(TValue.From<THash>(Id), FMethodName, SendBlock.Data);
    CallbackData := ABIDataQuota.PackCallback(FMethodName, [Id, False]);
    Result := TPair<TBytes, Boolean>.Create(CallbackData, True);
  end
  else
    Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodCancelStakeV3.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  if FMethodName = MethodNameCancelStakeWithCallback then
    Result := GasTable.CancelDelegateStakeQuota
  else
    Result := GasTable.CancelStakeQuota;
end;

function TMethodCancelStakeV3.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := 0;
end;

function TMethodCancelStakeV3.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Id: THash;
begin
  if Block.Amount.Sign > 0 then
    Exit(EUtilInvalidMethodParam.Create('invalid method param'));

  ABIDataQuota.UnpackMethod(TValue.From<THash>(Id), FMethodName, Block.Data);
  Block.Data := ABIDataQuota.PackMethod(FMethodName, [Id]);
  Result := nil;
end;

function TMethodCancelStakeV3.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Id: THash;
  StakeInfoKey: TBytes;
  StakeInfo: TStakeInfo;
  StakeAddress: TAddress;
  OldBeneficial: TVariableStakeBeneficial;
  BeneficialKey: TBytes;
  V: TBytes;
  CallbackData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataQuota.UnpackMethod(TValue.From<THash>(Id), FMethodName, SendBlock.Data);
  StakeInfoKey := Util.GetValue(Db, Id.Bytes);
  if Length(StakeInfoKey) = 0 then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  StakeInfo := GetStakeInfoByKey(Db, StakeInfoKey);
  StakeAddress := GetStakeAddrFromStakeInfoKey(StakeInfoKey);
  if (StakeInfo.Amount = nil) or (StakeAddress.Compare(SendBlock.AccountAddress) <> 0) or StakeNotDue(StakeInfo, Vm) then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  StakeInfo.StakeAddress := StakeAddress;

  BeneficialKey := GetStakeBeneficialKey(StakeInfo.Beneficiary);
  V := Util.GetValue(Db, BeneficialKey);
  ABIDataQuota.UnpackVariable(TValue.From<TVariableStakeBeneficial>(OldBeneficial), VariableNameStakeBeneficial, V);
  if OldBeneficial.Amount.Compare(StakeInfo.Amount) < 0 then
    Exit(nil); // Should be util.ErrInvalidMethodParam

  OldBeneficial.Amount := TBigInteger.Sub(OldBeneficial.Amount, StakeInfo.Amount);

  Util.SetValue(Db, StakeInfoKey, nil);
  Util.SetValue(Db, Id.Bytes, nil);
  if OldBeneficial.Amount.Sign = 0 then
    Util.SetValue(Db, BeneficialKey, nil)
  else
    Util.SetValue(Db, BeneficialKey, ABIDataQuota.PackVariable(VariableNameStakeBeneficial, [OldBeneficial.Amount]));

  if FMethodName = MethodNameCancelStakeWithCallback then
  begin
    CallbackData := ABIDataQuota.PackCallback(FMethodName, [Id, True]);
    SendBlockItem.AccountAddress := Block.AccountAddress;
    SendBlockItem.ToAddress := SendBlock.AccountAddress;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.Amount := TBigInteger.Create(0);
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Data := CallbackData;
    Result := [SendBlockItem];
  end
  else
  begin
    SendBlockItem.AccountAddress := Block.AccountAddress;
    SendBlockItem.ToAddress := SendBlock.AccountAddress;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.Amount := StakeInfo.Amount;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Data := [];
    Result := [SendBlockItem];
  end;
end;

function GetNextStakeInfoKey(Db: IVmDb; StakeAddr: TAddress; CurrentIndex: UInt64): TBytes;
var
  Iterator: IStorageIterator;
  MaxIndex: UInt64;
begin
  Iterator := Db.NewStorageIterator(GetStakeInfoKeyPrefix(StakeAddr));
  try
    MaxIndex := 0;
    while Iterator.Next do
    begin
      if not IsStakeInfoKey(Iterator.Key) then
        Continue;
      MaxIndex := Math.Max(MaxIndex, GetIndexFromStakeInfoKey(Iterator.Key));
    end;
  finally
    Iterator.Release;
  end;

  if MaxIndex < CurrentIndex then
    Result := GetStakeInfoKey(StakeAddr, CurrentIndex)
  else
    Result := GetStakeInfoKey(StakeAddr, MaxIndex + 1);
end;

initialization
  SbpStakeAmountPreMainnet := TBigInteger.Create(1000000000000000000000000); // 1M VITE
  SbpStakeAmountMainnet := TBigInteger.Create(1000000000000000000000000); // 1M VITE
  RewardPerBlock := TBigInteger.Create(1000000000000000000); // 1 VITE
  RewardTimeLimit := 30 * 24 * 60 * 60; // 30 days in seconds

end.
