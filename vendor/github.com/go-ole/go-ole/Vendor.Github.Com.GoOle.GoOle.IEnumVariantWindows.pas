{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IEnumVariantWindows;

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
	Vendor.Github.Com.GoOle.GoOle.IEnumVariant,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;

type
	TIEnumVARIANTWindowsHelper = class helper for IEnumVARIANT
	public
		function CloneWin : IEnumVARIANT;
		function ResetWin : Exception;
		function SkipWin( ParaCelt : Cardinal ) : Exception;
		function NextWin( ParaCelt : Cardinal; out ParaCeltFetched : Cardinal ) : Pointer;
	end;

implementation

type
	TCloneFunc = function( ParaSelf : Pointer; out ParaCloned : Pointer ) : HRESULT; stdcall;
	TResetFunc = function( ParaSelf : Pointer ) : HRESULT; stdcall;
	TSkipFunc = function( ParaSelf : Pointer; ParaCelt : Cardinal ) : HRESULT; stdcall;
	TNextFunc = function( ParaSelf : Pointer; ParaCelt : Cardinal; ParaArray : Pointer; out ParaFetched : Cardinal ) : HRESULT; stdcall;

function TIEnumVARIANTWindowsHelper.CloneWin : IEnumVARIANT;
var
	vFunc : TCloneFunc;
	vHr : HRESULT;
	vCloned : Pointer;
begin
	vFunc := TCloneFunc( VTable.mClone );
	vHr := vFunc( Self, vCloned );
	if vHr <> S_OK then
	begin
		raise TOleError.Create( vHr );
	end;
	Result := IEnumVARIANT.Create;
	Result.RawVTable := vCloned;
end;

function TIEnumVARIANTWindowsHelper.ResetWin : Exception;
var
	vFunc : TResetFunc;
	vHr : HRESULT;
begin
	vFunc := TResetFunc( VTable.mReset );
	vHr := vFunc( Self );
	if vHr <> S_OK then
	begin
		Result := TOleError.Create( vHr );
	end else
	begin
		Result := nil;
	end;
end;

function TIEnumVARIANTWindowsHelper.SkipWin( ParaCelt : Cardinal ) : Exception;
var
	vFunc : TSkipFunc;
	vHr : HRESULT;
begin
	vFunc := TSkipFunc( VTable.mSkip );
	vHr := vFunc( Self, ParaCelt );
	if vHr <> S_OK then
	begin
		Result := TOleError.Create( vHr );
	end else
	begin
		Result := nil;
	end;
end;

function TIEnumVARIANTWindowsHelper.NextWin( ParaCelt : Cardinal; out ParaCeltFetched : Cardinal ) : Pointer;
var
	vFunc : TNextFunc;
	vHr : HRESULT;
	vArray : Pointer;
begin
	vFunc := TNextFunc( VTable.mNext );
	vArray := nil; // Should be allocated or passed
	vHr := vFunc( Self, ParaCelt, vArray, ParaCeltFetched );
	if vHr <> S_OK then
	begin
		raise TOleError.Create( vHr );
	end;
	Result := vArray;
end;

end.
