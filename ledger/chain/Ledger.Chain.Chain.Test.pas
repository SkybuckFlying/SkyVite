unit Ledger.Chain.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Chain,
  Common.Types,
  Interfaces.Core;

type
  [TestFixture]
  TChainTest = class
  public
    [Test]
    procedure TestChain;
    [Test]
    procedure TestCheckHash;
    [Test]
    procedure TestCheckHash2;
    [Test]
    procedure TestChainForkRollBack;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Ledger.Chain.Test.Utils,
  Common.Upgrade,
  Common.Config.Genesis;

const
  GenesisJson = '{' +
  '  "GenesisAccountAddress": "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '  "ForkPoints": {' +
  '  },' +
  '  "GovernanceInfo": {' +
  '    "ConsensusGroupInfoMap":{' +
  '      "00000000000000000001":{' +
  '        "NodeCount": 1,' +
  '        "Interval":1,' +
  '        "PerCount":3,' +
  '        "RandCount":2,' +
  '        "RandRank":100,' +
  '        "Repeat":1,' +
  '        "CheckLevel":0,' +
  '        "CountingTokenId":"tti_5649544520544f4b454e6e40",' +
  '        "RegisterConditionId":1,' +
  '        "RegisterConditionParam":{' +
  '          "StakeAmount": 100000000000000000000000,' +
  '          "StakeHeight": 1,' +
  '          "StakeToken": "tti_5649544520544f4b454e6e40"' +
  '        },' +
  '        "VoteConditionId":1,' +
  '        "VoteConditionParam":{},' +
  '        "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '        "StakeAmount":0,' +
  '        "ExpirationHeight":1' +
  '      },' +
  '      "00000000000000000002":{' +
  '        "NodeCount": 1,' +
  '        "Interval":3,' +
  '        "PerCount":1,' +
  '        "RandCount":2,' +
  '        "RandRank":100,' +
  '        "Repeat":48,' +
  '        "CheckLevel":1,' +
  '        "CountingTokenId":"tti_5649544520544f4b454e6e40",' +
  '        "RegisterConditionId":1,' +
  '        "RegisterConditionParam":{' +
  '          "StakeAmount": 100000000000000000000000,' +
  '          "StakeHeight": 1,' +
  '          "StakeToken": "tti_5649544520544f4b454e6e40"' +
  '        },' +
  '        "VoteConditionId":1,' +
  '        "VoteConditionParam":{},' +
  '        "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '        "StakeAmount":0,' +
  '        "ExpirationHeight":1' +
  '      }' +
  '    },' +
  '    "RegistrationInfoMap":{' +
  '      "00000000000000000001":{' +
  '        "s1":{' +
  '          "BlockProducingAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a",' +
  '          "StakeAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a",' +
  '          "Amount":100000000000000000000000,' +
  '          "ExpirationHeight":7776000,' +
  '          "RewardTime":1,' +
  '          "RevokeTime":0,' +
  '          "HistoryAddressList":["vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a"]' +
  '        }' +
  '      }' +
  '    }' +
  '  },' +
  '  "AssetInfo":{' +
  '    "TokenInfoMap":{' +
  '      "tti_5649544520544f4b454e6e40":{' +
  '        "TokenName":"Vite Token",' +
  '        "TokenSymbol":"VITE",' +
  '        "TotalSupply":1000000000000000000000000000,' +
  '        "Decimals":18,' +
  '        "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '        "MaxSupply":115792089237316195423570985008687907853269984665640564039457584007913129639935,' +
  '        "IsOwnerBurnOnly":false,' +
  '        "IsReIssuable":true' +
  '      }' +
  '    },' +
  '    "LogList": [' +
  '      {' +
  '        "Data": "",' +
  '        "Topics": [' +
  '          "3f9dcc00d5e929040142c3fb2b67a3be1b0e91e98dac18d5bc2b7817a4cfecb6",' +
  '          "000000000000000000000000000000000000000000005649544520544f4b454e"' +
  '        ]' +
  '      }' +
  '    ]' +
  '  },' +
  '  "QuotaInfo": {' +
  '    "StakeInfoMap": {' +
  '      "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a": [' +
  '        {' +
  '          "Amount": 1000000000000000000000,' +
  '          "ExpirationHeight": 259200,' +
  '          "Beneficiary": "vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a"' +
  '        },' +
  '        {' +
  '          "Amount": 1000000000000000000000,' +
  '          "ExpirationHeight": 259200,' +
  '          "Beneficiary": "vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25"' +
  '        },' +
  '        {' +
  '          "Amount": 1000000000000000000000,' +
  '          "ExpirationHeight": 259200,' +
  '          "Beneficiary": "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a"' +
  '        },' +
  '        {' +
  '          "Amount": 1000000000000000000000,' +
  '          "ExpirationHeight": 259200,' +
  '          "Beneficiary": "vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23"' +
  '        }' +
  '      ]' +
  '    },' +
  '    "StakeBeneficialMap":{' +
  '      "vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a":1000000000000000000000,' +
  '      "vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25":1000000000000000000000,' +
  '      "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a":1000000000000000000000,' +
  '      "vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23":1000000000000000000000' +
  '    }' +
  '  },' +
  '  "AccountBalanceMap": {' +
  '    "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a": {' +
  '      "tti_5649544520544f4b454e6e40":99996000000000000000000000' +
  '    },' +
  '    "vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23": {' +
  '      "tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '    },' +
  '    "vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a": {' +
  '      "tti_5649544520544f4b454e6e40":600000000000000000000000000' +
  '    },' +
  '    "vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25": {' +
  '      "tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '    },' +
  '    "vite_847e1672c9a775ca0f3c3a2d3bf389ca466e5501cbecdb7107": {' +
  '      "tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '    }' +
  '  }' +
  '}';

