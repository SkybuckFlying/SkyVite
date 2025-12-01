unit Wallet.Manager;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  SyncObjs,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Config,
  Vite.Common.Errors,
  Vite.Common.Types,
  Vite.Log15,
  Wallet.EntropyStore,
  Wallet.Account,
  Wallet.HD_BIP.Derivation;

type
  TUnlockChangedListener = reference to procedure(const ParaEvent: TUnlockEvent);

  TManager = class
  private
    mConfig: TWalletConfig;
    mUnlockChangedIndex: Integer;
    mEntropyStoreManager: TDictionary<string, TEntropyStoreManager>;
    mUnlockChangedLis: TDictionary<Integer, TUnlockChangedListener>;
    mMutex: TCriticalSection;
    mLog: ILog15Logger;
    function GetEntropyStoreManager(const ParaEntropyStore: string): TEntropyStoreManager;
  public
    constructor Create(const ParaConfig: TWalletConfig);
    destructor Destroy; override;
    function ListAllEntropyFiles: TArray<string>;
    procedure Unlock(const ParaEntropyStore, ParaPassphrase string);
    function IsUnlocked(const ParaEntropyStore: string): Boolean;
    procedure Lock(const ParaEntropyStore: string);
    function GlobalCheckAddrUnlock(const ParaTargetAdr: TAddress): Boolean;
    procedure RefreshCache;
    function Account(const ParaAddress: TAddress): IAccount;
    function AccountAtIndex(const ParaEntryPath: string; const ParaTarget: TAddress; ParaIndex: Cardinal): IAccount;
    function AccountSearch(const ParaEntryPath: string; const ParaTarget: TAddress; const ParaPassphrase: string): IAccount;
    function GlobalFindAddr(const ParaTargetAdr: TAddress; out ParaPath: string; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
    function GlobalFindAddrWithPassphrase(const ParaTargetAdr: TAddress; const ParaPass: string; out ParaPath: string; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
    function ListEntropyFilesInStandardDir: TArray<string>;
    function ExtractMnemonic(const ParaEntropyStore, ParaPassphrase string): string;
    procedure AddEntropyStore(const ParaEntropyStore: string);
    procedure RemoveEntropyStore(const ParaEntropyStore: string);
    function RecoverEntropyStoreFromMnemonic(const ParaMnemonic, ParaPassphrase string): TEntropyStoreManager;
    function NewMnemonicAndEntropyStore(const ParaPassphrase: string; out ParaMnemonic: string): TEntropyStoreManager;
    function GetDataDir: string;
    procedure Start;
    procedure Stop;
    function AddLockEventListener(const ParaLis: TUnlockChangedListener): Integer;
    procedure RemoveUnlockChangeChannel(ParaId: Integer);
    function MatchAddress(const ParaEntryPath: string; const ParaCoinbase: TAddress; ParaIndex: Cardinal): Boolean;
  end;

implementation

uses
  System.IOUtils,
  BIP39,
  Vite.Common,
  Wallet.HD_BIP.Derivation;

constructor TManager.Create(const ParaConfig: TWalletConfig);
begin
  if ParaConfig = nil then
  begin
    raise EArgumentNilException.Create('ParaConfig');
  end;

  mConfig := ParaConfig;
  if mConfig.MaxSearchIndex = 0 then
  begin
    mConfig.MaxSearchIndex := TEntropyStoreManager.DefaultMaxIndex;
  end;

  mUnlockChangedIndex := 0;
  mEntropyStoreManager := TDictionary<string, TEntropyStoreManager>.Create;
  mUnlockChangedLis := TDictionary<Integer, TUnlockChangedListener>.Create;
  mMutex := TCriticalSection.Create;
  mLog := TLog15Logger.New('module', 'wallet');
end;

destructor TManager.Destroy;
begin
  mEntropyStoreManager.Free;
  mUnlockChangedLis.Free;
  mMutex.Free;
  inherited;
end;

function TManager.ListAllEntropyFiles: TArray<string>;
begin
  mMutex.Acquire;
  try
    Result := mEntropyStoreManager.Keys.ToArray;
  finally
    mMutex.Release;
  end;
end;

procedure TManager.Unlock(const ParaEntropyStore, ParaPassphrase string);
var
  vManager: TEntropyStoreManager;
begin
  vManager := GetEntropyStoreManager(ParaEntropyStore);
  vManager.Unlock(ParaPassphrase);
end;

function TManager.IsUnlocked(const ParaEntropyStore: string): Boolean;
var
  vManager: TEntropyStoreManager;
begin
  try
    vManager := GetEntropyStoreManager(ParaEntropyStore);
    Result := vManager.IsUnlocked;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

procedure TManager.Lock(const ParaEntropyStore: string);
var
  vManager: TEntropyStoreManager;
begin
  vManager := GetEntropyStoreManager(ParaEntropyStore);
  vManager.Lock;
end;

function TManager.GlobalCheckAddrUnlock(const ParaTargetAdr: TAddress): Boolean;
var
  vPath: string;
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  Result := GlobalFindAddr(ParaTargetAdr, vPath, vKey, vIndex);
end;

procedure TManager.RefreshCache;
var
  vFilename: string;
  vManager: TEntropyStoreManager;
begin
  mMutex.Acquire;
  try
    for vFilename in mEntropyStoreManager.Keys do
    begin
      if not TFile.Exists(vFilename) then
      begin
        if mEntropyStoreManager.TryGetValue(vFilename, vManager) then
        begin
          vManager.Lock;
          mEntropyStoreManager.Remove(vFilename);
        end;
      end;
    end;
  finally
    mMutex.Release;
  end;
end;

function TManager.Account(const ParaAddress: TAddress): IAccount;
var
  vEm: TEntropyStoreManager;
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  mMutex.Acquire;
  try
    for vEm in mEntropyStoreManager.Values do
    begin
      if vEm.IsUnlocked then
      begin
        if vEm.FindAddr(ParaAddress, vKey, vIndex) then
        begin
          Result := TAccount.Create(ParaAddress, vKey);
          Exit;
        end;
      end;
    end;
  finally
    mMutex.Release;
  end;
  raise EAddressNotFound.Create('Address not found');
end;

function TManager.AccountAtIndex(const ParaEntryPath: string; const ParaTarget: TAddress; ParaIndex: Cardinal): IAccount;
var
  vManager: TEntropyStoreManager;
  vPath: string;
  vKey: TDerivationKey;
  vAddress: TAddress;
begin
  vManager := GetEntropyStoreManager(ParaEntryPath);
  vManager.DeriveForIndexPath(ParaIndex, vPath, vKey);
  vAddress := vKey.Address;
  if not vAddress.Equals(ParaTarget) then
  begin
    raise Exception.Create('address do not match.');
  end;
  Result := TAccount.Create(ParaTarget, vKey);
end;

function TManager.AccountSearch(const ParaEntryPath: string; const ParaTarget: TAddress; const ParaPassphrase: string): IAccount;
var
  vKey: TDerivationKey;
  vIndex: Cardinal;
  vManager: TEntropyStoreManager;
  vPath: string;
begin
  if ParaEntryPath = '' then
  begin
    if GlobalFindAddrWithPassphrase(ParaTarget, ParaPassphrase, vPath, vKey, vIndex) then
    begin
      Result := TAccount.Create(ParaTarget, vKey);
      Exit;
    end;
  end
  else
  begin
    vManager := GetEntropyStoreManager(ParaEntryPath);
    vManager.Unlock(ParaPassphrase);
    if vManager.FindAddr(ParaTarget, vKey, vIndex) then
    begin
      Result := TAccount.Create(ParaTarget, vKey);
      Exit;
    end;
  end;
  raise EAddressNotFound.Create('Address not found');
end;

function TManager.GlobalFindAddr(const ParaTargetAdr: TAddress; out ParaPath: string; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
var
  vEm: TEntropyStoreManager;
begin
  mMutex.Acquire;
  try
    for ParaPath in mEntropyStoreManager.Keys do
    begin
      vEm := mEntropyStoreManager[ParaPath];
      if vEm.IsUnlocked then
      begin
        if vEm.FindAddr(ParaTargetAdr, ParaKey, ParaIndex) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  finally
    mMutex.Release;
  end;
  Result := False;
end;

function TManager.GlobalFindAddrWithPassphrase(const ParaTargetAdr: TAddress; const ParaPass: string; out ParaPath: string; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
var
  vEm: TEntropyStoreManager;
begin
  mMutex.Acquire;
  try
    for ParaPath in mEntropyStoreManager.Keys do
    begin
      vEm := mEntropyStoreManager[ParaPath];
      if vEm.FindAddrWithPassphrase(ParaPass, ParaTargetAdr, ParaKey, ParaIndex) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    mMutex.Release;
  end;
  Result := False;
end;

function TManager.ListEntropyFilesInStandardDir: TArray<string>;
var
  vFiles: TArray<string>;
  vFile: string;
  vAbsFilePath: string;
  vIsMayValid: Boolean;
  vAddr: TAddress;
begin
  vFiles := TDirectory.GetFiles(mConfig.DataDir);
  Result := [];
  for vFile in vFiles do
  begin
    if TDirectory.Exists(vFile) then
    begin
      Continue;
    end;

    if TPath.GetFileName(vFile).StartsWith('.') or TPath.GetFileName(vFile).EndsWith('~') then
    begin
      Continue;
    end;

    vAbsFilePath := TPath.Combine(mConfig.DataDir, vFile);
    if not TEntropyStoreManager.IsMayValidEntropystoreFile(vAbsFilePath, vIsMayValid, vAddr) or not vIsMayValid then
    begin
      Continue;
    end;
    Result := Result + [vAbsFilePath];
  end;
end;

function TManager.ExtractMnemonic(const ParaEntropyStore, ParaPassphrase string): string;
var
  vManager: TEntropyStoreManager;
begin
  vManager := GetEntropyStoreManager(ParaEntropyStore);
  Result := vManager.ExtractMnemonic(ParaPassphrase);
end;

function TManager.GetEntropyStoreManager(const ParaEntropyStore: string): TEntropyStoreManager;
var
  vAbsPath: string;
begin
  vAbsPath := ParaEntropyStore;
  if not TPath.IsPathRooted(vAbsPath) then
  begin
    vAbsPath := TPath.Combine(mConfig.DataDir, ParaEntropyStore);
  end;

  mMutex.Acquire;
  try
    if mEntropyStoreManager.TryGetValue(vAbsPath, Result) then
    begin
      Exit;
    end;
  finally
    mMutex.Release;
  end;
  raise EStoreNotFound.Create('Store not found');
end;

procedure TManager.AddEntropyStore(const ParaEntropyStore: string);
var
  vAbsPath: string;
  vMayValid: Boolean;
  vAddr: TAddress;
  vManager: TEntropyStoreManager;
begin
  vAbsPath := ParaEntropyStore;
  if not TPath.IsPathRooted(vAbsPath) then
  begin
    vAbsPath := TPath.Combine(mConfig.DataDir, ParaEntropyStore);
  end;

  if not TEntropyStoreManager.IsMayValidEntropystoreFile(vAbsPath, vMayValid, vAddr) or not vMayValid then
  begin
    raise Exception.Create('not valid entropy store file');
  end;

  mMutex.Acquire;
  try
    if mEntropyStoreManager.ContainsKey(vAbsPath) then
    begin
      Exit;
    end;

    vManager := TEntropyStoreManager.Create(vAbsPath, vAddr, mConfig.MaxSearchIndex);
    vManager.SetLockEventListener(
      procedure(const ParaEvent: TUnlockEvent)
      var
        vLis: TUnlockChangedListener;
      begin
        Self.mMutex.Acquire;
        try
          for vLis in Self.mUnlockChangedLis.Values do
          begin
            vLis(ParaEvent);
          end;
        finally
          Self.mMutex.Release;
        end;
      end
    );
    mEntropyStoreManager.Add(vAbsPath, vManager);
  finally
    mMutex.Release;
  end;
end;

procedure TManager.RemoveEntropyStore(const ParaEntropyStore: string);
var
  vAbsPath: string;
  vManager: TEntropyStoreManager;
begin
  vAbsPath := ParaEntropyStore;
  if not TPath.IsPathRooted(vAbsPath) then
  begin
    vAbsPath := TPath.Combine(mConfig.DataDir, ParaEntropyStore);
  end;

  mMutex.Acquire;
  try
    if mEntropyStoreManager.TryGetValue(vAbsPath, vManager) then
    begin
      vManager.Lock;
      mEntropyStoreManager.Remove(vAbsPath);
    end;
  finally
    mMutex.Release;
  end;
end;

function TManager.RecoverEntropyStoreFromMnemonic(const ParaMnemonic, ParaPassphrase string): TEntropyStoreManager;
var
  vSm: TEntropyStoreManager;
begin
  vSm := TEntropyStoreManager.StoreNewEntropy(mConfig.DataDir, ParaMnemonic, ParaPassphrase, mConfig.MaxSearchIndex);

  mMutex.Acquire;
  try
    mEntropyStoreManager.Add(vSm.GetEntropyStoreFile, vSm);
    vSm.SetLockEventListener(
      procedure(const ParaEvent: TUnlockEvent)
      var
        vLis: TUnlockChangedListener;
      begin
        Self.mMutex.Acquire;
        try
          for vLis in Self.mUnlockChangedLis.Values do
          begin
            vLis(ParaEvent);
          end;
        finally
          Self.mMutex.Release;
        end;
      end
    );
  finally
    mMutex.Release;
  end;
  Result := vSm;
end;

function TManager.NewMnemonicAndEntropyStore(const ParaPassphrase: string; out ParaMnemonic: string): TEntropyStoreManager;
var
  vEntropy: TBytes;
begin
  vEntropy := TBIP39.NewEntropy(256);
  ParaMnemonic := TBIP39.NewMnemonic(vEntropy);
  Result := RecoverEntropyStoreFromMnemonic(ParaMnemonic, ParaPassphrase);
end;

function TManager.GetDataDir: string;
begin
  Result := mConfig.DataDir;
end;

procedure TManager.Start;
var
  vFiles: TArray<string>;
  vEntropyStore: string;
begin
  mMutex.Acquire;
  try
    mEntropyStoreManager.Clear;
    vFiles := ListEntropyFilesInStandardDir;
    for vEntropyStore in vFiles do
    begin
      try
        AddEntropyStore(vEntropyStore);
      except
        on E: Exception do
        begin
          mLog.Error('wallet start AddEntropyStore', 'err', E.Message);
          raise;
        end;
      end;
    end;
  finally
    mMutex.Release;
  end;
end;

procedure TManager.Stop;
var
  vEm: TEntropyStoreManager;
begin
  mMutex.Acquire;
  try
    for vEm in mEntropyStoreManager.Values do
    begin
      vEm.Lock;
      vEm.RemoveUnlockChangeChannel;
    end;
    mEntropyStoreManager.Clear;
  finally
    mMutex.Release;
  end;
end;

function TManager.AddLockEventListener(const ParaLis: TUnlockChangedListener): Integer;
begin
  mMutex.Acquire;
  try
    Inc(mUnlockChangedIndex);
    mUnlockChangedLis.Add(mUnlockChangedIndex, ParaLis);
    Result := mUnlockChangedIndex;
  finally
    mMutex.Release;
  end;
end;

procedure TManager.RemoveUnlockChangeChannel(ParaId: Integer);
begin
  mMutex.Acquire;
  try
    mUnlockChangedLis.Remove(ParaId);
  finally
    mMutex.Release;
  end;
end;

function TManager.MatchAddress(const ParaEntryPath: string; const ParaCoinbase: TAddress; ParaIndex: Cardinal): Boolean;
var
  vManager: TEntropyStoreManager;
  vPath: string;
  vKey: TDerivationKey;
  vAddress: TAddress;
begin
  vManager := GetEntropyStoreManager(ParaEntryPath);
  vManager.DeriveForIndexPath(ParaIndex, vPath, vKey);
  vAddress := vKey.Address;
  Result := vAddress.Equals(ParaCoinbase);
end;

end.