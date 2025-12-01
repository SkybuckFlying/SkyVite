unit Ledger.Chain.Fork;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.Consensus.Core,
  V2.Ledger.Chain.Chain;

type
  TEmptyStruct = record
  end;

  TChainHelper = class helper for TChain
  public
    function getTopProducersMap(ParaSnapshotHeight: TUInt64): TDictionary<TAddress, TEmptyStruct>;
  end;

implementation

{ TChainHelper }

function TChainHelper.getTopProducersMap(ParaSnapshotHeight: TUInt64): TDictionary<TAddress, TEmptyStruct>;
var
  vSnapshotHash: THash;
  vSnapshotConsensusGroupInfo: IConsensusGroupInfo;
  vCount: Integer;
  vVoteDetails: TArray<IVoteDetails>;
  vTopProducers: TDictionary<TAddress, TEmptyStruct>;
  vIndex: Integer;
  vEndIndex: Integer;
  vEmptyStruct: TEmptyStruct;
begin
  try
    vSnapshotHash := Self.GetSnapshotHashByHeight(ParaSnapshotHeight);
  except
    on E: Exception do
    begin
      raise Exception.Create(Format('GetSnapshotHashByHeight failed. snapshotHeight is %d. Error: %s', [ParaSnapshotHeight, E.Message]));
    end;
  end;

  if vSnapshotHash = nil then
  begin
    Exit(nil);
  end;

  try
    vSnapshotConsensusGroupInfo := Self.GetConsensusGroup(vSnapshotHash, SNAPSHOT_GID);
  except
    on E: Exception do
    begin
      raise Exception.Create(Format('GetConsensusGroup failed. Error: %s', [E.Message]));
    end;
  end;

  if vSnapshotConsensusGroupInfo = nil then
  begin
    raise Exception.Create('snapshotConsensusGroupInfo can''t be nil');
  end;

  vCount := vSnapshotConsensusGroupInfo.NodeCount;

  try
    vVoteDetails := Self.CalVoteDetails(SNAPSHOT_GID, TGroupInfo.Create(Self.FGenesisSnapshotBlock.Timestamp, vSnapshotConsensusGroupInfo), THashHeight.Create(vSnapshotHash, ParaSnapshotHeight));
  except
    on E: Exception do
    begin
      raise Exception.Create(Format('CalVoteDetails failed. snapshotHeight is %d. Error: %s', [ParaSnapshotHeight, E.Message]));
    end;
  end;

  vTopProducers := TDictionary<TAddress, TEmptyStruct>.Create;
  vEndIndex := Length(vVoteDetails);
  if vEndIndex > vCount then
  begin
    vEndIndex := vCount;
  end;

  for vIndex := 0 to vEndIndex - 1 do
  begin
    vTopProducers.Add(vVoteDetails[vIndex].CurrentAddr, vEmptyStruct);
  end;

  Result := vTopProducers;
end;

end.