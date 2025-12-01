unit Ledger.Test.Tools.Chain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  Common.Config,
  Common.Upgrade,
  Ledger.Chain,
  Ledger.Chain.Test.Tools,
  Vm.Quota;

function NewChainInstanceFromDir(ParaDirName: string; ParaClear: Boolean; ParaGenesis: string): IChain;
function NewTestChainInstance(ParaDirName: string; ParaClear: Boolean; ParaGenesis: TGenesis): TPair<IChain, string>;
function NewTestChainInstance2(ParaDirName: string; ParaClear: Boolean; ParaGenesisJson: string): IChain;
procedure ClearChain(ParaC: IChain; ParaDir: string);

implementation

function NewChainInstanceFromDir(ParaDirName: string; ParaClear: Boolean; ParaGenesis: string): IChain;
var
  vGenesisConfig: TGenesis;
  vChainInstance: IChain;
begin
  if ParaClear then
    TDirectory.Delete(ParaDirName, True);
  TQuota.InitQuotaConfig(False, True);
  vGenesisConfig := TJson.JsonToObject<TGenesis>(ParaGenesis);
  vChainInstance := TChain.Create(ParaDirName, TChainConfig.Create, vGenesisConfig);
  vChainInstance.Init;
  vChainInstance.Start;
  Result := vChainInstance;
end;

function NewTestChainInstance(ParaDirName: string; ParaClear: Boolean; ParaGenesis: TGenesis): TPair<IChain, string>;
var
  vTempDir: string;
  vGenesisConfig: TGenesis;
  vChainInstance: IChain;
begin
  vTempDir := TPath.Combine(TChainTestTools.DefaultDataDir, ParaDirName);
  WriteLn('tempDir: ' + vTempDir);
  if ParaClear then
    TDirectory.Delete(vTempDir, True);

  TQuota.InitQuotaConfig(False, True);
  TUpgrade.CleanupUpgradeBox;

  if ParaGenesis <> nil then
  begin
    vGenesisConfig := ParaGenesis;
    TUpgrade.InitUpgradeBox(vGenesisConfig.UpgradeCfg.MakeUpgradeBox);
  end
  else
  begin
    vGenesisConfig := TGenesis.Create;
    TUpgrade.InitUpgradeBox(TUpgradeBox.Create.AddPoint(1, 10000000));
  end;

  vChainInstance := TChain.Create(vTempDir, TChainConfig.Create, vGenesisConfig);
  vChainInstance.Init;
  vChainInstance.Start;
  Result := TPair<IChain, string>.Create(vChainInstance, vTempDir);
end;

function NewTestChainInstance2(ParaDirName: string; ParaClear: Boolean; ParaGenesisJson: string): IChain;
var
  vDataDir: string;
  vGenesisConfig: TGenesis;
  vChainInstance: IChain;
begin
  if TPath.IsPathRooted(ParaDirName) then
    vDataDir := ParaDirName
  else
    vDataDir := TPath.Combine(TChainTestTools.DefaultDataDir, ParaDirName);

  if ParaClear then
    TDirectory.Delete(vDataDir, True);

  vGenesisConfig := TJson.JsonToObject<TGenesis>(ParaGenesisJson);
  TUpgrade.InitUpgradeBox(TConfig.MockGenesis.UpgradeCfg.MakeUpgradeBox);

  vChainInstance := TChain.Create(vDataDir, TChainConfig.Create, vGenesisConfig);
  vChainInstance.Init;
  vChainInstance.Start;
  Result := vChainInstance;
end;

procedure ClearChain(ParaC: IChain; ParaDir: string);
begin
  if ParaC <> nil then
    ParaC.Stop;
  TDirectory.Delete(ParaDir, True);
end;

end.