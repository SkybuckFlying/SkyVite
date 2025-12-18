unit Vendor.Github.Com.GoOle.GoOle.Variant;

interface

uses
	System.Classes,
	System.SysUtils,
	Winapi.ActiveX,
	Vendor.Github.Com.GoOle.GoOle.Constants;

type
	TVARIANT = TVariantArg;

function NewVariant( ParaVt : VT; ParaVal : Int64 ) : TVARIANT;

implementation

function NewVariant( ParaVt : VT; ParaVal : Int64 ) : TVARIANT;
begin
	Result.vt := ParaVt;
	Result.llVal := ParaVal;
end;

end.
