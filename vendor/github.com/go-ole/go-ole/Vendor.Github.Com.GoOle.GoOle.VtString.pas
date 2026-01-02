{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.VtString;

interface

uses
	Vendor.Github.Com.GoOle.GoOle.Constants
;

function VTToString( ParaV : VT ) : string;

implementation

uses
	System.SysUtils
;

function VTToString( ParaV : VT ) : string;
begin
	case ParaV of
		VT_EMPTY: Result := 'VT_EMPTY';
		VT_NULL: Result := 'VT_NULL';
		VT_I2: Result := 'VT_I2';
		VT_I4: Result := 'VT_I4';
		VT_R4: Result := 'VT_R4';
		VT_R8: Result := 'VT_R8';
		VT_CY: Result := 'VT_CY';
		VT_DATE: Result := 'VT_DATE';
		VT_BSTR: Result := 'VT_BSTR';
		VT_DISPATCH: Result := 'VT_DISPATCH';
		VT_ERROR: Result := 'VT_ERROR';
		VT_BOOL: Result := 'VT_BOOL';
		VT_VARIANT: Result := 'VT_VARIANT';
		VT_UNKNOWN: Result := 'VT_UNKNOWN';
		VT_DECIMAL: Result := 'VT_DECIMAL';
		VT_I1: Result := 'VT_I1';
		VT_UI1: Result := 'VT_UI1';
		VT_UI2: Result := 'VT_UI2';
		VT_UI4: Result := 'VT_UI4';
		VT_I8: Result := 'VT_I8';
		VT_UI8: Result := 'VT_UI8';
		VT_INT: Result := 'VT_INT';
		VT_UINT: Result := 'VT_UINT';
		VT_VOID: Result := 'VT_VOID';
		VT_HRESULT: Result := 'VT_HRESULT';
		VT_PTR: Result := 'VT_PTR';
		VT_SAFEARRAY: Result := 'VT_SAFEARRAY';
		VT_CARRAY: Result := 'VT_CARRAY';
		VT_USERDEFINED: Result := 'VT_USERDEFINED';
		VT_LPSTR: Result := 'VT_LPSTR';
		VT_LPWSTR: Result := 'VT_LPWSTR';
		VT_RECORD: Result := 'VT_RECORD';
		VT_INT_PTR: Result := 'VT_INT_PTR';
		VT_UINT_PTR: Result := 'VT_UINT_PTR';
		VT_FILETIME: Result := 'VT_FILETIME';
		VT_BLOB: Result := 'VT_BLOB';
		VT_STREAM: Result := 'VT_STREAM';
		VT_STORAGE: Result := 'VT_STORAGE';
		VT_STREAMED_OBJECT: Result := 'VT_STREAMED_OBJECT';
		VT_STORED_OBJECT: Result := 'VT_STORED_OBJECT';
		VT_BLOB_OBJECT: Result := 'VT_BLOB_OBJECT';
		VT_CF: Result := 'VT_CF';
		VT_CLSID: Result := 'VT_CLSID';
		VT_BSTR_BLOB: Result := 'VT_BSTR_BLOB';
		VT_VECTOR: Result := 'VT_VECTOR';
		VT_ARRAY: Result := 'VT_ARRAY';
		VT_BYREF: Result := 'VT_BYREF';
		VT_RESERVED: Result := 'VT_RESERVED';
		VT_ILLEGAL: Result := 'VT_ILLEGAL';
	else
		Result := 'VT(' + IntToStr( ParaV ) + ')';
	end;
end;

end.
