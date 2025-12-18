unit Vendor.Github.Com.GoOle.GoOle.IConnectionPoint;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Guid;

type
	IConnectionPoint = class( IUnknown )
	public
		function GetConnectionInterface( out ParaIid : TGUID ) : HRESULT;
		function Advise( ParaUnk : Pointer; out ParaCookie : Cardinal ) : HRESULT;
		function Unadvise( ParaCookie : Cardinal ) : HRESULT;
	end;

implementation

uses
	Winapi.ActiveX;

function IConnectionPoint.GetConnectionInterface( out ParaIid : TGUID ) : HRESULT;
var
	vCP : Winapi.ActiveX.IConnectionPoint;
begin
	vCP := Winapi.ActiveX.IConnectionPoint( RawVTable );
	Result := vCP.GetConnectionInterface( System.TGUID( ParaIid ) );
end;

function IConnectionPoint.Advise( ParaUnk : Pointer; out ParaCookie : Cardinal ) : HRESULT;
var
	vCP : Winapi.ActiveX.IConnectionPoint;
begin
	vCP := Winapi.ActiveX.IConnectionPoint( RawVTable );
	Result := vCP.Advise( Winapi.ActiveX.IUnknown( ParaUnk ), ParaCookie );
end;

function IConnectionPoint.Unadvise( ParaCookie : Cardinal ) : HRESULT;
var
	vCP : Winapi.ActiveX.IConnectionPoint;
begin
	vCP := Winapi.ActiveX.IConnectionPoint( RawVTable );
	Result := vCP.Unadvise( ParaCookie );
end;

end.
