unit Vm.Contracts.ContractsDexFund;

interface

uses
  Common.Types.Address Common.Types.Hash Common.Types.TokenTypeId,
  Interfaces.VmDb Interfaces.Core.AccountBlock Interfaces.Core.ContractMeta,
  System.SysUtils System.Classes System.Generics.Collections,
  Vm.Abi.Abi Vm.Contracts.Abi.AbiDexFund Vm.Contracts.Contracts Vm.Util.Util Vm.Quota.Quota,
  VM.Contracts.Contracts,
  VM.Contracts.Contracts.Asset,
  VM.Contracts.Contracts.Dex.Trade,
  VM.Contracts.Contracts.Governance,
  VM.Contracts.Contracts.Quota,
  VM.Contracts.Contracts.Test,
  Vm.Contracts.Dex.Dex Vm.Contracts.Dex.Proto.DexProto,
  VM.Contracts.Params,
  VM.Contracts.Reward.Test;

type
  TMethodDexFundDeposit = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundWithdraw = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundOpenNewMarket = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundPlaceOrder = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundSettleOrders = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundTriggerPeriodJob = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundStakeForMining = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundStakeForVIP = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundStakeForSVIP = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundStakeForPrincipalSVIP = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundCancelStakeById = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundDelegateStakeCallback = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundCancelDelegateStakeCallback = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundDelegateStakeCallbackV2 = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundCancelDelegateStakeCallbackV2 = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundGetTokenInfoCallback = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundDexAdminConfig = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundTradeAdminConfig = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundMarketAdminConfig = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundTransferTokenOwnership = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundNotifyTime = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundCreateNewInviter = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundBindInviteCode = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundEndorseVx = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundSettleMakerMinedVx = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundConfigMarketAgents = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundPlaceAgentOrder = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundLockVxForDividend = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexFundSwitchConfig = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexCancelOrderBySendHash = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexCommonAdminConfig = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTransfer = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexAgentDeposit = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexAssignedWithdraw = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

function HandleDexReceiveErr(Logger: ILogger; const MethodName: string; Err: Exception; SendBlock: TAccountBlock): TArray<TAccountBlock>;

implementation

uses
  System.Math;

var
  FundLogger: ILogger;

function HandleDexReceiveErr(Logger: ILogger; const MethodName: string; Err: Exception; SendBlock: TAccountBlock): TArray<TAccountBlock>;
begin
  Logger.Error('dex receive error', ['method', MethodName, 'err', Err.Message, 'fromhash', SendBlock.Hash.ToString]);
  Result := nil;
end;

{ TMethodDexFundDeposit }

constructor TMethodDexFundDeposit.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundDeposit.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundDeposit.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundDeposit.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundDeposit.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundDepositQuota;
end;

function TMethodDexFundDeposit.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
begin
  if Block.Amount.Sign <= 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundDeposit.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Account: TDexProtoAccount;
begin
  Account := Dex.DepositAccount(Db, SendBlock.AccountAddress, SendBlock.TokenId, SendBlock.Amount);
  if SendBlock.TokenId.Compare(VxTokenId) = 0 then
  begin
    if Dex.OnDepositVx(Db, Vm.ConsensusReader, SendBlock.AccountAddress, SendBlock.Amount, Account) <> nil then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnDepositVx(Db, Vm.ConsensusReader, SendBlock.AccountAddress, SendBlock.Amount, Account), SendBlock));
  end;
  if Dex.IsVersion11AddTransferAssetEvent(Db) then
    Dex.AddTransferAssetEvent(Db, Dex.TransferAssetDeposit, SendBlock.AccountAddress, AddressDexFund, SendBlock.TokenId, SendBlock.Amount, nil);
  Result := nil;
end;

{ TMethodDexFundWithdraw }

constructor TMethodDexFundWithdraw.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundWithdraw.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundWithdraw.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundWithdraw.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundWithdraw.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundWithdrawQuota;
end;

function TMethodDexFundWithdraw.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamWithdraw;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamWithdraw>(Param), FMethodName, Block.Data);
  if Param.Amount.Sign <= 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundWithdraw.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamWithdraw;
  Acc: TDexProtoAccount;
  Err: Exception;
  SendBlockItem: TAccountBlock;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamWithdraw>(Param), FMethodName, SendBlock.Data);
  Acc := Dex.ReduceAccount(Db, SendBlock.AccountAddress, Param.Token.Bytes, Param.Amount);
  if Acc.Amount = nil then // Check if Acc is valid
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Err, SendBlock));

  if Param.Token.Compare(VxTokenId) = 0 then
  begin
    if Dex.OnWithdrawVx(Db, Vm.ConsensusReader, SendBlock.AccountAddress, Param.Amount, Acc) <> nil then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnWithdrawVx(Db, Vm.ConsensusReader, SendBlock.AccountAddress, Param.Amount, Acc), SendBlock));
  end;
  if Dex.IsVersion11AddTransferAssetEvent(Db) then
    Dex.AddTransferAssetEvent(Db, Dex.TransferAssetWithdraw, AddressDexFund, SendBlock.AccountAddress, Param.Token, Param.Amount, nil);

  SendBlockItem.AccountAddress := AddressDexFund;
  SendBlockItem.ToAddress := SendBlock.AccountAddress;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.Amount := Param.Amount;
  SendBlockItem.TokenId := Param.Token;
  SendBlockItem.Data := [];
  Result := [SendBlockItem];
end;

{ TMethodDexFundOpenNewMarket }

constructor TMethodDexFundOpenNewMarket.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundOpenNewMarket.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundOpenNewMarket.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundOpenNewMarket.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundOpenNewMarket.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundOpenNewMarketQuota;
end;

function TMethodDexFundOpenNewMarket.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamOpenNewMarket;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamOpenNewMarket>(Param), FMethodName, Block.Data);
  Result := Dex.CheckMarketParam(Param);
end;

function TMethodDexFundOpenNewMarket.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamOpenNewMarket;
  Mk: TDexMarketInfo;
  Ok: Boolean;
  MarketInfo: TDexMarketInfo;
  AppendBlocks: TArray<TAccountBlock>;
  GetTokenInfoData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamOpenNewMarket>(Param), FMethodName, SendBlock.Data);
  Mk := Dex.GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
  Ok := Mk.Valid;
  if Ok then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketExists.Create('trade market exists'), SendBlock));

  MarketInfo := TDexMarketInfo.Create;
  if Dex.RenderMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken, nil, SendBlock.AccountAddress) <> nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.RenderMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken, nil, SendBlock.AccountAddress), SendBlock));

  if MarketInfo.Valid then
  begin
    AppendBlocks := Dex.OnNewMarketGetTokenInfoSuccess(Db, Vm.ConsensusReader, MarketInfo, Param.TradeToken, Param.QuoteToken, SendBlock.AccountAddress);
    if Length(AppendBlocks) > 0 then
      Result := AppendBlocks
    else
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('OnNewMarketGetTokenInfoSuccess failed'), SendBlock));
  end
  else
  begin
    GetTokenInfoData := Dex.OnNewMarketPending(Db, Param, MarketInfo);
    SendBlockItem.AccountAddress := AddressDexFund;
    SendBlockItem.ToAddress := AddressAsset;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Amount := TBigInteger.Create(0);
    SendBlockItem.Data := GetTokenInfoData;
    Result := [SendBlockItem];
  end;
end;

{ TMethodDexFundPlaceOrder }

constructor TMethodDexFundPlaceOrder.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundPlaceOrder.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundPlaceOrder.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundPlaceOrder.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundPlaceOrder.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundPlaceOrderQuota;
end;

function TMethodDexFundPlaceOrder.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamPlaceOrder;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamPlaceOrder>(Param), FMethodName, Block.Data);
  Result := Dex.PreCheckOrderParam(Param, Dex.IsStemFork(Db));
end;

function TMethodDexFundPlaceOrder.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamPlaceOrder;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamPlaceOrder>(Param), FMethodName, SendBlock.Data);
  Blocks := Dex.DoPlaceOrder(Db, Param, SendBlock.AccountAddress, nil, SendBlock.Hash);
  if Length(Blocks) > 0 then
    Result := Blocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('DoPlaceOrder failed'), SendBlock));
end;

{ TMethodDexFundSettleOrders }

constructor TMethodDexFundSettleOrders.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundSettleOrders.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundSettleOrders.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundSettleOrders.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundSettleOrders.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundSettleOrdersQuota;
end;

function TMethodDexFundSettleOrders.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamSerializedData;
  SettleActions: TDexProtoSettleActions;
begin
  if Block.AccountAddress.Compare(AddressDexTrade) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSerializedData>(Param), FMethodName, Block.Data);
  SettleActions.Deserialize(Param.Data);
  Result := Dex.CheckSettleActions(SettleActions);
