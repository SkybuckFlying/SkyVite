unit Ledger.Chain.Index.AccountBlock;

interface

uses
  Common.Types,
  Interfaces,
  Ledger.Chain.FileManager,
  Ledger.Chain.Index,
  Ledger.Chain.Index.Account,
  Ledger.Chain.Index.Cache,
  Ledger.Chain.Index.Delete,
  Ledger.Chain.Index.Index.DB,
  Ledger.Chain.Index.Index.DB.Test,
  Ledger.Chain.Index.Insert,
  Ledger.Chain.Index.Interface,
  Ledger.Chain.Index.Onroad,
  Ledger.Chain.Index.Snapshot.Block,
  Ledger.Chain.Utils,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TIndexDBHelper = class helper for TIndexDB
  public
    function IsAccountBlockExisted(const ParaHash: THash): Boolean;
    function GetLatestAccountBlock(const ParaAddr: TAddress; out ParaHeight: UInt64; out ParaLocation: ILocation): Exception;
    function GetAccountBlockLocationByHash(const ParaBlockHash: THash): ILocation;
    function GetAccountBlockLocation(const ParaAddr: TAddress; ParaHeight: UInt64): ILocation;
    function GetAccountBlockLocationByHeight(const ParaAddr: TAddress; ParaHeight: UInt64; out ParaHash: THash; out ParaLocation: ILocation): Exception;
    function GetAccountBlockLocationListByRange(const ParaAddr: TAddress; ParaStart, ParaEnd: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetAccountBlockLocationListByHeight(const ParaAddr: TAddress; ParaHeight, ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetAccountBlockLocationList(const ParaHash: THash; ParaCount: UInt64; out ParaAddr: TAddress; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
    function GetConfirmHeightByHash(const ParaBlockHash: THash): UInt64;
    function GetReceivedBySend(const ParaSendBlockHash: THash): PHash;
    function IsReceived(const ParaSendBlockHash: THash): Boolean;
    function GetAddrHeightByHash(const ParaBlockHash: THash; out ParaAddr: TAddress; out ParaHeight: UInt64): Exception;
  end;

implementation

uses
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.Util,
  Common.Helper;

{ TIndexDBHelper }

function TIndexDBHelper.IsAccountBlockExisted(const ParaHash: THash): Boolean;
var
  vErr: Exception;
begin
  Result := mStore.Has(TChainUtils.CreateAccountBlockHashKey(ParaHash).Bytes, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
end;

function TIndexDBHelper.GetLatestAccountBlock(const ParaAddr: TAddress; out ParaHeight: UInt64; out ParaLocation: ILocation): Exception;
var
  vStartKey, vEndKey: TBytes;
  vIter: IIterator;
  vValue: TBytes;
begin
  Result := nil;
  ParaHeight := 0;
  ParaLocation := nil;
  vStartKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, 1).Bytes;
  vEndKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, THelper.MaxUint64).Bytes;

  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    if not vIter.Last then
    begin
      Result := vIter.Error;
      if (Result <> nil) and (not(Result is ELevelDBNotFound)) then
      begin
        Exit;
      end;
      Result := nil;
      Exit;
    end;

    ParaHeight := TChainUtils.BytesToUint64(vIter.Key, 1 + TAddress.AddressSize);
    vValue := vIter.Value;

    if Length(vValue) > THash.HashSize then
    begin
      ParaLocation := TChainUtils.DeserializeLocation(vValue, THash.HashSize);
    end;
  finally
    vIter.Release;
  end;
end;

function TIndexDBHelper.GetAccountBlockLocationByHash(const ParaBlockHash: THash): ILocation;
var
  vAddr: TAddress;
  vHeight: UInt64;
  vErr: Exception;
begin
  vErr := GetAddrHeightByHash(ParaBlockHash, vAddr, vHeight);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if vAddr = Default(TAddress) then
  begin
    Result := nil;
    Exit;
  end;
  Result := GetAccountBlockLocation(vAddr, vHeight);
end;

function TIndexDBHelper.GetAccountBlockLocation(const ParaAddr: TAddress; ParaHeight: UInt64): ILocation;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  vKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, ParaHeight).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;

  if Length(vValue) <= THash.HashSize then
  begin
    Result := nil;
    Exit;
  end;
  Result := TChainUtils.DeserializeLocation(vValue, THash.HashSize);
end;

function TIndexDBHelper.GetAccountBlockLocationByHeight(const ParaAddr: TAddress; ParaHeight: UInt64; out ParaHash: THash; out ParaLocation: ILocation): Exception;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  Result := nil;
  ParaHash := Default(THash);
  ParaLocation := nil;
  vKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, ParaHeight).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  if Length(vValue) <= THash.HashSize then
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

