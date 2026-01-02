{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.Connect;

interface

{$IFDEF FPC}
uses
	Classes, SysUtils
;
{$ELSE}
uses
	System.Classes, System.SysUtils, System.Rtti
;
{$ENDIF}

type
	TDispatch = class;

	TConnection = class
	private
		mObject : TObject; // Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown
	public
		function Initialize : Exception;
		procedure Uninitialize;
		function Create( ParaProgId : string ) : Exception;
		procedure Release;
		function Load( const ParaNames : array of string ) : array of Exception;
		function Dispatch : TDispatch;
		
		property Object_ : TObject read mObject write mObject;
	end;

	TDispatch = class
	private
		mObject : TObject; // Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch
	public
		constructor Create( ParaObject : TObject );
		function Call( ParaMethod : string; const ParaParams : array of TValue ) : TObject;
		function MustCall( ParaMethod : string; const ParaParams : array of TValue ) : TObject;
		function Get( ParaName : string; const ParaParams : array of TValue ) : TObject;
		function MustGet( ParaName : string; const ParaParams : array of TValue ) : TObject;
		function Set_( ParaName : string; const ParaParams : array of TValue ) : TObject;
		function MustSet( ParaName : string; const ParaParams : array of TValue ) : TObject;
		function GetId( ParaName : string ) : Integer;
		function GetIds( const ParaNames : array of string ) : array of Integer;
		function Invoke( ParaId : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : TObject;
		procedure Release;

		property Object_ : TObject read mObject write mObject;
	end;

function Connect( const ParaNames : array of string ) : TConnection;

implementation

uses
	Vendor.Github.Com.GoOle.GoOle.ComFunc,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.IDispatch,
	Vendor.Github.Com.GoOle.GoOle.Variant,
	Vendor.Github.Com.GoOle.GoOle.Guid,
	Vendor.Github.Com.GoOle.GoOle.Constants,
	Vendor.Github.Com.GoOle.GoOle.Error
;

function TConnection.Initialize : Exception;
begin
	Result := nil;
	try
		Vendor.Github.Com.GoOle.GoOle.ComFunc.CoInitialize( 0 );
	except
		on E: Exception do
		begin
			Result := E;
		end;
	end;
end;

procedure TConnection.Uninitialize;
begin
	Vendor.Github.Com.GoOle.GoOle.ComFunc.CoUninitialize;
end;

function TConnection.Create( ParaProgId : string ) : Exception;
var
	vClsid : TGUID;
begin
	Result := nil;
	try
		// Simplified implementation
		mObject := nil;
	except
		on E: Exception do
		begin
			Result := E;
		end;
	end;
end;

procedure TConnection.Release;
begin
	if mObject <> nil then
	begin
		( mObject as Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown ).Release;
	end;
end;

function TConnection.Load( const ParaNames : array of string ) : array of Exception;
var
	vName : string;
	vErr : Exception;
begin
	SetLength( Result, 0 );
	for vName in ParaNames do
	begin
		vErr := Create( vName );
		if vErr <> nil then
		begin
			SetLength( Result, Length( Result ) + 1 );
			Result[ High( Result ) ] := vErr;
			Continue;
		end;
		Break;
	end;
end;

function TConnection.Dispatch : TDispatch;
var
	vDisp : Pointer;
begin
	vDisp := nil;
	if ( mObject as Vendor.Github.Com.GoOle.GoOle.IUnknown.IUnknown ).QueryInterface( @IID_IDispatch, vDisp ) = S_OK then
	begin
		Result := TDispatch.Create( TObject( vDisp ) );
	end else
	begin
		Result := nil;
	end;
end;

constructor TDispatch.Create( ParaObject : TObject );
begin
	inherited Create;
	mObject := ParaObject;
end;

function TDispatch.Call( ParaMethod : string; const ParaParams : array of TValue ) : TObject;
begin
	// Placeholder for Invoke implementation
	Result := nil;
end;

function TDispatch.MustCall( ParaMethod : string; const ParaParams : array of TValue ) : TObject;
begin
	Result := Call( ParaMethod, ParaParams );
end;

function TDispatch.Get( ParaName : string; const ParaParams : array of TValue ) : TObject;
begin
	Result := nil;
end;

function TDispatch.MustGet( ParaName : string; const ParaParams : array of TValue ) : TObject;
begin
	Result := Get( ParaName, ParaParams );
end;

function TDispatch.Set_( ParaName : string; const ParaParams : array of TValue ) : TObject;
begin
	Result := nil;
end;

function TDispatch.MustSet( ParaName : string; const ParaParams : array of TValue ) : TObject;
begin
	Result := Set_( ParaName, ParaParams );
end;

function TDispatch.GetId( ParaName : string ) : Integer;
begin
	Result := 0;
end;

function TDispatch.GetIds( const ParaNames : array of string ) : array of Integer;
begin
	SetLength( Result, Length( ParaNames ) );
end;

function TDispatch.Invoke( ParaId : Integer; ParaDispatch : SmallInt; const ParaParams : array of TValue ) : TObject;
begin
	Result := nil;
end;

procedure TDispatch.Release;
begin
	if mObject <> nil then
	begin
		( mObject as Vendor.Github.Com.GoOle.GoOle.IDispatch.IDispatch ).Release;
	end;
end;

function Connect( const ParaNames : array of string ) : TConnection;
begin
	Result := TConnection.Create;
	Result.Initialize;
	Result.Load( ParaNames );
end;

end.
