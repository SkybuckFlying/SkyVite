unit RpcApi.Api.WalletV2;

interface

uses
  Common.Types Wallet,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  System.SysUtils System.Classes System.JSON;

type
  TCreateEntropyFileResponse = class
  private
    FMnemonics: string;
    FPrimaryAddress: TAddress;
    FFilePath: string;
  public
    property Mnemonics: string read FMnemonics write FMnemonics;
    property PrimaryAddress: TAddress read FPrimaryAddress write FPrimaryAddress;
    property FilePath: string read FFilePath write FFilePath;
    function ToJSON: TJSONObject;
  end;

  TFindAddrResponse = class
  private
    FEntropyFile: string;
    FIndex: UInt32;
  public
    property EntropyFile: string read FEntropyFile write FEntropyFile;
    property Index: UInt32 read FIndex write FIndex;
    function ToJSON: TJSONObject;
  end;

  TCreateTransactionParams = class
  private
    FEntropyFile: PString;
    FAddress: TAddress;
    FToAddress: TAddress;
    FTokenId: TTokenTypeId;
    FPassphrase: string;
    FAmount: string;
    FData: TBytes;
    FDifficulty: PString;
  public
    property EntropyFile: PString read FEntropyFile write FEntropyFile;
    property Address: TAddress read FAddress write FAddress;
    property ToAddress: TAddress read FToAddress write FToAddress;
    property TokenId: TTokenTypeId read FTokenId write FTokenId;
    property Passphrase: string read FPassphrase write FPassphrase;
    property Amount: string read FAmount write FAmount;
    property Data: TBytes read FData write FData;
    property Difficulty: PString read FDifficulty write FDifficulty;
  end;

  TWalletApiV2 = class(TWalletApi)
  public
    function GetEntropyFilesInStandardDir: TArray<string>;
    function GetAllEntropyFiles: TArray<string>;
    function ExportMnemonic(const EntropyFile, Passphrase: string): string;
    procedure Unlock(const EntropyFile, Passphrase: string);
    procedure Lock(const EntropyFile: string);
    function DeriveAddressesByIndexRange(const EntropyFile: string; StartIndex, EndIndex: UInt32): TArray<TAddress>;
    function CreateEntropyFile(const Passphrase: string): TCreateEntropyFileResponse;
    function DeriveAddressByIndex(const EntropyFile: string; Index: UInt32): TDeriveResult;
    function DeriveAddressByPath(const EntropyFile, Bip44Path: string): TDeriveResult;
    function RecoverEntropyFile(const Mnemonics, Passphrase: string): TCreateEntropyFileResponse;
    function IsUnlocked(const EntropyFile: string): Boolean;
    function FindAddressInEntropyFile(const EntropyFile: string; Address: TAddress): TFindAddrResponse;
    function FindAddress(Address: TAddress): TFindAddrResponse;
    function CreateTransaction(Params: TCreateTransactionParams): THash;
  end;

implementation

uses
  System.StrUtils,
  Wallet.EntropyStore, Crypto;

{ TCreateEntropyFileResponse }

function TCreateEntropyFileResponse.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('mnemonics', FMnemonics);
  Result.AddPair('primaryAddress', FPrimaryAddress.ToJSON);
  Result.AddPair('filePath', FFilePath);
end;

{ TFindAddrResponse }

function TFindAddrResponse.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('entropyFile', FEntropyFile);
  Result.AddPair('index', TJSONNumber.Create(FIndex));
end;

{ TWalletApiV2 }

function TWalletApiV2.GetEntropyFilesInStandardDir: TArray<string>;
begin
  Result := FWallet.ListEntropyFilesInStandardDir;
end;

function TWalletApiV2.GetAllEntropyFiles: TArray<string>;
begin
  Result := FWallet.ListAllEntropyFiles;
end;

function TWalletApiV2.ExportMnemonic(const EntropyFile, Passphrase: string): string;
begin
  Result := FWallet.ExtractMnemonic(EntropyFile, Passphrase);
end;

procedure TWalletApiV2.Unlock(const EntropyFile, Passphrase: string);
var
  Manager: TEntropyStoreManager;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Manager.Unlock(Passphrase);
end;

procedure TWalletApiV2.Lock(const EntropyFile: string);
var
  Manager: TEntropyStoreManager;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Manager.Lock;
end;

