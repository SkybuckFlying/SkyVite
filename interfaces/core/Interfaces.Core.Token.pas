unit Interfaces.Core.Token;

interface

uses
  Common.Types,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils;

var
  ViteTokenId: TTokenTypeId;
  VCPTokenId: TTokenTypeId;

implementation

var
  vError: Exception;

initialization
  ViteTokenId := TTokenTypeId.FromBytes([Byte('V'), Byte('I'), Byte('T'), Byte('E'), Byte(' '), Byte('T'), Byte('O'), Byte('K'), Byte('E'), Byte('N')], vError);
  VCPTokenId := TTokenTypeId.FromHexString('tti_251a3e67a41b5ea2373936c8', vError);

end.
