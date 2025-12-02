unit Client.Dex.Client;

interface

uses
  System.SysUtils,
  System.Math.BigInts,
  Common.Types,
  Interfaces.Core,
  RpcApi.Api,
  VM.Contracts.ABI,
  VM.Contracts.Dex;

type
  IDexClient = interface
    ['{B8A2B68E-4B7E-4B1B-8F0E-0B2D2F2E2C2A}']
    function BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
    function BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
  end;

  TRequestTxParams = record
    SelfAddr: TAddress;
    ToAddr: TAddress;
    TokenId: TTokenId;
    Amount: TBigInteger;
    Data: TBytes;
  end;

  TClient = class // Partial definition, assuming it's defined elsewhere
  public
    function BuildNormalRequestBlock(const ParaParams: TRequestTxParams; const ParaPrev: THashHeight): TAccountBlock; virtual; abstract;
    function BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
    function BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
  end;

implementation

uses
  System.Rtti;

function buildDexNewOrderData(const ParaParam: TParamPlaceOrder): TBytes;
var
  vABIContract: TABIContract;
  vArguments: TArray<TValue>;
begin
  vABIContract := TABIDexFund;
  SetLength(vArguments, 6);
  vArguments[0] := TValue.From<TTokenId>(ParaParam.TradeToken);
  vArguments[1] := TValue.From<TTokenId>(ParaParam.QuoteToken);
  vArguments[2] := TValue.From<Byte>(ParaParam.Side);
  vArguments[3] := TValue.From<Byte>(ParaParam.OrderType);
  vArguments[4] := TValue.From<TBigInteger>(ParaParam.Price);
  vArguments[5] := TValue.From<TBigInteger>(ParaParam.Quantity);
  Result := vABIContract.PackMethod(ConstMethodNameDexFundNewOrder, vArguments);
end;

function buildDexCancelOrderData(const ParaParam: TParamDexCancelOrder): TBytes;
var
  vABIContract: TABIContract;
  vArguments: TArray<TValue>;
begin
  vABIContract := TABIDexTrade;
  SetLength(vArguments, 1);
  vArguments[0] := TValue.From<TBytes>(ParaParam.OrderId);
  Result := vABIContract.PackMethod(ConstMethodNameDexTradeCancelOrder, vArguments);
end;

function parseDexNewOrderData(const ParaInput: TBytes): TParamPlaceOrder;
var
  vABIContract: TABIContract;
begin
  vABIContract := TABIDexFund;
  Result := TParamPlaceOrder.Create;
  try
    vABIContract.UnpackMethod(Result, ConstMethodNameDexFundNewOrder, ParaInput);
  except
    on E: Exception do
    begin
      Result.Free;
      raise;
    end;
  end;
end;

function parseDexCancelOrderData(const ParaInput: TBytes): TParamDexCancelOrder;
var
  vABIContract: TABIContract;
begin
  vABIContract := TABIDexTrade;
  Result := TParamDexCancelOrder.Create;
  try
    vABIContract.UnpackMethod(Result, ConstMethodNameDexTradeCancelOrder, ParaInput);
  except
    on E: Exception do
    begin
      Result.Free;
      raise;
    end;
  end;
end;

{ TClient }

function TClient.BuildRequestNewOrderBlock(const ParaParam: TParamPlaceOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
var
  vData: TBytes;
  vParams: TRequestTxParams;
begin
  vData := buildDexNewOrderData(ParaParam);
  vParams.SelfAddr := ParaSelfAddr;
  vParams.Data := vData;
  vParams.ToAddr := ConstAddressDexFund;
  vParams.Amount := TBigInteger.Zero;
  vParams.TokenId := ConstViteTokenId;
  Result := BuildNormalRequestBlock(vParams, ParaPrev);
end;

function TClient.BuildRequestCancelOrderBlock(const ParaParam: TParamDexCancelOrder; const ParaSelfAddr: TAddress; const ParaPrev: THashHeight): TAccountBlock;
var
  vData: TBytes;
  vParams: TRequestTxParams;
begin
  vData := buildDexCancelOrderData(ParaParam);
  vParams.SelfAddr := ParaSelfAddr;
  vParams.Data := vData;
  vParams.ToAddr := ConstAddressDexTrade;
  vParams.Amount := TBigInteger.Zero;
  vParams.TokenId := ConstViteTokenId;
  Result := BuildNormalRequestBlock(vParams, ParaPrev);
end;

end.
