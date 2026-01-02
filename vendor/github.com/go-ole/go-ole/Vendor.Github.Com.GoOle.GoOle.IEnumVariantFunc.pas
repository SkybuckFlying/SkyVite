{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IEnumVariantFunc;

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
	TIEnumVARIANTHelper = class helper for IEnumVARIANT
	public
		function CloneFunc : IEnumVARIANT;
		function ResetFunc : Exception;
		function SkipFunc( ParaCelt : Cardinal ) : Exception;
		function NextFunc( ParaCelt : Cardinal; out ParaCeltFetched : Cardinal ) : Pointer;
	end;

implementation

function TIEnumVARIANTHelper.CloneFunc : IEnumVARIANT;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function TIEnumVARIANTHelper.ResetFunc : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

function TIEnumVARIANTHelper.SkipFunc( ParaCelt : Cardinal ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

function TIEnumVARIANTHelper.NextFunc( ParaCelt : Cardinal; out ParaCeltFetched : Cardinal ) : Pointer;
begin
	ParaCeltFetched := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

end.
