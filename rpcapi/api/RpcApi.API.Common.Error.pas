unit RpcApi.Api.CommonError;

interface

uses
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
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
