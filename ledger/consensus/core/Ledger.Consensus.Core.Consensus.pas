unit ledger.consensus.core;

interface

uses
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader.Test,
  Ledger.Consensus.Core.State.Reader,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.Time.Index.Test,
  Ledger.Consensus.Core.Utils,
  Ledger.Consensus.Core.Vote.Algo,
  Ledger.Consensus.Core.Vote.Algo.Test,
  SysUtils Classes Math.BigInt common.types Generics.Defaults;

type
  TVoteType = (NORMAL, SUCCESS_RATE_PROMOTION, SUCCESS_RATE_DEMOTION, RANDOM_PROMOTION);

  IVote = interface
    ['{14E3E3E3-3E3E-4E3E-8E3E-3E3E3E3E3E3E}']
    function GetName: string;
    function GetAddr: TAddress;
    function GetBalance: TBigInteger;
    function GetVoteType: TArray<TVoteType>;
  end;

  TVote = class(TInterfacedObject, IVote)
  private
    FName: string;
    FAddr: TAddress;
    FBalance: TBigInteger;
    FType: TArray<TVoteType>;
  public
    constructor Create(name: string; addr: TAddress; balance: TBigInteger; voteType: TArray<TVoteType>);
    function GetName: string;
    function GetAddr: TAddress;
    function GetBalance: TBigInteger;
    function GetVoteType: TArray<TVoteType>;
  end;

  TByBalance = class(TComparer<IVote>)
  public
    function Compare(const Left, Right: IVote): Integer; override;
  end;

implementation

{ TVote }

constructor TVote.Create(name: string; addr: TAddress; balance: TBigInteger; voteType: TArray<TVoteType>);
begin
  FName := name;
  FAddr := addr;
  FBalance := balance;
  FType := voteType;
end;

function TVote.GetName: string;
begin
  Result := FName;
end;

function TVote.GetAddr: TAddress;
begin
  Result := FAddr;
end;

function TVote.GetBalance: TBigInteger;
begin
  Result := FBalance;
end;

function TVote.GetVoteType: TArray<TVoteType>;
begin
  Result := FType;
end;

{ TByBalance }

function TByBalance.Compare(const Left, Right: IVote): Integer;
var
  r: Integer;
begin
  r := Right.GetBalance.CompareTo(Left.GetBalance);
  if r = 0 then
    Result := CompareStr(Left.GetName, Right.GetName)
  else
    Result := r;
end;

end.
