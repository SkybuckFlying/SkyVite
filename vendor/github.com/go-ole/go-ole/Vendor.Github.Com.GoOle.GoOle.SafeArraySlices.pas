{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.SafeArraySlices;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function safeArrayFromByteSlice( ParaSlice : TArray<Byte> ) : TSafeArray;
function safeArrayFromStringSlice( ParaSlice : TArray<string> ) : TSafeArray;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc,
	Vendor.Github.Com.GoOle.GoOle.Com
;

function safeArrayFromByteSlice( ParaSlice : TArray<Byte> ) : TSafeArray;
var
	vArray : TSafeArray;
	vIndex : Integer;
	vValue : Byte;
begin
	vArray := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayCreateVector( VT_UI1, 0, Length( ParaSlice ) );
	if vArray.mP = nil then
	begin
		raise Exception.Create( 'Could not convert []byte to SAFEARRAY' );
	end;

	for vIndex := 0 to Length( ParaSlice ) - 1 do
	begin
		vValue := ParaSlice[ vIndex ];
		Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayPutElement( vArray, vIndex, @vValue );
	end;
	Result := vArray;
end;

function safeArrayFromStringSlice( ParaSlice : TArray<string> ) : TSafeArray;
var
	vArray : TSafeArray;
	vIndex : Integer;
	vValue : PWideChar;
begin
	vArray := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayCreateVector( VT_BSTR, 0, Length( ParaSlice ) );
	if vArray.mP = nil then
	begin
		raise Exception.Create( 'Could not convert []string to SAFEARRAY' );
	end;

	for vIndex := 0 to Length( ParaSlice ) - 1 do
	begin
		vValue := SysAllocString( ParaSlice[ vIndex ] );
		Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayPutElement( vArray, vIndex, @vValue );
	end;
	Result := vArray;
end;

end.
