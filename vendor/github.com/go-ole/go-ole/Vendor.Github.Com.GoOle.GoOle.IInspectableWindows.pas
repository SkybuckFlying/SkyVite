{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.IInspectableWindows;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IInspectable,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;
{$ENDIF}

function GetIids( ParaV : IInspectable ) : TArray<PGUID>;
function GetRuntimeClassName( ParaV : IInspectable ) : string;
function GetTrustLevel( ParaV : IInspectable ) : Cardinal;

implementation

uses
	Winapi.Windows,
	Vendor.Github.Com.GoOle.GoOle.Com
;

type
	IWinRTInspectable = interface(IUnknown)
		['{AF86E2E0-B12D-4c6a-9C5A-D7AA65101E90}']
		function GetIids( out ParaIidCount : Cardinal; out ParaIids : Pointer ) : HRESULT; stdcall;
		function GetRuntimeClassName( out ParaClassName : Pointer ) : HRESULT; stdcall;
		function GetTrustLevel( out ParaTrustLevel : Cardinal ) : HRESULT; stdcall;
	end;

function GetIids( ParaV : IInspectable ) : TArray<PGUID>;
var
	vCount : Cardinal;
	vArray : Pointer;
	vHR : HRESULT;
	vIndex : Integer;
	vCurrent : PByte;
begin
	vCount := 0;
	vArray := nil;
	vHR := IWinRTInspectable( ParaV.RawVTable ).GetIids( vCount, vArray );
	if vHR <> S_OK then
	begin
		raise TOleError.Create( vHR );
	end;

	try
		SetLength( Result, vCount );
		vCurrent := PByte( vArray );
		for vIndex := 0 to vCount - 1 do
		begin
			Result[ vIndex ] := PGUID( vCurrent );
			Inc( vCurrent, SizeOf( TGUID ) );
		end;
	finally
		CoTaskMemFree( vArray );
	end;
end;

function GetRuntimeClassName( ParaV : IInspectable ) : string;
var
	vHString : Pointer;
	vHR : HRESULT;
begin
	vHString := nil;
	vHR := IWinRTInspectable( ParaV.RawVTable ).GetRuntimeClassName( vHString );
	if vHR <> S_OK then
	begin
		raise TOleError.Create( vHR );
	end;

	try
		Result := string( PWideChar( vHString ) );
	finally
		// RoFreeString or similar should be called if vHString is a real HSTRING
	end;
end;

function GetTrustLevel( ParaV : IInspectable ) : Cardinal;
var
	vLevel : Cardinal;
	vHR : HRESULT;
begin
	vLevel := 0;
	vHR := IWinRTInspectable( ParaV.RawVTable ).GetTrustLevel( vLevel );
	if vHR <> S_OK then
	begin
		raise TOleError.Create( vHR );
	end;
	Result := vLevel;
end;

end.
