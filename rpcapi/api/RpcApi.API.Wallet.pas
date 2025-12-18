unit RpcApi.Api.Wallet;

interface

uses
  Ledger.Consensus,
  Ledger.Pool Vm.Contracts.Dex Wallet Wallet.EntropyStore,
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
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.JSON BigNumbers,
  Vite Common.Types Interfaces Interfaces.Core Ledger.Chain Ledger.Generator;

type
  THexSignedTuple = class
  private
    FMessage: string;
    FSignedData: string;
    FPubKey: string;
  public
    property Message: string read FMessage write FMessage;
    property SignedData: string read FSignedData write FSignedData;
    property PubKey: string read FPubKey write FPubKey;
    function ToJSON: TJSONObject;
  end;

  TNewStoreResponse = class
  private
    FMnemonic: string;
    FPrimaryAddr: TAddress;
    FFilename: string;
  public
    property Mnemonic: string read FMnemonic write FMnemonic;
    property PrimaryAddr: TAddress read FPrimaryAddr write FPrimaryAddr;
    property Filename: string read FFilename write FFilename;
    function ToJSON: TJSONObject;
  end;

  TFindAddrResult = class
  private
    FEntropyStoreFile: string;
    FIndex: UInt32;
  public
    property EntropyStoreFile: string read FEntropyStoreFile write FEntropyStoreFile;
    property Index: UInt32 read FIndex write FIndex;
    function ToJSON: TJSONObject;
  end;

  TDeriveResult = class
  private
    FBip44Path: string;
    FAddress: TAddress;
    FPrivateKey: TBytes;
  public
    property Bip44Path: string read FBip44Path write FBip44Path;
    property Address: TAddress read FAddress write FAddress;
    property PrivateKey: TBytes read FPrivateKey write FPrivateKey;
    function ToJSON: TJSONObject;
  end;

  TCreateTransferTxParams = class
  private
    FEntropystoreFile: PString;
    FSelfAddr: TAddress;
    FToAddr: TAddress;
    FTokenTypeId: TTokenTypeId;
    FPassphrase: string;
    FAmount: string;
    FData: TBytes;
    FDifficulty: PString;
  public
    property EntropystoreFile: PString read FEntropystoreFile write FEntropystoreFile;
    property SelfAddr: TAddress read FSelfAddr write FSelfAddr;
    property ToAddr: TAddress read FToAddr write FToAddr;
    property TokenTypeId: TTokenTypeId read FTokenTypeId write FTokenTypeId;
    property Passphrase: string read FPassphrase write FPassphrase;
    property Amount: string read FAmount write FAmount;
    property Data: TBytes read FData write FData;
    property Difficulty: PString read FDifficulty write FDifficulty;
  end;

  TIsMayValidKeystoreFileResponse = record
    Maybe: Boolean;
    MayAddress: TAddress;
  end;

  TWalletApi = class
  protected
    FWallet: TWalletManager;
    FChain: IChain;
    FPool: IPoolWriter;
    FConsensus: IConsensus;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function ListAllEntropyFiles: TArray<string>;
    function ListEntropyFilesInStandardDir: TArray<string>;
    function ListEntropyStoreAddresses(const EntropyStore: string; From, ToValue: UInt32): TArray<TAddress>;
    function NewMnemonicAndEntropyStore(const Passphrase: string): TNewStoreResponse;
    function DeriveByFullPath(const EntropyStore, FullPath: string): TDeriveResult;
    function DeriveByIndex(const EntropyStore: string; Index: UInt32): TDeriveResult;
    function RecoverEntropyStoreFromMnemonic(const Mnemonic, NewPassphrase: string): TNewStoreResponse;
    function GlobalCheckAddrUnlocked(Addr: TAddress): Boolean;
    function IsAddrUnlocked(const EntropyStore: string; Addr: TAddress): Boolean;
    procedure RefreshCache;
    function ExtractMnemonic(const EntropyStore, Passphrase: string): string;
    function FindAddrWithPassphrase(const EntropyStore, Passphrase: string; Addr: TAddress): TFindAddrResult;
    function FindAddr(const EntropyStore: string; Addr: TAddress): TFindAddrResult;
    function GlobalFindAddr(Addr: TAddress): TFindAddrResult;
    function GlobalFindAddrWithPassphrase(Addr: TAddress; const Passphrase: string): TFindAddrResult;
    procedure AddEntropyStore(const Filename: string);
    function SignData(Addr: TAddress; const HexMsg: string): THexSignedTuple;
    function CreateTxWithPassphrase(Params: TCreateTransferTxParams): THash;
    function SignDataWithPassphrase(Addr: TAddress; const HexMsg, Passphrase: string): THexSignedTuple;
    function IsMayValidKeystoreFile(const Path: string): TIsMayValidKeystoreFileResponse;
    function GetDataDir: string;
    function GetPrivateKey(const EntropyStore, Passphrase: string): PString;
  end;

