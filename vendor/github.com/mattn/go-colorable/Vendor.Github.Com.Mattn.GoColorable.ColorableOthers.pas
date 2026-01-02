{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Mattn.GoColorable.ColorableOthers;

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

function NewColorable( ParaFile : THandleStream ) : TStream;
function NewColorableStdout : TStream;
function NewColorableStderr : TStream;
procedure EnableColorsStdout( ParaEnabled : PBoolean );

implementation

function NewColorable( ParaFile : THandleStream ) : TStream;
begin
	if ParaFile = nil then
	begin
		raise Exception.Create( 'nil passed instead of THandleStream to NewColorable()' );
	end;
	Result := ParaFile;
end;

function NewColorableStdout : TStream;
begin
	Result := THandleStream.Create( GetStdHandle( STD_OUTPUT_HANDLE ) );
end;

function NewColorableStderr : TStream;
begin
	Result := THandleStream.Create( GetStdHandle( STD_ERROR_HANDLE ) );
end;

procedure EnableColorsStdout( ParaEnabled : PBoolean );
begin
	if ParaEnabled <> nil then
	begin
		ParaEnabled^ := True;
	end;
end;

end.
