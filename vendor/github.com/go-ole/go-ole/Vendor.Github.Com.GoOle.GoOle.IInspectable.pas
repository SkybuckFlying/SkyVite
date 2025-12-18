unit Vendor.Github.Com.GoOle.GoOle.IInspectable;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Guid;

type
	IInspectable = class( IUnknown )
	public
		function GetIIds( out ParaIidCount : Cardinal; out ParaIids : Pointer ) : HRESULT;
		function GetRuntimeClassName( out ParaClassName : PWideChar ) : HRESULT;
		function GetTrustLevel( out ParaTrustLevel : Cardinal ) : HRESULT;
	end;

implementation

function IInspectable.GetIIds( out ParaIidCount : Cardinal; out ParaIids : Pointer ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function IInspectable.GetRuntimeClassName( out ParaClassName : PWideChar ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function IInspectable.GetTrustLevel( out ParaTrustLevel : Cardinal ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

end.
