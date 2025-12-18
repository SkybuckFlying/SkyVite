unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Spew;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Rtti,
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Config,
	Vendor.Github.Com.Davecgh.GoSpew.Spew.Dump;

// Convenience wrappers
procedure Printf( ParaFormat : string; const ParaA : array of TValue );
procedure Println( const ParaA : array of TValue );
function Sprintf( ParaFormat : string; const ParaA : array of TValue ) : string;

implementation

procedure Printf( ParaFormat : string; const ParaA : array of TValue );
begin
	// Uses Fprintf with stdout
end;

procedure Println( const ParaA : array of TValue );
begin
	// Uses Fprintln with stdout
end;

function Sprintf( ParaFormat : string; const ParaA : array of TValue ) : string;
begin
	// Uses Sprintf with internal string stream
end;

end.
