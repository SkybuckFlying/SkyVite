unit VM.DB.Unsaved;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInteger,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Db.Xleveldb.Comparer,
  Vite.Common.Db.Xleveldb.Memdb,
  Vite.Common.Db.Xleveldb.Util,
  Vite.Common.Types,
  Vite.Interfaces,
  Vite.Interfaces.Core;

type
  TUnsaved = class
  private
    mContractMetaMap: TDictionary<TAddress, IContractMeta>;
    mCode: TBytes;
    mLogList: IVmLogList;
    mStorage: IDB;
    mDeletedKeys: TDictionary<string, Boolean>;
    mKeys: TDictionary<string, Boolean>;
    mStorageDirty: Boolean;
    mStorageCache: TArray<TPair<TBytes, TBytes>>;
    mBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function GetStorage: TArray<TPair<TBytes, TBytes>>;
    function GetBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
    function GetContractMetaMap: TDictionary<TAddress, IContractMeta>;
    function GetCode: TBytes;
    function GetContractMeta(const ParaAddr: TAddress): IContractMeta;
    function IsDelete(const ParaKey: TBytes): Boolean;
    procedure SetValue(const ParaKey, ParaValue: TBytes);
    function GetValue(const ParaKey: TBytes; out ParaValue: TBytes): Boolean;
    function GetBalance(const ParaTokenTypeId: TTokenTypeId; out ParaAmount: TBigInteger): Boolean;
    procedure SetBalance(const ParaTokenTypeId: TTokenTypeId; const ParaAmount: TBigInteger);
    procedure AddLog(const ParaLog: IVmLog);
    function GetLogList: IVmLogList;
    function GetLogListHash(const ParaSnapshotBlockHeight: UInt64; const ParaAddress: TAddress; const ParaPrevHash: THash): THash;
    procedure SetContractMeta(const ParaAddr: TAddress; const ParaContractMeta: IContractMeta);
    procedure SetCode(const ParaCode: TBytes);
    function NewStorageIterator(const ParaPrefix: TBytes): IStorageIterator;
    procedure ReleaseRuntime;
  end;

implementation

{ TUnsaved }

constructor TUnsaved.Create;
begin
  mContractMetaMap := TDictionary<TAddress, IContractMeta>.Create;
  mLogList := TVmLogList.Create;
  mKeys := TDictionary<string, Boolean>.Create;
  mDeletedKeys := TDictionary<string, Boolean>.Create;
  mStorage := TMemDB.Create(TDefaultComparer.Create, 0);
  mStorageDirty := False;
  mBalanceMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
end;

destructor TUnsaved.Destroy;
begin
  mContractMetaMap.Free;
  mKeys.Free;
  mDeletedKeys.Free;
  inherited;
end;

procedure TUnsaved.Reset;
begin
  mContractMetaMap.Clear;
  mCode := nil;
  mLogList := nil;
  mStorage.Reset;
  mDeletedKeys.Clear;
  mStorageDirty := False;
  mStorageCache := nil;
  mBalanceMap.Clear;
end;

function TUnsaved.GetStorage: TArray<TPair<TBytes, TBytes>>;
var
  vIter: IIterator;
  vIndex: Integer;
begin
  if mStorageDirty then
  begin
    vIter := mStorage.NewIterator(nil);
    try
      SetLength(mStorageCache, mKeys.Count);
      vIndex := 0;
      while vIter.Next do
      begin
        mStorageCache[vIndex] := TPair<TBytes, TBytes>.Create(vIter.Key, vIter.Value);
        Inc(vIndex);
      end;
    finally
      vIter.Release;
    end;
    mStorageDirty := False;
  end;
  Result := mStorageCache;
end;

function TUnsaved.GetBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
begin
  Result := mBalanceMap;
end;

function TUnsaved.GetContractMetaMap: TDictionary<TAddress, IContractMeta>;
begin
  Result := mContractMetaMap;
end;

function TUnsaved.GetCode: TBytes;
begin
  Result := mCode;
end;

function TUnsaved.GetContractMeta(const ParaAddr: TAddress): IContractMeta;
begin
  mContractMetaMap.TryGetValue(ParaAddr, Result);
end;

function TUnsaved.IsDelete(const ParaKey: TBytes): Boolean;
begin
  Result := mDeletedKeys.ContainsKey(string(ParaKey));
end;

procedure TUnsaved.SetValue(const ParaKey, ParaValue: TBytes);
var
  vKeyStr: string;
begin
  mStorageDirty := True;
  vKeyStr := string(ParaKey);
  mKeys.AddOrSetValue(vKeyStr, True);
  if Length(ParaValue) <= 0 then
  begin
    mDeletedKeys.AddOrSetValue(vKeyStr, True);
  end
  else if mDeletedKeys.ContainsKey(vKeyStr) then
  begin
    mDeletedKeys.Remove(vKeyStr);
  end;
  mStorage.Put(ParaKey, ParaValue);
end;

function TUnsaved.GetValue(const ParaKey: TBytes; out ParaValue: TBytes): Boolean;
var
  vErr: Exception;
begin
  ParaValue := mStorage.Get(ParaKey, vErr);
  if vErr <> nil then
  begin
    if mDeletedKeys.ContainsKey(string(ParaKey)) then
    begin
      ParaValue := nil;
      Result := True;
    end
    else
    begin
      Result := False;
    end;
  end
  else
  begin
    Result := True;
  end;
end;

function TUnsaved.GetBalance(const ParaTokenTypeId: TTokenTypeId; out ParaAmount: TBigInteger): Boolean;
begin
  Result := mBalanceMap.TryGetValue(ParaTokenTypeId, ParaAmount);
end;

procedure TUnsaved.SetBalance(const ParaTokenTypeId: TTokenTypeId; const ParaAmount: TBigInteger);
begin
  mBalanceMap.AddOrSetValue(ParaTokenTypeId, ParaAmount);
end;

procedure TUnsaved.AddLog(const ParaLog: IVmLog);
begin
  mLogList.Add(ParaLog);
end;

function TUnsaved.GetLogList: IVmLogList;
begin
  Result := mLogList;
end;

function TUnsaved.GetLogListHash(const ParaSnapshotBlockHeight: UInt64; const ParaAddress: TAddress; const ParaPrevHash: THash): THash;
begin
  Result := mLogList.Hash(ParaSnapshotBlockHeight, ParaAddress, ParaPrevHash);
end;

procedure TUnsaved.SetContractMeta(const ParaAddr: TAddress; const ParaContractMeta: IContractMeta);
begin
  mContractMetaMap.AddOrSetValue(ParaAddr, ParaContractMeta);
end;

procedure TUnsaved.SetCode(const ParaCode: TBytes);
begin
  mCode := ParaCode;
end;

function TUnsaved.NewStorageIterator(const ParaPrefix: TBytes): IStorageIterator;
begin
  Result := mStorage.NewIterator(TBytesPrefix.Create(ParaPrefix));
end;

procedure TUnsaved.ReleaseRuntime;
begin
  GetStorage;
  mStorage := nil;
end;

end.