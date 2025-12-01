unit Common.DefaultParams;

interface

uses
  System.SysUtils;

const
  ConstDefaultHTTPHost = 'localhost'; // Default host interface for the HTTP RPC server
  ConstDefaultHTTPPort = 48132;       // Default TCP port for the HTTP RPC server
  ConstDefaultWSHost = 'localhost';   // Default host interface for the websocket RPC server
  ConstDefaultWSPort = 31420;       // Default TCP port for the websocket RPC server
  ConstDefaultP2PPort = 8483;

function DefaultDataDir: string;
function GoViteTestDataDir: string;
function HomeDir: string;
function DefaultHttpEndpoint: string;
function DefaultWSEndpoint: string;
function DefaultIpcFile: string;

implementation

uses
  System.IOUtils;

// DefaultDataDir is the default data directory for vite.
// It is equivalent to $HOME/viteisbest/ on most systems.
function DefaultDataDir: string;
var
  vHome: string;
begin
  vHome := HomeDir;
  if vHome <> '' then
  begin
    Result := TPath.Combine(vHome, 'viteisbest');
  end
  else
  begin
    Result := '';
  end;
end;

// GoViteTestDataDir returns the path to the testdata directory in the go-vite project.
// NOTE: This is a heuristic approach. In Go, `runtime.Caller(0)` provides the source file's path at runtime.
// In Delphi, we derive the path from the executable's location. This may require adjustment
// based on the final deployment structure (e.g., how deep the executable is nested).
function GoViteTestDataDir: string;
var
  vExecutablePath: string;
  vProjectRoot: string;
begin
  vExecutablePath := ExtractFilePath(ParamStr(0));
  // Assuming the executable is in a bin/ or Win32/Debug/ style folder,
  // we go up two levels to find the project root.
  vProjectRoot := TPath.GetFullPath(TPath.Combine(vExecutablePath, '..', '..'));
  Result := TPath.Combine(vProjectRoot, 'testdata');
end;

// HomeDir returns the user's home directory.
function HomeDir: string;
begin
  Result := TPath.GetHomePath;
  if Result = '' then
  begin
    // Fallback for environments where GetHomePath might fail.
    Result := GetEnvironmentVariable('HOME');
  end;
end;

// DefaultHttpEndpoint returns the default endpoint for the HTTP RPC server.
function DefaultHttpEndpoint: string;
begin
  Result := ':' + IntToStr(ConstDefaultHTTPPort);
end;

// DefaultWSEndpoint returns the default endpoint for the websocket RPC server.
function DefaultWSEndpoint: string;
begin
  Result := ':' + IntToStr(ConstDefaultWSPort);
}

// DefaultIpcFile returns the default IPC file path.
function DefaultIpcFile: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '\\.\pipe\vite.ipc';
  {$ELSE}
  Result := 'vite.ipc';
  {$ENDIF}
end;

end.