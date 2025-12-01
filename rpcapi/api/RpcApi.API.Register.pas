unit RpcApi.Api.Register;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.Types, Common.BigInt, Ledger.Chain, Ledger.Consensus, Log15,
  Vm.Contracts, Vm.Contracts.Abi, Vm.Util;

type
  TRegistrationInfo = record
    Name: string;
    NodeAddr: TAddress;
    PledgeAddr: TAddress;
    RewardWithdrawAddress: TAddress;
    PledgeAmount: string;
    WithdrawHeight: string;
    WithdrawTime: Int64;
    CancelTime: Int64;
  end;

  TReward = record
    BlockReward: string;
    VoteReward: string;
    TotalReward: string;
    BlockNum: string;
    ExpectedBlockNum: string;
    Drained: Boolean;
  end;

  TRewardInfo = record
    RewardMap: TDictionary<string, TReward>;
    StartTime: Int64;
    EndTime: Int64;
  end;

  TRegistParam = record
    Name: string;
    Gid: PGid;
  end;

  TCandidateInfo = record
    Name: string;
    NodeAddr: TAddress;
    VoteNum: string;
  end;

  TRegisterApi = class
  private
    FChain: IChain;
    FCs: IConsensus;
    FLog: ILogger;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function GetRegisterData(const Gid: TGid; const Name: string; const NodeAddr: TAddress): TBytes;
    function GetCancelRegisterData(const Gid: TGid; const Name: string): TBytes;
    function GetRewardData(const Gid: TGid; const Name: string; const BeneficialAddr: TAddress): TBytes;
    function GetUpdateRegistrationData(const Gid: TGid; const Name: string; const NodeAddr: TAddress): TBytes;
    // Deprecated
    function GetRegistrationList(const Gid: TGid; const PledgeAddr: TAddress): TArray<TRegistrationInfo>;
    function GetAvailableReward(const Gid: TGid; const Name: string): TReward;
    function GetRewardByDay(const Gid: TGid; Timestamp: Int64): TDictionary<string, TReward>;
    function GetRewardByIndex(const Gid: TGid; const IndexStr: string): TRewardInfo;
    function GetRegistration(const Name: string; const Gid: TGid): PRegistration;
    function GetRegisterPledgeAddrList(const ParamList: TArray<TRegistParam>): TArray<PAddress>;
    function GetCandidateList: TArray<TCandidateInfo>;
  end;

implementation

uses System.StrUtils, System.DateUtils, Vm.Db;

function BigIntToString(B: PBigInt): PString;
var
  S: string;
begin
  if B = nil then
    Exit(nil);
  S := B.ToString;
  Result := @S;
end;

function Uint64ToString(U: UInt64): string;
begin
  Result := IntToStr(U);
end;

function StringToUint64(S: string): UInt64;
begin
  Result := StrToInt(S);
end;

function GetVmDb(Chain: IChain; Addr: TAddress): IVmDb;
begin
  // Simplified
  Result := TVmDb.Create(Chain, @Addr, nil, nil);
end;

function ByRegistrationExpirationHeightSort(const A, B: PRegistration): Integer;
begin
  if A.ExpirationHeight = B.ExpirationHeight then
  begin
    if A.RevokeTime = B.RevokeTime then
      Result := CompareStr(B.Name, A.Name)
    else if A.RevokeTime > B.RevokeTime then
      Result := -1
    else
      Result := 1;
  end
  else if A.ExpirationHeight > B.ExpirationHeight then
    Result := -1
  else
    Result := 1;
end;

function ToReward(Source: PReward): TReward;
begin
  if Source = nil then
  begin
    Result.TotalReward := '0';
    Result.VoteReward := '0';
    Result.BlockReward := '0';
    Result.BlockNum := '0';
    Result.ExpectedBlockNum := '0';
  end
  else
  begin
    Result.TotalReward := BigIntToString(@Source.TotalReward)^;
    Result.VoteReward := BigIntToString(@Source.VoteReward)^;
    Result.BlockReward := BigIntToString(@Source.BlockReward)^;
    Result.BlockNum := Uint64ToString(Source.BlockNum);
    Result.ExpectedBlockNum := Uint64ToString(Source.ExpectedBlockNum);
  end;
end;

{ TRegisterApi }

constructor TRegisterApi.Create(AVite: TVite);
begin
  FChain := AVite.Chain;
  FCs := AVite.Consensus;
  FLog := TLog.New('module', 'rpc_api/register_api');
end;

function TRegisterApi.GetString: string;
begin
  Result := 'RegisterApi';
end;

function TRegisterApi.GetRegisterData(const Gid: TGid; const Name: string; const NodeAddr: TAddress): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbi.MethodNameRegister, [Gid, Name, NodeAddr]);
end;

function TRegisterApi.GetCancelRegisterData(const Gid: TGid; const Name: string): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbi.MethodNameRevoke, [Gid, Name]);
end;

function TRegisterApi.GetRewardData(const Gid: TGid; const Name: string; const BeneficialAddr: TAddress): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbi.MethodNameWithdrawReward, [Gid, Name, BeneficialAddr]);
end;

function TRegisterApi.GetUpdateRegistrationData(const Gid: TGid; const Name: string; const NodeAddr: TAddress): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbi.MethodNameUpdateBlockProducingAddress, [Gid, Name, NodeAddr]);
end;

function TRegisterApi.GetRegistrationList(const Gid: TGid; const PledgeAddr: TAddress): TArray<TRegistrationInfo>;
var
  Db: IVmDb;
  SnapshotBlock: PSnapshotBlock;
  List: TArray<PRegistration>;
  TargetList: TArray<TRegistrationInfo>;
  I: Integer;
  Info: PRegistration;
