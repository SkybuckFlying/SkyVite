unit Common.Types.Contracts;

interface

uses
  System.Math.BigInts,
  Common.Bytes,
  Common.Types.Address,
  Common.Types.Gid,
  Common.Types.TokenTypeId,
  Common.Types.Hash;

type
  PHash = ^THash;

  TConsensusGroupInfo = record
    mGid: TGid;
    mNodeCount: Byte;
    mInterval: Int64;
    mPerCount: Int64;
    mRandCount: Byte;
    mRandRank: Byte;
    mRepeat: Word;
    mCheckLevel: Byte;
    mCountingTokenId: TTokenTypeId;
    mRegisterConditionId: Byte;
    mRegisterConditionParam: TBytes;
    mVoteConditionId: Byte;
    mVoteConditionParam: TBytes;
    mOwner: TAddress;
    mStakeAmount: TBigInteger;
    mExpirationHeight: UInt64;
    function IsActive: Boolean;
  end;

  TVoteInfo = record
    mVoteAddr: TAddress;
    mSbpName: string;
  end;

  TRegistration = record
    mName: string;
    mBlockProducingAddress: TAddress;
    mRewardWithdrawAddress: TAddress;
    mStakeAddress: TAddress;
    mAmount: TBigInteger;
    mExpirationHeight: UInt64;
    mRewardTime: Int64;
    mRevokeTime: Int64;
    mHisAddrList: TArray<TAddress>;
    function IsActive: Boolean;
  end;

  TTokenInfo = record
    mTokenName: string;
    mTokenSymbol: string;
    mTotalSupply: TBigInteger;
    mDecimals: Byte;
    mOwner: TAddress;
    mMaxSupply: TBigInteger;
    mOwnerBurnOnly: Boolean;
    mIsReIssuable: Boolean;
    mIndex: Word;
  end;

  TStakeInfo = record
    mAmount: TBigInteger;
    mExpirationHeight: UInt64;
    mBeneficiary: TAddress;
    mIsDelegated: Boolean;
    mDelegateAddress: TAddress;
    mBid: Byte;
    mStakeAddress: TAddress;
    mId: PHash;
  end;

implementation

{ TConsensusGroupInfo }

function TConsensusGroupInfo.IsActive: Boolean;
begin
  Result := mExpirationHeight > 0;
end;

{ TRegistration }

function TRegistration.IsActive: Boolean;
begin
  Result := mRevokeTime = 0;
end;

end.
