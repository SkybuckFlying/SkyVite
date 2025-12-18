unit Common.Types.Height;

interface
uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test;

const
  ConstHeightSize = 8;
  ConstAccountIdSize = 8;

var
  gEmptyHeight: UInt64 = 0;
  gGenesisHeight: UInt64 = 1;

implementation

end.
