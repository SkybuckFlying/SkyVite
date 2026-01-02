{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Bypass;

interface

{$IFDEF FPC}
uses
	Rtti
;
{$ELSE}
uses
	System.Rtti
;
{$ENDIF}

const
	// UnsafeDisabled is a build-time constant which specifies whether or
	// not access to the unsafe package is available.
	ConstUnsafeDisabled = False;

function unsafeReflectValue
(
	ParaV : TValue
) : TValue;

implementation

{$IFDEF FPC}
uses
	SysUtils
;
{$ELSE}
uses
	System.SysUtils
;
{$ENDIF}

const
	// ptrSize is the size of a pointer on the current arch.
	Const_ptrSize = SizeOf( Pointer );

type
	flag = UIntPtr;
	PFlag = ^flag;

var
	// flagRO indicates whether the value field of a reflect.Value
	// is read-only.
	vFlagRO : flag;

	// flagAddr indicates whether the address of the reflect.Value's
	// value may be taken.
	vFlagAddr : flag;

const
	// flagKindMask holds the bits that make up the kind
	// part of the flags field. In all the supported versions,
	// it is in the lower 5 bits.
	Const_flagKindMask = flag( $1f );

type
	TOkFlag = record
		mRo : flag;
		mAddr : flag;
	end;

var
	// Different versions of Go have used different
	// bit layouts for the flags type. This table
	// records the known combinations.
	vOkFlags : array of TOkFlag;

	vFlagValOffset : UIntPtr;

// flagField returns a pointer to the flag field of a reflect.Value.
function flagField
(
	ParaV : Pointer
) : PFlag;
begin
	Result := PFlag( UIntPtr( ParaV ) + vFlagValOffset );
end;

// unsafeReflectValue converts the passed reflect.Value into a one that bypasses
// the typical safety restrictions preventing access to unaddressable and
// unexported data.  It works by digging the raw pointer to the underlying
// value out of the protected value and generating a new unprotected (unsafe)
// reflect.Value to it.
//
// This allows us to check for implementations of the Stringer and error
// interfaces to be used for pretty printing ordinarily unaddressable and
// inaccessible values such as unexported struct fields.
function unsafeReflectValue
(
	ParaV : TValue
) : TValue;
begin
	// In Delphi, TValue from RTTI doesn't have the same strict unexported
	// access restrictions as Go's reflect.Value when using RTTI to read fields.
	// Thus, we return the value as is for functional equivalence.
	Result := ParaV;
end;

initialization
begin
	try
		SetLength( vOkFlags, 2 );
		// From Go 1.4 to 1.5
		vOkFlags[ 0 ].mRo := 1 shl 5;
		vOkFlags[ 0 ].mAddr := 1 shl 7;
		// Up to Go tip.
		vOkFlags[ 1 ].mRo := 1 shl 5 or 1 shl 6;
		vOkFlags[ 1 ].mAddr := 1 shl 8;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed for vOkFlags' );
		end;
	end;

	vFlagRO := 0;
	vFlagAddr := 0;
	vFlagValOffset := 0;
end;

end.
