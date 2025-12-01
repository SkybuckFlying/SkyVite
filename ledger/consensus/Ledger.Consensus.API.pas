unit Ledger.Consensus.Api;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Interfaces.Core,
  Common.Types,
  Ledger.Consensus.CDB,
  Ledger.Consensus.Snapshot,
  GoToDelphi.Helpers.TChannel;

type
  // APISnapshot is the interface that can query snapshot consensus info.
  TAPISnapshot = class
  private
    mSnapshot: TSnapshotCs;
  public
    constructor Create(ParaSnapshot: TSnapshotCs);
    class function NewAPISnapshot(ParaSnapshot: TSnapshotCs): TAPISnapshot;
    function ReadVoteMap(const ParaTI: TDateTime): TTuple<TArray<IVoteDetails>, IHashHeight, Exception>;
    function ReadSuccessRate(ParaStart, ParaEnd: TUInt64): TTuple<TArray<TDictionary<TAddress, IContent>>, Exception>;
    function ReadByIndex(const ParaGid: TGid; ParaIndex: TUInt64): TTuple<TArray<IEvent>, TUInt64, Exception>;
  end;

implementation

uses
  Ledger.Consensus.Event;

{ TAPISnapshot }

constructor TAPISnapshot.Create(ParaSnapshot: TSnapshotCs);
begin
  mSnapshot := ParaSnapshot;
end;

class function TAPISnapshot.NewAPISnapshot(ParaSnapshot: TSnapshotCs): TAPISnapshot;
begin
  Result := TAPISnapshot.Create(ParaSnapshot);
end;

function TAPISnapshot.ReadVoteMap(const ParaTI: TDateTime): TTuple<TArray<IVoteDetails>, IHashHeight, Exception>;
begin
  try
    Result := mSnapshot.VoteDetailsBeforeTime(ParaTI);
  except
    on E: Exception do
    begin
      Result := TTuple<TArray<IVoteDetails>, IHashHeight, Exception>.Create(nil, nil, E);
    end;
  end;
end;

function TAPISnapshot.ReadSuccessRate(ParaStart, ParaEnd: TUInt64): TTuple<TArray<TDictionary<TAddress, IContent>>, Exception>;
var
  vResultList: TArray<TDictionary<TAddress, IContent>>;
  vIndex: TUInt64;
  vRateByHour: TDictionary<TAddress, IContent>;
  vError: Exception;
begin
  vError := nil;
  try
    SetLength(vResultList, 0);
    for vIndex := ParaStart to ParaEnd - 1 do
    begin
      try
        vRateByHour := mSnapshot.RW.GetSuccessRateByHour2(vIndex, vError);
        if vError <> nil then
        begin
          raise vError;
        end;
        vResultList := Concat(vResultList, [vRateByHour]);
      except
        on E: Exception do
        begin
          vError := E;
          break;
        end;
      end;
    end;
  except
    on E: EOutOfMemory do
    begin
      vError := E;
    end;
  end;
  Result := TTuple<TArray<TDictionary<TAddress, IContent>>, Exception>.Create(vResultList, vError);
end;

function TAPISnapshot.ReadByIndex(const ParaGid: TGid; ParaIndex: TUInt64): TTuple<TArray<IEvent>, TUInt64, Exception>;
var
  vLEResult: IElectionResult;
  vVoteTime: TDateTime;
  vResultList: TArray<IEvent>;
  vP: IPlan;
  vLE: IEvent;
  vError: Exception;
begin
  vError := nil;
  try
    vLEResult := mSnapshot.ElectionIndex(ParaIndex, vError);
    if vError <> nil then
    begin
      raise vError;
    end;

    vVoteTime := mSnapshot.GenProofTime(ParaIndex);
    try
      SetLength(vResultList, 0);
      for vP in vLEResult.Plans do
      begin
        vLE := TEvent.NewConsensusEvent(vLEResult, vP, ParaGid, vVoteTime);
        vResultList := Concat(vResultList, [vLE]);
      end;
    except
      on E: EOutOfMemory do
      begin
        vError := E;
      end;
    end;
  except
    on E: Exception do
    begin
      vError := E;
    end;
  end;
  if vError <> nil then
  begin
    Result := TTuple<TArray<IEvent>, TUInt64, Exception>.Create(nil, 0, vError);
  end
  else
  begin
    Result := TTuple<TArray<IEvent>, TUInt64, Exception>.Create(vResultList, vLEResult.Index, nil);
  end;
end;

end.