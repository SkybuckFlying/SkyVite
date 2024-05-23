unit unit_manager;

{

This is a Go code that implements a wallet manager for cryptocurrency transactions. The main functionality of this code includes:

1. **Entropy Store Management**: The code manages entropy stores, which are files that contain random data used to generate private keys and addresses for cryptocurrency transactions.
2. **Mnemonic Generation**: The code generates mnemonics, which are sequences of words used to recover a wallet's private keys.
3. **Address Derivation**: The code derives addresses from private keys using the Bitcoin protocol's BIP32 algorithm.
4. **Lock Event Handling**: The code handles lock events for entropy stores, such as when an entropy store is unlocked or locked.

The code defines several functions and methods:

1. `NewManager(config *Config)`: Creates a new wallet manager instance with the given configuration.
2. `AddEntropyStore(entropyStore string)`: Adds a new entropy store to the wallet manager's list of managed stores.
3. `GetEntropyStoreManager(entropyStore string)`: Returns a pointer to the entropy store manager for the given entropy store file.
4. `ExtractMnemonic(passphrase string)`: Extracts a mnemonic from an entropy store using a passphrase.
5. `RecoverEntropyStoreFromMnemonic(mnemonic string, passphrase string)`: Recovers an entropy store from a mnemonic and passphrase.
6. `NewMnemonicAndEntropyStore(passphrase string)`: Generates a new mnemonic and creates a new entropy store associated with it.
7. `GetDataDir()`: Returns the data directory path used by the wallet manager.
8. `Start()`: Initializes the wallet manager, including loading existing entropy stores and setting up lock event handling.
9. `Stop()`: Shuts down the wallet manager, releasing any held resources.

The code also includes several data structures:

1. `Manager`: The main wallet manager struct that holds references to various components, such as entropy store managers and configuration settings.
2. `EntropyStoreManager`: A struct that manages a single entropy store file, including lock event handling and address derivation.
3. `Config`: A struct that represents the wallet manager's configuration settings.

The code uses several external libraries and frameworks:

1. `entropystore`: A library for managing entropy stores (random data files).
2. `bip39`: A library for generating mnemonics from entropy data.
3. `types`: A type-safe library for working with cryptocurrency transaction types, such as addresses.

Overall, this code provides a robust implementation of a wallet manager for cryptocurrency transactions, allowing developers to create secure and reliable applications that interact with cryptocurrency networks.

}


interface

uses
  System.SysUtils,
  System.Generics.Collections,
  BIP39,
  EntropyStore;

type
  TConfig = record
    DataDir: string;
  end;

  TEntropyStoreManager = class
  private
    FLock: TRTLCriticalSection;
  public
    constructor Create(EntryPath: string);
    function DeriveForIndexPath(index: uint32): tuple of (address: TAddress, key: TKey);
    procedure RemoveUnlockChangeChannel(id: integer);
    procedure AddLockEventListener(lis: procedure(event: TUnlockEvent));
  end;

  TManager = class
  private
    FEntropyStoreManager: TDictionary<string, TEntropyStoreManager>;
    FMutex: TRTLCriticalSection;
    FUnlockChangedLis: TDictionary<integer, procedure(event: TUnlockEvent)>;
    FUnlockChangedIndex: integer;
  public
    constructor Create(config: TConfig);
    function GetEntropyStoreManager(EntryPath: string): TEntropyStoreManager;
    procedure Start();
    procedure Stop();
    procedure MatchAddress(EntryPath: string; coinbase: TAddress; index: uint32): HRESULT;
  end;

implementation

constructor TEntropyStoreManager.Create(EntryPath: string);
begin
  FLock := TRTLCriticalSection.Create;
end;

function TEntropyStoreManager.DeriveForIndexPath(index: uint32): tuple of (address: TAddress, key: TKey);
var
  manager: IEntropyStoreManager;
  key, e: TKey;
begin
  manager := GetEntropyStoreManager(EntryPath);
  if manager = nil then
    raise Exception.Create('err');
  address, key, e := manager.DeriveForIndexPath(index);
  if e <> nil then
    raise Exception.Create(e.Message);
  Result.address := address;
  Result.key := key;
end;

procedure TEntropyStoreManager.RemoveUnlockChangeChannel(id: integer);
begin
  FLock.Enter;
  try
    Delete(FUnlockChangedLis, id);
  finally
    FLock.Leave;
  end;
end;

procedure TEntropyStoreManager.AddLockEventListener(lis: procedure(event: TUnlockEvent));
var
  id: integer;
begin
  FLock.Enter;
  try
    inc(FUnlockChangedIndex);
    FUnlockChangedLis.Add(FUnlockChangedIndex, lis);
  finally
    FLock.Leave;
  end;
end;

constructor TManager.Create(config: TConfig);
begin
  FMutex := TRTLCriticalSection.Create;
  FEntropyStoreManager := TDictionary<string, TEntropyStoreManager>.Create;
  FUnlockChangedLis := TDictionary<integer, procedure(event: TUnlockEvent)>.Create;
  FUnlockChangedIndex := 0;
end;

function TManager.GetEntropyStoreManager(EntryPath: string): TEntropyStoreManager;
begin
  Result := FEntropyStoreManager[EntryPath];
end;

procedure TManager.Start();
var
  files, e: TArray<string>;
begin
  FMutex.Enter;
  try
    files, e := ListEntropyFilesInStandardDir();
    if e <> nil then
      raise Exception.Create(e.Message);
    for EntryPath in files do
    begin
      AddEntropyStore(EntryPath);
    end;
  finally
    FMutex.Leave;
  end;
end;

procedure TManager.Stop();
begin
  FMutex.Enter;
  try
    for EntryPath, manager in FEntropyStoreManager do
    begin
      manager.Lock();
      manager.RemoveUnlockChangeChannel();
    end;
    FEntropyStoreManager.Clear;
  finally
    FMutex.Leave;
  end;
end;

procedure TManager.MatchAddress(EntryPath: string; coinbase: TAddress; index: uint32): HRESULT;
var
  manager, e: IEntropyStoreManager;
begin
  manager := GetEntropyStoreManager(EntryPath);
  if manager = nil then
    raise Exception.Create('err');
  address, key, e := manager.DeriveForIndexPath(index);
  if e <> nil then
    raise Exception.Create(e.Message);
  if address = coinbase then
    Result := S_OK
  else
    Result := E_FAIL;
end;

end.
