unit Ledger.Chain.State.Interface;

interface

uses
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.MemDB,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  Ledger.Consensus.Core,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SysUtils;

type
  TIterateAccountsFunc = reference to function(AAddr: TAddress; AAccountId: UInt64; AErr: HResult): Boolean;

  IConsensus = interface
    ['{F4C8E4E1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function VerifyAccountProducer(ABlock: TAccountBlock): Boolean;
    function SBPReader: ISBPStatReader;
  end;

  ITimeIndex = interface
    ['{E1B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function Index2Time(AIndex: UInt64; out AStartTime, AEndTime: TDateTime): void;
    function Time2Index(ATime: TDateTime): UInt64;
  end;

  IChain = interface
    ['{B1B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    procedure IterateAccounts(AIterateFunc: TIterateAccountsFunc);
    function QueryLatestSnapshotBlock: TSnapshotBlock;
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetSnapshotHeightByHash(AHash: THash): UInt64;
    function GetUnconfirmedBlocks(AAddr: TAddress): TArray<TAccountBlock>;
    function GetAccountBlockByHash(ABlockHash: THash): TAccountBlock;
    function GetSnapshotHeaderBeforeTime(ATimestamp: TDateTime): TSnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(AEndHashHeight: THashHeight; AStartTime: TDateTime; AProducer: TAddress): TArray<TSnapshotBlock>;
    function GetSnapshotHeaderByHeight(AHeight: UInt64): TSnapshotBlock;
    procedure StopWrite;
    procedure RecoverWrite;
  end;

  IRoundCache = interface
    ['{A1B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function Init(ATimeIndex: ITimeIndex): HResult;
    function InsertSnapshotBlock(ASnapshotBlock: TSnapshotBlock; ASnapshotLog: TSnapshotLog): HResult;
    function DeleteSnapshotBlocks(ASnapshotBlocks: TArray<TSnapshotBlock>): HResult;
    function GetSnapshotViteBalanceList(ASnapshotHash: THash; AAddrList: TArray<TAddress>; out AMissingAddrList: TArray<TAddress>): TDictionary<TAddress, TBigInteger>;
    function StorageIterator(ASnapshotHash: THash): IStorageIterator;
    function GetCurrentData(ASnapshotHash: THash): TMemDB;
    function InitRounds(AStartRoundIndex, AEndRoundIndex: UInt64): TArray<TRedoCacheData>;
    function QueryCurrentData(ARoundIndex: UInt64; out ASnapshotBlock: TSnapshotBlock): TMemDB;
    function QueryRedoLogs(ARoundIndex: UInt64; out AIsStoreRedoLogs: Boolean): TRoundCacheRedoLogs;
    function BuildCurrentData(APrevCurrentData: TMemDB; ARedoLogs: TRoundCacheRedoLogs): TMemDB;
    function RoundToLastSnapshotBlock(ARoundIndex: UInt64): TSnapshotBlock;
    function GetRoundSnapshotBlocks(ARoundIndex: UInt64): TArray<TSnapshotBlock>;
    function SetAllBalanceToCache(ARoundData: TMemDB; ASnapshotHash: THash): HResult;
    function SetBalanceToCache(ARoundData: TMemDB; ASnapshotHash: THash; AAddressList: TArray<TAddress>): HResult;
    function SetStorageToCache(ARoundData: TMemDB; AContractAddress: TAddress; ASnapshotHash: THash): HResult;
  end;

  IStateDB = interface
    ['{91B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function NewStorageIterator(AAddr: TAddress; APrefix: TBytes): IStorageIterator;
    function NewSnapshotStorageIteratorByHeight(ASnapshotHeight: UInt64; AAddr: TAddress; APrefix: TBytes): IStorageIterator;
    function NewSnapshotStorageIterator(ASnapshotHash: THash; AAddr: TAddress; APrefix: TBytes): IStorageIterator;
    function NewRawSnapshotStorageIteratorByHeight(ASnapshotHeight: UInt64; AAddr: TAddress; APrefix: TBytes): IStorageIterator;
    function RollbackSnapshotBlocks(ADeletedSnapshotSegments: TArray<TSnapshotChunk>; ANewUnconfirmedBlocks: TArray<TAccountBlock>): HResult;
    function RollbackAccountBlocks(AAccountBlocks: TArray<TAccountBlock>): HResult;
    function RollbackByRedo(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; ARedoLogMap: TDictionary<TAddress, TArray<TLogItem>>; ARollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>; ARollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>): HResult;
    function RecoverLatestIndexToSnapshot(ABatch: TBatch; AHashHeight: THashHeight; AKeySetMap: TDictionary<TAddress, TDictionary<string, Boolean>>; ATokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>): HResult;
    procedure RecoverLatestIndexByRedo(ABatch: TBatch; AAddrMap: TDictionary<TAddress, Boolean>; ARedoLogMap: TDictionary<TAddress, TArray<TLogItem>>; ARollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>; ARollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>);
    procedure RollbackAccountBlock(ABatch: TBatch; AAccountBlock: TAccountBlock);
    function RecoverToSnapshot(ABatch: TBatch; ASnapshotHeight: UInt64; AUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>; AAddrMap: TDictionary<TAddress, Boolean>): HResult;
    function RecoverStorageToSnapshot(ABatch: TBatch; AHeight: UInt64; AAddr: TAddress; AKeySet: TDictionary<string, TBytes>): HResult;
    function RecoverBalanceToSnapshot(ABatch: TBatch; AHeight: UInt64; AAddr: TAddress; ATokenSet: TDictionary<TTokenTypeId, TBigInteger>): HResult;
    procedure CompactHistoryStorage;
    procedure DeleteContractMeta(ABatch: IBatch; AKey: TBytes);
    procedure DeleteBalance(ABatch: IBatch; AKey: TBytes);
    procedure DeleteHistoryKey(ABatch: IBatch; AKey: TBytes);
    function RollbackRoundCache(ADeletedSnapshotSegments: TArray<TSnapshotChunk>): HResult;
    function Init: HResult;
    function Close: HResult;
    function SetTimeIndex(APeriodTimeIndex: ITimeIndex): HResult;
    function GetStorageValue(AAddr: TAddress; AKey: TBytes): TBytes;
    function GetBalance(AAddr: TAddress; ATokenTypeId: TTokenTypeId): TBigInteger;
    function GetBalanceMap(AAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
    function GetCode(AAddr: TAddress): TBytes;
    function GetContractMeta(AAddr: TAddress): TContractMeta;
    procedure IterateContracts(AIterateFunc: TIterateContractsFunc);
    function HasContractMeta(AAddr: TAddress): Boolean;
    function GetContractList(AGid: TGid): TArray<TAddress>;
    function GetVmLogList(ALogHash: THash): TVmLogList;
    function GetCallDepth(ASendBlockHash: THash): Word;
    function GetSnapshotBalanceList(ABalanceMap: TDictionary<TAddress, TBigInteger>; ASnapshotBlockHash: THash; AAddrList: TArray<TAddress>; ATokenId: TTokenTypeId): HResult;
    function GetSnapshotValue(ASnapshotBlockHeight: UInt64; AAddr: TAddress; AKey: TBytes): TBytes;
    procedure SetCacheLevelForConsensus(ALevel: Cardinal);
    function Store: TStore;
    function RedoStore: TStore;
    function Redo: IRedo;
    function GetStatus: TArray<IDBStatus>;
    function GetSnapshotBalanceList(ABalanceMap: TDictionary<TAddress, TBigInteger>; ASnapshotBlockHash: THash; AAddrList: TArray<TAddress>; ATokenId: TTokenTypeId): HResult;
    function NewStorageDatabase(ASnapshotHash: THash; AAddr: TAddress): IStorageDatabase;
    function NewCache: HResult;
    function InitCache: HResult;
    procedure DisableCache;
    procedure EnableCache;
    function InitSnapshotValueCache: HResult;
    function InitContractMetaCache: HResult;
    function GetValue(AKey: TBytes; ACachePrefix: string): TBytes;
    function GetValueInCache(AKey: TBytes; ACachePrefix: string): TBytes;
    function ParseStorageKey(AKey: TBytes): TBytes;
    function CopyValue(AValue: TBytes): TBytes;
    function Write(ABlock: IVmAccountBlock): HResult;
    procedure WriteByRedo(ABlockHash: THash; AAddr: TAddress; ARedoLog: TLogItem);
    function InsertSnapshotBlock(ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
    procedure WriteContractMeta(ABatch: IBatch; AKey, AValue: TBytes);
    procedure WriteBalance(ABatch: IBatch; AKey, AValue: TBytes);
    procedure WriteHistoryKey(ABatch: IBatch; AKey, AValue: TBytes);
    function CanWriteVmLog(AAddr: TAddress): Boolean;
  end;

  IStorageDatabase = interface
    ['{81B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function GetValue(AKey: TBytes): TBytes;
    function NewStorageIterator(APrefix: TBytes): IStorageIterator;
    function Address: TAddress;
  end;

  IRedo = interface
    ['{71B0F4B1-4B2B-4B3F-8C3C-8E4B4B4B4B4B}']
    function InitCache: HResult;
    function Close: HResult;
    procedure InsertSnapshotBlock(ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>);
    function HasRedo(ASnapshotHeight: UInt64): Boolean;
    function QueryLog(ASnapshotHeight: UInt64; out AFound: Boolean): TSnapshotLog;
    procedure SetCurrentSnapshot(ASnapshotHeight: UInt64; ALogMap: TSnapshotLog);
    procedure AddLog(AAddr: TAddress; ALog: TLogItem);
    procedure Rollback(AChunks: TArray<TSnapshotChunk>);
  end;

implementation

end.
