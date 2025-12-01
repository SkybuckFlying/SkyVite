unit Common.Config.Genesis;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
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
  // Forward declarations
  TUpgrade = class;
  TGenesisVmLog = class;
  TGovernanceContractInfo = class;
  TAssetContractInfo = class;
  TQuotaContractInfo = class;
  TDexFundContractInfo = class;
  TConsensusGroupInfo = class;
  TRegistrationInfo = class;
  TTokenInfo = class;
  TStakeInfo = class;
  TRegisterConditionParam = class;
  TVoteConditionParam = class;
  TGenesis = class;

  TUpgrade = class
  public
    // In Go, this corresponds to the empty Upgrade message.
    // It might have fields added in the future.
  end;

  TGenesisVmLog = class
  private
    mData: string;
    mTopics: TArray<THash>;
  public
    property Data: string read mData write mData;
    property Topics: TArray<THash> read mTopics write mTopics;
  end;

  TRegisterConditionParam = class
  private
    mStakeAmount: TBigInt;
    mStakeToken: TTokenTypeId;
    mStakeHeight: UInt64;
  public
    constructor Create;
    destructor Destroy; override;
    property StakeAmount: TBigInt read mStakeAmount write mStakeAmount;
    property StakeToken: TTokenTypeId read mStakeToken write mStakeToken;
    property StakeHeight: UInt64 read mStakeHeight write mStakeHeight;
  end;

  TVoteConditionParam = class
  public
    // Corresponds to the empty VoteConditionParam message
  end;

  TConsensusGroupInfo = class
  private
    mNodeCount: byte;
    mInterval: Int64;
    mPerCount: Int64;
    mRandCount: byte;
    mRandRank: byte;
    mRepeat: Word;
    mCheckLevel: byte;
    mCountingTokenId: TTokenTypeId;
    mRegisterConditionId: byte;
    mRegisterConditionParam: TRegisterConditionParam;
    mVoteConditionId: byte;
    mVoteConditionParam: TVoteConditionParam;
    mOwner: TAddress;
    mStakeAmount: TBigInt;
    mExpirationHeight: UInt64;
  public
    constructor Create;
    destructor Destroy; override;
    property NodeCount: byte read mNodeCount write mNodeCount;
    property Interval: Int64 read mInterval write mInterval;
    property PerCount: Int64 read mPerCount write mPerCount;
    property RandCount: byte read mRandCount write mRandCount;
    property RandRank: byte read mRandRank write mRandRank;
    property Repeat: Word read mRepeat write mRepeat;
    property CheckLevel: byte read mCheckLevel write mCheckLevel;
    property CountingTokenId: TTokenTypeId read mCountingTokenId write mCountingTokenId;
    property RegisterConditionId: byte read mRegisterConditionId write mRegisterConditionId;
    property RegisterConditionParam: TRegisterConditionParam read mRegisterConditionParam write mRegisterConditionParam;
    property VoteConditionId: byte read mVoteConditionId write mVoteConditionId;
    property VoteConditionParam: TVoteConditionParam read mVoteConditionParam write mVoteConditionParam;
    property Owner: TAddress read mOwner write mOwner;
    property StakeAmount: TBigInt read mStakeAmount write mStakeAmount;
    property ExpirationHeight: UInt64 read mExpirationHeight write mExpirationHeight;
  end;

  TRegistrationInfo = class
  private
    mBlockProducingAddress: TAddress;
    mStakeAddress: TAddress;
    mAmount: TBigInt;
    mExpirationHeight: UInt64;
    mRewardTime: Int64;
    mRevokeTime: Int64;
    mHistoryAddressList: TArray<TAddress>;
  public
    constructor Create;
    destructor Destroy; override;
    property BlockProducingAddress: TAddress read mBlockProducingAddress write mBlockProducingAddress;
    property StakeAddress: TAddress read mStakeAddress write mStakeAddress;
    property Amount: TBigInt read mAmount write mAmount;
    property ExpirationHeight: UInt64 read mExpirationHeight write mExpirationHeight;
    property RewardTime: Int64 read mRewardTime write mRewardTime;
    property RevokeTime: Int64 read mRevokeTime write mRevokeTime;
    property HistoryAddressList: TArray<TAddress> read mHistoryAddressList write mHistoryAddressList;
  end;

  TGovernanceContractInfo = class
  private
    mConsensusGroupInfoMap: TDictionary<string, TConsensusGroupInfo>;
    mRegistrationInfoMap: TDictionary<string, TDictionary<string, TRegistrationInfo>>;
    mHisNameMap: TDictionary<string, TDictionary<string, string>>;
    mVoteStatusMap: TDictionary<string, TDictionary<string, string>>;
  public
    constructor Create;
    destructor Destroy; override;
    property ConsensusGroupInfoMap: TDictionary<string, TConsensusGroupInfo> read mConsensusGroupInfoMap;
    property RegistrationInfoMap: TDictionary<string, TDictionary<string, TRegistrationInfo>> read mRegistrationInfoMap;
    property HisNameMap: TDictionary<string, TDictionary<string, string>> read mHisNameMap;
    property VoteStatusMap: TDictionary<string, TDictionary<string, string>> read mVoteStatusMap;
  end;

  TTokenInfo = class
  private
    mTokenName: string;
    mTokenSymbol: string;
    mTotalSupply: TBigInt;
    mDecimals: byte;
    mOwner: TAddress;
    mMaxSupply: TBigInt;
    mIsOwnerBurnOnly: boolean;
    mIsReIssuable: boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property TokenName: string read mTokenName write mTokenName;
    property TokenSymbol: string read mTokenSymbol write mTokenSymbol;
    property TotalSupply: TBigInt read mTotalSupply write mTotalSupply;
    property Decimals: byte read mDecimals write mDecimals;
    property Owner: TAddress read mOwner write mOwner;
    property MaxSupply: TBigInt read mMaxSupply write mMaxSupply;
    property IsOwnerBurnOnly: boolean read mIsOwnerBurnOnly write mIsOwnerBurnOnly;
    property IsReIssuable: boolean read mIsReIssuable write mIsReIssuable;
  end;

  TAssetContractInfo = class
  private
    mTokenInfoMap: TDictionary<string, TTokenInfo>;
    mLogList: TObjectList<TGenesisVmLog>;
  public
    constructor Create;
    destructor Destroy; override;
    property TokenInfoMap: TDictionary<string, TTokenInfo> read mTokenInfoMap;
    property LogList: TObjectList<TGenesisVmLog> read mLogList;
  end;

  TStakeInfo = class
  private
    mAmount: TBigInt;
    mExpirationHeight: UInt64;
    mBeneficiary: TAddress;
  public
    constructor Create;
    destructor Destroy; override;
    property Amount: TBigInt read mAmount write mAmount;
    property ExpirationHeight: UInt64 read mExpirationHeight write mExpirationHeight;
    property Beneficiary: TAddress read mBeneficiary write mBeneficiary;
  end;

  TQuotaContractInfo = class
  private
    mStakeInfoMap: TDictionary<string, TObjectList<TStakeInfo>>;
    mStakeBeneficialMap: TDictionary<string, TBigInt>;
  public
    constructor Create;
    destructor Destroy; override;
    property StakeInfoMap: TDictionary<string, TObjectList<TStakeInfo>> read mStakeInfoMap;
    property StakeBeneficialMap: TDictionary<string, TBigInt> read mStakeBeneficialMap;
  end;

  TDexFundContractInfo = class
  private
    mOwner: TAddress;
  public
    property Owner: TAddress read mOwner write mOwner;
  end;

  TGenesis = class
  private
    mGenesisAccountAddress: TAddress;
    mUpgradeCfg: TUpgrade;
    mGovernanceInfo: TGovernanceContractInfo;
    mAssetInfo: TAssetContractInfo;
    mQuotaInfo: TQuotaContractInfo;
    mAccountBalanceMap: TDictionary<string, TDictionary<string, TBigInt>>;
    mDexFundInfo: TDexFundContractInfo;
  public
    constructor Create;
    destructor Destroy; override;
    property GenesisAccountAddress: TAddress read mGenesisAccountAddress write mGenesisAccountAddress;
    property UpgradeCfg: TUpgrade read mUpgradeCfg write mUpgradeCfg;
    property GovernanceInfo: TGovernanceContractInfo read mGovernanceInfo write mGovernanceInfo;
    property AssetInfo: TAssetContractInfo read mAssetInfo write mAssetInfo;
    property QuotaInfo: TQuotaContractInfo read mQuotaInfo write mQuotaInfo;
    property AccountBalanceMap: TDictionary<string, TDictionary<string, TBigInt>> read mAccountBalanceMap;
    property DexFundInfo: TDexFundContractInfo read mDexFundInfo write mDexFundInfo;
  end;

