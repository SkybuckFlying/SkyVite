unit Wallet.EntropyStore.Manager;

interface

uses
  Classes,
  GoToDelphi.Helpers.TBytes,
  SysUtils,
  Vite.Common.Types,
  Vite.Crypto,
  Vite.Log15,
  Wallet.EntropyStore.Crypto.Store,
  Wallet.EntropyStore.Crypto.Store.Test,
  Wallet.EntropyStore.CryptoStore,
  Wallet.EntropyStore.Manager.Test,
  Wallet.EntropyStore.Models,
  Wallet.EntropyStore.Utils,
  Wallet.HD_BIP.Derivation;

const
  Locked = 'Locked';
  UnLocked = 'Unlocked';
  DefaultMaxIndex = 100;

type
  TUnlockEvent = record
    EntropyStoreFile: string;
    PrimaryAddr: TAddress;
    Event: string;
    function ToString: string;
    function Unlocked: Boolean;
  end;

  TUnlockChangedListener = reference to procedure(const ParaEvent: TUnlockEvent);

  TEntropyStoreManager = class
  private
    mPrimaryAddr: TAddress;
    mCryptoStore: TCryptoStore;
    mMaxSearchIndex: Cardinal;
    mUnlockedSeed: TBytes;
    mUnlockedEntropy: TBytes;
    mUnlockChangedListener: TUnlockChangedListener;
    mLog: ILog15Logger;
    function GetEntropyStoreFile: string;
    function GetPrimaryAddr: TAddress;
  public
    constructor Create(const ParaEntropyStoreFilename: string; const ParaPrimaryAddr: TAddress; ParaMaxSearchIndex: Cardinal);
    destructor Destroy; override;
    function IsAddrUnlocked(const ParaAddr: TAddress): Boolean;
    function IsUnlocked: Boolean;
    function ListAddress(ParaFrom, ParaTo: Cardinal): TArray<TAddress>;
    procedure Unlock(const ParaPassphrase: string);
    procedure Lock;
    function FindAddrWithPassphrase(const ParaPassphrase: string; const ParaAddr: TAddress; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
    function FindAddr(const ParaAddr: TAddress; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
    procedure SignData(const ParaAddr: TAddress; const ParaData: TBytes; out ParaSignedData, ParaPubKey: TBytes);
    function GetPrivateKey(const ParaAddr: TAddress): TEd25519PrivateKey;
    procedure SignDataWithPassphrase(const ParaAddr: TAddress; const ParaPassphrase: string; const ParaData: TBytes; out ParaSignedData, ParaPubKey: TBytes);
    function DeriveForFullPath(const ParaPath: string; out ParaFPath: string): TDerivationKey;
    function DeriveForIndexPath(ParaIndex: Cardinal; out ParaPath: string): TDerivationKey;
    function DeriveForFullPathWithPassphrase(const ParaPath, ParaPassphrase: string; out ParaFPath: string): TDerivationKey;
    function DeriveForIndexPathWithPassphrase(ParaIndex: Cardinal; const ParaPassphrase: string; out ParaPath: string): TDerivationKey;
    function ExtractMnemonic(const ParaPassphrase: string): string;
    procedure SetLockEventListener(const ParaLis: TUnlockChangedListener);
    procedure RemoveUnlockChangeChannel;
    class function StoreNewEntropy(const ParaStoreDir, ParaMnemonic, ParaPwd: string; ParaMaxSearchIndex: Cardinal): TEntropyStoreManager; static;
    class function MnemonicToPrimaryAddr(const ParaMnemonic: string): TAddress; static;
    class function NewMnemonic: string; static;
    class function FindAddrFromSeed(const ParaSeed: TBytes; const ParaAddr: TAddress; ParaMaxSearchIndex: Cardinal; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean; static;
    property PrimaryAddr: TAddress read GetPrimaryAddr;
    property EntropyStoreFile: string read GetEntropyStoreFile;
  end;

implementation

uses
  System.IOUtils,
  BIP39,
  Vite.Common.Errors,
  Wallet.EntropyStore.Utils;

function TUnlockEvent.ToString: string;
begin
  Result := EntropyStoreFile + ' ' + PrimaryAddr.ToString + ' ' + Event;
end;

function TUnlockEvent.Unlocked: Boolean;
begin
  Result := Event = UnLocked;
end;

constructor TEntropyStoreManager.Create(const ParaEntropyStoreFilename: string; const ParaPrimaryAddr: TAddress; ParaMaxSearchIndex: Cardinal);
begin
  mPrimaryAddr := ParaPrimaryAddr;
  mCryptoStore := TCryptoStore.Create(ParaEntropyStoreFilename);
  mMaxSearchIndex := ParaMaxSearchIndex;
  mLog := TLog15Logger.New('module', 'wallet/keystore/Manager');
end;

destructor TEntropyStoreManager.Destroy;
begin
  mCryptoStore.Free;
  inherited;
end;

function TEntropyStoreManager.IsAddrUnlocked(const ParaAddr: TAddress): Boolean;
var
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  if not IsUnlocked then
  begin
    Result := False;
    Exit;
  end;
  Result := FindAddrFromSeed(mUnlockedSeed, ParaAddr, mMaxSearchIndex, vKey, vIndex);
end;

function TEntropyStoreManager.IsUnlocked: Boolean;
begin
  Result := Length(mUnlockedSeed) > 0;
end;

function TEntropyStoreManager.ListAddress(ParaFrom, ParaTo: Cardinal): TArray<TAddress>;
var
  vIndex, vAddrIndex: Cardinal;
  vKey: TDerivationKey;
  vPath: string;
begin
  if ParaFrom > ParaTo then
  begin
    raise EArgumentException.Create('from > to');
  end;
  if mUnlockedSeed = nil then
  begin
    raise EWalletError.Create(ErrLocked);
  end;

  SetLength(Result, ParaTo - ParaFrom);
  vAddrIndex := 0;
  for vIndex := ParaFrom to ParaTo - 1 do
  begin
    vKey := DeriveForIndexPath(vIndex, vPath);
    Result[vAddrIndex] := vKey.Address;
    Inc(vAddrIndex);
  end;
end;

procedure TEntropyStoreManager.Unlock(const ParaPassphrase: string);
var
  vSeed, vEntropy: TBytes;
  vEvent: TUnlockEvent;
begin
  mCryptoStore.ExtractSeed(ParaPassphrase, vSeed, vEntropy);
  mUnlockedSeed := vSeed;
  mUnlockedEntropy := vEntropy;

  if Assigned(mUnlockChangedListener) then
  begin
    vEvent.EntropyStoreFile := GetEntropyStoreFile;
    vEvent.PrimaryAddr := mPrimaryAddr;
    vEvent.Event := UnLocked;
    mUnlockChangedListener(vEvent);
  end;
end;

procedure TEntropyStoreManager.Lock;
var
  vEvent: TUnlockEvent;
begin
  mUnlockedSeed := nil;
  if Assigned(mUnlockChangedListener) then
  begin
    vEvent.EntropyStoreFile := GetEntropyStoreFile;
    vEvent.PrimaryAddr := mPrimaryAddr;
    vEvent.Event := Locked;
    mUnlockChangedListener(vEvent);
  end;
end;

function TEntropyStoreManager.FindAddrWithPassphrase(const ParaPassphrase: string; const ParaAddr: TAddress; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
var
  vSeed, vEntropy: TBytes;
begin
  mCryptoStore.ExtractSeed(ParaPassphrase, vSeed, vEntropy);
  Result := FindAddrFromSeed(vSeed, ParaAddr, mMaxSearchIndex, ParaKey, ParaIndex);
end;

function TEntropyStoreManager.FindAddr(const ParaAddr: TAddress; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
begin
  if not IsUnlocked then
  begin
    raise EWalletError.Create(ErrLocked);
  end;
  Result := FindAddrFromSeed(mUnlockedSeed, ParaAddr, mMaxSearchIndex, ParaKey, ParaIndex);
end;

procedure TEntropyStoreManager.SignData(const ParaAddr: TAddress; const ParaData: TBytes; out ParaSignedData, ParaPubKey: TBytes);
var
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  if not IsUnlocked then
  begin
    raise EWalletError.Create(ErrLocked);
  end;
  if not FindAddrFromSeed(mUnlockedSeed, ParaAddr, mMaxSearchIndex, vKey, vIndex) then
  begin
    raise EAddressNotFound.Create('Address not found');
  end;
  vKey.SignData(ParaData, ParaSignedData, ParaPubKey);
end;

function TEntropyStoreManager.GetPrivateKey(const ParaAddr: TAddress): TEd25519PrivateKey;
var
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  if not FindAddrFromSeed(mUnlockedSeed, ParaAddr, mMaxSearchIndex, vKey, vIndex) then
  begin
    raise EAddressNotFound.Create('Address not found');
  end;
  Result := vKey.PrivateKey;
end;

procedure TEntropyStoreManager.SignDataWithPassphrase(const ParaAddr: TAddress; const ParaPassphrase: string; const ParaData: TBytes; out ParaSignedData, ParaPubKey: TBytes);
var
  vSeed, vEntropy: TBytes;
  vKey: TDerivationKey;
  vIndex: Cardinal;
begin
  mCryptoStore.ExtractSeed(ParaPassphrase, vSeed, vEntropy);
  if not FindAddrFromSeed(vSeed, ParaAddr, mMaxSearchIndex, vKey, vIndex) then
  begin
    raise EAddressNotFound.Create('Address not found');
  end;
  vKey.SignData(ParaData, ParaSignedData, ParaPubKey);
end;

function TEntropyStoreManager.DeriveForFullPath(const ParaPath: string; out ParaFPath: string): TDerivationKey;
begin
  if mUnlockedSeed = nil then
  begin
    raise EWalletError.Create(ErrLocked);
  end;
  Result := TDerivation.DeriveForPath(ParaPath, mUnlockedSeed);
  ParaFPath := ParaPath;
end;

function TEntropyStoreManager.DeriveForIndexPath(ParaIndex: Cardinal; out ParaPath: string): TDerivationKey;
begin
  ParaPath := Format(TViteDerivation.ViteAccountPathFormat, [ParaIndex]);
  Result := DeriveForFullPath(ParaPath, ParaPath);
end;

function TEntropyStoreManager.DeriveForFullPathWithPassphrase(const ParaPath, ParaPassphrase: string; out ParaFPath: string): TDerivationKey;
var
  vSeed, vEntropy: TBytes;
begin
  mCryptoStore.ExtractSeed(ParaPassphrase, vSeed, vEntropy);
  Result := TDerivation.DeriveForPath(ParaPath, vSeed);
  ParaFPath := ParaPath;
end;

function TEntropyStoreManager.DeriveForIndexPathWithPassphrase(ParaIndex: Cardinal; const ParaPassphrase: string; out ParaPath: string): TDerivationKey;
begin
  ParaPath := Format(TViteDerivation.ViteAccountPathFormat, [ParaIndex]);
  Result := DeriveForFullPathWithPassphrase(ParaPath, ParaPassphrase, ParaPath);
end;

function TEntropyStoreManager.GetPrimaryAddr: TAddress;
begin
  Result := mPrimaryAddr;
end;

function TEntropyStoreManager.GetEntropyStoreFile: string;
begin
  Result := mCryptoStore.EntropyStoreFilename;
end;

function TEntropyStoreManager.ExtractMnemonic(const ParaPassphrase: string): string;
var
  vEntropy: TBytes;
begin
  vEntropy := mCryptoStore.ExtractEntropy(ParaPassphrase);
  Result := TBIP39.NewMnemonic(vEntropy);
end;

procedure TEntropyStoreManager.SetLockEventListener(const ParaLis: TUnlockChangedListener);
begin
  mUnlockChangedListener := ParaLis;
end;

procedure TEntropyStoreManager.RemoveUnlockChangeChannel;
begin
  mUnlockChangedListener := nil;
end;

class function TEntropyStoreManager.StoreNewEntropy(const ParaStoreDir, ParaMnemonic, ParaPwd: string; ParaMaxSearchIndex: Cardinal): TEntropyStoreManager;
var
  vEntropy: TBytes;
  vPrimaryAddress: TAddress;
  vFilename: string;
  vSs: TCryptoStore;
begin
  vEntropy := TBIP39.EntropyFromMnemonic(ParaMnemonic);
  vPrimaryAddress := MnemonicToPrimaryAddr(ParaMnemonic);
  vFilename := TWalletUtils.FullKeyFileName(ParaStoreDir, vPrimaryAddress);
  vSs := TCryptoStore.Create(vFilename);
  try
    vSs.StoreEntropy(vEntropy, vPrimaryAddress, ParaPwd);
    Result := TEntropyStoreManager.Create(vFilename, vPrimaryAddress, ParaMaxSearchIndex);
  finally
    vSs.Free;
  end;
end;

class function TEntropyStoreManager.MnemonicToPrimaryAddr(const ParaMnemonic: string): TAddress;
var
  vSeed: TBytes;
begin
  vSeed := TBIP39.NewSeed(ParaMnemonic, '');
  Result := TDerivation.GetPrimaryAddress(vSeed);
end;

class function TEntropyStoreManager.NewMnemonic: string;
var
  vEntropy: TBytes;
begin
  vEntropy := TBIP39.NewEntropy(256);
  Result := TBIP39.NewMnemonic(vEntropy);
end;

class function TEntropyStoreManager.FindAddrFromSeed(const ParaSeed: TBytes; const ParaAddr: TAddress; ParaMaxSearchIndex: Cardinal; out ParaKey: TDerivationKey; out ParaIndex: Cardinal): Boolean;
var
  vIndex: Cardinal;
  vGenAddr: TAddress;
begin
  Result := False;
  for vIndex := 0 to ParaMaxSearchIndex - 1 do
  begin
    ParaKey := TDerivation.DeriveWithIndex(vIndex, ParaSeed);
    vGenAddr := ParaKey.Address;
    if ParaAddr.Equals(vGenAddr) then
    begin
      ParaIndex := vIndex;
      Result := True;
      Exit;
    end;
  end;
end;

end.
