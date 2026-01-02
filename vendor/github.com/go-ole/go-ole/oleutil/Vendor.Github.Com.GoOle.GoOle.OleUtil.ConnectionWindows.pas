{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.OleUtil.ConnectionWindows;

interface

{$IFDEF FPC}
uses
	SysUtils, Rtti,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils, System.Rtti,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function ConnectObject( ParaDisp : IDispatch; ParaIid : PGUID; ParaIdisp : TObject ) : Cardinal;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.IConnectionPoint,
	Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainer,
	Vendor.Github.Com.GoOle.GoOle.IUnknown
;

function ConnectObject( ParaDisp : IDispatch; ParaIid : PGUID; ParaIdisp : TObject ) : Cardinal;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