end;

function TMethodDexFundSettleOrders.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamSerializedData;
  SettleActions: TDexProtoSettleActions;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  FundAction: TDexProtoFundAction;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSerializedData>(Param), FMethodName, SendBlock.Data);
  SettleActions.Deserialize(Param.Data);
  MarketInfo := Dex.GetMarketInfoByTokens(Db, SettleActions.TradeToken, SettleActions.QuoteToken);
  Ok := MarketInfo.Valid;
  if not Ok then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotExists.Create('trade market not exists'), SendBlock));

  for FundAction in SettleActions.FundActions do
  begin
    if Dex.DoSettleFund(Db, Vm.ConsensusReader, FundAction, MarketInfo, FundLogger) <> nil then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.DoSettleFund(Db, Vm.ConsensusReader, FundAction, MarketInfo, FundLogger), SendBlock));
  end;
  if Length(SettleActions.FeeActions) > 0 then
  begin
    Dex.SettleFees(Db, Vm.ConsensusReader, MarketInfo.AllowMining, MarketInfo.QuoteToken, MarketInfo.QuoteTokenDecimals, MarketInfo.QuoteTokenType, SettleActions.FeeActions, nil, nil);
    Dex.SettleOperatorFees(Db, Vm.ConsensusReader, SettleActions.FeeActions, MarketInfo);
  end;
  Result := nil;
end;

{ TMethodDexFundTriggerPeriodJob }

constructor TMethodDexFundTriggerPeriodJob.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundTriggerPeriodJob.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundTriggerPeriodJob.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundTriggerPeriodJob.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundTriggerPeriodJob.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundTriggerPeriodJobQuota;
end;

function TMethodDexFundTriggerPeriodJob.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamTriggerPeriodJob;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTriggerPeriodJob>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundTriggerPeriodJob.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamTriggerPeriodJob;
  LastPeriodId: UInt64;
  VxPool, Amount, VxPoolLeaved, Refund: TBigInteger;
  AmtForItems: TDictionary<Integer, TBigInteger>;
  Success: Boolean;
  Blocks: TArray<TAccountBlock>;
begin
  if not Dex.ValidTriggerAddress(Db, SendBlock.AccountAddress) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidSourceAddress.Create('invalid source address'), SendBlock));

  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTriggerPeriodJob>(Param), FMethodName, SendBlock.Data);
  if Param.PeriodId >= Dex.GetCurrentPeriodId(Db, Vm.ConsensusReader) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create(Format('job periodId for biz %d not before current periodId', [Param.BizType])), SendBlock));

  LastPeriodId := Dex.GetLastJobPeriodIdByBizType(Db, Param.BizType);
  if (LastPeriodId > 0) and (Param.PeriodId <> LastPeriodId + 1) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create(Format('job periodId for biz %d not equals to expected id %d', [Param.BizType, LastPeriodId + 1])), SendBlock));

  Dex.AddPeriodWithBizEvent(Db, Param.PeriodId, Param.BizType);

  case Param.BizType of
    Dex.FeeDividendJob:
      Blocks := Dex.DoFeesDividend(Db, Param.PeriodId);
    Dex.OperatorFeeDividendJob:
      Dex.DoOperatorFeesDividend(Db, Param.PeriodId);
    Dex.FinishVxUnlock:
      Dex.DoFinishVxUnlock(Db, Param.PeriodId);
    Dex.FinishCancelMiningStake:
      Dex.DoFinishCancelMiningStake(Db, Param.PeriodId);
  else
    VxPool := Dex.GetVxMinePool(Db);
    VxPoolLeaved := TBigInteger.Create(VxPool);
    case Param.BizType of
      Dex.MineVxForFeeJob:
        begin
          AmtForItems := Dex.GetFeeMineRateArr(Db);
          Success := Dex.GetVxAmountsForEqualItems(Db, Param.PeriodId, VxPool, AmtForItems, VxPoolLeaved);
          if Success then
          begin
            Refund := Dex.DoMineVxForFee(Db, Vm.ConsensusReader, Param.PeriodId, AmtForItems, FundLogger);
            if Refund <> nil then
              Exit(HandleDexReceiveErr(FundLogger, FMethodName, Refund, SendBlock));
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('no vx available on mine for fee'), SendBlock));
        end;
      Dex.MineVxForStakingJob:
        begin
          Amount := Dex.GetFeeStakingMineRate(Db);
          Success := Dex.GetVxAmountToMine(Db, Param.PeriodId, VxPool, Amount, VxPoolLeaved);
          if Success then
          begin
            Refund := Dex.DoMineVxForStaking(Db, Vm.ConsensusReader, Param.PeriodId, Amount);
            if Refund <> nil then
              Exit(HandleDexReceiveErr(FundLogger, FMethodName, Refund, SendBlock));
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('no vx available on mine for staking'), SendBlock));
        end;
      Dex.MineVxForMakerAndMaintainerJob:
        begin
          AmtForItems := Dex.GetMakerAndMaintainerArr(Db);
          Success := Dex.GetVxAmountsForEqualItems(Db, Param.PeriodId, VxPool, AmtForItems, VxPoolLeaved);
          if Success then
          begin
            if Dex.DoMineVxForMakerMineAndMaintainer(Db, Param.PeriodId, Vm.ConsensusReader, AmtForItems) <> nil then
              Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.DoMineVxForMakerMineAndMaintainer(Db, Param.PeriodId, Vm.ConsensusReader, AmtForItems), SendBlock));
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('no vx available on mine for maker and maintainer'), SendBlock));
        end;
    end;
    if (Refund <> nil) and (Refund.Sign > 0) then
      VxPoolLeaved := TBigInteger.Add(VxPoolLeaved, Refund);
    Dex.SaveVxMinePool(Db, VxPoolLeaved);
  end;
  Dex.SaveLastJobPeriodIdByBizType(Db, Param.PeriodId, Param.BizType);
  Result := Blocks;
end;

{ TMethodDexFundStakeForMining }

constructor TMethodDexFundStakeForMining.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundStakeForMining.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundStakeForMining.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundStakeForMining.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundStakeForMining.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundStakeForMiningQuota;
end;

function TMethodDexFundStakeForMining.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamStakeForMining;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForMining>(Param), FMethodName, Block.Data);
  if Param.Amount.Compare(Dex.StakeForMiningMinAmount) < 0 then
    Exit(EDexInvalidStakeAmount.Create('invalid stake amount'));
  if (Param.ActionType <> Dex.Stake) and (Param.ActionType <> Dex.CancelStake) then
    Exit(EDexInvalidStakeActionType.Create('invalid stake action type'));
  Result := nil;
end;

function TMethodDexFundStakeForMining.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamStakeForMining;
  StakeHeight: UInt64;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForMining>(Param), FMethodName, SendBlock.Data);
  StakeHeight := NodeConfig.Params.StakeHeight; // Assuming NodeConfig.Params is accessible
  if (not Dex.IsDexMiningFork(Db)) and Dex.IsEarthFork(Db) then
    StakeHeight := 1;

  AppendBlocks := Dex.HandleStakeAction(Db, Dex.StakeForMining, Param.ActionType, SendBlock.AccountAddress, TAddress.Zero, Param.Amount, StakeHeight, Block);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('HandleStakeAction failed'), SendBlock));
end;

{ TMethodDexFundStakeForVIP }

constructor TMethodDexFundStakeForVIP.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundStakeForVIP.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundStakeForVIP.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundStakeForVIP.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundStakeForVIP.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundStakeForVipQuota;
end;

function TMethodDexFundStakeForVIP.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamStakeForVIP;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForVIP>(Param), FMethodName, Block.Data);
  if (Param.ActionType <> Dex.Stake) and (Param.ActionType <> Dex.CancelStake) then
    Exit(EDexInvalidStakeActionType.Create('invalid stake action type'));
  Result := nil;
end;

function TMethodDexFundStakeForVIP.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamStakeForVIP;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForVIP>(Param), FMethodName, SendBlock.Data);
  AppendBlocks := Dex.HandleStakeAction(Db, Dex.StakeForVIP, Param.ActionType, SendBlock.AccountAddress, TAddress.Zero, Dex.StakeForVIPAmount, NodeConfig.Params.DexVipStakeHeight, Block);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('HandleStakeAction failed'), SendBlock));
end;

{ TMethodDexFundStakeForSVIP }

constructor TMethodDexFundStakeForSVIP.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundStakeForSVIP.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundStakeForSVIP.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundStakeForSVIP.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundStakeForSVIP.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundStakeForSuperVIPQuota;
end;

