unit Vite.Mock;

interface

uses
  Common.Config.Config,
  Vite,
  Wallet.Manager;

function NewMock( ParaCfg : TConfig; ParaWalletManager : TWalletManager ) : TVite;

implementation

uses
	System.SysUtils,
	Node.Config.Config;

function NewMock( ParaCfg : TConfig; ParaWalletManager : TWalletManager ) : TVite;
var
	vNodeConfig : TNodeConfig;
	vCfg : TConfig;
	vWalletManager : TWalletManager;
begin
	vCfg := ParaCfg;
	vWalletManager := ParaWalletManager;
	vNodeConfig := nil;

	try
		if ( vCfg = nil ) or ( vWalletManager = nil ) then
		begin
			try
				vNodeConfig := TNodeConfig.Create;
				// vNodeConfig.ParseFromFile('~/go/src/github.com/vitelabs/go-vite/conf/evm/node_config.json');
			except
				on E: Exception do
				begin
					// Handle node config creation error
				end;
			end;
		end;

		if vCfg = nil then
		begin
			if vNodeConfig <> nil then
			begin
				vCfg := vNodeConfig.MakeViteConfig;
			end;
		end;

		if vWalletManager = nil then
		begin
			if vNodeConfig <> nil then
			begin
				vWalletManager := TWalletManager.New( vNodeConfig.MakeWalletConfig );
			end;
		end;

		// TODO: use mocks for net, chain, pool, etc.
		Result := TVite.Create
		(
			vCfg,
			vWalletManager,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil
		);
	finally
		// Note: vNodeConfig might be needed by vCfg if it's not a deep copy, 
		// but usually in Go it's a pointer to a struct. 
		// If vNodeConfig is just a helper to create vCfg, we free it here.
		if vNodeConfig <> nil then
		begin
			vNodeConfig.Free;
		end;
	end;
end;

end.
