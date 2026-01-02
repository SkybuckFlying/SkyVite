{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Mattn.GoIsAtty.IsAttyOthers;

interface

function IsTerminal( ParaFd : THandle ) : Boolean;
function IsCygwinTerminal( ParaFd : THandle ) : Boolean;

implementation

function IsTerminal( ParaFd : THandle ) : Boolean;
begin
	Result := False;
end;

function IsCygwinTerminal( ParaFd : THandle ) : Boolean;
begin
	Result := False;
end;

end.