function TMethodDexFundStakeForSVIP.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamStakeForVIP;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForVIP>(Param), FMethodName, Block.Data);
  if (Param.ActionType <> Dex.Stake) and (Param.ActionType <> Dex.CancelStake) then
    Exit(EDexInvalidStakeActionType.Create('invalid stake action type'));
  Result := nil;
end;

function TMethodDexFundStakeForSVIP.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamStakeForVIP;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamStakeForVIP>(Param), FMethodName, SendBlock.Data);
  AppendBlocks := Dex.HandleStakeAction(Db, Dex.StakeForSuperVIP, Param.ActionType, SendBlock.AccountAddress, TAddress.Zero, Dex.StakeForSuperVIPAmount, NodeConfig.Params.DexSuperVipStakeHeight, Block);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('HandleStakeAction failed'), SendBlock));
end;

{ TMethodDexFundStakeForPrincipalSVIP }

constructor TMethodDexFundStakeForPrincipalSVIP.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundStakeForPrincipalSVIP.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundStakeForPrincipalSVIP.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundStakeForPrincipalSVIP.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundStakeForPrincipalSVIP.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundStakeForPrincipalSuperVIPQuota;
end;

function TMethodDexFundStakeForPrincipalSVIP.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Principal: TAddress;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TAddress>(Principal), FMethodName, Block.Data);
  if (Principal.Bytes = nil) or (Principal.Compare(TAddress.Zero) = 0) or (Principal.Compare(Block.AccountAddress) = 0) then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundStakeForPrincipalSVIP.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Principal: TAddress;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TAddress>(Principal), FMethodName, SendBlock.Data);
  AppendBlocks := Dex.HandleStakeAction(Db, Dex.StakeForPrincipalSuperVIP, Dex.Stake, SendBlock.AccountAddress, Principal, Dex.StakeForSuperVIPAmount, NodeConfig.Params.DexSuperVipStakeHeight, Block);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('HandleStakeAction failed'), SendBlock));
end;

{ TMethodDexFundCancelStakeById }

constructor TMethodDexFundCancelStakeById.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundCancelStakeById.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundCancelStakeById.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundCancelStakeById.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundCancelStakeById.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundCancelStakeByIdQuota;
end;

function TMethodDexFundCancelStakeById.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Id: THash;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<THash>(Id), FMethodName, Block.Data);
  Result := nil;
end;

function TMethodDexFundCancelStakeById.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Id: THash;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<THash>(Id), FMethodName, SendBlock.Data);
  AppendBlocks := Dex.DoCancelStakeV2(Db, SendBlock.AccountAddress, Id);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('DoCancelStakeV2 failed'), SendBlock));
end;

{ TMethodDexFundDelegateStakeCallback }

constructor TMethodDexFundDelegateStakeCallback.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundDelegateStakeCallback.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundDelegateStakeCallback.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundDelegateStakeCallback.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundDelegateStakeCallback.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundDelegateStakeCallbackQuota;
end;

function TMethodDexFundDelegateStakeCallback.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamDelegateStakeCallback;
begin
  if Block.AccountAddress.Compare(AddressQuota) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallback>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundDelegateStakeCallback.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  CallbackParam: TDexParamDelegateStakeCallback;
  StakedAmount: TBigInteger;
  VipStaking: TDexVipStaking;
  Ok: Boolean;
  SuperVipStaking: TDexSuperVipStaking;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallback>(CallbackParam), FMethodName, SendBlock.Data);
  if CallbackParam.Success then
  begin
    case CallbackParam.Bid of
      Dex.StakeForMining:
        begin
          StakedAmount := Dex.GetMiningStakedAmount(Db, CallbackParam.StakeAddress);
          StakedAmount := TBigInteger.Add(StakedAmount, CallbackParam.Amount);
          Dex.SaveMiningStakedAmount(Db, CallbackParam.StakeAddress, StakedAmount);
          if Dex.OnMiningStakeSuccess(Db, Vm.ConsensusReader, CallbackParam.StakeAddress, CallbackParam.Amount, StakedAmount) <> nil then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnMiningStakeSuccess(Db, Vm.ConsensusReader, CallbackParam.StakeAddress, CallbackParam.Amount, StakedAmount), SendBlock));
        end;
      Dex.StakeForVIP:
        begin
          VipStaking := Dex.GetVIPStaking(Db, CallbackParam.StakeAddress);
          Ok := VipStaking.StakedTimes > 0;
          if Ok then
          begin
            VipStaking.StakedTimes := VipStaking.StakedTimes + 1;
            Dex.SaveVIPStaking(Db, CallbackParam.StakeAddress, VipStaking);
            AppendBlocks := Dex.DoCancelStakeV1(Db, CallbackParam.StakeAddress, CallbackParam.Bid, CallbackParam.Amount);
            Result := AppendBlocks;
          end
          else
          begin
            VipStaking.Timestamp := Dex.GetTimestampInt64(Db);
            VipStaking.StakedTimes := 1;
            Dex.SaveVIPStaking(Db, CallbackParam.StakeAddress, VipStaking);
          end;
        end;
      Dex.StakeForSuperVIP:
        begin
          SuperVipStaking := Dex.GetSuperVIPStaking(Db, CallbackParam.StakeAddress);
          Ok := SuperVipStaking.StakedTimes > 0;
          if Ok then
          begin
            SuperVipStaking.StakedTimes := SuperVipStaking.StakedTimes + 1;
            Dex.SaveSuperVIPStaking(Db, CallbackParam.StakeAddress, SuperVipStaking);
            AppendBlocks := Dex.DoCancelStakeV1(Db, CallbackParam.StakeAddress, CallbackParam.Bid, CallbackParam.Amount);
            Result := AppendBlocks;
          end
          else
          begin
            SuperVipStaking.Timestamp := Dex.GetTimestampInt64(Db);
            SuperVipStaking.StakedTimes := 1;
            Dex.SaveSuperVIPStaking(Db, CallbackParam.StakeAddress, SuperVipStaking);
          end;
        end;
    end;
  end
  else
  begin
    case CallbackParam.Bid of
      Dex.StakeForMining:
        if CallbackParam.Amount.Compare(SendBlock.Amount) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
      Dex.StakeForVIP:
        if Dex.StakeForVIPAmount.Compare(SendBlock.Amount) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
      Dex.StakeForSuperVIP:
        if Dex.StakeForSuperVIPAmount.Compare(SendBlock.Amount) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
    end;
    Dex.DepositAccount(Db, CallbackParam.StakeAddress, ViteTokenId, SendBlock.Amount);
  end;
  Result := nil;
end;

{ TMethodDexFundCancelDelegateStakeCallback }

constructor TMethodDexFundCancelDelegateStakeCallback.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundCancelDelegateStakeCallback.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundCancelDelegateStakeCallback.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundCancelDelegateStakeCallback.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundCancelDelegateStakeCallback.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundCancelDelegateStakeCallbackQuota;
end;

function TMethodDexFundCancelDelegateStakeCallback.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamDelegateStakeCallback;
begin
  if Block.AccountAddress.Compare(AddressQuota) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallback>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundCancelDelegateStakeCallback.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamDelegateStakeCallback;
  StakedAmount: TBigInteger;
  Leaved: TBigInteger;
  VipStaking: TDexVipStaking;
  Ok: Boolean;
  SuperVipStaking: TDexSuperVipStaking;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallback>(Param), FMethodName, SendBlock.Data);
  if Param.Success then
  begin
    case Param.Bid of
      Dex.StakeForMining:
        begin
          if Param.Amount.Compare(SendBlock.Amount) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          StakedAmount := Dex.GetMiningStakedAmount(Db, Param.StakeAddress);
          Leaved := TBigInteger.Sub(StakedAmount, SendBlock.Amount);
          if Leaved.Sign < 0 then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock))
          else if Leaved.Sign = 0 then
            Dex.DeleteMiningStakedAmount(Db, Param.StakeAddress)
          else
            Dex.SaveMiningStakedAmount(Db, Param.StakeAddress, Leaved);
          if Dex.OnCancelMiningStakeSuccess(Db, Vm.ConsensusReader, Param.StakeAddress, SendBlock.Amount, Leaved) <> nil then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnCancelMiningStakeSuccess(Db, Vm.ConsensusReader, Param.StakeAddress, SendBlock.Amount, Leaved), SendBlock));
        end;
      Dex.StakeForVIP:
        begin
          if Dex.StakeForVIPAmount.Compare(SendBlock.Amount) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          VipStaking := Dex.GetVIPStaking(Db, Param.StakeAddress);
          Ok := VipStaking.StakedTimes > 0;
          if Ok then
          begin
            VipStaking.StakedTimes := VipStaking.StakedTimes - 1;
            if VipStaking.StakedTimes = 0 then
              Dex.DeleteVIPStaking(Db, Param.StakeAddress)
            else
              Dex.SaveVIPStaking(Db, Param.StakeAddress, VipStaking);
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexVIPStakingNotExists.Create('VIP staking not exists'), SendBlock));
        end;
      Dex.StakeForSuperVIP:
        begin
          if Dex.StakeForSuperVIPAmount.Compare(SendBlock.Amount) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          SuperVipStaking := Dex.GetSuperVIPStaking(Db, Param.StakeAddress);
          Ok := SuperVipStaking.StakedTimes > 0;
          if Ok then
          begin
            SuperVipStaking.StakedTimes := SuperVipStaking.StakedTimes - 1;
            if SuperVipStaking.StakedTimes = 0 then
              Dex.DeleteSuperVIPStaking(Db, Param.StakeAddress)
            else
              Dex.SaveSuperVIPStaking(Db, Param.StakeAddress, SuperVipStaking);
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexSuperVIPStakingNotExists.Create('Super VIP staking not exists'), SendBlock));
        end;
    end;
    if Dex.IsEarthFork(Db) and (Param.Bid = Dex.StakeForMining) then
      Dex.ScheduleCancelStake(Db, Param.StakeAddress, SendBlock.Amount)
    else
      Dex.DepositAccount(Db, Param.StakeAddress, ViteTokenId, SendBlock.Amount);
  end;
  Result := nil;
