unit Vendor.Github.Com.GoOle.GoOle.ITypeInfo;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Ole;

type
	ITypeInfo = class( IUnknown )
	public
		function GetTypeAttr( out ParaAttr : ^TTYPEATTR ) : HRESULT;
		procedure ReleaseTypeAttr( ParaAttr : Pointer );
	end;

implementation

uses
	Winapi.ActiveX;

function ITypeInfo.GetTypeAttr( out ParaAttr : ^TTYPEATTR ) : HRESULT;
var
	vTI : Winapi.ActiveX.ITypeInfo;
begin
	vTI := Winapi.ActiveX.ITypeInfo( RawVTable );
	Result := vTI.GetTypeAttr( Pointer( ParaAttr ) );
end;

procedure ITypeInfo.ReleaseTypeAttr( ParaAttr : Pointer );
var
	vTI : Winapi.ActiveX.ITypeInfo;
begin
	vTI := Winapi.ActiveX.ITypeInfo( RawVTable );
	vTI.ReleaseTypeAttr( ParaAttr );
end;

end.
