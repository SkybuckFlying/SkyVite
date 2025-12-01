program Cmd_Updater_Main;

{$APPTYPE CONSOLE}

uses
	System.SysUtils,
	System.Classes,
	System.IOUtils,
	System.Generics.Collections,
	Common.Types,
	Common.Db.Xleveldb,
	Ledger.Consensus.Cdb;

var
	vHashStr: string = '';
	vDataDir: string = 'devdata';
	vDoDelete: Boolean = False;
	vDB: TLevelDB;
	vHashPanic: THash;
	vCDB: IConsensusDB;
	vAddrMap: TDictionary<Integer, string>;
	vKey: Integer;
	vValue: string;
	vIndex: integer;
begin
	for vIndex := 1 to ParamCount do
	begin
		if ParamStr(vIndex).StartsWith('--hash=') then
		begin
			vHashStr := Copy(ParamStr(vIndex), 8, MaxInt);
		end
		else if ParamStr(vIndex).StartsWith('--dataDir=') then
		begin
			vDataDir := Copy(ParamStr(vIndex), 11, MaxInt);
		end
		else if ParamStr(vIndex) = '--delete' then
		begin
			vDoDelete := True;
		end;
	end;

	try
		vDB := TLevelDB.OpenFile(vDataDir, nil);
		try
			vHashPanic := THex.HexToHashPanic(vHashStr);

			vCDB := TConsensusDB.Create(vDB);
			vAddrMap := vCDB.GetElectionResultByHash(vHashPanic);

			WriteLn(Format('addr send:%s', [vHashPanic.ToString]));
			for vKey in vAddrMap.Keys do
			begin
				vValue := vAddrMap[vKey];
				WriteLn(Format('%d'#9'%s', [vKey, vValue]));
			end;

			if vDoDelete then
			begin
				WriteLn(Format('delete by hash:%s', [vHashPanic.ToString]));
				vCDB.DeleteElectionResultByHash(vHashPanic);
			end;
		finally
			vDB.Free;
		end;
	except
		on E: Exception do
		begin
			WriteLn(E.ClassName, ': ', E.Message);
			Halt(1);
		end;
	end;
end.