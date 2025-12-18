unit consensus.mock_ch;

interface

uses
  consensus.chain_rw,
  Go.leveldb,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SysUtils,
  Vendor.Github.Com.Golang.Mock.GoMock.Call,
  Vendor.Github.Com.Golang.Mock.GoMock.Callset,
  Vendor.Github.Com.Golang.Mock.GoMock.Controller,
  Vendor.Github.Com.Golang.Mock.GoMock.Matchers,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Cache,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Lru,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.BytesComparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbSnapshot,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbState,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbWrite,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Doc,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Bloom,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.ArrayIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.IndexedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.MergedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Journal.Journal,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Memdb.Memdb,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.OptionsDarwin,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.OptionsDefault,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageNacl,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStoragePlan9,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageSolaris,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageUnix,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageWindows,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.MemStorage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Reader,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Writer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Buffer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.BufferPool,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Hash,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Range,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version,
  Vite.Core,
  Vite.Interfaces,
  Vite.Types;

type
  TMockChain = class(TInterfacedObject, IChain)
  public
    function GetAllRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<TRegistration>;
    function GetConfirmedBalanceList(const AddrList: TArray<TAddress>; const TokenID: TTokenTypeId; const SbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetConsensusGroupList(const SnapshotHash: THash): TArray<TConsensusGroupInfo>;
    function GetContractMeta(const ContractAddress: TAddress): TContractMeta;
    function GetGenesisSnapshotBlock: TSnapshotBlock;
    function GetLastUnpublishedSeedSnapshotHeader(const Producer: TAddress; BeforeTime: TDateTime): TSnapshotBlock;
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetRandomSeed(const SnapshotHash: THash; N: Integer): UInt64;
    function GetRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<TRegistration>;
    function GetSnapshotBlockByHash(const Hash: THash): TSnapshotBlock;
    function GetSnapshotBlockByHeight(Height: UInt64): TSnapshotBlock;
    function GetSnapshotHeaderBeforeTime(Timestamp: TDateTime): TSnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(const EndHashHeight: THashHeight; StartTime: TDateTime; const Producer: TAddress): TArray<TSnapshotBlock>;
    function GetVoteList(const SnapshotHash: THash; const Gid: TGid): TArray<TVoteInfo>;
    function IsGenesisSnapshotBlock(const Hash: THash): Boolean;
    function NewDb(const DbDir: string): TLevelDB;
    procedure Register(Listener: IEventListener);
    procedure UnRegister(Listener: IEventListener);
  end;

implementation

{ TMockChain }

function TMockChain.GetAllRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<TRegistration>;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetConfirmedBalanceList(const AddrList: TArray<TAddress>; const TokenID: TTokenTypeId; const SbHash: THash): TDictionary<TAddress, TBigInteger>;
begin
  // Mock implementation
  Result := TDictionary<TAddress, TBigInteger>.Create;
end;

function TMockChain.GetConsensusGroupList(const SnapshotHash: THash): TArray<TConsensusGroupInfo>;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetContractMeta(const ContractAddress: TAddress): TContractMeta;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetGenesisSnapshotBlock: TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetLastUnpublishedSeedSnapshotHeader(const Producer: TAddress; BeforeTime: TDateTime): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetLatestSnapshotBlock: TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetRandomSeed(const SnapshotHash: THash; N: Integer): UInt64;
begin
  // Mock implementation
  Result := 0;
end;

function TMockChain.GetRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<TRegistration>;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetSnapshotBlockByHash(const Hash: THash): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetSnapshotBlockByHeight(Height: UInt64): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetSnapshotHeaderBeforeTime(Timestamp: TDateTime): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetSnapshotHeadersAfterOrEqualTime(const EndHashHeight: THashHeight; StartTime: TDateTime; const Producer: TAddress): TArray<TSnapshotBlock>;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.GetVoteList(const SnapshotHash: THash; const Gid: TGid): TArray<TVoteInfo>;
begin
  // Mock implementation
  Result := nil;
end;

function TMockChain.IsGenesisSnapshotBlock(const Hash: THash): Boolean;
begin
  // Mock implementation
  Result := False;
end;

function TMockChain.NewDb(const DbDir: string): TLevelDB;
begin
  // Mock implementation
  Result := nil;
end;

procedure TMockChain.Register(Listener: IEventListener);
begin
  // Mock implementation
end;

procedure TMockChain.UnRegister(Listener: IEventListener);
begin
  // Mock implementation
end;

end.
