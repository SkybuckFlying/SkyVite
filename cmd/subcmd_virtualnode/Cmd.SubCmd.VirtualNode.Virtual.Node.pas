unit Cmd.Subcmd_virtualnode.Virtual_node;

interface

uses
	System.SysUtils,
	System.Classes,
	BigNumbers,
	Cli,
	Nodemanager,
	Utils,
	Common.Config,
	Common.Helper,
	Common.Types,
	Interfaces.Core,
	Node.Nodeconfig;

var
	VirtualNodeCommand: TCommand;

implementation

uses
	System.Generics.Collections;

var
	richFlag: TStringFlag;

procedure VirtualConsensusVerifier(ParaCfg: TConfig);
begin
	ParaCfg.Producer.VirtualSnapshotVerifier := True;
end;

procedure VirtualApi(ParaCfg: TNodeConfig);
begin
	SetLength(ParaCfg.PublicModules, Length(ParaCfg.PublicModules) + 1);
	ParaCfg.PublicModules[High(ParaCfg.PublicModules)] := 'virtual';
end;

procedure RichAddresses(ParaCfg: TConfig; ParaRich: TArray<TAddress>);
var
	vTokenId: TTokenTypeId;
	vStakeAmount: TBigInteger;
	vAddr: TAddress;
	vAccountBalance: TDictionary<string, TBigInteger>;
begin
	vTokenId := TViteTokenId;
	try
		vStakeAmount := TBigInteger.Create(100000).Multiply(TBigInteger.Create(10).Power(18));
		try
			for vAddr in ParaRich do
			begin
				ParaCfg.Genesis.QuotaInfo.StakeBeneficialMap.AddOrSetValue(vAddr.ToString, vStakeAmount);

				if not ParaCfg.Genesis.AccountBalanceMap.TryGetValue(vAddr.ToString, vAccountBalance) then
				begin
					vAccountBalance := TDictionary<string, TBigInteger>.Create;
					ParaCfg.Genesis.AccountBalanceMap.Add(vAddr.ToString, vAccountBalance);
				end;
				vAccountBalance.AddOrSetValue(vTokenId.ToString, vStakeAmount);
			end;
		finally
			vStakeAmount.Free;
		end;
	except
		on E: EOutOfMemory do
		begin
			// Handle memory allocation failure for vStakeAmount
			raise;
		end;
	end;
end;

procedure StartVirtualNode(ParaCtx: TContext);
var
	vNodeManager: IDefaultNodeManager;
	vRichAddrStr: string;
	vRichAddrs: TArray<TAddress>;
begin
	if Length(ParaCtx.Args) > 0 then
	begin
		raise Exception.Create(Format('invalid command: %s', [ParaCtx.Args.First]));
	end;

	try
		vNodeManager := TDefaultNodeManager.Create(ParaCtx, TFullNodeMaker.Create);
		try
			if ParaCtx.GlobalIsSet(richFlag.Name) then
			begin
				vRichAddrStr := ParaCtx.GlobalString(richFlag.Name);
				try
					SetLength(vRichAddrs, 1);
					vRichAddrs[0] := THex.HexToAddressPanic(vRichAddrStr);
					RichAddresses(vNodeManager.Node.ViteConfig, vRichAddrs);
				except
					on E: EOutOfMemory do
					begin
						// Handle memory allocation failure for vRichAddrs
						raise;
					end;
				end;
			end;

			VirtualApi(vNodeManager.Node.Config);
			VirtualConsensusVerifier(vNodeManager.Node.ViteConfig);

			if vNodeManager.Start <> 0 then
			begin
				raise Exception.Create(Format('Failed to start node: %s', [vNodeManager.LastError.Message]));
			end;
		finally
			vNodeManager := nil; // Release interface
		end;
	except
		on E: Exception do
		begin
			WriteLn(E.ClassName, ': ', E.Message);
		end;
	end;
end;

initialization
	richFlag := TStringFlag.Create('rich', 'rich address', '');

	VirtualNodeCommand := TCommand.Create(
		'virtual',
		'start virtual node',
		'',
		'LOCAL COMMANDS',
		'Load ledger.',
		MigrateFlags(StartVirtualNode),
		utils.MergeFlags(utils.ConfigFlags, [richFlag])
	);
end.