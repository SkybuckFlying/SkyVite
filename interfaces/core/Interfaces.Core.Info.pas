unit Interfaces.Core.Info;

interface

uses
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils System.Generics.Collections Math.BigInt;

type
  TTokenBalanceInfo = record
    TotalAmount: TBigInt;
    Number: UInt64;
  end;

  TAccountInfo = record
    AccountAddress: TAddress;
    TotalNumber: UInt64;
    TokenBalanceInfoMap: TDictionary<TTokenTypeId, TTokenBalanceInfo>;
  end;

implementation

end.
