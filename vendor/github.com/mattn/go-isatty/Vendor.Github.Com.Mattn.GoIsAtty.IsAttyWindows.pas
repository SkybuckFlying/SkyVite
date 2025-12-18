unit Vendor.Github.Com.Mattn.GoIsAtty.IsAttyWindows;

interface

uses
	Winapi.Windows;

function IsTerminal( ParaFd : THandle ) : Boolean;
function IsCygwinTerminal( ParaFd : THandle ) : Boolean;

implementation

function IsTerminal( ParaFd : THandle ) : Boolean;
var
	vMode : DWORD;
begin
	Result := GetConsoleMode( ParaFd, vMode );
end;

function IsCygwinTerminal( ParaFd : THandle ) : Boolean;
begin
	// Simplified Cygwin detection
	Result := False;
end;

end.
