unit Client.LibWallet.Wallet;

interface

uses
  Client.ABI.Client,
  Client.ABI.Client.Test,
  Client.Client,
  Client.Client.Test,
  Client.Dex.Client,
  Client.Dex.Client.Test,
  Client.LibWallet.Wallet,
  Client.RPC,
  Client.RPC.Contract,
  Client.RPC.Dex.Trade,
  Client.RPC.Ledger,
  Client.RPC.Onroad,
  Client.RPC.Random,
  Client.RPC.Test,
  Client.RPC.Tx,
  Client.SBP.Upgrade.Test,
  Cmd.Generator.Wallet.Main,
  Cmd.Gvite.Main,
  Cmd.Gvite.Plugins.Load.Plugins,
  Cmd.Gvite.Plugins.MiscCmd,
  Cmd.Gvite.Plugins.SubCmd.Demo,
  Cmd.NodeManager.Assist,
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Export.Node.Manager,
  Cmd.NodeManager.Full.Node.Maker,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Maker,
  Cmd.NodeManager.Node.Manager,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  Cmd.Printer.Blocks.Main,
  Cmd.Printer.Consensus.Main,
  Cmd.Printer.Index.Main,
  Cmd.Printer.Main,
  Cmd.Printer.Storage.Main,
  Cmd.Printer.Vote.Main,
  Cmd.SubCmd.Check.Chain.Check.Chain,
  Cmd.SubCmd.Export.Export,
  Cmd.SubCmd.Ledger.DumpBalance,
  Cmd.SubCmd.Ledger.Ledger,
  Cmd.SubCmd.Loadledger.Load.Ledger,
  Cmd.SubCmd.Plugin.Data.Plugin.Data.Cmd,
  Cmd.SubCmd.Recover.SubCmd.Recover,
  Cmd.SubCmd.RPC.RPC.Call,
  Cmd.SubCmd.VirtualNode.Virtual.Node,
  Cmd.Updater.Consensus.Main,
  Cmd.Updater.Main,
  Cmd.Utils.Cli,
  Cmd.Utils.Customflags,
  Cmd.Utils.Customflags.Test,
  Cmd.Utils.Flags,
  Cmd.Utils.Flock.Flock,
  Cmd.Utils.Flock.Flock.Darwin,
  Cmd.Utils.Flock.Flock.Linux,
  Cmd.Utils.Flock.Flock.Plan9,
  Cmd.Utils.Flock.Flock.Solaris,
  Cmd.Utils.Flock.Flock.Windows,
  Cmd.Utils.Path,
  Common.Bloom.Bloom,
  Common.Bloom.Bloom.Test,
  Common.Bloom.Bucket,
  Common.Bloom.Util,
  Common.Bytes,
  Common.Bytes.Test,
  Common.Condtimeout,
  Common.Condtimeout.Test,
  Common.Condtimer,
  Common.Condtimer.Test,
  Common.Config,
  Common.Config.Chain,
  Common.Config.Config,
  Common.Config.Genesis,
  Common.Config.Genesis.Json,
  Common.Config.Genesis.Mock.Json,
  Common.Config.Genesis.Test,
  Common.Config.Net,
  Common.Config.Node.Reward,
  Common.Config.Producer,
  Common.Config.Subscribe,
  Common.Config.Upgrade,
  Common.Config.VM,
  Common.Config.Wallet,
  Common.DB.Memdb,
  Common.DB.Merged.Iterator,
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Cache.Cache,
  Common.DB.XLevelDB.Cache.Lru,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.Comparer.Bytes.Comparer,
  Common.DB.XLevelDB.Comparer.Comparer,
  Common.DB.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Iter,
  Common.DB.XLevelDB.DB.Snapshot,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Errors.Errors,
  Common.DB.XLevelDB.Filter,
  Common.DB.XLevelDB.Filter.Bloom,
  Common.DB.XLevelDB.Filter.Filter,
  Common.DB.XLevelDB.Iterator.Array.Iter,
  Common.DB.XLevelDB.Iterator.Indexed.Iter,
  Common.DB.XLevelDB.Iterator.Iter,
  Common.DB.XLevelDB.Iterator.Merged.Iter,
  Common.DB.XLevelDB.Journal.Journal,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Memdb.Memdb,
  Common.DB.XLevelDB.Opt.Options,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Storage.File.Storage,
  Common.DB.XLevelDB.Storage.File.Storage.Nacl,
  Common.DB.XLevelDB.Storage.File.Storage.Plan9,
  Common.DB.XLevelDB.Storage.File.Storage.Solaris,
  Common.DB.XLevelDB.Storage.File.Storage.Unix,
  Common.DB.XLevelDB.Storage.File.Storage.Windows,
  Common.DB.XLevelDB.Storage.Mem.Storage,
  Common.DB.XLevelDB.Storage.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Table.Reader,
  Common.DB.XLevelDB.Table.Table,
  Common.DB.XLevelDB.Table.Writer,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Util.Buffer,
  Common.DB.XLevelDB.Util.Buffer.Pool,
  Common.DB.XLevelDB.Util.Crc32,
  Common.DB.XLevelDB.Util.Hash,
  Common.DB.XLevelDB.Util.Range,
  Common.DB.XLevelDB.Util.Util,
  Common.DB.XLevelDB.Version,
  Common.Default.Params,
  Common.Errors.Errors,
  Common.Errors.Wallet.Errors,
  Common.Fileutils.Common.Use,
  Common.GoRoutine,
  Common.GoRoutine.Test,
  Common.Helper.Common,
  Common.Helper.Common.Test,
  Common.Helper.Math.Big,
  Common.Helper.Math.Integer,
  Common.Helper.Math.Test,
  Common.Helper.Rand,
  Common.Helper.Rand.Test,
  Common.Helper.Slice,
  Common.HexUtil.HexUtil,
  Common.HexUtil.HexUtil.Test,
  Common.HexUtil.Json,
  Common.HexUtil.Json.Example.Test,
  Common.HexUtil.Json.Test,
  Common.Lifecycle,
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Math.Big,
  Common.Math.Big.Test,
  Common.Math.Integer,
  Common.Math.Integer.Test,
  Common.Mock,
  Common.Mock.Test,
  Common.Types,
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  Common.Upgrade.Face,
  Common.Upgrade.Height.Point,
  Common.Upgrade.Upgrade,
  Common.Upgrade.Upgrade.Init,
  Common.Upgrade.Upgrade.Test,
  Common.Utils,
  Common.Version,
  Common.VitePB.Account.Block.PB,
  Common.VitePB.Account.Blockmeta.PB,
  Common.VitePB.Account.PB,
  Common.VitePB.Consensus.Point.PB,
  Common.VitePB.Message.PB,
  Common.VitePB.Onroad.PB,
  Common.VitePB.Snapshot.Block.PB,
  Common.VitePB.Sync.Cache.PB,
  Common.VitePB.VM.Log.List.PB,
  Crypto.Crypto,
  Crypto.Crypto.Test,
  Crypto.Ed25519,
  Crypto.Ed25519.Ed25519,
  Crypto.Ed25519.Ed25519.Test,
  Crypto.Ed25519.Internal.Edwards25519.Const,
  Crypto.Ed25519.Internal.Edwards25519.Edwards25519,
  Crypto.Hash,
  Crypto.Hast.Test,
  Interfaces.Core,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  Wallet.EntropyStore,
  Wallet.Wallet;

