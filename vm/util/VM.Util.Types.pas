unit vm.util.types;

interface

uses
  interfaces.core,
  SysUtils;

type
  IGlobalStatus = interface
    ['{B8B9B9B8-B9B8-B9B8-B9B8-B9B8B9B8B9B8}']
    function Seed: UInt64;
    function Random: UInt64;
    function SnapshotBlock: TSnapshotBlock;
  end;

implementation

end.
