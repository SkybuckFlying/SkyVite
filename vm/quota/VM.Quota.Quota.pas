unit VM.Quota.Quota;

interface

uses
  GoToDelphi.Helpers.BigInt,
  Common.Types,
  Interfaces.Core,
  System.Generics.Collections;

type
  TQuotaDb = interface
    ['{A6A7E2A3-5B3A-45B0-9A6E-0B2B2B2B2B2B}']
    function GetGlobalQuota: TQuotaInfo;
    function GetQuotaUsedList(const ParaAddress: TAddress): TArray<TQuotaInfo>;
    function GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<TAccountBlock>;
    function GetLatestAccountBlock(const ParaAddress: TAddress): TAccountBlock;
    function GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
  end;

  TCalcQuotaFunc = reference to function(const ParaDb: TQuotaDb; const ParaAddr: TAddress; const ParaStakeAmount: TBigInteger; const ParaDifficulty: TBigInteger; ParaSbHeight: UInt64): TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>;

  TQuotaConfigParams = record
    DifficultyList: TArray<TBigInteger>;
    StakeAmountList: TArray<TBigInteger>;
    QcIndexMin: UInt64;
    QcIndexMax: UInt64;
    QcMap: TDictionary<UInt64, TBigInteger>;
    CalcQuotaFunc: TCalcQuotaFunc;
  end;

var
  QuotaConfig: TQuotaConfigParams;

procedure InitQuotaConfig(ParaIsTest: Boolean; ParaIsTestParam: Boolean);
function CalcBlockQuotaUsed(const ParaDb: TQuotaDb; ParaBlock: TAccountBlock; ParaSbHeight: UInt64): UInt64;
function GetSnapshotCurrentQuota(const ParaDb: TQuotaDb; const ParaBeneficial: TAddress; const ParaStakeAmount: TBigInteger; ParaSbHeight: UInt64): UInt64;
function GetQuota(const ParaDb: TQuotaDb; const ParaBeneficial: TAddress; const ParaStakeAmount: TBigInteger; ParaSbHeight: UInt64): TQuota;
function GetQuotaForBlock(const ParaDb: TQuotaDb; const ParaAddr: TAddress; const ParaStakeAmount: TBigInteger; const ParaDifficulty: TBigInteger; ParaSbHeight: UInt64): TTuple<UInt64, UInt64>;
function CheckQuota(const ParaDb: TQuotaDb; const ParaQ: TQuota; const ParaAddr: TAddress): TTuple<Boolean, UInt64>;
function CanPoW(const ParaDb: TQuotaDb; const ParaAddress: TAddress): Boolean;
function CalcPoWDifficulty(const ParaDb: TQuotaDb; ParaQuotaRequired: UInt64; const ParaQ: TQuota; ParaSbHeight: UInt64): TBigInteger;
function CalcStakeAmountByQuota(ParaQ: UInt64): TBigInteger;
function CalcQc(const ParaDb: TQuotaDb; ParaSbHeight: UInt64): TTuple<TBigInteger, UInt64, Boolean>;

implementation

uses
  VM.Quota.Params,
  VM.Util,
  Common.Upgrade,
  System.SysUtils;

function isBlocked(db: TQuotaDb; addr: TAddress): TTuple<Boolean, UInt64, string>;
var
  prevBlock: TAccountBlock;
  confirmTime: UInt64;
begin
  if not IsContractAddr(addr) then
    Exit(TTuple<Boolean, UInt64, string>.Create(False, 0, ''));

  prevBlock := db.GetLatestAccountBlock(addr);
  if prevBlock = nil then
    Exit(TTuple<Boolean, UInt64, string>.Create(False, 0, ''));

  if prevBlock.BlockType = TBlockType.ReceiveError then
  begin
    confirmTime := db.GetConfirmedTimes(prevBlock.Hash);
    if confirmTime < ConstOutOfQuotaBlockTime then
      Exit(TTuple<Boolean, UInt64, string>.Create(True, ConstOutOfQuotaBlockTime - confirmTime, ''));
  end;
  Result := TTuple<Boolean, UInt64, string>.Create(False, 0, '');
end;

