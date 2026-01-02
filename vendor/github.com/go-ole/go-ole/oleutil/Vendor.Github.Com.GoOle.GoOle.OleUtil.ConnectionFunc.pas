{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.OleUtil.ConnectionFunc;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function ConnectObject( ParaDisp : IDispatch; ParaIid : PGUID; ParaIdisp : TObject ) : Cardinal;

implementation

function ConnectObject( ParaDisp : IDispatch; ParaIid : PGUID; ParaIdisp : TObject ) : Cardinal;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
