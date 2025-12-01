program Cmd_UpdaterConsensus_Main;

{$APPTYPE CONSOLE}

uses
	System.SysUtils,
	System.Classes,
	System.JSON,
	System.IOUtils,
	Common.Db.Xleveldb,
	Ledger.Consensus.Cdb;

var
	vIndex: UInt64 = 0;
	vDataDir: string = '';
	vDB: TLevelDB;
	vCDB: IConsensusDB;
	vPoint: TObject;
	vBytes: TBytes;
	vLoopIndex: integer;
begin
	for vLoopIndex := 1 to ParamCount do
	begin
		if ParamStr(vLoopIndex).StartsWith('--index=') then
		begin
			vIndex := StrToUInt64(Copy(ParamStr(vLoopIndex), 9, MaxInt));
		end
		else if ParamStr(vLoopIndex).StartsWith('--dataDir=') then
		begin
			vDataDir := Copy(ParamStr(vLoopIndex), 11, MaxInt);
		end;
	end;

	try
		if vIndex = 0 then
		begin
			raise Exception.Create('error index');
		end;
		if vDataDir = '' then
		begin
			raise Exception.Create('err dir');
		end;

		vDB := TLevelDB.OpenFile(vDataDir, nil);
		try
			vCDB := TConsensusDB.Create(vDB);

			vPoint := vCDB.GetPointByHeight(TIndexPointType.IndexPointDay, vIndex);

			vBytes := TEncoding.UTF8.GetBytes(TJson.ObjectToJsonString(vPoint));
			WriteLn(TEncoding.UTF8.GetString(vBytes));

			vCDB.DeletePointByHeight(TIndexPointType.IndexPointDay, vIndex);
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