unit Interfaces.Generator;

interface

uses
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Interfaces.Chain,
  Interfaces.Consensus,
  Interfaces.Core,
  Interfaces.Verifier,
  Interfaces.VmDb,
  Interfaces.Wallet,
  SysUtils Classes Math.BigInt;

type
  // GenResult represents the result of a block being validated by vm.
  TGenResult = record
    VMBlock: IVmAccountBlock;
    IsRetry: Boolean;
    Err: Exception;
  end;

  // IncomingMessage carries the necessary transaction info.
  TIncomingMessage = record
    BlockType: Byte;
    AccountAddress: TAddress;
    ToAddress: ^TAddress;
    FromBlockHash: ^THash;
    TokenId: ^TTokenTypeId;
    Amount: ^TBigInt;
    Fee: ^TBigInt;
    Data: TBytes;
    Difficulty: ^TBigInt;
  end;

  TSignFunc = reference to function(ParaData: TBytes; out ParaError: Exception): TBytes;

  IGenerator = interface(IInterface)
    ['{D0F5F5F5-5F5F-5F5F-AF5F-5F5F5F5F5F5F}']
    function GenerateWithBlock(ParaBlock, ParaFromBlock: IAccountBlock; out ParaError: Exception): TGenResult;
    function GenerateWithMessage(ParaMessage: TIncomingMessage; ParaProducer: TAddress; ParaSignFunc: TSignFunc; out ParaError: Exception): TGenResult;
    function GenerateWithOnRoad(ParaSendBlock: IAccountBlock; ParaProducer: TAddress; ParaSignFunc: TSignFunc; ParaDifficulty: ^TBigInt; out ParaError: Exception): TGenResult;
    function GetVMDB: IVmDb;
  end;

implementation

end.
