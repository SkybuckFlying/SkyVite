unit Ledger.Chain.State.Cache;

interface

uses
  System.SysUtils,
  GoToDelphi.Helpers.GoCache,
  Common.Types,
  Ledger.Chain.State.StateDB;

const
  ConstSnapshotValuePrefix = 'a';
  ConstContractAddrPrefix  = 'b';
  ConstBalancePrefix       = 'c';

type
  TStateDBCacheHelper = class helper for TStateDB
  public
    procedure NewCache;
    procedure InitCache;
    procedure DisableCache;
    procedure EnableCache;
    function GetValue(ParaKey: TBytes; const ParaCachePrefix: string): TBytes;
    function GetValueInCache(ParaKey: TBytes; const ParaCachePrefix: string): TBytes;
    function ParseStorageKey(ParaKey: TBytes): TBytes;
    function CopyValue(ParaValue: TBytes): TBytes;
  private
    procedure InitSnapshotValueCache;
    procedure InitContractMetaCache;
  end;

implementation

uses
  Common.DB.XLevelDB.Util,
  Ledger.Chain.Utils;

{ TStateDBCacheHelper }

procedure TStateDBCacheHelper.NewCache;
begin
  try
    Self.mCache := TGoCache.Create(TGoCache.NoExpiration, TGoCache.NoExpiration);
  except
    on E: Exception do
    begin
      // In Go, an error is returned. In Delphi, an exception is raised.
      // The caller should handle this exception.
      raise;
    end;
  end;
end;

// with cache
procedure TStateDBCacheHelper.InitCache;
begin
  Self.InitSnapshotValueCache;
  Self.InitContractMetaCache;
end;

procedure TStateDBCacheHelper.DisableCache;
begin
  Self.mUseCache := False;
end;

procedure TStateDBCacheHelper.EnableCache;
begin
  Self.mUseCache := True;
end;

procedure TStateDBCacheHelper.InitSnapshotValueCache;
var
  vContractAddr: TAddress;
  vIter: IIterator;
  vKey: TBytes;
  vReturnErr: Exception;
begin
  for vContractAddr in types.BuiltinContracts do
  begin
    vIter := Self.NewStorageIterator(vContractAddr, nil);
    vReturnErr := nil;
    try
      while vIter.Next do
      begin
        //fmt.Printf("init set snapshot value cache: %d, %d\n", []byte(snapshotValuePrefix+addrStr+string(key)), sDB.copyValue(value))
        vKey := TEncoding.UTF8.GetBytes(ConstSnapshotValuePrefix) + vContractAddr.Bytes + vIter.Key;
        Self.mCache.Set(string(vKey), Self.CopyValue(vIter.Value), TGoCache.NoExpiration);
      end;
      vReturnErr := vIter.Error;
    finally
      vIter.Release;
    end;

    if vReturnErr <> nil then
    begin
      raise vReturnErr;
    end;
  end;
end;

procedure TStateDBCacheHelper.InitContractMetaCache;
var
  vIter: IIterator;
  vKey: TBytes;
  vError: Exception;
begin
  vIter := Self.mStore.NewIterator(util.BytesPrefix(TEncoding.UTF8.GetBytes(string(chain_utils.ContractMetaKeyPrefix))));
  try
    while vIter.Next do
    begin
      vKey := TEncoding.UTF8.GetBytes(ConstContractAddrPrefix) + vIter.Key;
      Self.mCache.Set(string(vKey), Self.CopyValue(vIter.Value), TGoCache.NoExpiration);
    end;
    vError := vIter.Error;
    if vError <> nil then
    begin
      raise vError;
    end;
  finally
    vIter.Release;
  end;
end;

// with cache
function TStateDBCacheHelper.GetValue(ParaKey: TBytes; const ParaCachePrefix: string): TBytes;
var
  vOK: Boolean;
  vValue: TObject;
begin
  vOK := False;
  vValue := nil;
  if Self.mUseCache then
  begin
    vValue := Self.mCache.Get(ParaCachePrefix + string(ParaKey), vOK);
  end;

  if not vOK then
  begin
    try
      Result := Self.mStore.Get(ParaKey);
    except
      on E: Exception do
      begin
        Result := nil;
        raise;
      end;
    end;
  end
  else
  begin
    Result := TBytes(vValue);
  end;
end;

function TStateDBCacheHelper.GetValueInCache(ParaKey: TBytes; const ParaCachePrefix: string): TBytes;
var
  vValue: TObject;
  vOK: Boolean;
begin
  if not Self.mUseCache then
  begin
    Result := Self.GetValue(ParaKey, ParaCachePrefix);
    Exit;
  end;

  vValue := Self.mCache.Get(ParaCachePrefix + string(ParaKey), vOK);
  if not vOK then
  begin
    Result := nil;
    Exit;
  end;
  Result := TBytes(vValue);
end;

function TStateDBCacheHelper.ParseStorageKey(ParaKey: TBytes): TBytes;
var
  vRealKey: TBytes;
begin
  vRealKey := Copy(ParaKey, 1 + types.AddressSize, types.HashSize + 1);
  SetLength(Result, vRealKey[Length(vRealKey)-1]);
  System.Move(vRealKey[0], Result[0], Length(Result));
end;

function TStateDBCacheHelper.CopyValue(ParaValue: TBytes): TBytes;
begin
  SetLength(Result, Length(ParaValue));
  System.Move(ParaValue[0], Result[0], Length(ParaValue));
end;

end.
