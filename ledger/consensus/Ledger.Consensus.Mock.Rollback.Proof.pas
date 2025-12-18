unit consensus.mock_rollback_proof;

interface

uses
  consensus.rollback_proof,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Golang.Mock.GoMock.Call,
  Vendor.Github.Com.Golang.Mock.GoMock.Callset,
  Vendor.Github.Com.Golang.Mock.GoMock.Controller,
  Vendor.Github.Com.Golang.Mock.GoMock.Matchers,
  Vite.Core,
  Vite.Types;

type
  TMockRollbackProof = class(TInterfacedObject, IRollbackProof)
  public
    function Proof(const Arg0: THash; Arg1: TDateTime): TSnapshotBlock;
    function ProofEmpty(Arg0, Arg1: TDateTime): Boolean;
    function ProofHash(Arg0: TDateTime): THash;
  end;

implementation

{ TMockRollbackProof }

function TMockRollbackProof.Proof(const Arg0: THash; Arg1: TDateTime): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockRollbackProof.ProofEmpty(Arg0, Arg1: TDateTime): Boolean;
begin
  // Mock implementation
  Result := False;
end;

function TMockRollbackProof.ProofHash(Arg0: TDateTime): THash;
begin
  // Mock implementation
  Result := nil;
end;

end.