function NewChainInstance(t: TTest; dirName: string; clear: boolean): IChain;
var
  dataDir: string;
  genesisConfig: TGenesis;
  chainCfg: TChainConfig;
  chainInstance: IChain;
begin
  if TPath.IsPathRooted(dirName) then
    dataDir := dirName
  else
    dataDir := TPath.Combine(DefaultDataDir, dirName);

  if clear then
    TDirectory.Delete(dataDir, True);

  genesisConfig := TGenesis.Create;
  TJson.JsonToObject(genesisConfig, GenesisJson);

  chainCfg := TChainConfig.Create;
  chainCfg.VmLogAll := true;
  chainInstance := TChain.Create(dataDir, chainCfg, genesisConfig);

  Assert.IsTrue(chainInstance.Init, 'Failed to initialize chain instance');

  chainInstance.SetConsensus(TVerifier.Create, TPeriodTimeIndex.Create(chainInstance.GetGenesisSnapshotBlock.Timestamp));

  chainInstance.Start;
  Result := chainInstance;
end;

procedure Clear(c: IChain);
begin
  TDirectory.Delete(c.dataDir, True);
end;

procedure SetUp(t: TTest; accountNum, txCount, snapshotPerBlockNum: integer; out accounts: TDictionary<TAddress, TAccount>; out snapshotBlockList: TArray<ISnapshotBlock>): IChain;
begin
  // set fork point
  TUpgrade.CleanupUpgradeBox;
  TUpgrade.InitUpgradeBox(TUpgradeBox.Create.AddPoint(1, 10000000));

  // test quota
  TQuota.InitQuotaConfig(true, true);

  Result := NewChainInstance(t, t.Name, true);

  Result.ResetLog(Result.chainDir, 'info');
  //InsertSnapshotBlock(chainInstance, true)

  accounts := MakeAccounts(Result, accountNum);

  snapshotBlockList := InsertAccountBlockAndSnapshot(Result, accounts, txCount, snapshotPerBlockNum, false);
end;

procedure TearDown(chainInstance: IChain);
begin
  chainInstance.Stop;
  chainInstance.Destroy;
end;

procedure TestChainAll(t: TTest; AChain: IChain; AAccounts: TDictionary<TAddress, TAccount>; ASnapshotBlockList: TArray<ISnapshotBlock>);
begin
  TestAccount(AChain, AAccounts);
  TestAccountBlock(t, AChain, AAccounts);
  TestOnRoad(t, AChain, AAccounts);
  TestSnapshotBlock(t, AChain, AAccounts, ASnapshotBlockList);
  TestState(t, AChain, AAccounts, ASnapshotBlockList);
  TestBuiltinContract(t, AChain, AAccounts, ASnapshotBlockList);
end;

{ TChainTest }

procedure TChainTest.TestChain;
var
  LChain: IChain;
  LAccounts: TDictionary<TAddress, TAccount>;
  LSnapshotBlockList: TArray<ISnapshotBlock>;