function calcQuotaTotal(db: TQuotaDb; addr: TAddress; stakeAmount: TBigInteger; difficulty: TBigInteger; sbHeight: UInt64): TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>;
var
  blocked: Boolean;
  blockReleaseHeight: UInt64;
  err: string;
  qc: TBigInteger;
  isCongestion: Boolean;
  quotaStake, quotaAddition, quotaTotal, quotaUsedTotal, blockCountTotal, snapshotCurrentQuota, quotaAvg, unconfirmedQuota: UInt64;
  quotaList: TArray<TQuotaInfo>;
  q: TQuotaInfo;
  i: Integer;
begin
  var tuple := isBlocked(db, addr);
  blocked := tuple.Item1;
  blockReleaseHeight := tuple.Item2;
  err := tuple.Item3;
  if err <> '' then
    Exit(TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(0, 0, 0, 0, 0, False, 0, err));

  var tuple2 := CalcQc(db, sbHeight);
  qc := tuple2.Item1;
  isCongestion := tuple2.Item3;

  quotaStake := calcStakeQuota(qc, isCongestion, stakeAmount);
  quotaAddition := calcPoWQuota(qc, isCongestion, difficulty);
  quotaList := db.GetQuotaUsedList(addr);
  quotaTotal := 0;
  quotaUsedTotal := 0;
  blockCountTotal := 0;
  if Length(quotaList) > 1 then
  begin
    for i := 0 to Length(quotaList) - 2 do
    begin
      q := quotaList[i];
      quotaTotal := quotaTotal + quotaStake;
      quotaUsedTotal := quotaUsedTotal + q.QuotaUsedTotal;
      blockCountTotal := blockCountTotal + q.BlockCount;
      if quotaTotal >= q.QuotaTotal then
        quotaTotal := quotaTotal - q.QuotaTotal
      else
        quotaTotal := 0;
    end;
  end;

  if Length(quotaList) > 0 then
  begin
    q := quotaList[High(quotaList)];
    quotaTotal := quotaTotal + quotaStake;
    snapshotCurrentQuota := quotaTotal;
    quotaUsedTotal := quotaUsedTotal + q.QuotaUsedTotal;
    blockCountTotal := blockCountTotal + q.BlockCount;
    unconfirmedQuota := q.QuotaTotal;
  end
  else
  begin
    snapshotCurrentQuota := quotaTotal;
    unconfirmedQuota := 0;
  end;

  if blockCountTotal > 0 then
    quotaAvg := quotaUsedTotal div blockCountTotal
  else
    quotaAvg := 0;

  if quotaTotal >= unconfirmedQuota then
    quotaTotal := quotaTotal - unconfirmedQuota
  else
    Exit(TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(0, quotaStake, 0, snapshotCurrentQuota, quotaAvg, blocked, blockReleaseHeight, ErrInvalidUnconfirmedQuota));

  if blocked then
    Exit(TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(0, quotaStake, 0, snapshotCurrentQuota, quotaAvg, blocked, blockReleaseHeight, ''));

  Result := TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(quotaTotal + quotaAddition, quotaStake, quotaAddition, snapshotCurrentQuota, quotaAvg, blocked, blockReleaseHeight, '');
end;

function calcStakeQuota(qc: TBigInteger; isCongestion: Boolean; stakeAmount: TBigInteger): UInt64;
var
  index: Integer;
begin
  if (stakeAmount = nil) or (stakeAmount.Sign <= 0) then
    Exit(0);

  stakeAmount := calcStakeParam(qc, isCongestion, stakeAmount);
  index := getIndexInBigIntList(stakeAmount, QuotaConfig.stakeAmountList, 0, ConstSectionLen);
  Result := calcQuotaByIndex(index);
end;

function CalcQuotaV3(const ParaDb: TQuotaDb; const ParaAddr: TAddress; const ParaStakeAmount: TBigInteger; const ParaDifficulty: TBigInteger; ParaSbHeight: UInt64): TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>;
var
  vPowFlag: Boolean;
  vCanPoW: Boolean;
begin
  vPowFlag := (ParaDifficulty <> nil) and (ParaDifficulty.Sign > 0);
  if vPowFlag then
  begin
    vCanPoW := CanPoW(ParaDb, ParaAddr);
    if not vCanPoW then
    begin
      Result := TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(0, 0, 0, 0, 0, False, 0, ErrCalcPoWTwice);
      Exit;
    end;
  end;
  Result := calcQuotaTotal(ParaDb, ParaAddr, ParaStakeAmount, ParaDifficulty, ParaSbHeight);
end;


