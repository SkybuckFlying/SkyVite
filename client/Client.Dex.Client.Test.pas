unit Client.DexClient.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDexClientTest = class(TObject)
  public
    [Test]
    procedure TestClient_NewOrderInputs;
    [Test]
    procedure TestClient_BuildRequestNewOrderBlock;
    [Test]
    procedure TestClient_BuildRequestCancelOrderBlock;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math.BigInt,
  System.Net.Encodings,
  System.JSON,
  DUnitX.Assert,
  Common.Types,
  Vm.Contracts.Abi,
  Vm.Contracts.Dex,
  Client;

function buildDexNewOrderData(const ParaParam: TParamPlaceOrder): TBytes;
var
  vAbiContract: IABIContract;
  vMethodName: string;
  vArguments: TArray<TValue>;
begin
  vAbiContract := ABIDexFund;
  vMethodName := MethodNameDexFundNewOrder;
  SetLength(vArguments, 6);
  vArguments[0] := TValue.From<TTokenTypeId>(ParaParam.TradeToken);
  vArguments[1] := TValue.From<TTokenTypeId>(ParaParam.QuoteToken);
  vArguments[2] := TValue.From<Boolean>(ParaParam.Side);
  vArguments[3] := TValue.From<TOrderType>(ParaParam.OrderType);
  vArguments[4] := TValue.From<string>(ParaParam.Price);
  vArguments[5] := TValue.From<TBigInteger>(ParaParam.Quantity);
  Result := vAbiContract.PackMethod(vMethodName, vArguments);
end;

function buildDexCancelOrderData(const ParaParam: TParamDexCancelOrder): TBytes;
var
  vAbiContract: IABIContract;
  vMethodName: string;
  vArguments: TArray<TValue>;
begin
  vAbiContract := ABIDexTrade;
  vMethodName := MethodNameDexTradeCancelOrder;
  SetLength(vArguments, 1);
  vArguments[0] := TValue.From<TBytes>(ParaParam.OrderId);
  Result := vAbiContract.PackMethod(vMethodName, vArguments);
end;

function parseDexNewOrderData(const ParaInput: TBytes; out ParaParam: TParamPlaceOrder): Boolean;
var
  vAbiContract: IABIContract;
  vMethodName: string;
begin
  Result := False;
  try
    vAbiContract := ABIDexFund;
    vMethodName := MethodNameDexFundNewOrder;
    vAbiContract.UnpackMethod(@ParaParam, vMethodName, ParaInput);
    Result := True;
  except
    on E: Exception do
      Assert.Fail('parseDexNewOrderData failed: ' + E.Message);
  end;
end;

function parseDexCancelOrderData(const ParaInput: TBytes; out ParaParam: TParamDexCancelOrder): Boolean;
var
  vAbiContract: IABIContract;
  vMethodName: string;
begin
  Result := False;
  try
    vAbiContract := ABIDexTrade;
    vMethodName := MethodNameDexTradeCancelOrder;
    vAbiContract.UnpackMethod(@ParaParam, vMethodName, ParaInput);
    Result := True;
  except
    on E: Exception do
      Assert.Fail('parseDexCancelOrderData failed: ' + E.Message);
  end;
end;

{ TDexClientTest }

procedure TDexClientTest.TestClient_NewOrderInputs;
var
  vAbiContract: IABIContract;
  vMethodName: string;
  vMethod: IMethod;
  vKey: string;
  vValue: IArgument;
  vOffChain: IOffChain;
begin
  vAbiContract := ABIDexFund;
  vMethodName := MethodNameDexFundNewOrder;

  vMethod := vAbiContract.Methods[vMethodName];
  for vKey in vMethod.Inputs.Keys do
  begin
    vValue := vMethod.Inputs[vKey];
    WriteLn(Format('%s %s %s %s', [vKey, vValue.Name, vValue.Type.ToString, vValue.Indexed.ToString]));
  end;

  for vKey in ABIDexTrade.OffChains.Keys do
  begin
    vOffChain := ABIDexTrade.OffChains[vKey];
    WriteLn(Format('%s %s', [vKey, vOffChain.ToString]));
  end;
end;

