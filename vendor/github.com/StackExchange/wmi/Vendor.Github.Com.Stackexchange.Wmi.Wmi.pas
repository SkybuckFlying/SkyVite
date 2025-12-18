unit Vendor.Github.Com.Stackexchange.Wmi.Wmi;

interface

uses
	Winapi.Windows,
	Winapi.ActiveX,
	System.Win.ComObj,
	System.SysUtils,
	System.Variants,
	System.Classes;

type
	EWmiError = class( Exception );

function WmiQuery( const ParaQuery : string; var ParaDest : OleVariant; const ParaNamespace : string = '' ) : HRESULT;
function CreateWqlQuery( const ParaClassName : string; const ParaFields : TArray<string> = [] ) : string;

implementation

function WmiQuery( const ParaQuery : string; var ParaDest : OleVariant; const ParaNamespace : string = '' ) : HRESULT;
var
	vLocator  : OleVariant;
	vServices : OleVariant;
begin
	Result := S_OK;
	try
		vLocator := CreateOleObject( 'WbemScripting.SWbemLocator' );
		if ParaNamespace = '' then
			vServices := vLocator.ConnectServer( '.', 'root\cimv2' )
		else
			vServices := vLocator.ConnectServer( '.', ParaNamespace );

		ParaDest := vServices.ExecQuery( ParaQuery );
	except
		on E : Exception do
		begin
			Result := E_UNEXPECTED;
			// In a real implementation, we might want to log or handle specific OLE errors
		end;
	end;
end;

function CreateWqlQuery( const ParaClassName : string; const ParaFields : TArray<string> = [] ) : string;
var
	vI : Integer;
begin
	Result := 'SELECT ';
	if Length( ParaFields ) = 0 then
		Result := Result + '* '
	else
	begin
		for vI := 0 to High( ParaFields ) do
		begin
			Result := Result + ParaFields[ vI ];
			if vI < High( ParaFields ) then
				Result := Result + ', ';
		end;
		Result := Result + ' ';
	end;
	Result := Result + 'FROM ' + ParaClassName;
end;

initialization
	// CoInitialize is usually handled by the application or framework (e.g., VCL/FMX)
	// but for console apps using COM, it must be called.
	// We don't call it here to avoid multiple initializations in a library.

end.
