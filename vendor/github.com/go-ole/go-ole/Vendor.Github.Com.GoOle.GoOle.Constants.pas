unit Vendor.Github.Com.GoOle.GoOle.Constants;

interface

uses
  Vendor.Github.Com.GoOle.GoOle.Com,
  Vendor.Github.Com.GoOle.GoOle.ComFunc,
  Vendor.Github.Com.GoOle.GoOle.Connect,
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
  Vendor.Github.Com.GoOle.GoOle.Ole,
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
  Vendor.Github.Com.GoOle.GoOle.WinRTDoc,
  Winapi.ActiveX;

const
	CLSCTX_INPROC_SERVER   = 1;
	CLSCTX_INPROC_HANDLER  = 2;
	CLSCTX_LOCAL_SERVER    = 4;
	CLSCTX_INPROC_SERVER16 = 8;
	CLSCTX_REMOTE_SERVER   = 16;
	CLSCTX_ALL             = CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER or CLSCTX_LOCAL_SERVER;
	CLSCTX_INPROC          = CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER;
	CLSCTX_SERVER          = CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER or CLSCTX_REMOTE_SERVER;

	COINIT_APARTMENTTHREADED = $2;
	COINIT_MULTITHREADED     = $0;
	COINIT_DISABLE_OLE1DDE   = $4;
	COINIT_SPEED_OVER_MEMORY = $8;

	DISPATCH_METHOD         = 1;
	DISPATCH_PROPERTYGET    = 2;
	DISPATCH_PROPERTYPUT    = 4;
	DISPATCH_PROPERTYPUTREF = 8;

	S_OK           = $00000000;
	E_UNEXPECTED   = $8000FFFF;
	E_NOTIMPL      = $80004001;
	E_OUTOFMEMORY  = $8007000E;
	E_INVALIDARG   = $80070057;
	E_NOINTERFACE  = $80004002;
	E_POINTER      = $80004003;
	E_HANDLE       = $80070006;
	E_ABORT        = $80004004;
	E_FAIL         = $80004005;
	E_ACCESSDENIED = $80070005;
	E_PENDING      = $8000000A;

	CO_E_CLASSSTRING = $800401F3;

	CC_FASTCALL = 0;
	CC_CDECL = 1;
	CC_MSCPASCAL = 2;
	CC_PASCAL = CC_MSCPASCAL;
	CC_MACPASCAL = 3;
	CC_STDCALL = 4;
	CC_FPFASTCALL = 5;
	CC_SYSCALL = 6;
	CC_MPWCDECL = 7;
	CC_MPWPASCAL = 8;
	CC_MAX = CC_MPWPASCAL;

type
	VT = Word;

const
	VT_EMPTY           : VT = $0;
	VT_NULL            : VT = $1;
	VT_I2              : VT = $2;
	VT_I4              : VT = $3;
	VT_R4              : VT = $4;
	VT_R8              : VT = $5;
	VT_CY              : VT = $6;
	VT_DATE            : VT = $7;
	VT_BSTR            : VT = $8;
	VT_DISPATCH        : VT = $9;
	VT_ERROR           : VT = $a;
	VT_BOOL            : VT = $b;
	VT_VARIANT         : VT = $c;
	VT_UNKNOWN         : VT = $d;
	VT_DECIMAL         : VT = $e;
	VT_I1              : VT = $10;
	VT_UI1             : VT = $11;
	VT_UI2             : VT = $12;
	VT_UI4             : VT = $13;
	VT_I8              : VT = $14;
	VT_UI8             : VT = $15;
	VT_INT             : VT = $16;
	VT_UINT            : VT = $17;
	VT_VOID            : VT = $18;
	VT_HRESULT         : VT = $19;
	VT_PTR             : VT = $1a;
	VT_SAFEARRAY       : VT = $1b;
	VT_CARRAY          : VT = $1c;
	VT_USERDEFINED     : VT = $1d;
	VT_LPSTR           : VT = $1e;
	VT_LPWSTR          : VT = $1f;
	VT_RECORD          : VT = $24;
	VT_INT_PTR         : VT = $25;
	VT_UINT_PTR        : VT = $26;
	VT_FILETIME        : VT = $40;
	VT_BLOB            : VT = $41;
	VT_STREAM          : VT = $42;
	VT_STORAGE         : VT = $43;
	VT_STREAMED_OBJECT : VT = $44;
	VT_STORED_OBJECT   : VT = $45;
	VT_BLOB_OBJECT     : VT = $46;
	VT_CF              : VT = $47;
	VT_CLSID           : VT = $48;
	VT_BSTR_BLOB       : VT = $fff;
	VT_VECTOR          : VT = $1000;
	VT_ARRAY           : VT = $2000;
	VT_BYREF           : VT = $4000;
	VT_RESERVED        : VT = $8000;
	VT_ILLEGAL         : VT = $ffff;
	VT_ILLEGALMASKED   : VT = $fff;
	VT_TYPEMASK        : VT = $fff;

	DISPID_UNKNOWN     = -1;
	DISPID_VALUE       = 0;
	DISPID_PROPERTYPUT = -3;
	DISPID_NEWENUM     = -4;
	DISPID_EVALUATE    = -5;
	DISPID_CONSTRUCTOR = -6;
	DISPID_DESTRUCTOR  = -7;
	DISPID_COLLECT     = -8;

	TKIND_ENUM      = 1;
	TKIND_RECORD    = 2;
	TKIND_MODULE    = 3;
	TKIND_INTERFACE = 4;
	TKIND_DISPATCH  = 5;
	TKIND_COCLASS   = 6;
	TKIND_ALIAS     = 7;
	TKIND_UNION     = 8;
	TKIND_MAX       = 9;

	FADF_AUTO        = $0001;
	FADF_STATIC      = $0002;
	FADF_EMBEDDED    = $0004;
	FADF_FIXEDSIZE   = $0010;
	FADF_RECORD      = $0020;
	FADF_HAVEIID     = $0040;
	FADF_HAVEVARTYPE = $0080;
	FADF_BSTR        = $0100;
	FADF_UNKNOWN     = $0200;
	FADF_DISPATCH    = $0400;
	FADF_VARIANT     = $0800;
	FADF_RESERVED    = $F008;

implementation

end.