function MakeGenesisConfig(const ParaGenesisFile: string): TGenesis;
function IsCompleteGenesisConfig(const ParaGenesisConfig: TGenesis): boolean;
function GenesisJson: string;
function MockGenesisJson: string;
function MainnetGenesis: TGenesis;
function MockGenesis: TGenesis;

implementation

uses
  System.IOUtils,
  Common.Utils; // Assuming a Crit logger is in here

// Forward declaration for the JSON strings
const
  ConstGenesisJson: string = ''; // TODO: Content from genesis_json.go is too large to be included here. Needs to be loaded from a resource or file.
  ConstMockGenesisJson: string =
  '{' +
  '	"GenesisAccountAddress": "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '	"UpgradeCfg": {' +
  '		"Level": "latest"' +
  '	},' +
  '	"GovernanceInfo": {' +
  '	  "ConsensusGroupInfoMap":{' +
  '		"00000000000000000001":{' +
  '		  "NodeCount": 1,' +
  '		  "Interval":1,' +
  '		  "PerCount":3,' +
  '		  "RandCount":2,' +
  '		  "RandRank":100,' +
  '		  "Repeat":1,' +
  '		  "CheckLevel":0,' +
  '		  "CountingTokenId":"tti_5649544520544f4b454e6e40",' +
  '		  "RegisterConditionId":1,' +
  '		  "RegisterConditionParam":{' +
  '			"StakeAmount": 100000000000000000000000,' +
  '			"StakeHeight": 1,' +
  '			"StakeToken": "tti_5649544520544f4b454e6e40"' +
  '		  },' +
  '		  "VoteConditionId":1,' +
  '		  "VoteConditionParam":{},' +
  '		  "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '		  "StakeAmount":0,' +
  '		  "ExpirationHeight":1' +
  '		},' +
  '		"00000000000000000002":{' +
  '		  "NodeCount": 1,' +
  '		  "Interval":3,' +
  '		  "PerCount":1,' +
  '		  "RandCount":2,' +
  '		  "RandRank":100,' +
  '		  "Repeat":48,' +
  '		  "CheckLevel":1,' +
  '		  "CountingTokenId":"tti_5649544520544f4b454e6e40",' +
  '		  "RegisterConditionId":1,' +
  '		  "RegisterConditionParam":{' +
  '			"StakeAmount": 100000000000000000000000,' +
  '			"StakeHeight": 1,' +
  '			"StakeToken": "tti_5649544520544f4b454e6e40"' +
  '		  },' +
  '		  "VoteConditionId":1,' +
  '		  "VoteConditionParam":{},' +
  '		  "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '		  "StakeAmount":0,' +
  '		  "ExpirationHeight":1' +
  '		}' +
  '	  },' +
  '	  "RegistrationInfoMap":{' +
  '		"00000000000000000001":{' +
  '		  "s1":{' +
  '			"BlockProducingAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a",' +
  '			"StakeAddress":"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a",' +
  '			"Amount":100000000000000000000000,' +
  '			"ExpirationHeight":7776000,' +
  '			"RewardTime":1,' +
  '			"RevokeTime":0,' +
  '			"HistoryAddressList":["vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a"]' +
  '		  }' +
  '		}' +
  '	  }' +
  '	},' +
  '	"AssetInfo":{' +
  '	  "TokenInfoMap":{' +
  '		"tti_5649544520544f4b454e6e40":{' +
  '		  "TokenName":"Vite Token",' +
  '		  "TokenSymbol":"VITE",' +
  '		  "TotalSupply":1000000000000000000000000000,' +
  '		  "Decimals":18,' +
  '		  "Owner":"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a",' +
  '		  "MaxSupply":115792089237316195423570985008687907853269984665640564039457584007913129639935,' +
  '		  "IsOwnerBurnOnly":false,' +
  '		  "IsReIssuable":true' +
  '		}' +
  '	  },' +
  '	  "LogList": [' +
  '		{' +
  '		  "Data": "",' +
  '		  "Topics": [' +
  '			"3f9dcc00d5e929040142c3fb2b67a3be1b0e91e98dac18d5bc2b7817a4cfecb6",' +
  '			"000000000000000000000000000000000000000000005649544520544f4b454e"' +
  '		  ]' +
  '		}' +
  '	  ]' +
  '	},' +
  '	"QuotaInfo": {' +
  '	  "StakeInfoMap": {' +
  '		"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a": [' +
  '		  {' +
  '			"Amount": 1000000000000000000000,' +
  '			"ExpirationHeight": 259200,' +
  '			"Beneficiary": "vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a"' +
  '		  },' +
  '		  {' +
  '			"Amount": 1000000000000000000000,' +
  '			"ExpirationHeight": 259200,' +
  '			"Beneficiary": "vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25"' +
  '		  },' +
  '		  {' +
  '			"Amount": 1000000000000000000000,' +
  '			"ExpirationHeight": 259200,' +
  '			"Beneficiary": "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a"' +
  '		  },' +
  '		  {' +
  '			"Amount": 1000000000000000000000,' +
  '			"ExpirationHeight": 259200,' +
  '			"Beneficiary": "vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23"' +
  '		  }' +
  '		]' +
  '	  },' +
  '	  "StakeBeneficialMap":{' +
  '		"vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a":1000000000000000000000,' +
  '		"vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25":1000000000000000000000,' +
  '		"vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a":1000000000000000000000,' +
  '		"vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23":1000000000000000000000' +
  '	  }' +
  '	},' +
  '	"AccountBalanceMap": {' +
  '	  "vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a": {' +
  '		"tti_5649544520544f4b454e6e40":99996000000000000000000000' +
  '	  },' +
  '	  "vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23": {' +
  '		"tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '	  },' +
  '	  "vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a": {' +
  '		"tti_5649544520544f4b454e6e40":600000000000000000000000000' +
  '	  },' +
  '	  "vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25": {' +
  '		"tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '	  },' +
  '	  "vite_847e1672c9a775ca0f3c3a2d3bf389ca466e5501cbecdb7107": {' +
  '		"tti_5649544520544f4b454e6e40":100000000000000000000000000' +
  '	  }' +
  '	}' +
  '  }';