procedure TDexClientTest.TestClient_BuildRequestNewOrderBlock;
var
  vViteTokenId, vBtcTokenId: TTokenTypeId;
  vPrice: string;
  vOne, vQuantity: TBigInteger;
  vData: TBytes;
  vDataBase64: string;
  vExpected: string;
  vInput: TBytes;
  vNewOrder: TParamPlaceOrder;
  vKey: string;
  vValue: IEvent;
begin
  try
    vViteTokenId := THex.HexToTokenTypeId('tti_5649544520544f4b454e6e40');
    vBtcTokenId := THex.HexToTokenTypeId('tti_322862b3f8edae3b02b110b1');
  except
    on E: Exception do
      Assert.Fail('HexToTokenTypeId failed: ' + E.Message);
  end;

  vPrice := '0.00001899';

  vOne := TBigInteger.Create(10).Pow(18);
  vQuantity := vOne * 1000;

  vNewOrder.TradeToken := vViteTokenId;
  vNewOrder.QuoteToken := vBtcTokenId;
  vNewOrder.Side := True;
  vNewOrder.Price := vPrice;
  vNewOrder.Quantity := vQuantity;

  try
    vData := buildDexNewOrderData(vNewOrder);
  except
    on E: Exception do
      Assert.Fail('buildDexNewOrderData failed: ' + E.Message);
  end;

  vDataBase64 := TBase64Encoding.EncodeBytesToString(vData);
  WriteLn(vDataBase64);

  vExpected := 'FHkn7AAAAAAAAAAAAAAAAAAAAAAAAAAAAABWSVRFIFRPS0VOAAAAAAAAAAAAAAAAAAAAAAAAAAAAADIoYrP47a47ArEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADY1ya3F3qAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKMC4wMDAwMTg5OQAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  try
    vInput := TBase64Encoding.DecodeStringToBytes(vExpected);
  except
    on E: Exception do
      Assert.Fail('DecodeStringToBytes failed: ' + E.Message);
  end;
  Assert.AreEqual(vExpected, vDataBase64);

  Assert.IsTrue(parseDexNewOrderData(vInput, vNewOrder), 'parseDexNewOrderData failed');
  WriteLn(vNewOrder.ToString);

  for vKey in ABIDexFund.Events.Keys do
  begin
    vValue := ABIDexFund.Events[vKey];
    WriteLn(Format('%s %s', [vKey, vValue.ToString]));
  end;

  for vKey in ABIDexTrade.Events.Keys do
  begin
    vValue := ABIDexTrade.Events[vKey];
    WriteLn(Format('%s %s', [vKey, vValue.ToString]));
  end;
end;

procedure TDexClientTest.TestClient_BuildRequestCancelOrderBlock;
var
  vOrderId: string;
  vId: TBytes;
  vData: TBytes;
  vDataBase64: string;
  vExpected: string;
  vInput: TBytes;
  vCancelOrder: TParamDexCancelOrder;
begin
  vOrderId := '0000010100000000000001312d00005d2e049e000000';
  try
    vId := THex.DecodeString(vOrderId);
  except
    on E: Exception do
      Assert.Fail('DecodeString failed: ' + E.Message);
  end;

  vCancelOrder.OrderId := vId;
  try
    vData := buildDexCancelOrderData(vCancelOrder);
  except
    on E: Exception do
      Assert.Fail('buildDexCancelOrderData failed: ' + E.Message);
  end;

  vDataBase64 := TBase64Encoding.EncodeBytesToString(vData);
  WriteLn(vDataBase64);

  vExpected := 'slGtxQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABYAAAEBAAAAAAAAATEtAABdLgSeAAAAAAAAAAAAAAAAAA==';
  try
    vInput := TBase64Encoding.DecodeStringToBytes(vExpected);
  except
    on E: Exception do
      Assert.Fail('DecodeStringToBytes failed: ' + E.Message);
  end;
  Assert.AreEqual(vExpected, vDataBase64);

  Assert.IsTrue(parseDexCancelOrderData(vInput, vCancelOrder), 'parseDexCancelOrderData failed');
  WriteLn(THex.EncodeToString(vCancelOrder.OrderId));
end;

initialization
  RegisterTestFixture(TDexClientTest);
end.