type
	TGoResult = class
	public
		Error: string;
		Code: Integer;
		Data: TJSONValue;
		constructor Create;
		destructor Destroy; override;
	end;

	TEntropyResult = class
	public
		Mnemonic: string;
		EntropyStore: string;
	end;

	TDerivationResult = class
	public
		Path: string;
		Address: string;
		PrivateKey: string;
	end;

	TSignDataResult = class
	public
		PublicKey: string;
		Data: string;
		Signature: string;
	end;

var
	GWalletInstance: TManager;
	GVerbose: Boolean = False;

function SuccessResult: string;
function SuccessResultWithData( const ParaData: TJSONValue ): string;
function FailResult( const ParaErr: Exception ): string;

function InitWallet( const ParaDataDir: string; ParaMaxSearchIndex: Integer; ParaUseLightScrypt: Boolean ): string;
function ListAllEntropyFiles: string;
function Unlock( const ParaEntropyStore, ParaPassphrase: string ): string;
function IsUnlocked( const ParaEntropyStore: string ): string;
function Lock( const ParaEntropyStore: string ): string;
function AddEntropyStore( const ParaEntropyStore: string ): string;
function RemoveEntropyStore( const ParaEntropyStore: string ): string;
function RecoverEntropyStoreFromMnemonic( const ParaMnemonic, ParaNewPassphrase, ParaLanguage, ParaExtensionWord: string ): string;
function NewMnemonicAndEntropyStore( const ParaPassphrase, ParaLanguage, ParaExtensionWord: string; ParaMnemonicSize: Integer ): string;
function DeriveByFullPath( const ParaEntropyStore, ParaFullPath, ParaExtensionWord: string ): string;
function DeriveByIndex( const ParaEntropyStore: string; ParaIndex: Integer; const ParaExtensionWord: string ): string;
function ExtractMnemonic( const ParaEntropyStore, ParaPassphrase: string ): string;
function GetDataDir: string;
function EntropyStoreToAddress( const ParaEntropyStore: string ): string;
function Hash256( const ParaData: string ): string;
function Hash( ParaSize: Integer; const ParaData: string ): string;
function SignData( const ParaPrivHex, ParaMessageBase64: string ): string;
function VerifySignature( const ParaPub, ParaMessage, ParaSignData: string ): string;
function PubkeyToAddress( const ParaPubBase64: string ): string;
function TransformMnemonic( const ParaMnemonic, ParaLanguage, ParaExtensionWord: string ): string;
function RandomMnemonic( const ParaLanguage: string; ParaMnemonicSize: Integer ): string;
function ComputeHashForAccountBlock( const ParaBlock: string ): string;
function Hello( const ParaName: string ): string;
procedure SetVerbose( ParaFlag: Boolean );

