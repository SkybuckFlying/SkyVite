unit Client.Rpc.Tx;

interface

uses
  System.SysUtils,
  System.Classes,
  Rpc,
  RpcApi.Api;

type
	ITxApi = interface
		['{F7D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A70}']
		procedure SendRawTx( const ParaBlock: TAccountBlock );
		function SendTxWithPrivateKey( const ParaParam: TSendTxWithPrivateKeyParam ): TAccountBlock;
		function CalcPoWDifficulty( const ParaParam: TCalcPoWDifficultyParam ): TCalcPoWDifficultyResult;
	end;

	TTxApi = class(TInterfacedObject, ITxApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		procedure SendRawTx( const ParaBlock: TAccountBlock );
		function SendTxWithPrivateKey( const ParaParam: TSendTxWithPrivateKeyParam ): TAccountBlock;
		function CalcPoWDifficulty( const ParaParam: TCalcPoWDifficultyParam ): TCalcPoWDifficultyResult;
	end;

function NewTxApi( const ParaCc: TRpcClient ): ITxApi;

implementation

function NewTxApi( const ParaCc: TRpcClient ): ITxApi;
begin
	Result := TTxApi.Create(ParaCc);
end;

{ TTxApi }

constructor TTxApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TTxApi.Destroy;
begin
	inherited Destroy;
end;

procedure TTxApi.SendRawTx( const ParaBlock: TAccountBlock );
var
	vResult: TObject;
begin
	vResult := nil;
	mCc.Call(vResult, 'tx_sendRawTx', ParaBlock);
end;

function TTxApi.SendTxWithPrivateKey( const ParaParam: TSendTxWithPrivateKeyParam ): TAccountBlock;
begin
	mCc.Call(Result, 'tx_sendTxWithPrivateKey', ParaParam);
end;

function TTxApi.CalcPoWDifficulty( const ParaParam: TCalcPoWDifficultyParam ): TCalcPoWDifficultyResult;
begin
	mCc.Call(Result, 'tx_calcPoWDifficulty', ParaParam);
end;

end.
