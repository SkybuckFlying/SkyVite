{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainerWindows;

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
	TIConnectionPointContainerWindowsHelper = class helper for IConnectionPointContainer
	public
		function EnumConnectionPoints( ParaPoints : TValue ) : Exception;
		function FindConnectionPoint( ParaIid : PGUID; out ParaPoint : Pointer ) : Exception;
	end;

implementation

function TIConnectionPointContainerWindowsHelper.EnumConnectionPoints( ParaPoints : TValue ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

type
	TFindConnectionPointFunc = function( ParaSelf : Pointer; ParaIid : PGUID; out ParaPoint : Pointer ) : HRESULT; stdcall;

function TIConnectionPointContainerWindowsHelper.FindConnectionPoint( ParaIid : PGUID; out ParaPoint : Pointer ) : Exception;
var
	vFunc : TFindConnectionPointFunc;
	vHr : HRESULT;
begin
	vFunc := TFindConnectionPointFunc( VTable.mFindConnectionPoint );
	vHr := vFunc( Self, ParaIid, ParaPoint );
	if vHr <> S_OK then
	begin
		Result := TOleError.Create( vHr );
	end else
	begin
		Result := nil;
	end;
end;

end.
