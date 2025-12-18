unit Interfaces.Core.Serializable;

interface

uses
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils;

type
  ISerializable = interface(IInterface)
    ['{B8F5F3E9-449B-473F-B52F-3833927A56C1}']
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
  end;

implementation

end.