implementation

uses
  System.Net.Encoding;

{ TGoResult }

constructor TGoResult.Create;
begin
	inherited;
end;

destructor TGoResult.Destroy;
begin
	Data.Free;
	inherited;
end;

function SuccessResult: string;
begin
	Result := '{"Code":0}';
end;

function SuccessResultWithData( const ParaData: TJSONValue ): string;
var
	vResult: TGoResult;
	vJson: TJSONObject;
begin
	vResult := nil;
	vJson := nil;
	try
		try
			vResult := TGoResult.Create;
			vResult.Code := 0;
			vResult.Data := ParaData;
			vJson := TJSONObject.Create;
			vJson.AddPair('Code', TJSONNumber.Create(vResult.Code));
			vJson.AddPair('Data', vResult.Data);
			Result := vJson.ToString;
		except
			on E: Exception do
			begin
				Result := FailResult(E);
			end;
		end;
	finally
		vJson.Free;
		vResult.Free;
	end;
end;

function FailResult( const ParaErr: Exception ): string;
begin
	Result := Format('{"Error":"%s","Code":1}', [ParaErr.Message]);
end;

function InitWallet( const ParaDataDir: string; ParaMaxSearchIndex: Cardinal; ParaUseLightScrypt: Boolean ): string;
var
	vWalletConfig: TWalletConfig;
begin
	try
		vWalletConfig := TWalletConfig.Create;
		try
			vWalletConfig.DataDir := ParaDataDir;
			vWalletConfig.MaxSearchIndex := ParaMaxSearchIndex;
			GWalletInstance := TManager.New(vWalletConfig);
			GWalletInstance.Start;
			Result := SuccessResult;
		finally
			vWalletConfig.Free;
		end;
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function ListAllEntropyFiles: string;
var
	vFiles: TArray<string>;
	vJsonArray: TJSONArray;
	vIndex: Integer;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	vJsonArray := nil;
	try
		try
			vFiles := GWalletInstance.ListAllEntropyFiles;
			vJsonArray := TJSONArray.Create;
			for vIndex := 0 to High(vFiles) do
			begin
				vJsonArray.AddElement(TJSONString.Create(vFiles[vIndex]));
			end;
			Result := SuccessResultWithData(vJsonArray);
		except
			on E: Exception do
			begin
				Result := FailResult(E);
			end;
		end;
	finally
		vJsonArray.Free;
	end;
end;

