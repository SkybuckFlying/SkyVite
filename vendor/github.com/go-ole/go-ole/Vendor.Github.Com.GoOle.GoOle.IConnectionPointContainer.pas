{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IConnectionPointContainer;

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

	IConnectionPointContainerVtbl = record
		mIUnknownVtbl : IUnknownVtbl;
		mEnumConnectionPoints : UIntPtr;
		mFindConnectionPoint  : UIntPtr;
	end;
	PIConnectionPointContainerVtbl = ^IConnectionPointContainerVtbl;

	IConnectionPointContainer = class( Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown )
	public
		function VTable : PIConnectionPointContainerVtbl;
	end;

implementation

function IConnectionPointContainer.VTable : PIConnectionPointContainerVtbl;
begin
	Result := PIConnectionPointContainerVtbl( RawVTable );
end;

end.
