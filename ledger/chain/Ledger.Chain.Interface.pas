unit Ledger.Chain.Interface;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  Go.leveldb,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Common.Types,
  V2.Ledger.Chain.Block,
  V2.Ledger.Chain.Flusher,
  V2.Ledger.Chain.Index,
  V2.Ledger.Chain.Plugins,
  V2.Ledger.Chain.State,
  V2.Ledger.Consensus.Core,
  V2.VM.Contracts.DEX;

type
  IConsensus = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-3B3B3B3B3B3B}']
    function VerifyAccountProducer(ParaBlock: IAccountBlock): Boolean;
    function SBPReader: ISBPStatReader;
    function VerifyABsProducer(ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
  end;

  IChain = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B3C}']
    // Lifecycle
    procedure Init;
    procedure Start;
    procedure Stop;
    procedure Destroy;

    // Event Manager
    procedure Register(ParaListener: IEventListener);
    procedure UnRegister(ParaListener: IEventListener);

    // C(Create)
    procedure InsertAccountBlock(ParaVmAccountBlocks: IVmAccountBlock);
    function InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;

    // D(Delete)
    function DeleteAccountBlocks(const ParaAddr: TAddress; const ParaToHash: THash): TArray<IAccountBlock>;
    function DeleteAccountBlocksToHeight(const ParaAddr: TAddress; ParaToHeight: TUInt64): TArray<IAccountBlock>;
    function DeleteSnapshotBlocks(const ParaToHash: THash): TArray<ISnapshotChunk>;
    function DeleteSnapshotBlocksToHeight(ParaToHeight: TUInt64): TArray<ISnapshotChunk>;

    // R(Retrieve)
    // ====== Query account block ======
    function IsGenesisAccountBlock(const ParaHash: THash): Boolean;
    function IsAccountBlockExisted(const ParaHash: THash): Boolean;
    function GetAccountBlockByHeight(const ParaAddr: TAddress; ParaHeight: TUInt64): IAccountBlock;
    function GetAccountBlockHashByHeight(const ParaAddr: TAddress; ParaHeight: TUInt64): THash;
    function GetAccountBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    function GetReceiveAbBySendAb(const ParaSendBlockHash: THash): IAccountBlock;
    function IsReceived(const ParaSendBlockHash: THash): Boolean;
    function GetAccountBlocks(const ParaBlockHash: THash; ParaCount: TUInt64): TArray<IAccountBlock>;
    function GetCompleteBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    function GetAccountBlocksByHeight(const ParaAddr: TAddress; ParaHeight: TUInt64; ParaCount: TUInt64): TArray<IAccountBlock>;
    function GetAccountBlocksByRange(const ParaAddr: TAddress; ParaStart, ParaEnd: TUInt64): TArray<IAccountBlock>;
    function GetCallDepth(const ParaSendBlock: THash): Word;
    function IsSeedConfirmedNTimes(const ParaBlockHash: THash; ParaN: TUInt64): Boolean;
    function GetConfirmedTimes(const ParaBlockHash: THash): TUInt64;
    function GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;
    function GetLatestAccountHeight(const ParaAddr: TAddress): TUInt64;

    // ====== Query snapshot block ======
    function IsGenesisSnapshotBlock(const ParaHash: THash): Boolean;
    function IsSnapshotBlockExisted(const ParaHash: THash): Boolean;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSnapshotHeightByHash(const ParaHash: THash): TUInt64;
    function GetSnapshotHeaderByHeight(ParaHeight: TUInt64): ISnapshotBlock;
    function GetSnapshotHashByHeight(ParaHeight: TUInt64): THash;
    function GetSnapshotBlockByHeight(ParaHeight: TUInt64): ISnapshotBlock;
    function GetSnapshotHeaderByHash(const ParaHash: THash): ISnapshotBlock;
    function GetSnapshotBlockByHash(const ParaHash: THash): ISnapshotBlock;
    function GetRangeSnapshotHeaders(const ParaStartHash, ParaEndHash: THash): TArray<ISnapshotBlock>;
    function GetRangeSnapshotBlocks(const ParaStartHash, ParaEndHash: THash): TArray<ISnapshotBlock>;
    function GetSnapshotHeaders(const ParaBlockHash: THash; ParaHigher: Boolean; ParaCount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocks(const ParaBlockHash: THash; ParaHigher: Boolean; ParaCount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotHeadersByHeight(ParaHeight: TUInt64; ParaHigher: Boolean; ParaCount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocksByHeight(ParaHeight: TUInt64; ParaHigher: Boolean; ParaCount: TUInt64): TArray<ISnapshotBlock>;
    function GetConfirmSnapshotHeaderByAbHash(const ParaAbHash: THash): ISnapshotBlock;
    function GetConfirmSnapshotBlockByAbHash(const ParaAbHash: THash): ISnapshotBlock;
    function GetSnapshotHeaderBeforeTime(ParaTimestamp: TDateTime): ISnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(const ParaEndHashHeight: IHashHeight; ParaStartTime: TDateTime; const ParaProducer: TAddress): TArray<ISnapshotBlock>;
    function GetLastUnpublishedSeedSnapshotHeader(const ParaProducer: TAddress; ParaBeforeTime: TDateTime): ISnapshotBlock;
    function GetRandomSeed(const ParaSnapshotHash: THash; ParaN: Integer): TUInt64;
    function GetSnapshotBlockByContractMeta(const ParaAddr: TAddress; const ParaFromHash: THash): ISnapshotBlock;
    function GetSeedConfirmedSnapshotBlock(const ParaAddr: TAddress; const ParaFromHash: THash): ISnapshotBlock;
    function GetSeed(const ParaLimitSb: ISnapshotBlock; const ParaFromHash: THash): TUInt64;
    function GetSubLedger(ParaStartHeight, ParaEndHeight: TUInt64): TArray<ISnapshotChunk>;
    function GetSubLedgerAfterHeight(ParaHeight: TUInt64): TArray<ISnapshotChunk>;

    // ====== Query unconfirmed pool ======
    function GetAllUnconfirmedBlocks: TArray<IAccountBlock>;
    function GetUnconfirmedBlocks(const ParaAddr: TAddress): TArray<IAccountBlock>;
    function GetContentNeedSnapshot: ISnapshotContent;
    function GetContentNeedSnapshotRange: TDictionary<TAddress, IHeightRange>;

    // ====== Query account ======
    procedure IterateContracts(ParaIterateFunc: TFunc<TAddress, IContractMeta, string, Boolean>);
    procedure IterateAccounts(ParaIterateFunc: TFunc<TAddress, TUInt64, string, Boolean>);

    // ===== Query state ======
    function GetBalance(const ParaAddr: TAddress; const ParaTokenId: TTokenTypeId): TBigInteger;
    function GetBalanceMap(const ParaAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
    function GetConfirmedBalanceList(const ParaAddrList: TArray<TAddress>; const ParaTokenId: TTokenTypeId; const ParaSbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetContractCode(const ParaContractAddr: TAddress): TBytes;
    function GetContractMeta(const ParaContractAddress: TAddress): IContractMeta;
    function GetContractMetaInSnapshot(const ParaContractAddress: TAddress; ParaSnapshotHeight: TUInt64): IContractMeta;
    function GetContractList(const ParaGid: TGid): TArray<TAddress>;
    function GetQuotaUnused(const ParaAddress: TAddress): TUInt64;
    function GetGlobalQuota: IQuotaInfo;
    function GetQuotaUsedList(const ParaAddress: TAddress): TArray<IQuotaInfo>;
    function GetStorageIterator(const ParaAddress: TAddress; const ParaPrefix: TBytes): IStorageIterator;
    function GetValue(const ParaAddress: TAddress; const ParaKey: TBytes): TBytes;
    function GetVmLogList(const ParaLogListHash: THash): IVmLogList;
    function GetVMLogListByAddress(const ParaAddress: TAddress; ParaStart, ParaEnd: TUInt64; const ParaId: THash): IVmLogList;

    // ====== Query built-in contract storage ======
    function GetRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IRegistration>;
    function GetAllRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IRegistration>;
    function GetConsensusGroupList(const ParaSnapshotHash: THash): TArray<IConsensusGroupInfo>;
    function GetConsensusGroup(const ParaSnapshotHash: THash; const ParaGid: TGid): IConsensusGroupInfo;
    function GetVoteList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IVoteInfo>;
    function GetStakeBeneficialAmount(const ParaAddr: TAddress): TBigInteger;
    function GetStakeQuota(const ParaAddr: TAddress; out ParaQuota: IQuota): TBigInteger;
    function GetStakeQuotas(const ParaAddrList: TArray<TAddress>): TDictionary<TAddress, IQuota>;
    function GetTokenInfoById(const ParaTokenId: TTokenTypeId): ITokenInfo;
    function GetAllTokenInfo: TDictionary<TTokenTypeId, ITokenInfo>;
    function CalVoteDetails(const ParaGid: TGid; ParaInfo: IGroupInfo; const ParaSnapshotBlock: IHashHeight): TArray<IVoteDetails>;
    function GetStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: TUInt64; out ParaNextKey: TBytes): TArray<IStakeInfo>;
    function GetDexFundsByPage(const ParaSnapshotHash: THash; const ParaLastAddress: TAddress; ParaCount: Integer): TArray<IDexFund>;
    function GetDexStakeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: TBytes; ParaCount: Integer; out ParaNextKey: TBytes): TArray<IDelegateStakeInfo>;

    // ====== Sync ledger ======
    function GetLedgerReaderByHeight(ParaStartHeight, ParaEndHeight: TUInt64): ILedgerReader;
    function GetSyncCache: ISyncCache;

    // ====== OnRoad ======
    procedure LoadOnRoadRange(const ParaGid: TGid; ParaFn: TLoadOnroadFn);
    procedure DeleteOnRoad(const ParaToAddress: TAddress; const ParaSendBlockHash: THash);
    function GetOnRoadBlocksByAddr(const ParaAddr: TAddress; ParaPageNum, ParaPageSize: Integer): TArray<IAccountBlock>;
    function LoadAllOnRoad: TDictionary<TAddress, TArray<THash>>;
    function GetAccountOnRoadInfo(const ParaAddr: TAddress): IAccountInfo;
    function GetOnRoadInfoUnconfirmedHashList(const ParaAddr: TAddress): TArray<THash>;
    procedure UpdateOnRoadInfo(const ParaAddr: TAddress; const ParaTkId: TTokenTypeId; ParaNumber: TUInt64; ParaAmount: TBigInteger);
    procedure ClearOnRoadUnconfirmedCache(const ParaAddr: TAddress; const ParaHashList: TArray<THash>);

    // ====== Other ======
    procedure SetCacheLevelForConsensus(ParaLevel: Cardinal);
    function NewDb(const ParaDirName: string): TLevelDB;
    function PrepareOnroadDb: TLevelDB;
    function Plugins: TPlugins;
    procedure SetConsensus(ParaVerifier: IConsensusVerifier; ParaPeriodTimeIndex: ITimeIndex);
    function DBs: TTuple<TIndexDB, TBlockDB, TStateDB>;
    function Flusher: TFlusher;
    procedure StopWrite;
    procedure RecoverWrite;
    procedure WriteGenesisCheckSum(const ParaHash: THash);
    function QueryGenesisCheckSum: THash;

    // ====== Check ======
    function CheckRedo: string;
    function CheckRecentBlocks: string;
    function CheckOnRoad: string;
    function GetStatus: TArray<IDBStatus>;
  end;

implementation

end.