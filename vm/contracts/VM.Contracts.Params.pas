unit VM.Contracts.Params;

interface

uses
  System.BigInt;

type
  TContractsParams = record
    StakeHeight: UInt64;
    DexVipStakeHeight: UInt64;
    DexSuperVipStakeHeight: UInt64;
  end;

const
  CG_NODE_COUNT_MIN: Byte = 3;
  CG_NODE_COUNT_MAX: Byte = 101;
  CG_INTERVAL_MIN: Int64 = 1;
  CG_INTERVAL_MAX: Int64 = 10 * 60;
  CG_PER_COUNT_MIN: Int64 = 1;
  CG_PER_COUNT_MAX: Int64 = 10 * 60;
  CG_PER_INTERVAL_MIN: Int64 = 1;
  CG_PER_INTERVAL_MAX: Int64 = 10 * 60;

  REGISTRATION_NAME_LENGTH_MAX = 40;
  TOKEN_NAME_LENGTH_MAX = 40;
  TOKEN_SYMBOL_LENGTH_MAX = 10;
  TOKEN_NAME_INDEX_MAX: Word = 1000;
  REWARD_TIME_LIMIT: Int64 = 3600;
  STAKE_HEIGHT_MAX: UInt64 = 3600 * 24 * 365;

var
  SbpStakeAmountPreMainnet: TBigInteger;
  SbpStakeAmountMainnet: TBigInteger;
  RewardPerBlock: TBigInteger;
  StakeAmountMin: TBigInteger;
  IssueFee: TBigInteger;

  ContractsParamsTest: TContractsParams;
  ContractsParamsMainNet: TContractsParams;

implementation

uses
  GoVite.VM.Util; // Assumed to contain AttovPerVite

initialization
  SbpStakeAmountPreMainnet := TBigInteger.Multiply(TBigInteger.Create(5e5), AttovPerVite);
  SbpStakeAmountMainnet := TBigInteger.Multiply(TBigInteger.Create(1e6), AttovPerVite);
  RewardPerBlock := TBigInteger.Parse('951293759512937595');
  StakeAmountMin := TBigInteger.Multiply(TBigInteger.Create(134), AttovPerVite);
  IssueFee := TBigInteger.Multiply(TBigInteger.Create(1e3), AttovPerVite);

  ContractsParamsTest := TContractsParams.Create(
    StakeHeight: 600,
    DexVipStakeHeight: 600,
    DexSuperVipStakeHeight: 600
  );

  ContractsParamsMainNet := TContractsParams.Create(
    StakeHeight: 3600 * 24 * 3,
    DexVipStakeHeight: 3600 * 24 * 30,
    DexSuperVipStakeHeight: 3600 * 24 * 30
  );

end.
