unit Common.Types.Enum;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  System.SysUtils;

type
  // IEnum defines the interface for an enumerable type.
  IEnum = interface
    ['{B7E4F8B9-3B1F-4B7C-8C2E-9A5D2B7E4F8B}']
    // GetName returns the string name of the enum value.
    function GetName: string;
    // GetOrdinal returns the integer ordinal of the enum value.
    function GetOrdinal: Integer;
    // GetValues returns a list of all possible string values for the enum.
    function GetValues: TArray<string>;

    property Name: string read GetName;
    property Ordinal: Integer read GetOrdinal;
    property Values: TArray<string> read GetValues;
  end;

implementation

end.
