{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesLinuxAmd64;

interface

{$IFDEF FPC}
uses
	SysUtils;
{$ELSE}
uses
	System.SysUtils;
{$ENDIF}

const
	ConstSizeofPtr  = $8;
	ConstSizeofLong = $8;

type
	Timespec = record
		mSec  : Int64;
		mNsec : Int64;
	end;

	Timeval = record
		mSec  : Int64;
		mUsec : Int64;
	end;

	Timex = record
		mModes     : Cardinal;
		mOffset    : Int64;
		mFreq      : Int64;
		mMaxerror  : Int64;
		mEsterror  : Int64;
		mStatus    : Integer;
		mConstant  : Int64;
		mPrecision : Int64;
		mTolerance : Int64;
		mTime      : Timeval;
		mTick      : Int64;
		mPpsfreq   : Int64;
		mJitter    : Int64;
		mShift     : Integer;
		mStabil    : Int64;
		mJitcnt    : Int64;
		mCalcnt    : Int64;
		mErrcnt    : Int64;
		mStbcnt    : Int64;
		mTai       : Integer;
		m_         : array[0..43] of Byte;
	end;

	Time_t = Int64;

	Tms = record
		mUtime  : Int64;
		mStime  : Int64;
		mCutime : Int64;
		mCstime : Int64;
	end;

	Utimbuf = record
		mActime  : Int64;
		mModtime : Int64;
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

	Stat_t = record
		mDev     : UInt64;
		mIno     : UInt64;
		mNlink   : UInt64;
		mMode    : Cardinal;
		mUid     : Cardinal;
		mGid     : Cardinal;
		m_       : Integer;
		mRdev    : UInt64;
		mSize    : Int64;
		mBlksize : Int64;
		mBlocks  : Int64;
		mAtim    : Timespec;
		mMtim    : Timespec;
		mCtim    : Timespec;
		m_1      : array[0..2] of Int64;
	end;

	Dirent = record
		mIno    : UInt64;
		mOff    : Int64;
		mReclen : Word;
		mType   : Byte;
		mName   : array[0..255] of ShortInt;
		m_      : array[0..4] of Byte;
	end;

	Flock_t = record
		mType   : SmallInt;
		mWhence : SmallInt;
		mStart  : Int64;
		mLen    : Int64;
		mPid    : Integer;
		m_      : array[0..3] of Byte;
	end;

	DmNameList = record
		mDev  : UInt64;
		mNext : Cardinal;
		mName : array[0..0] of Byte;
		m_    : array[0..3] of Byte;
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
		mService_name_len : UInt64;
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
		mLen  : UInt64;
	end;
	PIovec = ^Iovec;

	Msghdr = record
		mName       : PByte;
		mNamelen    : Cardinal;
		mIov        : PIovec;
		mIovlen     : UInt64;
		mControl    : PByte;
		mControllen : UInt64;
		mFlags      : Integer;
		m_          : array[0..3] of Byte;
	end;

	Cmsghdr = record
		mLen   : UInt64;
		mLevel : Integer;
		mType  : Integer;
	end;

const
	ConstSizeofSockaddrNFCLLCP = $60;
	ConstSizeofIovec           = $10;
	ConstSizeofMsghdr          = $38;
	ConstSizeofCmsghdr         = $10;

const
	ConstSizeofSockFprog = $10;

type
	PtraceRegs = record
		mR15      : UInt64;
		mR14      : UInt64;
		mR13      : UInt64;
		mR12      : UInt64;
		mRbp      : UInt64;
		mRbx      : UInt64;
		mR11      : UInt64;
		mR10      : UInt64;
		mR9       : UInt64;
		mR8       : UInt64;
		mRax      : UInt64;
		mRcx      : UInt64;
		mRdx      : UInt64;
		mRsi      : UInt64;
		mRdi      : UInt64;
		mOrig_rax : UInt64;
		mRip      : UInt64;
		mCs       : UInt64;
		mEflags   : UInt64;
		mRsp      : UInt64;
		mSs       : UInt64;
		mFs_base  : UInt64;
		mGs_base  : UInt64;
		mDs       : UInt64;
		mEs       : UInt64;
		mFs       : UInt64;
		mGs       : UInt64;
	end;

	FdSet = record
		mBits : array[0..15] of Int64;
	end;

	Sysinfo_t = record
		mUptime    : Int64;
		mLoads     : array[0..2] of UInt64;
		mTotalram  : UInt64;
		mFreeram   : UInt64;
		mSharedram : UInt64;
		mBufferram : UInt64;
		mTotalswap : UInt64;
		mFreeswap  : UInt64;
		mProcs     : Word;
		mPad       : Word;
		mTotalhigh : UInt64;
		mFreehigh  : UInt64;
		mUnit      : Cardinal;
		m_         : array[0..0] of ShortInt;
		m_1        : array[0..3] of Byte;
	end;

	Ustat_t = record
		mTfree  : Integer;
		mTinode : UInt64;
		mFname  : array[0..5] of ShortInt;
		mFpack  : array[0..5] of ShortInt;
		m_      : array[0..3] of Byte;
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
		mVal : array[0..15] of UInt64;
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
		m_                         : array[0..3] of Byte;
		mAc_uid                    : Cardinal;
		mAc_gid                    : Cardinal;
		mAc_pid                    : Cardinal;
		mAc_ppid                   : Cardinal;
		mAc_btime                  : Cardinal;
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
	_C_long = Int64;

	ifreq = record
		mIfrn : array[0..15] of Byte;
		mIfru : array[0..23] of Byte;
	end;

	cpuMask = UInt64;

const
	Const_NCPUBITS = $40;

const
	Const_CBitFieldMaskBit0  = $1;
	Const_CBitFieldMaskBit1  = $2;
	Const_CBitFieldMaskBit2  = $4;
	Const_CBitFieldMaskBit3  = $8;
	Const_CBitFieldMaskBit4  = $10;
	Const_CBitFieldMaskBit5  = $20;
	Const_CBitFieldMaskBit6  = $40;
	Const_CBitFieldMaskBit7  = $80;
	Const_CBitFieldMaskBit8  = $100;
	Const_CBitFieldMaskBit9  = $200;
	Const_CBitFieldMaskBit10 = $400;
	Const_CBitFieldMaskBit11 = $800;
	Const_CBitFieldMaskBit12 = $1000;
	Const_CBitFieldMaskBit13 = $2000;
	Const_CBitFieldMaskBit14 = $4000;
	Const_CBitFieldMaskBit15 = $8000;
	Const_CBitFieldMaskBit16 = $10000;
	Const_CBitFieldMaskBit17 = $20000;
	Const_CBitFieldMaskBit18 = $40000;
	Const_CBitFieldMaskBit19 = $80000;
	Const_CBitFieldMaskBit20 = $100000;
	Const_CBitFieldMaskBit21 = $200000;
	Const_CBitFieldMaskBit22 = $400000;
	Const_CBitFieldMaskBit23 = $800000;
	Const_CBitFieldMaskBit24 = $1000000;
	Const_CBitFieldMaskBit25 = $2000000;
	Const_CBitFieldMaskBit26 = $4000000;
	Const_CBitFieldMaskBit27 = $8000000;
	Const_CBitFieldMaskBit28 = $10000000;
	Const_CBitFieldMaskBit29 = $20000000;
	Const_CBitFieldMaskBit30 = $40000000;
	Const_CBitFieldMaskBit31 = $80000000;
	Const_CBitFieldMaskBit32 = $100000000;
	Const_CBitFieldMaskBit33 = $200000000;
	Const_CBitFieldMaskBit34 = $400000000;
	Const_CBitFieldMaskBit35 = $800000000;
	Const_CBitFieldMaskBit36 = $1000000000;
	Const_CBitFieldMaskBit37 = $2000000000;
	Const_CBitFieldMaskBit38 = $4000000000;
	Const_CBitFieldMaskBit39 = $8000000000;
	Const_CBitFieldMaskBit40 = $10000000000;
	Const_CBitFieldMaskBit41 = $20000000000;
	Const_CBitFieldMaskBit42 = $40000000000;
	Const_CBitFieldMaskBit43 = $80000000000;
	Const_CBitFieldMaskBit44 = $100000000000;
	Const_CBitFieldMaskBit45 = $200000000000;
	Const_CBitFieldMaskBit46 = $400000000000;
	Const_CBitFieldMaskBit47 = $800000000000;
	Const_CBitFieldMaskBit48 = $1000000000000;
	Const_CBitFieldMaskBit49 = $2000000000000;
	Const_CBitFieldMaskBit50 = $4000000000000;
	Const_CBitFieldMaskBit51 = $8000000000000;
	Const_CBitFieldMaskBit52 = $10000000000000;
	Const_CBitFieldMaskBit53 = $20000000000000;
	Const_CBitFieldMaskBit54 = $40000000000000;
	Const_CBitFieldMaskBit55 = $80000000000000;
	Const_CBitFieldMaskBit56 = $100000000000000;
	Const_CBitFieldMaskBit57 = $200000000000000;
	Const_CBitFieldMaskBit58 = $400000000000000;
	Const_CBitFieldMaskBit59 = $800000000000000;
	Const_CBitFieldMaskBit60 = $1000000000000000;
	Const_CBitFieldMaskBit61 = $2000000000000000;
	Const_CBitFieldMaskBit62 = $4000000000000000;
	Const_CBitFieldMaskBit63 = $8000000000000000;

end.
