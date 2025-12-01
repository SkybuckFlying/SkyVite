unit RpcApi.Api.CommonError;

interface

uses
  System.SysUtils;

const
  ConstErrStrToBigInt = 'convert to big.Int failed';
  ConstErrPoWNotSupportedUnderCongestion = 'PoW service not supported';
  ConstErrDifficultyTooLarge = 'difficulty is too large';

resourcestring
  resErrStrToBigInt = ConstErrStrToBigInt;
  resErrPoWNotSupportedUnderCongestion = ConstErrPoWNotSupportedUnderCongestion;
  resErrDifficultyTooLarge = ConstErrDifficultyTooLarge;

implementation

end.