end;

{ TMethodDexFundDelegateStakeCallbackV2 }

constructor TMethodDexFundDelegateStakeCallbackV2.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundDelegateStakeCallbackV2.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundDelegateStakeCallbackV2.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundDelegateStakeCallbackV2.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundDelegateStakeCallbackV2.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundDelegateStakeCallbackV2Quota;
end;

function TMethodDexFundDelegateStakeCallbackV2.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamDelegateStakeCallbackV2;
begin
  if Block.AccountAddress.Compare(AddressQuota) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallbackV2>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundDelegateStakeCallbackV2.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamDelegateStakeCallbackV2;
  Info: TDexDelegateStakeInfo;
  Ok: Boolean;
  Address: TAddress;
  Amount: TBigInteger;
  StakedAmount: TBigInteger;
  VipStaking: TDexVipStaking;
  SuperVipStaking: TDexSuperVipStaking;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallbackV2>(Param), FMethodName, SendBlock.Data);
  Info := Dex.GetDelegateStakeInfo(Db, Param.Id.Bytes);
  Ok := Info.Address.Bytes <> nil; // Check if Info is valid
  if not Ok then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexStakingInfoByIdNotExists.Create('staking info by ID not exists'), SendBlock));

  Address := BytesToAddress(Info.Address);
  Amount := TBigInteger.FromByteArray(Info.Amount);

  if Param.Success then
  begin
    case Info.StakeType of
      Dex.StakeForMining:
        begin
          StakedAmount := Dex.GetMiningStakedV2Amount(Db, Address);
          StakedAmount := TBigInteger.Add(StakedAmount, Amount);
          Dex.SaveMiningStakedV2Amount(Db, Address, StakedAmount);
          if Dex.OnMiningStakeSuccessV2(Db, Vm.ConsensusReader, Address, Amount, StakedAmount) <> nil then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnMiningStakeSuccessV2(Db, Vm.ConsensusReader, Address, Amount, StakedAmount), SendBlock));
        end;
      Dex.StakeForVIP:
        begin
          VipStaking := Dex.GetVIPStaking(Db, Address);
          Ok := VipStaking.StakedTimes > 0;
          if Ok then
          begin
            VipStaking.StakedTimes := VipStaking.StakedTimes + 1;
            VipStaking.StakingHashes := VipStaking.StakingHashes + [Param.Id.Bytes];
            Dex.SaveVIPStaking(Db, Address, VipStaking);
            Blocks := Dex.DoRawCancelStakeV2(Param.Id);
            Result := Blocks;
          end
          else
          begin
            VipStaking.Timestamp := Dex.GetTimestampInt64(Db);
            VipStaking.StakedTimes := 1;
            VipStaking.StakingHashes := VipStaking.StakingHashes + [Param.Id.Bytes];
            Dex.SaveVIPStaking(Db, Address, VipStaking);
          end;
        end;
      Dex.StakeForSuperVIP, Dex.StakeForPrincipalSuperVIP:
        begin
          if Info.StakeType = Dex.StakeForPrincipalSuperVIP then
            Address := BytesToAddress(Info.Principal);
          SuperVipStaking := Dex.GetSuperVIPStaking(Db, Address);
          Ok := SuperVipStaking.StakedTimes > 0;
          if Ok then
          begin
            SuperVipStaking.StakedTimes := SuperVipStaking.StakedTimes + 1;
            SuperVipStaking.StakingHashes := SuperVipStaking.StakingHashes + [Param.Id.Bytes];
            Dex.SaveSuperVIPStaking(Db, Address, SuperVipStaking);
            Blocks := Dex.DoRawCancelStakeV2(Param.Id);
            Result := Blocks;
          end
          else
          begin
            SuperVipStaking.Timestamp := Dex.GetTimestampInt64(Db);
            SuperVipStaking.StakedTimes := 1;
            SuperVipStaking.StakingHashes := SuperVipStaking.StakingHashes + [Param.Id.Bytes];
            Dex.SaveSuperVIPStaking(Db, Address, SuperVipStaking);
          end;
        end;
    end;
    Dex.SaveDelegateStakeAddressIndex(Db, Param.Id, Info.StakeType, Info.Address);
    Dex.ConfirmDelegateStakeInfo(Db, Param.Id, Info, 0); // SerialNo is not used in Delphi
  end
  else
  begin
    case Info.StakeType of
      Dex.StakeForMining:
        if CompareMem(Pointer(Info.Amount), Pointer(SendBlock.Amount.ToByteArray), Length(Info.Amount)) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
      Dex.StakeForVIP:
        if Dex.StakeForVIPAmount.Compare(SendBlock.Amount) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
      Dex.StakeForSuperVIP, Dex.StakeForPrincipalSuperVIP:
        if Dex.StakeForSuperVIPAmount.Compare(SendBlock.Amount) <> 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock));
    end;
    Dex.DepositAccount(Db, Address, ViteTokenId, SendBlock.Amount);
    Dex.DeleteDelegateStakeInfo(Db, Param.Id.Bytes);
  end;
  Result := Blocks;
end;

{ TMethodDexFundCancelDelegateStakeCallbackV2 }

