unit Vendor.Github.Com.GoOle.GoOle.Com;

interface

uses
  System.Classes,
  System.SysUtils,
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
  Winapi.ActiveX,
  Winapi.Windows;

function CoInitialize( ParaP : Pointer ) : HRESULT;
function CoInitializeEx( ParaP : Pointer; ParaCoinit : Cardinal ) : HRESULT;
procedure CoUninitialize;
procedure CoTaskMemFree( ParaMemptr : Pointer );
function CLSIDFromProgID( ParaProgId : string; out ParaClsid : TGUID ) : HRESULT;
function CLSIDFromString( ParaStr : string; out ParaClsid : TGUID ) : HRESULT;
function StringFromCLSID( const ParaClsid : TGUID; out ParaStr : string ) : HRESULT;
function IIDFromString( ParaProgId : string; out ParaClsid : TGUID ) : HRESULT;
function StringFromIID( const ParaIid : TGUID; out ParaStr : string ) : HRESULT;
function CreateInstance( const ParaClsid : TGUID; const ParaIid : TGUID; out ParaUnk : Pointer ) : HRESULT;
function GetActiveObject( const ParaClsid : TGUID; const ParaIid : TGUID; out ParaUnk : Pointer ) : HRESULT;
function VariantInit( var ParaV : TVariantArg ) : HRESULT;
function VariantClear( var ParaV : TVariantArg ) : HRESULT;
function SysAllocString( ParaV : string ) : PWideChar;
function SysAllocStringLen( ParaV : string ) : PWideChar;
function SysFreeString( ParaV : PWideChar ) : HRESULT;
function SysStringLen( ParaV : PWideChar ) : Cardinal;

implementation

function CoInitialize( ParaP : Pointer ) : HRESULT;
begin
	Result := Winapi.ActiveX.CoInitialize( ParaP );
end;

function CoInitializeEx( ParaP : Pointer; ParaCoinit : Cardinal ) : HRESULT;
begin
	Result := Winapi.ActiveX.CoInitializeEx( ParaP, ParaCoinit );
end;

procedure CoUninitialize;
begin
	Winapi.ActiveX.CoUninitialize;
end;

procedure CoTaskMemFree( ParaMemptr : Pointer );
begin
	Winapi.ActiveX.CoTaskMemFree( ParaMemptr );
end;

function CLSIDFromProgID( ParaProgId : string; out ParaClsid : TGUID ) : HRESULT;
begin
	Result := Winapi.ActiveX.CLSIDFromProgID( PWideChar( ParaProgId ), System.TGUID( ParaClsid ) );
end;

function CLSIDFromString( ParaStr : string; out ParaClsid : TGUID ) : HRESULT;
begin
	Result := Winapi.ActiveX.CLSIDFromString( PWideChar( ParaStr ), System.TGUID( ParaClsid ) );
end;

function StringFromCLSID( const ParaClsid : TGUID; out ParaStr : string ) : HRESULT;
var
	vPtr : PWideChar;
begin
	Result := Winapi.ActiveX.StringFromCLSID( System.TGUID( ParaClsid ), vPtr );
	if Succeeded( Result ) then
	begin
		ParaStr := string( vPtr );
		CoTaskMemFree( vPtr );
	end;
end;

function IIDFromString( ParaProgId : string; out ParaClsid : TGUID ) : HRESULT;
begin
	Result := Winapi.ActiveX.IIDFromString( PWideChar( ParaProgId ), System.TGUID( ParaClsid ) );
end;

function StringFromIID( const ParaIid : TGUID; out ParaStr : string ) : HRESULT;
var
	vPtr : PWideChar;
begin
	Result := Winapi.ActiveX.StringFromIID( System.TGUID( ParaIid ), vPtr );
	if Succeeded( Result ) then
	begin
		ParaStr := string( vPtr );
		CoTaskMemFree( vPtr );
	end;
end;

function CreateInstance( const ParaClsid : TGUID; const ParaIid : TGUID; out ParaUnk : Pointer ) : HRESULT;
begin
	Result := Winapi.ActiveX.CoCreateInstance( System.TGUID( ParaClsid ), nil, CLSCTX_ALL, System.TGUID( ParaIid ), ParaUnk );
end;

function GetActiveObject( const ParaClsid : TGUID; const ParaIid : TGUID; out ParaUnk : Pointer ) : HRESULT;
var
	vUnk : IUnknown;
begin
	Result := Winapi.ActiveX.GetActiveObject( System.TGUID( ParaClsid ), nil, vUnk );
	if Succeeded( Result ) then
		Result := vUnk.QueryInterface( System.TGUID( ParaIid ), ParaUnk );
end;

function VariantInit( var ParaV : TVariantArg ) : HRESULT;
begin
	System.Variants.VariantInit( ParaV );
	Result := S_OK;
end;

function VariantClear( var ParaV : TVariantArg ) : HRESULT;
begin
	Result := Winapi.ActiveX.VariantClear( ParaV );
end;

function SysAllocString( ParaV : string ) : PWideChar;
begin
	Result := Winapi.ActiveX.SysAllocString( PWideChar( ParaV ) );
end;

function SysAllocStringLen( ParaV : string ) : PWideChar;
begin
	Result := Winapi.ActiveX.SysAllocStringLen( PWideChar( ParaV ), Length( ParaV ) );
end;

function SysFreeString( ParaV : PWideChar ) : HRESULT;
begin
	Winapi.ActiveX.SysFreeString( ParaV );
	Result := S_OK;
end;

function SysStringLen( ParaV : PWideChar ) : Cardinal;
begin
	Result := Winapi.ActiveX.SysStringLen( ParaV );
end;

end.
