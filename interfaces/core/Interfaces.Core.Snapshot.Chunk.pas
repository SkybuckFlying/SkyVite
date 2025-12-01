unit Interfaces.Core.SnapshotChunk;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Interfaces.Core.AccountBlock, Interfaces.Core.SnapshotBlock;

type
  TSnapshotChunk = record
    SnapshotBlock: TSnapshotBlock;
    AccountBlocks: TArray<TAccountBlock>;
  end;

implementation

end.
