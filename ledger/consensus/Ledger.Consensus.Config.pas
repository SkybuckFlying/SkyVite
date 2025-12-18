unit Ledger.Consensus.Config;

interface

uses
  Common.Types,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
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
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test;

type
  TConsensusParms = record
    ConsensusMaxBlockTime: Int64;
  end;

  TConsensusCfg = class
  private
    FConsensusParms: TConsensusParms;
  public
    property ConsensusParms: TConsensusParms read FConsensusParms write FConsensusParms;
  end;

function DefaultCfg: TConsensusCfg;
function FullCfg: TConsensusCfg;

implementation

function DefaultCfg: TConsensusCfg;
begin
  Result := TConsensusCfg.Create;
  Result.ConsensusParms.ConsensusMaxBlockTime := 10;
end;

function FullCfg: TConsensusCfg;
begin
  Result := TConsensusCfg.Create;
  Result.ConsensusParms.ConsensusMaxBlockTime := 0;
end;

end.