constructor TMethodDexFundCancelDelegateStakeCallbackV2.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundDelegateCancelStakeCallbackV2Quota;
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamDelegateStakeCallbackV2;
begin
  if Block.AccountAddress.Compare(AddressQuota) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallbackV2>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundCancelDelegateStakeCallbackV2.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamDelegateStakeCallbackV2;
  Info: TDexDelegateStakeInfo;
  Ok: Boolean;
  Address: TAddress;
  StakedAmount: TBigInteger;
  Leaved: TBigInteger;
  VipStaking: TDexVipStaking;
  SuperVipStaking: TDexSuperVipStaking;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDelegateStakeCallbackV2>(Param), FMethodName, SendBlock.Data);
  Info := Dex.GetDelegateStakeInfo(Db, Param.Id.Bytes);
  Ok := Info.Address.Bytes <> nil;
  if not Ok then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexStakingInfoByIdNotExists.Create('staking info by ID not exists'), SendBlock));

  Address := BytesToAddress(Info.Address);

  if Param.Success then
  begin
    case Info.StakeType of
      Dex.StakeForMining:
        begin
          if CompareMem(Pointer(Info.Amount), Pointer(SendBlock.Amount.ToByteArray), Length(Info.Amount)) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          StakedAmount := Dex.GetMiningStakedV2Amount(Db, Address);
          Leaved := TBigInteger.Sub(StakedAmount, SendBlock.Amount);
          if Leaved.Sign < 0 then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback'), SendBlock))
          else if Leaved.Sign = 0 then
            Dex.DeleteMiningStakedV2Amount(Db, Address)
          else
            Dex.SaveMiningStakedV2Amount(Db, Address, Leaved);
          if Dex.OnCancelMiningStakeSuccessV2(Db, Vm.ConsensusReader, Address, SendBlock.Amount, Leaved) <> nil then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnCancelMiningStakeSuccessV2(Db, Vm.ConsensusReader, Address, SendBlock.Amount, Leaved), SendBlock));
        end;
      Dex.StakeForVIP:
        begin
          if Dex.StakeForVIPAmount.Compare(SendBlock.Amount) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          VipStaking := Dex.GetVIPStaking(Db, Address);
          Ok := VipStaking.StakedTimes > 0;
          if Ok then
          begin
            VipStaking.StakedTimes := VipStaking.StakedTimes - 1;
            if VipStaking.StakedTimes = 0 then
              Dex.DeleteVIPStaking(Db, Address)
            else
            begin
              if not Dex.ReduceVipStakingHash(VipStaking, Param.Id) then
                raise EDexInvalidIdForStakeCallback.Create('invalid ID for stake callback');
              Dex.SaveVIPStaking(Db, Address, VipStaking);
            end;
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexVIPStakingNotExists.Create('VIP staking not exists'), SendBlock));
        end;
      Dex.StakeForSuperVIP, Dex.StakeForPrincipalSuperVIP:
        begin
          if Info.StakeType = Dex.StakeForPrincipalSuperVIP then
            Address := BytesToAddress(Info.Principal);
          if Dex.StakeForSuperVIPAmount.Compare(SendBlock.Amount) <> 0 then
            raise EDexInvalidAmountForStakeCallback.Create('invalid amount for stake callback');
          SuperVipStaking := Dex.GetSuperVIPStaking(Db, Address);
          Ok := SuperVipStaking.StakedTimes > 0;
          if Ok then
          begin
            SuperVipStaking.StakedTimes := SuperVipStaking.StakedTimes - 1;
            if SuperVipStaking.StakedTimes = 0 then
              Dex.DeleteSuperVIPStaking(Db, Address)
            else
            begin
              if not Dex.ReduceVipStakingHash(SuperVipStaking, Param.Id) then
                raise EDexInvalidIdForStakeCallback.Create('invalid ID for stake callback');
              Dex.SaveSuperVIPStaking(Db, Address, SuperVipStaking);
            end;
          end
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexSuperVIPStakingNotExists.Create('Super VIP staking not exists'), SendBlock));
        end;
    end;
    if Info.StakeType = Dex.StakeForPrincipalSuperVIP then
      Dex.DepositAccount(Db, BytesToAddress(Info.Address), ViteTokenId, SendBlock.Amount)
    else if Info.StakeType = Dex.StakeForMining then
      Dex.ScheduleCancelStake(Db, Address, SendBlock.Amount)
    else
      Dex.DepositAccount(Db, Address, ViteTokenId, SendBlock.Amount);
    Dex.DeleteDelegateStakeInfo(Db, Param.Id.Bytes);
    Dex.DeleteDelegateStakeAddressIndex(Db, Info.Address, 0); // SerialNo is not used in Delphi
  end;
  Result := nil;
end;

{ TMethodDexFundGetTokenInfoCallback }

constructor TMethodDexFundGetTokenInfoCallback.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundGetTokenInfoCallback.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundGetTokenInfoCallback.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundGetTokenInfoCallback.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundGetTokenInfoCallback.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundGetTokenInfoCallbackQuota;
end;

function TMethodDexFundGetTokenInfoCallback.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamGetTokenInfoCallback;
begin
  if Block.AccountAddress.Compare(AddressAsset) <> 0 then
    Exit(EDexInvalidSourceAddress.Create('invalid source address'));
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamGetTokenInfoCallback>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundGetTokenInfoCallback.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  CallbackParam: TDexParamGetTokenInfoCallback;
  AppendBlocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamGetTokenInfoCallback>(CallbackParam), FMethodName, SendBlock.Data);
  case CallbackParam.Bid of
    Dex.GetTokenForNewMarket:
      if CallbackParam.Exist then
      begin
        AppendBlocks := Dex.OnNewMarketGetTokenInfoSuccess(Db, Vm.ConsensusReader, CallbackParam.TokenId, CallbackParam);
        if Length(AppendBlocks) > 0 then
          Result := AppendBlocks
        else
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('OnNewMarketGetTokenInfoSuccess failed'), SendBlock));
      end
      else
      begin
        if Dex.OnNewMarketGetTokenInfoFailed(Db, CallbackParam.TokenId) <> nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnNewMarketGetTokenInfoFailed(Db, CallbackParam.TokenId), SendBlock));
      end;
    Dex.GetTokenForSetQuote:
      if CallbackParam.Exist then
      begin
        if Dex.OnSetQuoteGetTokenInfoSuccess(Db, CallbackParam) <> nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnSetQuoteGetTokenInfoSuccess(Db, CallbackParam), SendBlock));
      end
      else
      begin
        if Dex.OnSetQuoteGetTokenInfoFailed(Db, CallbackParam.TokenId) <> nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnSetQuoteGetTokenInfoFailed(Db, CallbackParam.TokenId), SendBlock));
      end;
    Dex.GetTokenForTransferOwner:
      if CallbackParam.Exist then
      begin
        if Dex.OnTransferOwnerGetTokenInfoSuccess(Db, CallbackParam) <> nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnTransferOwnerGetTokenInfoSuccess(Db, CallbackParam), SendBlock));
      end
      else
      begin
        if Dex.OnTransferOwnerGetTokenInfoFailed(Db, CallbackParam.TokenId) <> nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnTransferOwnerGetTokenInfoFailed(Db, CallbackParam.TokenId), SendBlock));
      end;
  end;
  Result := nil;
end;

{ TMethodDexFundDexAdminConfig }

constructor TMethodDexFundDexAdminConfig.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundDexAdminConfig.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundDexAdminConfig.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundDexAdminConfig.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundDexAdminConfig.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundAdminConfigQuota;
end;

function TMethodDexFundDexAdminConfig.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamDexAdminConfig;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDexAdminConfig>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundDexAdminConfig.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamDexAdminConfig;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamDexAdminConfig>(Param), FMethodName, SendBlock.Data);
  if Dex.IsOwner(Db, SendBlock.AccountAddress) then
  begin
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigOwner) then
      Dex.SetOwner(Db, Param.Owner);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigTimeOracle) then
      Dex.SetTimeOracle(Db, Param.TimeOracle);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigPeriodJobTrigger) then
      Dex.SetPeriodJobTrigger(Db, Param.PeriodJobTrigger);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigStopDex) then
      Dex.SaveDexStopped(Db, Param.StopDex);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigMakerMiningAdmin) then
      Dex.SaveMakerMiningAdmin(Db, Param.MakerMiningAdmin);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.AdminConfigMaintainer) then
      Dex.SaveMaintainer(Db, Param.Maintainer);
  end
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexOnlyOwnerAllow.Create('only owner allow'), SendBlock));
  Result := nil;
end;

{ TMethodDexFundTradeAdminConfig }

constructor TMethodDexFundTradeAdminConfig.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundTradeAdminConfig.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundTradeAdminConfig.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundTradeAdminConfig.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundTradeAdminConfig.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundTradeAdminConfigQuota;
end;

function TMethodDexFundTradeAdminConfig.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamTradeAdminConfig;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTradeAdminConfig>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundTradeAdminConfig.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamTradeAdminConfig;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  TokenInfo: TDexTokenInfo;
  GetTokenInfoData: TBytes;
  SendBlockItem: TAccountBlock;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTradeAdminConfig>(Param), FMethodName, SendBlock.Data);
  if Dex.IsOwner(Db, SendBlock.AccountAddress) then
  begin
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminConfigMineMarket) then
    begin
      MarketInfo := Dex.GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
      Ok := MarketInfo.Valid;
      if Ok then
      begin
        if Param.AllowMining <> MarketInfo.AllowMining then
        begin
          MarketInfo.AllowMining := Param.AllowMining;
          Dex.SaveMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken);
          Dex.AddMarketEvent(Db, MarketInfo);
        end
        else
        begin
          if MarketInfo.AllowMining then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketAllowMine.Create('trade market allow mine'), SendBlock))
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotAllowMine.Create('trade market not allow mine'), SendBlock));
        end;
      end
      else
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotExists.Create('trade market not exists'), SendBlock));
    end;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminConfigNewQuoteToken) then
    begin
      if (Param.QuoteTokenType < Dex.ViteTokenType) or (Param.QuoteTokenType > Dex.UsdTokenType) then
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidQuoteTokenType.Create('invalid quote token type'), SendBlock));

      if not Dex.QuoteTokenTypeInfos.ContainsKey(Param.QuoteTokenType) then
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidQuoteTokenType.Create('invalid quote token type'), SendBlock));

      TokenInfo := Dex.GetTokenInfo(Db, Param.NewQuoteToken);
      Ok := TokenInfo.Valid;
      if not Ok then
      begin
        GetTokenInfoData := Dex.OnSetQuoteTokenPending(Db, Param.NewQuoteToken, Param.QuoteTokenType);
        SendBlockItem.AccountAddress := AddressDexFund;
        SendBlockItem.ToAddress := AddressAsset;
        SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
        SendBlockItem.TokenId := ViteTokenId;
        SendBlockItem.Amount := TBigInteger.Create(0);
        SendBlockItem.Data := GetTokenInfoData;
        Result := [SendBlockItem];
      end
      else
      begin
        if TokenInfo.QuoteTokenType > 0 then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexAlreadyQuoteType.Create('already quote type'), SendBlock))
        else
        begin
          TokenInfo.QuoteTokenType := Param.QuoteTokenType;
          Dex.SaveTokenInfo(Db, Param.NewQuoteToken, TokenInfo);
          Dex.AddTokenEvent(Db, TokenInfo);
        end;
      end;
    end;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminConfigTradeThreshold) then
      Dex.SaveTradeThreshold(Db, Param.TokenTypeForTradeThreshold, Param.MinTradeThreshold);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminConfigMineThreshold) then
      Dex.SaveMineThreshold(Db, Param.TokenTypeForMiningThreshold, Param.MinMiningThreshold);
    if Dex.IsEarthFork(Db) and Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminStartNormalMine) and (not Dex.IsNormalMiningStarted(Db)) then
      Dex.StartNormalMine(Db);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.TradeAdminBurnExtraVx) and Dex.IsNormalMiningStarted(Db) and (Dex.GetVxBurnAmount(Db).Sign = 0) then
    begin
      Blocks := Dex.BurnExtraVx(Db);
      if Length(Blocks) > 0 then
        Result := Blocks;
    end;
  end
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexOnlyOwnerAllow.Create('only owner allow'), SendBlock));
  Result := nil;
