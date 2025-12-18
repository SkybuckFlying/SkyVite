unit Ledger.Chain.Test.Tools.Data.Dir;

interface

uses
  Ledger.Chain.Test.Tools.Mock,
  System.SysUtils;

function DefaultDataDir: string;

implementation

uses
  System.IOUtils;

function HomeDir: string;
begin
  // TPath.GetHomePath is the standard cross-platform way to get the user's home directory in Delphi.
  // It handles the underlying OS specifics, similar to the Go implementation.
  Result := TPath.GetHomePath;
end;

function DefaultDataDir: string;
var
  vHome: string;
begin
  vHome := HomeDir;
  if vHome <> '' then
  begin
    {$IFDEF MACOS}
    Result := TPath.Combine(TPath.Combine(vHome, 'Library'), 'GVite');
    {$ELSEIF MSWINDOWS}
    Result := TPath.Combine(TPath.Combine(TPath.Combine(vHome, 'AppData'), 'Roaming'), 'GVite');
    {$ELSE}
    // This covers Linux and other Unix-like systems, same as the Go code's default case.
    Result := TPath.Combine(vHome, '.gvite');
    {$ENDIF}
  end
  else
  begin
    // As we cannot guess a stable location, return empty and handle later.
    Result := '';
  end;
end;

end.
