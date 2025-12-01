unit VM.Quota.Quota.Test;

interface

uses
  TestFramework,
  VM.Quota.Quota,
  Common.Types,
  Interfaces.Core,
  GoToDelphi.Helpers.BigInt,
  System.Generics.Collections;

type
  TTestQuotaDb = class(TInterfacedObject, TQuotaDb)
  private
    FAddr: TAddress;
    FQuotaList: TArray<TQuotaInfo>;
    FUnconfirmedBlockList: TArray<TAccountBlock>;
    FGlobalQuota: TQuotaInfo;
  public
    constructor Create(const ParaAddr: TAddress; const ParaQuotaList: TArray<TQuotaInfo>; const ParaUnconfirmedBlockList: TArray<TAccountBlock>; const ParaGlobalQuota: TQuotaInfo);
    function GetGlobalQuota: TQuotaInfo;
    function GetQuotaUsedList(const ParaAddress: TAddress): TArray<TQuotaInfo>;
    function GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<TAccountBlock>;
    function GetLatestAccountBlock(const ParaAddress: TAddress): TAccountBlock;
    function GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
  end;

  TTestVMQuota = class(TTestCase)
  published
    procedure TestCalcPoWDifficulty;
    procedure TestCanPoW;
    procedure TestCalcQuotaV3;
    procedure TestCalcQuotaForBlock;
    procedure TestCalcStakeAmountByUtps;
  end;

implementation

uses
  VM.Util,
  Common.Upgrade,
  System.SysUtils;

{ TTestQuotaDb }

constructor TTestQuotaDb.Create(const ParaAddr: TAddress; const ParaQuotaList: TArray<TQuotaInfo>; const ParaUnconfirmedBlockList: TArray<TAccountBlock>; const ParaGlobalQuota: TQuotaInfo);
begin
  FAddr := ParaAddr;
  FQuotaList := ParaQuotaList;
  FUnconfirmedBlockList := ParaUnconfirmedBlockList;
  FGlobalQuota := ParaGlobalQuota;
end;

function TTestQuotaDb.GetGlobalQuota: TQuotaInfo;
begin
  Result := FGlobalQuota;
end;

function TTestQuotaDb.GetQuotaUsedList(const ParaAddress: TAddress): TArray<TQuotaInfo>;
begin
  Result := FQuotaList;
end;

function TTestQuotaDb.GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<TAccountBlock>;
begin
  Result := FUnconfirmedBlockList;
end;

function TTestQuotaDb.GetLatestAccountBlock(const ParaAddress: TAddress): TAccountBlock;
begin
  if Length(FUnconfirmedBlockList) > 0 then
    Result := FUnconfirmedBlockList[High(FUnconfirmedBlockList)]
  else
    Result := nil;
end;

function TTestQuotaDb.GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
begin
  Result := 0;
end;

{ TTestVMQuota }

procedure TTestVMQuota.TestCalcPoWDifficulty;
var
  vTestCases: TArray<TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>>;
  vTestCase: TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>;
  vDb: TQuotaDb;
  vDifficulty: TBigInteger;
  vErr: string;
