{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.OleUtil.Connection;

interface

{$IFDEF FPC}
uses
	SysUtils, Rtti, Generics.Collections,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid
;
{$ELSE}
uses
	System.SysUtils, System.Rtti, System.Generics.Collections,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid
;
{$ENDIF}

type
	TStdDispatchVtbl = record
		pQueryInterface   : Pointer;
		pAddRef           : Pointer;
		pRelease          : Pointer;
		pGetTypeInfoCount : Pointer;
		pGetTypeInfo      : Pointer;
		pGetIDsOfNames    : Pointer;
		pInvoke           : Pointer;
	end;
	PStdDispatchVtbl = ^TStdDispatchVtbl;

	TStdDispatch = class
	public
		mPvtbl   : PStdDispatchVtbl;
		mRef     : Integer;
		mIid     : TGUID;
		mIface   : TObject;
		mFuncMap : TDictionary<string, Integer>;

		constructor Create;
		destructor Destroy; override;
	end;

implementation

constructor TStdDispatch.Create;
begin
	inherited Create;
	mFuncMap := TDictionary<string, Integer>.Create;
end;

destructor TStdDispatch.Destroy;
begin
	mFuncMap.Free;
	inherited;
end;

end.
