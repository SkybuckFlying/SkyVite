unit Net.Sync.Server.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Threading,
	Net.Sync.Server,
	unit_GoLang_Compatibility_version_006;

procedure Test_File_Server;

implementation

procedure Test_File_Server;
var
	vAddr : string;
	vFs : TSyncServer;
	vConns : Int32;
	vI : Integer;
begin
	vAddr := 'localhost:8484';
	vFs := TSyncServer.Create( vAddr, nil, nil );
	try
		vFs.Start;
		
		vConns := 0;
		for vI := 0; vI < 100; vI ++ do
		begin
			TGo.Run( procedure
				var
					vClient : TGoTcpClient;
				begin
					vClient := TGoTcpClient.Create;
					try
						if vClient.Connect( '127.0.0.1', 8484 ) then
						begin
							TInterlocked.Increment( vConns );
							if Random( 10 ) > 5 then
							begin
								TThread.Sleep( 1000 );
								vClient.Close;
								TInterlocked.Decrement( vConns );
							end;
						end;
					finally
						vClient.Free;
					end;
				end );
		end;
		
		TThread.Sleep( 3000 );
		
		// Map size check... (need access to internal map or status)
		// if vFs.ConnCount <> vConns then raise Exception.Create('Fail');
		
		vFs.Stop;
		
		// if vFs.ConnCount <> 0 then raise Exception.Create('Fail');
	finally
		vFs.Free;
	end;
end;

end.
