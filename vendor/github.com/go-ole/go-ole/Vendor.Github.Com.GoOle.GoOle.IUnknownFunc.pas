{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IUnknownFunc;

interface

{$IFDEF FPC}
uses
	SysUtils, Rtti,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils, System.Rtti,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

function reflectQueryInterface( ParaSelf : TValue; ParaMethod : Pointer; ParaInterfaceID : PGUID; out ParaObj : TValue ) : HRESULT;
function queryInterface( ParaUnk : IUnknown; ParaIid : PGUID ) : IDispatch;
function addRef( ParaUnk : IUnknown ) : Integer;
function release( ParaUnk : IUnknown ) : Integer;

implementation

function reflectQueryInterface( ParaSelf : TValue; ParaMethod : Pointer; ParaInterfaceID : PGUID; out ParaObj : TValue ) : HRESULT;
begin
	Result := E_NOTIMPL;
end;

function queryInterface( ParaUnk : IUnknown; ParaIid : PGUID ) : IDispatch;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function addRef( ParaUnk : IUnknown ) : Integer;
begin
	Result := 0;
end;

function release( ParaUnk : IUnknown ) : Integer;
begin
	Result := 0;
end;

end.
