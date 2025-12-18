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