end;

{ TMethodDexFundMarketAdminConfig }

constructor TMethodDexFundMarketAdminConfig.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundMarketAdminConfig.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundMarketAdminConfig.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundMarketAdminConfig.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundMarketAdminConfig.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundMarketAdminConfigQuota;
end;

function TMethodDexFundMarketAdminConfig.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamMarketAdminConfig;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamMarketAdminConfig>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundMarketAdminConfig.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamMarketAdminConfig;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamMarketAdminConfig>(Param), FMethodName, SendBlock.Data);
  MarketInfo := Dex.GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
  Ok := MarketInfo.Valid;
  if (not Ok) or (not MarketInfo.Valid) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotExists.Create('trade market not exists'), SendBlock));

  if CompareMem(Pointer(SendBlock.AccountAddress.Bytes), Pointer(MarketInfo.Owner), Length(MarketInfo.Owner)) then
  begin
    if Param.OperationCode = 0 then
      Exit(nil);
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.MarketOwnerTransferOwner) then
      MarketInfo.Owner := Param.MarketOwner.Bytes;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.MarketOwnerConfigTakerRate) then
    begin
      if not Dex.ValidOperatorFeeRate(Param.TakerFeeRate) then
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidOperatorFeeRate.Create('invalid operator fee rate'), SendBlock));
      MarketInfo.TakerOperatorFeeRate := Param.TakerFeeRate;
    end;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.MarketOwnerConfigMakerRate) then
    begin
      if not Dex.ValidOperatorFeeRate(Param.MakerFeeRate) then
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidOperatorFeeRate.Create('invalid operator fee rate'), SendBlock));
      MarketInfo.MakerOperatorFeeRate := Param.MakerFeeRate;
    end;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.MarketOwnerStopMarket) then
      MarketInfo.Stopped := Param.StopMarket;
    Dex.SaveMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken);
    Dex.AddMarketEvent(Db, MarketInfo);
  end
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexOnlyOwnerAllow.Create('only owner allow'), SendBlock));
  Result := nil;
end;

{ TMethodDexFundTransferTokenOwnership }

constructor TMethodDexFundTransferTokenOwnership.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundTransferTokenOwnership.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundTransferTokenOwnership.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundTransferTokenOwnership.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundTransferTokenOwnership.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundTransferTokenOwnershipQuota;
end;

function TMethodDexFundTransferTokenOwnership.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamTransferTokenOwnership;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTransferTokenOwnership>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundTransferTokenOwnership.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamTransferTokenOwnership;
  TokenInfo: TDexTokenInfo;
  Ok: Boolean;
  GetTokenInfoData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTransferTokenOwnership>(Param), FMethodName, SendBlock.Data);
  TokenInfo := Dex.GetTokenInfo(Db, Param.Token);
  Ok := TokenInfo.Valid;
  if Ok then
  begin
    if CompareMem(Pointer(TokenInfo.Owner), Pointer(SendBlock.AccountAddress.Bytes), Length(TokenInfo.Owner)) then
    begin
      TokenInfo.Owner := Param.NewOwner.Bytes;
      Dex.SaveTokenInfo(Db, Param.Token, TokenInfo);
      Dex.AddTokenEvent(Db, TokenInfo);
    end
    else
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexOnlyOwnerAllow.Create('only owner allow'), SendBlock));
  end
  else
  begin
    GetTokenInfoData := Dex.OnTransferTokenOwnerPending(Db, Param.Token, SendBlock.AccountAddress, Param.NewOwner);
    SendBlockItem.AccountAddress := AddressDexFund;
    SendBlockItem.ToAddress := AddressAsset;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Amount := TBigInteger.Create(0);
    SendBlockItem.Data := GetTokenInfoData;
    Result := [SendBlockItem];
  end;
  Result := nil;
end;

{ TMethodDexFundNotifyTime }

constructor TMethodDexFundNotifyTime.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundNotifyTime.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundNotifyTime.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundNotifyTime.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundNotifyTime.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundNotifyTimeQuota;
end;

function TMethodDexFundNotifyTime.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamNotifyTime;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamNotifyTime>(Param), FMethodName, Block.Data);
end;

function TMethodDexFundNotifyTime.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  NotifyTimeParam: TDexParamNotifyTime;
begin
  if not Dex.ValidTimeOracle(Db, SendBlock.AccountAddress) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidSourceAddress.Create('invalid source address'), SendBlock));

  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamNotifyTime>(NotifyTimeParam), FMethodName, SendBlock.Data);
  if Dex.SetDexTimestamp(Db, NotifyTimeParam.Timestamp, Vm.ConsensusReader) <> nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.SetDexTimestamp(Db, NotifyTimeParam.Timestamp, Vm.ConsensusReader), SendBlock));
  Result := nil;
end;

{ TMethodDexFundCreateNewInviter }

constructor TMethodDexFundCreateNewInviter.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundCreateNewInviter.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundCreateNewInviter.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundCreateNewInviter.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundCreateNewInviter.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundCreateNewInviterQuota;
end;

function TMethodDexFundCreateNewInviter.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
begin
  Result := nil;
end;

function TMethodDexFundCreateNewInviter.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Code: UInt32;
  Fee: TBigInteger;
begin
  Code := Dex.GetCodeByInviter(Db, SendBlock.AccountAddress);
  if Code > 0 then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexAlreadyIsInviter.Create('already is inviter'), SendBlock));

  Fee := Dex.NewInviterFeeAmount;
  if Dex.IsVersion10Upgrade(Db) then
    Fee := Dex.NewInviterFeeAmountForVersion10;

  if Dex.ReduceAccount(Db, SendBlock.AccountAddress, ViteTokenId.Bytes, Fee) <> nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.ReduceAccount(Db, SendBlock.AccountAddress, ViteTokenId.Bytes, Fee), SendBlock));

  Dex.SettleFeesWithTokenId(Db, Vm.ConsensusReader, True, ViteTokenId, Dex.ViteTokenDecimals, Dex.ViteTokenType, nil, Fee, nil);

  Code := Dex.NewInviteCode(Db, Block.PrevHash);
  if Code = 0 then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexNewInviteCodeFail.Create('new invite code fail'), SendBlock))
  else
  begin
    Dex.SaveCodeByInviter(Db, SendBlock.AccountAddress, Code);
    Dex.SaveInviterByCode(Db, SendBlock.AccountAddress, Code);
  end;
  Result := nil;
end;

{ TMethodDexFundBindInviteCode }

constructor TMethodDexFundBindInviteCode.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundBindInviteCode.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundBindInviteCode.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundBindInviteCode.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundBindInviteCode.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundBindInviteCodeQuota;
end;

function TMethodDexFundBindInviteCode.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Code: UInt32;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<UInt32>(Code), FMethodName, Block.Data);
end;

function TMethodDexFundBindInviteCode.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Inviter: TAddress;
  Code: UInt32;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<UInt32>(Code), FMethodName, SendBlock.Data);
  Inviter := Dex.GetInviterByInvitee(Db, SendBlock.AccountAddress);
  if Inviter.Bytes <> nil then
  begin
    if Inviter.Compare(TAddress.Zero) <> 0 then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexAlreadyBindInviter.Create('already bind inviter'), SendBlock))
    else
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('GetInviterByInvitee failed'), SendBlock));
  end;

  Inviter := Dex.GetInviterByCode(Db, Code);
  if Inviter.Bytes = nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInviterNotExists.Create('inviter not exists'), SendBlock));

  Dex.SaveInviterByInvitee(Db, SendBlock.AccountAddress, Inviter);
  Dex.AddInviteRelationEvent(Db, Inviter, SendBlock.AccountAddress, Code);
  Result := nil;
