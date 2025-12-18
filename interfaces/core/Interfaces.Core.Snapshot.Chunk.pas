unit Interfaces.Core.SnapshotChunk;

interface

uses
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.AccountBlock Interfaces.Core.SnapshotBlock,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TSnapshotChunk = record
    SnapshotBlock: TSnapshotBlock;
    AccountBlocks: TArray<TAccountBlock>;
  end;

implementation

end.
