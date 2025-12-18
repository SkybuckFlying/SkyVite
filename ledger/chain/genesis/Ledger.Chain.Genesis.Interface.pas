unit Ledger.Chain.Genesis.Interface;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Genesis.Account.Block,
  Ledger.Chain.Genesis.Check.Sum,
  Ledger.Chain.Genesis.Genesis,
  Ledger.Chain.Genesis.Snapshot.Block,
  System.SysUtils;

type
  IChain = interface
    ['{E5F4B3C2-4A6B-4C8D-9A2D-2F3E6E1D0A7C}']
    function InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;
    function InsertAccountBlock(ParaVmAccountBlocks: IVmAccountBlock): Exception;
    function QuerySnapshotBlockByHeight(ParaHeight: UInt64): ISnapshotBlock;
    function GetContentNeedSnapshot: ISnapshotContent;

    function WriteGenesisCheckSum(ParaHash: THash): Exception;
    function QueryGenesisCheckSum: PHash;
  end;

implementation

end.
