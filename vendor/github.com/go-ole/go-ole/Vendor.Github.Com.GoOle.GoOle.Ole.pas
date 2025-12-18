unit Vendor.Github.Com.GoOle.GoOle.Ole;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.GoOle.GoOle.Com,
  Vendor.Github.Com.GoOle.GoOle.ComFunc,
  Vendor.Github.Com.GoOle.GoOle.Connect,
  Vendor.Github.Com.GoOle.GoOle.Constants,
  Vendor.Github.Com.GoOle.GoOle.Error,
  Vendor.Github.Com.GoOle.GoOle.ErrorFunc,
  Vendor.Github.Com.GoOle.GoOle.ErrorWindows,
  Vendor.Github.Com.GoOle.GoOle.Guid,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPoint,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainer,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainerFunc,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainerWindows,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPointFunc,
  Vendor.Github.Com.GoOle.GoOle.IConnectionPointWindows,
  Vendor.Github.Com.GoOle.GoOle.IDispatch,
  Vendor.Github.Com.GoOle.GoOle.IDispatchFunc,
  Vendor.Github.Com.GoOle.GoOle.IDispatchWindows,
  Vendor.Github.Com.GoOle.GoOle.IEnumVariant,
  Vendor.Github.Com.GoOle.GoOle.IEnumVariantFunc,
  Vendor.Github.Com.GoOle.GoOle.IEnumVariantWindows,
  Vendor.Github.Com.GoOle.GoOle.IInspectable,
  Vendor.Github.Com.GoOle.GoOle.IInspectableFunc,
  Vendor.Github.Com.GoOle.GoOle.IInspectableWindows,
  Vendor.Github.Com.GoOle.GoOle.IProvideClassInfo,
  Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoFunc,
  Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoWindows,
  Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
  Vendor.Github.Com.GoOle.GoOle.ITypeInfoFunc,
  Vendor.Github.Com.GoOle.GoOle.ITypeInfoWindows,
  Vendor.Github.Com.GoOle.GoOle.IUnknown,
  Vendor.Github.Com.GoOle.GoOle.IUnknownFunc,
  Vendor.Github.Com.GoOle.GoOle.IUnknownWindows,
  Vendor.Github.Com.GoOle.GoOle.SafeArray,
  Vendor.Github.Com.GoOle.GoOle.SafeArrayConversion,
  Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc,
  Vendor.Github.Com.GoOle.GoOle.SafeArraySlices,
  Vendor.Github.Com.GoOle.GoOle.SafeArrayWindows,
  Vendor.Github.Com.GoOle.GoOle.Utility,
  Vendor.Github.Com.GoOle.GoOle.Variables,
  Vendor.Github.Com.GoOle.GoOle.Variant,
  Vendor.Github.Com.GoOle.GoOle.Variant386,
  Vendor.Github.Com.GoOle.GoOle.VariantAmd64,
  Vendor.Github.Com.GoOle.GoOle.VariantS390x,
  Vendor.Github.Com.GoOle.GoOle.VtString,
  Vendor.Github.Com.GoOle.GoOle.WinRT,
  Vendor.Github.Com.GoOle.GoOle.WinRTDoc;

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
