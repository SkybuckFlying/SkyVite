unit Ledger.Chain.Cache.Interfaces;

interface

uses
  System.SysUtils, Interfaces.Core;

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
