{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.TypesWindowsArm;

interface

type
	TWSAData = record
		mVersion : UInt16;
		mHighVersion : UInt16;
		mDescription : array[ 0 .. 256 ] of Byte; // WSADESCRIPTION_LEN + 1
		mSystemStatus : array[ 0 .. 128 ] of Byte; // WSASYS_STATUS_LEN + 1
		mMaxSockets : UInt16;
		mMaxUdpDg : UInt16;
		mVendorInfo : PByte;
	end;

	TServent = record
		mName : PByte;
		mAliases : ^PByte;
		mPort : UInt16;
		mProto : PByte;
	end;

	TJOBOBJECT_BASIC_LIMIT_INFORMATION = record
		mPerProcessUserTimeLimit : Int64;
		mPerJobUserTimeLimit : Int64;
		mLimitFlags : UInt32;
		mMinimumWorkingSetSize : NativeUInt;
		mMaximumWorkingSetSize : NativeUInt;
		mActiveProcessLimit : UInt32;
		mAffinity : NativeUInt;
		mPriorityClass : UInt32;
		mSchedulingClass : UInt32;
		mPadding : UInt32; // pad to 8 byte boundary
	end;

implementation

end.