procedure InitQuotaConfig(ParaIsTest: Boolean; ParaIsTestParam: Boolean);
var
  vStakeAmountList: TArray<TBigInteger>;
  vIndex: Integer;
  vStr: string;
begin
  if ParaIsTestParam then
  begin
    // Not implemented: quotaConfig.difficultyList := difficultyListTestnet
    SetLength(vStakeAmountList, Length(StakeAmountListTestnet));
    for vIndex := 0 to High(StakeAmountListTestnet) do
    begin
      vStr := StakeAmountListTestnet[vIndex];
      vStakeAmountList[vIndex] := TBigInteger.Create(vStr);
    end;
    QuotaConfig.StakeAmountList := vStakeAmountList;
  end
  else
  begin
    // Not implemented: quotaConfig.difficultyList := difficultyListMainnet
    SetLength(vStakeAmountList, Length(StakeAmountListMainnet));
    for vIndex := 0 to High(StakeAmountListMainnet) do
    begin
      vStr := StakeAmountListMainnet[vIndex];
      vStakeAmountList[vIndex] := TBigInteger.Create(vStr);
    end;
    QuotaConfig.StakeAmountList := vStakeAmountList;
  end;

  QuotaConfig.QcIndexMin := ConstQcIndexMinMainnet;
  QuotaConfig.QcIndexMax := ConstQcIndexMaxMainnet;
  QuotaConfig.QcMap := QcMapMainnet;

  if ParaIsTest then
  begin
    QuotaConfig.CalcQuotaFunc :=
      function(const ParaDb: TQuotaDb; const ParaAddr: TAddress; const ParaStakeAmount: TBigInteger; const ParaDifficulty: TBigInteger; ParaSbHeight: UInt64): TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>
      begin
        Result := TTuple<UInt64, UInt64, UInt64, UInt64, UInt64, Boolean, UInt64, string>.Create(75000000, 1000000, 0, 1000000, 0, False, 0, '');
      end;
  end
  else
  begin
    QuotaConfig.CalcQuotaFunc := CalcQuotaV3;
  end;
end;

function calcPoWQuotaByQc(db: TQuotaDb; difficulty: TBigInteger; sbHeight: UInt64): UInt64;
var
  index: Integer;
begin
  if (difficulty = nil) or (difficulty.Sign <= 0) then
    Exit(0);

  difficulty := calcStakeParamByQc(db, difficulty, sbHeight);
  index := getIndexInBigIntList(difficulty, QuotaConfig.difficultyList, 0, ConstSectionLen);
  Result := calcQuotaByIndex(index);
end;

function calcPoWQuota(qc: TBigInteger; isCongestion: Boolean; difficulty: TBigInteger): UInt64;
var
  index: Integer;
begin
  if (difficulty = nil) or (difficulty.Sign <= 0) then
    Exit(0);

  difficulty := calcStakeParam(qc, isCongestion, difficulty);
  index := getIndexInBigIntList(difficulty, QuotaConfig.difficultyList, 0, ConstSectionLen);
  Result := calcQuotaByIndex(index);
end;

function calcQuotaByIndex(index: Integer): UInt64;
begin
  if (index >= 0) and (index <= ConstSectionLen) then
    Result := UInt64(index) * ConstQuotaForSection
  else
    Result := 0;
end;

function getIndexByQuota(q: UInt64): Integer;
var
  index: Integer;
begin
  index := (q + ConstQuotaForSection - 1) div ConstQuotaForSection;
  if (index > ConstSectionLen) or (UInt64(index) * ConstQuotaForSection < q) then
    raise EQuotaException.Create(ErrBlockQuotaLimitReached);
  Result := index;
end;

function getIndexInBigIntList(x: TBigInteger; list: TArray<TBigInteger>; left, right: Integer): Integer;
var
  mid, cmp: Integer;
begin
  if left = right then
    Exit(getExactIndex(x, list, left));

  mid := (left + right + 1) div 2;
  cmp := list[mid].CompareTo(x);
  if cmp = 0 then
    Result := mid
  else if cmp > 0 then
    Result := getIndexInBigIntList(x, list, left, mid - 1)
  else
    Result := getIndexInBigIntList(x, list, mid, right);
end;

function getExactIndex(x: TBigInteger; list: TArray<TBigInteger>; index: Integer): Integer;
begin
  if (index = 0) or (list[index].CompareTo(x) <= 0) then
    Result := index
  else
    Result := index - 1;