end;

{ TMethodDexFundEndorseVx }

constructor TMethodDexFundEndorseVx.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundEndorseVx.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundEndorseVx.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundEndorseVx.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundEndorseVx.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundEndorseVxQuota;
end;

function TMethodDexFundEndorseVx.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
begin
  if (Block.Amount.Sign <= 0) or (Block.TokenId.Compare(VxTokenId) <> 0) then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundEndorseVx.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  PoolAmount: TBigInteger;
begin
  PoolAmount := Dex.GetVxMinePool(Db);
  PoolAmount := TBigInteger.Add(PoolAmount, SendBlock.Amount);
  Dex.SaveVxMinePool(Db, PoolAmount);
  Result := nil;
end;

{ TMethodDexFundSettleMakerMinedVx }

constructor TMethodDexFundSettleMakerMinedVx.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundSettleMakerMinedVx.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundSettleMakerMinedVx.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundSettleMakerMinedVx.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundSettleMakerMinedVx.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundSettleMakerMinedVxQuota;
end;

function TMethodDexFundSettleMakerMinedVx.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamSerializedData;
  Actions: TDexProtoVxSettleActions;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSerializedData>(Param), FMethodName, Block.Data);
  Actions.Deserialize(Param.Data);
  Result := nil;
end;

function TMethodDexFundSettleMakerMinedVx.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamSerializedData;
  Actions: TDexProtoVxSettleActions;
  PoolAmt: TBigInteger;
  Finish: Boolean;
  Action: TDexProtoVxSettleAction;
  Addr: TAddress;
  Amt: TBigInteger;
begin
  if not Dex.IsMakerMiningAdmin(Db, SendBlock.AccountAddress) then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidSourceAddress.Create('invalid source address'), SendBlock));

  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSerializedData>(Param), FMethodName, SendBlock.Data);
  Actions.Deserialize(Param.Data);
  if Length(Actions.Actions) = 0 then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidInputParam.Create('invalid input param'), SendBlock));

  if Dex.GetLastSettledMakerMinedVxPeriod(Db) > 0 then
  begin
    if Actions.Period <> Dex.GetLastSettledMakerMinedVxPeriod(Db) + 1 then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidInputParam.Create('invalid input param'), SendBlock));
  end;
  if Dex.GetLastSettledMakerMinedVxPage(Db) > 0 then
  begin
    if Actions.Page <> Dex.GetLastSettledMakerMinedVxPage(Db) + 1 then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidInputParam.Create('invalid input param'), SendBlock));
  end;

  PoolAmt := Dex.GetMakerMiningPoolByPeriodId(Db, Actions.Period);
  if PoolAmt.Sign = 0 then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexExceedFundAvailable.Create('exceed fund available'), SendBlock));

  for Action in Actions.Actions do
  begin
    Addr := BytesToAddress(Action.Address);
    Amt := TBigInteger.FromByteArray(Action.Amount);
    if Amt.Compare(PoolAmt) > 0 then
      Amt := TBigInteger.Create(PoolAmt);

    if Dex.OnVxMined(Db, Vm.ConsensusReader, Addr, Amt) <> nil then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, Dex.OnVxMined(Db, Vm.ConsensusReader, Addr, Amt), SendBlock));

    PoolAmt := TBigInteger.Sub(PoolAmt, Amt);
    if PoolAmt.Sign <= 0 then
      Break;
  end;

  if PoolAmt.Sign > 0 then
  begin
    Dex.SaveMakerMiningPoolByPeriodId(Db, Actions.Period, PoolAmt);
    Dex.SaveLastSettledMakerMinedVxPage(Db, Actions.Page);
  end
  else
  begin
    Finish := True;
    Dex.DeleteMakerMiningPoolByPeriodId(Db, Actions.Period);
    Dex.SaveLastSettledMakerMinedVxPeriod(Db, Actions.Period);
    Dex.DeleteLastSettledMakerMinedVxPage(Db);
  end;
  Dex.AddSettleMakerMinedVxEvent(Db, Actions.Period, Actions.Page, Finish);
  Result := nil;
end;

{ TMethodDexFundConfigMarketAgents }

constructor TMethodDexFundConfigMarketAgents.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundConfigMarketAgents.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundConfigMarketAgents.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundConfigMarketAgents.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundConfigMarketAgents.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundConfigMarketAgentsQuota;
end;

function TMethodDexFundConfigMarketAgents.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamConfigMarketAgents;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamConfigMarketAgents>(Param), FMethodName, Block.Data);
  if (Param.ActionType <> Dex.GrantAgent) and (Param.ActionType <> Dex.RevokeAgent) then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  if (Length(Param.TradeTokens) = 0) or (Length(Param.TradeTokens) <> Length(Param.QuoteTokens)) then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  if Block.AccountAddress.Compare(Param.Agent) = 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundConfigMarketAgents.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamConfigMarketAgents;
  I: Integer;
  TradeToken: TTokenTypeId;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamConfigMarketAgents>(Param), FMethodName, SendBlock.Data);
  for I := 0 to High(Param.TradeTokens) do
  begin
    TradeToken := Param.TradeTokens[I];
    MarketInfo := Dex.GetMarketInfo(Db, TradeToken, Param.QuoteTokens[I]);
    Ok := MarketInfo.Valid;
    if not Ok then
      Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotExists.Create('trade market not exists'), SendBlock));

    case Param.ActionType of
      Dex.GrantAgent:
        if not Dex.IsMarketGrantedToAgent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId) then
        begin
          Dex.GrantMarketToAgent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId);
          Dex.AddGrantMarketToAgentEvent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId);
        end;
      Dex.RevokeAgent:
        if Dex.IsMarketGrantedToAgent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId) then
        begin
          Dex.RevokeMarketFromAgent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId);
          Dex.AddRevokeMarketFromAgentEvent(Db, SendBlock.AccountAddress, Param.Agent, MarketInfo.MarketId);
        end;
    end;
  end;
  Result := nil;
end;

{ TMethodDexFundPlaceAgentOrder }

constructor TMethodDexFundPlaceAgentOrder.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundPlaceAgentOrder.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundPlaceAgentOrder.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundPlaceAgentOrder.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundPlaceAgentOrder.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundPlaceAgentOrderQuota;
end;

function TMethodDexFundPlaceAgentOrder.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamPlaceAgentOrder;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamPlaceAgentOrder>(Param), FMethodName, Block.Data);
  Result := Dex.PreCheckOrderParam(Param.ParamPlaceOrder, True);
end;

function TMethodDexFundPlaceAgentOrder.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamPlaceAgentOrder;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamPlaceAgentOrder>(Param), FMethodName, SendBlock.Data);
  Blocks := Dex.DoPlaceOrder(Db, Param.ParamPlaceOrder, Param.Principal, SendBlock.AccountAddress, SendBlock.Hash);
  if Length(Blocks) > 0 then
    Result := Blocks
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('DoPlaceOrder failed'), SendBlock));
end;

{ TMethodDexFundLockVxForDividend }

constructor TMethodDexFundLockVxForDividend.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundLockVxForDividend.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundLockVxForDividend.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundLockVxForDividend.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundLockVxForDividend.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundLockVxForDividendQuota;
end;

function TMethodDexFundLockVxForDividend.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamLockVxForDividend;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamLockVxForDividend>(Param), FMethodName, Block.Data);
  if (Param.ActionType <> Dex.LockVx) and (Param.ActionType <> Dex.UnlockVx) then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  if Param.Amount.Compare(Dex.VxLockThreshold) < 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundLockVxForDividend.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamLockVxForDividend;
  UpdatedVxAccount: TDexProtoAccount;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamLockVxForDividend>(Param), FMethodName, SendBlock.Data);
  case Param.ActionType of
    Dex.LockVx:
      begin
        UpdatedVxAccount := Dex.LockVxForDividend(Db, SendBlock.AccountAddress, Param.Amount);
        if UpdatedVxAccount.Amount = nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('LockVxForDividend failed'), SendBlock));
        Dex.DoSettleVxFunds(Db, Vm.ConsensusReader, SendBlock.AccountAddress.Bytes, Param.Amount, UpdatedVxAccount);
      end;
    Dex.UnlockVx:
      begin
        UpdatedVxAccount := Dex.ScheduleVxUnlockForDividend(Db, SendBlock.AccountAddress, Param.Amount);
        if UpdatedVxAccount.Amount = nil then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('ScheduleVxUnlockForDividend failed'), SendBlock));
        Dex.AddVxUnlock(Db, Vm.ConsensusReader, SendBlock.AccountAddress, Param.Amount);
        Dex.DoSettleVxFunds(Db, Vm.ConsensusReader, SendBlock.AccountAddress.Bytes, TBigInteger.Negate(Param.Amount), UpdatedVxAccount);
      end;
  end;
  Result := nil;
