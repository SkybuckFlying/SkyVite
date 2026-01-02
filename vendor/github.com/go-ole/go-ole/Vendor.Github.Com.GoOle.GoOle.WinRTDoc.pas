{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.WinRTDoc;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.WinRT,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.WinRT,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function RoInitialize( ParaThreadType : Cardinal ) : HRESULT;
function RoActivateInstance( ParaClsid : string ) : IInspectable;
function RoGetActivationFactory( ParaClsid : string; ParaIid : PGUID ) : IInspectable;

implementation

function RoInitialize( ParaThreadType : Cardinal ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function RoActivateInstance( ParaClsid : string ) : IInspectable;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function RoGetActivationFactory( ParaClsid : string; ParaIid : PGUID ) : IInspectable;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
