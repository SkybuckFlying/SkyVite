unit VM.Contracts.Dex.Fund.Stake;

interface

uses
  GoVite.Types GoVite.Interfaces GoVite.Ledger GoVite.VM.Util,
  System.BigInt System.SysUtils,
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
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Proto,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

const
  Stake = 0;

function HandleStakeAction(const ADB: IVmDb; AStakeType, AActionType: Byte; AAddress, APrincipal: TAddress; AAmount: TBigInteger; AStakeHeight: UInt64; ABlock: TAccountBlock): TArray<TAccountBlock>;
function DoCancelStakeV1(const ADB: IVmDb; AAddress: TAddress; AStakeType: Byte; AAmount: TBigInteger): TArray<TAccountBlock>;
function DoCancelStakeV2(const ADB: IVmDb; AAddress: TAddress; AId: THash): TArray<TAccountBlock>;
function DoRawCancelStakeV2(AId: THash): TArray<TAccountBlock>;
function IsVipStakingWithId(AStaking: TVIPStaking): Boolean;
function OnMiningStakeSuccess(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AAmount, AUpdatedAmount: TBigInteger): TError;
function OnMiningStakeSuccessV2(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AAmount, AUpdatedAmountV2: TBigInteger): TError;
function OnCancelMiningStakeSuccess(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AAmount, AUpdatedAmount: TBigInteger): TError;
function OnCancelMiningStakeSuccessV2(const ADB: IVmDb; const AReader: TConsensusReader; AAddress: TAddress; AAmount, AUpdatedAmountV2: TBigInteger): TError;
function GetStakeInfoList(const ADB: IVmDb; AStakeAddr: TAddress; AFilter: TFunc<TDelegateStakeAddressIndex, Boolean>): TPair<TArray<TDelegateStakeInfo>, TBigInteger>;
function GetStakeListByPage(const ADB: IStorageDatabase; ALastKey: TBytes; ACount: Integer): TTuple<TArray<TDelegateStakeInfo>, TBytes>;
function GetStakeForMiningV1ByPage(const ADB: IStorageDatabase; ALastKey: TBytes; ACount: Integer): TTuple<TArray<TAddress>, TBytes>;
function GetStakeForMiningV2ByPage(const ADB: IStorageDatabase; ALastKey: TBytes; ACount: Integer): TTuple<TArray<TAddress>, TBytes>;

implementation

uses
  System.Generics.Collections,
  VM.Contracts.ABI, VM.Contracts.Dex.Storage;

function stakeRequest(const ADB: IVmDb; AAddress, APrincipal: TAddress; AStakeType: Byte; AAmount: TBigInteger; AStakeHeight: UInt64): TBytes;
var
  LStakeData: TBytes;
  LStakeMethod: string;
begin
  case AStakeType of
    StakeForVIP:
      if Assigned(GetVIPStaking(ADB, AAddress)) then
        raise Exception.Create(VIPStakingExistsErr);
    StakeForSuperVIP:
      if Assigned(GetSuperVIPStaking(ADB, AAddress)) then
        raise Exception.Create(SuperVipStakingExistsErr);
    StakeForPrincipalSuperVIP:
      if Assigned(GetSuperVIPStaking(ADB, APrincipal)) then
        raise Exception.Create(SuperVipStakingExistsErr);
  end;

  ReduceAccount(ADB, AAddress, ViteTokenId.Bytes, AAmount);

  if IsEarthFork(ADB) then
  begin
    Result := ABIQuota.PackMethod(MethodNameStakeWithCallback, [AddressDexFund, AStakeHeight]);
  end
  else
  begin
    if IsLeafFork(ADB) then
      LStakeMethod := MethodNameDelegateStakeV2
    else
      LStakeMethod := MethodNameDelegateStake;
    Result := ABIQuota.PackMethod(LStakeMethod, [AAddress, AddressDexFund, AStakeType, AStakeHeight]);
  end;
end;

function composeCancelBlock(AMethodData: TBytes): TArray<TAccountBlock>;
begin
  SetLength(Result, 1);
  Result[0] := TAccountBlock.Create;
  Result[0].AccountAddress := AddressDexFund;
  Result[0].ToAddress := AddressQuota;
  Result[0].BlockType := BlockTypeSendCall;
  Result[0].TokenId := ViteTokenId;
  Result[0].Amount := TBigInteger.Zero;
  Result[0].Data := AMethodData;
end;

function HandleStakeAction(const ADB: IVmDb; AStakeType, AActionType: Byte; AAddress, APrincipal: TAddress; AAmount: TBigInteger; AStakeHeight: UInt64; ABlock: TAccountBlock): TArray<TAccountBlock>;
var
  LMethodData: TBytes;
  LBlocks: TArray<TAccountBlock>;
  LStakeId: THash;
begin
  if AActionType = Stake then
  begin
    LMethodData := stakeRequest(ADB, AAddress, APrincipal, AStakeType, AAmount, AStakeHeight);
    SetLength(LBlocks, 1);
    LBlocks[0] := TAccountBlock.Create;
    with LBlocks[0] do
    begin
      AccountAddress := AddressDexFund;
      ToAddress := AddressQuota;
      BlockType := BlockTypeSendCall;
      Amount := AAmount;
      TokenId := ViteTokenId;
      Data := LMethodData;
    end;
    if IsEarthFork(ADB) then
    begin
      LStakeId := ComputeSendBlockHash(ABlock, LBlocks[0], 0);
      SaveDelegateStakeInfo(ADB, LStakeId.Bytes, AStakeType, AAddress, APrincipal, AAmount);
    end;
    Result := LBlocks;
  end
  else
  begin
    Result := DoCancelStakeV1(ADB, AAddress, AStakeType, AAmount);
  end;
end;

// ... and so on for the rest of the file ...

end.
