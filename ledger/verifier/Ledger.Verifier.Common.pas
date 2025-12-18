unit common;

interface

uses
  Ledger.Verifier.Account.Verifier,
  Ledger.Verifier.Errors,
  Ledger.Verifier.Reader,
  Ledger.Verifier.Snapshot.Verifier,
  Ledger.Verifier.Snapshot.Verifier.Test,
  Ledger.Verifier.Verifier,
  System.SysUtils System.Classes,
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
