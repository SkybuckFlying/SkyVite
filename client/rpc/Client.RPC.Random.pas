unit Client.Rpc.Random;

interface

uses
  Client.RPC.Contract,
  Client.RPC.Dex.Trade,
  Client.RPC.Ledger,
  Client.RPC.Onroad,
  Client.RPC.Tx,
  Common.Types,
  Ledger.Consensus,
  Rpc,
  RpcApi.Api,
  System.Classes,
  System.JSON,
  System.SysUtils;

type
	IRandomApi = interface
		['{E6D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A6F}']
		function GetRewardByIndex( const ParaIndex: UInt64 ): TRewardInfo;
		function GetVoteDetailsByIndex( const ParaIndex: UInt64 ): TArray<TVoteDetails>;
		function RawCall( const ParaMethod: string; const ParaParams: array of const ): TJSONValue;
	end;

	TRandomApi = class(TInterfacedObject, IRandomApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		function GetRewardByIndex( const ParaIndex: UInt64 ): TRewardInfo;
		function GetVoteDetailsByIndex( const ParaIndex: UInt64 ): TArray<TVoteDetails>;
		function RawCall( const ParaMethod: string; const ParaParams: array of const ): TJSONValue;
	end;

function NewRandomApi( const ParaCc: TRpcClient ): IRandomApi;

implementation

function NewRandomApi( const ParaCc: TRpcClient ): IRandomApi;
begin
	Result := TRandomApi.Create(ParaCc);
end;

{ TRandomApi }

constructor TRandomApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TRandomApi.Destroy;
begin
	inherited Destroy;
end;

function TRandomApi.GetRewardByIndex( const ParaIndex: UInt64 ): TRewardInfo;
begin
	mCc.Call(Result, 'register_getRewardByIndex', TTypes.SNAPSHOT_GID, IntToStr(ParaIndex));
end;

function TRandomApi.GetVoteDetailsByIndex( const ParaIndex: UInt64 ): TArray<TVoteDetails>;
begin
	mCc.Call(Result, 'vote_getVoteDetails', ParaIndex);
end;

function TRandomApi.RawCall( const ParaMethod: string; const ParaParams: array of const ): TJSONValue;
begin
	mCc.Call(Result, ParaMethod, ParaParams);
end;

end.
