unit Vendor.Github.Com.Pkg.Errors.Go113;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Pkg.Errors.Errors;

function IsError( ParaErr, ParaTarget : IError ) : Boolean;
function AsError( ParaErr : IError; const ParaTarget : GUID; out ParaResult : IInterface ) : Boolean;
function Unwrap( ParaErr : IError ) : IError;

implementation

function IsError( ParaErr, ParaTarget : IError ) : Boolean;
var
	vWrapper : IWrapper;
begin
	Result := False;
	while Assigned( ParaErr ) do
	begin
		if ParaErr = ParaTarget then
			Exit( True );
		
		// In Go, it also checks for an Is(error) bool method.
		// We could add an IIsError interface if needed.
		
		if Supports( ParaErr, IWrapper, vWrapper ) then
			ParaErr := vWrapper.Unwrap
		else
			Break;
	end;
end;

function AsError( ParaErr : IError; const ParaTarget : GUID; out ParaResult : IInterface ) : Boolean;
var
	vWrapper : IWrapper;
begin
	Result := False;
	while Assigned( ParaErr ) do
	begin
		if ParaErr.QueryInterface( ParaTarget, ParaResult ) = 0 then
			Exit( True );
		
		if Supports( ParaErr, IWrapper, vWrapper ) then
			ParaErr := vWrapper.Unwrap
		else
			Break;
	end;
end;

function Unwrap( ParaErr : IError ) : IError;
var
	vWrapper : IWrapper;
begin
	Result := nil;
	if Assigned( ParaErr ) and Supports( ParaErr, IWrapper, vWrapper ) then
		Result := vWrapper.Unwrap;
end;

end.
