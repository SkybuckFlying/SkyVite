unit Ledger.Chain.Index.SnapshotBlock;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces,
  Ledger.Chain.Index,
  Ledger.Chain.FileManager;

type
  TIndexDBHelper = class helper for TIndexDB
  public
    function IsSnapshotBlockExisted(const ParaHash: THash): Boolean;
    function GetSnapshotBlockHeight(const ParaHash: THash): UInt64;
    function GetSnapshotBlockLocationByHash(const ParaHash: THash): ILocation;
    function GetSnapshotBlockLocation(ParaHeight: UInt64): ILocation;
    function GetSnapshotBlockByHeight(ParaHeight: UInt64; out ParaHash: THash; out ParaLocation: ILocation): Exception;
    function GetLatestSnapshotBlockLocation: ILocation;
    function GetSnapshotBlockLocationList(const ParaBlockHash: THash; ParaHigher: Boolean; ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetSnapshotBlockLocationListByHeight(ParaHeight: UInt64; ParaHigher: Boolean; ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetRangeSnapshotBlockLocations(const ParaStartHash, ParaEndHash: THash; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
  private
    function GetSnapshotBlockLocations(ParaStartHeight, ParaEndHeight: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetSnapshotBlockLocationsByCache(ParaEndHeight, ParaStartHeight: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
  end;

implementation

uses
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.Util,
  Common.Helper,
  Ledger.Chain.Utils,
  GoToDelphi.Helpers.GoCache;

{ TIndexDBHelper }

function TIndexDBHelper.IsSnapshotBlockExisted(const ParaHash: THash): Boolean;
var
  vErr: Exception;
begin
  Result := mStore.Has(TChainUtils.CreateSnapshotBlockHashKey(ParaHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
end;

function TIndexDBHelper.GetSnapshotBlockHeight(const ParaHash: THash): UInt64;
var
  vValue: TBytes;
  vErr: Exception;
begin
  vValue := GetValue(TChainUtils.CreateSnapshotBlockHashKey(ParaHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vValue) <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := TChainUtils.BytesToUint64(vValue);
end;

function TIndexDBHelper.GetSnapshotBlockLocationByHash(const ParaHash: THash): ILocation;
var
  vValue: TBytes;
  vErr: Exception;
begin
  vValue := GetValue(TChainUtils.CreateSnapshotBlockHashKey(ParaHash).Bytes, vErr);
  if vErr <> nil then
  begin
    if vErr is ELevelDBNotFound then
    begin
      Result := nil;
      Exit;
    end;
    raise vErr;
  end;
  if Length(vValue) <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  Result := GetSnapshotBlockLocation(TChainUtils.BytesToUint64(vValue));
end;

function TIndexDBHelper.GetSnapshotBlockLocation(ParaHeight: UInt64): ILocation;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  vKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaHeight).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vValue) <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  Result := TChainUtils.DeserializeLocation(vValue, THash.HashSize);
end;

function TIndexDBHelper.GetSnapshotBlockByHeight(ParaHeight: UInt64; out ParaHash: THash; out ParaLocation: ILocation): Exception;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  Result := nil;
  ParaHash := Default(THash);
  ParaLocation := nil;
  vKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaHeight).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;
  if Length(vValue) <= 0 then
  begin
    Exit;
  end;
  ParaHash := THash.BytesToHash(vValue, 0, vErr);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;
  ParaLocation := TChainUtils.DeserializeLocation(vValue, THash.HashSize);
end;

function TIndexDBHelper.GetLatestSnapshotBlockLocation: ILocation;
var
  vStartKey, vEndKey: TBytes;
  vIter: IIterator;
  vLocation: ILocation;
  vErr: Exception;
begin
  vStartKey := TChainUtils.CreateSnapshotBlockHeightKey(1).Bytes;
  vEndKey := TChainUtils.CreateSnapshotBlockHeightKey(THelper.MaxUint64).Bytes;
  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    vLocation := nil;
    if vIter.Last then
    begin
      vLocation := TChainUtils.DeserializeLocation(vIter.Value, THash.HashSize);
    end;
    vErr := vIter.Error;
    if (vErr <> nil) and (not(vErr is ELevelDBNotFound)) then
    begin
      raise vErr;
    end;
    Result := vLocation;
  finally
    vIter.Release;
  end;
end;

function TIndexDBHelper.GetSnapshotBlockLocationList(const ParaBlockHash: THash; ParaHigher: Boolean; ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vValue: TBytes;
  vErr: Exception;
  vHeight: UInt64;
begin
  SetLength(ParaHeightRange, 2);
  if ParaCount <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  vValue := GetValue(TChainUtils.CreateSnapshotBlockHashKey(ParaBlockHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vValue) <= 0 then
  begin
    raise Exception.Create('Block not found');
  end;
  vHeight := TChainUtils.BytesToUint64(vValue);
  Result := GetSnapshotBlockLocationListByHeight(vHeight, ParaHigher, ParaCount, ParaHeightRange);
end;

function TIndexDBHelper.GetSnapshotBlockLocationListByHeight(ParaHeight: UInt64; ParaHigher: Boolean; ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vStartHeight, vEndHeight: UInt64;
begin
  SetLength(ParaHeightRange, 2);
  if ParaCount <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  if ParaHigher then
  begin
    vStartHeight := ParaHeight;
    vEndHeight := vStartHeight + ParaCount - 1;
  end
  else
  begin
    vEndHeight := ParaHeight;
    if vEndHeight <= ParaCount then
    begin
      vStartHeight := 1;
    end
    else
    begin
      vStartHeight := vEndHeight - ParaCount + 1;
    end;
  end;
  Result := GetSnapshotBlockLocations(vStartHeight, vEndHeight, ParaHeightRange);
end;

function TIndexDBHelper.GetRangeSnapshotBlockLocations(const ParaStartHash, ParaEndHash: THash; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vStartValue, vEndValue: TBytes;
  vErr: Exception;
  vStartHeight, vEndHeight: UInt64;
begin
  SetLength(ParaHeightRange, 2);
  vStartValue := GetValue(TChainUtils.CreateSnapshotBlockHashKey(ParaStartHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vStartValue) <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  vStartHeight := TChainUtils.BytesToUint64(vStartValue);

  vEndValue := GetValue(TChainUtils.CreateSnapshotBlockHashKey(ParaEndHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vEndValue) <= 0 then
  begin
    Result := nil;
    Exit;
  end;
  vEndHeight := TChainUtils.BytesToUint64(vEndValue);

  Result := GetSnapshotBlockLocations(vStartHeight, vEndHeight, ParaHeightRange);
end;

function TIndexDBHelper.GetSnapshotBlockLocations(ParaStartHeight, ParaEndHeight: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vLocationList: TArray<ILocation>;
  vCacheHeightRange: TArray<UInt64>;
  vErr: Exception;
  vMaxHeight, vMinHeight: UInt64;
  vStartKey, vEndKey: TBytes;
  vIter: IIterator;
  vIterOk: Boolean;
  vHeight: UInt64;
begin
  SetLength(ParaHeightRange, 2);
  vLocationList := GetSnapshotBlockLocationsByCache(ParaEndHeight, ParaStartHeight, vCacheHeightRange);
  vMaxHeight := vCacheHeightRange[0];
  vMinHeight := vCacheHeightRange[1];

  if vMinHeight <= ParaEndHeight then
  begin
    ParaEndHeight := vMinHeight - 1;
  end;

  if ParaEndHeight >= ParaStartHeight then
  begin
    vStartKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaStartHeight).Bytes;
    vEndKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaEndHeight + 1).Bytes;
    vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
    try
      vIterOk := vIter.Last;
      while vIterOk do
      begin
        vHeight := TChainUtils.BytesToUint64(vIter.Key, 1);
        if vHeight < vMinHeight then
        begin
          vMinHeight := vHeight;
        end;
        if vHeight > vMaxHeight then
        begin
          vMaxHeight := vHeight;
        end;
        vLocationList := vLocationList + [TChainUtils.DeserializeLocation(vIter.Value, THash.HashSize)];
        vIterOk := vIter.Prev;
      end;
      vErr := vIter.Error;
      if (vErr <> nil) and (not(vErr is ELevelDBNotFound)) then
      begin
        raise vErr;
      end;
    finally
      vIter.Release;
    end;
  end;

  Result := vLocationList;
  ParaHeightRange[0] := vMaxHeight;
  ParaHeightRange[1] := vMinHeight;
end;

function TIndexDBHelper.GetSnapshotBlockLocationsByCache(ParaEndHeight, ParaStartHeight: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vH: UInt64;
  vLocationList: TList<ILocation>;
  vMinHeight, vMaxHeight: UInt64;
  vValue: TBytes;
  vErr: Exception;
begin
  SetLength(ParaHeightRange, 2);
  vLocationList := TList<ILocation>.Create;
  try
    vMinHeight := ParaEndHeight + 1;
    vMaxHeight := ParaStartHeight - 1;
    vH := ParaEndHeight;
    while vH >= ParaStartHeight do
    begin
      vValue := mCache.Get(TChainUtils.CreateSnapshotBlockHeightKey(vH).ToString, vErr);
      if vErr <> nil then
      begin
        if vErr is EGoCacheEntryNotFound then
        begin
          Break;
        end;
        raise vErr;
      end;
      vLocationList.Add(TChainUtils.DeserializeLocation(vValue, THash.HashSize));
      if vH < vMinHeight then
      begin
        vMinHeight := vH;
      end;
      if vH > vMaxHeight then
      begin
        vMaxHeight := vH;
      end;
      Dec(vH);
    end;
    Result := vLocationList.ToArray;
    ParaHeightRange[0] := vMaxHeight;
    ParaHeightRange[1] := vMinHeight;
  finally
    vLocationList.Free;
  end;
end;

end.
