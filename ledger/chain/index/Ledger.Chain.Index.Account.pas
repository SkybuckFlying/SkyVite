unit Ledger.Chain.Index.Account;

interface

uses
  Common.Types,
  Interfaces,
  Ledger.Chain.Index,
  Ledger.Chain.Index.Account.Block,
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
    function HasAccount(ParaAddr: TAddress): Boolean;
    function GetAccountId(ParaAddr: TAddress): UInt64;
    function GetAccountAddress(ParaAccountId: UInt64): TAddress;
    procedure IterateAccounts(ParaIterateFunc: TFunc<TAddress, UInt64, Exception, Boolean>);
    function CreateAccount(ParaBatch: IBatch; ParaAddr: TAddress): UInt64;
    function QueryLatestAccountId: UInt64;
  end;

implementation

uses
  System.SyncObjs,
  Common.DB.XLevelDB.Util,
  Common.Helper;

{ TIndexDBHelper }

function TIndexDBHelper.HasAccount(ParaAddr: TAddress): Boolean;
var
  vOk: Boolean;
  vValue: TObject;
begin
  vValue := nil;
  vOk := mAccountCache.Get(ParaAddr, vValue);
  if vOk then
  begin
    Result := vOk;
    Exit;
  end;

  Result := mStore.Has(TChainUtils.CreateAccountAddressKey(ParaAddr).Bytes);
  if Result then
  begin
    mAccountCache.Add(ParaAddr, nil);
  end;
end;

function TIndexDBHelper.GetAccountId(ParaAddr: TAddress): UInt64;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
begin
  vKey := TChainUtils.CreateAccountAddressKey(ParaAddr).Bytes;
  vValue := mStore.Get(vKey, vErr);
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

function TIndexDBHelper.GetAccountAddress(ParaAccountId: UInt64): TAddress;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
  vAddr: TAddress;
begin
  vKey := TChainUtils.CreateAccountIdKey(ParaAccountId).Bytes;
  vValue := mStore.Get(vKey, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;

  if Length(vValue) <= 0 then
  begin
    Result := Default(TAddress);
    Exit;
  end;

  vAddr := TAddress.BytesToAddress(vValue, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Result := vAddr;
end;

procedure TIndexDBHelper.IterateAccounts(ParaIterateFunc: TFunc<TAddress, UInt64, Exception, Boolean>);
var
  vIter: IIterator;
  vAccountId: UInt64;
  vAccount: TAddress;
  vErr: Exception;
begin
  vIter := mStore.NewIterator(TBytesPrefix.Create(TBytes.Create(TChainUtils.AccountIdKeyPrefix)));
  try
    while vIter.Next do
    begin
      vAccountId := TBigEndian.ToUInt64(vIter.Key, 1);
      vAccount := TAddress.BytesToAddress(vIter.Value, vErr);

      if not ParaIterateFunc(vAccount, vAccountId, vErr) then
      begin
        Break;
      end;
      if vErr <> nil then
      begin
        Break;
      end;
    end;
  finally
    vIter.Release;
  end;
end;

function TIndexDBHelper.CreateAccount(ParaBatch: IBatch; ParaAddr: TAddress): UInt64;
var
  vNewAccountId: UInt64;
begin
  vNewAccountId := TInterlocked.Add(mLatestAccountId, 1);
  ParaBatch.Put(TChainUtils.CreateAccountAddressKey(ParaAddr).Bytes, TChainUtils.Uint64ToBytes(vNewAccountId));
  ParaBatch.Put(TChainUtils.CreateAccountIdKey(vNewAccountId).Bytes, ParaAddr.Bytes);
  Result := vNewAccountId;
end;

function TIndexDBHelper.QueryLatestAccountId: UInt64;
var
  vStartKey: TBytes;
  vEndKey: TBytes;
  vIter: IIterator;
  vLatestAccountId: UInt64;
  vErr: Exception;
begin
  vStartKey := TChainUtils.CreateAccountIdKey(1).Bytes;
  vEndKey := TChainUtils.CreateAccountIdKey(THelper.MaxUint64).Bytes;

  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    vLatestAccountId := 0;
    if vIter.Last then
    begin
      vLatestAccountId := TChainUtils.BytesToUint64(vIter.Key, 1);
    end;
    vErr := vIter.Error;
    if vErr <> nil then
    begin
      raise vErr;
    end;
    Result := vLatestAccountId;
  finally
    vIter.Release;
  end;
end;

end.
