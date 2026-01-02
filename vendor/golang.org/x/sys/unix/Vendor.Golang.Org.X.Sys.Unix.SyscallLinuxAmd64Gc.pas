{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxAmd64Gc;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function gettimeofday( ParaTv : PZTimeval ) : Integer;

implementation

function gettimeofday( ParaTv : PZTimeval ) : Integer;
begin
	Result := 0; // Placeholder
end;

end.