implementation

uses
  System.StrUtils, System.NetEncoding,
  Common.HexUtil;

{ THexSignedTuple }

function THexSignedTuple.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('message', FMessage);
  Result.AddPair('signedData', FSignedData);
  Result.AddPair('pubkey', FPubKey);
end;

{ TNewStoreResponse }

function TNewStoreResponse.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('mnemonic', FMnemonic);
  Result.AddPair('primaryAddr', FPrimaryAddr.ToJSON);
  Result.AddPair('filename', FFilename);
end;

{ TFindAddrResult }

function TFindAddrResult.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('entropyStoreFile', FEntropyStoreFile);
  Result.AddPair('index', TJSONNumber.Create(FIndex));
end;

{ TDeriveResult }

function TDeriveResult.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('bip44Path', FBip44Path);
  Result.AddPair('address', FAddress.ToJSON);
  Result.AddPair('privateKey', TNetEncoding.Base64.EncodeBytesToString(FPrivateKey));
end;

{ TWalletApi }

constructor TWalletApi.Create(AVite: TVite);
begin
  FWallet := AVite.WalletManager;
  FChain := AVite.Chain;
  FPool := AVite.Pool;
  FConsensus := AVite.Consensus;
end;

function TWalletApi.GetString: string;
begin
  Result := 'WalletApi';
end;

function TWalletApi.ListAllEntropyFiles: TArray<string>;
begin
  Result := FWallet.ListAllEntropyFiles;
end;

function TWalletApi.ListEntropyFilesInStandardDir: TArray<string>;
begin
  Result := FWallet.ListEntropyFilesInStandardDir;
end;

function TWalletApi.ListEntropyStoreAddresses(const EntropyStore: string; From, ToValue: UInt32): TArray<TAddress>;
var
  Manager: TEntropyStoreManager;
begin
  if From > ToValue then
    raise Exception.Create('from value > to');
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Result := Manager.ListAddress(From, ToValue);
end;

function TWalletApi.NewMnemonicAndEntropyStore(const Passphrase: string): TNewStoreResponse;
var
  Mnemonic: string;
  Em: TEntropyStoreManager;
begin
  FWallet.NewMnemonicAndEntropyStore(Passphrase, Mnemonic, Em);
  Result := TNewStoreResponse.Create;
  Result.Mnemonic := Mnemonic;
  Result.PrimaryAddr := Em.GetPrimaryAddr;
  Result.Filename := Em.GetEntropyStoreFile;
end;

function TWalletApi.DeriveByFullPath(const EntropyStore, FullPath: string): TDeriveResult;
var
  Manager: TEntropyStoreManager;
  Key: TKey;
  Address: TAddress;
  PrivateKey: TBytes;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Manager.DeriveForFullPath(FullPath, Key);
  Address := Key.Address;
  PrivateKey := Key.PrivateKey;
  Result := TDeriveResult.Create;
  Result.Bip44Path := FullPath;
  Result.Address := Address;
  Result.PrivateKey := PrivateKey;
end;

function TWalletApi.DeriveByIndex(const EntropyStore: string; Index: UInt32): TDeriveResult;
var
  Manager: TEntropyStoreManager;
  Path: string;
  Key: TKey;
  Address: TAddress;
  PrivateKey: TBytes;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Manager.DeriveForIndexPath(Index, Path, Key);
  Address := Key.Address;
  PrivateKey := Key.PrivateKey;
  Result := TDeriveResult.Create;
  Result.Bip44Path := Path;
  Result.Address := Address;
  Result.PrivateKey := PrivateKey;
