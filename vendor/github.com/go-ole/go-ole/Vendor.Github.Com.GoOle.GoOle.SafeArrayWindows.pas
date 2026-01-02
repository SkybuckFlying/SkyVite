{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.SafeArrayWindows;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

function safeArrayAccessData( ParaSafearray : TSafeArray ) : Pointer;
function safeArrayUnaccessData( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayAllocData( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayAllocDescriptor( ParaDimensions : Cardinal ) : TSafeArray;
function safeArrayAllocDescriptorEx( ParaVariantType : Word; ParaDimensions : Cardinal ) : TSafeArray;
function safeArrayCopy( ParaOriginal : TSafeArray ) : TSafeArray;
function safeArrayCopyData( ParaOriginal : TSafeArray; ParaDuplicate : TSafeArray ) : HRESULT;
function safeArrayCreate( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer ) : TSafeArray;
function safeArrayCreateEx( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer; ParaExtra : Pointer ) : TSafeArray;
function safeArrayCreateVector( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal ) : TSafeArray;
function safeArrayCreateVectorEx( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal; ParaExtra : Pointer ) : TSafeArray;
function safeArrayDestroy( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayDestroyData( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayDestroyDescriptor( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayGetDim( ParaSafearray : TSafeArray ) : Cardinal;
function safeArrayGetElementSize( ParaSafearray : TSafeArray ) : Cardinal;
procedure safeArrayGetElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaPv : Pointer );
function safeArrayGetElementString( ParaSafearray : TSafeArray; ParaIndex : Int64 ) : string;
function safeArrayGetIID( ParaSafearray : TSafeArray ) : TGUID;
function safeArrayGetLBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
function safeArrayGetUBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
function safeArrayGetVartype( ParaSafearray : TSafeArray ) : Word;
function safeArrayLock( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayUnlock( ParaSafearray : TSafeArray ) : HRESULT;
function safeArrayPutElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaElement : Pointer ) : HRESULT;

implementation

uses
	Winapi.ActiveX,
	Vendor.Github.Com.GoOle.GoOle.Com
;

function safeArrayAccessData( ParaSafearray : TSafeArray ) : Pointer;
var
	vPtr : Pointer;
	vHR : HRESULT;
begin
	vPtr := nil;
	vHR := Winapi.ActiveX.SafeArrayAccessData( ParaSafearray.mP, vPtr );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := vPtr;
end;

function safeArrayUnaccessData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayUnaccessData( ParaSafearray.mP );
end;

function safeArrayAllocData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayAllocData( ParaSafearray.mP );
end;

function safeArrayAllocDescriptor( ParaDimensions : Cardinal ) : TSafeArray;
var
	vSA : PSafeArray;
	vHR : HRESULT;
begin
	vSA := nil;
	vHR := Winapi.ActiveX.SafeArrayAllocDescriptor( ParaDimensions, vSA );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result.mP := vSA;
end;

function safeArrayAllocDescriptorEx( ParaVariantType : Word; ParaDimensions : Cardinal ) : TSafeArray;
var
	vSA : PSafeArray;
	vHR : HRESULT;
begin
	vSA := nil;
	vHR := Winapi.ActiveX.SafeArrayAllocDescriptorEx( ParaVariantType, ParaDimensions, vSA );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result.mP := vSA;
end;

function safeArrayCopy( ParaOriginal : TSafeArray ) : TSafeArray;
var
	vSA : PSafeArray;
	vHR : HRESULT;
begin
	vSA := nil;
	vHR := Winapi.ActiveX.SafeArrayCopy( ParaOriginal.mP, vSA );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result.mP := vSA;
end;

function safeArrayCopyData( ParaOriginal : TSafeArray; ParaDuplicate : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayCopyData( ParaOriginal.mP, ParaDuplicate.mP );
end;

function safeArrayCreate( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer ) : TSafeArray;
begin
	Result.mP := Winapi.ActiveX.SafeArrayCreate( ParaVariantType, ParaDimensions, PSafeArrayBound( ParaBounds )^ );
end;

function safeArrayCreateEx( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer; ParaExtra : Pointer ) : TSafeArray;
begin
	Result.mP := Winapi.ActiveX.SafeArrayCreateEx( ParaVariantType, ParaDimensions, PSafeArrayBound( ParaBounds )^, ParaExtra );
end;

function safeArrayCreateVector( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal ) : TSafeArray;
begin
	Result.mP := Winapi.ActiveX.SafeArrayCreateVector( ParaVariantType, ParaLowerBound, ParaLength );
end;

function safeArrayCreateVectorEx( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal; ParaExtra : Pointer ) : TSafeArray;
begin
	Result.mP := Winapi.ActiveX.SafeArrayCreateVectorEx( ParaVariantType, ParaLowerBound, ParaLength, ParaExtra );
end;

function safeArrayDestroy( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayDestroy( ParaSafearray.mP );
end;

function safeArrayDestroyData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayDestroyData( ParaSafearray.mP );
end;

function safeArrayDestroyDescriptor( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayDestroyDescriptor( ParaSafearray.mP );
end;

function safeArrayGetDim( ParaSafearray : TSafeArray ) : Cardinal;
begin
	Result := Winapi.ActiveX.SafeArrayGetDim( ParaSafearray.mP );
end;

function safeArrayGetElementSize( ParaSafearray : TSafeArray ) : Cardinal;
begin
	Result := Winapi.ActiveX.SafeArrayGetElemsize( ParaSafearray.mP );
end;

procedure safeArrayGetElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaPv : Pointer );
var
	vHR : HRESULT;
	vIndex : Integer;
begin
	vIndex := Integer( ParaIndex );
	vHR := Winapi.ActiveX.SafeArrayGetElement( ParaSafearray.mP, vIndex, ParaPv^ );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
end;

function safeArrayGetElementString( ParaSafearray : TSafeArray; ParaIndex : Int64 ) : string;
var
	vBstr : PWideChar;
	vHR : HRESULT;
	vIndex : Integer;
begin
	vIndex := Integer( ParaIndex );
	vBstr := nil;
	vHR := Winapi.ActiveX.SafeArrayGetElement( ParaSafearray.mP, vIndex, vBstr );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	try
		Result := string( vBstr );
	finally
		Winapi.ActiveX.SysFreeString( vBstr );
	end;
end;

function safeArrayGetIID( ParaSafearray : TSafeArray ) : TGUID;
var
	vIID : System.TGUID;
	vHR : HRESULT;
begin
	vHR := Winapi.ActiveX.SafeArrayGetIID( ParaSafearray.mP, vIID );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := TGUID( vIID );
end;

function safeArrayGetLBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
var
	vBound : Integer;
	vHR : HRESULT;
begin
	vHR := Winapi.ActiveX.SafeArrayGetLBound( ParaSafearray.mP, ParaDimension, vBound );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := vBound;
end;

function safeArrayGetUBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
var
	vBound : Integer;
	vHR : HRESULT;
begin
	vHR := Winapi.ActiveX.SafeArrayGetUBound( ParaSafearray.mP, ParaDimension, vBound );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := vBound;
end;

function safeArrayGetVartype( ParaSafearray : TSafeArray ) : Word;
var
	vVT : Word;
	vHR : HRESULT;
begin
	vHR := Winapi.ActiveX.SafeArrayGetVartype( ParaSafearray.mP, vVT );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := vVT;
end;

function safeArrayLock( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayLock( ParaSafearray.mP );
end;

function safeArrayUnlock( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := Winapi.ActiveX.SafeArrayUnlock( ParaSafearray.mP );
end;

function safeArrayPutElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaElement : Pointer ) : HRESULT;
var
	vIndex : Integer;
begin
	vIndex := Integer( ParaIndex );
	Result := Winapi.ActiveX.SafeArrayPutElement( ParaSafearray.mP, vIndex, ParaElement^ );
end;

end.