{ TRegisterConditionParam }
constructor TRegisterConditionParam.Create;
begin
  inherited Create;
  mStakeAmount := TBigInt.Create;
end;

destructor TRegisterConditionParam.Destroy;
begin
  mStakeAmount.Free;
  inherited Destroy;
end;

{ TConsensusGroupInfo }
constructor TConsensusGroupInfo.Create;
begin
  inherited Create;
  mRegisterConditionParam := TRegisterConditionParam.Create;
  mVoteConditionParam := TVoteConditionParam.Create;
  mStakeAmount := TBigInt.Create;
end;

destructor TConsensusGroupInfo.Destroy;
begin
  mRegisterConditionParam.Free;
  mVoteConditionParam.Free;
  mStakeAmount.Free;
  inherited Destroy;
end;

{ TRegistrationInfo }
constructor TRegistrationInfo.Create;
begin
  inherited Create;
  mAmount := TBigInt.Create;
end;

destructor TRegistrationInfo.Destroy;
begin
  mAmount.Free;
  inherited Destroy;
end;

{ TGovernanceContractInfo }
constructor TGovernanceContractInfo.Create;
begin
  inherited Create;
  mConsensusGroupInfoMap := TDictionary<string, TConsensusGroupInfo>.Create;
  mRegistrationInfoMap := TDictionary<string, TDictionary<string, TRegistrationInfo>>.Create;
  mHisNameMap := TDictionary<string, TDictionary<string, string>>.Create;
  mVoteStatusMap := TDictionary<string, TDictionary<string, string>>.Create;