function TIndexDBHelper.GetAccountBlockLocationListByRange(const ParaAddr: TAddress; ParaStart, ParaEnd: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vStartHeight, vEndHeight: UInt64;
  vStartKey, vEndKey: TBytes;
  vIter: IIterator;
  vLocationList: TList<ILocation>;
  vMinHeight, vMaxHeight: UInt64;
  vIterOk: Boolean;
  vHeight: UInt64;
  vValue: TBytes;
  vErr: Exception;
begin
  SetLength(ParaHeightRange, 2);
  if ParaEnd < ParaStart then
  begin
    Result := nil;
    Exit;
  end;

  vStartHeight := ParaStart;
  vEndHeight := ParaEnd;

  vStartKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, vStartHeight).Bytes;
  vEndKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, vEndHeight + 1).Bytes;

  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    vLocationList := TList<ILocation>.Create;
    vMinHeight := vEndHeight;
    vMaxHeight := vStartHeight;

    vIterOk := vIter.Last;
    while vIterOk do
    begin
      vHeight := TChainUtils.BytesToUint64(vIter.Key, 1 + TAddress.AddressSize);

      if vHeight < vMinHeight then
      begin
        vMinHeight := vHeight;
      end;

      if vHeight > vMaxHeight then
      begin
        vMaxHeight := vHeight;
      end;

      vValue := vIter.Value;

      if Length(vValue) > THash.HashSize then
      begin
        vLocationList.Add(TChainUtils.DeserializeLocation(vValue, THash.HashSize));
      end
      else
      begin
        vLocationList.Add(nil);
      end;

      vIterOk := vIter.Prev;
    end;

    vErr := vIter.Error;
    if (vErr <> nil) and (not(vErr is ELevelDBNotFound)) then
    begin
      raise vErr;
    end;

    Result := vLocationList.ToArray;
    ParaHeightRange[0] := vMinHeight;
    ParaHeightRange[1] := vMaxHeight;
  finally
    vLocationList.Free;
    vIter.Release;
  end;
end;

function TIndexDBHelper.GetAccountBlockLocationListByHeight(const ParaAddr: TAddress; ParaHeight, ParaCount: UInt64; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vStartHeight, vEndHeight: UInt64;
begin
  vStartHeight := 1;
  vEndHeight := ParaHeight;
  if vEndHeight > ParaCount then
  begin
    vStartHeight := vEndHeight - ParaCount + 1;
  end;
  Result := GetAccountBlockLocationListByRange(ParaAddr, vStartHeight, vEndHeight, ParaHeightRange);
end;

function TIndexDBHelper.GetAccountBlockLocationList(const ParaHash: THash; ParaCount: UInt64; out ParaAddr: TAddress; out ParaHeightRange: TArray<UInt64>): TArray<ILocation>;
var
  vHeight: UInt64;
  vErr: Exception;
begin
  SetLength(ParaHeightRange, 2);
  if ParaCount <= 0 then
  begin
    Result := nil;
    Exit;
  end;

  vErr := GetAddrHeightByHash(ParaHash, ParaAddr, vHeight);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if ParaAddr = Default(TAddress) then
  begin
    Result := nil;
    Exit;
  end;

  Result := GetAccountBlockLocationListByHeight(ParaAddr, vHeight, ParaCount, ParaHeightRange);
end;

function TIndexDBHelper.GetConfirmHeightByHash(const ParaBlockHash: THash): UInt64;
var
  vSnapshotHeight: TObject;
  vOk: Boolean;
  vAddr: TAddress;
  vHeight: UInt64;
  vErr: Exception;
  vStartKey, vEndKey: TBytes;
  vIter: IIterator;
  vValue: TBytes;
begin
  vOk := mSendCreateBlockHashCache.Get(ParaBlockHash, vSnapshotHeight);
  if vOk then
  begin
    Result := UInt64(vSnapshotHeight);
    Exit;
  end;

  vErr := GetAddrHeightByHash(ParaBlockHash, vAddr, vHeight);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if vAddr = Default(TAddress) then
  begin
    Result := 0;
    Exit;
  end;

  vStartKey := TChainUtils.CreateConfirmHeightKey(vAddr, vHeight).Bytes;
  vEndKey := TChainUtils.CreateConfirmHeightKey(vAddr, THelper.MaxUint64).Bytes;

  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    while vIter.Next do
    begin
      vValue := vIter.Value;
      Result := TChainUtils.BytesToUint64(vValue);
      Exit;
    end;

    vErr := vIter.Error;
    if (vErr <> nil) and (not(vErr is ELevelDBNotFound)) then
    begin
      raise vErr;
    end;

    Result := 0;
  finally
    vIter.Release;
  end;
end;

function TIndexDBHelper.GetReceivedBySend(const ParaSendBlockHash: THash): PHash;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
  vHash: THash;
begin
  vKey := TChainUtils.CreateReceiveKey(ParaSendBlockHash).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;

  if Length(vValue) <> THash.HashSize then
  begin
    Result := nil;
    Exit;
  end;

  vHash := THash.BytesToHash(vValue, 0, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Result := @vHash;
end;

function TIndexDBHelper.IsReceived(const ParaSendBlockHash: THash): Boolean;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  vKey := TChainUtils.CreateReceiveKey(ParaSendBlockHash).Bytes;
  vValue := GetValue(vKey, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  if Length(vValue) <= 0 then
  begin
    Result := False;
    Exit;
  end;

  if Length(vValue) <> THash.HashSize then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TIndexDBHelper.GetAddrHeightByHash(const ParaBlockHash: THash; out ParaAddr: TAddress; out ParaHeight: UInt64): Exception;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  Result := nil;
  ParaAddr := Default(TAddress);
  ParaHeight := 0;
  vKey := TChainUtils.CreateAccountBlockHashKey(ParaBlockHash).Bytes;

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

  ParaAddr := TAddress.BytesToAddress(vValue, vErr);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  ParaHeight := TChainUtils.BytesToUint64(vValue, TAddress.AddressSize);
end;

end.
