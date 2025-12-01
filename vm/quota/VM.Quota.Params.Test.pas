unit VM.Quota.Params.Test;

interface

uses
  TestFramework,
  VM.Quota.Params;

type
  TTestVMQuotaParams = class(TTestCase)
  published
    procedure TestPrintParamAndSectionList;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  GoToDelphi.Helpers.BigInt,
  System.Generics.Collections;

procedure TTestVMQuotaParams.TestPrintParamAndSectionList;
var
  vQuotaLimit: Double;
  vSectionList: TList<TBigFloat>;
  vQ: Double;
  vIndex: Integer;
  vGapLow: Double;
  vFloatTmp: TBigFloat;
  vStakeAmountForOneTpsMainnet: TBigFloat;
  vDefaultSectionForStake: TBigFloat;
  vDefaultSectionForPoW: TBigFloat;
  vParamaForMainnet: string;
  vDefaultDifficultyForMainnet: TBigFloat;
  vParambForMainnet: string;
  vStakeAmountForOneTpsTestnet: TBigFloat;
  vParamaForTestnet: string;
  vDefaultDifficultyForTestnet: TBigFloat;
  vParambForTestnet: string;
begin
  vQuotaLimit := 1000000.0;
  vSectionList := TList<TBigFloat>.Create;
  try
    vQ := 0.0;
    vIndex := 0;
    while True do
    begin
      if vQ >= vQuotaLimit then
        break;
      vGapLow := Log(2.0 / (1.0 - vQ / vQuotaLimit) - 1.0);
      vSectionList.Add(TBigFloat.Create(vGapLow));
      Inc(vIndex);
      vQ := vQ + 280;
    end;

    vDefaultSectionForStake := vSectionList[75];
    vDefaultSectionForPoW := vSectionList[75];

    vFloatTmp := TBigFloat.Create(0);
    try
      vStakeAmountForOneTpsMainnet := TBigFloat.Create('9999');
      vStakeAmountForOneTpsMainnet := vStakeAmountForOneTpsMainnet * TBigFloat.Create(1000000000000000000); // AttovPerVite
      vFloatTmp := vDefaultSectionForStake / vStakeAmountForOneTpsMainnet;
      vParamaForMainnet := vFloatTmp.ToString;

      vDefaultDifficultyForMainnet := TBigFloat.Create(67108862);
      vFloatTmp := vDefaultSectionForPoW / vDefaultDifficultyForMainnet;
      vParambForMainnet := vFloatTmp.ToString;

      CheckEquals('4.201037667e-24', vParamaForMainnet, 'ParamaForMainnet does not match');
      CheckEquals('6.259408129e-10', vParambForMainnet, 'ParambForMainnet does not match');

      vStakeAmountForOneTpsTestnet := TBigFloat.Create('10');
      vStakeAmountForOneTpsTestnet := vStakeAmountForOneTpsTestnet * TBigFloat.Create(1000000000000000000); // AttovPerVite
      vFloatTmp := vDefaultSectionForStake / vStakeAmountForOneTpsTestnet;
      vParamaForTestnet := vFloatTmp.ToString;

      vDefaultDifficultyForTestnet := TBigFloat.Create(65534);
      vFloatTmp := vDefaultSectionForPoW / vDefaultDifficultyForTestnet;
      vParambForTestnet := vFloatTmp.ToString;

      CheckEquals('4.200617563e-21', vParamaForTestnet, 'ParamaForTestnet does not match');
      CheckEquals('6.409829346e-07', vParambForTestnet, 'ParambForTestnet does not match');

    finally
      vFloatTmp.Free;
    end;
  finally
    for vFloatTmp in vSectionList do
      vFloatTmp.Free;
    vSectionList.Free;
  end;
end;

initialization
  RegisterTest(TTestVMQuotaParams.Suite);
end.
