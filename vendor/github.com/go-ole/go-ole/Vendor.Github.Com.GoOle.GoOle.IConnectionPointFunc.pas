{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IConnectionPointFunc;

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
	Vendor.Github.Com.GoOle.GoOle.IConnectionPoint,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Constants
;

type
	TIConnectionPointFuncHelper = class helper for IConnectionPoint
	public
		function GetConnectionInterfaceFunc( out ParaPiid : PGUID ) : Integer;
		function AdviseFunc( ParaUnknown : Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown ) : Cardinal;
		function UnadviseFunc( ParaCookie : Cardinal ) : Exception;
		function EnumConnectionsFunc( var ParaP : Pointer ) : Exception;
	end;

implementation

function TIConnectionPointFuncHelper.GetConnectionInterfaceFunc( out ParaPiid : PGUID ) : Integer;
begin
	Result := 0;
end;

function TIConnectionPointFuncHelper.AdviseFunc( ParaUnknown : Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown ) : Cardinal;
begin
	Result := 0;
end;

function TIConnectionPointFuncHelper.UnadviseFunc( ParaCookie : Cardinal ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

function TIConnectionPointFuncHelper.EnumConnectionsFunc( var ParaP : Pointer ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

end.
