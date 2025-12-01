unit VM.DB;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInteger,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Types,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Vite.Interfaces.VmDb,
  VM.DB.Interfaces,
  VM.DB.Unsaved,
  Common.Db.MergedIterator;

type
  TVmDb = class(TInterfacedObject, IVmDb)
  private
    mChain: IChain;
    mUnsaved: TUnsaved;
    mAddress: TAddress;
    mIsGenesis: Boolean;
    mLatestSnapshotBlockHash: THash;
    mLatestSnapshotBlock: ISnapshotBlock;
    mPrevAccountBlockHash: THash;
    mPrevAccountBlock: IAccountBlock;
    mCallDepth: ^Word;
    function GetUnsaved: TUnsaved;
  public
    constructor Create(const ParaChain: IChain; const ParaAddress: TAddress; const ParaLatestSnapshotBlockHash, ParaPrevAccountBlockHash: THash);
    constructor CreateNoContext(const ParaChain: IChain);
    constructor CreateByAddr(const ParaChain: IChain; const ParaAddress: TAddress);
    constructor CreateGenesis(const ParaAddress: TAddress);
    destructor Destroy; override;

    function CanWrite: Boolean;

    // IVmDb methods from account_block.go
    function GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<IAccountBlock>;
    function GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;

    // IVmDb methods from balance.go
    function GetBalance(const ParaTokenTypeId: TTokenTypeId): TBigInteger;
    procedure SetBalance(const ParaTokenTypeId: TTokenTypeId; const ParaAmount: TBigInteger);
    function GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;

    // IVmDb methods from builtin_contract.go
    function GetStakeBeneficialAmount(const ParaAddr: TAddress): TBigInteger;

    // IVmDb methods from context.go
    function Address: TAddress;
    function LatestSnapshotBlock: ISnapshotBlock;
    function PrevAccountBlockHash: THash;
    function PrevAccountBlock: IAccountBlock;
    function GetCallDepth(const ParaSendBlockHash: THash): Word;
    function GetQuotaUsedList(const ParaAddr: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;

    // IVmDb methods from storage.go, storage_iterator.go
    function GetValue(const ParaKey: TBytes): TBytes;
    function GetOriginalValue(const ParaKey: TBytes): TBytes;
    procedure SetValue(const ParaKey, ParaValue: TBytes);
    function GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
    function NewStorageIterator(const ParaPrefix: TBytes): IStorageIterator;

    // IVmDb methods from debug.go
    function DebugGetStorage: TDictionary<string, TBytes>;

    // IVmDb methods from meta_code.go
    procedure SetContractMeta(const ParaToAddr: TAddress; const ParaMeta: IContractMeta);
    function GetContractMeta: IContractMeta;
    function GetContractMetaInSnapshot(const ParaContractAddress: TAddress; const ParaSnapshotBlock: ISnapshotBlock): IContractMeta;
    procedure SetContractCode(const ParaCode: TBytes);
    function GetContractCode: TBytes;
    function GetContractCodeBySnapshotBlock(const ParaAddr: TAddress; const ParaSnapshotBlock: ISnapshotBlock): TBytes;
    function GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
    function GetUnsavedContractCode: TBytes;

    // IVmDb methods from snapshot_block.go
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetConfirmSnapshotHeader(const ParaBlockHash: THash): ISnapshotBlock;
    function GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
    function GetSnapshotBlockByHeight(const ParaHeight: UInt64): ISnapshotBlock;

    // IVmDb methods from state.go
    function GetReceiptHash: THash;
    procedure Reset;
    procedure Finish;

    // IVmDb methods from vm_log.go
    procedure AddLog(const ParaLog: IVmLog);
    function GetLogList: IVmLogList;
    function GetHistoryLogList(const ParaLogHash: THash): IVmLogList;
    function GetLogListHash: THash;
  end;

implementation

uses
  Vite.Crypto;

{ TVmDb }

constructor TVmDb.Create(const ParaChain: IChain; const ParaAddress: TAddress; const ParaLatestSnapshotBlockHash, ParaPrevAccountBlockHash: THash);
begin
  if ParaAddress = nil then
  begin
    raise Exception.Create('address is nil');
  end;
  if ParaLatestSnapshotBlockHash = nil then
  begin
    raise Exception.Create('latestSnapshotBlockHash is nil');
  end;
  if ParaPrevAccountBlockHash = nil then
  begin
    raise Exception.Create('prevAccountBlockHash is nil');
  end;

  mChain := ParaChain;
  mAddress := ParaAddress;
  mLatestSnapshotBlockHash := ParaLatestSnapshotBlockHash;
  mPrevAccountBlockHash := ParaPrevAccountBlockHash;
  mIsGenesis := False;
end;

constructor TVmDb.CreateNoContext(const ParaChain: IChain);
begin
  mChain := ParaChain;
end;

constructor TVmDb.CreateByAddr(const ParaChain: IChain; const ParaAddress: TAddress);
begin
  mChain := ParaChain;
  mAddress := ParaAddress;
end;

constructor TVmDb.CreateGenesis(const ParaAddress: TAddress);
begin
  mAddress := ParaAddress;
  mIsGenesis := True;
end;

destructor TVmDb.Destroy;
begin
  if mCallDepth <> nil then
  begin
    FreeMem(mCallDepth);
  end;
  inherited;
end;

function TVmDb.GetUnsaved: TUnsaved;
begin
  if mUnsaved = nil then
  begin
    mUnsaved := TUnsaved.Create;
  end;
  Result := mUnsaved;
end;

function TVmDb.CanWrite: Boolean;
begin
  Result := mIsGenesis or ((mAddress <> nil) and (mPrevAccountBlockHash <> nil) and (mLatestSnapshotBlockHash <> nil));
end;

function TVmDb.GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<IAccountBlock>;
begin
  Result := mChain.GetUnconfirmedBlocks(ParaAddress);
end;

function TVmDb.GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;
begin
  Result := mChain.GetLatestAccountBlock(ParaAddr);
end;

function TVmDb.GetBalance(const ParaTokenTypeId: TTokenTypeId): TBigInteger;
var
  vBalance: TBigInteger;
  vOk: Boolean;
begin
  if mUnsaved <> nil then
  begin
    if mUnsaved.GetBalance(ParaTokenTypeId, vBalance) then
    begin
      Result := vBalance;
      Exit;
    end;
  end;
  Result := mChain.GetBalance(mAddress, ParaTokenTypeId);
end;

procedure TVmDb.SetBalance(const ParaTokenTypeId: TTokenTypeId; const ParaAmount: TBigInteger);
begin
  GetUnsaved.SetBalance(ParaTokenTypeId, ParaAmount);
end;

function TVmDb.GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
begin
  if mUnsaved = nil then
  begin
    Result := TDictionary<TTokenTypeId, TBigInteger>.Create;
  end
  else
  begin
    Result := GetUnsaved.GetBalanceMap;
  end;
end;

function TVmDb.GetStakeBeneficialAmount(const ParaAddr: TAddress): TBigInteger;
begin
  if mLatestSnapshotBlockHash = nil then
  begin
    raise Exception.Create('no context, vdb.latestSnapshotBlockHash is nil');
  end;
  Result := mChain.GetStakeBeneficialAmount(ParaAddr);
end;

{ TVmDb from context.go }

function TVmDb.Address: TAddress;
begin
  Result := mAddress;
end;

function TVmDb.LatestSnapshotBlock: ISnapshotBlock;
begin
  if mLatestSnapshotBlock = nil then
  begin
    if mLatestSnapshotBlockHash = nil then
    begin
      raise Exception.Create('No context, vdb.latestSnapshotBlockHash is nil');
    end;
    mLatestSnapshotBlock := mChain.GetSnapshotHeaderByHash(mLatestSnapshotBlockHash);
    if mLatestSnapshotBlock = nil then
    begin
      raise Exception.CreateFmt('the returned snapshotHeader of vdb.chain.GetSnapshotHeaderByHash is nil, vdb.latestSnapshotBlockHash is %s', [mLatestSnapshotBlockHash.ToString]);
    end;
  end;
  Result := mLatestSnapshotBlock;
end;

function TVmDb.PrevAccountBlockHash: THash;
begin
  if mPrevAccountBlockHash = nil then
  begin
    Result := THash.CreateEmpty;
  end
  else
  begin
    Result := mPrevAccountBlockHash;
  end;
end;

function TVmDb.PrevAccountBlock: IAccountBlock;
begin
  if mPrevAccountBlock = nil then
  begin
    if mPrevAccountBlockHash = nil then
    begin
      raise Exception.Create('No context, vdb.prevAccountBlockHash is nil');
    end;
    if mPrevAccountBlockHash.IsZero then
    begin
      Result := nil;
      Exit;
    end;
    mPrevAccountBlock := mChain.GetAccountBlockByHash(mPrevAccountBlockHash);
    if mPrevAccountBlock = nil then
    begin
      raise Exception.CreateFmt('the returned accountBlock of vdb.chain.GetAccountBlockByHash is nil, vdb.prevAccountBlockHash is %s', [mPrevAccountBlockHash.ToString]);
    end;
  end;
  Result := mPrevAccountBlock;
end;

function TVmDb.GetCallDepth(const ParaSendBlockHash: THash): Word;
begin
  if mCallDepth <> nil then
  begin
    Result := mCallDepth^;
    Exit;
  end;

  New(mCallDepth);
  mCallDepth^ := mChain.GetCallDepth(ParaSendBlockHash);
  Result := mCallDepth^;
end;

function TVmDb.GetQuotaUsedList(const ParaAddr: TAddress): TArray<TQuotaInfo>;
begin
  Result := mChain.GetQuotaUsedList(ParaAddr);
end;

function TVmDb.GetGlobalQuota: TQuotaInfo;
begin
  Result := mChain.GetGlobalQuota;
end;

{ TVmDb from storage.go }

function TVmDb.GetValue(const ParaKey: TBytes): TBytes;
var
  vValue: TBytes;
begin
  if GetUnsaved.GetValue(ParaKey, vValue) then
  begin
    Result := vValue;
    Exit;
  end;
  Result := GetOriginalValue(ParaKey);
end;

function TVmDb.GetOriginalValue(const ParaKey: TBytes): TBytes;
begin
  Result := mChain.GetValue(mAddress, ParaKey);
end;

procedure TVmDb.SetValue(const ParaKey, ParaValue: TBytes);
begin
  if Length(ParaKey) > 32 then
  begin
    raise Exception.Create('the length of key is not allowed to exceed 32 bytes');
  end;
  GetUnsaved.SetValue(ParaKey, ParaValue);
end;

function TVmDb.GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
begin
  Result := GetUnsaved.GetStorage;
end;

{ TVmDb from storage_iterator.go }

function TVmDb.NewStorageIterator(const ParaPrefix: TBytes): IStorageIterator;
var
  vIter: IStorageIterator;
  vUnsavedIter: IStorageIterator;
begin
  vIter := mChain.GetStorageIterator(mAddress, ParaPrefix);
  vUnsavedIter := GetUnsaved.NewStorageIterator(ParaPrefix);
  Result := TMergedIterator.Create([vUnsavedIter, vIter], GetUnsaved.IsDelete);
end;

{ TVmDb from debug.go }

function TVmDb.DebugGetStorage: TDictionary<string, TBytes>;
var
  vIterator: IStorageIterator;
begin
  Result := TDictionary<string, TBytes>.Create;
  vIterator := Self.NewStorageIterator(nil);
  if vIterator = nil then
  begin
    Exit;
  end;

  try
    while vIterator.Next do
    begin
      Result.Add(string(vIterator.Key), vIterator.Value);
    end;
    if vIterator.GetError <> nil then
    begin
      raise vIterator.GetError;
    end;
  finally
    vIterator.Release;
  end;
end;

{ TVmDb from meta_code.go }

procedure TVmDb.SetContractMeta(const ParaToAddr: TAddress; const ParaMeta: IContractMeta);
begin
  GetUnsaved.SetContractMeta(ParaToAddr, ParaMeta);
end;

function TVmDb.GetContractMeta: IContractMeta;
var
  vMeta: IContractMeta;
begin
  if mAddress = nil then
  begin
    raise Exception.Create('no self address');
  end;

  if mUnsaved <> nil then
  begin
    vMeta := GetUnsaved.GetContractMeta(mAddress);
    if vMeta <> nil then
    begin
      Result := vMeta;
      Exit;
    end;
  end;

  Result := mChain.GetContractMeta(mAddress);
end;

function TVmDb.GetContractMetaInSnapshot(const ParaContractAddress: TAddress; const ParaSnapshotBlock: ISnapshotBlock): IContractMeta;
begin
  Result := mChain.GetContractMetaInSnapshot(ParaContractAddress, ParaSnapshotBlock.Height);
end;

procedure TVmDb.SetContractCode(const ParaCode: TBytes);
begin
  GetUnsaved.SetCode(ParaCode);
end;

function TVmDb.GetContractCode: TBytes;
var
  vCode: TBytes;
begin
  if mUnsaved <> nil then
  begin
    vCode := GetUnsaved.GetCode;
    if Length(vCode) > 0 then
    begin
      Result := vCode;
      Exit;
    end;
  end;

  Result := mChain.GetContractCode(mAddress);
end;

function TVmDb.GetContractCodeBySnapshotBlock(const ParaAddr: TAddress; const ParaSnapshotBlock: ISnapshotBlock): TBytes;
begin
  Result := nil;
end;

function TVmDb.GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
begin
  Result := GetUnsaved.GetContractMetaMap;
end;

function TVmDb.GetUnsavedContractCode: TBytes;
begin
  Result := GetUnsaved.GetCode;
end;

{ TVmDb from snapshot_block.go }

function TVmDb.GetGenesisSnapshotBlock: ISnapshotBlock;
begin
  Result := mChain.GetGenesisSnapshotBlock;
end;

function TVmDb.GetConfirmSnapshotHeader(const ParaBlockHash: THash): ISnapshotBlock;
begin
  Result := mChain.GetConfirmSnapshotHeaderByAbHash(ParaBlockHash);
end;

function TVmDb.GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
begin
  Result := mChain.GetConfirmedTimes(ParaBlockHash);
end;

function TVmDb.GetSnapshotBlockByHeight(const ParaHeight: UInt64): ISnapshotBlock;
begin
  Result := mChain.GetSnapshotBlockByHeight(ParaHeight);
end;

{ TVmDb from state.go }

function TVmDb.GetReceiptHash: THash;
var
  vKVList: TArray<TPair<TBytes, TBytes>>;
  vSize: Integer;
  vKV: TPair<TBytes, TBytes>;
  vHashSource: TBytes;
  vIndex: Integer;
begin
  vKVList := GetUnsaved.GetStorage;
  if Length(vKVList) <= 0 then
  begin
    Result := THash.CreateEmpty;
    Exit;
  end;

  vSize := 0;
  for vKV in vKVList do
  begin
    vSize := vSize + Length(vKV.Key) + Length(vKV.Value);
  end;

  SetLength(vHashSource, vSize);
  vIndex := 0;
  for vKV in vKVList do
  begin
    System.Move(vKV.Key[0], vHashSource[vIndex], Length(vKV.Key));
    Inc(vIndex, Length(vKV.Key));
    System.Move(vKV.Value[0], vHashSource[vIndex], Length(vKV.Value));
    Inc(vIndex, Length(vKV.Value));
  end;

  Result := TViteCrypto.Hash256(vHashSource);
end;

procedure TVmDb.Reset;
begin
  GetUnsaved.Reset;
end;

procedure TVmDb.Finish;
begin
  GetUnsaved.ReleaseRuntime;
end;

{ TVmDb from vm_log.go }

procedure TVmDb.AddLog(const ParaLog: IVmLog);
begin
  GetUnsaved.AddLog(ParaLog);
end;

function TVmDb.GetLogList: IVmLogList;
begin
  Result := GetUnsaved.GetLogList;
end;

function TVmDb.GetHistoryLogList(const ParaLogHash: THash): IVmLogList;
begin
  Result := mChain.GetVmLogList(ParaLogHash);
end;

function TVmDb.GetLogListHash: THash;
var
  vSBHeight: UInt64;
  vLatestSB: ISnapshotBlock;
begin
  vSBHeight := 0;
  if not mIsGenesis then
  begin
    vLatestSB := Self.LatestSnapshotBlock;
    if vLatestSB = nil then
    begin
      raise Exception.Create('Error: latest snapshot block is nil');
    end;
    vSBHeight := vLatestSB.Height;
  end;

  Result := GetUnsaved.GetLogListHash(vSBHeight, Self.Address, Self.PrevAccountBlockHash);
end;

end.