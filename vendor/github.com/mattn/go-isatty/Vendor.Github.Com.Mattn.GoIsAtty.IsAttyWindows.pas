unit Vendor.Github.Com.Mattn.GoIsAtty.IsAttyWindows;

interface

uses
  Vendor.Github.Com.Mattn.GoIsAtty.Doc,
  Vendor.Github.Com.Mattn.GoIsAtty.IsAttyBsd,
  Vendor.Github.Com.Mattn.GoIsAtty.IsAttyOthers,
  Vendor.Github.Com.Mattn.GoIsAtty.IsAttyPlan9,
  Vendor.Github.Com.Mattn.GoIsAtty.IsAttySolaris,
  Vendor.Github.Com.Mattn.GoIsAtty.IsAttyTcgets,
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
