unit Client.Rpc;

interface

uses
  Client.ABI.Client,
  Client.ABI.Client.Test,
  Client.Client,
  Client.Client.Test,
  Client.Dex.Client,
  Client.Dex.Client.Test,
  Client.Rpc.Contract,
  Client.Rpc.DexTrade,
  Client.Rpc.Ledger,
  Client.Rpc.Onroad,
  Client.Rpc.Random,
  Client.RPC.Test,
  Client.Rpc.Tx,
  Client.SBP.Upgrade.Test,
  Rpc,
  System.Classes,
  System.SysUtils;

type
	ERpcClientError = class(Exception);

	IRpcClient = interface(ILedgerApi, IOnroadApi, ITxApi, IContractApi, IDexTradeApi, IRandomApi)
		['{C5D8E1A9-2B3C-4F5A-8E1A-9B3C2D8E1A9B}']
		function GetClient: TRpcClient;
	end;

function NewRpcClient( const ParaRawUrl: string ) : IRpcClient;

implementation

uses
	Common.Types,
	RpcApi.Api;

type
	TRpcClientImpl = class(TInterfacedObject, IRpcClient)
	private
		mLedgerApi: ILedgerApi;
		mOnroadApi: IOnroadApi;
		mTxApi: ITxApi;
		mContractApi: IContractApi;
		mDexTradeApi: IDexTradeApi;
		mRandomApi: IRandomApi;
		mClient: TRpcClient;
	public
		constructor Create( const ParaClient: TRpcClient );
		destructor Destroy; override;
		function GetClient: TRpcClient;

		{ ILedgerApi }
		function GetSnapshotChainHeight: TUint64;
		function GetBlockByHash(const ParaHash: THash): IAccountBlock;
		function GetLatestBlock(const ParaAddr: TAddress): IAccountBlock;
		function GetAccountByAccAddr(const ParaAddr: TAddress): IRpcAccountInfo;
		function GetTransactionByHash(const ParaHash: THash): IAccountBlock;
		function GetSnapshotBlockByHash(const ParaHash: THash): ISnapshotBlock;
		function GetConfirmedBalances(const ParaSnapshotHash: THash; const ParaAddrList: TArray<TAddress>; const ParaTokenIdList: TArray<TTokenTypeId>): TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>;
		function GetRewardByIndex(const ParaIndex: Integer): TObject;
		function GetVoteDetailsByIndex(const ParaIndex: Integer): TObject;
		function GetHourSBPStats(const ParaHour: Integer; const ParaIndex: Integer): TObject;

		{ IOnroadApi }
		function GetOnroadBlocksByAddress(const ParaAddr: TAddress; const ParaIndex: Integer; const ParaCount: Integer): TArray<IAccountBlock>;
		function GetOnroadInfoByAddress(const ParaAddr: TAddress): IRpcAccountInfo;

		{ ITxApi }
		function SendRawTx(const ParaBlock: IAccountBlock): TBytes;
		function CalcPoWDifficulty(const ParaParam: TCalcPoWDifficultyParam): TBytes;

		{ IContractApi }
		function CallOffChainMethod(const ParaParam: TCallOffChainMethodParam): TBytes;
		function GetCreateContractData(const ParaParam: TCreateContractDataParam): TBytes;

		{ IDexTradeApi }
		function GetOrdersFromMarket(const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer): TObject;

		{ IRandomApi }
		function GetRewardByIndex(const ParaIndex: TUint64): TObject;
		function GetVoteDetailsByIndex(const ParaIndex: TUint64): TArray<TObject>;
		function RawCall(const ParaMethod: string; const ParaParams: array of const): TObject;
	end;

function NewRpcClient( const ParaRawUrl: string ) : IRpcClient;
var
	vClient: TRpcClient;
begin
	try
		vClient := Rpc.Dial(ParaRawUrl);
		Result := TRpcClientImpl.Create(vClient);
	except
		on E: Exception do
		begin
			raise ERpcClientError.Create('Failed to create RPC client: ' + E.Message);
		end;
	end;
end;

{ TRpcClientImpl }

constructor TRpcClientImpl.Create( const ParaClient: TRpcClient );
begin
	inherited Create;
	mClient := ParaClient;
	mLedgerApi := NewLedgerApi(mClient);
	mOnroadApi := NewOnroadApi(mClient);
	mTxApi := NewTxApi(mClient);
	mContractApi := NewContractApi(mClient);
	mDexTradeApi := NewDexTradeApi(mClient);
	mRandomApi := NewRandomApi(mClient);
end;

destructor TRpcClientImpl.Destroy;
begin
	inherited Destroy;
