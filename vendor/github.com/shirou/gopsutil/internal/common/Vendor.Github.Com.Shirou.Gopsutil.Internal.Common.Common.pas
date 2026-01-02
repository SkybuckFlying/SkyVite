{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Internal.Common.Common;

interface

{$IFDEF FPC}
uses
	SysUtils, Classes
;
{$ELSE}
uses
	System.SysUtils, System.Classes
;
{$ENDIF}

var
	ErrNotImplementedError : Exception;

function ReadFile( ParaFilename : string ) : string;
function ReadLines( ParaFilename : string ) : TArray<string>;
function PathExists( ParaFilename : string ) : Boolean;

implementation

function ReadFile( ParaFilename : string ) : string;
var
	vSL : TStringList;
begin
	vSL := TStringList.Create;
	try
		vSL.LoadFromFile( ParaFilename );
		Result := vSL.Text;
	finally
		vSL.Free;
	end;
end;

function ReadLines( ParaFilename : string ) : TArray<string>;
var
	vSL : TStringList;
	vI : Integer;
begin
	vSL := TStringList.Create;
	try
		vSL.LoadFromFile( ParaFilename );
		SetLength( Result, vSL.Count );
		for vI := 0 to vSL.Count - 1 do
			Result[ vI ] := vSL[ vI ];
	finally
		vSL.Free;
	end;
end;

function PathExists( ParaFilename : string ) : Boolean;
begin
	Result := FileExists( ParaFilename ) or DirectoryExists( ParaFilename );
end;

initialization
	ErrNotImplementedError := Exception.Create( 'not implemented yet' );
finalization
	ErrNotImplementedError.Free;

end.