begin
  InitQuotaConfig(False, False);
  // initForkPointsForQuotaTest(t);
  vTestCases := [
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(1, 0, 1000001, TQuota.Create(0, 0, 0, 0, False, 0), nil, 'quota limit for block reached', 'block_quota_limit_reached_before_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(1, 0, 21000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('67108863'), '', 'no_stake_quota_before_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(1, 0, 22000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('70689140'), '', 'stake_quota_not_enough_before_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(1, 0, 21000, TQuota.Create(0, 21000, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_before_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(1, 0, 21000, TQuota.Create(0, 21001, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_2_before_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 1000001, TQuota.Create(0, 0, 0, 0, False, 0), nil, 'quota limit for block reached', 'block_quota_limit_reached_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 21000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('67108863'), '', 'no_stake_quota_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 22000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('70689140'), '', 'stake_quota_not_enough_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 21000, TQuota.Create(0, 21000, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 21000, TQuota.Create(0, 21001, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_2_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 0, 1000001, TQuota.Create(0, 0, 0, 0, False, 0), nil, 'quota limit for block reached', 'block_quota_limit_reached_with_congestion_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 74 * 51 * 21000, 21000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('67987247'), '', 'no_stake_quota_with_congestion_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 74 * 51 * 21000, 22000, TQuota.Create(0, 0, 0, 0, False, 0), TBigInteger.Create('71614386'), '', 'stake_quota_not_enough_with_congestion_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 74 * 51 * 21000, 21000, TQuota.Create(0, 21000, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_with_congestion_after_hardfork'),
    TTuple<UInt64, UInt64, UInt64, TQuota, TBigInteger, string, string>.Create(200, 74 * 51 * 21000, 21000, TQuota.Create(0, 21001, 0, 0, False, 0), TBigInteger.Create(0), '', 'current_quota_enough_2_with_congestion_after_hardfork')
  ];

  for vTestCase in vTestCases do
  begin
    vDb := TTestQuotaDb.Create(TAddress.Create, nil, nil, TQuotaInfo.Create(0, vTestCase.Item2, 0));
    try
      vDifficulty := CalcPoWDifficulty(vDb, vTestCase.Item3, vTestCase.Item4, vTestCase.Item1);
      vErr := '';
    except
      on E: Exception do
        vErr := E.Message;
    end;
    CheckEquals(vTestCase.Item6, vErr, vTestCase.Item7 + ' error not match');
    if vErr = '' then
      CheckEquals(0, vDifficulty.CompareTo(vTestCase.Item5), vTestCase.Item7 + ' difficulty not match');
  end;
end;

procedure TTestVMQuota.TestCanPoW;
var
  vTestCases: TArray<TTuple<TArray<TAccountBlock>, Boolean, string>>;
  vTestCase: TTuple<TArray<TAccountBlock>, Boolean, string>;
  vDb: TQuotaDb;
  vAddr: TAddress;
  vResult: Boolean;
begin
  vTestCases := [
    TTuple<TArray<TAccountBlock>, Boolean, string>.Create([], True, 'no_blocks'),
    TTuple<TArray<TAccountBlock>, Boolean, string>.Create([TAccountBlock.Create(TBlockType.Send, nil, nil, nil, nil, nil, nil, [1], nil, nil)], False, 'cannot_calc_pow1'),
    TTuple<TArray<TAccountBlock>, Boolean, string>.Create([TAccountBlock.Create, TAccountBlock.Create(TBlockType.Send, nil, nil, nil, nil, nil, nil, [1], nil, nil)], False, 'cannot_calc_pow2'),
    TTuple<TArray<TAccountBlock>, Boolean, string>.Create([TAccountBlock.Create], True, 'can_calc_pow1'),
    TTuple<TArray<TAccountBlock>, Boolean, string>.Create([TAccountBlock.Create, TAccountBlock.Create], True, 'can_calc_pow2')
  ];
  vAddr := TAddress.Create;
  for vTestCase in vTestCases do
  begin
    vDb := TTestQuotaDb.Create(vAddr, nil, vTestCase.Item1, TQuotaInfo.Create);
    vResult := CanPoW(vDb, vAddr);
    CheckEquals(vTestCase.Item2, vResult, vTestCase.Item3 + ' CanPoW failed');
  end;
end;

procedure TTestVMQuota.TestCalcQuotaV3;
begin
  // Not implemented
end;

procedure TTestVMQuota.TestCalcQuotaForBlock;
begin
  // Not implemented
end;

procedure TTestVMQuota.TestCalcStakeAmountByUtps;
begin
  // Not implemented
end;

initialization
  RegisterTest(TTestVMQuota.Suite);
end.
