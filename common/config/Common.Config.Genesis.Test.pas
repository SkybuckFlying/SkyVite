unit Common.Config.Genesis.Test;

interface

uses
  DUnitX.TestFramework,
  Common.Config.Genesis,
  Common.Types,
  GoToDelphi.Helpers.BigInt;

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
  [TestFixture]
  TGenesisTests = class(TObject)
  public
    [Test]
    procedure TestMakeGenesisConfig;
    [Test]
    procedure TestIsCompleteGenesisConfig;
    [Test]
    procedure TestMainnetGenesis;
    [Test]
    procedure TestMockGenesis;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections;

{ TGenesisTests }

procedure TGenesisTests.TestMakeGenesisConfig;
var
  vTempFile: string;
  vGenesis: TGenesis;
begin
  // Test with a valid mock file
  vTempFile := TPath.GetTempFileName;
  try
    TFile.WriteAllText(vTempFile, MockGenesisJson);
    vGenesis := MakeGenesisConfig(vTempFile);
    Assert.IsNotNull(vGenesis, 'Genesis object should not be nil when loading from a valid file');
    Assert.IsTrue(IsCompleteGenesisConfig(vGenesis), 'Genesis config should be complete when loading from a valid file');
    vGenesis.Free;
  finally
    TFile.Delete(vTempFile);
  end;

  // Test with no file (should attempt to load mainnet, which is currently empty and should fail)
  vGenesis := MakeGenesisConfig('');
  Assert.IsNull(vGenesis, 'Genesis object should be nil when mainnet JSON is not available');
end;

procedure TGenesisTests.TestIsCompleteGenesisConfig;
var
  vGenesis: TGenesis;
  vAddr: TAddress;
  vTokenId: TTokenTypeId;
  vBig: TBigInt;
  vTokenInfo: TTokenInfo;
  vGroupInfo: TConsensusGroupInfo;
  vRegInfo: TRegistrationInfo;
  vRegInfoMap: TDictionary<string, TRegistrationInfo>;
begin
  vGenesis := TGenesis.Create;
  try
    Assert.IsFalse(IsCompleteGenesisConfig(nil), 'IsCompleteGenesisConfig(nil) should be false');
    Assert.IsFalse(IsCompleteGenesisConfig(vGenesis), 'Empty genesis should be incomplete');

    // Populate GovernanceInfo
    vGroupInfo := TConsensusGroupInfo.Create;
    vGenesis.GovernanceInfo.ConsensusGroupInfoMap.Add('g1', vGroupInfo);
    Assert.IsFalse(IsCompleteGenesisConfig(vGenesis), 'Genesis should be incomplete without RegistrationInfo');

    vRegInfo := TRegistrationInfo.Create;
    vRegInfoMap := TDictionary<string, TRegistrationInfo>.Create;
    vRegInfoMap.Add('sbp1', vRegInfo);
    vGenesis.GovernanceInfo.RegistrationInfoMap.Add('g1', vRegInfoMap);
    Assert.IsFalse(IsCompleteGenesisConfig(vGenesis), 'Genesis should be incomplete without AssetInfo');

    // Populate AssetInfo
    vTokenInfo := TTokenInfo.Create;
    vGenesis.AssetInfo.TokenInfoMap.Add('tti_1', vTokenInfo);
    Assert.IsFalse(IsCompleteGenesisConfig(vGenesis), 'Genesis should be incomplete without AccountBalanceMap');

    // Populate AccountBalanceMap
    vAddr := TAddress.FromString('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
    vTokenId := TTokenTypeId.FromString('tti_5649544520544f4b454e6e40');
    vBig := TBigInt.Create;
    vBig.SetString('1000', 10);
    vGenesis.AccountBalanceMap.Add(vAddr.ToString, TDictionary<string, TBigInt>.Create);
    vGenesis.AccountBalanceMap[vAddr.ToString].Add(vTokenId.ToString, vBig);

    Assert.IsTrue(IsCompleteGenesisConfig(vGenesis), 'Fully populated genesis should be complete');

  finally
    vGenesis.Free;
  end;
end;

procedure TGenesisTests.TestMainnetGenesis;
begin
  // Since ConstGenesisJson is empty, this is expected to raise an exception.
  Assert.WillRaise(procedure
    var
      vGenesis: TGenesis;
    begin
      vGenesis := MainnetGenesis;
      if Assigned(vGenesis) then
        vGenesis.Free;
    end, EJSONParseException, 'MainnetGenesis should raise an exception with empty JSON');
end;

procedure TGenesisTests.TestMockGenesis;
var
  vGenesis: TGenesis;
  vExpectedAddr: string;
begin
  vGenesis := nil;
  try
    vGenesis := MockGenesis;
    Assert.IsNotNull(vGenesis, 'MockGenesis should return a non-nil object');

    vExpectedAddr := 'vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a';
    Assert.AreEqual(vExpectedAddr, vGenesis.GenesisAccountAddress.ToString, 'MockGenesis address does not match');

    Assert.IsTrue(vGenesis.AssetInfo.TokenInfoMap.ContainsKey('tti_5649544520544f4b454e6e40'), 'MockGenesis should contain VITE token info');
  finally
    if Assigned(vGenesis) then
      vGenesis.Free;
  end;
end;

initialization
  RegisterTestFixture(TGenesisTests);
end.
