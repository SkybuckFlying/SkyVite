{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.WinRT;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function RoInitialize( ParaThreadType : Cardinal ) : HRESULT;
function RoActivateInstance( ParaClsid : string ) : IInspectable;
function RoGetActivationFactory( ParaClsid : string; ParaIid : PGUID ) : IInspectable;

type
	HString = Pointer;

function NewHString( ParaS : string ) : HString;
function DeleteHString( ParaHstring : HString ) : HRESULT;
function HStringToString( ParaH : HString ) : string;

implementation

uses
	Winapi.Windows,
	Vendor.Github.Com.GoOle.GoOle.Com
;

function RoInitialize( ParaThreadType : Cardinal ) : HRESULT;
begin
	{$IFDEF MSWINDOWS}
	// Result := Winapi.Winrt.RoInitialize( ParaThreadType );
	Result := E_NOTIMPL; // Placeholder
	{$ELSE}
	Result := E_NOTIMPL;
	{$ENDIF}
end;

function RoActivateInstance( ParaClsid : string ) : IInspectable;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function RoGetActivationFactory( ParaClsid : string; ParaIid : PGUID ) : IInspectable;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function NewHString( ParaS : string ) : HString;
begin
	Result := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function DeleteHString( ParaHstring : HString ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function HStringToString( ParaH : HString ) : string;
begin
	Result := '';
end;

end.
