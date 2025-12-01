unit Client.Client.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TClientTest = class(TObject)
  public
    [Test]
    procedure TestWallet;
    [Test]
    procedure TestClient_SubmitRequestTx;
    [Test]
    procedure TestClient_CreateContract;
    [Test]
    procedure TestClient_SubmitResponseTx;
    [Test]
    procedure TestClient_QueryOnroad;
    [Test]
    procedure TestClient_GetBalanceAll;
    [Test]
    procedure TestClient_GetBalance;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math.BigInt,
  DUnitX.Assert,
  Common.Types,
  Common.Config,
  Interfaces.Core,
  RpcApi.Api,
  Wallet,
  Wallet.EntropyStore,
  Client,
  Client.Test.Helper;

{ TClientTest }

procedure TClientTest.TestWallet;
var
  i: Cardinal;
  vKey: IKey;
  vAddr: TAddress;
  vErr: Exception;
begin
  if not PreTest(Self) then
  begin
    Exit;
  end;

  WriteLn('----------------------Wallet2----------------------');
  for i := 0 to 9 do
  begin
    try
      vErr := gWallet2.DeriveForIndexPath(i, vKey);
      Assert.IsNull(vErr, 'DeriveForIndexPath failed: ' + vErr.Message);
      vAddr := vKey.Address;
      WriteLn(vAddr.ToString);
    except
      on E: Exception do
      begin
        Assert.Fail(E.Message);
      end;
    end;
  end;
  WriteLn('----------------------Wallet2----------------------');
end;

procedure TClientTest.TestClient_SubmitRequestTx;
var
  vRpc: IRpcClient;
  vClient: IClient;
  vSelf, vTo: TAddress;
  vBlock: IAccountBlock;
  vRequestParams: TRequestTxParams;
  vErr: Exception;
begin
  Self.Skip('Skipped by default. This test can be used to submit a request transaction.');

  if not PreTest(Self) then
  begin
    Exit;
  end;
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vClient := NewClient(vRpc);
    Assert.IsNotNull(vClient, 'NewClient should not return nil');

    vSelf := THex.HexToAddress('vite_165a295e214421ef1276e79990533953e901291d29b2d4851f');
    vTo := THex.HexToAddress('vite_2ca3c5f1f18b38f865eb47196027ae0c50d0c21e67774abdda');

    vRequestParams.ToAddr := vTo;
    vRequestParams.SelfAddr := vSelf;
    vRequestParams.Amount := TBigInteger.Create(10000);
    vRequestParams.TokenId := TTypes.ViteTokenId;
    vRequestParams.Data := TEncoding.UTF8.GetBytes('hello pow');

    vBlock := vClient.BuildNormalRequestBlock(vRequestParams, nil);
    Assert.IsNotNull(vBlock, 'BuildNormalRequestBlock should not return nil');

    vClient.SignData(gWallet2, vBlock);

    vErr := vRpc.SendRawTx(vBlock);
    Assert.IsNull(vErr, 'SendRawTx failed: ' + vErr.Message);

    WriteLn(Format('submit request tx success. %s %s', [vBlock.Hash.ToString, vBlock.Height]));
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

procedure TClientTest.TestClient_CreateContract;
var
  vRpc: IRpcClient;
  vClient: IClient;
  vSelf: TAddress;
  vBlock: IAccountBlock;
  vDefinition, vCode: string;
  vCreateParams: TRequestCreateContractParams;
  vErr: Exception;
begin
  Self.Skip('Skipped by default. This test can be used to create a contract.');

  if not PreTest(Self) then
  begin
    Exit;
  end;
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vClient := NewClient(vRpc);
    Assert.IsNotNull(vClient, 'NewClient should not return nil');

    vSelf := THex.HexToAddress('vite_165a295e214421ef1276e79990533953e901291d29b2d4851f');
    vDefinition := '';
    vCode := '';

    vCreateParams.SelfAddr := vSelf;
    vCreateParams.abiStr := vDefinition;
    vCreateParams.metaParams.Gid := TTypes.DELEGATE_GID;
    vCreateParams.metaParams.ConfirmTime := 12;
    vCreateParams.metaParams.SeedCount := 12;
    vCreateParams.metaParams.QuotaRatio := 10;
    vCreateParams.metaParams.HexCode := vCode;

    vBlock := vClient.BuildRequestCreateContractBlock(vCreateParams, nil);
    Assert.IsNotNull(vBlock, 'BuildRequestCreateContractBlock should not return nil');

    vClient.SignData(gWallet2, vBlock);

    vErr := vRpc.SendRawTx(vBlock);
    Assert.IsNull(vErr, 'SendRawTx failed: ' + vErr.Message);

    WriteLn(Format('submit request tx success. %s %s', [vBlock.Hash.ToString, vBlock.Height]));
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

