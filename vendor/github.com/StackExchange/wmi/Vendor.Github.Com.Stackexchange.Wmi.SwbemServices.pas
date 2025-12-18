unit Vendor.Github.Com.Stackexchange.Wmi.SwbemServices;

interface

uses
	Winapi.Windows,
	Winapi.ActiveX,
	System.Win.ComObj,
	System.SysUtils,
	System.Variants,
	System.Classes,
	Vendor.Github.Com.Stackexchange.Wmi.Wmi;

type
	TSWbemServices = class
	private
		mLocator  : OleVariant;
		mServices : OleVariant;
		mNamespace : string;
	public
		constructor Create( const ParaNamespace : string = 'root\cimv2' );
		function Query( const ParaQuery : string; var ParaDest : OleVariant ) : HRESULT;
		procedure Close;
	end;

implementation

constructor TSWbemServices.Create( const ParaNamespace : string );
begin
	inherited Create;
	mNamespace := ParaNamespace;
	mLocator := CreateOleObject( 'WbemScripting.SWbemLocator' );
	mServices := mLocator.ConnectServer( '.', mNamespace );
end;

function TSWbemServices.Query( const ParaQuery : string; var ParaDest : OleVariant ) : HRESULT;
begin
	Result := S_OK;
	try
		ParaDest := mServices.ExecQuery( ParaQuery );
	except
		on E : Exception do
		begin
			Result := E_UNEXPECTED;
		end;
	end;
end;

procedure TSWbemServices.Close;
begin
	mServices := Unassigned;
	mLocator := Unassigned;
end;

end.
