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
  unit_ed25519_alternative_1 in 'crypto\ed25519\unit_ed25519_alternative_1.pas',
  unit_manager in 'wallet\unit_manager.pas',
  unit_rpc in 'node\unit_rpc.pas',
  unit_pow in 'pow\unit_pow.pas',
  unit_node_config in 'node\config\unit_node_config.pas',
  unit_chain in 'ledger\chain\unit_chain.pas',
  unit_consensus in 'ledger\consensus\unit_consensus.pas',
  unit_pool in 'ledger\pool\unit_pool.pas',
  unit_verifier in 'ledger\verifier\unit_verifier.pas',
  unit_chain_v2 in 'ledger\chain\unit_chain_v2.pas';

begin
  try
	Main;
  except
	on E: Exception do
	  Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
