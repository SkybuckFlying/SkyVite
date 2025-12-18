unit Vite;

interface

uses
	System.SysUtils,
	System.Classes,
	Common.Config.Config,
	Common.Types.Address,
	Interfaces.Chain,
	Interfaces.Consensus,
	Interfaces.Verifier,
	Interfaces.Wallet,
	Ledger.Onroad.Manager,
	Ledger.Pool.Pool,
	Log15.Logger,
	Net.Interface,
	Producer.Interface,
	Wallet.Manager;

type
	TVite = class(TObject)
	private
		mConfig : TConfig;
		mWalletManager : TWalletManager;
		mVerifier : IVerifier;
		mChain : IChain;
		mProducer : IProducer;
		mNet : INet;
		mPool : IBlockPool;
		mConsensus : IConsensus;
		mOnRoad : TOnroadManager;

		class var mLog : ILogger;
	public
		constructor Create
		(
			ParaCfg : TConfig;
			ParaWalletManager : TWalletManager;
			ParaVerifier : IVerifier;
			ParaChain : IChain;
			ParaProducer : IProducer;
			ParaNet : INet;
			ParaPool : IBlockPool;
			ParaConsensus : IConsensus;
			ParaOnRoad : TOnroadManager
		);
	public
		class constructor Create;
		destructor Destroy; override;

		class function New( ParaCfg : TConfig; ParaWalletManager : TWalletManager ) : TVite;

		function Init : Boolean;
		function Start : Boolean;
		function Stop : Boolean;

		function GetChain : IChain;
		function GetNet : INet;
		function GetWalletManager : TWalletManager;
		function GetProducer : IProducer;
		function GetPool : IBlockPool;
		function GetConsensus : IConsensus;
		function GetOnRoad : TOnroadManager;
		function GetConfig : TConfig;
		function GetVerifier : IVerifier;

		property Chain : IChain read GetChain;
		property Net : INet read GetNet;
		property WalletManager : TWalletManager read GetWalletManager;
		property Producer : IProducer read GetProducer;
		property Pool : IBlockPool read GetPool;
		property Consensus : IConsensus read GetConsensus;
		property OnRoad : TOnroadManager read GetOnRoad;
		property Config : TConfig read GetConfig;
		property Verifier : IVerifier read GetVerifier;
	end;

function ParseCoinbase( ParaCoinbaseCfg : string; out ParaAddress : TAddress; out ParaIndex : UInt32 ) : Boolean;

implementation

uses
	Common.Upgrade.Upgrade.Init,
	Ledger.Chain.Chain,
	Ledger.Consensus.Consensus,
	Ledger.Verifier.Verifier,
	Net.Net,
	Producer.Producer,
	VM.VM,
	Wallet.Account;

{ TVite }

class constructor TVite.Create;
begin
	mLog := TLogger.New('module', 'console/bridge');
end;

constructor TVite.Create
(
	ParaCfg : TConfig;
	ParaWalletManager : TWalletManager;
	ParaVerifier : IVerifier;
	ParaChain : IChain;
	ParaProducer : IProducer;
	ParaNet : INet;
	ParaPool : IBlockPool;
	ParaConsensus : IConsensus;
	ParaOnRoad : TOnroadManager
);
begin
	inherited Create;
	mConfig := ParaCfg;
	mWalletManager := ParaWalletManager;
	mVerifier := ParaVerifier;
	mChain := ParaChain;
	mProducer := ParaProducer;
	mNet := ParaNet;
	mPool := ParaPool;
	mConsensus := ParaConsensus;
	mOnRoad := ParaOnRoad;
end;

destructor TVite.Destroy;
begin
	inherited Destroy;
end;

class function TVite.New( ParaCfg : TConfig; ParaWalletManager : TWalletManager ) : TVite;
var
	vAccount : TAccount;
	vChain : IChain;
	vPool : IBlockPool;
	vConsensus : IConsensus;
	vVerifier : IVerifier;
	vNet : INet;
	vProducer : IProducer;
	vOnRoad : TOnroadManager;