function Unlock( const ParaEntropyStore, ParaPassphrase: string ): string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		GWalletInstance.Unlock(ParaEntropyStore, ParaPassphrase);
		Result := SuccessResult;
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function IsUnlocked( const ParaEntropyStore: string ): string;
var
	vIsUnlocked: Boolean;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		vIsUnlocked := GWalletInstance.IsUnlocked(ParaEntropyStore);
		Result := SuccessResultWithData(TJSONBool.Create(vIsUnlocked));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function Lock( const ParaEntropyStore: string ): string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		GWalletInstance.Lock(ParaEntropyStore);
		Result := SuccessResult;
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function AddEntropyStore( const ParaEntropyStore: string ): string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		GWalletInstance.AddEntropyStore(ParaEntropyStore);
		Result := SuccessResult;
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function RemoveEntropyStore( const ParaEntropyStore: string ): string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		GWalletInstance.RemoveEntropyStore(ParaEntropyStore);
		Result := SuccessResult;
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function RecoverEntropyStoreFromMnemonic( const ParaMnemonic, ParaNewPassphrase, ParaLanguage, ParaExtensionWord: string ): string;
var
	vEntropyManager: IEntropyStoreManager;
	vPrimaryAddr: TAddress;
	vResult: TEntropyResult;
	vJson: TJSONObject;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	vResult := nil;
	vJson := nil;
	try
		try
			vEntropyManager := GWalletInstance.RecoverEntropyStoreFromMnemonic(ParaMnemonic, ParaNewPassphrase);
			vPrimaryAddr := vEntropyManager.GetPrimaryAddr;

			vResult := TEntropyResult.Create;
			vResult.Mnemonic := ParaMnemonic;
			vResult.EntropyStore := vPrimaryAddr.ToString;

			vJson := TJSONObject.Create;
			vJson.AddPair('mnemonic', TJSONString.Create(vResult.Mnemonic));
			vJson.AddPair('entropyStore', TJSONString.Create(vResult.EntropyStore));
			Result := SuccessResultWithData(vJson);
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vResult.Free;
	end;
end;

function NewMnemonicAndEntropyStore( const ParaPassphrase, ParaLanguage, ParaExtensionWord: string; ParaMnemonicSize: Integer ): string;
var
	vMnemonic: string;
	vEntropyManager: IEntropyStoreManager;
	vPrimaryAddr: TAddress;
	vResult: TEntropyResult;
	vJson: TJSONObject;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	vResult := nil;
	vJson := nil;
	try
		try
			GWalletInstance.NewMnemonicAndEntropyStore(ParaPassphrase, vMnemonic, vEntropyManager);
			vPrimaryAddr := vEntropyManager.GetPrimaryAddr;

			vResult := TEntropyResult.Create;
			vResult.Mnemonic := vMnemonic;
			vResult.EntropyStore := vPrimaryAddr.ToString;

			vJson := TJSONObject.Create;
			vJson.AddPair('mnemonic', TJSONString.Create(vResult.Mnemonic));
			vJson.AddPair('entropyStore', TJSONString.Create(vResult.EntropyStore));
			Result := SuccessResultWithData(vJson);
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vResult.Free;
	end;
end;

function DeriveByFullPath( const ParaEntropyStore, ParaFullPath, ParaExtensionWord: string ): string;
var
	vManager: IEntropyStoreManager;
	vPath: string;
	vKey: IKey;
	vAddr: TAddress;
	vPriKey: TPrivateKey;
	vResult: TDerivationResult;
	vJson: TJSONObject;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	vResult := nil;
	vJson := nil;
	try
		try
			vManager := GWalletInstance.GetEntropyStoreManager(ParaEntropyStore);
			vManager.DeriveForFullPath(ParaFullPath, vPath, vKey);
			vAddr := vKey.Address;
			vPriKey := vKey.PrivateKey;

			vResult := TDerivationResult.Create;
			vResult.Path := vPath;
			vResult.Address := vAddr.ToString;
			vResult.PrivateKey := vPriKey.Hex;

			vJson := TJSONObject.Create;
			vJson.AddPair('path', TJSONString.Create(vResult.Path));
			vJson.AddPair('address', TJSONString.Create(vResult.Address));
			vJson.AddPair('privateKey', TJSONString.Create(vResult.PrivateKey));
			Result := SuccessResultWithData(vJson);
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vResult.Free;
	end;
