{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainerFunc;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils, Rtti
;
{$ELSE}
uses
	System.Classes, System.SysUtils, System.Rtti
;
{$ENDIF}

uses
	Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainer,
	Vendor.Github.Com.GoOle.GoOle.IConnectionPoint,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;

type
	TIConnectionPointContainerHelper = class helper for IConnectionPointContainer
	public
		function EnumConnectionPoints( ParaPoints : TValue ) : Exception;
		function FindConnectionPoint( ParaIid : PGUID; out ParaPoint : Pointer ) : Exception;
	end;

implementation

function TIConnectionPointContainerHelper.EnumConnectionPoints( ParaPoints : TValue ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

function TIConnectionPointContainerHelper.FindConnectionPoint( ParaIid : PGUID; out ParaPoint : Pointer ) : Exception;
begin
	ParaPoint := nil;
	Result := TOleError.Create( E_NOTIMPL );
end;

end.
