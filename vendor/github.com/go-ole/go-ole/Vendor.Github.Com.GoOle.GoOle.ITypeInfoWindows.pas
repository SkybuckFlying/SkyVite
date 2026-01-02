{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.ITypeInfoWindows;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

uses
	Winapi.ActiveX
;

function GetTypeAttr( ParaV : ITypeInfo ) : PTypeAttr;

implementation

function GetTypeAttr( ParaV : ITypeInfo ) : PTypeAttr;
var
	vAttr : PTypeAttr;
	vHR : HRESULT;
begin
	vAttr := nil;
	vHR := ParaV.GetTypeAttr( vAttr );
	if vHR <> S_OK then
	begin
		raise TOleError.Create( vHR );
	end;
	Result := vAttr;
end;

end.
