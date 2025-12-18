unit consensus.mock_dpos_reader;

interface

uses
  consensus.core,
  consensus.dpos,
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
  Ledger.Consensus.Mock.Linkedarray,
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
  Vite.Core,
  Vite.Types;

type
  TMockDposReader = class(TInterfacedObject, IDposReader)
  public
    function ElectionIndex(Index: UInt64): TElectionResult;
    function GetInfo: TGroupInfo;
    function Time2Index(T: TDateTime): UInt64;
    function Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
    function GenProofTime(T: UInt64): TDateTime;
    function VerifyProducer(const Address: TAddress; T: TDateTime): Boolean;
  end;

implementation

{ TMockDposReader }

function TMockDposReader.ElectionIndex(Index: UInt64): TElectionResult;
begin
  // Mock implementation
  Result := nil;
end;

function TMockDposReader.GetInfo: TGroupInfo;
begin
  // Mock implementation
  Result := nil;
end;

function TMockDposReader.Time2Index(T: TDateTime): UInt64;
begin
  // Mock implementation
  Result := 0;
end;

function TMockDposReader.Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
begin
  // Mock implementation
  Result := TTuple<TDateTime, TDateTime>.Create(0, 0);
end;

function TMockDposReader.GenProofTime(T: UInt64): TDateTime;
begin
  // Mock implementation
  Result := 0;
end;

function TMockDposReader.VerifyProducer(const Address: TAddress; T: TDateTime): Boolean;
begin
  // Mock implementation
  Result := False;
end;

end.
