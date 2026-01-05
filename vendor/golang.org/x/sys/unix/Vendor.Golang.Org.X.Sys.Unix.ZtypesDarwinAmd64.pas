{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesDarwinAmd64;

interface

uses
	System.SysUtils;

const
	Const_SizeofPtr = $8;
	Const_SizeofShort = $2;
	Const_SizeofInt = $4;
	Const_SizeofLong = $8;
	Const_SizeofLongLong = $8;

type
	_C_short = Int16;
	_C_int = Int32;
	_C_long = Int64;
	_C_long_long = Int64;

	Timespec = record
		mSec : Int64;
		mNsec : Int64;
	end;

	Timeval = record
		mSec : Int64;
		mUsec : Int32;
		mPad_cgo_0 : array [0..3] of Byte;
	end;

	Timeval32 = record
		mSec : Int32;
		mUsec : Int32;
	end;

	Rusage = record
		mUtime : Timeval;
		mStime : Timeval;
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

	Rlimit = record
		mCur : UInt64;
		mMax : UInt64;
	end;

	_Gid_t = UInt32;

	Stat_t = record
		mDev : Int32;
		mMode : UInt16;
		mNlink : UInt16;
		mIno : UInt64;
		mUid : UInt32;
		mGid : UInt32;
		mRdev : Int32;
		mAtim : Timespec;
		mMtim : Timespec;
		mCtim : Timespec;
		mBtim : Timespec;
		mSize : Int64;
		mBlocks : Int64;
		mBlksize : Int32;
		mFlags : UInt32;
		mGen : UInt32;
		mLspare : Int32;
		mQspare : array [0..1] of Int64;
	end;

	Fsid = record
		mVal : array [0..1] of Int32;
	end;

	Statfs_t = record
		mBsize : UInt32;
		mIosize : Int32;
		mBlocks : UInt64;
		mBfree : UInt64;
		mBavail : UInt64;
		mFiles : UInt64;
		mFfree : UInt64;
		mFsid : Fsid;
		mOwner : UInt32;
		mType : UInt32;
		mFlags : UInt32;
		mFssubtype : UInt32;
		mFstypename : array [0..15] of Byte;
		mMntonname : array [0..1023] of Byte;
		mMntfromname : array [0..1023] of Byte;
		mFlags_ext : UInt32;
		mReserved : array [0..6] of UInt32;
	end;

	Flock_t = record
		mStart : Int64;
		mLen : Int64;
		mPid : Int32;
		mType : Int16;
		mWhence : Int16;
	end;

	Fstore_t = record
		mFlags : UInt32;
		mPosmode : Int32;
		mOffset : Int64;
		mLength : Int64;
		mBytesalloc : Int64;
	end;

	Radvisory_t = record
		mOffset : Int64;
		mCount : Int32;
		mPad_cgo_0 : array [0..3] of Byte;
	end;

	Fbootstraptransfer_t = record
		mOffset : Int64;
		mLength : UInt64;
		mBuffer : PByte;
	end;

	Log2phys_t = record
		mFlags : UInt32;
		mPad_cgo_0 : array [0..15] of Byte;
	end;

	Dirent = record
		mIno : UInt64;
		mSeekoff : UInt64;
		mReclen : UInt16;
		mNamlen : UInt16;
		mType : UInt8;
		mName : array [0..1023] of Int8;
		mPad_cgo_0 : array [0..2] of Byte;
	end;

const
	Const_PathMax = $400;

type
	RawSockaddrInet4 = record
		mLen : UInt8;
		mFamily : UInt8;
		mPort : UInt16;
		mAddr : array [0..3] of Byte;
		mZero : array [0..7] of Int8;
	end;

	RawSockaddrInet6 = record
		mLen : UInt8;
		mFamily : UInt8;
		mPort : UInt16;
		mFlowinfo : UInt32;
		mAddr : array [0..15] of Byte;
		mScope_id : UInt32;
	end;

	RawSockaddrUnix = record
		mLen : UInt8;
		mFamily : UInt8;
		mPath : array [0..103] of Int8;
	end;

	RawSockaddrDatalink = record
		mLen : UInt8;
		mFamily : UInt8;
		mIndex : UInt16;
		mType : UInt8;
		mNlen : UInt8;
		mAlen : UInt8;
		mSlen : UInt8;
		mData : array [0..11] of Int8;
	end;

	RawSockaddr = record
		mLen : UInt8;
		mFamily : UInt8;
		mData : array [0..13] of Int8;
	end;

	RawSockaddrAny = record
		mAddr : RawSockaddr;
		mPad : array [0..91] of Int8;
	end;

	RawSockaddrCtl = record
		mSc_len : UInt8;
		mSc_family : UInt8;
		mSs_sysaddr : UInt16;
		mSc_id : UInt32;
		mSc_unit : UInt32;
		mSc_reserved : array [0..4] of UInt32;
	end;

	_Socklen = UInt32;

	Xucred = record
		mVersion : UInt32;
		mUid : UInt32;
		mNgroups : Int16;
		mGroups : array [0..15] of UInt32;
	end;

	Linger = record
		mOnoff : Int32;
		mLinger : Int32;
	end;

	Iovec = record
		mBase : PByte;
		mLen : UInt64;
	end;

	IPMreq = record
		mMultiaddr : array [0..3] of Byte;
		mInterface : array [0..3] of Byte;
	end;

	IPMreqn = record
		mMultiaddr : array [0..3] of Byte;
		mAddress : array [0..3] of Byte;
		mIfindex : Int32;
	end;

	IPv6Mreq = record
		mMultiaddr : array [0..15] of Byte;
		mInterface : UInt32;
	end;

	Msghdr = record
		mName : PByte;
		mNamelen : UInt32;
		mIov : ^Iovec;
		mIovlen : Int32;
		mControl : PByte;
		mControllen : UInt32;
		mFlags : Int32;
	end;

	Cmsghdr = record
		mLen : UInt32;
		mLevel : Int32;
		mType : Int32;
	end;

	Inet4Pktinfo = record
		mIfindex : UInt32;
		mSpec_dst : array [0..3] of Byte;
		mAddr : array [0..3] of Byte;
	end;

	Inet6Pktinfo = record
		mAddr : array [0..15] of Byte;
		mIfindex : UInt32;
	end;

	IPv6MTUInfo = record
		mAddr : RawSockaddrInet6;
		mMtu : UInt32;
	end;

	ICMPv6Filter = record
		mFilt : array [0..7] of UInt32;
	end;

const
	Const_SizeofSockaddrInet4 = $10;
	Const_SizeofSockaddrInet6 = $1c;
	Const_SizeofSockaddrAny = $6c;
	Const_SizeofSockaddrUnix = $6a;
	Const_SizeofSockaddrDatalink = $14;
	Const_SizeofSockaddrCtl = $20;
	Const_SizeofXucred = $4c;
	Const_SizeofLinger = $8;
	Const_SizeofIovec = $10;
	Const_SizeofIPMreq = $8;
	Const_SizeofIPMreqn = $c;
	Const_SizeofIPv6Mreq = $14;
	Const_SizeofMsghdr = $30;
	Const_SizeofCmsghdr = $c;
	Const_SizeofInet4Pktinfo = $c;
	Const_SizeofInet6Pktinfo = $14;
	Const_SizeofIPv6MTUInfo = $20;
	Const_SizeofICMPv6Filter = $20;

const
	Const_PTRACE_TRACEME = $0;
	Const_PTRACE_CONT = $7;
	Const_PTRACE_KILL = $8;

type
	Kevent_t = record
		mIdent : UInt64;
		mFilter : Int16;
		mFlags : UInt16;
		mFflags : UInt32;
		mData : Int64;
		mUdata : PByte;
	end;

	FdSet = record
		mBits : array [0..31] of Int32;
	end;

const
	Const_SizeofIfMsghdr = $70;
	Const_SizeofIfData = $60;
	Const_SizeofIfaMsghdr = $14;
	Const_SizeofIfmaMsghdr = $10;
	Const_SizeofIfmaMsghdr2 = $14;
	Const_SizeofRtMsghdr = $5c;
	Const_SizeofRtMetrics = $38;

type
	IfData = record
		mType : UInt8;
		mTypelen : UInt8;
		mPhysical : UInt8;
		mAddrlen : UInt8;
		mHdrlen : UInt8;
		mRecvquota : UInt8;
		mXmitquota : UInt8;
		mUnused1 : UInt8;
		mMtu : UInt32;
		mMetric : UInt32;
		mBaudrate : UInt32;
		mIpackets : UInt32;
		mIerrors : UInt32;
		mOpackets : UInt32;
		mOerrors : UInt32;
		mCollisions : UInt32;
		mIbytes : UInt32;
		mObytes : UInt32;
		mImcasts : UInt32;
		mOmcasts : UInt32;
		mIqdrops : UInt32;
		mNoproto : UInt32;
		mRecvtiming : UInt32;
		mXmittiming : UInt32;
		mLastchange : Timeval32;
		mUnused2 : UInt32;
		mHwassist : UInt32;
		mReserved1 : UInt32;
		mReserved2 : UInt32;
	end;

	IfMsghdr = record
		mMsglen : UInt16;
		mVersion : UInt8;
		mType : UInt8;
		mAddrs : Int32;
		mFlags : Int32;
		mIndex : UInt16;
		mData : IfData;
	end;

	IfaMsghdr = record
		mMsglen : UInt16;
		mVersion : UInt8;
		mType : UInt8;
		mAddrs : Int32;
		mFlags : Int32;
		mIndex : UInt16;
		mMetric : Int32;
	end;

	IfmaMsghdr = record
		mMsglen : UInt16;
		mVersion : UInt8;
		mType : UInt8;
		mAddrs : Int32;
		mFlags : Int32;
		mIndex : UInt16;
		mPad_cgo_0 : array [0..1] of Byte;
	end;

	IfmaMsghdr2 = record
		mMsglen : UInt16;
		mVersion : UInt8;
		mType : UInt8;
		mAddrs : Int32;
		mFlags : Int32;
		mIndex : UInt16;
		mRefcount : Int32;
	end;

	RtMetrics = record
		mLocks : UInt32;
		mMtu : UInt32;
		mHopcount : UInt32;
		mExpire : Int32;
		mRecvpipe : UInt32;
		mSendpipe : UInt32;
		mSsthresh : UInt32;
		mRtt : UInt32;
		mRttvar : UInt32;
		mPksent : UInt32;
		mState : UInt32;
		mFiller : array [0..2] of UInt32;
	end;

	RtMsghdr = record
		mMsglen : UInt16;
		mVersion : UInt8;
		mType : UInt8;
		mIndex : UInt16;
		mFlags : Int32;
		mAddrs : Int32;
		mPid : Int32;
		mSeq : Int32;
		mErrno : Int32;
		mUse : Int32;
		mInits : UInt32;
		mRmx : RtMetrics;
	end;

const
	Const_SizeofBpfVersion = $4;
	Const_SizeofBpfStat = $8;
	Const_SizeofBpfProgram = $10;
	Const_SizeofBpfInsn = $8;
	Const_SizeofBpfHdr = $14;

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
		mJt : UInt8;
		mJf : UInt8;
		mK : UInt32;
	end;

	BpfProgram = record
		mLen : UInt32;
		mInsns : ^BpfInsn;
	end;

	BpfHdr = record
		mTstamp : Timeval32;
		mCaplen : UInt32;
		mDatalen : UInt32;
		mHdrlen : UInt16;
		mPad_cgo_0 : array [0..1] of Byte;
	end;

	Termios = record
		mIflag : UInt64;
		mOflag : UInt64;
		mCflag : UInt64;
		mLflag : UInt64;
		mCc : array [0..19] of UInt8;
		mIspeed : UInt64;
		mOspeed : UInt64;
	end;

	Winsize = record
		mRow : UInt16;
		mCol : UInt16;
		mXpixel : UInt16;
		mYpixel : UInt16;
	end;

const
	Const_AT_FDCWD = -$2;
	Const_AT_REMOVEDIR = $80;
	Const_AT_SYMLINK_FOLLOW = $40;
	Const_AT_SYMLINK_NOFOLLOW = $20;

type
	PollFd = record
		mFd : Int32;
		mEvents : Int16;
		mRevents : Int16;
	end;

const
	Const_POLLERR = $8;
	Const_POLLHUP = $10;
	Const_POLLIN = $1;
	Const_POLLNVAL = $20;
	Const_POLLOUT = $4;
	Const_POLLPRI = $2;
	Const_POLLRDBAND = $80;
	Const_POLLRDNORM = $40;
	Const_POLLWRBAND = $100;
	Const_POLLWRNORM = $4;

type
	Utsname = record
		mSysname : array [0..255] of Byte;
		mNodename : array [0..255] of Byte;
		mRelease : array [0..255] of Byte;
		mVersion : array [0..255] of Byte;
		mMachine : array [0..255] of Byte;
	end;

const
	Const_SizeofClockinfo = $14;

type
	Clockinfo = record
		mHz : Int32;
		mTick : Int32;
		mTickadj : Int32;
		mStathz : Int32;
		mProfhz : Int32;
	end;

	CtlInfo = record
		mId : UInt32;
		mName : array [0..95] of Byte;
	end;

const
	Const_SizeofKinfoProc = $288;

type
	Pcred = record
		mPc_lock : array [0..71] of Int8;
		mPc_ucred : UIntPtr;
		mP_ruid : UInt32;
		mP_svuid : UInt32;
		mP_rgid : UInt32;
		mP_svgid : UInt32;
		mP_refcnt : Int32;
		mPad_cgo_0 : array [0..3] of Byte;
	end;

	Ucred = record
		mRef : Int32;
		mUid : UInt32;
		mNgroups : Int16;
		mGroups : array [0..15] of UInt32;
	end;

	Vmspace = record
		mDummy : Int32;
		mDummy2 : ^Int8;
		mDummy3 : array [0..4] of Int32;
		mDummy4 : array [0..2] of ^Int8;
	end;

	Eproc = record
		mPaddr : UIntPtr;
		mSess : UIntPtr;
		mPcred : Pcred;
		mUcred : Ucred;
		mVm : Vmspace;
		mPpid : Int32;
		mPgid : Int32;
		mJobc : Int16;
		mTdev : Int32;
		mTpgid : Int32;
		mTsess : UIntPtr;
		mWmesg : array [0..7] of Int8;
		mXsize : Int32;
		mXrssize : Int16;
		mXccount : Int16;
		mXswrss : Int16;
		mFlag : Int32;
		mLogin : array [0..11] of Int8;
		mSpare : array [0..3] of Int32;
		mPad_cgo_0 : array [0..3] of Byte;
	end;

	Itimerval = record
		mInterval : Timeval;
		mValue : Timeval;
	end;

	ExternProc = record
		mP_starttime : Timeval;
		mP_vmspace : ^Vmspace;
		mP_sigacts : UIntPtr;
		mP_flag : Int32;
		mP_stat : Int8;
		mP_pid : Int32;
		mP_oppid : Int32;
		mP_dupfd : Int32;
		mUser_stack : ^Int8;
		mExit_thread : PByte;
		mP_debugger : Int32;
		mSigwait : Int32;
		mP_estcpu : UInt32;
		mP_cpticks : Int32;
		mP_pctcpu : UInt32;
		mP_wchan : PByte;
		mP_wmesg : ^Int8;
		mP_swtime : UInt32;
		mP_slptime : UInt32;
		mP_realtimer : Itimerval;
		mP_rtime : Timeval;
		mP_uticks : UInt64;
		mP_sticks : UInt64;
		mP_iticks : UInt64;
		mP_traceflag : Int32;
		mP_tracep : UIntPtr;
		mP_siglist : Int32;
		mP_textvp : UIntPtr;
		mP_holdcnt : Int32;
		mP_sigmask : UInt32;
		mP_sigignore : UInt32;
		mP_sigcatch : UInt32;
		mP_priority : UInt8;
		mP_usrpri : UInt8;
		mP_nice : Int8;
		mP_comm : array [0..16] of Int8;
		mP_pgrp : UIntPtr;
		mP_addr : UIntPtr;
		mP_xstat : UInt16;
		mP_acflag : UInt16;
		mP_ru : ^Rusage;
	end;

	KinfoProc = record
		mProc : ExternProc;
		mEproc : Eproc;
	end;

implementation

end.
