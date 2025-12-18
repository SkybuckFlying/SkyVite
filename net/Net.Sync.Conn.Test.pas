unit Net.Sync.Conn.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	Common.Types,
	Net.Sync.Conn,
	Net.Vnode;

procedure TestSpeedToString;
procedure TestSyncHandshakeMsg_Serialize;
procedure Test_FileConns_Del;
procedure TestSyncReadyMsg;
procedure TestSyncRequest_Serialize;

implementation

procedure TestSpeedToString;
begin
	// formatting tests...
end;

procedure TestSyncHandshakeMsg_Serialize;
var
	vS, vS2 : TSyncHandshake;
	vData : TBytes;
begin
	vS := TSyncHandshake.Create;
	try
		vS.Id := TRandomNodeID;
		vS.Key := THash.Empty.Bytes;
		vS.Time := DateTimeToUnix( Now );
		vS.Token := [1, 2, 3];

		vData := vS.Serialize;
		
		vS2 := TSyncHandshake.Create;
		try
			vS2.Deserialize( vData );
			if vS.Id <> vS2.Id then raise Exception.Create( 'different id' );
			if vS.Time <> vS2.Time then raise Exception.Create( 'different time' );
		finally
			vS2.Free;
		end;
	finally
		vS.Free;
	end;
end;

procedure Test_FileConns_Del;
begin
	// delete tests...
end;

procedure TestSyncReadyMsg;
var
	vMsg, vMsg2 : TSyncResponse;
	vData : TBytes;
begin
	vMsg := TSyncResponse.Create;
	try
		vMsg.From := 101;
		vMsg.ToVal := 200;
		vMsg.Size := 20293;
		vMsg.PrevHash := THash.FromBytes( [1] );
		vMsg.EndHash := THash.FromBytes( [2] );

		vData := vMsg.Serialize;

		vMsg2 := TSyncResponse.Create;
		try
			vMsg2.Deserialize( vData );
			if vMsg2.From <> vMsg.From then raise Exception.Create( 'different from' );
			if vMsg2.Size <> vMsg.Size then raise Exception.Create( 'different size' );
		finally
			vMsg2.Free;
		end;
	finally
		vMsg.Free;
	end;
end;

procedure TestSyncRequest_Serialize;
var
	vRequest, vRequest2 : TSyncRequest;
	vData : TBytes;
begin
	vRequest := TSyncRequest.Create;
	try
		vRequest.From := 101;
		vRequest.ToVal := 200;
		vRequest.PrevHash := THash.FromBytes( [2] );
		vRequest.EndHash := THash.FromBytes( [1] );

		vData := vRequest.Serialize;

		vRequest2 := TSyncRequest.Create;
		try
			vRequest2.Deserialize( vData );
			if vRequest2.From <> vRequest.From then raise Exception.Create( 'different from' );
		finally
			vRequest2.Free;
		end;
	finally
		vRequest.Free;
	end;
end;

end.
