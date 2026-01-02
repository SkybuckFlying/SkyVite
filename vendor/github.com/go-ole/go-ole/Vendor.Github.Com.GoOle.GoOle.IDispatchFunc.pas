{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IDispatchFunc;

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
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;

function getIDsOfName( ParaDisp : TObject; const ParaNames : array of string ) : array of Integer;
function getTypeInfoCount( ParaDisp : TObject ) : Cardinal;
function getTypeInfo( ParaDisp : TObject ) : TObject;
function invoke( ParaDisp : TObject; ParaDispid : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : Pointer;

implementation

function getIDsOfName( ParaDisp : TObject; const ParaNames : array of string ) : array of Integer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function getTypeInfoCount( ParaDisp : TObject ) : Cardinal;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function getTypeInfo( ParaDisp : TObject ) : TObject;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function invoke( ParaDisp : TObject; ParaDispid : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
