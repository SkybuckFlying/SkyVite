{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IDispatchWindows;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils, Rtti, Variants
;
{$ELSE}
uses
	System.Classes, System.SysUtils, System.Rtti, System.Variants
;
{$ENDIF}

uses
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Ole
;

function getIDsOfName( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch; const ParaNames : array of string ) : array of Integer;
function getTypeInfoCount( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch ) : Cardinal;
function getTypeInfo( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch ) : Vendor.Github.Com.GoOle.GoOle.ITypeInfo.ITypeInfo;
function invoke( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch; ParaDispid : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : Pointer;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.ComFunc
;

function getIDsOfName( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch; const ParaNames : array of string ) : array of Integer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function getTypeInfoCount( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch ) : Cardinal;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function getTypeInfo( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch ) : Vendor.Github.Com.GoOle.GoOle.ITypeInfo.ITypeInfo;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function invoke( ParaDisp : Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch; ParaDispid : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