procedure TClientTest.TestClient_SubmitResponseTx;
var
  vRpc: IRpcClient;
  vClient: IClient;
  vTo: TAddress;
  vRequestHash: THash;
  vBlock: IAccountBlock;
  vResponseParams: TResponseTxParams;
  vErr: Exception;
begin
  Self.Skip('Skipped by default. This test can be used to submit a response transaction.');

  if not PreTest(Self) then
  begin
    Exit;
  end;
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vTo := THex.HexToAddress('vite_2ca3c5f1f18b38f865eb47196027ae0c50d0c21e67774abdda');
    WriteLn(vTo.ToString);

    vClient := NewClient(vRpc);
    Assert.IsNotNull(vClient, 'NewClient should not return nil');

    vRequestHash := THex.HexToHashPanic('1058ac419ffa5f8cfa8bf3a19e8f4cf870ec0956025dc4ebc17793344fd2e67e');
    WriteLn(Format('receive request. %s', [vRequestHash.ToString]));

    vResponseParams.SelfAddr := vTo;
    vResponseParams.RequestHash := vRequestHash;

    vBlock := vClient.BuildResponseBlock(vResponseParams, nil);
    Assert.IsNotNull(vBlock, 'BuildResponseBlock should not return nil');

    WriteLn(Format('receive request. %s %s', [vRequestHash.ToString, vBlock.Amount]));

    vClient.SignData(gWallet2, vBlock);
    vErr := vRpc.SendRawTx(vBlock);
    Assert.IsNull(vErr, 'SendRawTx failed: ' + vErr.Message);
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

procedure TClientTest.TestClient_QueryOnroad;
var
  vRpc: IRpcClient;
  vAddr: TAddress;
  vBlocks: TArray<IAccountBlock>;
  vBlock: IAccountBlock;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vAddr := THex.HexToAddress('vite_2ca3c5f1f18b38f865eb47196027ae0c50d0c21e67774abdda');

    vErr := vRpc.GetOnroadBlocksByAddress(vAddr, 0, 100, vBlocks);
    Assert.IsNull(vErr, 'GetOnroadBlocksByAddress failed: ' + vErr.Message);

    if Length(vBlocks) > 0 then
    begin
      for vBlock in vBlocks do
      begin
        WriteLn(Format('%s %s %s %s %s', [vBlock.Height, vBlock.AccountAddress.ToString, vBlock.ToAddress.ToString, vBlock.Amount, vBlock.Hash.ToString]));
      end;
    end;
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

procedure TClientTest.TestClient_GetBalanceAll;
var
  vRpc: IRpcClient;
  vClient: IClient;
  vAddr: TAddress;
  vBalance, vOnroad: IRpcAccountInfo;
  vKey: TTokenTypeId;
  vValue: ITokenBalanceInfo;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vClient := NewClient(vRpc);
    Assert.IsNotNull(vClient, 'NewClient should not return nil');

    vAddr := THex.HexToAddress('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');

    vErr := vClient.GetBalanceAll(vAddr, vBalance, vOnroad);
    Assert.IsNull(vErr, 'GetBalanceAll failed: ' + vErr.Message);

    for vKey in vBalance.TokenBalanceInfoMap.Keys do
    begin
      vValue := vBalance.TokenBalanceInfoMap[vKey];
      WriteLn(Format('%s balance %s %s', [vKey.ToString, vValue.TokenInfo.TokenSymbol, vValue.TotalAmount]));
    end;
    for vKey in vOnroad.TokenBalanceInfoMap.Keys do
    begin
      vValue := vOnroad.TokenBalanceInfoMap[vKey];
      WriteLn(Format('%s onroad %s %s', [vKey.ToString, vValue.TokenInfo.TokenSymbol, vValue.TotalAmount]));
    end;
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

procedure TClientTest.TestClient_GetBalance;
var
  vRpc: IRpcClient;
  vClient: IClient;
  vAddr: TAddress;
  vBalance, vOnroad: TBigInteger;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vClient := NewClient(vRpc);
    Assert.IsNotNull(vClient, 'NewClient should not return nil');

    vAddr := THex.HexToAddress('vite_1b351d987dd194ea7f8146a45e7b2625c1d9d483505fc524e8');

    vErr := vClient.GetBalance(vAddr, TTypes.ViteTokenId, vBalance, vOnroad);
    Assert.IsNull(vErr, 'GetBalance failed: ' + vErr.Message);

    WriteLn(Format('balance %s', [vBalance.ToString]));
    WriteLn(Format('onroad %s', [vOnroad.ToString]));
  except
    on E: Exception do
    begin
      Assert.Fail(E.Message);
    end;
  end;
end;

initialization
  RegisterTestFixture(TClientTest);
end.
