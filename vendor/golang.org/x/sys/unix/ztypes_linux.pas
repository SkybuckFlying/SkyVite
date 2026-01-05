{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

interface

{$IFDEF FPC}
uses
	SysUtils;
{$ELSE}
uses
	System.SysUtils;
{$ENDIF}

const
	ConstSizeofShort    = $2;
	ConstSizeofInt      = $4;
	ConstSizeofLongLong = $8;
	ConstPathMax        = $1000;

type
	Timespec = record
		mSec  : Int64;
		mNsec : Int64;
	end;

	Timeval = record
		mSec  : Int64;
		mUsec : Int64;
	end;

	ItimerSpec = record
		mInterval : Timespec;
		mValue    : Timespec;
	end;

const
	Const_TIME_OK    = $0;
	Const_TIME_INS   = $1;
	Const_TIME_DEL   = $2;
	Const_TIME_OOP   = $3;
	Const_TIME_WAIT  = $4;
	Const_TIME_ERROR = $5;
	Const_TIME_BAD   = $5;

type
	Rlimit = record
		mCur : UInt64;
		mMax : UInt64;
	end;

	StatxTimestamp = record
		mSec  : Int64;
		mNsec : Cardinal;
		m_    : Integer;
	end;

	Statx_t = record
		mMask            : Cardinal;
		mBlksize         : Cardinal;
		mAttributes      : UInt64;
		mNlink           : Cardinal;
		mUid             : Cardinal;
		mGid             : Cardinal;
		mMode            : Word;
		m_               : array[0..0] of Word;
		mIno             : UInt64;
		mSize            : UInt64;
		mBlocks          : UInt64;
		mAttributes_mask : UInt64;
		mAtime           : StatxTimestamp;
		mBtime           : StatxTimestamp;
		mCtime           : StatxTimestamp;
		mMtime           : StatxTimestamp;
		mRdev_major      : Cardinal;
		mRdev_minor      : Cardinal;
		mDev_major       : Cardinal;
		mDev_minor       : Cardinal;
		mMnt_id          : UInt64;
		m_1              : UInt64;
		m_2              : array[0..11] of UInt64;
	end;

	Fsid = record
		mVal : array[0..1] of Integer;
	end;

	FileCloneRange = record
		mSrc_fd      : Int64;
		mSrc_offset  : UInt64;
		mSrc_length  : UInt64;
		mDest_offset : UInt64;
	end;

	RawFileDedupeRange = record
		mSrc_offset : UInt64;
		mSrc_length : UInt64;
		mDest_count : Word;
		mReserved1  : Word;
		mReserved2  : Cardinal;
	end;

	RawFileDedupeRangeInfo = record
		mDest_fd       : Int64;
		mDest_offset   : UInt64;
		mBytes_deduped : UInt64;
		mStatus        : Integer;
		mReserved      : Cardinal;
	end;

const
	ConstSizeofRawFileDedupeRange     = $18;
	ConstSizeofRawFileDedupeRangeInfo = $20;
	Const_FILE_DEDUPE_RANGE_SAME       = $0;
	Const_FILE_DEDUPE_RANGE_DIFFERS    = $1;

type
	FscryptPolicy = record
		mVersion                   : Byte;
		mContents_encryption_mode  : Byte;
		mFilenames_encryption_mode : Byte;
		mFlags                     : Byte;
		mMaster_key_descriptor     : array[0..7] of Byte;
	end;

	FscryptKey = record
		mMode : Cardinal;
		mRaw  : array[0..63] of Byte;
		mSize : Cardinal;
	end;

	FscryptPolicyV1 = record
		mVersion                   : Byte;
		mContents_encryption_mode  : Byte;
		mFilenames_encryption_mode : Byte;
		mFlags                     : Byte;
		mMaster_key_descriptor     : array[0..7] of Byte;
	end;

	FscryptPolicyV2 = record
		mVersion                   : Byte;
		mContents_encryption_mode  : Byte;
		mFilenames_encryption_mode : Byte;
		mFlags                     : Byte;
		m_                         : array[0..3] of Byte;
		mMaster_key_identifier     : array[0..15] of Byte;
	end;

	FscryptGetPolicyExArg = record
		mSize   : UInt64;
		mPolicy : array[0..23] of Byte;
	end;

	FscryptKeySpecifier = record
		mType : Cardinal;
		m_    : Cardinal;
		mU    : array[0..31] of Byte;
	end;

	FscryptAddKeyArg = record
		mKey_spec : FscryptKeySpecifier;
		mRaw_size : Cardinal;
		mKey_id   : Cardinal;
		m_        : array[0..7] of Cardinal;
	end;

	FscryptRemoveKeyArg = record
		mKey_spec             : FscryptKeySpecifier;
		mRemoval_status_flags : Cardinal;
		m_                    : array[0..4] of Cardinal;
	end;

	FscryptGetKeyStatusArg = record
		mKey_spec     : FscryptKeySpecifier;
		m_            : array[0..5] of Cardinal;
		mStatus       : Cardinal;
		mStatus_flags : Cardinal;
		mUser_count   : Cardinal;
		m_1           : array[0..12] of Cardinal;
	end;

	DmIoctl = record
		mVersion      : array[0..2] of Cardinal;
		mData_size    : Cardinal;
		mData_start   : Cardinal;
		mTarget_count : Cardinal;
		mOpen_count   : Integer;
		mFlags        : Cardinal;
		mEvent_nr     : Cardinal;
		m_            : Cardinal;
		mDev          : UInt64;
		mName         : array[0..127] of Byte;
		mUuid         : array[0..128] of Byte;
		mData         : array[0..6] of Byte;
	end;

	DmTargetSpec = record
		mSector_start : UInt64;
		mLength       : UInt64;
		mStatus       : Integer;
		mNext         : Cardinal;
		mTarget_type  : array[0..15] of Byte;
	end;

	DmTargetDeps = record
		mCount : Cardinal;
		m_     : Cardinal;
	end;

	DmTargetVersions = record
		mNext    : Cardinal;
		mVersion : array[0..2] of Cardinal;
	end;

	DmTargetMsg = record
		mSector : UInt64;
	end;

const
	ConstSizeofDmIoctl      = $138;
	ConstSizeofDmTargetSpec = $28;

type
	KeyctlDHParams = record
		mPrivate : Integer;
		mPrime   : Integer;
		mBase    : Integer;
	end;

const
	Const_FADV_NORMAL     = $0;
	Const_FADV_RANDOM     = $1;
	Const_FADV_SEQUENTIAL = $2;
	Const_FADV_WILLNEED   = $3;

type
	RawSockaddrInet4 = record
		mFamily : Word;
		mPort   : Word;
		mAddr   : array[0..3] of Byte;
		mZero   : array[0..7] of Byte;
	end;

	RawSockaddrInet6 = record
		mFamily   : Word;
		mPort     : Word;
		mFlowinfo : Cardinal;
		mAddr     : array[0..15] of Byte;
		mScope_id : Cardinal;
	end;

	RawSockaddrUnix = record
		mFamily : Word;
		mPath   : array[0..107] of ShortInt;
	end;

	RawSockaddrLinklayer = record
		mFamily   : Word;
		mProtocol : Word;
		mIfindex  : Integer;
		mHatype   : Word;
		mPkttype  : Byte;
		mHalen    : Byte;
		mAddr     : array[0..7] of Byte;
	end;

	RawSockaddrNetlink = record
		mFamily : Word;
		mPad    : Word;
		mPid    : Cardinal;
		mGroups : Cardinal;
	end;

	RawSockaddrHCI = record
		mFamily  : Word;
		mDev     : Word;
		mChannel : Word;
	end;

	RawSockaddrL2 = record
		mFamily      : Word;
		mPsm         : Word;
		mBdaddr      : array[0..5] of Byte;
		mCid         : Word;
		mBdaddr_type : Byte;
		m_           : array[0..0] of Byte;
	end;

	RawSockaddrRFCOMM = record
		mFamily  : Word;
		mBdaddr  : array[0..5] of Byte;
		mChannel : Byte;
		m_       : array[0..0] of Byte;
	end;

	RawSockaddrCAN = record
		mFamily  : Word;
		mIfindex : Integer;
		mAddr    : array[0..15] of Byte;
	end;

	RawSockaddrALG = record
		mFamily : Word;
		mType   : array[0..13] of Byte;
		mFeat   : Cardinal;
		mMask   : Cardinal;
		mName   : array[0..63] of Byte;
	end;

	RawSockaddrVM = record
		mFamily    : Word;
		mReserved1 : Word;
		mPort      : Cardinal;
		mCid       : Cardinal;
		mFlags     : Byte;
		mZero      : array[0..2] of Byte;
	end;

	RawSockaddrXDP = record
		mFamily         : Word;
		mFlags          : Word;
		mIfindex        : Cardinal;
		mQueue_id       : Cardinal;
		mShared_umem_fd : Cardinal;
	end;

	RawSockaddrPPPoX = array[0..$1d] of Byte;

	RawSockaddrTIPC = record
		mFamily   : Word;
		mAddrtype : Byte;
		mScope    : ShortInt;
		mAddr     : array[0..11] of Byte;
	end;

	RawSockaddrL2TPIP = record
		mFamily  : Word;
		mUnused  : Word;
		mAddr    : array[0..3] of Byte;
		mConn_id : Cardinal;
		m_       : array[0..3] of Byte;
	end;

	RawSockaddrL2TPIP6 = record
		mFamily   : Word;
		mUnused   : Word;
		mFlowinfo : Cardinal;
		mAddr     : array[0..15] of Byte;
		mScope_id : Cardinal;
		mConn_id  : Cardinal;
	end;

	RawSockaddrIUCV = record
		mFamily  : Word;
		mPort    : Word;
		mAddr    : Cardinal;
		mNodeid  : array[0..7] of ShortInt;
		mUser_id : array[0..7] of ShortInt;
		mName    : array[0..7] of ShortInt;
	end;

	RawSockaddrNFC = record
		mSa_family    : Word;
		mDev_idx      : Cardinal;
		mTarget_idx   : Cardinal;
		mNfc_protocol : Cardinal;
	end;

	Linger = record
		mOnoff  : Integer;
		mLinger : Integer;
	end;

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

	PacketMreq = record
		mIfindex : Integer;
		mType    : Word;
		mAlen    : Word;
		mAddress : array[0..7] of Byte;
	end;

	Inet4Pktinfo = record
		mIfindex  : Integer;
		mSpec_dst : array[0..3] of Byte;
		mAddr     : array[0..3] of Byte;
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
		mData : array[0..7] of Cardinal;
	end;

	Ucred = record
		mPid : Integer;
		mUid : Cardinal;
		mGid : Cardinal;
	end;

	TCPInfo = record
		mState          : Byte;
		mCa_state       : Byte;
		mRetransmits    : Byte;
		mProbes         : Byte;
		mBackoff        : Byte;
		mOptions        : Byte;
		mRto            : Cardinal;
		mAto            : Cardinal;
		mSnd_mss        : Cardinal;
		mRcv_mss        : Cardinal;
		mUnacked        : Cardinal;
		mSacked         : Cardinal;
		mLost           : Cardinal;
		mRetrans        : Cardinal;
		mFackets        : Cardinal;
		mLast_data_sent : Cardinal;
		mLast_ack_sent  : Cardinal;
		mLast_data_recv : Cardinal;
		mLast_ack_recv  : Cardinal;
		mPmtu           : Cardinal;
		mRcv_ssthresh   : Cardinal;
		mRtt            : Cardinal;
		mRttvar         : Cardinal;
		mSnd_ssthresh   : Cardinal;
		mSnd_cwnd       : Cardinal;
		mAdvmss         : Cardinal;
		mReordering     : Cardinal;
		mRcv_rtt        : Cardinal;
		mRcv_space      : Cardinal;
		mTotal_retrans  : Cardinal;
	end;

	CanFilter = record
		mId   : Cardinal;
		mMask : Cardinal;
	end;

const
	ConstSizeofSockaddrInet4     = $10;
	ConstSizeofSockaddrInet6     = $1c;
	ConstSizeofSockaddrAny       = $70;
	ConstSizeofSockaddrUnix      = $6e;
	ConstSizeofSockaddrLinklayer = $14;
	ConstSizeofSockaddrNetlink   = $c;
	ConstSizeofSockaddrHCI       = $6;
	ConstSizeofSockaddrL2        = $e;
	ConstSizeofSockaddrRFCOMM    = $a;
	ConstSizeofSockaddrCAN       = $18;
	ConstSizeofSockaddrALG       = $58;
	ConstSizeofSockaddrVM        = $10;
	ConstSizeofSockaddrXDP       = $10;
	ConstSizeofSockaddrPPPoX     = $1e;
	ConstSizeofSockaddrTIPC      = $10;
	ConstSizeofSockaddrL2TPIP    = $10;
	ConstSizeofSockaddrL2TPIP6   = $20;
	ConstSizeofSockaddrIUCV      = $20;
	ConstSizeofSockaddrNFC       = $10;
	ConstSizeofLinger            = $8;
	ConstSizeofIPMreq           = $8;
	ConstSizeofIPMreqn          = $c;
	ConstSizeofIPv6Mreq         = $14;
	ConstSizeofPacketMreq        = $10;
	ConstSizeofInet4Pktinfo      = $c;
	ConstSizeofInet6Pktinfo     = $14;
	ConstSizeofIPv6MTUInfo      = $20;
	ConstSizeofICMPv6Filter     = $20;
	ConstSizeofUcred             = $c;
	ConstSizeofTCPInfo           = $68;
	ConstSizeofCanFilter         = $8;

const
	Const_NDA_UNSPEC         = $0;
	Const_NDA_DST            = $1;
	Const_NDA_LLADDR         = $2;
	Const_NDA_CACHEINFO      = $3;
	Const_NDA_PROBES         = $4;
	Const_NDA_VLAN           = $5;
	Const_NDA_PORT           = $6;
	Const_NDA_VNI            = $7;
	Const_NDA_IFINDEX        = $8;
	Const_NDA_MASTER         = $9;
	Const_NDA_LINK_NETNSID   = $a;
	Const_NDA_SRC_VNI        = $b;
	Const_NTF_USE            = $1;
	Const_NTF_SELF           = $2;
	Const_NTF_MASTER         = $4;
	Const_NTF_PROXY          = $8;
	Const_NTF_EXT_LEARNED    = $10;
	Const_NTF_OFFLOADED      = $20;
	Const_NTF_ROUTER         = $80;
	Const_NUD_INCOMPLETE     = $1;
	Const_NUD_REACHABLE      = $2;
	Const_NUD_STALE          = $4;
	Const_NUD_DELAY          = $8;
	Const_NUD_PROBE          = $10;
	Const_NUD_FAILED         = $20;
	Const_NUD_NOARP          = $40;
	Const_NUD_PERMANENT      = $80;
	Const_NUD_NONE           = $0;
	Const_IFA_UNSPEC         = $0;
	Const_IFA_ADDRESS        = $1;
	Const_IFA_LOCAL          = $2;
	Const_IFA_LABEL          = $3;
	Const_IFA_BROADCAST      = $4;
	Const_IFA_ANYCAST        = $5;
	Const_IFA_CACHEINFO      = $6;
	Const_IFA_MULTICAST      = $7;
	Const_IFA_FLAGS          = $8;
	Const_IFA_RT_PRIORITY    = $9;
	Const_IFA_TARGET_NETNSID = $a;
	Const_RT_SCOPE_UNIVERSE  = $0;
	Const_RT_SCOPE_SITE      = $c8;
	Const_RT_SCOPE_LINK      = $fd;
	Const_RT_SCOPE_HOST      = $fe;
	Const_RT_SCOPE_NOWHERE   = $ff;
	Const_RT_TABLE_UNSPEC    = $0;
	Const_RT_TABLE_COMPAT    = $fc;
	Const_RT_TABLE_DEFAULT   = $fd;
	Const_RT_TABLE_MAIN      = $fe;
	Const_RT_TABLE_LOCAL     = $ff;
	Const_RT_TABLE_MAX       = $ffffffff;
	Const_RTA_UNSPEC         = $0;
	Const_RTA_DST            = $1;
	Const_RTA_SRC            = $2;
	Const_RTA_IIF            = $3;
	Const_RTA_OIF            = $4;
	Const_RTA_GATEWAY        = $5;
	Const_RTA_PRIORITY       = $6;
	Const_RTA_PREFSRC        = $7;
	Const_RTA_METRICS        = $8;
	Const_RTA_MULTIPATH      = $9;
	Const_RTA_FLOW           = $b;
	Const_RTA_CACHEINFO      = $c;
	Const_RTA_TABLE          = $f;
	Const_RTA_MARK           = $10;
	Const_RTA_MFC_STATS      = $11;
	Const_RTA_VIA            = $12;
	Const_RTA_NEWDST         = $13;
	Const_RTA_PREF           = $14;
	Const_RTA_ENCAP_TYPE     = $15;
	Const_RTA_ENCAP          = $16;
	Const_RTA_EXPIRES        = $17;
	Const_RTA_PAD            = $18;
	Const_RTA_UID            = $19;
	Const_RTA_TTL_PROPAGATE  = $1a;
	Const_RTA_IP_PROTO       = $1b;
	Const_RTA_SPORT          = $1c;
	Const_RTA_DPORT          = $1d;
	Const_RTN_UNSPEC         = $0;
	Const_RTN_UNICAST        = $1;
	Const_RTN_LOCAL          = $2;
	Const_RTN_BROADCAST      = $3;
	Const_RTN_ANYCAST        = $4;
	Const_RTN_MULTICAST      = $5;
	Const_RTN_BLACKHOLE      = $6;
	Const_RTN_UNREACHABLE    = $7;
	Const_RTN_PROHIBIT       = $8;
	Const_RTN_THROW          = $9;
	Const_RTN_NAT            = $a;
	Const_RTN_XRESOLVE       = $b;
	ConstSizeofNlMsghdr     = $10;
	ConstSizeofNlMsgerr     = $14;
	ConstSizeofRtGenmsg     = $1;
	ConstSizeofNlAttr       = $4;
	ConstSizeofRtAttr       = $4;
	ConstSizeofIfInfomsg    = $10;
	ConstSizeofIfAddrmsg    = $8;
	ConstSizeofIfaCacheinfo = $10;
	ConstSizeofRtMsg        = $c;
	ConstSizeofRtNexthop    = $8;
	ConstSizeofNdUseroptmsg = $10;
	ConstSizeofNdMsg        = $c;

type
	NlMsghdr = record
		mLen   : Cardinal;
		mType  : Word;
		mFlags : Word;
		mSeq   : Cardinal;
		mPid   : Cardinal;
	end;

	NlMsgerr = record
		mError : Integer;
		mMsg   : NlMsghdr;
	end;

	RtGenmsg = record
		mFamily : Byte;
	end;

	NlAttr = record
		mLen  : Word;
		mType : Word;
	end;

	RtAttr = record
		mLen  : Word;
		mType : Word;
	end;

	IfInfomsg = record
		mFamily : Byte;
		m_      : Byte;
		mType   : Word;
		mIndex  : Integer;
		mFlags  : Cardinal;
		mChange : Cardinal;
	end;

	IfAddrmsg = record
		mFamily    : Byte;
		mPrefixlen : Byte;
		mFlags     : Byte;
		mScope      : Byte;
		mIndex     : Cardinal;
	end;

	IfaCacheinfo = record
		mPrefered : Cardinal;
		mValid    : Cardinal;
		mCstamp   : Cardinal;
		mTstamp   : Cardinal;
	end;

	RtMsg = record
		mFamily   : Byte;
		mDst_len  : Byte;
		mSrc_len  : Byte;
		mTos      : Byte;
		mTable    : Byte;
		mProtocol : Byte;
		mScope    : Byte;
		mType     : Byte;
		mFlags    : Cardinal;
	end;

	RtNexthop = record
		mLen     : Word;
		mFlags   : Byte;
		mHops    : Byte;
		mIfindex : Integer;
	end;

	NdUseroptmsg = record
		mFamily    : Byte;
		mPad1      : Byte;
		mOpts_len  : Word;
		mIfindex   : Integer;
		mIcmp_type : Byte;
		mIcmp_code : Byte;
		mPad2      : Word;
		mPad3      : Cardinal;
	end;

	NdMsg = record
		mFamily  : Byte;
		mPad1    : Byte;
		mPad2    : Word;
		mIfindex : Integer;
		mState   : Word;
		mFlags   : Byte;
		mType    : Byte;
	end;

const
	ConstSizeofSockFilter = $8;

type
	SockFilter = record
		mCode : Word;
		mJt   : Byte;
		mJf   : Byte;
		mK    : Cardinal;
	end;
	PSockFilter = ^SockFilter;

	SockFprog = record
		mLen    : Word;
		mFilter : PSockFilter;
	end;

	InotifyEvent = record
		mWd     : Integer;
		mMask   : Cardinal;
		mCookie : Cardinal;
		mLen    : Cardinal;
	end;

const ConstSizeofInotifyEvent = $10;

const Const_SI_LOAD_SHIFT = $10;

type
	Utsname = record
		mSysname    : array[0..64] of Byte;
		mNodename   : array[0..64] of Byte;
		mRelease    : array[0..64] of Byte;
		mVersion    : array[0..64] of Byte;
		mMachine    : array[0..64] of Byte;
		mDomainname : array[0..64] of Byte;
	end;

const
	Const_AT_EMPTY_PATH   = $1000;
	Const_AT_FDCWD        = -$64;
	Const_AT_NO_AUTOMOUNT = $800;
	Const_AT_REMOVEDIR    = $200;

	Const_AT_STATX_SYNC_AS_STAT = $0;
	Const_AT_STATX_FORCE_SYNC   = $2000;
	Const_AT_STATX_DONT_SYNC    = $4000;

	Const_AT_SYMLINK_FOLLOW   = $400;
	Const_AT_SYMLINK_NOFOLLOW = $100;

	Const_AT_EACCESS = $200;

type
	OpenHow = record
		mFlags   : UInt64;
		mMode    : UInt64;
		mResolve : UInt64;
	end;

const ConstSizeofOpenHow = $18;

const
	Const_RESOLVE_BENEATH       = $8;
	Const_RESOLVE_IN_ROOT       = $10;
	Const_RESOLVE_NO_MAGICLINKS = $2;
	Const_RESOLVE_NO_SYMLINKS   = $4;
	Const_RESOLVE_NO_XDEV       = $1;

type
	PollFd = record
		mFd      : Integer;
		mEvents  : SmallInt;
		mRevents : SmallInt;
	end;

const
	ConstPOLLIN   = $1;
	ConstPOLLPRI  = $2;
	ConstPOLLOUT  = $4;
	ConstPOLLERR  = $8;
	ConstPOLLHUP  = $10;
	ConstPOLLNVAL = $20;

type
	SignalfdSiginfo = record
		mSigno     : Cardinal;
		mErrno     : Integer;
		mCode      : Integer;
		mPid       : Cardinal;
		mUid       : Cardinal;
		mFd        : Integer;
		mTid       : Cardinal;
		mBand      : Cardinal;
		mOverrun   : Cardinal;
		mTrapno    : Cardinal;
		mStatus    : Integer;
		mInt       : Integer;
		mPtr       : UInt64;
		mUtime     : UInt64;
		mStime     : UInt64;
		mAddr      : UInt64;
		mAddr_lsb  : Word;
		m_         : Word;
		mSyscall   : Integer;
		mCall_addr : UInt64;
		mArch      : Cardinal;
		m_1        : array[0..27] of Byte;
	end;

	Winsize = record
		mRow    : Word;
		mCol    : Word;
		mXpixel : Word;
		mYpixel : Word;
	end;

const
	Const_TASKSTATS_CMD_UNSPEC                  = $0;
	Const_TASKSTATS_CMD_GET                     = $1;
	Const_TASKSTATS_CMD_NEW                     = $2;
	Const_TASKSTATS_TYPE_UNSPEC                 = $0;
	Const_TASKSTATS_TYPE_PID                    = $1;
	Const_TASKSTATS_TYPE_TGID                   = $2;
	Const_TASKSTATS_TYPE_STATS                  = $3;
	Const_TASKSTATS_TYPE_AGGR_PID               = $4;
	Const_TASKSTATS_TYPE_AGGR_TGID              = $5;
	Const_TASKSTATS_TYPE_NULL                   = $6;
	Const_TASKSTATS_CMD_ATTR_UNSPEC             = $0;
	Const_TASKSTATS_CMD_ATTR_PID                = $1;
	Const_TASKSTATS_CMD_ATTR_TGID               = $2;
	Const_TASKSTATS_CMD_ATTR_REGISTER_CPUMASK   = $3;
	Const_TASKSTATS_CMD_ATTR_DEREGISTER_CPUMASK = $4;

type
	CGroupStats = record
		mSleeping        : UInt64;
		mRunning         : UInt64;
		mStopped         : UInt64;
		mUninterruptible : UInt64;
		mIo_wait         : UInt64;
	end;

const
	Const_CGROUPSTATS_CMD_UNSPEC        = $3;
	Const_CGROUPSTATS_CMD_GET           = $4;
	Const_CGROUPSTATS_CMD_NEW           = $5;
	Const_CGROUPSTATS_TYPE_UNSPEC       = $0;
	Const_CGROUPSTATS_TYPE_CGROUP_STATS = $1;
	Const_CGROUPSTATS_CMD_ATTR_UNSPEC   = $0;
	Const_CGROUPSTATS_CMD_ATTR_FD       = $1;

type
	Genlmsghdr = record
		mCmd      : Byte;
		mVersion  : Byte;
		mReserved : Word;
	end;

const
	Const_CTRL_CMD_UNSPEC            = $0;
	Const_CTRL_CMD_NEWFAMILY         = $1;
	Const_CTRL_CMD_DELFAMILY         = $2;
	Const_CTRL_CMD_GETFAMILY         = $3;
	Const_CTRL_CMD_NEWOPS            = $4;
	Const_CTRL_CMD_DELOPS            = $5;
	Const_CTRL_CMD_GETOPS            = $6;
	Const_CTRL_CMD_NEWMCAST_GRP      = $7;
	Const_CTRL_CMD_DELMCAST_GRP      = $8;
	Const_CTRL_CMD_GETMCAST_GRP      = $9;
	Const_CTRL_ATTR_UNSPEC           = $0;
	Const_CTRL_ATTR_FAMILY_ID        = $1;
	Const_CTRL_ATTR_FAMILY_NAME      = $2;
	Const_CTRL_ATTR_VERSION          = $3;
	Const_CTRL_ATTR_HDRSIZE          = $4;
	Const_CTRL_ATTR_MAXATTR          = $5;
	Const_CTRL_ATTR_OPS              = $6;
	Const_CTRL_ATTR_MCAST_GROUPS     = $7;
	Const_CTRL_ATTR_OP_UNSPEC        = $0;
	Const_CTRL_ATTR_OP_ID            = $1;
	Const_CTRL_ATTR_OP_FLAGS         = $2;
	Const_CTRL_ATTR_MCAST_GRP_UNSPEC = $0;
	Const_CTRL_ATTR_MCAST_GRP_NAME   = $1;
	Const_CTRL_ATTR_MCAST_GRP_ID     = $2;

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

const
	ConstPerfBitDisabled               = Const_CBitFieldMaskBit0;
	ConstPerfBitInherit                       = Const_CBitFieldMaskBit1;
	ConstPerfBitPinned                        = Const_CBitFieldMaskBit2;
	ConstPerfBitExclusive                     = Const_CBitFieldMaskBit3;
	ConstPerfBitExcludeUser                   = Const_CBitFieldMaskBit4;
	ConstPerfBitExcludeKernel                 = Const_CBitFieldMaskBit5;
	ConstPerfBitExcludeHv                     = Const_CBitFieldMaskBit6;
	ConstPerfBitExcludeIdle                   = Const_CBitFieldMaskBit7;
	ConstPerfBitMmap                          = Const_CBitFieldMaskBit8;
	ConstPerfBitComm                          = Const_CBitFieldMaskBit9;
	ConstPerfBitFreq                          = Const_CBitFieldMaskBit10;
	ConstPerfBitInheritStat                   = Const_CBitFieldMaskBit11;
	ConstPerfBitEnableOnExec                  = Const_CBitFieldMaskBit12;
	ConstPerfBitTask                          = Const_CBitFieldMaskBit13;
	ConstPerfBitWatermark                     = Const_CBitFieldMaskBit14;
	ConstPerfBitPreciseIPBit1                 = Const_CBitFieldMaskBit15;
	ConstPerfBitPreciseIPBit2                 = Const_CBitFieldMaskBit16;
	ConstPerfBitMmapData                      = Const_CBitFieldMaskBit17;
	ConstPerfBitSampleIDAll                   = Const_CBitFieldMaskBit18;
	ConstPerfBitExcludeHost                   = Const_CBitFieldMaskBit19;
	ConstPerfBitExcludeGuest                  = Const_CBitFieldMaskBit20;
	ConstPerfBitExcludeCallchainKernel        = Const_CBitFieldMaskBit21;
	ConstPerfBitExcludeCallchainUser          = Const_CBitFieldMaskBit22;
	ConstPerfBitMmap2                         = Const_CBitFieldMaskBit23;
	ConstPerfBitCommExec                      = Const_CBitFieldMaskBit24;
	ConstPerfBitUseClockID                    = Const_CBitFieldMaskBit25;
	ConstPerfBitContextSwitch                 = Const_CBitFieldMaskBit26;

const
	Const_PERF_TYPE_HARDWARE                    = $0;
	Const_PERF_TYPE_SOFTWARE                    = $1;
	Const_PERF_TYPE_TRACEPOINT                  = $2;
	Const_PERF_TYPE_HW_CACHE                    = $3;
	Const_PERF_TYPE_RAW                         = $4;
	Const_PERF_TYPE_BREAKPOINT                  = $5;
	Const_PERF_TYPE_MAX                         = $6;
	Const_PERF_COUNT_HW_CPU_CYCLES              = $0;
	Const_PERF_COUNT_HW_INSTRUCTIONS            = $1;
	Const_PERF_COUNT_HW_CACHE_REFERENCES        = $2;
	Const_PERF_COUNT_HW_CACHE_MISSES            = $3;
	Const_PERF_COUNT_HW_BRANCH_INSTRUCTIONS     = $4;
	Const_PERF_COUNT_HW_BRANCH_MISSES            = $5;
	Const_PERF_COUNT_HW_BUS_CYCLES              = $6;
	Const_PERF_COUNT_HW_STALLED_CYCLES_FRONTEND = $7;
	Const_PERF_COUNT_HW_STALLED_CYCLES_BACKEND  = $8;
	Const_PERF_COUNT_HW_REF_CPU_CYCLES          = $9;
	Const_PERF_COUNT_HW_MAX                     = $a;

type
	SockaddrStorage = record
		mFamily : Word;
		m_      : array[0..117] of ShortInt;
		m_1     : UInt64;
	end;

	TCPMD5Sig = record
		mAddr      : SockaddrStorage;
		mFlags     : Byte;
		mPrefixlen : Byte;
		mKeylen    : Word;
		m_         : Cardinal;
		mKey       : array[0..79] of Byte;
	end;

	HDDriveCmdHdr = record
		mCommand : Byte;
		mNumber  : Byte;
		mFeature : Byte;
		mCount   : Byte;
	end;

	HDDriveID = record
		mConfig         : Word;
		mCyls           : Word;
		mReserved2      : Word;
		mHeads          : Word;
		mTrack_bytes    : Word;
		mSector_bytes   : Word;
		mSectors        : Word;
		mVendor0        : Word;
		mVendor1        : Word;
		mVendor2        : Word;
		mSerial_no      : array[0..19] of Byte;
		mBuf_type       : Word;
		mBuf_size       : Word;
		mEcc_bytes      : Word;
		mFw_rev         : array[0..7] of Byte;
		mModel          : array[0..39] of Byte;
		mMax_multsect   : Byte;
		mVendor3        : Byte;
		mDword_io       : Word;
		mVendor4        : Byte;
		mCapability     : Byte;
		mReserved50     : Word;
		mVendor5        : Byte;
		mTPIO           : Byte;
		mVendor6        : Byte;
		mTDMA           : Byte;
		mField_valid    : Word;
		mCur_cyls       : Word;
		mCur_heads      : Word;
		mCur_sectors    : Word;
		mCur_capacity0  : Word;
		mCur_capacity1  : Word;
		mMultsect       : Byte;
		mMultsect_valid : Byte;
		mLba_capacity   : Cardinal;
		mDma_1word      : Word;
		mDma_mword      : Word;
		mEide_pio_modes : Word;
		mEide_dma_min   : Word;
		mEide_dma_time  : Word;
		mEide_pio       : Word;
		mEide_pio_iordy : Word;
		mWords69_70     : array[0..1] of Word;
		mWords71_74     : array[0..3] of Word;
		mQueue_depth    : Word;
		mWords76_79     : array[0..3] of Word;
		mMajor_rev_num  : Word;
		mMinor_rev_num  : Word;
		mCommand_set_1  : Word;
		mCommand_set_2  : Word;
		mCfsse          : Word;
		mCfs_enable_1   : Word;
		mCfs_enable_2   : Word;
		mCsf_default    : Word;
		mDma_ultra      : Word;
		mTrseuc         : Word;
		mTrsEuc         : Word;
		mCurAPMvalues   : Word;
		mMprc           : Word;
		mHw_config      : Word;
		mAcoustic       : Word;
		mMsrqs          : Word;
		mSxfert         : Word;
		mSal            : Word;
		mSpg            : Cardinal;
		mLba_capacity_2 : UInt64;
		mWords104_125   : array[0..21] of Word;
		mLast_lun       : Word;
		mWord127        : Word;
		mDlf            : Word;
		mCsfo           : Word;
		mWords130_155   : array[0..25] of Word;
		mWord156        : Word;
		mWords157_159   : array[0..2] of Word;
		mCfa_power      : Word;
		mWords161_175   : array[0..14] of Word;
		mWords176_205   : array[0..29] of Word;
		mWords206_254   : array[0..48] of Word;
		mIntegrity_word : Word;
	end;

const
	Const_ST_MANDLOCK    = $40;
	Const_ST_NOATIME     = $400;
	Const_ST_NODEV       = $4;
	Const_ST_NODIRATIME  = $800;
	Const_ST_NOEXEC      = $8;
	Const_ST_NOSUID      = $2;
	Const_ST_RDONLY      = $1;
	Const_ST_RELATIME    = $1000;
	Const_ST_SYNCHRONOUS = $10;

type
	Tpacket2Hdr = record
		mStatus    : Cardinal;
		mLen       : Cardinal;
		mSnaplen   : Cardinal;
		mMac       : Word;
		mNet       : Word;
		mSec       : Cardinal;
		mNsec      : Cardinal;
		mVlan_tci  : Word;
		mVlan_tpid : Word;
		m_         : array[0..3] of Byte;
	end;

	TpacketHdrVariant1 = record
		mRxhash    : Cardinal;
		mVlan_tci  : Cardinal;
		mVlan_tpid : Word;
		m_         : Word;
	end;

	Tpacket3Hdr = record
		mNext_offset : Cardinal;
		mSec         : Cardinal;
		mNsec        : Cardinal;
		mSnaplen     : Cardinal;
		mLen         : Cardinal;
		mStatus      : Cardinal;
		mMac         : Word;
		mNet         : Word;
		mHv1         : TpacketHdrVariant1;
		m_           : array[0..7] of Byte;
	end;

	TpacketBlockDesc = record
		mVersion : Cardinal;
		mTo_priv : Cardinal;
		mHdr     : array[0..39] of Byte;
	end;

	TpacketBDTS = record
		mSec  : Cardinal;
		mUsec : Cardinal;
	end;

	TpacketHdrV1 = record
		mBlock_status        : Cardinal;
		mNum_pkts            : Cardinal;
		mOffset_to_first_pkt : Cardinal;
		mBlk_len             : Cardinal;
		mSeq_num             : UInt64;
		mTs_first_pkt        : TpacketBDTS;
		mTs_last_pkt         : TpacketBDTS;
	end;

	TpacketReq = record
		mBlock_size : Cardinal;
		mBlock_nr   : Cardinal;
		mFrame_size : Cardinal;
		mFrame_nr   : Cardinal;
	end;

	TpacketReq3 = record
		mBlock_size       : Cardinal;
		mBlock_nr         : Cardinal;
		mFrame_size       : Cardinal;
		mFrame_nr         : Cardinal;
		mRetire_blk_tov   : Cardinal;
		mSizeof_priv      : Cardinal;
		mFeature_req_word : Cardinal;
	end;

	TpacketStats = record
		mPackets : Cardinal;
		mDrops   : Cardinal;
	end;

	TpacketStatsV3 = record
		mPackets      : Cardinal;
		mDrops        : Cardinal;
		mFreeze_q_cnt : Cardinal;
	end;

	TpacketAuxdata = record
		mStatus    : Cardinal;
		mLen       : Cardinal;
		mSnaplen   : Cardinal;
		mMac       : Word;
		mNet       : Word;
		mVlan_tci  : Word;
		mVlan_tpid : Word;
	end;

const
	Const_TPACKET_V1 = $0;
	Const_TPACKET_V2 = $1;
	Const_TPACKET_V3 = $2;

const
	ConstSizeofTpacket2Hdr = $20;
	ConstSizeofTpacket3Hdr = $30;

	ConstSizeofTpacketStats   = $8;
	ConstSizeofTpacketStatsV3 = $c;

type
	Nfgenmsg = record
		mNfgen_family : Byte;
		mVersion      : Byte;
		mRes_id       : Word;
	end;

type
	RTCTime = record
		mSec   : Integer;
		mMin   : Integer;
		mHour  : Integer;
		mMday  : Integer;
		mMon   : Integer;
		mYear  : Integer;
		mWday  : Integer;
		mYday  : Integer;
		mIsdst : Integer;
	end;

	RTCWkAlrm = record
		mEnabled : Byte;
		mPending : Byte;
		mTime    : RTCTime;
	end;

	BlkpgIoctlArg = record
		mOp      : Integer;
		mFlags   : Integer;
		mDatalen : Integer;
		mData    : PByte;
	end;

type
	XDPRingOffset = record
		mProducer : UInt64;
		mConsumer : UInt64;
		mDesc     : UInt64;
		mFlags    : UInt64;
	end;

	XDPMmapOffsets = record
		mRx : XDPRingOffset;
		mTx : XDPRingOffset;
		mFr : XDPRingOffset;
		mCr : XDPRingOffset;
	end;

	XDPStatistics = record
		mRx_dropped               : UInt64;
		mRx_invalid_descs         : UInt64;
		mTx_invalid_descs         : UInt64;
		mRx_ring_full             : UInt64;
		mRx_fill_ring_empty_descs : UInt64;
		mTx_ring_empty_descs      : UInt64;
	end;

	XDPDesc = record
		mAddr    : UInt64;
		mLen     : Cardinal;
		mOptions : Cardinal;
	end;

type
	ScmTimestamping = record
		mTs : array[0..2] of Timespec;
	end;

type
	SockExtendedErr = record
		mErrno  : Cardinal;
		mOrigin : Byte;
		mType   : Byte;
		mCode   : Byte;
		mPad    : Byte;
		mInfo   : Cardinal;
		mData   : Cardinal;
	end;

	FanotifyEventMetadata = record
		mEvent_len    : Cardinal;
		mVers         : Byte;
		mReserved     : Byte;
		mMetadata_len : Word;
		mMask         : UInt64;
		mFd           : Integer;
		mPid          : Integer;
	end;

	FanotifyResponse = record
		mFd       : Integer;
		mResponse : Cardinal;
	end;

type
	LoopInfo64 = record
		mDevice           : UInt64;
		mInode            : UInt64;
		mRdevice          : UInt64;
		mOffset           : UInt64;
		mSizelimit        : UInt64;
		mNumber           : Cardinal;
		mEncrypt_type     : Cardinal;
		mEncrypt_key_size : Cardinal;
		mFlags            : Cardinal;
		mFile_name        : array[0..63] of Byte;
		mCrypt_name       : array[0..63] of Byte;
		mEncrypt_key      : array[0..31] of Byte;
		mInit             : array[0..1] of UInt64;
	end;

	TIPCSocketAddr = record
		mRef  : Cardinal;
		mNode : Cardinal;
	end;

	TIPCServiceRange = record
		mType  : Cardinal;
		mLower : Cardinal;
		mUpper : Cardinal;
	end;

	TIPCServiceName = record
		mType     : Cardinal;
		mInstance : Cardinal;
		mDomain   : Cardinal;
	end;

	TIPCSubscr = record
		mSeq     : TIPCServiceRange;
		mTimeout : Cardinal;
		mFilter  : Cardinal;
		mHandle  : array[0..7] of ShortInt;
	end;

	TIPCEvent = record
		mEvent : Cardinal;
		mLower : Cardinal;
		mUpper : Cardinal;
		mPort  : TIPCSocketAddr;
		mS     : TIPCSubscr;
	end;

	TIPCGroupReq = record
		mType     : Cardinal;
		mInstance : Cardinal;
		mScope    : Cardinal;
		mFlags    : Cardinal;
	end;

type
	FsverityDigest = record
		mAlgorithm : Word;
		mSize      : Word;
	end;

	FsverityEnableArg = record
		mVersion        : Cardinal;
		mHash_algorithm : Cardinal;
		mBlock_size     : Cardinal;
		mSalt_size      : Cardinal;
		mSalt_ptr       : UInt64;
		mSig_size       : Cardinal;
		m_              : Cardinal;
		mSig_ptr        : UInt64;
		m_1             : array[0..10] of UInt64;
	end;

	Nhmsg = record
		mFamily   : Byte;
		mScope    : Byte;
		mProtocol : Byte;
		mResvd    : Byte;
		mFlags    : Cardinal;
	end;

	NexthopGrp = record
		mId     : Cardinal;
		mWeight : Byte;
		mResvd1 : Byte;
		mResvd2 : Word;
	end;

type
	WatchdogInfo = record
		mOptions  : Cardinal;
		mVersion  : Cardinal;
		mIdentity : array[0..31] of Byte;
	end;

	PPSKTime = record
		mSec   : Int64;
		mNsec  : Integer;
		mFlags : Cardinal;
	end;

	PPSKInfo = record
		mAssert_sequence : Cardinal;
		mClear_sequence  : Cardinal;
		mAssert_tu       : PPSKTime;
		mClear_tu        : PPSKTime;
		mCurrent_mode    : Integer;
		m_               : array[0..3] of Byte;
	end;

	PPSFData = record
		mInfo    : PPSKInfo;
		mTimeout : PPSKTime;
	end;

	PPSKParams = record
		mApi_version   : Integer;
		mMode          : Integer;
		mAssert_off_tu : PPSKTime;
		mClear_off_tu  : PPSKTime;
	end;

type
	EthtoolDrvinfo = record
		mCmd          : Cardinal;
		mDriver       : array[0..31] of Byte;
		mVersion      : array[0..31] of Byte;
		mFw_version   : array[0..31] of Byte;
		mBus_info     : array[0..31] of Byte;
		mErom_version : array[0..31] of Byte;
		mReserved2    : array[0..11] of Byte;
		mN_priv_flags : Cardinal;
		mN_stats      : Cardinal;
		mTestinfo_len : Cardinal;
		mEedump_len   : Cardinal;
		mRegdump_len  : Cardinal;
	end;

	HIDRawReportDescriptor = record
		mSize  : Cardinal;
		mValue : array[0..4095] of Byte;
	end;

	HIDRawDevInfo = record
		mBustype : Cardinal;
		mVendor  : SmallInt;
		mProduct : SmallInt;
	end;

type
	EraseInfo = record
		mStart  : Cardinal;
		mLength : Cardinal;
	end;

	EraseInfo64 = record
		mStart  : UInt64;
		mLength : UInt64;
	end;

	MtdOobBuf = record
		mStart  : Cardinal;
		mLength : Cardinal;
		mPtr    : PByte;
	end;

	MtdOobBuf64 = record
		mStart  : UInt64;
		mPad    : Cardinal;
		mLength : Cardinal;
		mPtr    : UInt64;
	end;

	MtdWriteReq = record
		mStart  : UInt64;
		mLen    : UInt64;
		mOoblen : UInt64;
		mData   : UInt64;
		mOob    : UInt64;
		mMode   : Byte;
		m_      : array[0..6] of Byte;
	end;

	MtdInfo = record
		mType      : Byte;
		mFlags     : Cardinal;
		mSize      : Cardinal;
		mErasesize : Cardinal;
		mWritesize : Cardinal;
		mOobsize   : Cardinal;
		m_         : UInt64;
	end;

	RegionInfo = record
		mOffset      : Cardinal;
		mErasesize   : Cardinal;
		mNumblocks   : Cardinal;
		mRegionindex : Cardinal;
	end;

	OtpInfo = record
		mStart  : Cardinal;
		mLength : Cardinal;
		mLocked : Cardinal;
	end;

	NandOobinfo = record
		mUseecc   : Cardinal;
		mEccbytes : Cardinal;
		mOobfree  : array[0..7, 0..1] of Cardinal;
		mEccpos   : array[0..31] of Cardinal;
	end;

	NandOobfree = record
		mOffset : Cardinal;
		mLength : Cardinal;
	end;

	NandEcclayout = record
		mEccbytes : Cardinal;
		mEccpos   : array[0..63] of Cardinal;
		mOobavail : Cardinal;
		mOobfree  : array[0..7] of NandOobfree;
	end;

	MtdEccStats = record
		mCorrected : Cardinal;
		mFailed    : Cardinal;
		mBadblocks : Cardinal;
		mBbtblocks : Cardinal;
	end;

implementation

type
	_C_short = SmallInt;
	_C_int   = Integer;
	_C_long_long = Int64;

	_Gid_t = Cardinal;
	_Socklen = Cardinal;

	cpuMask = UInt64;

const
	Const__CPU_SETSIZE = $400;

type
	TpacketHdr = record
		mStatus  : UInt64;
		mLen     : Cardinal;
		mSnaplen : Cardinal;
		mMac     : Word;
		mNet     : Word;
		mSec     : Cardinal;
		mUsec    : Cardinal;
		m_       : array[0..3] of Byte;
	end;

const
	ConstSizeofTpacketHdr = $20;

end.