begin
	Result := nil;
	vAccount := nil;
	vProducer := nil;

	try
		// set upgrade
		TUpgradeBox.InitUpgradeBox( ParaCfg.UpgradeCfg.MakeUpgradeBox );

		if ParaCfg.Producer.IsMine then
		begin
			vAccount := ParaWalletManager.AccountAtIndex( ParaCfg.EntropyStorePath, ParaCfg.Producer.GetCoinbase, ParaCfg.Producer.GetIndex );
			if vAccount = nil then
			begin
				mLog.Error( Format( 'coinBase is not child of entropyStore, coinBase is : %v', [ParaCfg.Producer.Coinbase] ), 'err', 'Account not found' );
				Exit;
			end;

			ParaCfg.Net.MineKey := vAccount.PrivateKey;
		end;

		// chain
		vChain := TChain.NewChain( ParaCfg.DataDir, ParaCfg.Chain, ParaCfg.Genesis );
		vChain.Init;

		// pool
		vPool := TPool.NewPool( vChain );

		// consensus
		vConsensus := TConsensus.NewConsensus( vChain, vPool );

		vVerifier := TVerifier.NewVerifier( vChain );

		// net
		vNet := TNet.New( ParaCfg.Net, vChain, vVerifier, vConsensus, vPool );

		if vAccount <> nil then
		begin
			vProducer := TProducer.NewProducer( vChain, vNet, vAccount, vConsensus, vPool );
		end;

		// set onroad
		vOnRoad := TOnroadManager.NewManager( vNet, vPool, vProducer, vConsensus.SBPReader, vAccount );

		Result := TVite.Create
		(
			ParaCfg,
			ParaWalletManager,
			vVerifier,
			vChain,
			vProducer,
			vNet,
			vPool,
			vConsensus,
			vOnRoad
		);
	except
		on E: Exception do
		begin
			mLog.Error( 'Vite creation failed', 'err', E.Message );
			Result := nil;
		end;
	end;
end;

function TVite.Init : Boolean;
begin
	Result := True;
	try
		TVM.InitVMConfig( mConfig.IsVmTest, mConfig.IsUseVmTestParam, mConfig.IsUseQuotaTestParam, mConfig.IsVmDebug, mConfig.DataDir );

		if mProducer <> nil then
		begin
			if not mProducer.Init then
			begin
				mLog.Error( 'Init producer failed', 'method', 'vite.Init' );
				Result := False;
				Exit;
			end;
		end;

		// initOnRoadPool
		mOnRoad.Init( mChain );
		if mConfig.Producer.VirtualSnapshotVerifier then
		begin
			mVerifier.Init( TConsensus.NewVirtualVerifier, mConsensus.SBPReader, mOnRoad );
		end else
		begin
			mVerifier.Init( mConsensus, mConsensus.SBPReader, mOnRoad );
		end;
	except
		on E: Exception do
		begin
			mLog.Error( 'Vite Init failed', 'err', E.Message );
			Result := False;
		end;
	end;
end;

function TVite.Start : Boolean;
begin
	Result := True;
	try
		mOnRoad.Start;
		mChain.Start;

		if not mConsensus.Init( TConsensus.Cfg ) then
		begin
			Result := False;
			Exit;
		end;

		mChain.SetConsensus( mConsensus, mConsensus.SBPReader.GetPeriodTimeIndex );
		mPool.Init( mNet, mVerifier, mConsensus.SBPReader );

		mConsensus.Start;

		if not mNet.Start then
		begin
			Result := False;
			Exit;
		end;

		mPool.Start;
		if mProducer <> nil then
		begin
			if not mProducer.Start then
			begin
				mLog.Error( 'producer.Start failed', 'method', 'vite.Start' );
				Result := False;
				Exit;
			end;
		end;
	except
		on E: Exception do
		begin
			mLog.Error( 'Vite Start failed', 'err', E.Message );
			Result := False;
		end;
	end;
end;

function TVite.Stop : Boolean;
begin
	Result := True;
	try
		mNet.Stop;
		mPool.Stop;

		if mProducer <> nil then
		begin
			if not mProducer.Stop then
			begin
				mLog.Error( 'producer.Stop failed', 'method', 'vite.Stop' );
				Result := False;
				Exit;
			end;
		end;
		mConsensus.Stop;
		mChain.Stop;
		mOnRoad.Stop;
	except
		on E: Exception do
		begin
			mLog.Error( 'Vite Stop failed', 'err', E.Message );
			Result := False;
		end;
	end;
end;

function TVite.GetChain : IChain;
begin
	Result := mChain;
end;

function TVite.GetNet : INet;
begin
	Result := mNet;
end;

function TVite.GetWalletManager : TWalletManager;
begin
	Result := mWalletManager;
end;

function TVite.GetProducer : IProducer;
begin
	Result := mProducer;
end;

function TVite.GetPool : IBlockPool;
begin
	Result := mPool;
end;

function TVite.GetConsensus : IConsensus;
begin
	Result := mConsensus;
end;

function TVite.GetOnRoad : TOnroadManager;
begin
	Result := mOnRoad;
end;

function TVite.GetConfig : TConfig;
begin
	Result := mConfig;
end;

function TVite.GetVerifier : IVerifier;
begin
	Result := mVerifier;
end;

function ParseCoinbase( ParaCoinbaseCfg : string; out ParaAddress : TAddress; out ParaIndex : UInt32 ) : Boolean;
var
	vSplits : TArray<string>;
	vInt : Integer;
begin
	Result := False;
	vSplits := ParaCoinbaseCfg.Split([':']);
	if Length( vSplits ) <> 2 then
	begin
		Exit;
	end;

	if not TryStrToInt( vSplits[0], vInt ) then
	begin
		Exit;
	end;

	ParaIndex := UInt32( vInt );
	ParaAddress := TAddress.HexToAddress( vSplits[1] );
	Result := True;
end;

end.
