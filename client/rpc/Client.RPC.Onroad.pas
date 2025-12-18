unit Client.Rpc.Onroad;

interface

uses
  Client.RPC.Contract,
  Client.RPC.Dex.Trade,
  Client.RPC.Ledger,
  Client.RPC.Random,
  Client.RPC.Tx,
  Common.Types,
  Rpc,
  RpcApi.Api,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
	IOnroadApi = interface
		['{D4D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A6E}']
		function GetOnroadBlocksByAddress( const ParaAddress: TAddress; ParaIndex, ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetOnroadInfoByAddress( const ParaAddress: TAddress ): TRpcAccountInfo;
		function GetOnroadBlocksInBatch( const ParaQueryList: TArray<TOnroadPagingQuery> ): TDictionary<TAddress, TArray<TAccountBlock>>;
		function GetOnroadInfoInBatch( const ParaAddrList: TArray<TAddress> ): TArray<TRpcAccountInfo>;
		function GetContractOnRoadFrontBlocks( const ParaAddr: TAddress; const ParaGid: TGid ): TArray<TAccountBlock>;
	end;

	TOnroadApi = class(TInterfacedObject, IOnroadApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		function GetOnroadBlocksByAddress( const ParaAddress: TAddress; ParaIndex, ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetOnroadInfoByAddress( const ParaAddress: TAddress ): TRpcAccountInfo;
		function GetOnroadBlocksInBatch( const ParaQueryList: TArray<TOnroadPagingQuery> ): TDictionary<TAddress, TArray<TAccountBlock>>;
		function GetOnroadInfoInBatch( const ParaAddrList: TArray<TAddress> ): TArray<TRpcAccountInfo>;
		function GetContractOnRoadFrontBlocks( const ParaAddr: TAddress; const ParaGid: TGid ): TArray<TAccountBlock>;
	end;

function NewOnroadApi( const ParaCc: TRpcClient ): IOnroadApi;

implementation

function NewOnroadApi( const ParaCc: TRpcClient ): IOnroadApi;
begin
	Result := TOnroadApi.Create(ParaCc);
end;

{ TOnroadApi }

constructor TOnroadApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TOnroadApi.Destroy;
begin
	inherited Destroy;
end;

function TOnroadApi.GetOnroadBlocksByAddress( const ParaAddress: TAddress; ParaIndex, ParaCount: UInt64 ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'onroad_getOnroadBlocksByAddress', ParaAddress, ParaIndex, ParaCount);
end;

function TOnroadApi.GetOnroadInfoByAddress( const ParaAddress: TAddress ): TRpcAccountInfo;
begin
	mCc.Call(Result, 'onroad_getOnroadInfoByAddress', ParaAddress);
end;

function TOnroadApi.GetOnroadBlocksInBatch( const ParaQueryList: TArray<TOnroadPagingQuery> ): TDictionary<TAddress, TArray<TAccountBlock>>;
begin
	mCc.Call(Result, 'onroad_GetOnroadBlocksInBatch', ParaQueryList);
end;

function TOnroadApi.GetOnroadInfoInBatch( const ParaAddrList: TArray<TAddress> ): TArray<TRpcAccountInfo>;
begin
	mCc.Call(Result, 'onroad_getOnroadInfoInBatch', ParaAddrList);
end;

function TOnroadApi.GetContractOnRoadFrontBlocks( const ParaAddr: TAddress; const ParaGid: TGid ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'onroad_getContractOnRoadFrontBlocks', ParaAddr, ParaGid);
end;

end.
