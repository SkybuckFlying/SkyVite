unit Interfaces.Core.VmLogList;

interface

uses
  Common.Types,
  Common.Upgrade,
  Common.VitePb,
  Crypto,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Account.Block.Test,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List.Test,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TVmLog = record
    Topics: TArray<THash>;
    Data: TBytes;
  end;

  TVmLogList = class(TList<TVmLog>)
  public
    function Hash(ParaSnapshotHeight: UInt64; ParaAddress: TAddress; ParaPrevHash: THash): ^THash;
    function ToProto: TVmLogListPb;
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
    function DeProto(const ParaPb: TVmLogListPb): Exception;
    procedure Sort;
  end;

implementation

{ TVmLogList }

function TVmLogList.Hash(ParaSnapshotHeight: UInt64; ParaAddress: TAddress; ParaPrevHash: THash): ^THash;
var
  vSource: TBytes;
  vVmLog: TVmLog;
  vTopic: THash;
  vHash: THash;
  vError: Exception;
begin
  if Self.Count = 0 then
  begin
    Result := nil;
    Exit;
  end;

  SetLength(vSource, 0);
  for vVmLog in Self do
  begin
    for vTopic in vVmLog.Topics do
      vSource := vSource + vTopic.Bytes;
    vSource := vSource + vVmLog.Data;
  end;

  if IsSeedUpgrade(ParaSnapshotHeight) then
  begin
    vSource := vSource + ParaAddress.Bytes;
    vSource := vSource + ParaPrevHash.Bytes;
  end;

  vHash := THash.Hash256(vSource, vError);
  if vError = nil then
  begin
    New(Result);
    Result^ := vHash;
  end
  else
    Result := nil;
end;

function TVmLogList.ToProto: TVmLogListPb;
var
  vVmLog: TVmLog;
  vTopic: THash;
  vTopicsPb: TArray<TBytes>;
  vVmLogPb: TVmLogPb;
  i, j: Integer;
begin
  Result := TVmLogListPb.Create;
  SetLength(Result.List, Self.Count);
  i := 0;
  for vVmLog in Self do
  begin
    SetLength(vTopicsPb, Length(vVmLog.Topics));
    j := 0;
    for vTopic in vVmLog.Topics do
    begin
      vTopicsPb[j] := vTopic.Bytes;
      Inc(j);
    end;

    vVmLogPb := TVmLogPb.Create;
    vVmLogPb.Topics := vTopicsPb;
    vVmLogPb.Data := vVmLog.Data;
    Result.List[i] := vVmLogPb;
    Inc(i);
  end;
end;

function TVmLogList.Serialize(out ParaError: Exception): TBytes;
var
  vPb: TVmLogListPb;
begin
  vPb := Self.ToProto;
  Result := vPb.ToBytes(ParaError);
end;

function TVmLogList.Deserialize(const ParaBuf: TBytes): Exception;
var
  vPb: TVmLogListPb;
begin
  Result := nil;
  vPb := TVmLogListPb.Create;
  Result := vPb.FromBytes(ParaBuf);
  if Result = nil then
    Result := Self.DeProto(vPb);
end;

function TVmLogList.DeProto(const ParaPb: TVmLogListPb): Exception;
var
  vVmLogPb: TVmLogPb;
  vTopics: TArray<THash>;
  vTopicPb: TBytes;
  vVmLog: TVmLog;
  vError: Exception;
  i: Integer;
begin
  Result := nil;
  Self.Clear;
  for vVmLogPb in ParaPb.List do
  begin
    SetLength(vTopics, Length(vVmLogPb.Topics));
    i := 0;
    for vTopicPb in vVmLogPb.Topics do
    begin
      vTopics[i] := THash.FromBytes(vTopicPb, vError);
      if vError <> nil then
        Exit(vError);
      Inc(i);
    end;

    vVmLog.Topics := vTopics;
    vVmLog.Data := vVmLogPb.Data;
    Self.Add(vVmLog);
  end;
end;

procedure TVmLogList.Sort;
begin
  inherited Sort(TComparer<TVmLog>.Construct(
    function(const L, R: TVmLog): Integer
    var
      i, r: Integer;
    begin
      if Length(L.Topics) <> Length(R.Topics) then
      begin
        Result := Length(L.Topics) - Length(R.Topics);
        Exit;
      end;
      for i := 0 to Length(L.Topics) - 1 do
      begin
        r := L.Topics[i].Compare(R.Topics[i]);
        if r <> 0 then
        begin
          Result := r;
          Exit;
        end;
      end;
      Result := TBytes.Compare(L.Data, R.Data);
    end));
end;

end.
