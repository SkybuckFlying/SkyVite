unit Ledger.Consensus.ConsensusContract;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  V2.Interfaces.Core,
  Common.Types,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.ContractDPoS,
  Log15;

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