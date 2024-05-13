program SkyVite;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Unit_Main in 'cmd\gvite\Unit_Main.pas',
  unit_govite in 'version\unit_govite.pas',
  unit_build_version in 'version\unit_build_version.pas',
  unit_load_plugins in 'cmd\gvite_plugins\unit_load_plugins.pas',
  unit_cli in 'go\unit_cli.pas',
  unit_default_node_manager in 'cmd\nodemanager\unit_default_node_manager.pas',
  unit_node in 'node\unit_node.pas',
  unit_vite in 'unit_vite.pas',
  unit_config in 'common\config\unit_config.pas',
  unit_producer in 'common\config\unit_producer.pas',
  unit_address in 'common\types\unit_address.pas',
  unit_crypto in 'crypto\unit_crypto.pas',
  unit_ed25519 in 'crypto\ed25519\unit_ed25519.pas',
  unit_ed25519_alternative_1 in 'crypto\ed25519\unit_ed25519_alternative_1.pas';

begin
  try
	Main;
  except
	on E: Exception do
	  Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
