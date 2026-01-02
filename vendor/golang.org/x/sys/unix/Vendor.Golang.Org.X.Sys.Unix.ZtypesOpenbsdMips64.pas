{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsdMips64;

interface

{$IFDEF FPC}
uses
  SysUtils;
{$ELSE}
uses
  System.SysUtils;
{$ENDIF}

const
    ConstSizeofPtr      = $8;
    ConstSizeofShort    = $2;
    ConstSizeofInt      = $4;
    ConstSizeofLong     = $8;
    ConstSizeofLongLong = $8;

type
    _C_short     = Int16;
    _C_int       = Int32;
    _C_long      = Int64;
    _C_long_long = Int64;

    Timespec = record
        mSec  : Int64;
        mNsec : Int64;
    end;

    Timeval = record
        mSec  : Int64;
        mUsec : Int64;
    end;

    Rusage = record
        mUtime    : Timeval;
        mStime    : Timeval;
        mMaxrss   : Int64;
        mIxrss    : Int64;
        mIdrss    : Int64;
        mIsrss    : Int64;
        mMinflt   : Int64;
        mMajflt   : Int64;
        mNswap    : Int64;
        mInblock  : Int64;
        mOublock  : Int64;
        mMsgsnd   : Int64;
        mMsgrcv   : Int64;
        mNsignals : Int64;
        mNvcsw    : Int64;
        mNivcsw   : Int64;
    end;

    Rlimit = record
        mCur : UInt64;
        mMax : UInt64;
    end;

    _Gid_t = UInt32;

    Stat_t = record
        mMode    : UInt32;
        mDev     : Int32;
        mIno     : UInt64;
        mNlink   : UInt32;
        mUid     : UInt32;
        mGid     : UInt32;
        mRdev    : Int32;
        mAtim    : Timespec;
        mMtim    : Timespec;
        mCtim    : Timespec;
        mSize    : Int64;
        mBlocks  : Int64;
        mBlksize : Int32;
        mFlags   : UInt32;
        mGen     : UInt32;
        m_       : Timespec;
    end;

    Fsid = record
        mVal : array[0..1] of Int32;
    end;

    Statfs_t = record
        mF_flags       : UInt32;
        mF_bsize       : UInt32;
        mF_iosize      : UInt32;
        mF_blocks      : UInt64;
        mF_bfree       : UInt64;
        mF_bavail      : Int64;
        mF_files       : UInt64;
        mF_ffree       : UInt64;
        mF_favail      : Int64;
        mF_syncwrites  : UInt64;
        mF_syncreads   : UInt64;
        mF_asyncwrites : UInt64;
        mF_asyncreads  : UInt64;
        mF_fsid        : Fsid;
        mF_namemax     : UInt32;
        mF_owner       : UInt32;
        mF_ctime       : UInt64;
        mF_fstypename  : array[0..15] of Int8;
        mF_mntonname   : array[0..89] of Int8;
        mF_mntfromname : array[0..89] of Int8;
        mF_mntfromspec : array[0..89] of Int8;
        m_             : array[0..1] of Byte;
        mMount_info    : array[0..159] of Byte;
    end;

    Flock_t = record
        mStart  : Int64;
        mLen    : Int64;
        mPid    : Int32;
        mType   : Int16;
        mWhence : Int16;
    end;

    Dirent = record
        mFileno : UInt64;
        mOff    : Int64;
        mReclen : UInt16;
        mType   : UInt8;
        mNamlen : UInt8;
        m_      : array[0..3] of UInt8;
        mName   : array[0..255] of Int8;
    end;

const
    ConstPathMax = $400;

type
    RawSockaddrInet4 = record
        mLen    : UInt8;
        mFamily : UInt8;
        mPort   : UInt16;
        mAddr   : array[0..3] of Byte; { in_addr }
        mZero   : array[0..7] of Int8;
    end;

    RawSockaddrInet6 = record
        mLen      : UInt8;
        mFamily   : UInt8;
        mPort     : UInt16;
        mFlowinfo : UInt32;
        mAddr     : array[0..15] of Byte; { in6_addr }
        mScope_id : UInt32;
    end;

    RawSockaddrUnix = record
        mLen    : UInt8;
        mFamily : UInt8;
        mPath   : array[0..103] of Int8;
    end;

    RawSockaddrDatalink = record
        mLen    : UInt8;
        mFamily : UInt8;
        mIndex  : UInt16;
        mType   : UInt8;
        mNlen   : UInt8;
        mAlen   : UInt8;
        mSlen   : UInt8;
        mData   : array[0..23] of Int8;
    end;

    RawSockaddr = record
        mLen    : UInt8;
        mFamily : UInt8;
        mData   : array[0..13] of Int8;
    end;

    RawSockaddrAny = record
        mAddr : RawSockaddr;
        mPad  : array[0..91] of Int8;
    end;

    _Socklen = UInt32;

    Linger = record
        mOnoff  : Int32;
        mLinger : Int32;
    end;

    Iovec = record
        mBase : PByte;
        mLen  : UInt64;
    end;
    PIovec = ^Iovec;

    IPMreq = record
        mMultiaddr : array[0..3] of Byte; { in_addr }
        mInterface : array[0..3] of Byte; { in_addr }
    end;

    IPv6Mreq = record
        mMultiaddr : array[0..15] of Byte; { in6_addr }
        mInterface : UInt32;
    end;

    Msghdr = record
        mName       : PByte;
        mNamelen    : UInt32;
        mIov        : PIovec;
        mIovlen     : UInt32;
        mControl    : PByte;
        mControllen : UInt32;
        mFlags      : Int32;
    end;

    Cmsghdr = record
        mLen   : UInt32;
        mLevel : Int32;
        mType  : Int32;
    end;

    Inet6Pktinfo = record
        mAddr    : array[0..15] of Byte; { in6_addr }
        mIfindex : UInt32;
    end;

    IPv6MTUInfo = record
        mAddr : RawSockaddrInet6;
        mMtu  : UInt32;
    end;

    ICMPv6Filter = record
        mFilt : array[0..7] of UInt32;
    end;

const
    ConstSizeofSockaddrInet4    = $10;
    ConstSizeofSockaddrInet6    = $1c;
    ConstSizeofSockaddrAny      = $6c;
    ConstSizeofSockaddrUnix     = $6a;
    ConstSizeofSockaddrDatalink = $20;
    ConstSizeofLinger           = $8;
    ConstSizeofIovec            = $10;
    ConstSizeofIPMreq           = $8;
    ConstSizeofIPv6Mreq         = $14;
    ConstSizeofMsghdr           = $30;
    ConstSizeofCmsghdr          = $c;
    ConstSizeofInet6Pktinfo     = $14;
    ConstSizeofIPv6MTUInfo      = $20;
    ConstSizeofICMPv6Filter     = $20;

    ConstPTRACE_TRACEME = $0;
    ConstPTRACE_CONT    = $7;
    ConstPTRACE_KILL    = $8;

type
    Kevent_t = record
        mIdent  : UInt64;
        mFilter : Int16;
        mFlags  : UInt16;
        mFflags : UInt32;
        mData   : Int64;
        mUdata  : PByte;
    end;

    FdSet = record
        mBits : array[0..31] of UInt32;
    end;

const
    ConstSizeofIfMsghdr         = $a8;
    ConstSizeofIfData           = $90;
    ConstSizeofIfaMsghdr        = $18;
    ConstSizeofIfAnnounceMsghdr = $1a;
    ConstSizeofRtMsghdr         = $60;
    ConstSizeofRtMetrics        = $38;

type
    Mclpool = record
    end;

    IfData = record
        mType         : UInt8;
        mAddrlen      : UInt8;
        mHdrlen       : UInt8;
        mLink_state   : UInt8;
        mMtu          : UInt32;
        mMetric       : UInt32;
        mRdomain      : UInt32;
        mBaudrate     : UInt64;
        mIpackets     : UInt64;
        mIerrors      : UInt64;
        mOpackets     : UInt64;
        mOerrors      : UInt64;
        mCollisions   : UInt64;
        mIbytes       : UInt64;
        mObytes       : UInt64;
        mImcasts      : UInt64;
        mOmcasts      : UInt64;
        mIqdrops      : UInt64;
        mOqdrops      : UInt64;
        mNoproto      : UInt64;
        mCapabilities : UInt32;
        mLastchange   : Timeval;
    end;

    IfMsghdr = record
        mMsglen  : UInt16;
        mVersion : UInt8;
        mType    : UInt8;
        mHdrlen  : UInt16;
        mIndex   : UInt16;
        mTableid : UInt16;
        mPad1    : UInt8;
        mPad2    : UInt8;
        mAddrs   : Int32;
        mFlags   : Int32;
        mXflags  : Int32;
        mData    : IfData;
    end;

    IfaMsghdr = record
        mMsglen  : UInt16;
        mVersion : UInt8;
        mType    : UInt8;
        mHdrlen  : UInt16;
        mIndex   : UInt16;
        mTableid : UInt16;
        mPad1    : UInt8;
        mPad2    : UInt8;
        mAddrs   : Int32;
        mFlags   : Int32;
        mMetric  : Int32;
    end;

    IfAnnounceMsghdr = record
        mMsglen  : UInt16;
        mVersion : UInt8;
        mType    : UInt8;
        mHdrlen  : UInt16;
        mIndex   : UInt16;
        mWhat    : UInt16;
        mName    : array[0..15] of Int8;
    end;

    RtMetrics = record
        mPksent   : UInt64;
        mExpire   : Int64;
        mLocks    : UInt32;
        mMtu      : UInt32;
        mRefcnt   : UInt32;
        mHopcount : UInt32;
        mRecvpipe : UInt32;
        mSendpipe : UInt32;
        mSsthresh : UInt32;
        mRtt      : UInt32;
        mRttvar   : UInt32;
        mPad      : UInt32;
    end;

    RtMsghdr = record
        mMsglen   : UInt16;
        mVersion  : UInt8;
        mType     : UInt8;
        mHdrlen   : UInt16;
        mIndex    : UInt16;
        mTableid  : UInt16;
        mPriority : UInt8;
        mMpls     : UInt8;
        mAddrs    : Int32;
        mFlags    : Int32;
        mFmask    : Int32;
        mPid      : Int32;
        mSeq      : Int32;
        mErrno    : Int32;
        mInits    : UInt32;
        mRmx      : RtMetrics;
    end;

const
    ConstSizeofBpfVersion = $4;
    ConstSizeofBpfStat    = $8;
    ConstSizeofBpfProgram = $10;
    ConstSizeofBpfInsn    = $8;
    ConstSizeofBpfHdr     = $14;

type
    BpfVersion = record
        mMajor : UInt16;
        mMinor : UInt16;
    end;

    BpfStat = record
        mRecv : UInt32;
        mDrop : UInt32;
    end;

    BpfInsn = record
        mCode : UInt16;
        mJt   : UInt8;
        mJf   : UInt8;
        mK    : UInt32;
    end;
    PBpfInsn = ^BpfInsn;

    BpfProgram = record
        mLen   : UInt32;
        mInsns : PBpfInsn;
    end;

    BpfTimeval = record
        mSec  : UInt32;
        mUsec : UInt32;
    end;

    BpfHdr = record
        mTstamp  : BpfTimeval;
        mCaplen  : UInt32;
        mDatalen : UInt32;
        mHdrlen  : UInt16;
        m_       : array[0..1] of Byte;
    end;

    Termios = record
        mIflag  : UInt32;
        mOflag  : UInt32;
        mCflag  : UInt32;
        mLflag  : UInt32;
        mCc     : array[0..19] of UInt8;
        mIspeed : Int32;
        mOspeed : Int32;
    end;

    Winsize = record
        mRow    : UInt16;
        mCol    : UInt16;
        mXpixel : UInt16;
        mYpixel : UInt16;
    end;

const
    ConstAT_FDCWD            = -$64;
    ConstAT_EACCESS          = $1;
    ConstAT_SYMLINK_NOFOLLOW = $2;
    ConstAT_SYMLINK_FOLLOW   = $4;
    ConstAT_REMOVEDIR        = $8;

type
    PollFd = record
        mFd      : Int32;
        mEvents  : Int16;
        mRevents : Int16;
    end;

const
    ConstPOLLERR    = $8;
    ConstPOLLHUP    = $10;
    ConstPOLLIN     = $1;
    ConstPOLLNVAL   = $20;
    ConstPOLLOUT    = $4;
    ConstPOLLPRI    = $2;
    ConstPOLLRDBAND = $80;
    ConstPOLLRDNORM = $40;
    ConstPOLLWRBAND = $100;
    ConstPOLLWRNORM = $4;

type
    Sigset_t = UInt32;

    Utsname = record
        mSysname  : array[0..255] of Byte;
        mNodename : array[0..255] of Byte;
        mRelease  : array[0..255] of Byte;
        mVersion  : array[0..255] of Byte;
        mMachine  : array[0..255] of Byte;
    end;

const
    ConstSizeofUvmexp = $158;

type
    Uvmexp = record
        mPagesize           : Int32;
        mPagemask           : Int32;
        mPageshift          : Int32;
        mNpages             : Int32;
        mFree               : Int32;
        mActive             : Int32;
        mInactive           : Int32;
        mPaging             : Int32;
        mWired              : Int32;
        mZeropages          : Int32;
        mReserve_pagedaemon : Int32;
        mReserve_kernel     : Int32;
        mUnused01           : Int32;
        mVnodepages         : Int32;
        mVtextpages         : Int32;
        mFreemin            : Int32;
        mFreetarg           : Int32;
        mInactarg           : Int32;
        mWiredmax           : Int32;
        mAnonmin            : Int32;
        mVtextmin           : Int32;
        mVnodemin           : Int32;
        mAnonminpct         : Int32;
        mVtextminpct        : Int32;
        mVnodeminpct        : Int32;
        mNswapdev           : Int32;
        mSwpages            : Int32;
        mSwpginuse          : Int32;
        mSwpgonly           : Int32;
        mNswget             : Int32;
        mNanon              : Int32;
        mUnused05           : Int32;
        mUnused06           : Int32;
        mFaults             : Int32;
        mTraps              : Int32;
        mIntrs              : Int32;
        mSwtch              : Int32;
        mSofts              : Int32;
        mSyscalls           : Int32;
        mPageins            : Int32;
        mUnused07           : Int32;
        mUnused08           : Int32;
        mPgswapin           : Int32;
        mPgswapout          : Int32;
        mForks              : Int32;
        mForks_ppwait       : Int32;
        mForks_sharevm      : Int32;
        mPga_zerohit        : Int32;
        mPga_zeromiss       : Int32;
        mUnused09           : Int32;
        mFltnoram           : Int32;
        mFltnoanon          : Int32;
        mFltnoamap          : Int32;
        mFltpgwait          : Int32;
        mFltpgrele          : Int32;
        mFltrelck           : Int32;
        mFltrelckok         : Int32;
        mFltanget           : Int32;
        mFltanretry         : Int32;
        mFltamcopy          : Int32;
        mFltnamap           : Int32;
        mFltnomap           : Int32;
        mFltlget            : Int32;
        mFltget             : Int32;
        mFlt_anon           : Int32;
        mFlt_acow           : Int32;
        mFlt_obj            : Int32;
        mFlt_prcopy         : Int32;
        mFlt_przero         : Int32;
        mPdwoke             : Int32;
        mPdrevs             : Int32;
        mPdswout            : Int32;
        mPdfreed            : Int32;
        mPdscans            : Int32;
        mPdanscan           : Int32;
        mPdobscan           : Int32;
        mPdreact            : Int32;
        mPdbusy             : Int32;
        mPdpageouts         : Int32;
        mPdpending          : Int32;
        mPddeact            : Int32;
        mUnused11           : Int32;
        mUnused12           : Int32;
        mUnused13           : Int32;
        mFpswtch            : Int32;
        mKmapent            : Int32;
    end;

const
    ConstSizeofClockinfo = $14;

type
    Clockinfo = record
        mHz      : Int32;
        mTick    : Int32;
        mTickadj : Int32;
        mStathz  : Int32;
        mProfhz  : Int32;
    end;

implementation

end.
