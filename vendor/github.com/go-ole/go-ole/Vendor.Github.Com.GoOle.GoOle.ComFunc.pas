{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.ComFunc;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils
;
{$ELSE}
uses
	System.Classes, System.Rtti, System.SysUtils
;
{$ENDIF}

type
	Pint16 = ^SmallInt;

procedure CoInitialize( ParaP : UIntPtr );
procedure CoInitializeEx( ParaP : UIntPtr; ParaCoinit : Cardinal );
procedure CoUninitialize;
procedure CoTaskMemFree( ParaMemptr : UIntPtr );

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Ole
;

function coInitialize : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

function coInitializeEx( ParaCoinit : Cardinal ) : Exception;
begin
	Result := TOleError.Create( E_NOTIMPL );
end;

procedure CoInitialize( ParaP : UIntPtr );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

procedure CoInitializeEx( ParaP : UIntPtr; ParaCoinit : Cardinal );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

procedure CoUninitialize;
begin
end;

procedure CoTaskMemFree( ParaMemptr : UIntPtr );
begin
end;

function CLSIDFromProgID( ParaProgId : string ) : TGUID;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function CLSIDFromString( ParaStr : string ) : TGUID;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function StringFromCLSID( ParaClsid : PGUID ) : string;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function IIDFromString( ParaProgId : string ) : TGUID;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function StringFromIID( ParaIid : PGUID ) : string;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function CreateInstance( ParaClsid : PGUID; ParaIid : PGUID ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function GetActiveObject( ParaClsid : PGUID; ParaIid : PGUID ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

procedure VariantInit( ParaV : Pointer );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

procedure VariantClear( ParaV : Pointer );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function SysAllocString( ParaV : string ) : Pint16;
var
	vU : SmallInt;
begin
	vU := 0;
	Result := @vU;
end;

function SysAllocStringLen( ParaV : string ) : Pint16;
var
	vU : SmallInt;
begin
	vU := 0;
	Result := @vU;
end;

procedure SysFreeString( ParaV : Pint16 );
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function SysStringLen( ParaV : Pint16 ) : Cardinal;
begin
	Result := 0;
end;

function CreateStdDispatch( ParaUnk : Pointer; ParaV : UIntPtr; ParaPtinfo : Pointer ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function CreateDispTypeInfo( ParaIdata : Pointer ) : Pointer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

procedure copyMemory( ParaDest : Pointer; ParaSrc : Pointer; ParaLength : Cardinal );
begin
	Move( ParaSrc^, ParaDest^, ParaLength );
end;

function GetUserDefaultLCID : Cardinal;
begin
	Result := 0;
end;

function GetMessage( ParaMsg : Pointer; ParaHwnd : Cardinal; ParaMsgFilterMin : Cardinal; ParaMsgFilterMax : Cardinal ) : Integer;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

function DispatchMessage( ParaMsg : Pointer ) : Integer;
begin
	Result := 0;
end;

function GetVariantDate( ParaValue : Double ) : TDateTime;
begin
	raise TOleError.Create( E_NOTIMPL );
end;

end.
