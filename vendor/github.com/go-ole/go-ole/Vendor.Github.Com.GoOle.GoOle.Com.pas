unit Vendor.Github.Com.GoOle.GoOle.Com;

interface

uses
	System.Classes,
	System.SysUtils,
	Winapi.Windows,
	Winapi.ActiveX,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Ole;

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
