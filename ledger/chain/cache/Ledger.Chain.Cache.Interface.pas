unit Ledger.Chain.Cache.Interfaces;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Cache,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Hot.Data,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Quota,
  Ledger.Chain.Cache.Quota.List,
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils Interfaces.Core;

type
  IChain = interface
    ['{E3B4C5D6-F7A8-B9C0-D1E2-F3A4B5C6D7E8}']
    function QueryLatestSnapshotBlock: TSnapshotBlock;
    function QuerySnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
    function GetSnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
    function GetSubLedger(ParaEndHeight, ParaStartHeight: UInt64): TArray<TSnapshotChunk>;
    function GetSubLedgerAfterHeight(ParaHeight: UInt64): TArray<TSnapshotChunk>;
  end;

implementation

end.
