{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IConnectionPointWindows;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils
;
{$ELSE}
uses
	System.Classes, System.SysUtils
;
{$ENDIF}

uses
	Vendor.Github.Com.GoOle.GoOle.IConnectionPoint,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;

type
	TIConnectionPointWindowsHelper = class helper for IConnectionPoint
	public
		function GetConnectionInterfaceWin( out ParaPiid : PGUID ) : Integer;
		function AdviseWin( ParaUnknown : Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown; out ParaCookie : Cardinal ) : Exception;
		function UnadviseWin( ParaCookie : Cardinal ) : Exception;
		function EnumConnectionsWin( var ParaP : Pointer ) : Exception;
	end;

implementation

function TIConnectionPointWindowsHelper.GetConnectionInterfaceWin( out ParaPiid : PGUID ) : Integer;
begin
	// Translation of the Go code: return release((*IUnknown)(unsafe.Pointer(v)))
	Result := Release;
end;

type
	TAdviseFunc = function( ParaSelf : Pointer; ParaUnk : Pointer; out ParaCookie : Cardinal ) : HRESULT; stdcall;
	TUnadviseFunc = function( ParaSelf : Pointer; ParaCookie : Cardinal ) : HRESULT; stdcall;

function TIConnectionPointWindowsHelper.AdviseWin( ParaUnknown : Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown; out ParaCookie : Cardinal ) : Exception;
var
	vFunc : TAdviseFunc;
	vHr : HRESULT;
begin
	// This assumes TIUnknownVtbl is accessible or methods are properly offset
	// Using a simplified call since IConnectionPoint already has an Advise method in its class
	vHr := Advise( ParaUnknown.RawVTable, ParaCookie );
	if vHr <> S_OK then
	begin
		Result := TOleError.Create( vHr );
	end else
	begin
		Result := nil;
	end;
end;

function TIConnectionPointWindowsHelper.UnadviseWin( ParaCookie : Cardinal ) : Exception;
var
	vHr : HRESULT;
begin
	vHr := Unadvise( ParaCookie );
	if vHr <> S_OK then
	begin
		Result := TOleError.Create( vHr );
	end else
	begin
		Result := nil;
	end;
end;

function TIConnectionPointWindowsHelper.EnumConnectionsWin( var ParaP : Pointer ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

end.
