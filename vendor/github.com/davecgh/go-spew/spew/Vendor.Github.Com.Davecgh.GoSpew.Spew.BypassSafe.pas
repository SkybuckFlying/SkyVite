{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Davecgh.GoSpew.Spew.BypassSafe;

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
	ConstUnsafeDisabled = True;

function unsafeReflectValue
(
	ParaV : TValue
) : TValue;

implementation

// unsafeReflectValue typically converts the passed reflect.Value into a one
// that bypasses the typical safety restrictions preventing access to
// unaddressable and unexported data.  However, doing this relies on access to
// the unsafe package.  This is a stub version which simply returns the passed
// reflect.Value when the unsafe package is not available.
function unsafeReflectValue
(
	ParaV : TValue
) : TValue;
begin
	Result := ParaV;
end;

end.
