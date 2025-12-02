unit Ledger.Chain.Plugins.Interface;

interface

uses
  System.SysUtils,
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.Flusher;

type
  IChain = interface
    ['{12345678-1234-1234-1234-1234567890AC}']
    function Flusher: TFlusher;
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetSnapshotBlocksByHeight(AHeight: UInt64; AHigher: Boolean; ACount: UInt64): TArray<TSnapshotBlock>;
    function GetSubLedgerAfterHeight(AHeight: UInt64): TArray<TSnapshotChunk>;
    function GetSubLedger(AStartHeight, AEndHeight: UInt64): TArray<TSnapshotChunk>;
    function GetAccountBlockByHash(const ABlockHash: THash): TAccountBlock;
    function IsAccountBlockExisted(const AHash: THash): Boolean;
    function IsGenesisAccountBlock(const AHash: THash): Boolean;
    function GetAllUnconfirmedBlocks: TArray<TAccountBlock>;
    function LoadAllOnRoad: TDictionary<TAddress, TArray<THash>>;
  end;

  IPlugin = interface
    ['{12345678-1234-1234-1234-1234567890AD}']
    procedure SetStore(AStore: TStore);
    function InsertAccountBlock(ABatch: TBatch; AAccountBlock: TAccountBlock): HResult;
    function InsertSnapshotBlock(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
    function DeleteAccountBlocks(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
    function DeleteSnapshotBlocks(ABatch: TBatch; AChunks: TArray<TSnapshotChunk>): HResult;
    function RemoveNewUnconfirmed(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
  end;

implementation

end.
