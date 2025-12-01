unit Cmd.Subcmd_rpc.Rpc_call;

interface

uses
	System.SysUtils,
	System.Classes,
	System.JSON,
	Cli,
	Utils,
	Client;

var
	RpcCommand: TCommand;

implementation

uses
	System.Generics.Collections;

procedure RemoteCallAction(ParaCtx: TContext);
var
	vEndpoint: string;
	vMethod: string;
	vArgsStr: string;
	vConn: IRpcClient;
	vArgs: TJSONArray;
	vResultValue: TJSONValue;
	vResultBytes: TBytes;
	vParams: TArray<TObject>;
	vIndex: integer;
begin
	vEndpoint := ParaCtx.Args.First;
	vMethod := ParaCtx.Args.Get(1);
	vArgsStr := ParaCtx.Args.Get(2);

	try
		vConn := NewRpcClient(vEndpoint);
		try
			vArgs := nil;
			if vArgsStr <> '' then
			begin
				try
					vArgs := TJSONObject.ParseJSONValue(vArgsStr) as TJSONArray;
				except
					on E: Exception do
					begin
						raise Exception.Create(Format('Failed to parse arguments as JSON array: %s', [E.Message]));
					end;
					end;
				end;

			if Assigned(vArgs) then
			begin
				try
					SetLength(vParams, vArgs.Size);
					for vIndex := 0 to vArgs.Size - 1 do
					begin
						vParams[vIndex] := TObject(vArgs.Items[vIndex]);
					end;
\t			except
					on E: EOutOfMemory do
					begin
						// Handle memory allocation failure for vParams
						raise;
					end;
					end;
				end
			else
			begin
				SetLength(vParams, 0);
			end;

			vResultValue := vConn.RawCall(vMethod, vParams);

			vResultBytes := TEncoding.UTF8.GetBytes(vResultValue.ToString);
			WriteLn(TEncoding.UTF8.GetString(vResultBytes));
		finally
			vConn := nil;
			if Assigned(vArgs) then
			begin
				vArgs.Free;
			end;
		end;
	except
		on E: Exception do
		begin
			WriteLn(E.ClassName, ': ', E.Message);
		end;
	end;
end;

initialization
	RpcCommand := TCommand.Create(
		'rpc',
		'Remote Procedure Call',
		'gvite rpc [endpoint] methodName \'[args]\'',
		'REMOTE COMMANDS',
		'For details, see <https://docs.vite.org/vite-docs/api/rpc>',
		MigrateFlags(RemoteCallAction),
		utils.MergeFlags(utils.ConsoleFlags, [utils.DataDirFlag])
	);

end.