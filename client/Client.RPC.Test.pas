unit Client.Rpc.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TRpcTest = class(TObject)
  public
    [Test]
    procedure TestGetBlockByHash;
    [Test]
    procedure TestGetOnroadBlocksByAddress;
    [Test]
    procedure TestCalcPoWDifficulty;
    [Test]
    procedure TestQueryReward;
    [Test]
    procedure TestQueryVoteDetails;
    [Test]
    procedure Test_GetConfirmedBalances;
    [Test]
    procedure TestSBPStats;
    [Test]
    procedure TestSbpHash;
    [Test]
    procedure TestSbpddd;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math.BigInt,
  System.JSON,
  System.Generics.Collections,
  DUnitX.Assert,
  Common.Types,
  Interfaces.Core,
  Ledger.Consensus.Core,
  RpcApi.Api,
  Client,
  Client.Test.Helper;

{ TRpcTest }

procedure TRpcTest.TestGetBlockByHash;
var
  vRpc: IRpcClient;
  vHash: THash;
  vBlock: IAccountBlock;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vHash := THex.HexToHash('bfff83c40823c60ff8b28430f988334e60f49a9adacfc4b94b2fce224aa97d14');
    vErr := vRpc.GetBlockByHash(vHash, vBlock);
    Assert.IsNull(vErr, 'GetBlockByHash failed: ' + vErr.Message);
    Assert.IsNotNull(vBlock);
    WriteLn(vBlock.ToString);
    WriteLn(vBlock.TokenId.ToString);
  except
    on E: Exception do
      Assert.Fail('TestGetBlockByHash failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestGetOnroadBlocksByAddress;
var
  vRpc: IRpcClient;
  vAddr: TAddress;
  vBs: TArray<IAccountBlock>;
  vBlock: IAccountBlock;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vAddr := THex.HexToAddress('vite_c4a8fe0c93156fe3fd5dc965cc5aea3fcb46f5a0777f9d1304');
    vErr := vRpc.GetOnroadBlocksByAddress(vAddr, 1, 10, vBs);
    Assert.IsNull(vErr, 'GetOnroadBlocksByAddress failed: ' + vErr.Message);

    if Length(vBs) > 0 then
    begin
      for vBlock in vBs do
      begin
        WriteLn(vBlock.ToString);
      end;
    end;
  except
    on E: Exception do
      Assert.Fail('TestGetOnroadBlocksByAddress failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestCalcPoWDifficulty;
var
  vRpc: IRpcClient;
  vSelf, vTo: TAddress;
  vPrevHash: THash;
  vBs: TBytes;
  vParam: TCalcPoWDifficultyParam;
  vErr: Exception;
begin
  Self.Skip('Skipped by default. This test can be used to calculate PoW difficulty.');

  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vSelf := THex.HexToAddress('vite_165a295e214421ef1276e79990533953e901291d29b2d4851f');
    vTo := THex.HexToAddress('vite_228f578d58842437fb52104b25750aa84a6f8558b6d9e970b1');
    vPrevHash := THex.HexToHash('58cb3cd2d00c6c0c883ec3aee9069445b826a165eacc75ece9e1fd008f6ccc5e');

    vParam.SelfAddr := vSelf;
    vParam.PrevHash := vPrevHash;
    vParam.BlockType := TBlockType.SendCall;
    vParam.ToAddr := vTo;
    vParam.Data := TEncoding.UTF8.GetBytes('hello world');
    vParam.UseStakeQuota := False;

    vErr := vRpc.CalcPoWDifficulty(vParam, vBs);
    Assert.IsNull(vErr, 'CalcPoWDifficulty failed: ' + vErr.Message);
    WriteLn(THex.EncodeToString(vBs));
  except
    on E: Exception do
      Assert.Fail('TestCalcPoWDifficulty failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestQueryReward;
var
  vClient: IRpcClient;
  vBs: TObject;
  vJson: TJSONValue;
  vErr: Exception;
begin
  vClient := PreTestRpc(Self, RawUrl);
  if vClient = nil then
    Exit;

  try
    vErr := vClient.GetRewardByIndex(0, vBs);
    Assert.IsNull(vErr, 'GetRewardByIndex failed: ' + vErr.Message);
    Assert.IsNotNull(vBs);
    vJson := TJSONObject.FromObject(vBs);
    WriteLn(vJson.ToString);
  except
    on E: Exception do
      Assert.Fail('TestQueryReward failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestQueryVoteDetails;
var
  vRpc: IRpcClient;
  vBs: TObject;
  vJson: TJSONValue;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vErr := vRpc.GetVoteDetailsByIndex(0, vBs);
    Assert.IsNull(vErr, 'GetVoteDetailsByIndex failed: ' + vErr.Message);
    Assert.IsNotNull(vBs);
    vJson := TJSONObject.FromObject(vBs);
    WriteLn(vJson.ToString);
  except
    on E: Exception do
      Assert.Fail('TestQueryVoteDetails failed: ' + E.Message);
  end;
end;

procedure TRpcTest.Test_GetConfirmedBalances;
var
  vRpc: IRpcClient;
  vShash: THash;
  vGids: TArray<TTokenTypeId>;
  vData: TArray<string>;
  vAddrList: TArray<TAddress>;
  vBalancesRes: TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>;
  vTotal: TBigInteger;
  vAddr: TAddress;
  vBalances: TDictionary<TTokenTypeId, TBigInteger>;
  vTokenId: TTokenTypeId;
  vAmount: TBigInteger;
  i: Integer;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  vShash := THex.HexToHashPanic('25e11b16de62fe5863266cac3c318cf603759a647049672fdb9db5524cc26282');
  SetLength(vGids, 1);
  vGids[0] := TTypes.ViteTokenId;

  vData := ['vite_002f27f64a3e52b8ff62b28c4bb52441cb7d7dcf038032a52f',
    'vite_0033e7c54bd8bc63a4885aa194c15cb6d20465dc035cdab3a2',
    'vite_0065513a57258a84af95a438cf04efbb2071734cf29dabd7df',
    'vite_01b0cb6e49a9e1a86b76562a46f406efcf0ed14d31f9cc68a8',
    'vite_01c92aba4b6e5278e9c4b9fdd559bc9fe7ead97b30a2f55de5',
    'vite_02473e87c77ab8891dda88797764f960379c81b2380b749959',
    'vite_ffe984e5754cfcb852920147fcd931832d85f051363f50aee4'];

  SetLength(vAddrList, Length(vData));
  for i := 0 to High(vData) do
  begin
    vAddrList[i] := THex.HexToAddressPanic(vData[i]);
  end;

  try
    vErr := vRpc.GetConfirmedBalances(vShash, vAddrList, vGids, vBalancesRes);
    Assert.IsNull(vErr, 'GetConfirmedBalances failed: ' + vErr.Message);

    vTotal := TBigInteger.Zero;
    for vAddr in vBalancesRes.Keys do
    begin
      vBalances := vBalancesRes[vAddr];
      for vTokenId in vBalances.Keys do
      begin
        vAmount := vBalances[vTokenId];
        WriteLn(Format('%s %s %s', [vAddr.ToString, vTokenId.ToString, vAmount.ToString]));
        vTotal := vTotal + vAmount;
      end;
    end;

    WriteLn(Format('total %s', [vTotal.ToString]));
  except
    on E: Exception do
      Assert.Fail('Test_GetConfirmedBalances failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestSBPStats;
var
  vRpc: IRpcClient;
  vStats: TObject;
  vRate: TDictionary<string, TArray<TSbpStats>>;
  vPair: TPair<string, TObject>;
  vStatObj: TObject;
  vBytes: TBytes;
  vHourStats: THourStats;
  vTotalNum, vTotalExcepted: UInt64;
  vAddr: TAddress;
  vSbpStat: TSbpStats;
  vKey: string;
  vSbpStatsArray: TArray<TSbpStats>;
  vStat: TSbpStats;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vErr := vRpc.GetHourSBPStats(1, 0, vStats);
    Assert.IsNull(vErr, 'GetHourSBPStats failed: ' + vErr.Message);

    vRate := TDictionary<string, TArray<TSbpStats>>.Create;
    try
      for vPair in TDictionary<string, TObject>(vStats) do
      begin
        vStatObj := TDictionary<string, TObject>(vPair.Value).Items['stat'];
        vBytes := TJson.ObjectToBytes(vStatObj);
        vHourStats := TJson.BytesToObject<THourStats>(vBytes);

        vTotalNum := 0;
        vTotalExcepted := 0;
        for vAddr in vHourStats.Stats.Keys do
        begin
          vSbpStat := vHourStats.Stats[vAddr];
          vTotalNum := vTotalNum + vSbpStat.BlockNum;
          vTotalExcepted := vTotalExcepted + vSbpStat.ExceptedBlockNum;
          if not vRate.ContainsKey(vAddr.ToString) then
          begin
            vRate.Add(vAddr.ToString, []);
          end;
          vSbpStatsArray := vRate[vAddr.ToString];
          SetLength(vSbpStatsArray, Length(vSbpStatsArray) + 1);
          vSbpStatsArray[High(vSbpStatsArray)] := vSbpStat;
          vRate[vAddr.ToString] := vSbpStatsArray;
        end;
        WriteLn(Format('%s %d %d %f', [TDictionary<string, TValue>(vPair.Value).Items['stime'].ToString, vTotalNum, vTotalExcepted, vTotalNum / vTotalExcepted]));
      end;

      for vKey in vRate.Keys do
      begin
        Write(vKey);
        vSbpStatsArray := vRate[vKey];
        for vStat in vSbpStatsArray do
        begin
          Write(Format(#9#9'%.4f', [vStat.BlockNum / vStat.ExceptedBlockNum]));
        end;
        WriteLn;
      end;
    finally
      vRate.Free;
    end;
  except
    on E: Exception do
      Assert.Fail('TestSBPStats failed: ' + E.Message);
  end;
end;

procedure TRpcTest.TestSbpHash;
var
  vRpc: IRpcClient;
  vHashes: TArray<string>;
  vHashStr: string;
  vBlock: ISnapshotBlock;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  vHashes := ['f348100aa8ef02f3dfa0938bc1c050073ddb2d73259357d3cbcb0610374350fc',
    'b111255964406a4c319fd41c941b6da7921273dea3139373bb7ce686623d6022',
    'ff044e6dff2fa64afa7d453d0addc663f93b560266759af42f69130b978687e4',
    'f2f071e4c09664d6023d9f5063e13c975e2d45249a15fc4d4e2521ec91b2ee0e',
    'b282eec7feaad79eff119637c5a5585a8d0ea468b8b3d4bb26f6d21ff4fded07',
    'bc6b714c5156467c771fc8e5faf933e8da67c4988b5846a9ed6f5d805e5a2e57',
    'cdd1d81a8cee589217f301b1acc4a571384340325c7e9df9aa673b2694406b2a',
    'c69280cc3daf4be24187fe3132046efa9dd4c4eba5e264dba55d2e4090b635c9'];

  for vHashStr in vHashes do
  begin
    try
      vErr := vRpc.GetSnapshotBlockByHash(THex.HexToHashPanic(vHashStr), vBlock);
      Assert.IsNull(vErr, 'GetSnapshotBlockByHash failed: ' + vErr.Message);
      Assert.IsNotNull(vBlock);
      WriteLn(Format('%s %s', [vHashStr, vBlock.Producer.ToString]));
    except
      on E: Exception do
        Assert.Fail('TestSbpHash failed for hash ' + vHashStr + ': ' + E.Message);
    end;
  end;
end;

procedure TRpcTest.TestSbpddd;
var
  vRpc: IRpcClient;
  vHash1, vHash2: THash;
  vBlock1, vBlock2: IAccountBlock;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  try
    vHash1 := THex.HexToHashPanic('108f714be8fa1662eed21891d74694eae839408d9e28e19670be52dd177818a5');
    vHash2 := THex.HexToHashPanic('da5eb52fe8e39ca52698c47e7c6384b7a6c08177d44fc828f8dc562bf3157ad2');

    vErr := vRpc.GetBlockByHash(vHash1, vBlock1);
    Assert.IsNull(vErr, 'GetBlockByHash(1) failed: ' + vErr.Message);
    Assert.IsNotNull(vBlock1);

    vErr := vRpc.GetBlockByHash(vHash2, vBlock2);
    Assert.IsNull(vErr, 'GetBlockByHash(2) failed: ' + vErr.Message);
    Assert.IsNotNull(vBlock2);

    WriteLn(THex.EncodeToString(vBlock1.Data));
    WriteLn(THex.EncodeToString(vBlock2.Data));
  except
    on E: Exception do
      Assert.Fail('TestSbpddd failed: ' + E.Message);
  end;
end;

initialization
  RegisterTestFixture(TRpcTest);
end.