end;

function TWalletApi.RecoverEntropyStoreFromMnemonic(const Mnemonic, NewPassphrase: string): TNewStoreResponse;
var
  Em: TEntropyStoreManager;
begin
  Em := FWallet.RecoverEntropyStoreFromMnemonic(Mnemonic, NewPassphrase);
  Result := TNewStoreResponse.Create;
  Result.Mnemonic := Mnemonic;
  Result.PrimaryAddr := Em.GetPrimaryAddr;
  Result.Filename := Em.GetEntropyStoreFile;
end;

function TWalletApi.GlobalCheckAddrUnlocked(Addr: TAddress): Boolean;
begin
  Result := FWallet.GlobalCheckAddrUnlock(Addr);
end;

function TWalletApi.IsAddrUnlocked(const EntropyStore: string; Addr: TAddress): Boolean;
var
  Manager: TEntropyStoreManager;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Result := Manager.IsAddrUnlocked(Addr);
end;

procedure TWalletApi.RefreshCache;
begin
  FWallet.RefreshCache;
end;

function TWalletApi.ExtractMnemonic(const EntropyStore, Passphrase: string): string;
begin
  Result := FWallet.ExtractMnemonic(EntropyStore, Passphrase);
end;

function TWalletApi.FindAddrWithPassphrase(const EntropyStore, Passphrase: string; Addr: TAddress): TFindAddrResult;
var
  Manager: TEntropyStoreManager;
  Index: UInt32;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Manager.FindAddrWithPassphrase(Passphrase, Addr, Index);
  Result := TFindAddrResult.Create;
  Result.EntropyStoreFile := Manager.GetEntropyStoreFile;
  Result.Index := Index;
end;

function TWalletApi.FindAddr(const EntropyStore: string; Addr: TAddress): TFindAddrResult;
var
  Manager: TEntropyStoreManager;
  Index: UInt32;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Manager.FindAddr(Addr, Index);
  Result := TFindAddrResult.Create;
  Result.EntropyStoreFile := Manager.GetEntropyStoreFile;
  Result.Index := Index;
end;

function TWalletApi.GlobalFindAddr(Addr: TAddress): TFindAddrResult;
var
  Path: string;
  Index: UInt32;
begin
  FWallet.GlobalFindAddr(Addr, Path, Index);
  Result := TFindAddrResult.Create;
  Result.EntropyStoreFile := Path;
  Result.Index := Index;
end;

function TWalletApi.GlobalFindAddrWithPassphrase(Addr: TAddress; const Passphrase: string): TFindAddrResult;
var
  Path: string;
  Index: UInt32;
begin
  FWallet.GlobalFindAddrWithPassphrase(Addr, Passphrase, Path, Index);
  Result := TFindAddrResult.Create;
  Result.EntropyStoreFile := Path;
  Result.Index := Index;
end;

procedure TWalletApi.AddEntropyStore(const Filename: string);
begin
  FWallet.AddEntropyStore(Filename);
end;

function TWalletApi.SignData(Addr: TAddress; const HexMsg: string): THexSignedTuple;
var
  Hash: THash;
  Account: IAccount;
  SignedData, PubKey: TBytes;
begin
  Hash := THex.HexToHash(HexMsg);
  Account := FWallet.Account(Addr);
  Account.Sign(Hash.Bytes, SignedData, PubKey);
  Result := THexSignedTuple.Create;
  Result.Message := HexMsg;
  Result.PubKey := THex.EncodeToString(PubKey);
  Result.SignedData := THex.EncodeToString(SignedData);
end;

function TWalletApi.CreateTxWithPassphrase(Params: TCreateTransferTxParams): THash;
var
  Amount, Difficulty: TBigInteger;
  Msg: IIncomingMessage;
  AddrState: TAddressState;
  G: TGenerator;
  Account: IAccount;
  GenResult: TGenerateResult;
