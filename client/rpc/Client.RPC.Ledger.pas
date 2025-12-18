unit Client.Rpc.Ledger;

interface

uses
  Client.RPC.Contract,
  Client.RPC.Dex.Trade,
  Client.RPC.Onroad,
  Client.RPC.Random,
  Client.RPC.Tx,
  Common.Types,
  Interfaces.Core,
  Rpc,
  RpcApi.Api,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils;

type
	ILedgerApi = interface
		['{C3D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A6D}']
		function GetRawBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetCompleteBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetBlocksByHash( const ParaAddr: TAddress; const ParaOriginBlockHash: THash; ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetVmLogListByHash( const ParaLogHash: THash ): TVmLogList;
		function GetBlocksByHeight( const ParaAddr: TAddress; const ParaHeight: TValue; ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetBlockByHeight( const ParaAddr: TAddress; const ParaHeight: TValue ): TAccountBlock;
		function GetBlocksByAccAddr( const ParaAddr: TAddress; ParaIndex, ParaCount: Integer ): TArray<TAccountBlock>;
		function GetAccountByAccAddr( const ParaAddr: TAddress ): TRpcAccountInfo;
		function GetSnapshotBlockByHash( const ParaHash: THash ): TSnapshotBlock;
		function GetSnapshotBlockByHeight( const ParaHeight: TValue ): TSnapshotBlock;
		function GetSnapshotBlocks( const ParaHeight: TValue; ParaCount: Integer ): TArray<TSnapshotBlock>;
		function GetChunks( const ParaStartHeight, ParaEndHeight: TValue ): TArray<TSnapshotChunk>;
		function GetSnapshotChainHeight: string;
		function GetLatestSnapshotChainHash: THash;
		function GetLatestBlock( const ParaAddr: TAddress ): TAccountBlock;
		function GetVmLogList( const ParaBlockHash: THash ): TVmLogList;
		function GetUnconfirmedBlocks( const ParaAddr: TAddress ): TArray<TAccountBlock>;
		function GetConfirmedBalances( const ParaSnapshotHash: THash; const ParaAddrList: TArray<TAddress>; const ParaTokenIds: TArray<TTokenTypeId> ): TGetBalancesRes;
		function GetHourSBPStats( ParaStartIdx, ParaEndIdx: UInt64 ): TArray<TJSONObject>;
	end;

	TLedgerApi = class(TInterfacedObject, ILedgerApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		function GetRawBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetCompleteBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
		function GetBlocksByHash( const ParaAddr: TAddress; const ParaOriginBlockHash: THash; ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetVmLogListByHash( const ParaLogHash: THash ): TVmLogList;
		function GetBlocksByHeight( const ParaAddr: TAddress; const ParaHeight: TValue; ParaCount: UInt64 ): TArray<TAccountBlock>;
		function GetBlockByHeight( const ParaAddr: TAddress; const ParaHeight: TValue ): TAccountBlock;
		function GetBlocksByAccAddr( const ParaAddr: TAddress; ParaIndex, ParaCount: Integer ): TArray<TAccountBlock>;
		function GetAccountByAccAddr( const ParaAddr: TAddress ): TRpcAccountInfo;
		function GetSnapshotBlockByHash( const ParaHash: THash ): TSnapshotBlock;
		function GetSnapshotBlockByHeight( const ParaHeight: TValue ): TSnapshotBlock;
		function GetSnapshotBlocks( const ParaHeight: TValue; ParaCount: Integer ): TArray<TSnapshotBlock>;
		function GetChunks( const ParaStartHeight, ParaEndHeight: TValue ): TArray<TSnapshotChunk>;
		function GetSnapshotChainHeight: string;
		function GetLatestSnapshotChainHash: THash;
		function GetLatestBlock( const ParaAddr: TAddress ): TAccountBlock;
		function GetVmLogList( const ParaBlockHash: THash ): TVmLogList;
		function GetUnconfirmedBlocks( const ParaAddr: TAddress ): TArray<TAccountBlock>;
		function GetConfirmedBalances( const ParaSnapshotHash: THash; const ParaAddrList: TArray<TAddress>; const ParaTokenIds: TArray<TTokenTypeId> ): TGetBalancesRes;
		function GetHourSBPStats( ParaStartIdx, ParaEndIdx: UInt64 ): TArray<TJSONObject>;
	end;

function NewLedgerApi( const ParaCc: TRpcClient ): ILedgerApi;

implementation

function NewLedgerApi( const ParaCc: TRpcClient ): ILedgerApi;
begin
	Result := TLedgerApi.Create(ParaCc);
end;

{ TLedgerApi }

constructor TLedgerApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TLedgerApi.Destroy;
begin
	inherited Destroy;
end;

function TLedgerApi.GetRawBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
begin
	mCc.Call(Result, 'ledger_getRawBlockByHash', ParaBlockHash);
end;

function TLedgerApi.GetBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
begin
	mCc.Call(Result, 'ledger_getBlockByHash', ParaBlockHash);
end;

function TLedgerApi.GetCompleteBlockByHash( const ParaBlockHash: THash ): TAccountBlock;
begin
	mCc.Call(Result, 'ledger_getCompleteBlockByHash', ParaBlockHash);
end;

function TLedgerApi.GetBlocksByHash( const ParaAddr: TAddress; const ParaOriginBlockHash: THash; ParaCount: UInt64 ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'ledger_getBlocksByHash', ParaAddr, ParaOriginBlockHash, ParaCount);
end;

function TLedgerApi.GetVmLogListByHash( const ParaLogHash: THash ): TVmLogList;
begin
	mCc.Call(Result, 'ledger_getVmLogListByHash', ParaLogHash);
end;

function TLedgerApi.GetBlocksByHeight( const ParaAddr: TAddress; const ParaHeight: TValue; ParaCount: UInt64 ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'ledger_getBlocksByHeight', ParaAddr, ParaHeight, ParaCount);
end;

function TLedgerApi.GetBlockByHeight( const ParaAddr: TAddress; const ParaHeight: TValue ): TAccountBlock;
begin
	mCc.Call(Result, 'ledger_getBlockByHeight', ParaAddr, ParaHeight);
end;

function TLedgerApi.GetBlocksByAccAddr( const ParaAddr: TAddress; ParaIndex, ParaCount: Integer ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'ledger_getBlocksByAccAddr', ParaAddr, ParaIndex, ParaCount);
end;

function TLedgerApi.GetAccountByAccAddr( const ParaAddr: TAddress ): TRpcAccountInfo;
begin
	mCc.Call(Result, 'ledger_getAccountByAccAddr', ParaAddr);
end;

function TLedgerApi.GetSnapshotBlockByHash( const ParaHash: THash ): TSnapshotBlock;
begin
	mCc.Call(Result, 'ledger_getSnapshotBlockByHash', ParaHash);
end;

function TLedgerApi.GetSnapshotBlockByHeight( const ParaHeight: TValue ): TSnapshotBlock;
begin
	mCc.Call(Result, 'ledger_getSnapshotBlockByHeight', ParaHeight);
end;

function TLedgerApi.GetSnapshotBlocks( const ParaHeight: TValue; ParaCount: Integer ): TArray<TSnapshotBlock>;
begin
	mCc.Call(Result, 'ledger_getSnapshotBlocks', ParaHeight, ParaCount);
end;

function TLedgerApi.GetChunks( const ParaStartHeight, ParaEndHeight: TValue ): TArray<TSnapshotChunk>;
begin
	mCc.Call(Result, 'ledger_getChunks', ParaStartHeight, ParaEndHeight);
end;

function TLedgerApi.GetSnapshotChainHeight: string;
begin
	mCc.Call(Result, 'ledger_getSnapshotChainHeight');
end;

function TLedgerApi.GetLatestSnapshotChainHash: THash;
begin
	mCc.Call(Result, 'ledger_getLatestSnapshotChainHash');
end;

function TLedgerApi.GetLatestBlock( const ParaAddr: TAddress ): TAccountBlock;
begin
	mCc.Call(Result, 'ledger_getLatestBlock', ParaAddr);
end;

function TLedgerApi.GetVmLogList( const ParaBlockHash: THash ): TVmLogList;
begin
	mCc.Call(Result, 'ledger_getVmLogList', ParaBlockHash);
end;

function TLedgerApi.GetUnconfirmedBlocks( const ParaAddr: TAddress ): TArray<TAccountBlock>;
begin
	mCc.Call(Result, 'ledger_getUnconfirmedBlocks', ParaAddr);
end;

function TLedgerApi.GetConfirmedBalances( const ParaSnapshotHash: THash; const ParaAddrList: TArray<TAddress>; const ParaTokenIds: TArray<TTokenTypeId> ): TGetBalancesRes;
begin
	mCc.Call(Result, 'ledger_getConfirmedBalances', ParaSnapshotHash, ParaAddrList, ParaTokenIds);
end;

function TLedgerApi.GetHourSBPStats( ParaStartIdx, ParaEndIdx: UInt64 ): TArray<TJSONObject>;
begin
	mCc.Call(Result, 'sbpstats_getHourSBPStats', ParaStartIdx, ParaEndIdx);
end;

end.
