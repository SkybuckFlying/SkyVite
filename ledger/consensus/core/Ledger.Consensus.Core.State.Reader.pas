unit Ledger.Consensus.Core.State.Reader;

interface

uses
  BigNumbers,
  Common.Types,
  Interfaces.Core,
  Ledger.Consensus.Core.Consensus,
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader.Test,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.Time.Index.Test,
  Ledger.Consensus.Core.Utils,
  Ledger.Consensus.Core.Vote.Algo,
  Ledger.Consensus.Core.Vote.Algo.Test,
  System.Generics.Collections,
  System.SysUtils;

type
  IStateCh = interface
    ['{E3A2E8B9-A2C3-4B8D-9B1A-2A8E5C1B4A5C}']
    function GetRegisterList(const ASnapshotHash: THash; const AGid: TGid): TArray<TRegistration>;
    function GetVoteList(const ASnapshotHash: THash; const AGid: TGid): TArray<TVoteInfo>;
    function GetConfirmedBalanceList(const AAddrList: TArray<TAddress>; const ATokenId: TTokenTypeId; const ASbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetSnapshotHeaderBeforeTime(const ATimestamp: TDateTime): ISnapshotBlock;
    function GetSnapshotBlockByHeight(AHeight: UInt64): ISnapshotBlock;
  end;

  TVote = class
  public
    Balance: TBigInteger;
    Name: string;
    Addr: TAddress;
  end;

function CalVotes(const AInfo: TConsensusGroupInfo; const AHash: THash; const ARw: IStateCh): TArray<TVote>;
function VoteCompleting(const ASnapshotHash: THash; const AVote: TVote; const AInfos: TArray<TVoteInfo>; const AId: TTokenTypeId; const ARw: IStateCh): Boolean;

implementation

function CalVotes(const AInfo: TConsensusGroupInfo; const AHash: THash; const ARw: IStateCh): TArray<TVote>;
var
  vRegisterList: TArray<TRegistration>;
  vVotes: TArray<TVoteInfo>;
  vRegistration: TRegistration;
  vVote: TVote;
begin
  vRegisterList := ARw.GetRegisterList(AHash, AInfo.Gid);
  vVotes := ARw.GetVoteList(AHash, AInfo.Gid);

  SetLength(Result, 0);
  for vRegistration in vRegisterList do
  begin
    vVote := TVote.Create;
    vVote.Balance := TBigInteger.Zero;
    vVote.Name := vRegistration.Name;
    vVote.Addr := vRegistration.BlockProducingAddress;

    if not VoteCompleting(AHash, vVote, vVotes, AInfo.CountingTokenId, ARw) then
    begin
      // Handle error
      Result := nil;
      Exit;
    end;

    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := vVote;
  end;
end;

function VoteCompleting(const ASnapshotHash: THash; const AVote: TVote; const AInfos: TArray<TVoteInfo>; const AId: TTokenTypeId; const ARw: IStateCh): Boolean;
var
  vAddrs: TArray<TAddress>;
  vInfo: TVoteInfo;
  vBalanceMap: TDictionary<TAddress, TBigInteger>;
  vBalance: TBigInteger;
begin
  SetLength(vAddrs, 0);
  for vInfo in AInfos do
  begin
    if vInfo.SbpName = AVote.Name then
    begin
      SetLength(vAddrs, Length(vAddrs) + 1);
      vAddrs[High(vAddrs)] := vInfo.VoteAddr;
    end;
  end;

  if Length(vAddrs) > 0 then
  begin
    try
      vBalanceMap := ARw.GetConfirmedBalanceList(vAddrs, AId, ASnapshotHash);
      for vBalance in vBalanceMap.Values do
      begin
        AVote.Balance := AVote.Balance + vBalance;
      end;
    except
      on E: Exception do
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
  Result := True;
end;

end.
