{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.OleUtil.OleUtil;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Constants
;
{$ENDIF}

function ClassIDFrom( ParaProgramID : string ) : TGUID;
function CreateObject( ParaProgramID : string ) : IUnknown;
function GetActiveObject( ParaProgramID : string ) : IUnknown;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.Com,
	Vendor.Github.Com.GoOle.GoOle.Error
;

function ClassIDFrom( ParaProgramID : string ) : TGUID;
var
	vClsid : TGUID;
	vHR : HRESULT;
begin
	vHR := Vendor.Github.Com.GoOle.GoOle.Com.CLSIDFromProgID( ParaProgramID, vClsid );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := vClsid;
end;

function CreateObject( ParaProgramID : string ) : IUnknown;
var
	vClsid : TGUID;
	vUnkPtr : Pointer;
	vHR : HRESULT;
begin
	vClsid := ClassIDFrom( ParaProgramID );
	vUnkPtr := nil;
	vHR := Vendor.Github.Com.GoOle.GoOle.Com.CreateInstance( vClsid, IID_IUnknown, vUnkPtr );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := IUnknown.Create;
	Result.RawVTable := vUnkPtr;
end;

function GetActiveObject( ParaProgramID : string ) : IUnknown;
var
	vClsid : TGUID;
	vUnkPtr : Pointer;
	vHR : HRESULT;
begin
	vClsid := ClassIDFrom( ParaProgramID );
	vUnkPtr := nil;
	vHR := Vendor.Github.Com.GoOle.GoOle.Com.GetActiveObject( vClsid, IID_IUnknown, vUnkPtr );
	if vHR <> S_OK then
		raise TOleError.Create( vHR );
	Result := IUnknown.Create;
	Result.RawVTable := vUnkPtr;
end;

end.
