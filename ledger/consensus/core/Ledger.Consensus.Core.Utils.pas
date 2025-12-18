unit Ledger.Consensus.Core.Utils;

interface

uses
  System.SysUtils,
  Common.Types,
  Ledger.Consensus.Core.State.Reader; // Assuming TVote is defined here

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
