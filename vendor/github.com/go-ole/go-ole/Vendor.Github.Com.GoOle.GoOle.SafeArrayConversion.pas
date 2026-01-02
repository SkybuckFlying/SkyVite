{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.SafeArrayConversion;

interface

{$IFDEF FPC}
uses
	SysUtils, Rtti, Variants,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils, System.Rtti, System.Variants,
	Vendor.Github.Com.GoOle.GoOle.SafeArray,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

type
	TSafeArrayConversion = record
	public
		mArray : TSafeArray;

		function ToStringArray : TArray<string>;
		function ToByteArray : TArray<Byte>;
		function ToValueArray : TArray<TValue>;
		function GetType : Word;
		function GetDimensions : Cardinal;
		function GetSize : Cardinal;
		function TotalElements( ParaIndex : Cardinal ) : Int64;
		procedure Release;
	end;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc
;

function TSafeArrayConversion.ToStringArray : TArray<string>;
var
	vTotalElements : Int64;
	vIndex : Int64;
begin
	vTotalElements := TotalElements( 0 );
	SetLength( Result, vTotalElements );

	for vIndex := 0 to vTotalElements - 1 do
	begin
		Result[ vIndex ] := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElementString( mArray, vIndex );
	end;
end;

function TSafeArrayConversion.ToByteArray : TArray<Byte>;
var
	vTotalElements : Int64;
	vIndex : Int64;
	vByte : Byte;
begin
	vTotalElements := TotalElements( 0 );
	SetLength( Result, vTotalElements );

	for vIndex := 0 to vTotalElements - 1 do
	begin
		vByte := 0;
		Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vByte );
		Result[ vIndex ] := vByte;
	end;
end;

function TSafeArrayConversion.ToValueArray : TArray<TValue>;
var
	vTotalElements : Int64;
	vIndex : Integer;
	vVT : Word;
	vBoolValue : WordBool;
	vInt8Value : ShortInt;
	vInt16Value : SmallInt;
	vInt32Value : Integer;
	vInt64Value : Int64;
	vUInt8Value : Byte;
	vUInt16Value : Word;
	vUInt32Value : Cardinal;
	vUInt64Value : UInt64;
	vFloat32Value : Single;
	vFloat64Value : Double;
	vStringValue : string;
begin
	vTotalElements := TotalElements( 0 );
	SetLength( Result, vTotalElements );
	vVT := GetType;

	for vIndex := 0 to vTotalElements - 1 do
	begin
		case vVT of
			VT_BOOL :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vBoolValue );
				Result[ vIndex ] := TValue.From<Boolean>( vBoolValue );
			end;
			VT_I1 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vInt8Value );
				Result[ vIndex ] := TValue.From<ShortInt>( vInt8Value );
			end;
			VT_I2 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vInt16Value );
				Result[ vIndex ] := TValue.From<SmallInt>( vInt16Value );
			end;
			VT_I4 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vInt32Value );
				Result[ vIndex ] := TValue.From<Integer>( vInt32Value );
			end;
			VT_I8 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vInt64Value );
				Result[ vIndex ] := TValue.From<Int64>( vInt64Value );
			end;
			VT_UI1 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vUInt8Value );
				Result[ vIndex ] := TValue.From<Byte>( vUInt8Value );
			end;
			VT_UI2 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vUInt16Value );
				Result[ vIndex ] := TValue.From<Word>( vUInt16Value );
			end;
			VT_UI4 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vUInt32Value );
				Result[ vIndex ] := TValue.From<Cardinal>( vUInt32Value );
			end;
			VT_UI8 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vUInt64Value );
				Result[ vIndex ] := TValue.From<UInt64>( vUInt64Value );
			end;
			VT_R4 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vFloat32Value );
				Result[ vIndex ] := TValue.From<Single>( vFloat32Value );
			end;
			VT_R8 :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vFloat64Value );
				Result[ vIndex ] := TValue.From<Double>( vFloat64Value );
			end;
			VT_BSTR :
			begin
				Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElement( mArray, vIndex, @vStringValue );
				Result[ vIndex ] := TValue.From<string>( vStringValue );
			end;
		else
			begin
				// Default
			end;
		end;
	end;
end;

function TSafeArrayConversion.GetType : Word;
begin
	Result := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetVartype( mArray );
end;

function TSafeArrayConversion.GetDimensions : Cardinal;
begin
	Result := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetDim( mArray );
end;

function TSafeArrayConversion.GetSize : Cardinal;
begin
	Result := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetElementSize( mArray );
end;

function TSafeArrayConversion.TotalElements( ParaIndex : Cardinal ) : Int64;
var
	vLowerBounds : Int64;
	vUpperBounds : Int64;
begin
	if ParaIndex < 1 then
	begin
		ParaIndex := 1;
	end;

	vLowerBounds := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetLBound( mArray, ParaIndex );
	vUpperBounds := Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayGetUBound( mArray, ParaIndex );

	Result := vUpperBounds - vLowerBounds + 1;
end;

procedure TSafeArrayConversion.Release;
begin
	Vendor.Github.Com.GoOle.GoOle.SafeArrayFunc.safeArrayDestroy( mArray );
end;

end.