end;

function DeriveByIndex( const ParaEntropyStore: string; ParaIndex: Cardinal; const ParaExtensionWord: string ): string;
var
	vManager: IEntropyStoreManager;
	vPath: string;
	vKey: IKey;
	vAddr: TAddress;
	vPriKey: TPrivateKey;
	vResult: TDerivationResult;
	vJson: TJSONObject;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	vResult := nil;
	vJson := nil;
	try
		try
			vManager := GWalletInstance.GetEntropyStoreManager(ParaEntropyStore);
			vManager.DeriveForIndexPath(ParaIndex, vPath, vKey);
			vAddr := vKey.Address;
			vPriKey := vKey.PrivateKey;

			vResult := TDerivationResult.Create;
			vResult.Path := vPath;
			vResult.Address := vAddr.ToString;
			vResult.PrivateKey := vPriKey.Hex;

			vJson := TJSONObject.Create;
			vJson.AddPair('path', TJSONString.Create(vResult.Path));
			vJson.AddPair('address', TJSONString.Create(vResult.Address));
			vJson.AddPair('privateKey', TJSONString.Create(vResult.PrivateKey));
			Result := SuccessResultWithData(vJson);
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vResult.Free;
	end;
end;

function ExtractMnemonic( const ParaEntropyStore, ParaPassphrase: string ): string;
var
	vMnemonic: string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		vMnemonic := GWalletInstance.ExtractMnemonic(ParaEntropyStore, ParaPassphrase);
		Result := SuccessResultWithData(TJSONString.Create(vMnemonic));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function GetDataDir: string;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		Result := SuccessResultWithData(TJSONString.Create(GWalletInstance.GetDataDir));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function EntropyStoreToAddress( const ParaEntropyStore: string ): string;
var
	vAddrStr: string;
	vAddress: TAddress;
begin
	if GWalletInstance = nil then
	begin
		Result := FailResult(Exception.Create('wallet should be init'));
		Exit;
	end;

	try
		vAddrStr := ParaEntropyStore;
		if TPath.IsPathRooted(ParaEntropyStore) then
			vAddrStr := TPath.GetFileName(ParaEntropyStore);

		vAddress := THex.HexToAddress(vAddrStr);
		Result := SuccessResultWithData(TJSONString.Create(vAddress.ToString));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function Hash256( const ParaData: string ): string;
var
	vBytes: TBytes;
begin
	try
		vBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaData);
		vBytes := TCrypto.Hash256(vBytes);
		Result := SuccessResultWithData(TJSONString.Create(TNetEncoding.Base64.EncodeBytesToString(vBytes)));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function Hash( ParaSize: Integer; const ParaData: string ): string;
var
	vBytes: TBytes;
begin
	try
		vBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaData);
		vBytes := TCrypto.Hash(ParaSize, vBytes);
		Result := SuccessResultWithData(TJSONString.Create(TNetEncoding.Base64.EncodeBytesToString(vBytes)));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function SignData( const ParaPrivHex, ParaMessageBase64: string ): string;
var
	vPriKey: TPrivateKey;
	vMessage: TBytes;
	vSignature: TBytes;
	vResult: TSignDataResult;
	vJson: TJSONObject;
begin
	vResult := nil;
	vJson := nil;
	try
		try
			vPriKey := TEd25519.HexToPrivateKey(ParaPrivHex);
			vMessage := TNetEncoding.Base64.DecodeStringToBytes(ParaMessageBase64);
			vSignature := TEd25519.Sign(vPriKey, vMessage);

			vResult := TSignDataResult.Create;
			vResult.PublicKey := TNetEncoding.Base64.EncodeBytesToString(vPriKey.PubByte);
			vResult.Data := ParaMessageBase64;
			vResult.Signature := TNetEncoding.Base64.EncodeBytesToString(vSignature);

			vJson := TJSONObject.Create;
			vJson.AddPair('publicKey', TJSONString.Create(vResult.PublicKey));
			vJson.AddPair('data', TJSONString.Create(vResult.Data));
			vJson.AddPair('signature', TJSONString.Create(vResult.Signature));
			Result := SuccessResultWithData(vJson);
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vResult.Free;
	end;
end;

