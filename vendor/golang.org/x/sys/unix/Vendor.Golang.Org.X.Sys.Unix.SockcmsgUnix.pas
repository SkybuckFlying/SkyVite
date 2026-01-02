unit Vendor.Golang.Org.X.Sys.Unix.SockcmsgUnix;

interface

uses
  System.SysUtils;

function CmsgLen(Datalen: Integer): Integer;
function CmsgSpace(Datalen: Integer): Integer;

type
  TSocketControlMessage = record
    // Header: TCmsghdr;
    Data: TBytes;
  end;

function UnixRights(const Fds: array of Integer): TBytes;

implementation

function CmsgLen(Datalen: Integer): Integer;
begin
  Result := Datalen + 8; // Simplified
end;

function CmsgSpace(Datalen: Integer): Integer;
begin
  Result := Datalen + 16; // Simplified
end;

function UnixRights(const Fds: array of Integer): TBytes;
begin
  Result := nil;
end;

end.
