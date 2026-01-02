{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoFunc;

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

function GetClassInfo( ParaDisp : IProvideClassInfo ) : ITypeInfo;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