end;

function calcStakeParamByQc(db: TQuotaDb; param: TBigInteger; sbHeight: UInt64): TBigInteger;
var
  qc: TBigInteger;
  isCongestion: Boolean;
  globalQuota: UInt64;
begin
  var tuple := CalcQc(db, sbHeight);
  qc := tuple.Item1;
  globalQuota := tuple.Item2;
  isCongestion := tuple.Item3;
  Result := calcStakeParam(qc, isCongestion, param);
end;

function calcStakeParam(qc: TBigInteger; isCongestion: Boolean; param: TBigInteger): TBigInteger;
var
  newParam: TBigInteger;
begin
  if not isCongestion then
    Exit(param);

  newParam := param * qc;
  newParam := newParam.Div(newParam, QcDivision);
  Result := newParam;
end;

function calcStakeTargetParam(qc: TBigInteger; isCongestion: Boolean; target: TBigInteger): TBigInteger;
var
  newTarget, calcTarget: TBigInteger;
begin
  newTarget := target * QcDivision;
  newTarget := newTarget.Div(newTarget, qc);
  // following for loop will only execute once
  while True do
  begin
    calcTarget := calcStakeParam(qc, isCongestion, newTarget);
    if calcTarget.CompareTo(target) >= 0 then
      break;
    newTarget := newTarget + TBigInteger.Create(1);
  end;
  if newTarget.BitLen <= 256 then
    Result := newTarget
  else
    raise EQuotaException.Create(ErrBlockQuotaLimitReached);
end;

function getMaxQuota: UInt64;
begin
  Result := UInt64(ConstSectionLen) * ConstQuotaForSection;
end;

function CalcPoWDifficulty(const ParaDb: TQuotaDb; ParaQuotaRequired: UInt64; const ParaQ: TQuota; ParaSbHeight: UInt64): TBigInteger;
var
  vIndex: Integer;
  vDifficulty, vDifficultyByQc: TBigInteger;
  vQc: TBigInteger;
begin
  if ParaQuotaRequired > ConstQuotaLimitForBlock then
    raise EQuotaException.Create(ErrBlockQuotaLimitReached);

  if ParaQ.Current >= ParaQuotaRequired then
    Exit(TBigInteger.Create(0));

  vIndex := getIndexByQuota(ParaQuotaRequired);

  vDifficulty := TBigInteger.Create(QuotaConfig.difficultyList[vIndex]);
  var tuple := calcStakeTargetParamByQc(ParaDb, vDifficulty, ParaSbHeight);
  vDifficultyByQc := tuple.Item1;
  vQc := tuple.Item2;
  Result := vDifficultyByQc;
end;

function CalcStakeAmountByQuota(ParaQ: UInt64): TBigInteger;
var
  vIndex: UInt64;
begin
  if ParaQ > getMaxQuota then
    raise EQuotaException.Create(ErrInvalidMethodParam);

  if ParaQ = 0 then
    Exit(TBigInteger.Create(0));

  vIndex := (ParaQ + ConstQuotaForSection - 1) div ConstQuotaForSection;
  Result := TBigInteger.Create(QuotaConfig.StakeAmountList[vIndex]);
end;


function CalcQc(const ParaDb: TQuotaDb; ParaSbHeight: UInt64): TTuple<TBigInteger, UInt64, Boolean>;
var
  vGlobalQuota: UInt64;
  vQcIndex: UInt64;
begin
  if not IsDexUpgrade(ParaSbHeight) then
    Exit(TTuple<TBigInteger, UInt64, Boolean>.Create(TBigInteger.Create(0), 0, False));

  vGlobalQuota := ParaDb.GetGlobalQuota.QuotaUsedTotal;
  vQcIndex := (vGlobalQuota + ConstQcGap - 1) div ConstQcGap;
  if vQcIndex < QuotaConfig.QcIndexMin then
    Result := TTuple<TBigInteger, UInt64, Boolean>.Create(QcDivision, vGlobalQuota, False)
  else
  begin
    if vQcIndex >= QuotaConfig.QcIndexMax then
      vQcIndex := QuotaConfig.QcIndexMax;
    Result := TTuple<TBigInteger, UInt64, Boolean>.Create(QuotaConfig.QcMap[vQcIndex], vGlobalQuota, True);
  end;
end;

end.