begin
  if not CheckTxToAddressAvailable(Params.ToAddr) then
    raise Exception.Create('ToAddress is invalid');
  if (Params.ToAddr = AddressDexFund) and (not TDex.VerifyNewOrderPriceForRpc(Params.Data)) then
    raise Exception.Create(InvalidOrderPriceErr);
  if not TryStrToBigInt(Params.Amount, Amount) then
    raise Exception.Create(ErrStrToBigInt);
  if CheckTokenIdValid(FChain, Params.TokenTypeId) <> nil then
    raise Exception.Create(CheckTokenIdValid(FChain, Params.TokenTypeId).Message);
  Difficulty := nil;
  if Params.Difficulty <> nil then
  begin
    if not TryStrToBigInt(Params.Difficulty^, Difficulty) then
      raise Exception.Create(ErrStrToBigInt);
  end;

  Msg := TIncomingMessage.Create;
  Msg.BlockType := BlockTypeSendCall;
  Msg.AccountAddress := Params.SelfAddr;
  Msg.ToAddress := Params.ToAddr;
  Msg.TokenId := Params.TokenTypeId;
  Msg.Amount := Amount;
  Msg.Fee := nil;
  Msg.Difficulty := Difficulty;
  Msg.Data := Params.Data;

  AddrState := TGenerator.GetAddressStateForGenerator(FChain, Msg.AccountAddress);
  if AddrState = nil then
    raise Exception.Create(Format('failed to get addr state for generator, err:%v', [Err]));

  G := TGenerator.Create(FChain, FConsensus.SBPReader, Msg.AccountAddress, AddrState.LatestSnapshotHash, AddrState.LatestAccountHash);
  try
    Account := FWallet.AccountSearch(Params.EntropystoreFile^, Msg.AccountAddress, Params.Passphrase);
    GenResult := G.GenerateWithMessage(Msg, Msg.AccountAddress, Account.Sign);
    if GenResult.Err <> nil then
      raise Exception.Create(GenResult.Err.Message);
    if GenResult.VMBlock <> nil then
    begin
      Result := GenResult.VMBlock.AccountBlock.Hash;
      FPool.AddDirectAccountBlock(Params.SelfAddr, GenResult.VMBlock);
    end
    else
      raise Exception.Create('generator gen an empty block');
  finally
    G.Free;
  end;
end;

function TWalletApi.SignDataWithPassphrase(Addr: TAddress; const HexMsg, Passphrase: string): THexSignedTuple;
var
  Hash: THash;
  Account: IAccount;
  SignedData, PubKey: TBytes;
begin
  Hash := THex.HexToHash(HexMsg);
  Account := FWallet.AccountSearch('', Addr, Passphrase);
  Account.Sign(Hash.Bytes, SignedData, PubKey);
  Result := THexSignedTuple.Create;
  Result.Message := HexMsg;
  Result.PubKey := THex.EncodeToString(PubKey);
  Result.SignedData := THex.EncodeToString(SignedData);
end;

function TWalletApi.IsMayValidKeystoreFile(const Path: string): TIsMayValidKeystoreFileResponse;
var
  B: Boolean;
  Addr: TAddress;
begin
  TEntropyStore.IsMayValidEntropystoreFile(Path, B, Addr);
  if B and (Addr <> nil) then
  begin
    Result.Maybe := True;
    Result.MayAddress := Addr;
  end
  else
  begin
    Result.Maybe := False;
    Result.MayAddress := TAddress.Create;
  end;
end;

function TWalletApi.GetDataDir: string;
begin
  Result := FWallet.GetDataDir;
end;

function TWalletApi.GetPrivateKey(const EntropyStore, Passphrase: string): PString;
var
  Manager: TEntropyStoreManager;
  Pk: TBytes;
  PkStr: string;
begin
  Manager := FWallet.GetEntropyStoreManager(EntropyStore);
  Manager.Unlock(Passphrase);
  Pk := Manager.GetPrivateKey(Manager.GetPrimaryAddr);
  PkStr := THex.EncodeToString(Pk);
  Result := @PkStr;
end;

end.
