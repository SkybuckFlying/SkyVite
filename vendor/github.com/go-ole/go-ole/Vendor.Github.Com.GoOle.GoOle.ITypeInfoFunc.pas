{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.ITypeInfoFunc;

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
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