begin
  LChain := SetUp(Self, 20, 500, 10, LAccounts, LSnapshotBlockList);
  TestChainAll(Self, LChain, LAccounts, LSnapshotBlockList);
  LSnapshotBlockList := LSnapshotBlockList + InsertAccountBlockAndSnapshot(LChain, LAccounts, Random(50), Random(3), True);
  TestChainAll(Self, LChain, LAccounts, LSnapshotBlockList);
  LSnapshotBlockList := TestInsertAndDelete(Self, LChain, LAccounts, LSnapshotBlockList);
  TearDown(LChain);
end;

procedure TChainTest.TestCheckHash;
var
  LChain: IChain;
  LAccounts: TDictionary<TAddress, TAccount>;
  LSnapshotBlockList: TArray<ISnapshotBlock>;
begin
  LChain := SetUp(Self, 0, 0, 0, LAccounts, LSnapshotBlockList);
  Assert.IsTrue(LChain.CheckHash);
end;

procedure TChainTest.TestCheckHash2;
var
  chainInstance: IChain;
  hash: THash;
  block: IAccountBlock;
  LAccounts: TDictionary<TAddress, TAccount>;
  LSnapshotBlockList: TArray<ISnapshotBlock>;
begin
  chainInstance := SetUp(Self, 0, 0, 0, LAccounts, LSnapshotBlockList);
  hash := THex.HexToHash('3cc090aaaa241b3ff480cd461a1fb220fd429717855b5c990d1cb34dd1cef6c1');
  block := chainInstance.GetAccountBlockByHash(hash);
  Assert.IsNotNull(block);
end;

procedure TChainTest.TestChainForkRollBack;
var
  LCurSnapshotBlock: ISnapshotBlock;
  LAccountBlockList: TArray<IAccountBlock>;
  LAccountBlockListCopy: TArray<IAccountBlock>;
  LCreateSnaoshotContent: TFunc<ISnapshotContent>;
  LSb: ISnapshotBlock;
  LDelaccountBlockList: TArray<IAccountBlock>;
  LAccountBlockListNew: TArray<IAccountBlock>;
  LChain: IChain;
  LAccounts: TDictionary<TAddress, TAccount>;
begin
  LChain := SetUp(Self, 3, 100, 2, LAccounts, LSnapshotBlockList);
  LCurSnapshotBlock := LChain.GetLatestSnapshotBlock;
  TUpgrade.CleanupUpgradeBox;
  TUpgrade.InitUpgradeBox(TUpgradeBox.Create.AddPoint(1, LCurSnapshotBlock.Height + 1));
  InsertAccountBlocks(nil, LChain, LAccounts, 5);
  LAccountBlockList := LChain.GetAllUnconfirmedBlocks;
  SetLength(LAccountBlockListCopy, 2);
  System.Move(LAccountBlockList[Length(LAccountBlockList) - 2], LAccountBlockListCopy[0], 2 * SizeOf(IAccountBlock));

  LCreateSnaoshotContent := function: ISnapshotContent
    var
      LSc: ISnapshotContent;
      I: Integer;
      LBlock: IAccountBlock;
    begin
      LSc := TSnapshotContent.Create;
      for I := Length(LAccountBlockList) - 3 downto 0 do
      begin
        if I = Length(LAccountBlockList) then
          Continue;
        LBlock := LAccountBlockList[I];
        if not LSc.ContainsKey(LBlock.AccountAddress) then
          LSc.Add(LBlock.AccountAddress, THashHeight.Create(LBlock.Hash, LBlock.Height));
      end;
      Result := LSc;
    end;

  LSb := TSnapshotBlock.Create;
  LSb.PrevHash := LCurSnapshotBlock.Hash;
  LSb.Height := LCurSnapshotBlock.Height + 1;
  LSb.Timestamp := Now;
  LSb.SnapshotContent := LCreateSnaoshotContent();
  LSb.Hash := LSb.ComputeHash;
  LDelaccountBlockList := LChain.InsertSnapshotBlock(LSb);
  Assert.AreEqual(Length(LAccountBlockListCopy), Length(LDelaccountBlockList), 'len must be equal');
  for I := 0 to High(LDelaccountBlockList) do
    Assert.AreEqual(LDelaccountBlockList[I].Hash, LAccountBlockListCopy[I].Hash, 'must be equal');

  LAccountBlockListNew := LChain.GetAllUnconfirmedBlocks;
  Assert.AreEqual(0, Length(LAccountBlockListNew), 'GetAllUnconfirmedBlocks must be 0');
end;

end.
