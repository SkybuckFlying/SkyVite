unit Node.Config.Defaults;

interface

uses
  Node.Config.Config,
  Node.Config.Config.Test,
  System.IOUtils,
  System.SysUtils;

function DefaultNodeConfig : TNodeConfig;
function DefaultDataDir : string;

implementation

function HomeDir : string;
begin
	Result := TPath.GetHomePath;
end;

function DefaultDataDir : string;
var
	vHome : string;
begin
	vHome := HomeDir;
	if vHome <> '' then
	begin
		{$IFDEF MSWINDOWS}
		Result := TPath.Combine( TPath.GetHomePath, 'AppData\Roaming\GVite' );
		{$ELSE}
		{$IFDEF MACOS}
		Result := TPath.Combine( vHome, 'Library\GVite' );
		{$ELSE}
		Result := TPath.Combine( vHome, '.gvite' );
		{$ENDIF}
		{$ENDIF}
	end else Result := '';
end;

function DefaultNodeConfig : TNodeConfig;
begin
	Result := TNodeConfig.Create;
	Result.IPCPath := 'gvite.ipc';
	Result.DataDir := DefaultDataDir;
	Result.KeyStoreDir := DefaultDataDir;
	Result.HttpPort := 48132; // Default ports
	Result.WSPort := 48133;
	Result.LogLevel := 'info';
	// Other defaults...
end;

end.
