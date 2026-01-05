{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Windows.TypesWindowsAmd64;

interface

type
	TWSAData = record
		mVersion : UInt16;
		mHighVersion : UInt16;
		mMaxSockets : UInt16;
		mMaxUdpDg : UInt16;
		mVendorInfo : PByte;
		mDescription : array[ 0 .. 256 ] of Byte; // WSADESCRIPTION_LEN + 1
		mSystemStatus : array[ 0 .. 128 ] of Byte; // WSASYS_STATUS_LEN + 1
	end;

	TServent = record
		mName : PByte;
		mAliases : ^PByte;
		mProto : PByte;
		mPort : UInt16;
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
	end;

implementation

end.