function VerifySignature( const ParaPub, ParaMessage, ParaSignData: string ): string;
var
	vPubBytes, vMessageBytes, vSignDataBytes: TBytes;
	vResultBool: Boolean;
begin
	try
		vPubBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaPub);
		vMessageBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaMessage);
		vSignDataBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaSignData);

		vResultBool := TCrypto.VerifySig(vPubBytes, vMessageBytes, vSignDataBytes);
		Result := SuccessResultWithData(TJSONBool.Create(vResultBool));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function PubkeyToAddress( const ParaPubBase64: string ): string;
var
	vPubBytes: TBytes;
	vAddress: TAddress;
begin
	try
		vPubBytes := TNetEncoding.Base64.DecodeStringToBytes(ParaPubBase64);
		vAddress := TTypes.PubkeyToAddress(vPubBytes);
		Result := SuccessResultWithData(TJSONString.Create(vAddress.ToString));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function TransformMnemonic( const ParaMnemonic, ParaLanguage, ParaExtensionWord: string ): string;
var
	vPrimaryAddress: TAddress;
begin
	try
		vPrimaryAddress := TEntropyStore.MnemonicToPrimaryAddr(ParaMnemonic);
		Result := SuccessResultWithData(TJSONString.Create(vPrimaryAddress.ToString));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function RandomMnemonic( const ParaLanguage: string; ParaMnemonicSize: Integer ): string;
var
	vMnemonic: string;
begin
	try
		vMnemonic := TEntropyStore.NewMnemonic;
		Result := SuccessResultWithData(TJSONString.Create(vMnemonic));
	except
		on E: Exception do
			Result := FailResult(E);
	end;
end;

function ComputeHashForAccountBlock( const ParaBlock: string ): string;
var
	vAccountBlock: TAccountBlock;
	vHash: THash;
	vJson: TJSONObject;
begin
	vAccountBlock := nil;
	vJson := nil;
	try
		try
			vJson := TJSONObject.ParseJSONValue(ParaBlock) as TJSONObject;
			vAccountBlock := TAccountBlock.Create;
			// This is a simplified deserialization. A real implementation would need a more robust solution.
			vAccountBlock.BlockType := TBlockType(vJson.GetValue<Integer>('BlockType'));
			vAccountBlock.Hash := THash.FromHex(vJson.GetValue<string>('Hash'));
			vAccountBlock.PrevHash := THash.FromHex(vJson.GetValue<string>('PrevHash'));
			vAccountBlock.AccountAddress := TAddress.FromHex(vJson.GetValue<string>('AccountAddress'));
			vAccountBlock.PublicKey := TNetEncoding.Base64.DecodeStringToBytes(vJson.GetValue<string>('PublicKey'));
			vAccountBlock.ToAddress := TAddress.FromHex(vJson.GetValue<string>('ToAddress'));
			vAccountBlock.TokenId := TTokenTypeId.FromHex(vJson.GetValue<string>('TokenId'));
			vAccountBlock.Data := TNetEncoding.Base64.DecodeStringToBytes(vJson.GetValue<string>('Data'));
			vAccountBlock.Nonce := TNetEncoding.Base64.DecodeStringToBytes(vJson.GetValue<string>('Nonce'));
			vAccountBlock.Signature := TNetEncoding.Base64.DecodeStringToBytes(vJson.GetValue<string>('Signature'));
			vAccountBlock.Height := vJson.GetValue<string>('Height');
			vAccountBlock.Amount := vJson.GetValue<string>('Amount');
			vAccountBlock.Difficulty := vJson.GetValue<string>('Difficulty');
			vAccountBlock.Fee := vJson.GetValue<string>('Fee');
			vAccountBlock.FromBlockHash := THash.FromHex(vJson.GetValue<string>('FromBlockHash'));

			vHash := vAccountBlock.ComputeHash;
			Result := SuccessResultWithData(TJSONString.Create(vHash.ToString));
		except
			on E: Exception do
				Result := FailResult(E);
		end;
	finally
		vAccountBlock.Free;
		vJson.Free;
	end;
end;

function Hello( const ParaName: string ): string;
begin
	Result := 'Hello ' + ParaName + ' !';
end;

procedure SetVerbose( ParaFlag: Boolean );
begin
	GVerbose := ParaFlag;
end;

end.
