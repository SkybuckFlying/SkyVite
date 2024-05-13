unit unit_govite;

interface

procedure PrintBuildVersion();

implementation

uses
	unit_build_version,
	SysUtils;

// For "govendor install"

procedure PrintBuildVersion();
begin
  if VITE_COMMIT_VERSION <> '' then
  begin
	WriteLn(Format('this vite node''s version(%s), git commit %s, ', [VITE_BUILD_VERSION, VITE_COMMIT_VERSION]));
  end
  else
  begin
	WriteLn('can not read gitversion file please use Make to build Vite ');
  end;
end;


end.
