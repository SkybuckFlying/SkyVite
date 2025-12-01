unit Ledger.Consensus.Config;

interface

uses
  Common.Types;

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