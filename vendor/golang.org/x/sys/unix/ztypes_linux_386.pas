{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux386;

interface

{$IFDEF FPC}
uses
	SysUtils;
{$ELSE}
uses
	System.SysUtils;
{$ENDIF}

const
	ConstSizeofPtr  = $4;
	ConstSizeofLong = $4;

type
	Timespec = record
		mSec  : Integer;
		mNsec : Integer;
	end;

	Timeval = record
		mSec  : Integer;
		mUsec : Integer;
	end;

	Timex = record
		mModes     : Cardinal;
		mOffset    : Integer;
		mFreq      : Integer;
		mMaxerror  : Integer;
		mEsterror  : Integer;
		mStatus    : Integer;
		mConstant  : Integer;
		mPrecision : Integer;
		mTolerance : Integer;
		mTime      : Timeval;
		mTick      : Integer;
		mPpsfreq   : Integer;
		mJitter    : Integer;
		mShift     : Integer;
		mStabil    : Integer;
		mJitcnt    : Integer;
		mCalcnt    : Integer;
		mErrcnt    : Integer;
		mStbcnt    : Integer;
		mTai       : Integer;
		m_         : array[0..43] of Byte;
	end;

	Time_t = Integer;

	Tms = record
		mUtime  : Integer;
		mStime  : Integer;
		mCutime : Integer;
		mCstime : Integer;
	end;

	Utimbuf = record
		mActime  : Integer;
		mModtime : Integer;
	end;

	Rusage = record
		mUtime    : Timeval;
		mStime    : Timeval;
		mMaxrss   : Integer;
		mIxrss    : Integer;
		mIdrss    : Integer;
		mIsrss    : Integer;
		mMinflt   : Integer;
		mMajflt   : Integer;
		mNswap    : Integer;
		mInblock  : Integer;
		mOublock  : Integer;
		mMsgsnd   : Integer;
		mMsgrcv   : Integer;
		mNsignals : Integer;
		mNvcsw    : Integer;
		mNivcsw   : Integer;
	end;

	Stat_t = record
		mDev     : UInt64;
		m_0      : Word;
		m_1      : Cardinal;
		mMode    : Cardinal;
		mNlink   : Cardinal;
		mUid     : Cardinal;
		mGid     : Cardinal;
		mRdev    : UInt64;
		m_2      : Word;
		mSize    : Int64;
		mBlksize : Integer;
		mBlocks  : Int64;
		mAtim    : Timespec;
		mMtim    : Timespec;
		mCtim    : Timespec;
		mIno     : UInt64;
	end;

	Dirent = record
		mIno    : UInt64;
		mOff    : Int64;
		mReclen : Word;
		mType   : Byte;
		mName   : array[0..255] of ShortInt;
		m_      : array[0..0] of Byte;
	end;

	Flock_t = record
		mType   : SmallInt;
		mWhence : SmallInt;
		mStart  : Int64;
		mLen    : Int64;
		mPid    : Integer;
	end;

	DmNameList = record
		mDev  : UInt64;
		mNext : Cardinal;
	end;

const
	Const_FADV_DONTNEED = $4;
	Const_FADV_NOREUSE  = $5;

type
	RawSockaddrNFCLLCP = record
		mSa_family        : Word;
		mDev_idx          : Cardinal;
		mTarget_idx       : Cardinal;
		mNfc_protocol     : Cardinal;
		mDsap             : Byte;
		mSsap             : Byte;
		mService_name     : array[0..62] of Byte;
		mService_name_len : Cardinal;
	end;

	RawSockaddr = record
		mFamily : Word;
		mData   : array[0..13] of ShortInt;
	end;

	RawSockaddrAny = record
		mAddr : RawSockaddr;
		mPad  : array[0..95] of ShortInt;
	end;

	Iovec = record
		mBase : PByte;
		mLen  : Cardinal;
	end;

	Msghdr = record
		mName       : PByte;
		mNamelen    : Cardinal;
		mIov        : ^Iovec;
		mIovlen     : Cardinal;
		mControl    : PByte;
		mControllen : Cardinal;
		mFlags      : Integer;
	end;

	Cmsghdr = record
		mLen   : Cardinal;
		mLevel : Integer;
		mType  : Integer;
	end;

const
	ConstSizeofSockaddrNFCLLCP = $58;
	ConstSizeofIovec           = $8;
	ConstSizeofMsghdr          = $1c;
	ConstSizeofCmsghdr         = $c;

const
	ConstSizeofSockFprog = $8;

type
	PtraceRegs = record
		mEbx      : Integer;
		mEcx      : Integer;
		mEdx      : Integer;
		mEsi      : Integer;
		mEdi      : Integer;
		mEbp      : Integer;
		mEax      : Integer;
		mXds      : Integer;
		mXes      : Integer;
		mXfs      : Integer;
		mXgs      : Integer;
		mOrig_eax : Integer;
		mEip      : Integer;
		mXcs      : Integer;
		mEflags   : Integer;
		mEsp      : Integer;
		mXss      : Integer;
	end;

	FdSet = record
		mBits : array[0..31] of Integer;
	end;

	Sysinfo_t = record
		mUptime    : Integer;
		mLoads     : array[0..2] of Cardinal;
		mTotalram  : Cardinal;
		mFreeram   : Cardinal;
		mSharedram : Cardinal;
		mBufferram : Cardinal;
		mTotalswap : Cardinal;
		mFreeswap  : Cardinal;
		mProcs     : Word;
		mPad       : Word;
		mTotalhigh : Cardinal;
		mFreehigh  : Cardinal;
		mUnit      : Cardinal;
		m_         : array[0..7] of ShortInt;
	end;

	Ustat_t = record
		mTfree  : Integer;
		mTinode : Cardinal;
		mFname  : array[0..5] of ShortInt;
		mFpack  : array[0..5] of ShortInt;
	end;

	EpollEvent = record
		mEvents : Cardinal;
		mFd     : Integer;
		mPad    : Integer;
	end;

const
	Const_POLLRDHUP = $2000;

type
	Sigset_t = record
		mVal : array[0..31] of Cardinal;
	end;

const Const_C__NSIG = $41;

type
	Termios = record
		mIflag  : Cardinal;
		mOflag  : Cardinal;
		mCflag  : Cardinal;
		mLflag  : Cardinal;
		mLine   : Byte;
		mCc     : array[0..18] of Byte;
		mIspeed : Cardinal;
		mOspeed : Cardinal;
	end;

type
	Taskstats = record
		mVersion                   : Word;
		mAc_exitcode               : Cardinal;
		mAc_flag                   : Byte;
		mAc_nice                   : Byte;
		m_                         : array[0..3] of Byte;
		mCpu_count                 : UInt64;
		mCpu_delay_total           : UInt64;
		mBlkio_count               : UInt64;
		mBlkio_delay_total         : UInt64;
		mSwapin_count              : UInt64;
		mSwapin_delay_total        : UInt64;
		mCpu_run_real_total        : UInt64;
		mCpu_run_virtual_total     : UInt64;
		mAc_comm                   : array[0..31] of ShortInt;
		mAc_sched                  : Byte;
		mAc_pad                    : array[0..2] of Byte;
		m_1                        : array[0..3] of Byte;
		mAc_uid                    : Cardinal;
		mAc_gid                    : Cardinal;
		mAc_pid                    : Cardinal;
		mAc_ppid                   : Cardinal;
		mAc_btime                  : Cardinal;
		m_2                        : array[0..3] of Byte;
		mAc_etime                  : UInt64;
		mAc_utime                  : UInt64;
		mAc_stime                  : UInt64;
		mAc_minflt                 : UInt64;
		mAc_majflt                 : UInt64;
		mCoremem                   : UInt64;
		mVirtmem                   : UInt64;
		mHiwater_rss               : UInt64;
		mHiwater_vm                : UInt64;
		mRead_char                 : UInt64;
		mWrite_char                : UInt64;
		mRead_syscalls             : UInt64;
		mWrite_syscalls            : UInt64;
		mRead_bytes                : UInt64;
		mWrite_bytes               : UInt64;
		mCancelled_write_bytes     : UInt64;
		mNvcsw                     : UInt64;
		mNivcsw                    : UInt64;
		mAc_utimescaled            : UInt64;
		mAc_stimescaled            : UInt64;
		mCpu_scaled_run_real_total : UInt64;
		mFreepages_count           : UInt64;
		mFreepages_delay_total     : UInt64;
		mThrashing_count           : UInt64;
		mThrashing_delay_total     : UInt64;
		mAc_btime64                : UInt64;
	end;

implementation

type
	_C_long = Integer;

	ifreq = record
		mIfrn : array[0..15] of Byte;
		mIfru : array[0..15] of Byte;
	end;

	cpuMask = Cardinal;

const
	Const_NCPUBITS = $20;

end.
