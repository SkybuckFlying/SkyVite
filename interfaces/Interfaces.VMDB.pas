unit Interfaces.VmDb;

interface

uses
  SysUtils, Classes, Generics.Collections, Math.BigInt,
  GoToDelphi.Helpers.BigInt,
  Common.Types,
  Interfaces.Core,
  Interfaces.Chain;

type
  IVmDb = interface;

  TVmAccountBlock = record
    AccountBlock: IAccountBlock;
    VmDb: IVmDb;
  end;

  IVmDb = interface(IInterface)
    ['{02070707-0707-0707-8707-070707070707}']
    // ====== Context ======
    function CanWrite: Boolean;
    function Address: ^TAddress;
    function LatestSnapshotBlock(out ParaError: Exception): ISnapshotBlock;
    function PrevAccountBlock(out ParaError: Exception): IAccountBlock;
    function GetLatestAccountBlock(ParaAddr: TAddress; out ParaError: Exception): IAccountBlock;
    function GetCallDepth(ParaSendBlockHash: ^THash; out ParaError: Exception): UInt16;
    function GetQuotaUsedList(ParaAddr: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;

    // ====== State ======
    function GetReceiptHash: ^THash;
    procedure Reset;
    procedure Finish;

    // ====== Storage ======
    function GetValue(ParaKey: TBytes; out ParaError: Exception): TBytes;
    function GetOriginalValue(ParaKey: TBytes; out ParaError: Exception): TBytes;
    function SetValue(ParaKey, ParaValue: TBytes): Exception;
    function NewStorageIterator(ParaPrefix: TBytes; out ParaError: Exception): IStorageIterator;
    function GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;

    // ====== Balance ======
    function GetBalance(ParaTokenTypeId: ^TTokenTypeId; out ParaError: Exception): TBigInt;
    procedure SetBalance(ParaTokenTypeId: ^TTokenTypeId; ParaAmount: ^TBigInt);
    function GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInt>;

    // ====== VMLog ======
    procedure AddLog(ParaLog: IVmLog);
    function GetLogList: IVmLogList;
    function GetHistoryLogList(ParaLogHash: ^THash; out ParaError: Exception): IVmLogList;
    function GetLogListHash: ^THash;

    // ====== AccountBlock ======
    function GetUnconfirmedBlocks(ParaAddress: TAddress): TArray<IAccountBlock>;

    // ====== SnapshotBlock ======
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetConfirmSnapshotHeader(ParaBlockHash: THash; out ParaError: Exception): ISnapshotBlock;
    function GetConfirmedTimes(ParaBlockHash: THash; out ParaError: Exception): UInt64;
    function GetSnapshotBlockByHeight(ParaHeight: UInt64; out ParaError: Exception): ISnapshotBlock;

    // ====== Meta & Code ======
    procedure SetContractMeta(ParaToAddr: TAddress; ParaMeta: IContractMeta);
    function GetContractMeta(out ParaError: Exception): IContractMeta;
    function GetContractMetaInSnapshot(ParaContractAddress: TAddress; ParaSnapshotBlock: ISnapshotBlock; out ParaError: Exception): IContractMeta;
    procedure SetContractCode(ParaCode: TBytes);
    function GetContractCode(out ParaError: Exception): TBytes;
    function GetContractCodeBySnapshotBlock(ParaAddr: ^TAddress; ParaSnapshotBlock: ISnapshotBlock; out ParaError: Exception): TBytes;
    function GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
    function GetUnsavedContractCode: TBytes;

    // ====== built-in contract ======
    function GetStakeBeneficialAmount(ParaAddr: ^TAddress; out ParaError: Exception): TBigInt;

    // ====== debug ======
    function DebugGetStorage(out ParaError: Exception): TDictionary<string, TBytes>;
  end;

implementation

end.
