unit Ledger.Consensus.Core.Utils;

interface

uses
  Common.Types,
  Ledger.Consensus.Core.Consensus,
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader.Test,
  Ledger.Consensus.Core.State.Reader,
  Ledger.Consensus.Core.State.Reader // Assuming TVote is defined here,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.Time.Index.Test,
  Ledger.Consensus.Core.Vote.Algo,
  Ledger.Consensus.Core.Vote.Algo.Test,
  System.SysUtils;

function ConvertVoteToAddress(const AVotes: TArray<TVote>): TArray<TAddress>;

implementation

function ConvertVoteToAddress(const AVotes: TArray<TVote>): TArray<TAddress>;
var
  vVote: TVote;
  I: Integer;
begin
  SetLength(Result, Length(AVotes));
  I := 0;
  for vVote in AVotes do
  begin
    Result[I] := vVote.Addr;
    Inc(I);
  end;
end;

end.
