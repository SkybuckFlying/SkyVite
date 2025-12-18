unit Vendor.Github.Com.GoOle.GoOle.IUnknown;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.Guid;

type
	IUnknown = class
	private
		mRawVTable : Pointer;
	public
		property RawVTable : Pointer read mRawVTable write mRawVTable;

		function QueryInterface( ParaIid : PGUID; out ParaDisp : Pointer ) : HRESULT;
		function AddRef : Integer;
		function Release : Integer;
	end;

implementation

uses
	Winapi.ActiveX;

function IUnknown.QueryInterface( ParaIid : PGUID; out ParaDisp : Pointer ) : HRESULT;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk.QueryInterface( ParaIid^, ParaDisp );
end;

function IUnknown.AddRef : Integer;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk._AddRef;
end;

function IUnknown.Release : Integer;
var
	vUnk : Winapi.ActiveX.IUnknown;
begin
	vUnk := Winapi.ActiveX.IUnknown( mRawVTable );
	Result := vUnk._Release;
end;

end.
