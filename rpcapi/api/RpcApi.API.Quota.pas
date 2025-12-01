unit RpcApi.Api.Quota;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.Types, Common.BigInt, Ledger.Chain, Log15, Vm.Contracts.Abi,
  Vm.Quota, Vm.Util, Ledger;

type
  TAgentPledgeParam = record
    PledgeAddr: TAddress;
    BeneficialAddr: TAddress;
    Bid: Byte;
    StakeHeight: string;
    Amount: string;
  end;

  TQuotaAndTxNum = record
    QuotaPerSnapshotBlock: string;
    CurrentQuota: string;
    CurrentTxNumPerSec: string;
    CurrentUt: string;
    Utpe: string;
    PledgeAmount: string;
  end;

  TPledgeInfo = record
    Amount: string;
    BeneficialAddr: TAddress;
    WithdrawHeight: string;
    WithdrawTime: Int64;
    Agent: Boolean;
    AgentAddress: TAddress;
    Bid: Byte;
    Id: PHash;
  end;

  TPledgeInfoList = record
    TotalPledgeAmount: string;
    Count: Integer;
    List: TArray<TPledgeInfo>;
  end;

  TPledgeQueryParams = record
    PledgeAddr: TAddress;
    AgentAddr: TAddress;
    BeneficialAddr: TAddress;
    Bid: Byte;
  end;

  TQuotaCoefficientInfo = record
    Qc: PString;
    GlobalQuota: string;
    GlobalUt: string;
    IsCongestion: Boolean;
  end;

  TQuotaApi = class
  private
    FChain: IChain;
    FLog: ILogger;
    FLedgerApi: TLedgerApi;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function GetPledgeData(const BeneficialAddr: TAddress): TBytes;
    function GetCancelPledgeData(const BeneficialAddr: TAddress; const Amount: string): TBytes;
    function GetAgentPledgeData(const Param: TAgentPledgeParam): TBytes;
    function GetAgentCancelPledgeData(const Param: TAgentPledgeParam): TBytes;
    function GetQuotaUsedList(const Addr: TAddress): TArray<TQuotaInfo>;
    function GetQuotaCoefficient: TQuotaCoefficientInfo;
    // Deprecated
    function GetAgentPledgeInfo(const Params: TPledgeQueryParams): TPledgeInfo;
    function GetPledgeAmountByUtps(const Utps: string): PString;
    function GetPledgeList(const Addr: TAddress; Index, Count: Integer): TPledgeInfoList;
    function GetPledgeBeneficialAmount(const Addr: TAddress): string;
    function GetPledgeQuota(const Addr: TAddress): TQuotaAndTxNum;
  end;

implementation

uses System.StrUtils, System.Math, Vm.Db;

function StringToBigInt(S: PString): TBigInteger;
begin
  Result := TBigInteger.Create;
  if S <> nil then
    Result.SetString(S^, 10);
end;

function StringToFloat64(S: string): Double;
begin
  Result := StrToFloat(S);
end;

function Uint64ToString(U: UInt64): string;
begin
  Result := IntToStr(U);
end;

function Float64ToString(D: Double; Prec: Integer): string;
begin
  Result := FloatToStrF(D, ffFixed, 18, Prec);
end;

function BigIntToString(B: PBigInt): PString;
var
  S: string;
begin
  if B = nil then
    Exit(nil);
  S := B.ToString;
  Result := @S;
end;

function GetVmDb(Chain: IChain; Addr: TAddress): IVmDb;
begin
  // Simplified
  Result := TVmDb.Create(Chain, @Addr, nil, nil);
end;

function NewPledgeInfo(Info: PStakeInfo; SnapshotBlock: PSnapshotBlock): TPledgeInfo;
begin
  Result.Amount := BigIntToString(Info.Amount)^;
  Result.BeneficialAddr := Info.Beneficiary;
  Result.WithdrawHeight := Uint64ToString(Info.ExpirationHeight);
  Result.WithdrawTime := GetWithdrawTime(SnapshotBlock.Timestamp, SnapshotBlock.Height, Info.ExpirationHeight);
  Result.Agent := Info.IsDelegated;
  Result.AgentAddress := Info.DelegateAddress;
  Result.Bid := Info.Bid;
  Result.Id := Info.Id;
end;

function ByExpirationHeightSort(const A, B: PStakeInfo): Integer;
begin
  if A.ExpirationHeight = B.ExpirationHeight then
    Result := CompareStr(A.Beneficiary.ToString, B.Beneficiary.ToString)
  else if A.ExpirationHeight < B.ExpirationHeight then
    Result := -1
  else
    Result := 1;
end;

{ TQuotaApi }

constructor TQuotaApi.Create(AVite: TVite);
begin
  FChain := AVite.Chain;
  FLog := TLog.New('module', 'rpc_api/quota_api');
  FLedgerApi := TLedgerApi.Create(AVite);
end;

function TQuotaApi.GetString: string;
begin
  Result := 'QuotaApi';
end;

function TQuotaApi.GetPledgeData(const BeneficialAddr: TAddress): TBytes;
begin
  Result := TAbiQuota.PackMethod(TAbi.MethodNameStake, [BeneficialAddr]);
end;

function TQuotaApi.GetCancelPledgeData(const BeneficialAddr: TAddress; const Amount: string): TBytes;
var
  BAmount: TBigInteger;
begin
  BAmount := StringToBigInt(@Amount);
  Result := TAbiQuota.PackMethod(TAbi.MethodNameCancelStake, [BeneficialAddr, BAmount]);