end;

destructor TGovernanceContractInfo.Destroy;
begin
  mConsensusGroupInfoMap.Free;
  mRegistrationInfoMap.Free;
  mHisNameMap.Free;
  mVoteStatusMap.Free;
  inherited Destroy;
end;

{ TTokenInfo }
constructor TTokenInfo.Create;
begin
  inherited Create;
  mTotalSupply := TBigInt.Create;
  mMaxSupply := TBigInt.Create;
end;

destructor TTokenInfo.Destroy;
begin
  mTotalSupply.Free;
  mMaxSupply.Free;
  inherited Destroy;
end;

{ TAssetContractInfo }
constructor TAssetContractInfo.Create;
begin
  inherited Create;
  mTokenInfoMap := TDictionary<string, TTokenInfo>.Create;
  mLogList := TObjectList<TGenesisVmLog>.Create(True); // True owns the objects
end;

destructor TAssetContractInfo.Destroy;
begin
  mTokenInfoMap.Free;
  mLogList.Free;
  inherited Destroy;
end;

{ TStakeInfo }
constructor TStakeInfo.Create;
begin
  inherited Create;
  mAmount := TBigInt.Create;
end;

destructor TStakeInfo.Destroy;
begin
  mAmount.Free;
  inherited Destroy;
end;

