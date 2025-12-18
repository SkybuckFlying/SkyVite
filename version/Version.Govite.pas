unit version.govite;

interface

uses
  System.SysUtils,
  Version.Buildversion;

procedure PrintBuildVersion;

implementation

uses
  version.buildversion;

procedure PrintBuildVersion;
begin
  if VITE_COMMIT_VERSION <> '' then
    WriteLn(Format('this vite node`s version(%s), git commit %s, ', [VITE_BUILD_VERSION, VITE_COMMIT_VERSION]))
  else
    WriteLn('can not read gitversion file please use Make to build Vite ');
end;

end.