begin
  Db := GetVmDb(FChain, TAddress.Governance);
  SnapshotBlock := Db.LatestSnapshotBlock;
  List := TAbi.GetRegistrationList(Db, Gid, PledgeAddr);
  SetLength(TargetList, Length(List));
  if Length(List) > 0 then
  begin
    TArray.Sort<PRegistration>(List, ByRegistrationExpirationHeightSort);
    for I := 0 to High(List) do
    begin
      Info := List[I];
      TargetList[I].Name := Info.Name;
      TargetList[I].NodeAddr := Info.BlockProducingAddress;
      TargetList[I].PledgeAddr := Info.StakeAddress;
      TargetList[I].RewardWithdrawAddress := Info.RewardWithdrawAddress;
      TargetList[I].PledgeAmount := BigIntToString(@Info.Amount)^;
      TargetList[I].WithdrawHeight := Uint64ToString(Info.ExpirationHeight);
      TargetList[I].WithdrawTime := GetWithdrawTime(SnapshotBlock.Timestamp, SnapshotBlock.Height, Info.ExpirationHeight);
      TargetList[I].CancelTime := Info.RevokeTime;
    end;
  end;
  Result := TargetList;
end;

function TRegisterApi.GetAvailableReward(const Gid: TGid; const Name: string): TReward;
var
  Db: IVmDb;
  Info: PRegistration;
  Sb: PSnapshotBlock;
  Reward: PReward;
  Drained: Boolean;
begin
  Db := GetVmDb(FChain, TAddress.Governance);
  Info := TAbi.GetRegistration(Db, Gid, Name);
  if Info = nil then
    Exit;
  Sb := Db.LatestSnapshotBlock;
  TContracts.CalcReward(TUtil.NewVMConsensusReader(FCs.SBPReader), Db, Info, Sb, Reward, Drained);
  Result := ToReward(Reward);
  Result.Drained := TContracts.RewardDrained(Reward, Drained);
end;

function TRegisterApi.GetRewardByDay(const Gid: TGid; Timestamp: Int64): TDictionary<string, TReward>;
var
  Db: IVmDb;
  M: TDictionary<string, PReward>;
  Index: UInt64;
  RewardMap: TDictionary<string, TReward>;
  Name: string;
  Reward: PReward;
begin
  Db := GetVmDb(FChain, TAddress.Governance);
  TContracts.CalcRewardByCycle(Db, TUtil.NewVMConsensusReader(FCs.SBPReader), Timestamp, M, Index);
  RewardMap := TDictionary<string, TReward>.Create;
  for Name in M.Keys do
  begin
    Reward := M[Name];
    RewardMap.Add(Name, ToReward(Reward));
  end;
  Result := RewardMap;
end;

function TRegisterApi.GetRewardByIndex(const Gid: TGid; const IndexStr: string): TRewardInfo;
var
  Index: UInt64;
  Db: IVmDb;
  M: TDictionary<string, PReward>;
  RewardMap: TDictionary<string, TReward>;
  Name: string;
  Reward: PReward;
  StartTime, EndTime: TDateTime;
begin
  Index := StringToUint64(IndexStr);
  Db := GetVmDb(FChain, TAddress.Governance);
  M := TContracts.CalcRewardByIndex(Db, TUtil.NewVMConsensusReader(FCs.SBPReader), Index);
  RewardMap := TDictionary<string, TReward>.Create;
  for Name in M.Keys do
  begin
    Reward := M[Name];
    RewardMap.Add(Name, ToReward(Reward));
  end;
  FCs.SBPReader.GetDayTimeIndex.Index2Time(Index, StartTime, EndTime);
  Result.RewardMap := RewardMap;
  Result.StartTime := Round(StartTime);
  Result.EndTime := Round(EndTime);
end;

function TRegisterApi.GetRegistration(const Name: string; const Gid: TGid): PRegistration;
var
  Db: IVmDb;
begin
  Db := GetVmDb(FChain, TAddress.Governance);
  Result := TAbi.GetRegistration(Db, Gid, Name);
end;

function TRegisterApi.GetRegisterPledgeAddrList(const ParamList: TArray<TRegistParam>): TArray<PAddress>;
var
  Db: IVmDb;
  AddrList: TArray<PAddress>;
  K: Integer;
  V: TRegistParam;
  R: PRegistration;
begin
  if Length(ParamList) = 0 then
    Exit;
  Db := GetVmDb(FChain, TAddress.Governance);
  SetLength(AddrList, Length(ParamList));
  for K := 0 to High(ParamList) do
  begin
    V := ParamList[K];
    if (V.Gid = nil) or (V.Gid^ = TTypes.DELEGATE_GID) then
      R := TAbi.GetRegistration(Db, TTypes.SNAPSHOT_GID, V.Name)
    else
      R := TAbi.GetRegistration(Db, V.Gid^, V.Name);
    if R <> nil then
      AddrList[K] := @R.StakeAddress;
  end;
  Result := AddrList;
end;

function TRegisterApi.GetCandidateList: TArray<TCandidateInfo>;
var
  Head: PSnapshotBlock;
  Details: TArray<TVoteDetail>;
  VoteMap: TDictionary<string, TVoteDetail>;
  Res: TArray<TCandidateInfo>;
  V: TVoteDetail;
begin
  Head := FChain.GetLatestSnapshotBlock;
  FCs.API.ReadVoteMap(IncSecond(Head.Timestamp), VoteMap);
  SetLength(Res, VoteMap.Count);
  var I := 0;
  for V in VoteMap.Values do
  begin
    Res[I].Name := V.Name;
    Res[I].NodeAddr := V.CurrentAddr;
    Res[I].VoteNum := BigIntToString(@V.VoteNum)^;
    Inc(I);
  end;
  Result := Res;
end;

end.