function TWalletApiV2.DeriveAddressesByIndexRange(const EntropyFile: string; StartIndex, EndIndex: UInt32): TArray<TAddress>;
var
  Manager: TEntropyStoreManager;
begin
  if StartIndex > EndIndex then
    raise Exception.Create('from value > to');
  if EndIndex - StartIndex > 5000 then
    raise Exception.Create('endIndex-startIndex must be less than 5000');

  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Result := Manager.ListAddress(StartIndex, EndIndex);
end;

function TWalletApiV2.CreateEntropyFile(const Passphrase: string): TCreateEntropyFileResponse;
var
  Mnemonic: string;
  Em: TEntropyStoreManager;
begin
  FWallet.NewMnemonicAndEntropyStore(Passphrase, Mnemonic, Em);
  Result := TCreateEntropyFileResponse.Create;
  Result.Mnemonics := Mnemonic;
  Result.PrimaryAddress := Em.GetPrimaryAddr;
  Result.FilePath := Em.GetEntropyStoreFile;
end;

function TWalletApiV2.DeriveAddressByIndex(const EntropyFile: string; Index: UInt32): TDeriveResult;
var
  Manager: TEntropyStoreManager;
  Path: string;
  Key: TKey;
  Address: TAddress;
  PrivateKey: TBytes;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Manager.DeriveForIndexPath(Index, Path, Key);
  Address := Key.Address;
  PrivateKey := Key.PrivateKey;
  Result := TDeriveResult.Create;
  Result.Bip44Path := Path;
  Result.Address := Address;
  Result.PrivateKey := PrivateKey;
end;

function TWalletApiV2.DeriveAddressByPath(const EntropyFile, Bip44Path: string): TDeriveResult;
var
  Manager: TEntropyStoreManager;
  Key: TKey;
  Address: TAddress;
  PrivateKey: TBytes;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Manager.DeriveForFullPath(Bip44Path, Key);
  Address := Key.Address;
  PrivateKey := Key.PrivateKey;
  Result := TDeriveResult.Create;
  Result.Bip44Path := Bip44Path;
  Result.Address := Address;
  Result.PrivateKey := PrivateKey;
end;

function TWalletApiV2.RecoverEntropyFile(const Mnemonics, Passphrase: string): TCreateEntropyFileResponse;
var
  Em: TEntropyStoreManager;
begin
  Em := FWallet.RecoverEntropyStoreFromMnemonic(Mnemonics, Passphrase);
  Result := TCreateEntropyFileResponse.Create;
  Result.Mnemonics := Mnemonics;
  Result.PrimaryAddress := Em.GetPrimaryAddr;
  Result.FilePath := Em.GetEntropyStoreFile;
end;

function TWalletApiV2.IsUnlocked(const EntropyFile: string): Boolean;
begin
  Result := FWallet.IsUnlocked(EntropyFile);
end;

function TWalletApiV2.FindAddressInEntropyFile(const EntropyFile: string; Address: TAddress): TFindAddrResponse;
var
  Manager: TEntropyStoreManager;
  Index: UInt32;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyFile);
  Manager.FindAddr(Address, Index);
  Result := TFindAddrResponse.Create;
  Result.EntropyFile := Manager.GetEntropyStoreFile;
  Result.Index := Index;
end;

function TWalletApiV2.FindAddress(Address: TAddress): TFindAddrResponse;
var
  Path: string;
  Index: UInt32;
begin
  FWallet.GlobalFindAddr(Address, Path, Index);
  Result := TFindAddrResponse.Create;
  Result.EntropyFile := Path;
  Result.Index := Index;
end;

function TWalletApiV2.CreateTransaction(Params: TCreateTransactionParams): THash;
var
  TxParams: TCreateTransferTxParams;
begin
  TxParams := TCreateTransferTxParams.Create;
  if Params.EntropyFile <> nil then
    TxParams.EntropystoreFile := Params.EntropyFile^;
  TxParams.SelfAddr := Params.Address;
  TxParams.ToAddr := Params.ToAddress;
  TxParams.TokenTypeId := Params.TokenId;
  TxParams.Passphrase := Params.Passphrase;
  TxParams.Amount := Params.Amount;
  TxParams.Data := Params.Data;
  if Params.Difficulty <> nil then
    TxParams.Difficulty := Params.Difficulty^;
  Result := CreateTxWithPassphrase(TxParams);
end;

end.
