{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesFreebsdArm64;

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
		mCur : Int64;
		mMax : Int64;
	end;

type
	Stat_t = record
		mDev     : UInt64;
		mIno     : UInt64;
		mNlink   : UInt64;
		mMode    : Word;
		m_0      : SmallInt;
		mUid     : Cardinal;
		mGid     : Cardinal;
		m_1      : Integer;
		mRdev    : UInt64;
		mAtim    : Timespec;
		mMtim    : Timespec;
		mCtim    : Timespec;
		mBtim    : Timespec;
		mSize    : Int64;
		mBlocks  : Int64;
		mBlksize : Integer;
		mFlags   : Cardinal;
		mGen     : UInt64;
		mSpare   : array[0..9] of UInt64;
	end;

	Fsid = record
		mVal : array[0..1] of Integer;
	end;

	Statfs_t = record
		mVersion     : Cardinal;
		mType        : Cardinal;
		mFlags       : UInt64;
		mBsize       : UInt64;
		mIosize      : UInt64;
		mBlocks      : UInt64;
		mBfree       : UInt64;
		mBavail      : Int64;
		mFiles       : UInt64;
		mFfree       : Int64;
		mSyncwrites  : UInt64;
		mAsyncwrites : UInt64;
		mSyncreads   : UInt64;
		mAsyncreads  : UInt64;
		mSpare       : array[0..9] of UInt64;
		mNamemax     : Cardinal;
		mOwner       : Cardinal;
		mFsid        : Fsid;
		mCharspare   : array[0..79] of ShortInt;
		mFstypename  : array[0..15] of Byte;
		mMntfromname : array[0..1023] of Byte;
		mMntonname   : array[0..1023] of Byte;
	end;

	Flock_t = record
		mStart  : Int64;
		mLen    : Int64;
		mPid    : Integer;
		mType   : SmallInt;
		mWhence : SmallInt;
		mSysid  : Integer;
		m_      : array[0..3] of Byte;
	end;

	Dirent = record
		mFileno : UInt64;
		mOff    : Int64;
		mReclen : Word;
		mType   : Byte;
		mPad0   : Byte;
		mNamlen : Word;
		mPad1   : Word;
		mName   : array[0..255] of ShortInt;
	end;

const
	ConstPathMax = $400;

const
	Const_FADV_NORMAL     = $0;
	Const_FADV_RANDOM     = $1;
	Const_FADV_SEQUENTIAL = $2;
	Const_FADV_WILLNEED   = $3;
	Const_FADV_DONTNEED   = $4;
	Const_FADV_NOREUSE    = $5;

type
	RawSockaddrInet4 = record
		mLen    : Byte;
		mFamily : Byte;
		mPort   : Word;
		mAddr   : array[0..3] of Byte;
		mZero   : array[0..7] of ShortInt;
	end;

	RawSockaddrInet6 = record
		mLen      : Byte;
		mFamily   : Byte;
		mPort     : Word;
		mFlowinfo : Cardinal;
		mAddr     : array[0..15] of Byte;
		mScope_id : Cardinal;
	end;

	RawSockaddrUnix = record
		mLen    : Byte;
		mFamily : Byte;
		mPath   : array[0..103] of ShortInt;
	end;

	RawSockaddrDatalink = record
		mLen    : Byte;
		mFamily : Byte;
		mIndex  : Word;
		mType   : Byte;
		mNlen   : Byte;
		mAlen   : Byte;
		mSlen   : Byte;
		mData   : array[0..45] of ShortInt;
	end;

	RawSockaddr = record
		mLen    : Byte;
		mFamily : Byte;
		mData   : array[0..13] of ShortInt;
	end;

	RawSockaddrAny = record
		mAddr : RawSockaddr;
		mPad  : array[0..91] of ShortInt;
	end;

	Xucred = record
		mVersion : Cardinal;
		mUid     : Cardinal;
		mNgroups : SmallInt;
		mGroups  : array[0..15] of Cardinal;
		m_       : PByte;
	end;

	Linger = record
		mOnoff  : Integer;
		mLinger : Integer;
	end;

	Iovec = record
		mBase : PByte;
		mLen  : UInt64;
	end;
	PIovec = ^Iovec;

	IPMreq = record
		mMultiaddr : array[0..3] of Byte;
		mInterface : array[0..3] of Byte;
	end;

	IPMreqn = record
		mMultiaddr : array[0..3] of Byte;
		mAddress   : array[0..3] of Byte;
		mIfindex   : Integer;
	end;

	IPv6Mreq = record
		mMultiaddr : array[0..15] of Byte;
		mInterface : Cardinal;
	end;

	Msghdr = record
		mName       : PByte;
		mNamelen    : Cardinal;
		mIov        : PIovec;
		mIovlen     : Integer;
		mControl    : PByte;
		mControllen : Cardinal;
		mFlags      : Integer;
	end;

	Cmsghdr = record
		mLen   : Cardinal;
		mLevel : Integer;
		mType  : Integer;
	end;

	Inet6Pktinfo = record
		mAddr    : array[0..15] of Byte;
		mIfindex : Cardinal;
	end;

	IPv6MTUInfo = record
		mAddr : RawSockaddrInet6;
		mMtu  : Cardinal;
	end;

	ICMPv6Filter = record
		mFilt : array[0..7] of Cardinal;
	end;

const
	ConstSizeofSockaddrInet4    = $10;
	ConstSizeofSockaddrInet6    = $1c;
	ConstSizeofSockaddrAny      = $6c;
	ConstSizeofSockaddrUnix     = $6a;
	ConstSizeofSockaddrDatalink = $36;
	ConstSizeofXucred           = $58;
	ConstSizeofLinger           = $8;
	ConstSizeofIovec            = $10;
	ConstSizeofIPMreq           = $8;
	ConstSizeofIPMreqn          = $c;
	ConstSizeofIPv6Mreq         = $14;
	ConstSizeofMsghdr           = $30;
	ConstSizeofCmsghdr          = $c;
	ConstSizeofInet6Pktinfo     = $14;
	ConstSizeofIPv6MTUInfo      = $20;
	ConstSizeofICMPv6Filter     = $20;

const
	Const_PTRACE_ATTACH     = $a;
	Const_PTRACE_CONT       = $7;
	Const_PTRACE_DETACH     = $b;
	Const_PTRACE_GETFPREGS  = $23;
	Const_PTRACE_GETLWPLIST = $f;
	Const_PTRACE_GETNUMLWPS = $e;
	Const_PTRACE_GETREGS    = $21;
	Const_PTRACE_IO         = $c;
	Const_PTRACE_KILL       = $8;
	Const_PTRACE_LWPEVENTS  = $18;
	Const_PTRACE_LWPINFO    = $d;
	Const_PTRACE_SETFPREGS  = $24;
	Const_PTRACE_SETREGS    = $22;
	Const_PTRACE_SINGLESTEP = $9;
	Const_PTRACE_TRACEME    = $0;

const
	Const_PIOD_READ_D  = $1;
	Const_PIOD_WRITE_D = $2;
	Const_PIOD_READ_I  = $3;
	Const_PIOD_WRITE_I = $4;

const
	Const_PL_FLAG_BORN   = $100;
	Const_PL_FLAG_EXITED = $200;
	Const_PL_FLAG_SI     = $20;

const
	Const_TRAP_BRKPT = $1;
	Const_TRAP_TRACE = $2;

type
	Sigset_t = record
		mVal : array[0..3] of Cardinal;
	end;

	PtraceLwpInfoStruct = record
		mLwpid        : Integer;
		mEvent        : Integer;
		mFlags        : Integer;
		mSigmask      : Sigset_t;
		mSiglist      : Sigset_t;
		mSiginfo      : record
			mSigno  : Integer;
			mErrno  : Integer;
			mCode   : Integer;
			mPid    : Integer;
			mUid    : Cardinal;
			mStatus : Integer;
			mAddr   : PByte;
			mValue  : array[0..7] of Byte;
			m_      : array[0..39] of Byte;
		end;
		mTdname       : array[0..19] of ShortInt;
		mChild_pid    : Integer;
		mSyscall_code : Cardinal;
		mSyscall_narg : Cardinal;
	end;

	Reg = record
		mX    : array[0..29] of UInt64;
		mLr   : UInt64;
		mSp   : UInt64;
		mElr  : UInt64;
		mSpsr : Cardinal;
		m_    : array[0..3] of Byte;
	end;

	FpReg = record
		mQ  : array[0..31, 0..15] of Byte;
		mSr : Cardinal;
		mCr : Cardinal;
		m_  : array[0..7] of Byte;
	end;

	PtraceIoDesc = record
		mOp   : Integer;
		mOffs : PByte;
		mAddr : PByte;
		mLen  : UInt64;
	end;

	Kevent_t = record
		mIdent  : UInt64;
		mFilter : SmallInt;
		mFlags  : Word;
		mFflags : Cardinal;
		mData   : Int64;
		mUdata  : PByte;
	end;

	FdSet = record
		mBits : array[0..15] of UInt64;
	end;

const
	ConstSizeofIfMsghdr         = $a8;
	ConstSizeofIfData           = $98;
	ConstSizeofIfaMsghdr        = $14;
	ConstSizeofIfmaMsghdr       = $10;
	ConstSizeofIfAnnounceMsghdr = $18;
	ConstSizeofRtMsghdr         = $98;
	ConstSizeofRtMetrics        = $70;

type
	IfData = record
		mType        : Byte;
		mPhysical    : Byte;
		mAddrlen     : Byte;
		mHdrlen      : Byte;
		mLink_state  : Byte;
		mSpare_char1 : Byte;
		mSpare_char2 : Byte;
		mDatalen     : Byte;
		mMtu         : UInt64;
		mMetric      : UInt64;
		mBaudrate    : UInt64;
		mIpackets    : UInt64;
		mIerrors     : UInt64;
		mOpackets    : UInt64;
		mOerrors     : UInt64;
		mCollisions  : UInt64;
		mIbytes      : UInt64;
		mObytes      : UInt64;
		mImcasts     : UInt64;
		mOmcasts     : UInt64;
		mIqdrops     : UInt64;
		mNoproto     : UInt64;
		mHwassist    : UInt64;
		mEpoch       : Int64;
		mLastchange  : Timeval;
	end;

	IfMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mAddrs   : Integer;
		mFlags   : Integer;
		mIndex   : Word;
		mData    : IfData;
	end;

	IfaMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mAddrs   : Integer;
		mFlags   : Integer;
		mIndex   : Word;
		m_       : Word;
		mMetric  : Integer;
	end;

	IfmaMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mAddrs   : Integer;
		mFlags   : Integer;
		mIndex   : Word;
		m_       : Word;
	end;

	IfAnnounceMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mIndex   : Word;
		mName    : array[0..15] of ShortInt;
		mWhat    : Word;
	end;

	RtMetrics = record
		mLocks    : UInt64;
		mMtu      : UInt64;
		mHopcount : UInt64;
		mExpire   : UInt64;
		mRecvpipe : UInt64;
		mSendpipe : UInt64;
		mSsthresh : UInt64;
		mRtt      : UInt64;
		mRttvar   : UInt64;
		mPksent   : UInt64;
		mWeight   : UInt64;
		mFiller   : array[0..2] of UInt64;
	end;

	RtMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mIndex   : Word;
		m_       : Word;
		mFlags   : Integer;
		mAddrs   : Integer;
		mPid     : Integer;
		mSeq     : Integer;
		mErrno   : Integer;
		mFmask   : Integer;
		mInits   : UInt64;
		mRmx     : RtMetrics;
	end;

const
	ConstSizeofBpfVersion    = $4;
	ConstSizeofBpfStat       = $8;
	ConstSizeofBpfZbuf       = $18;
	ConstSizeofBpfProgram    = $10;
	ConstSizeofBpfInsn       = $8;
	ConstSizeofBpfHdr        = $20;
	ConstSizeofBpfZbufHeader = $20;

type
	BpfVersion = record
		mMajor : Word;
		mMinor : Word;
	end;

	BpfStat = record
		mRecv : Cardinal;
		mDrop : Cardinal;
	end;

	BpfZbuf = record
		mBufa   : PByte;
		mBufb   : PByte;
		mBuflen : UInt64;
	end;

	BpfInsn = record
		mCode : Word;
		mJt   : Byte;
		mJf   : Byte;
		mK    : Cardinal;
	end;
	PBpfInsn = ^BpfInsn;

	BpfProgram = record
		mLen   : Cardinal;
		mInsns : PBpfInsn;
	end;

	BpfHdr = record
		mTstamp  : Timeval;
		mCaplen  : Cardinal;
		mDatalen : Cardinal;
		mHdrlen  : Word;
		m_       : array[0..5] of Byte;
	end;

	BpfZbufHeader = record
		mKernel_gen : Cardinal;
		mKernel_len : Cardinal;
		mUser_gen   : Cardinal;
		m_          : array[0..4] of Cardinal;
	end;

	Termios = record
		mIflag  : Cardinal;
		mOflag  : Cardinal;
		mCflag  : Cardinal;
		mLflag  : Cardinal;
		mCc     : array[0..19] of Byte;
		mIspeed : Cardinal;
		mOspeed : Cardinal;
	end;

	Winsize = record
		mRow    : Word;
		mCol    : Word;
		mXpixel : Word;
		mYpixel : Word;
	end;

const
	Const_AT_FDCWD            = -$64;
	Const_AT_EACCESS          = $100;
	Const_AT_SYMLINK_NOFOLLOW = $200;
	Const_AT_SYMLINK_FOLLOW   = $400;
	Const_AT_REMOVEDIR        = $800;

type
	PollFd = record
		mFd      : Integer;
		mEvents  : SmallInt;
		mRevents : SmallInt;
	end;

const
	ConstPOLLERR      = $8;
	ConstPOLLHUP      = $10;
	ConstPOLLIN       = $1;
	Const_POLLINIGNEOF = $2000;
	ConstPOLLNVAL     = $20;
	ConstPOLLOUT      = $4;
	ConstPOLLPRI      = $2;
	ConstPOLLRDBAND   = $80;
	ConstPOLLRDNORM   = $40;
	ConstPOLLWRBAND   = $100;
	ConstPOLLWRNORM   = $4;

type
	CapRights = record
		mRights : array[0..1] of UInt64;
	end;

	Utsname = record
		mSysname  : array[0..255] of Byte;
		mNodename : array[0..255] of Byte;
		mRelease  : array[0..255] of Byte;
		mVersion  : array[0..255] of Byte;
		mMachine  : array[0..255] of Byte;
	end;

const ConstSizeofClockinfo = $14;

type
	Clockinfo = record
		mHz     : Integer;
		mTick   : Integer;
		mSpare  : Integer;
		mStathz : Integer;
		mProfhz : Integer;
	end;

implementation

type
	_C_short     = SmallInt;
	_C_int       = Integer;
	_C_long      = Int64;
	_C_long_long = Int64;

	_Gid_t = Cardinal;

const
	Const_statfsVersion = $20140518;
	Const_dirblksiz     = $400;

type
	stat_freebsd11_t = record
		mDev     : Cardinal;
		mIno     : Cardinal;
		mMode    : Word;
		mNlink   : Word;
		mUid     : Cardinal;
		mGid     : Cardinal;
		mRdev    : Cardinal;
		mAtim    : Timespec;
		mMtim    : Timespec;
		mCtim    : Timespec;
		mSize    : Int64;
		mBlocks  : Int64;
		mBlksize : Integer;
		mFlags   : Cardinal;
		mGen     : Cardinal;
		mLspare  : Integer;
		mBtim    : Timespec;
	end;

	statfs_freebsd11_t = record
		mVersion     : Cardinal;
		mType        : Cardinal;
		mFlags       : UInt64;
		mBsize       : UInt64;
		mIosize      : UInt64;
		mBlocks      : UInt64;
		mBfree       : UInt64;
		mBavail      : Int64;
		mFiles       : UInt64;
		mFfree       : Int64;
		mSyncwrites  : UInt64;
		mAsyncwrites : UInt64;
		mSyncreads   : UInt64;
		mAsyncreads  : UInt64;
		mSpare       : array[0..9] of UInt64;
		mNamemax     : Cardinal;
		mOwner       : Cardinal;
		mFsid        : Fsid;
		mCharspare   : array[0..79] of ShortInt;
		mFstypename  : array[0..15] of Byte;
		mMntfromname : array[0..87] of Byte;
		mMntonname   : array[0..87] of Byte;
	end;

	dirent_freebsd11 = record
		mFileno : Cardinal;
		mReclen : Word;
		mType   : Byte;
		mNamlen : Byte;
		mName   : array[0..255] of ShortInt;
	end;

type
	_Socklen = Cardinal;

type
	__Siginfo = record
		mSigno  : Integer;
		mErrno  : Integer;
		mCode   : Integer;
		mPid    : Integer;
		mUid    : Cardinal;
		mStatus : Integer;
		mAddr   : PByte;
		mValue  : array[0..7] of Byte;
		m_      : array[0..39] of Byte;
	end;

const
	Const_sizeofIfMsghdr         = $a8;
	Const_sizeofIfData           = $98;

type
	ifData = record
		mType       : Byte;
		mPhysical   : Byte;
		mAddrlen    : Byte;
		mHdrlen     : Byte;
		mLink_state : Byte;
		mVhid       : Byte;
		mDatalen    : Word;
		mMtu        : Cardinal;
		mMetric     : Cardinal;
		mBaudrate   : UInt64;
		mIpackets   : UInt64;
		mIerrors    : UInt64;
		mOpackets    : UInt64;
		mOerrors     : UInt64;
		mCollisions : UInt64;
		mIbytes     : UInt64;
		mObytes     : UInt64;
		mImcasts    : UInt64;
		mOmcasts    : UInt64;
		mIqdrops    : UInt64;
		mOqdrops    : UInt64;
		mNoproto    : UInt64;
		mHwassist   : UInt64;
		m_          : array[0..7] of Byte;
		m_1         : array[0..15] of Byte;
	end;

	ifMsghdr = record
		mMsglen  : Word;
		mVersion : Byte;
		mType    : Byte;
		mAddrs   : Integer;
		mFlags   : Integer;
		mIndex   : Word;
		m_       : Word;
		mData    : ifData;
	end;

end.
