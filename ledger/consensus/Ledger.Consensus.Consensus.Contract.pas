unit Ledger.Consensus.ConsensusContract;

interface

uses
  Common.Types,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
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
  Ledger.Consensus.ContractDPoS,
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
  Ledger.Consensus.Unittest.Util.Test,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  V2.Interfaces.Core;

type
  TContractsCs = class
  private
    mRw: TChainRw;
    mContracts: TDictionary<TGid, TContractDposCs>;
    mContractsMu: TCriticalSection;
    mLog: ILogger;
    function GetOrLoadGid(const ParaGid: TGid; out ParaErr: Exception): TContractDposCs;
    function ReloadGid(const ParaGid: TGid; out ParaErr: Exception): TContractDposCs;
    function GetForGid(const ParaGid: TGid): TContractDposCs;
  public
    constructor Create(ParaRw: TChainRw; ParaLog: ILogger);
    destructor Destroy; override;
    function LoadGid(const ParaGid: TGid): Exception;
    function ElectionTime(const ParaGid: TGid; ParaT: TDateTime): TTuple<IElectionResult, Exception>;
    function ElectionIndex(const ParaGid: TGid; ParaIndex: TUInt64): TTuple<IElectionResult, Exception>;
  end;

implementation

{ TContractsCs }

constructor TContractsCs.Create(ParaRw: TChainRw; ParaLog: ILogger);
begin
  mRw := ParaRw;
  mLog := ParaLog.New('gid', 'contracts');
  mContracts := TDictionary<TGid, TContractDposCs>.Create;
  mContractsMu := TCriticalSection.Create;
end;

destructor TContractsCs.Destroy;
begin
  mContracts.Free;
  mContractsMu.Free;
  inherited;
end;

function TContractsCs.LoadGid(const ParaGid: TGid): Exception;
var
  vResultCs: TContractDposCs;
  vErr: Exception;
begin
  vResultCs := ReloadGid(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(vErr);
  end;
  if vResultCs = nil then
  begin
    Exit(Exception.CreateFmt('load contract consensus group[%s] fail.', [ParaGid.ToString]));
  end;
  Result := nil;
end;

function TContractsCs.ElectionTime(const ParaGid: TGid; ParaT: TDateTime): TTuple<IElectionResult, Exception>;
var
  vResultCs: TContractDposCs;
  vErr: Exception;
begin
  vResultCs := GetOrLoadGid(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<IElectionResult, Exception>.Create(nil, vErr));
  end;
  if vResultCs = nil then
  begin
    Exit(TTuple<IElectionResult, Exception>.Create(nil, Exception.CreateFmt('can''t load contract group for gid:%s, t:%s', [ParaGid.ToString, DateTimeToStr(ParaT)])));
  end;
  Result := vResultCs.ElectionTime(ParaT);
end;

function TContractsCs.ElectionIndex(const ParaGid: TGid; ParaIndex: TUInt64): TTuple<IElectionResult, Exception>;
var
  vResultCs: TContractDposCs;
  vErr: Exception;
begin
  vResultCs := GetOrLoadGid(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<IElectionResult, Exception>.Create(nil, vErr));
  end;
  if vResultCs = nil then
  begin
    Exit(TTuple<IElectionResult, Exception>.Create(nil, Exception.CreateFmt('can''t load contract group for gid:%s, index:%d', [ParaGid.ToString, ParaIndex])));
  end;
  Result := vResultCs.ElectionIndex(ParaIndex);
end;

function TContractsCs.GetOrLoadGid(const ParaGid: TGid; out ParaErr: Exception): TContractDposCs;
var
  vCs: TContractDposCs;
begin
  ParaErr := nil;
  vCs := GetForGid(ParaGid);
  if vCs = nil then
  begin
    Result := ReloadGid(ParaGid, ParaErr);
  end
  else
  begin
    Result := vCs;
  end;
end;

function TContractsCs.ReloadGid(const ParaGid: TGid; out ParaErr: Exception): TContractDposCs;
var
  vInfo: IGroupInfo;
  vCs: TContractDposCs;
begin
  ParaErr := nil;
  mContractsMu.Enter;
  try
    try
      vInfo := mRw.GetMemberInfo(ParaGid, ParaErr);
      if ParaErr <> nil then
      begin
        Exit(nil);
      end;
      if vInfo = nil then
      begin
        ParaErr := Exception.CreateFmt('can''t load consensus gid:%s', [ParaGid.ToString]);
        Exit(nil);
      end;
      vCs := TContractDposCs.Create(vInfo, mRw, mLog);
      mContracts.AddOrSetValue(ParaGid, vCs);
      Result := vCs;
    except
      on E: Exception do
      begin
        ParaErr := E;
        Result := nil;
      end;
    end;
  finally
    mContractsMu.Leave;
  end;
end;

function TContractsCs.GetForGid(const ParaGid: TGid): TContractDposCs;
begin
  mContractsMu.Enter;
  try
    if mContracts.TryGetValue(ParaGid, Result) then
    begin
      Exit(Result);
    end;
    Result := nil;
  finally
    mContractsMu.Leave;
  end;
end;

end.
