{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IEnumVariant;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils
;
{$ELSE}
uses
	System.Classes, System.SysUtils
;
{$ENDIF}

uses
	Vendor.Github.Com.GoOle.GoOle.IUnknown
;

type
	IUnknownVtbl = record
		mQueryInterface : UIntPtr;
		mAddRef         : UIntPtr;
		mRelease        : UIntPtr;
	end;

	IEnumVARIANTVtbl = record
		mIUnknownVtbl : IUnknownVtbl;
		mNext  : UIntPtr;
		mSkip  : UIntPtr;
		mReset : UIntPtr;
		mClone : UIntPtr;
	end;
	PIEnumVARIANTVtbl = ^IEnumVARIANTVtbl;

	IEnumVARIANT = class( Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown )
	public
		function VTable : PIEnumVARIANTVtbl;
	end;

implementation

function IEnumVARIANT.VTable : PIEnumVARIANTVtbl;
begin
	Result := PIEnumVARIANTVtbl( RawVTable );
end;

end.
