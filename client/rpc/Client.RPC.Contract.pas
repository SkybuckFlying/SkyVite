unit Client.Rpc.Contract;

interface

uses
  Client.RPC.Dex.Trade,
  Client.RPC.Ledger,
  Client.RPC.Onroad,
  Client.RPC.Random,
  Client.RPC.Tx,
  Common.Types,
  Rpc,
  RpcApi.Api,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
	IContractApi = interface
		['{B4D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A6B}']
		function CallOffChainMethod( const ParaParam: TCallOffChainMethodParam ): TBytes;
		function Query( const ParaParam: TQueryParam ): TBytes;
		function GetCreateContractData( const ParaParam: TCreateContractDataParam ): TBytes;
		function GetContractStorage( const ParaAddr: TAddress; const ParaPrefix: string ): TDictionary<string, string>;
		function GetContractInfo( const ParaAddr: TAddress ): TContractInfo;
		function GetSBPVoteList: TArray<TSBPVoteInfo>;
	end;

	TContractApi = class(TInterfacedObject, IContractApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		function CallOffChainMethod( const ParaParam: TCallOffChainMethodParam ): TBytes;
		function Query( const ParaParam: TQueryParam ): TBytes;
		function GetCreateContractData( const ParaParam: TCreateContractDataParam ): TBytes;
		function GetContractStorage( const ParaAddr: TAddress; const ParaPrefix: string ): TDictionary<string, string>;
		function GetContractInfo( const ParaAddr: TAddress ): TContractInfo;
		function GetSBPVoteList: TArray<TSBPVoteInfo>;
	end;

function NewContractApi( const ParaCc: TRpcClient ): IContractApi;

implementation

function NewContractApi( const ParaCc: TRpcClient ): IContractApi;
begin
	Result := TContractApi.Create(ParaCc);
end;

{ TContractApi }

constructor TContractApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TContractApi.Destroy;
begin
	inherited Destroy;
end;

function TContractApi.CallOffChainMethod( const ParaParam: TCallOffChainMethodParam ): TBytes;
begin
	mCc.Call(Result, 'contract_callOffChainMethod', ParaParam);
end;

function TContractApi.Query( const ParaParam: TQueryParam ): TBytes;
begin
	mCc.Call(Result, 'contract_query', ParaParam);
end;

function TContractApi.GetCreateContractData( const ParaParam: TCreateContractDataParam ): TBytes;
begin
	mCc.Call(Result, 'contract_getCreateContractData', ParaParam);
end;

function TContractApi.GetContractStorage( const ParaAddr: TAddress; const ParaPrefix: string ): TDictionary<string, string>;
begin
	mCc.Call(Result, 'contract_getContractStorage', ParaAddr, ParaPrefix);
end;

function TContractApi.GetContractInfo( const ParaAddr: TAddress ): TContractInfo;
begin
	mCc.Call(Result, 'contract_getContractInfo', ParaAddr);
end;

function TContractApi.GetSBPVoteList: TArray<TSBPVoteInfo>;
begin
	mCc.Call(Result, 'contract_getSBPVoteList');
end;

end.
