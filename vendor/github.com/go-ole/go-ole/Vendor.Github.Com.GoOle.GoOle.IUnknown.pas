unit Vendor.Github.Com.GoOle.GoOle.IUnknown;

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
  Vendor.Github.Com.GoOle.GoOle.WinRTDoc;

type
	IUnknown = class
	private
		mRawVTable : Pointer;
	public
		property RawVTable : Pointer read mRawVTable write mRawVTable;

		function QueryInterface( ParaIid : PGUID; out ParaDisp : Pointer ) : HRESULT;
		function AddRef : Integer;
		function Release : Integer;
	end;

implementation

uses
	Winapi.ActiveX;

function IUnknown.QueryInterface( ParaIid : PGUID; out ParaDisp : Pointer ) : HRESULT;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk.QueryInterface( ParaIid^, ParaDisp );
end;

function IUnknown.AddRef : Integer;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk._AddRef;
end;

function IUnknown.Release : Integer;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk._Release;
end;

end.