end;

function TQuotaApi.GetAgentPledgeData(const Param: TAgentPledgeParam): TBytes;
var
  StakeHeight: UInt64;
begin
  StakeHeight := StrToUInt64(Param.StakeHeight);
  Result := TAbiQuota.PackMethod(TAbi.MethodNameDelegateStake, [Param.PledgeAddr, Param.BeneficialAddr, Param.Bid, StakeHeight]);
end;

function TQuotaApi.GetAgentCancelPledgeData(const Param: TAgentPledgeParam): TBytes;
var
  BAmount: TBigInteger;
begin
  BAmount := StringToBigInt(@Param.Amount);
  Result := TAbiQuota.PackMethod(TAbi.MethodNameCancelDelegateStake, [Param.PledgeAddr, Param.BeneficialAddr, BAmount, Param.Bid]);
end;

function TQuotaApi.GetQuotaUsedList(const Addr: TAddress): TArray<TQuotaInfo>;
var
  Db: IVmDb;
begin
  Db := GetVmDb(FChain, TAddress.Quota);
  Result := Db.GetQuotaUsedList(Addr);
end;

function TQuotaApi.GetQuotaCoefficient: TQuotaCoefficientInfo;
var
  Qc: TBigInteger;
  GlobalQuota: UInt64;
  IsCongestion: Boolean;
begin
  TQuota.CalcQc(FChain, FChain.GetLatestSnapshotBlock.Height, Qc, GlobalQuota, IsCongestion);
  Result.Qc := BigIntToString(@Qc);
  Result.GlobalQuota := Uint64ToString(GlobalQuota);
  Result.GlobalUt := Float64ToString(GlobalQuota / 21000 / 74, 2);
  Result.IsCongestion := IsCongestion;
end;

function TQuotaApi.GetAgentPledgeInfo(const Params: TPledgeQueryParams): TPledgeInfo;
var
  Db: IVmDb;
  SnapshotBlock: PSnapshotBlock;
  Info: PStakeInfo;
begin
  Db := GetVmDb(FChain, TAddress.Quota);
  SnapshotBlock := Db.LatestSnapshotBlock;
  Info := TAbi.GetStakeInfo(Db, Params.PledgeAddr, Params.BeneficialAddr, Params.AgentAddr, True, Params.Bid);
  if Info = nil then
    Exit;
  Result := NewPledgeInfo(Info, SnapshotBlock);
end;

function TQuotaApi.GetPledgeAmountByUtps(const Utps: string): PString;
var
  UtpfF: Double;
  Q: UInt64;
  Amount: TBigInteger;
begin
  UtpfF := StringToFloat64(Utps);
  Q := Ceil(UtpfF * TQuota.QuotaPerUt);
  Amount := TQuota.CalcStakeAmountByQuota(Q);
  Result := BigIntToString(@Amount);
end;

function TQuotaApi.GetPledgeList(const Addr: TAddress; Index, Count: Integer): TPledgeInfoList;
var
  Db: IVmDb;
  List: TArray<PStakeInfo>;
  Amount: TBigInteger;
  StartHeight, EndHeight: Integer;
  TargetList: TArray<TPledgeInfo>;
  SnapshotBlock: PSnapshotBlock;
  I: Integer;
  Info: PStakeInfo;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  Db := GetVmDb(FChain, TAddress.Quota);
  TAbi.GetStakeInfoList(Db, Addr, List, Amount);
  TArray.Sort<PStakeInfo>(List, ByExpirationHeightSort);
  StartHeight := Index * Count;
  EndHeight := (Index + 1) * Count;
  if StartHeight >= Length(List) then
  begin
    Result.TotalPledgeAmount := BigIntToString(@Amount)^;
    Result.Count := Length(List);
    SetLength(Result.List, 0);
    Exit;
  end;
  if EndHeight > Length(List) then
    EndHeight := Length(List);
  SetLength(TargetList, EndHeight - StartHeight);
  SnapshotBlock := Db.LatestSnapshotBlock;
  for I := 0 to High(TargetList) do
  begin
    Info := List[StartHeight + I];
    TargetList[I] := NewPledgeInfo(Info, SnapshotBlock);
  end;
  Result.TotalPledgeAmount := BigIntToString(@Amount)^;
  Result.Count := Length(List);
  Result.List := TargetList;
end;

function TQuotaApi.GetPledgeBeneficialAmount(const Addr: TAddress): string;
var
  Amount: TBigInteger;
begin
  Amount := FChain.GetStakeBeneficialAmount(Addr);
  Result := BigIntToString(@Amount)^;
end;

function TQuotaApi.GetPledgeQuota(const Addr: TAddress): TQuotaAndTxNum;
var
  Amount: TBigInteger;
  Q: TQuota;
begin
  FChain.GetStakeQuota(Addr, Amount, Q);
  Result.QuotaPerSnapshotBlock := Uint64ToString(Q.StakeQuotaPerSnapshotBlock);
  Result.CurrentQuota := Uint64ToString(Q.Current);
  Result.CurrentTxNumPerSec := Uint64ToString(Q.Current div TQuota.QuotaPerUt);
  Result.CurrentUt := Float64ToString(Q.Current / TQuota.QuotaPerUt, 4);
  Result.Utpe := Float64ToString(Q.StakeQuotaPerSnapshotBlock * TUtil.QuotaAccumulationBlockCount / TQuota.QuotaPerUt, 4);
  Result.PledgeAmount := BigIntToString(@Amount)^;
end;

end.