end;

{ TMethodDexFundSwitchConfig }

constructor TMethodDexFundSwitchConfig.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexFundSwitchConfig.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexFundSwitchConfig.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexFundSwitchConfig.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexFundSwitchConfig.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundSwitchConfigQuota;
end;

function TMethodDexFundSwitchConfig.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamSwitchConfig;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSwitchConfig>(Param), FMethodName, Block.Data);
  if Param.SwitchType <> Dex.AutoLockMinedVx then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexFundSwitchConfig.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamSwitchConfig;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamSwitchConfig>(Param), FMethodName, SendBlock.Data);
  case Param.SwitchType of
    Dex.AutoLockMinedVx: Dex.SetAutoLockMinedVx(Db, SendBlock.AccountAddress.Bytes, Param.Enable);
  end;
  Result := nil;
end;

{ TMethodDexCancelOrderBySendHash }

constructor TMethodDexCancelOrderBySendHash.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexCancelOrderBySendHash.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexCancelOrderBySendHash.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexCancelOrderBySendHash.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexCancelOrderBySendHash.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundCancelOrderBySendHashQuota;
end;

function TMethodDexCancelOrderBySendHash.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamCancelOrderByHash;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamCancelOrderByHash>(Param), FMethodName, Block.Data);
  if (Param.Principal.Compare(TAddress.Zero) <> 0) and (Param.Principal.Compare(Block.AccountAddress) <> 0) then
  begin
    if (Param.TradeToken.Compare(TTokenTypeId.Zero) = 0) or (Param.QuoteToken.Compare(TTokenTypeId.Zero) = 0) then
      Exit(EDexInvalidInputParam.Create('invalid input param'));
  end;
  Result := nil;
end;

function TMethodDexCancelOrderBySendHash.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamCancelOrderByHash;
  Owner: TAddress;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamCancelOrderByHash>(Param), FMethodName, SendBlock.Data);
  Owner := Dex.CheckCancelAgentOrder(Db, SendBlock.AccountAddress, Param);
  if Owner.Bytes = nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('CheckCancelAgentOrder failed'), SendBlock));

  Blocks := Dex.DoCancelOrder(Param.SendHash, Owner);
  Result := Blocks;
end;

{ TMethodDexCommonAdminConfig }

constructor TMethodDexCommonAdminConfig.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexCommonAdminConfig.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexCommonAdminConfig.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexCommonAdminConfig.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexCommonAdminConfig.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundCommonAdminConfigQuota;
end;

function TMethodDexCommonAdminConfig.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamCommonAdminConfig;
begin
  Result := ABIDataDexFund.UnpackMethod(TValue.From<TDexParamCommonAdminConfig>(Param), FMethodName, Block.Data);
end;

function TMethodDexCommonAdminConfig.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamCommonAdminConfig;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  Blocks: TArray<TAccountBlock>;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamCommonAdminConfig>(Param), FMethodName, SendBlock.Data);
  if Dex.IsOwner(Db, SendBlock.AccountAddress) then
  begin
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.CommonAdminConfigStableMarket) then
    begin
      MarketInfo := Dex.GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
      Ok := MarketInfo.Valid;
      if Ok then
      begin
        if Param.Enable <> MarketInfo.StableMarket then
        begin
          MarketInfo.StableMarket := Param.Enable;
          Dex.SaveMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken);
          Dex.AddMarketEvent(Db, MarketInfo);
        end
        else
        begin
          if MarketInfo.StableMarket then
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketStableMarket.Create('trade market stable market'), SendBlock))
          else
            Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotStableMarket.Create('trade market not stable market'), SendBlock));
        end;
      end
      else
        Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexTradeMarketNotExists.Create('trade market not exists'), SendBlock));
    end;
    if Dex.IsOperationValidWithMask(Param.OperationCode, Dex.CommonAdminConfigMarketOrderAmtThreshold) and Dex.IsVersion11EnrichOrderFork(Db) then
    begin
      if Param.Amount.Sign > 0 then
      begin
        if not Dex.QuoteTokenTypeInfos.ContainsKey(Param.Value) then
          Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexInvalidInputParam.Create('invalid input param'), SendBlock));
        Dex.SaveMarketOrderAmtThreshold(Db, Param.Value, Param.Amount);
      end;
    end;
  end
  else
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, EDexOnlyOwnerAllow.Create('only owner allow'), SendBlock));
  Result := nil;
end;

{ TMethodDexTransfer }

constructor TMethodDexTransfer.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexTransfer.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexTransfer.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexTransfer.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexTransfer.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundTransferQuota;
end;

function TMethodDexTransfer.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamTransferConfig;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTransferConfig>(Param), FMethodName, Block.Data);
  if Param.Amount.Sign <= 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexTransfer.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamTransferConfig;
  Account: TDexProtoAccount;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamTransferConfig>(Param), FMethodName, SendBlock.Data);
  Account := Dex.ReduceAccount(Db, SendBlock.AccountAddress, Param.Token.Bytes, Param.Amount);
  if Account.Amount = nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('ReduceAccount failed'), SendBlock));

  Dex.DepositAccount(Db, Param.Target, Param.Token, Param.Amount);
  Dex.AddTransferAssetEvent(Db, Dex.TransferAssetTransfer, SendBlock.AccountAddress, Param.Target, Param.Token, Param.Amount, nil);
  Result := nil;
end;

{ TMethodDexAgentDeposit }

constructor TMethodDexAgentDeposit.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexAgentDeposit.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexAgentDeposit.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexAgentDeposit.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexAgentDeposit.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundAgentDepositQuota;
end;

function TMethodDexAgentDeposit.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Beneficiary: TAddress;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TAddress>(Beneficiary), FMethodName, Block.Data);
  if Block.Amount.Sign <= 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexAgentDeposit.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Beneficiary: TAddress;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TAddress>(Beneficiary), FMethodName, SendBlock.Data);
  Dex.DepositAccount(Db, Beneficiary, SendBlock.TokenId, SendBlock.Amount);
  Dex.AddTransferAssetEvent(Db, Dex.TransferAssetAgentDeposit, SendBlock.AccountAddress, Beneficiary, SendBlock.TokenId, SendBlock.Amount, nil);
  Result := nil;
end;

{ TMethodDexAssignedWithdraw }

constructor TMethodDexAssignedWithdraw.Create(const MethodName: string);
begin
  FMethodName := MethodName;
end;

function TMethodDexAssignedWithdraw.GetFee(Block: TAccountBlock): TBigInteger;
begin
  Result := TBigInteger.Create(0);
end;

function TMethodDexAssignedWithdraw.GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
begin
  Result := TPair<TBytes, Boolean>.Create([], False);
end;

function TMethodDexAssignedWithdraw.GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
begin
  Result := Util.RequestQuotaCost(Data, GasTable);
end;

function TMethodDexAssignedWithdraw.GetReceiveQuota(GasTable: TQuotaTable): UInt64;
begin
  Result := GasTable.DexFundAssignedWithdrawQuota;
end;

function TMethodDexAssignedWithdraw.DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
var
  Param: TDexParamAssignedWithdraw;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamAssignedWithdraw>(Param), FMethodName, Block.Data);
  if Param.Amount.Sign <= 0 then
    Exit(EDexInvalidInputParam.Create('invalid input param'));
  Result := nil;
end;

function TMethodDexAssignedWithdraw.DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
var
  Param: TDexParamAssignedWithdraw;
  Account: TDexProtoAccount;
begin
  ABIDataDexFund.UnpackMethod(TValue.From<TDexParamAssignedWithdraw>(Param), FMethodName, SendBlock.Data);
  Account := Dex.ReduceAccount(Db, SendBlock.AccountAddress, Param.Token.Bytes, Param.Amount);
  if Account.Amount = nil then
    Exit(HandleDexReceiveErr(FundLogger, FMethodName, Exception.Create('ReduceAccount failed'), SendBlock));

  Dex.DepositAccount(Db, Param.Target, Param.Token, Param.Amount);
  Dex.AddTransferAssetEvent(Db, Dex.TransferAssetAssignedWithdraw, SendBlock.AccountAddress, Param.Target, Param.Token, Param.Amount, Param.Label);
  Result := nil;
end;

initialization
  FundLogger := TLogger.Create;

end.
