unit common;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common;

type
  TVerifyResult = (vrPending, vrFail, vrSuccess);

  TSnapshotPendingTask = record
    Hash: PHash;
  end;

  TAccountPendingTask = record
    Addr: PAddress;
    Hash: PHash;
  end;

implementation

end.
