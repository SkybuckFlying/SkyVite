unit Ledger.Chain.Index.Cache;

interface

uses
  Common.DB.XLevelDB.Cache,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Index,
  Ledger.Chain.Index.Account,
  Ledger.Chain.Index.Account.Block,
  Ledger.Chain.Index.Delete,
  Ledger.Chain.Index.Index.DB,
  Ledger.Chain.Index.Index.DB.Test,
  Ledger.Chain.Index.Insert,
  Ledger.Chain.Index.Interface,
  Ledger.Chain.Index.Onroad,
  Ledger.Chain.Index.Snapshot.Block,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TIndexDBHelper = class helper for TIndexDB
  public
    function NewCache: Exception;
    function InitCache(ParaChain: IChain): Exception;
    function GetValue(ParaKey: TBytes): TBytes;
  end;

implementation

uses
  GoToDelphi.Helpers.GoCache;

{ TIndexDBHelper }

function TIndexDBHelper.NewCache: Exception;
begin
  Result := nil;
  try
    mCache := TGoCache.Create(128, 1024, 10 * 60 * 1000);
    mAccountCache := TLruCache.Create(10 * 10000);
    mSendCreateBlockHashCache := TLruCache.Create(10000);
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

function TIndexDBHelper.InitCache(ParaChain: IChain): Exception;
var
  vReturnErr: Exception;
begin
  vReturnErr := nil;
  ParaChain.IterateContracts(
    function(ParaAddr: TAddress; ParaMeta: IContractMeta; ParaErr: Exception): Boolean
    var
      vBlockHash: THash;
      vSnapshotHeight: UInt64;
      vErr: Exception;
    begin
      if ParaErr <> nil then
      begin
        vReturnErr := ParaErr;
        Result := False;
        Exit;
      end;
      vBlockHash := ParaMeta.CreateBlockHash;
      if not vBlockHash.IsZero then
      begin
        vSnapshotHeight := GetConfirmHeightByHash(vBlockHash, vErr);
        if vErr <> nil then
        begin
          raise Exception.CreateFmt('indexDB initCache failed, Error: %s', [vErr.Message]);
        end;
        InsertConfirmCache(vBlockHash, vSnapshotHeight);
      end;
      Result := True;
    end
  );
  Result := vReturnErr;
end;

function TIndexDBHelper.GetValue(ParaKey: TBytes): TBytes;
var
  vValue: TBytes;
  vErr: Exception;
begin
  vValue := mCache.Get(string(ParaKey), vErr);
  if vErr <> nil then
  begin
    if vErr is EGoCacheEntryNotFound then
    begin
      vValue := mStore.Get(ParaKey, vErr);
      if vErr <> nil then
      begin
        raise vErr;
      end;
    end
    else
    begin
      raise vErr;
    end;
  end;
  Result := vValue;
end;

end.
