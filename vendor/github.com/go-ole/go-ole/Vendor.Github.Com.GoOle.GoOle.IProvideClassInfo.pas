{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IProvideClassInfo;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.ITypeInfo
;

type
	IProvideClassInfo = class( IUnknown )
	public
		function GetClassInfo : ITypeInfo;
	end;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoFunc,
	Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoWindows
;

function IProvideClassInfo.GetClassInfo : ITypeInfo;
begin
	{$IFDEF MSWINDOWS}
	Result := Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoWindows.GetClassInfo( Self );
	{$ELSE}
	Result := Vendor.Github.Com.GoOle.GoOle.IProvideClassInfoFunc.GetClassInfo( Self );
	{$ENDIF}
end;

end.
