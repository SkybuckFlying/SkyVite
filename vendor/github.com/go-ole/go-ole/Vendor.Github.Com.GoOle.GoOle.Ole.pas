unit Vendor.Github.Com.GoOle.GoOle.Ole;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.Guid;

type
	TDISPPARAMS = record
	public
		mRgvarg            : Pointer;
		mRgdispidNamedArgs : Pointer;
		mCArgs             : Cardinal;
		mCNamedArgs        : Cardinal;
	end;

	TEXCEPINFO = record
	public
		mWCode             : Word;
		mWReserved         : Word;
		mBstrSource        : PWideChar;
		mBstrDescription   : PWideChar;
		mBstrHelpFile      : PWideChar;
		mDwHelpContext     : Cardinal;
		mPvReserved        : Pointer;
		mPfnDeferredFillIn : Pointer;
		mScode             : Cardinal;

		function WCode : Word;
		function SCODE : Cardinal;
		function ToString : string;
		function Error : string;
	end;

	TPARAMDATA = record
	public
		mName : PSmallInt;
		mVt   : Word;
	end;

	TMETHODDATA = record
	public
		mName     : PWideChar;
		mData     : ^TPARAMDATA;
		mDispid   : Integer;
		mMeth     : Cardinal;
		mCC       : Integer;
		mCArgs    : Cardinal;
		mFlags    : Word;
		mVtReturn : Cardinal;
	end;

	TINTERFACEDATA = record
	public
		mMethodData : ^TMETHODDATA;
		mCMembers   : Cardinal;
	end;

	TPoint = record
	public
		mX : Integer;
		mY : Integer;
	end;

	TMsg = record
	public
		mHwnd    : Cardinal;
		mMessage : Cardinal;
		mWparam  : Integer;
		mLparam  : Integer;
		mTime    : Cardinal;
		mPt      : TPoint;
	end;

	TTYPEDESC = record
	public
		mHreftype : Cardinal;
		mVT       : Word;
	end;

	TIDLDESC = record
	public
		mDwReserved : Cardinal;
		mWIDLFlags  : Word;
	end;

	TTYPEATTR = record
	public
		mGuid             : TGUID;
		mLcid             : Cardinal;
		mDwReserved       : Cardinal;
		mMemidConstructor : Integer;
		mMemidDestructor  : Integer;
		mLpstrSchema      : PWideChar;
		mCbSizeInstance   : Cardinal;
		mTypekind         : Integer;
		mCFuncs           : Word;
		mCVars            : Word;
		mCImplTypes       : Word;
		mCbSizeVft        : Word;
		mCbAlignment      : Word;
		mWTypeFlags       : Word;
		mWMajorVerNum     : Word;
		mWMinorVerNum     : Word;
		mTdescAlias       : TTYPEDESC;
		mIdldescType      : TIDLDESC;
	end;

implementation

{ TEXCEPINFO }

function TEXCEPINFO.WCode : Word;
begin
	Result := mWCode;
end;

function TEXCEPINFO.SCODE : Cardinal;
begin
	Result := mScode;
end;

function TEXCEPINFO.ToString : string;
begin
	Result := Format( 'wCode: %d, scode: %d', [ mWCode, mScode ] );
end;

function TEXCEPINFO.Error : string;
begin
	if mBstrDescription <> nil then
		Result := string( mBstrDescription )
	else
		Result := 'Unknown: ' + IntToHex( mScode, 8 );
end;

end.
