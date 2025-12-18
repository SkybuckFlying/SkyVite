unit Common.Config.Config;

interface

uses
  Common.Config.Chain,
  Common.Config.Genesis,
  Common.Config.Genesis.Json,
  Common.Config.Genesis.Mock.Json,
  Common.Config.Genesis.Test,
  Common.Config.Net,
  Common.Config.Node.Reward,
  Common.Config.Node_Reward,
  Common.Config.Producer,
  Common.Config.Subscribe,
  Common.Config.Upgrade,
  Common.Config.Vm,
  Common.Config.Wallet,
  System.SysUtils;

/*
 * Copyright 2019 The go-vite Authors
 * This file is part of the go-vite library.
 *
 * The go-vite library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The go-vite library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.
 */

type
  TConfig = class
  private
    mProducer: TProducer;
    mChain: TChain;
    mVm: TVm;
    mSubscribe: TSubscribe;
    mNet: TNet;
    mNodeReward: TNodeReward;
    mGenesis: TGenesis;
    mDataDir: string;
    mLogLevel: string;
  public
    [JsonReflect(ctObject, TProducer)]
    property Producer: TProducer read mProducer write mProducer;
    [JsonReflect(ctObject, TChain)]
    property Chain: TChain read mChain write mChain;
    [JsonReflect(ctObject, TVm)]
    property Vm: TVm read mVm write mVm;
    [JsonReflect(ctObject, TSubscribe)]
    property Subscribe: TSubscribe read mSubscribe write mSubscribe;
    [JsonReflect(ctObject, TNet)]
    property Net: TNet read mNet write mNet;
    [JsonReflect(ctObject, TNodeReward, 'Reward')]
    property NodeReward: TNodeReward read mNodeReward write mNodeReward;
    [JsonReflect(ctObject, TGenesis)]
    property Genesis: TGenesis read mGenesis write mGenesis;

    // global keys
    property DataDir: string read mDataDir write mDataDir;
    // Log level
    property LogLevel: string read mLogLevel write mLogLevel;

    constructor Create;
    destructor Destroy; override;

    function RunLogDir: string;
    class function DefaultDataDir: string;
  end;

implementation

uses
  System.IOUtils,
  System.JSON;

{ TConfig }

constructor TConfig.Create;
begin
  inherited Create;
  try
    mProducer := TProducer.Create;
    mChain := TChain.Create;
    mVm := TVm.Create;
    mSubscribe := TSubscribe.Create;
    mNet := TNet.Create;
    mNodeReward := TNodeReward.Create;
    mGenesis := TGenesis.Create;
  except
    on E: Exception do
    begin
      FreeAndNil(mProducer);
      FreeAndNil(mChain);
      FreeAndNil(mVm);
      FreeAndNil(mSubscribe);
      FreeAndNil(mNet);
      FreeAndNil(mNodeReward);
      FreeAndNil(mGenesis);
      raise;
    end;
  end;
end;

destructor TConfig.Destroy;
begin
  mProducer.Free;
  mChain.Free;
  mVm.Free;
  mSubscribe.Free;
  mNet.Free;
  mNodeReward.Free;
  mGenesis.Free;
  inherited Destroy;
end;

function TConfig.RunLogDir: string;
begin
  Result := TPath.Combine(mDataDir, 'runlog');
end;

// DefaultDataDir is the default data directory to use for the databases and other persistence requirements.
class function TConfig.DefaultDataDir: string;
var
  vHome: string;
begin
  vHome := homeDir;
  if vHome <> '' then
  begin
    {$IFDEF MACOS}
    Result := TPath.Combine(vHome, 'Library', 'GVite');
    {$ELSEIF MSWINDOWS}
    Result := TPath.Combine(vHome, 'AppData', 'Roaming', 'GVite');
    {$ELSE}
    Result := TPath.Combine(vHome, '.gvite');
    {$ENDIF}
  end
  else
  begin
    // As we cannot guess chain stable location, return empty and handle later
    Result := '';
  end;
end;

class function TConfig.homeDir: string;
begin
  Result := TPath.GetHomePath;
  if Result = '' then
  begin
    Result := GetEnvironmentVariable('HOME');
  end;
end;

end.