{ TQuotaContractInfo }
constructor TQuotaContractInfo.Create;
begin
  inherited Create;
  mStakeInfoMap := TDictionary<string, TObjectList<TStakeInfo>>.Create;
  mStakeBeneficialMap := TDictionary<string, TBigInt>.Create;
end;

destructor TQuotaContractInfo.Destroy;
begin
  mStakeInfoMap.Free;
  mStakeBeneficialMap.Free;
  inherited Destroy;
end;

{ TGenesis }
constructor TGenesis.Create;
begin
  inherited Create;
  mUpgradeCfg := TUpgrade.Create;
  mGovernanceInfo := TGovernanceContractInfo.Create;
  mAssetInfo := TAssetContractInfo.Create;
  mQuotaInfo := TQuotaContractInfo.Create;
  mAccountBalanceMap := TDictionary<string, TDictionary<string, TBigInt>>.Create;
  mDexFundInfo := TDexFundContractInfo.Create;
end;

destructor TGenesis.Destroy;
begin
  mUpgradeCfg.Free;
  mGovernanceInfo.Free;
  mAssetInfo.Free;
  mQuotaInfo.Free;
  mAccountBalanceMap.Free;
  mDexFundInfo.Free;
  inherited Destroy;
end;

function MakeGenesisConfig(const ParaGenesisFile: string): TGenesis;
var
  vJson: string;
begin
  if ParaGenesisFile <> '' then
  begin
    try
      if not TFile.Exists(ParaGenesisFile) then
      begin
        LogCrit(Format('Failed to read genesis file: %s', [ParaGenesisFile]), 'readGenesis');
        Exit(nil);
      end;
      vJson := TFile.ReadAllText(ParaGenesisFile);
    except
      on E: Exception do
      begin
        LogCrit(Format('Failed to read genesis file: %s', [E.Message]), 'readGenesis');
        Exit(nil);
      end;
    end;
  end
  else
  begin
    vJson := GenesisJson;
  end;

  try
    Result := TJson.JsonToObject<TGenesis>(vJson);
    if not IsCompleteGenesisConfig(Result) then
    begin
      LogCrit('Invalid genesis file, genesis account info is not complete', 'readGenesis');
      Result.Free; // Prevent memory leak
      Exit(nil);
    end;
  except
    on E: Exception do
    begin
      LogCrit(Format('Invalid genesis file: %s', [E.Message]), 'readGenesis');
      Exit(nil);
    end;
  end;
end;

function IsCompleteGenesisConfig(const ParaGenesisConfig: TGenesis): boolean;
begin
  if (ParaGenesisConfig = nil) or
     (ParaGenesisConfig.GovernanceInfo = nil) or (ParaGenesisConfig.GovernanceInfo.ConsensusGroupInfoMap.Count = 0) or
     (ParaGenesisConfig.GovernanceInfo.RegistrationInfoMap.Count = 0) or
     (ParaGenesisConfig.AssetInfo = nil) or (ParaGenesisConfig.AssetInfo.TokenInfoMap.Count = 0) or
     (ParaGenesisConfig.AccountBalanceMap.Count = 0) then
  begin
    Result := False;
  end
  else
  begin
    Result := True;
  end;
end;

function GenesisJson: string;
begin
  Result := ConstGenesisJson;
end;

function MockGenesisJson: string;
begin
  Result := ConstMockGenesisJson;
end;

function MainnetGenesis: TGenesis;
begin
  try
    Result := TJson.JsonToObject<TGenesis>(GenesisJson);
  except
    on E: Exception do
    begin
      // In a real scenario, you might panic or log a fatal error.
      raise Exception.Create('Failed to unmarshal mainnet genesis: ' + E.Message);
    end;
  end;
end;

function MockGenesis: TGenesis;
begin
  try
    Result := TJson.JsonToObject<TGenesis>(MockGenesisJson);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to unmarshal mock genesis: ' + E.Message);
    end;
  end;
end;

end.