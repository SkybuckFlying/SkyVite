unit Vendor.Golang.Org.X.Sys.Unix.SockcmsgLinux;

interface

uses
  System.SysUtils;

type
  TUcred = record
    // ...
  end;
  PUcred = ^TUcred;

function UnixCredentials(Ucred: PUcred): TBytes;
// function ParseUnixCredentials(M: PSocketControlMessage): TTuple<PUcred, Exception>;

implementation

function UnixCredentials(Ucred: PUcred): TBytes;
begin
  Result := nil;
end;

end.
