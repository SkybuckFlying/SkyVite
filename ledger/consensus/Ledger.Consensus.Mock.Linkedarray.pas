unit consensus.mock_linked_array;

interface

uses
  consensus.cdb,
  consensus.point_array,
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
  Ledger.Consensus.Mock.Rollback.Proof,
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
  Vite.Types;

type
  TMockLinkedArray = class(TInterfacedObject, ILinkedArray)
  public
    function GetByIndex(Index: UInt64): TPoint;
    function GetByIndexWithProof(Index: UInt64; const ProofHash: THash): TPoint;
    function Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
    function Time2Index(T: TDateTime): UInt64;
  end;

implementation

{ TMockLinkedArray }

function TMockLinkedArray.GetByIndex(Index: UInt64): TPoint;
begin
  // Mock implementation
  Result := nil;
end;

function TMockLinkedArray.GetByIndexWithProof(Index: UInt64; const ProofHash: THash): TPoint;
begin
  // Mock implementation
  Result := nil;
end;

function TMockLinkedArray.Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
begin
  // Mock implementation
  Result := TTuple<TDateTime, TDateTime>.Create(0, 0);
end;

function TMockLinkedArray.Time2Index(T: TDateTime): UInt64;
begin
  // Mock implementation
  Result := 0;
end;

end.
