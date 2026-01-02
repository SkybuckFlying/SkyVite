{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoWindows;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IProvideClassInfo,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IProvideClassInfo,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function GetClassInfo( ParaDisp : IProvideClassInfo ) : ITypeInfo;

implementation

uses
	Winapi.ActiveX
;

type
	IWinRTProvideClassInfo = interface(IUnknown)
		['{B196B283-BAB4-101A-B69C-00AA00341D07}']
		function GetClassInfo( out ParaTypeInfo : Pointer ) : HRESULT; stdcall;
	end;

function GetClassInfo( ParaDisp : IProvideClassInfo ) : ITypeInfo;
var
	vTypeInfoPtr : Pointer;
	vHR : HRESULT;
begin
	vTypeInfoPtr := nil;
	vHR := IWinRTProvideClassInfo( ParaDisp.RawVTable ).GetClassInfo( vTypeInfoPtr );
	if vHR <> S_OK then
	begin
		raise TOleError.Create( vHR );
	end;

	Result := ITypeInfo.Create;
	Result.RawVTable := vTypeInfoPtr;
end;

end.
