{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesZosS390x;

interface

// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Hand edited based on ztypes_linux_s390x.go
// TODO: auto-generate.

{$IFDEF FPC}
uses
  SysUtils;
{$ELSE}
uses
  System.SysUtils;
{$ENDIF}

const
    ConstSizeofPtr = $8;
    ConstSizeofShort = $2;
    ConstSizeofInt = $4;
    ConstSizeofLong = $8;
    ConstSizeofLongLong = $8;
    Const_PathMax = $1000;

    ConstSizeofSockaddrAny = 128;
    ConstSizeofCmsghdr = 12;
    ConstSizeofIPMreq = 8;
    ConstSizeofIPv6Mreq = 20;
    ConstSizeofICMPv6Filter = 32;
    ConstSizeofIPv6MTUInfo = 32;
    ConstSizeofLinger = 8;
    ConstSizeofSockaddrInet4 = 16;
    ConstSizeofSockaddrInet6 = 28;
    ConstSizeofTCPInfo = $68;

type
    // Basic C-type aliases
    C_short = SmallInt;
    C_int = Integer;
    C_long = Int64;
    C_long_long = Int64;

    // Forward declarations for pointers
    PTimespec = ^TTimespec;
    PTimeval = ^TTimeval;
    PTimeval_zos = ^TTimeval_zos;
    PTms = ^TTms;
    PTime_t = ^TTime_t;
    PUtimbuf = ^TUtimbuf;
    PUtsname = ^TUtsname;
    PRawSockaddrInet4 = ^TRawSockaddrInet4;
    PRawSockaddrInet6 = ^TRawSockaddrInet6;
    PRawSockaddrUnix = ^TRawSockaddrUnix;
    PRawSockaddr = ^TRawSockaddr;
    PRawSockaddrAny = ^TRawSockaddrAny;
    PLinger = ^TLinger;
    PIovec = ^TIovec;
    PIPMreq = ^TIPMreq;
    PIPv6Mreq = ^TIPv6Mreq;
    PMsghdr = ^TMsghdr;
    PCmsghdr = ^TCmsghdr;
    PInet4Pktinfo = ^TInet4Pktinfo;
    PInet6Pktinfo = ^TInet6Pktinfo;
    PIPv6MTUInfo = ^TIPv6MTUInfo;
    PICMPv6Filter = ^TICMPv6Filter;
    PTCPInfo = ^TTCPInfo;
    PGid_t = ^TGid_t;
    PRusage_zos = ^TRusage_zos;
    PRusage = ^TRusage;
    PRlimit = ^TRlimit;
    PPollFd = ^TPollFd;
    PStat_t = ^TStat_t;
    PStat_LE_t = ^TStat_LE_t;
    PStatvfs_t = ^TStatvfs_t;
    PStatfs_t = ^TStatfs_t;
    PDirent = ^TDirent;
    PFdSet = ^TFdSet;
    PFlock_t = ^TFlock_t;
    PTermios = ^TTermios;
    PWinsize = ^TWinsize;
    PW_Mnth = ^TW_Mnth;
    PW_Mntent = ^TW_Mntent;

    TTimespec = record
        mSec : Int64;
        mNsec : Int64;
    end;

    TTimeval = record
        mSec : Int64;
        mUsec : Int64;
    end;

    // correct (with padding and all)
    TTimeval_zos = record
        mSec : Int64;
        m_pad : array[0..3] of Byte; // [4]byte // pad
        mUsec : Integer; // int32
    end;

    // clock_t is 4-byte unsigned int in zos
    TTms = record
        mUtime : Cardinal; // uint32
        mStime : Cardinal; // uint32
        mCutime : Cardinal; // uint32
        mCstime : Cardinal; // uint32
    end;

    TTime_t = Int64;

    TUtimbuf = record
        mActime : Int64;
        mModtime : Int64;
    end;

    TUtsname = record
        mSysname : array[0..64] of Byte; // [65]byte
        mNodename : array[0..64] of Byte; // [65]byte
        mRelease : array[0..64] of Byte; // [65]byte
        mVersion : array[0..64] of Byte; // [65]byte
        mMachine : array[0..64] of Byte; // [65]byte
        mDomainname : array[0..64] of Byte; // [65]byte
    end;

    TRawSockaddrInet4 = record
        mLen : Byte;
        mFamily : Byte;
        mPort : Word;
        mAddr : array[0..3] of Byte; // [4]byte /* in_addr */
        mZero : array[0..7] of Byte; // [8]uint8
    end;

    TRawSockaddrInet6 = record
        mLen : Byte;
        mFamily : Byte;
        mPort : Word;
        mFlowinfo : Cardinal;
        mAddr : array[0..15] of Byte; // [16]byte /* in6_addr */
        mScope_id : Cardinal;
    end;

    TRawSockaddrUnix = record
        mLen : Byte;
        mFamily : Byte;
        mPath : array[0..107] of AnsiChar; // [108]int8
    end;

    TRawSockaddr = record
        mLen : Byte;
        mFamily : Byte;
        mData : array[0..13] of Byte; // [14]uint8
    end;

    TRawSockaddrAny = record
        mAddr : TRawSockaddr;
        m_pad : array[0..111] of Byte; // [112]uint8 // pad
    end;

    TSocklen = Cardinal;

    TLinger = record
        mOnoff : Integer;
        mLinger : Integer;
    end;

    TIovec = record
        mBase : PByte; // *byte
        mLen : UInt64;
    end;

    TIPMreq = record
        mMultiaddr : array[0..3] of Byte; // [4]byte /* in_addr */
        mInterface : array[0..3] of Byte; // [4]byte /* in_addr */
    end;

    TIPv6Mreq = record
        mMultiaddr : array[0..15] of Byte; // [16]byte /* in6_addr */
        mInterface : Cardinal; // uint32
    end;

    TMsghdr = record
        mName : PByte; // *byte
        mIov : PIovec;
        mControl : PByte; // *byte
        mFlags : Integer;
        mNamelen : Integer;
        mIovlen : Integer;
        mControllen : Integer;
    end;

    TCmsghdr = record
        mLen : Integer;
        mLevel : Integer;
        mType : Integer;
    end;

    TInet4Pktinfo = record
        mAddr : array[0..3] of Byte; // [4]byte /* in_addr */
        mIfindex : Cardinal; // uint32
    end;

    TInet6Pktinfo = record
        mAddr : array[0..15] of Byte; // [16]byte /* in6_addr */
        mIfindex : Cardinal; // uint32
    end;

    TIPv6MTUInfo = record
        mAddr : TRawSockaddrInet6;
        mMtu : Cardinal; // uint32
    end;

    TICMPv6Filter = record
        mData : array[0..7] of Cardinal; // [8]uint32
    end;

    TTCPInfo = record
        mState : Byte;
        mCa_state : Byte;
        mRetransmits : Byte;
        mProbes : Byte;
        mBackoff : Byte;
        mOptions : Byte;
        mRto : Cardinal; // uint32
        mAto : Cardinal; // uint32
        mSnd_mss : Cardinal; // uint32
        mRcv_mss : Cardinal; // uint32
        mUnacked : Cardinal; // uint32
        mSacked : Cardinal; // uint32
        mLost : Cardinal; // uint32
        mRetrans : Cardinal; // uint32
        mFackets : Cardinal; // uint32
        mLast_data_sent : Cardinal; // uint32
        mLast_ack_sent : Cardinal; // uint32
        mLast_data_recv : Cardinal; // uint32
        mLast_ack_recv : Cardinal; // uint32
        mPmtu : Cardinal; // uint32
        mRcv_ssthresh : Cardinal; // uint32
        mRtt : Cardinal; // uint32
        mRttvar : Cardinal; // uint32
        mSnd_ssthresh : Cardinal; // uint32
        mSnd_cwnd : Cardinal; // uint32
        mAdvmss : Cardinal; // uint32
        mReordering : Cardinal; // uint32
        mRcv_rtt : Cardinal; // uint32
        mRcv_space : Cardinal; // uint32
        mTotal_retrans : Cardinal; // uint32
    end;

    TGid_t = Cardinal; // uint32

    Trusage_zos = record
        mUtime : TTimeval_zos;
        mStime : TTimeval_zos;
    end;

    TRusage = record
        mUtime : TTimeval;
        mStime : TTimeval;
        mMaxrss : Int64;
        mIxrss : Int64;
        mIdrss : Int64;
        mIsrss : Int64;
        mMinflt : Int64;
        mMajflt : Int64;
        mNswap : Int64;
        mInblock : Int64;
        mOublock : Int64;
        mMsgsnd : Int64;
        mMsgrcv : Int64;
        mNsignals : Int64;
        mNvcsw : Int64;
        mNivcsw : Int64;
    end;

    TRlimit = record
        mCur : UInt64;
        mMax : UInt64;
    end;

    // { int, short, short } in poll.h
    TPollFd = record
        mFd : Integer; // int32
        mEvents : SmallInt; // int16
        mRevents : SmallInt; // int16
    end;

    // Linux Definition
    TStat_t = record
        mDev : UInt64;
        mIno : UInt64;
        mNlink : UInt64;
        mMode : Cardinal; // uint32
        mUid : Cardinal; // uint32
        mGid : Cardinal; // uint32
        m_pad1 : Integer; // int32
        mRdev : UInt64;
        mSize : Int64;
        mAtim : TTimespec;
        mMtim : TTimespec;
        mCtim : TTimespec;
        mBlksize : Int64;
        mBlocks : Int64;
        m_pad2 : array[0..2] of Int64; // [3]int64
    end;

    // File_tag struct embedded in Stat_LE_t
    TFile_tag = packed record
        mCcsid : Word; // uint16
        mTxtflag : Word; // uint16 // aggregating Txflag:1 deferred:1 rsvflags:14
    end;

    TStat_LE_t = packed record // Go Struct is packed/aligned implicitly. Delphi uses packed record for C-struct alignment.
        m_eye_catcher : array[0..3] of Byte; // [4]byte // eye catcher
        mLength : Word; // uint16
        mVersion : Word; // uint16
        mMode : Integer; // int32
        mIno : Cardinal; // uint32
        mDev : Cardinal; // uint32
        mNlink : Integer; // int32
        mUid : Integer; // int32
        mGid : Integer; // int32
        mSize : Int64;
        mAtim31 : array[0..3] of Byte; // [4]byte
        mMtim31 : array[0..3] of Byte; // [4]byte
        mCtim31 : array[0..3] of Byte; // [4]byte
        mRdev : Cardinal; // uint32
        mAuditoraudit : Cardinal; // uint32
        mUseraudit : Cardinal; // uint32
        mBlksize : Integer; // int32
        mCreatim31 : array[0..3] of Byte; // [4]byte
        mAuditID : array[0..15] of Byte; // [16]byte
        m_rsrvd1 : array[0..3] of Byte; // [4]byte // rsrvd1
        mFile_tag : TFile_tag;
        mCharsetID : array[0..7] of Byte; // [8]byte
        mBlocks : Int64;
        mGenvalue : Cardinal; // uint32
        mReftim31 : array[0..3] of Byte; // [4]byte
        mFid : array[0..7] of Byte; // [8]byte
        mFilefmt : Byte;
        mFspflag2 : Byte;
        m_rsrvd2 : array[0..1] of Byte; // [2]byte // rsrvd2
        mCtimemsec : Integer; // int32
        mSeclabel : array[0..7] of Byte; // [8]byte
        m_rsrvd3 : array[0..3] of Byte; // [4]byte // rsrvd3
        m_rsrvd4 : array[0..3] of Byte; // [4]byte // rsrvd4
        mAtim : TTime_t;
        mMtim : TTime_t;
        mCtim : TTime_t;
        mCreatim : TTime_t;
        mReftim : TTime_t;
        m_rsrvd5 : array[0..23] of Byte; // [24]byte // rsrvd5
    end;

    TStatvfs_t = record
        mID : array[0..3] of Byte; // [4]byte
        mLen : Integer; // int32
        mBsize : UInt64;
        mBlocks : UInt64;
        mUsedspace : UInt64;
        mBavail : UInt64;
        mFlag : UInt64;
        mMaxfilesize : Int64;
        m_pad1 : array[0..15] of Byte; // [16]byte
        mFrsize : UInt64;
        mBfree : UInt64;
        mFiles : Cardinal; // uint32
        mFfree : Cardinal; // uint32
        mFavail : Cardinal; // uint32
        mNamemax31 : Cardinal; // uint32
        mInvarsec : Cardinal; // uint32
        m_pad2 : array[0..3] of Byte; // [4]byte
        mFsid : UInt64;
        mNamemax : UInt64;
    end;

    TStatfs_t = record
        mType : Cardinal; // uint32
        mBsize : UInt64;
        mBlocks : UInt64;
        mBfree : UInt64;
        mBavail : UInt64;
        mFiles : Cardinal; // uint32
        mFfree : Cardinal; // uint32
        mFsid : UInt64;
        mNamelen : UInt64;
        mFrsize : UInt64;
        mFlags : UInt64;
    end;

    TDirent = record
        mReclen : Word; // uint16
        mNamlen : Word; // uint16
        mIno : Cardinal; // uint32
        mExtra : NativeUInt; // uintptr
        mName : array[0..255] of Byte; // [256]byte
    end;

    TFdSet = record
        mBits : array[0..63] of Integer; // [64]int32
    end;

    // This struct is packed on z/OS so it can't be used directly.
    TFlock_t = record
        mType : SmallInt; // int16
        mWhence : SmallInt; // int16
        mStart : Int64;
        mLen : Int64;
        mPid : Integer; // int32
    end;

    TTermios = record
        mCflag : Cardinal; // uint32
        mIflag : Cardinal; // uint32
        mLflag : Cardinal; // uint32
        mOflag : Cardinal; // uint32
        mCc : array[0..10] of Byte; // [11]uint8
    end;

    TWinsize = record
        mRow : Word; // uint16
        mCol : Word; // uint16
        mXpixel : Word; // uint16
        mYpixel : Word; // uint16
    end;

    TW_Mnth = record
        mHid : array[0..3] of Byte; // [4]byte
        mSize : Integer; // int32
        mCur1 : Integer; // int32 // 32bit pointer
        mCur2 : Integer; // int32 // ^
        mDevno : Cardinal; // uint32
        m_pad : array[0..3] of Byte; // [4]byte
    end;

    TW_Mntent = record
        mFstype : Cardinal; // uint32
        mMode : Cardinal; // uint32
        mDev : Cardinal; // uint32
        mParentdev : Cardinal; // uint32
        mRootino : Cardinal; // uint32
        mStatus : Byte;
        mDdname : array[0..8] of Byte; // [9]byte
        mFstname : array[0..8] of Byte; // [9]byte
        mFsname : array[0..44] of Byte; // [45]byte
        mPathlen : Cardinal; // uint32
        mMountpoint : array[0..1023] of Byte; // [1024]byte
        mJobname : array[0..7] of Byte; // [8]byte
        mPID : Integer; // int32
        mParmoffset : Integer; // int32
        mParmlen : SmallInt; // int16
        mOwner : array[0..7] of Byte; // [8]byte
        mQuiesceowner : array[0..7] of Byte; // [8]byte
        m_pad : array[0..37] of Byte; // [38]byte
    end;

implementation

end.