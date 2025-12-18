unit vm.util.errors;

interface

uses
  SysUtils,
  VM.Util.Common,
  VM.Util.Consensus.Reader,
  VM.Util.DB.Helper,
  VM.Util.IntPool,
  VM.Util.Intpool.Test,
  VM.Util.Quota,
  VM.Util.Quota.Test,
  VM.Util.Types;

var
  ErrInvalidMethodParam: Exception;
  ErrInvalidQuotaMultiplier: Exception;
  ErrRewardIsNotDrained: Exception;
  ErrInsufficientBalance: Exception;
  ErrCalcPoWTwice: Exception;
  ErrAbiMethodNotFound: Exception;
  ErrInvalidResponseLatency: Exception;
  ErrInvalidRandomDegree: Exception;
  ErrAddressNotMatch: Exception;
  ErrTransactionTypeNotSupport: Exception;
  ErrVersionNotSupport: Exception;
  ErrBlockTypeNotSupported: Exception;
  ErrDataNotExist: Exception;
  ErrContractNotExists: Exception;
  ErrNoReliableStatus: Exception;
  ErrSBPNotExists: Exception;
  ErrAddressCollision: Exception;
  ErrIDCollision: Exception;
  ErrRewardNotDue: Exception;
  ErrExecutionReverted: Exception;
  ErrDepth: Exception;
  ErrGasUintOverflow: Exception;
  ErrStorageModifyLimitReached: Exception;
  ErrMemSizeOverflow: Exception;
  ErrReturnDataOutOfBounds: Exception;
  ErrBlockQuotaLimitReached: Exception;
  ErrAccountQuotaLimitReached: Exception;
  ErrOutOfQuota: Exception;
  ErrInvalidCodeLength: Exception;
  ErrInvalidUnconfirmedQuota: Exception;
  ErrStackLimitReached: Exception;
  ErrStackUnderflow: Exception;
  ErrInvalidJumpDestination: Exception;
  ErrInvalidOpCode: Exception;
  ErrChainForked: Exception;
  ErrContractCreationFail: Exception;
  ErrExecutionCanceled: Exception;

procedure DealWithErr(v: TObject);

implementation

initialization
  ErrInvalidMethodParam := Exception.Create('invalid method param');
  ErrInvalidQuotaMultiplier := Exception.Create('invalid quota multiplier');
  ErrRewardIsNotDrained := Exception.Create('reward is not drained');
  ErrInsufficientBalance := Exception.Create('insufficient balance for transfer');
  ErrCalcPoWTwice := Exception.Create('calc PoW twice referring to one snapshot block');
  ErrAbiMethodNotFound := Exception.Create('abi: method not found');
  ErrInvalidResponseLatency := Exception.Create('invalid response latency');
  ErrInvalidRandomDegree := Exception.Create('invalid random degree');
  ErrAddressNotMatch := Exception.Create('current address not match');
  ErrTransactionTypeNotSupport := Exception.Create('transaction type not supported');
  ErrVersionNotSupport := Exception.Create('feature not supported in current snapshot height');
  ErrBlockTypeNotSupported := Exception.Create('block type not supported');
  ErrDataNotExist := Exception.Create('data not exist');
  ErrContractNotExists := Exception.Create('contract not exists');
  ErrNoReliableStatus := Exception.Create('no reliable status');
  ErrSBPNotExists := Exception.Create('sbp name does not exists');
  ErrAddressCollision := Exception.Create('contract address collision');
  ErrIDCollision := Exception.Create('id collision');
  ErrRewardNotDue := Exception.Create('reward not due');
  ErrExecutionReverted := Exception.Create('execution reverted');
  ErrDepth := Exception.Create('max call depth exceeded');
  ErrGasUintOverflow := Exception.Create('gas uint64 overflow');
  ErrStorageModifyLimitReached := Exception.Create('contract storage modify count limit reached');
  ErrMemSizeOverflow := Exception.Create('memory size uint64 overflow');
  ErrReturnDataOutOfBounds := Exception.Create('vm: return data out of bounds');
  ErrBlockQuotaLimitReached := Exception.Create('quota limit for block reached');
  ErrAccountQuotaLimitReached := Exception.Create('quota limit for account reached');
  ErrOutOfQuota := Exception.Create('out of quota');
  ErrInvalidCodeLength := Exception.Create('invalid code length');
  ErrInvalidUnconfirmedQuota := Exception.Create('calc quota failed, invalid unconfirmed quota');
  ErrStackLimitReached := Exception.Create('stack limit reached');
  ErrStackUnderflow := Exception.Create('stack underflow');
  ErrInvalidJumpDestination := Exception.Create('invalid jump destination');
  ErrInvalidOpCode := Exception.Create('invalid opcode');
  ErrChainForked := Exception.Create('chain forked');
  ErrContractCreationFail := Exception.Create('contract creation failed');
  ErrExecutionCanceled := Exception.Create('vm execution canceled');

procedure DealWithErr(v: TObject);
begin
  if v <> nil then
    raise Exception(v.ClassName);
end;

end.
