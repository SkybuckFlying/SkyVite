unit Client.Rpc.DexTrade;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Types,
  Rpc,
  RpcApi.Api.Dex;

type
	IDexTradeApi = interface
		['{E5D9A0B1-3E1F-4E6F-8A69-7C2D3E4F5A6C}']
		function GetOrdersFromMarket( const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer ): TOrdersRes;
	end;

	TDexTradeApi = class(TInterfacedObject, IDexTradeApi)
	private
		mCc: TRpcClient;
	public
		constructor Create( const ParaCc: TRpcClient );
		destructor Destroy; override;
		function GetOrdersFromMarket( const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer ): TOrdersRes;
	end;

function NewDexTradeApi( const ParaCc: TRpcClient ): IDexTradeApi;

implementation

function NewDexTradeApi( const ParaCc: TRpcClient ): IDexTradeApi;
begin
	Result := TDexTradeApi.Create(ParaCc);
end;

{ TDexTradeApi }

constructor TDexTradeApi.Create( const ParaCc: TRpcClient );
begin
	inherited Create;
	mCc := ParaCc;
end;

destructor TDexTradeApi.Destroy;
begin
	inherited Destroy;
end;

function TDexTradeApi.GetOrdersFromMarket( const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer ): TOrdersRes;
begin
  Result := TOrdersRes.Create;
	mCc.Call(Result, 'dextrade_getOrdersFromMarket', ParaTradeToken, ParaQuoteToken, ParaSide, ParaBegin, ParaEnd);
end;

end.
