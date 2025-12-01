unit Client.AbiClient;

interface

uses
	System.SysUtils,
	System.Classes,
	Common.Types,
	Client.Rpc,
	Vm.Abi,
	RpcApi.Api;

type
	IAbiClient = interface
		['{7229348A-E331-4A2D-9D3A-3A7C4E6B1F2C}']
		function CallOffChain( const ParaMethodName : string; const ParaParams : array of const ) : TArray<TObject>;
	end;

	TAbiCli = class(TInterfacedObject, IAbiClient)
	private
		mCli: IRpcClient;
		mContractAbi: IABIContract;
		mOffchainCode: string;
		mContractAddr: TAddress;
	public
		constructor Create( const ParaCli : IRpcClient; const ParaContractAbi : IABIContract; const ParaOffchainCode : string; const ParaAddr : TAddress );
		destructor Destroy; override;
		function CallOffChain( const ParaMethodName : string; const ParaParams : array of const ) : TArray<TObject>;
	end;

function GetAbiCli( const ParaCli : IRpcClient; const ParaAbiCode : string; const ParaOffchainCode : string; const ParaAddr : TAddress ) : IAbiClient;

implementation

uses
	System.JSON,
	System.IOUtils;

function GetAbiCli( const ParaCli : IRpcClient; const ParaAbiCode : string; const ParaOffchainCode : string; const ParaAddr : TAddress ) : IAbiClient;
var
	vContractAbi: IABIContract;
	vStringReader: TStringReader;
begin
	vStringReader := nil;
	try
		try
			vStringReader := TStringReader.Create(ParaAbiCode);
			vContractAbi := TAbiContract.JSONToABIContract(vStringReader);
			Result := TAbiCli.Create(ParaCli, vContractAbi, ParaOffchainCode, ParaAddr);
		except
			on E: Exception do
			begin
				// Handle exception
				Result := nil;
			end;
		end;
	finally
		vStringReader.Free;
	end;
end;

{ TAbiCli }

constructor TAbiCli.Create( const ParaCli : IRpcClient; const ParaContractAbi : IABIContract; const ParaOffchainCode : string; const ParaAddr : TAddress );
begin
	inherited Create;
	mCli := ParaCli;
	mContractAbi := ParaContractAbi;
	mOffchainCode := ParaOffchainCode;
	mContractAddr := ParaAddr;
end;

destructor TAbiCli.Destroy;
begin
	inherited Destroy;
end;

function TAbiCli.CallOffChain( const ParaMethodName : string; const ParaParams : array of const ) : TArray<TObject>;
var
	vData: TBytes;
	vRpcParam: TCallOffChainMethodParam;
	vOutputs: TBytes;
	vResult: TArray<TObject>;
begin
	try
		vData := mContractAbi.PackOffChain(ParaMethodName, ParaParams);
		vRpcParam.SelfAddr := mContractAddr;
		vRpcParam.OffChainCode := mOffchainCode;
		vRpcParam.Data := vData;
		vOutputs := mCli.CallOffChainMethod(vRpcParam);
		vResult := mContractAbi.DirectUnpackOffchainOutput(ParaMethodName, vOutputs);
		Result := vResult;
	except
		on E: Exception do
		begin
			// Handle exception
			Result := nil;
		end;
	end;
end;

end.
