unit Ledger.Consensus.UnitTest.Util;

interface

uses
  DUnitX.TestFramework,
  Common.Config,
  Ledger.Chain,
  GoToDelphi.Helpers.LevelDB;

const
  GenesisJson = '{"GenesisAccountAddress":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a","ForkPoints":{},"GovernanceInfo":{"ConsensusGroupInfoMap":{"00000000000000000001":{"NodeCount":3,"Interval":1,"PerCount":3,"RandCount":2,"RandRank":100,"Repeat":1,"CheckLevel":0,"CountingTokenId":"tti_5649544520544f4b454e6e40","RegisterConditionId":1,"RegisterConditionParam":{"StakeAmount":100000000000000000000000,"StakeHeight":1,"StakeToken":"tti_5649544520544f4b454e6e40"},"VoteConditionId":1,"VoteConditionParam":{},"Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a","StakeAmount":0,"ExpirationHeight":1},"00000000000000000002":{"NodeCount":3,"Interval":3,"PerCount":1,"RandCount":2,"RandRank":100,"Repeat":48,"CheckLevel":1,"CountingTokenId":"tti_5649544520544f4b454e6e40","RegisterConditionId":1,"RegisterConditionParam":{"StakeAmount":100000000000000000000000,"StakeHeight":1,"StakeToken":"tti_5649544520544f4b454e6e40"},"VoteConditionId":1,"VoteConditionParam":{},"Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a","StakeAmount":0,"ExpirationHeight":1}},"RegistrationInfoMap":{"00000000000000000001":{"s1":{"BlockProducingAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a","StakeAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a","Amount":100000000000000000000000,"ExpirationHeight":7776000,"RewardTime":1,"RevokeTime":0,"HistoryAddressList":["vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a"]},"s2":{"BlockProducingAddress":"vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25","StakeAddress":"vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25","Amount":100000000000000000000000,"ExpirationHeight":7776000,"RewardTime":1,"RevokeTime":0,"HistoryAddressList":["vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25"]},"s3":{"BlockProducingAddress":"vite_409...';
  UnitTestDir = 'testdata-unittest';

function NewDb(t: TTest; const dirName: string): TLevelDB;
procedure ClearDb(t: TTest; const dirName: string);
function NewChain(t: TTest; const dirName: string; const genesis: string): IChain;
procedure ClearChain(const dirName: string);

implementation

uses
  System.IOUtils,
  System.Json,
  VM.Quota;

function NewDb(t: TTest; const dirName: string): TLevelDB;
var
  db: TLevelDB;
  err: Exception;
begin
  err := nil;
  try
    db := TLevelDB.OpenFile(dirName, nil);
  except
    on E: Exception do
    begin
      err := E;
    end;
  end;
  if err <> nil then
  begin
    t.Fail(err.Message);
  end;
  Result := db;
end;

procedure ClearDb(t: TTest; const dirName: string);
begin
  TDirectory.Delete(dirName, True);
end;

function NewChain(t: TTest; const dirName: string; const genesis: string): IChain;
var
  genesisConfig: TGenesis;
  chainInstance: IChain;
  err: Exception;
begin
  ClearChain(dirName);
  TQuota.InitQuotaConfig(False, True);
  genesisConfig := TGenesis.Create;
  try
    TJson.PopulateObject(TJson.Parse(genesis), genesisConfig);
    chainInstance := TChain.Create(dirName, TChainConfig.Create, genesisConfig);
    err := nil;
    try
      chainInstance.Init;
    except
      on E: Exception do
      begin
        err := E;
      end;
    end;
    if err <> nil then
    begin
      t.Fail(err.Message);
    end;
    chainInstance.Start;
    Result := chainInstance;
  finally
    genesisConfig.Free;
  end;
end;

procedure ClearChain(const dirName: string);
begin
  TDirectory.Delete(dirName, True);
end;

end.
