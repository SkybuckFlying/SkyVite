unit Ledger.Chain.Index.OnRoad;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Index;

type
  TIndexDBHelper = class helper for TIndexDB
  private
    procedure InsertOnRoad(const ParaBatch: IBatch; const ParaToAddr: TAddress; const ParaBlockHash: THash);
    procedure DeleteOnRoad(const ParaBatch: IBatch; const ParaToAddr: TAddress; const ParaBlockHash: THash);
  public
    function LoadRange(const ParaAddrList: TArray<TAddress>; const ParaLoadFn: TLoadOnroadFn): Exception;
    function LoadAllHash(out ParaOnRoadListMap: TDictionary<TAddress, TArray<THash>>): Exception;
    function GetOnRoadHashList(const ParaAddr: TAddress; const ParaPageNum, ParaPageSize: Integer): TArray<THash>;
  end;

implementation

uses
  Common.DB.XLevelDB.Util,
  Ledger.Chain.Utils;

{ TIndexDBHelper }

procedure TIndexDBHelper.InsertOnRoad(const ParaBatch: IBatch; const ParaToAddr: TAddress; const ParaBlockHash: THash);
begin
  ParaBatch.Put(TChainUtils.CreateOnRoadKey(ParaToAddr, ParaBlockHash).Bytes, []);
end;

procedure TIndexDBHelper.DeleteOnRoad(const ParaBatch: IBatch; const ParaToAddr: TAddress; const ParaBlockHash: THash);
begin
  ParaBatch.Delete(TChainUtils.CreateOnRoadKey(ParaToAddr, ParaBlockHash).Bytes);
end;

function TIndexDBHelper.LoadRange(const ParaAddrList: TArray<TAddress>; const ParaLoadFn: TLoadOnroadFn): Exception;
var
  vAddr: TAddress;
  vIter: IIterator;
  vKey: TBytes;
  vBlockHashBytes: TBytes;
  vBlockHash: THash;
  vErr: Exception;
  vFromAddr: TAddress;
  vHeight: UInt64;
  vHashHeight: IHashHeight;
begin
  Result := nil;
  for vAddr in ParaAddrList do
  begin
    vIter := mStore.NewIterator(TBytesPrefix.Create(TBytes.Concat(TBytes.Create(TChainUtils.OnRoadKeyPrefix), vAddr.Bytes)));
    try
      while vIter.Next do
      begin
        vKey := vIter.Key;
        vBlockHashBytes := TBytes.Copy(vKey, Length(vKey) - THash.HashSize, THash.HashSize);
        vBlockHash := THash.BytesToHash(vBlockHashBytes, 0, vErr);
        if vErr <> nil then
        begin
          Result := vErr;
          Exit;
        end;

        vErr := GetAddrHeightByHash(vBlockHash, vFromAddr, vHeight);
        if vErr <> nil then
        begin
          Result := vErr;
          Exit;
        end;

        if vFromAddr = Default(TAddress) then
        begin
          mLog.Error(Format('block hash is %s, fromAddr is %s, height is %d', [vBlockHash.ToString, vFromAddr.ToString, vHeight]), 'method', 'Load');
          Continue;
        end;
        vHashHeight := THashHeight.Create;
        vHashHeight.Height := vHeight;
        vHashHeight.Hash := vBlockHash;
        vErr := ParaLoadFn(vFromAddr, vAddr, vHashHeight);
        if vErr <> nil then
        begin
          Result := vErr;
          Exit;
        end;
      end;

      vErr := vIter.Error;
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;
    finally
      vIter.Release;
    end;
  end;
end;

function TIndexDBHelper.LoadAllHash(out ParaOnRoadListMap: TDictionary<TAddress, TArray<THash>>): Exception;
var
  vIter: IIterator;
  vKey: TBytes;
  vAddrBytes: TBytes;
  vAddr: TAddress;
  vErr: Exception;
  vBlockHashBytes: TBytes;
  vBlockHash: THash;
  vOk: Boolean;
  vList: TArray<THash>;
begin
  Result := nil;
  ParaOnRoadListMap := TDictionary<TAddress, TArray<THash>>.Create;
  vIter := mStore.NewIterator(TBytesPrefix.Create(TBytes.Create(TChainUtils.OnRoadKeyPrefix)));
  try
    while vIter.Next do
    begin
      vKey := vIter.Key;
      vAddrBytes := TBytes.Copy(vKey, 1, Length(vKey) - THash.HashSize - 1);
      vAddr := TAddress.BytesToAddress(vAddrBytes, vErr);
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;
      vBlockHashBytes := TBytes.Copy(vKey, Length(vKey) - THash.HashSize, THash.HashSize);
      vBlockHash := THash.BytesToHash(vBlockHashBytes, 0, vErr);
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;
      vOk := ParaOnRoadListMap.TryGetValue(vAddr, vList);
      if not vOk then
      begin
        vList := [];
      end;
      vList := vList + [vBlockHash];
      ParaOnRoadListMap.AddOrSetValue(vAddr, vList);
    end;

    vErr := vIter.Error;
    if vErr <> nil then
    begin
      Result := vErr;
      Exit;
    end;
  finally
    vIter.Release;
  end;
end;

function TIndexDBHelper.GetOnRoadHashList(const ParaAddr: TAddress; const ParaPageNum, ParaPageSize: Integer): TArray<THash>;
var
  vIndex: Integer;
  vHashList: TList<THash>;
  vIter: IIterator;
  vKey: TBytes;
  vBlockHashBytes: TBytes;
  vBlockHash: THash;
  vErr: Exception;
begin
  vIndex := 0;
  vHashList := TList<THash>.Create;
  try
    vIter := mStore.NewIterator(TBytesPrefix.Create(TBytes.Concat(TBytes.Create(TChainUtils.OnRoadKeyPrefix), ParaAddr.Bytes)));
    try
      while vIter.Next do
      begin
        if vIndex >= ParaPageSize * ParaPageNum then
        begin
          if vIndex >= ParaPageSize * (ParaPageNum + 1) then
          begin
            Break;
          end;

          vKey := vIter.Key;
          vBlockHashBytes := TBytes.Copy(vKey, Length(vKey) - THash.HashSize, THash.HashSize);
          vBlockHash := THash.BytesToHash(vBlockHashBytes, 0, vErr);
          if vErr <> nil then
          begin
            raise vErr;
          end;
          vHashList.Add(vBlockHash);
        end;
        Inc(vIndex);
      end;

      vErr := vIter.Error;
      if vErr <> nil then
      begin
        raise vErr;
      end;
      Result := vHashList.ToArray;
    finally
      vIter.Release;
    end;
  finally
    vHashList.Free;
  end;
end;

end.