{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc;

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

function safeArrayAccessData( ParaSafearray : TSafeArray ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayUnaccessData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayAllocData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayAllocDescriptor( ParaDimensions : Cardinal ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayAllocDescriptorEx( ParaVariantType : Word; ParaDimensions : Cardinal ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayCopy( ParaOriginal : TSafeArray ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayCopyData( ParaOriginal : TSafeArray; ParaDuplicate : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayCreate( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayCreateEx( ParaVariantType : Word; ParaDimensions : Cardinal; ParaBounds : Pointer; ParaExtra : Pointer ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayCreateVector( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayCreateVectorEx( ParaVariantType : Word; ParaLowerBound : Integer; ParaLength : Cardinal; ParaExtra : Pointer ) : TSafeArray;
begin
	Result.mP := nil;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayDestroy( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayDestroyData( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayDestroyDescriptor( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayGetDim( ParaSafearray : TSafeArray ) : Cardinal;
begin
	Result := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetElementSize( ParaSafearray : TSafeArray ) : Cardinal;
begin
	Result := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

procedure safeArrayGetElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaPv : Pointer );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetElementString( ParaSafearray : TSafeArray; ParaIndex : Int64 ) : string;
begin
	Result := '';
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetIID( ParaSafearray : TSafeArray ) : TGUID;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetLBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
begin
	Result := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetUBound( ParaSafearray : TSafeArray; ParaDimension : Cardinal ) : Int64;
begin
	Result := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayGetVartype( ParaSafearray : TSafeArray ) : Word;
begin
	Result := 0;
	raise TOleError.Create( E_NOTIMPL );
end;

function safeArrayLock( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayUnlock( ParaSafearray : TSafeArray ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function safeArrayPutElement( ParaSafearray : TSafeArray; ParaIndex : Int64; ParaElement : Pointer ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

end.
