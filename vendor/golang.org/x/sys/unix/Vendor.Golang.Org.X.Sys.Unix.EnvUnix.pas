unit Vendor.Golang.Org.X.Sys.Unix.EnvUnix;

interface

uses
  System.SysUtils;

function Getenv(const Key: string; out Value: string): Boolean;
function Setenv(const Key, Value: string): Exception;
procedure Clearenv;
function Environ: TArray<string>;
function Unsetenv(const Key: string): Exception;

implementation

function Getenv(const Key: string; out Value: string): Boolean;
begin
  Value := GetEnvironmentVariable(Key);
  Result := Value <> '';
end;

function Setenv(const Key, Value: string): Exception;
begin
  // SetEnvironmentVariable(Key, Value)
  Result := nil;
end;

procedure Clearenv;
begin
end;

function Environ: TArray<string>;
begin
  Result := nil;
end;

function Unsetenv(const Key: string): Exception;
begin
  Result := nil;
end;

end.
