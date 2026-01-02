{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IInspectableFunc;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

function GetIids( ParaV : IInspectable ) : TArray<PGUID>;
function GetRuntimeClassName( ParaV : IInspectable ) : string;
function GetTrustLevel( ParaV : IInspectable ) : Cardinal;

implementation

function GetIids( ParaV : IInspectable ) : TArray<PGUID>;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function GetRuntimeClassName( ParaV : IInspectable ) : string;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function GetTrustLevel( ParaV : IInspectable ) : Cardinal;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