end;

function TRpcClientImpl.GetClient: TRpcClient;
begin
	Result := mClient;
end;

{ ILedgerApi }
function TRpcClientImpl.GetSnapshotChainHeight: TUint64;
begin
	Result := mLedgerApi.GetSnapshotChainHeight();
end;

function TRpcClientImpl.GetBlockByHash(const ParaHash: THash): IAccountBlock;
begin
	Result := mLedgerApi.GetBlockByHash(ParaHash);
end;

function TRpcClientImpl.GetLatestBlock(const ParaAddr: TAddress): IAccountBlock;
begin
	Result := mLedgerApi.GetLatestBlock(ParaAddr);
end;

function TRpcClientImpl.GetAccountByAccAddr(const ParaAddr: TAddress): IRpcAccountInfo;
begin
	Result := mLedgerApi.GetAccountByAccAddr(ParaAddr);
end;

function TRpcClientImpl.GetTransactionByHash(const ParaHash: THash): IAccountBlock;
begin
	Result := mLedgerApi.GetTransactionByHash(ParaHash);
end;

function TRpcClientImpl.GetSnapshotBlockByHash(const ParaHash: THash): ISnapshotBlock;
begin
	Result := mLedgerApi.GetSnapshotBlockByHash(ParaHash);
end;

function TRpcClientImpl.GetConfirmedBalances(const ParaSnapshotHash: THash; const ParaAddrList: TArray<TAddress>; const ParaTokenIdList: TArray<TTokenTypeId>): TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>;
begin
	Result := mLedgerApi.GetConfirmedBalances(ParaSnapshotHash, ParaAddrList, ParaTokenIdList);
end;

function TRpcClientImpl.GetRewardByIndex(const ParaIndex: Integer): TObject;
begin
	Result := mLedgerApi.GetRewardByIndex(ParaIndex);
end;

function TRpcClientImpl.GetVoteDetailsByIndex(const ParaIndex: Integer): TObject;
begin
	Result := mLedgerApi.GetVoteDetailsByIndex(ParaIndex);
end;

function TRpcClientImpl.GetHourSBPStats(const ParaHour: Integer; const ParaIndex: Integer): TObject;
begin
	Result := mLedgerApi.GetHourSBPStats(ParaHour, ParaIndex);
end;

{ IOnroadApi }
function TRpcClientImpl.GetOnroadBlocksByAddress(const ParaAddr: TAddress; const ParaIndex: Integer; const ParaCount: Integer): TArray<IAccountBlock>;
begin
	Result := mOnroadApi.GetOnroadBlocksByAddress(ParaAddr, ParaIndex, ParaCount);
end;

function TRpcClientImpl.GetOnroadInfoByAddress(const ParaAddr: TAddress): IRpcAccountInfo;
begin
	Result := mOnroadApi.GetOnroadInfoByAddress(ParaAddr);
end;

{ ITxApi }
function TRpcClientImpl.SendRawTx(const ParaBlock: IAccountBlock): TBytes;
begin
	Result := mTxApi.SendRawTx(ParaBlock);
end;

function TRpcClientImpl.CalcPoWDifficulty(const ParaParam: TCalcPoWDifficultyParam): TBytes;
begin
	Result := mTxApi.CalcPoWDifficulty(ParaParam);
end;

{ IContractApi }
function TRpcClientImpl.CallOffChainMethod(const ParaParam: TCallOffChainMethodParam): TBytes;
begin
	Result := mContractApi.CallOffChainMethod(ParaParam);
end;

function TRpcClientImpl.GetCreateContractData(const ParaParam: TCreateContractDataParam): TBytes;
begin
	Result := mContractApi.GetCreateContractData(ParaParam);
end;

{ IDexTradeApi }
function TRpcClientImpl.GetOrdersFromMarket(const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer): TObject;
begin
  Result := mDexTradeApi.GetOrdersFromMarket(ParaTradeToken, ParaQuoteToken, ParaSide, ParaBegin, ParaEnd);
end;

{ IRandomApi }
function TRpcClientImpl.GetRewardByIndex(const ParaIndex: TUint64): TObject;
begin
  Result := mRandomApi.GetRewardByIndex(ParaIndex);
end;

function TRpcClientImpl.GetVoteDetailsByIndex(const ParaIndex: TUint64): TArray<TObject>;
begin
  Result := mRandomApi.GetVoteDetailsByIndex(ParaIndex);
end;

function TRpcClientImpl.RawCall(const ParaMethod: string; const ParaParams: array of const): TObject;
begin
  Result := mRandomApi.RawCall(ParaMethod, ParaParams);
end;

end.
