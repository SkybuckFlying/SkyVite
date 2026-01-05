{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZtypesIllumosAmd64;

interface

{$IFDEF FPC}
uses
	SysUtils;
{$ELSE}
uses
	System.SysUtils;
{$ENDIF}

const
	ConstTUNNEWPPA = $540001;
	ConstTUNSETPPA = $540002;

	Const_I_STR     = $5308;
	Const_I_POP     = $5303;
	Const_I_PUSH    = $5302;
	Const_I_PLINK   = $5316;
	Const_I_PUNLINK = $5317;

	Const_IF_UNITSEL = -$7ffb8cca;

type
	Strioctl = record
		mCmd    : Integer;
		mTimout : Integer;
		mLen    : Integer;
		mDp     : PShortInt;
	end;

	Lifreq = record
		mName   : array[0..31] of ShortInt;
		mLifru1 : array[0..3] of Byte;
		mType   : Cardinal;
		mLifru  : array[0..335] of Byte;
	end;

implementation

type
	strbuf = record
		mMaxlen : Integer;
		mLen    : Integer;
		mBuf    : PShortInt;
	end;

end.
