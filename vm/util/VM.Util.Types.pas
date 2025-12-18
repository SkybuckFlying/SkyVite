unit vm.util.types;

interface

uses
  interfaces.core,
  SysUtils,
  VM.Util.Common,
  VM.Util.Consensus.Reader,
  VM.Util.DB.Helper,
  VM.Util.Errors,
  VM.Util.IntPool,
  VM.Util.Intpool.Test,
  VM.Util.Quota,
  VM.Util.Quota.Test;

type
  IGlobalStatus = interface
    ['{B8B9B9B8-B9B8-B9B8-B9B8-B9B8B9B8B9B8}']
    function Seed: UInt64;
    function Random: UInt64;
    function SnapshotBlock: TSnapshotBlock;
  end;

implementation

end.
