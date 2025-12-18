unit Net.Sync.Conn;

interface

uses
  Common.Types,
  Common.VitePB,
  Crypto.Ed25519,
  Crypto.X25519,
  Interfaces,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Connector.Connector,
  Net.Database.Database,
  Net.Database.Database.Test,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Protos.Message.PB,
  Net.Discovery.Simular.Simular,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  Net.Netool.Net.Test,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  Net.Vnode,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  System.TimeSpan,
  unit_GoLang_Compatibility_version_006;

type
	TSyncHandshake = class
	public
		Id : TNodeID;
		Key : TBytes;
		Time : Int64;
		Token : TBytes;
		function Serialize : TBytes;
		procedure Deserialize( ParaData : TBytes );
	end;

	TSyncRequest = class
	public
		From, ToVal : UInt64;
		PrevHash, EndHash : THash;
		function Serialize : TBytes;
		procedure Deserialize( ParaData : TBytes );
	end;

	TSyncResponse = class
	public
		From, ToVal : UInt64;
		Size : UInt64;
		PrevHash, EndHash : THash;
		function Serialize : TBytes;
		procedure Deserialize( ParaData : TBytes );
	end;

	TSyncConn = class
	private
		// mConn : ISocket;
		mCodec : ICodec;
		mPeer : TPeer;
		mBusy : Integer; // atomic
		mSpeed : UInt64;
		mTask : TDownloadTask;
		mClosed : Integer; // atomic
		mCacher : ISyncChain;
		mFailed : Integer;
		function GetAddress : string;
		function IsBusy : Boolean;
		function Fail : Boolean;
	public
		constructor Create( ParaCodec : ICodec; ParaPeer : TPeer; ParaCacher : ISyncChain );
		function Status : TSyncConnectionStatus;
		function Download( ParaT : TDownloadTask ) : Boolean; // Return True if fatal
		procedure Close;
		property Speed : UInt64 read mSpeed;
	end;

	TDownloadConnPool = class
	private
		mMu : TCriticalSection;
		mPeers : TPeerSet;
		mMapIdToIndex : TDictionary<TNodeID, Integer>;
		mConnections : TList<TSyncConn>;
		mBlackList : TDictionary<TNodeID, Int64>;
		procedure SortLocked;
		procedure DelConnLocked( ParaId : TNodeID );
	public
		constructor Create( ParaPeers : TPeerSet );
		destructor Destroy; override;
		procedure BlockPeer( ParaId : TNodeID; ParaDuration : TTimeSpan );
		function IsBlocked( ParaId : TNodeID ) : Boolean;
		function GetConnections : TArray<TSyncConnectionStatus>;
		procedure AddConn( ParaC : TSyncConn );
		procedure DelConn( ParaC : TSyncConn );
		procedure Sort;
		function ChooseSource( ParaT : TDownloadTask; out ParaPeer : TPeer; out ParaConn : TSyncConn ) : Boolean;
		procedure Reset;
	end;

implementation

{ TSyncHandshake }

function TSyncHandshake.Serialize : TBytes;
var
	vPB : TSyncConnHandshakePB;
begin
	vPB := TSyncConnHandshakePB.Create;
	try
		vPB.ID := Id.Bytes;
		vPB.Timestamp := Time;
		vPB.Key := Key;
		vPB.Token := Token;
		Result := vPB.Marshal;
	finally
		vPB.Free;
	end;
end;

procedure TSyncHandshake.Deserialize( ParaData : TBytes );
var
	vPB : TSyncConnHandshakePB;
begin
	vPB := TSyncConnHandshakePB.Create;
	try
		vPB.Unmarshal( ParaData );
		Id := TNodeID.FromBytes( vPB.ID );
		Time := vPB.Timestamp;
		Key := vPB.Key;
		Token := vPB.Token;
	finally
		vPB.Free;
	end;
end;

{ TSyncRequest }

function TSyncRequest.Serialize : TBytes;
var
	vPB : TChunkRequestPB;
begin
	vPB := TChunkRequestPB.Create;
	try
		vPB.From := From;
		vPB.ToVal := ToVal;
		vPB.PrevHash := PrevHash.Bytes;
		vPB.EndHash := EndHash.Bytes;
		Result := vPB.Marshal;
	finally
		vPB.Free;
	end;
end;

procedure TSyncRequest.Deserialize( ParaData : TBytes );
var
	vPB : TChunkRequestPB;
begin
	vPB := TChunkRequestPB.Create;
	try
		vPB.Unmarshal( ParaData );
		From := vPB.From;
		ToVal := vPB.ToVal;
		PrevHash := THash.FromBytes( vPB.PrevHash );
		EndHash := THash.FromBytes( vPB.EndHash );
	finally
		vPB.Free;
	end;
end;

{ TSyncResponse }

function TSyncResponse.Serialize : TBytes;
var
	vPB : TChunkResponsePB;
begin
	vPB := TChunkResponsePB.Create;
	try
		vPB.From := From;
		vPB.ToVal := ToVal;
		vPB.Size := Size;
		vPB.PrevHash := PrevHash.Bytes;
		vPB.EndHash := EndHash.Bytes;
		Result := vPB.Marshal;
	finally
		vPB.Free;
	end;
end;

procedure TSyncResponse.Deserialize( ParaData : TBytes );
var
	vPB : TChunkResponsePB;
begin
	vPB := TChunkResponsePB.Create;
	try
		vPB.Unmarshal( ParaData );
		From := vPB.From;
		ToVal := vPB.ToVal;
		Size := vPB.Size;
		PrevHash := THash.FromBytes( vPB.PrevHash );
		EndHash := THash.FromBytes( vPB.EndHash );
	finally
		vPB.Free;
	end;
end;

{ TSyncConn }

constructor TSyncConn.Create( ParaCodec : ICodec; ParaPeer : TPeer; ParaCacher : ISyncChain );
begin
	inherited Create;
	mCodec := ParaCodec;
	mPeer := ParaPeer;
	mCacher := ParaCacher;
	mBusy := 0;
	mClosed := 0;
	mSpeed := 0;
	mFailed := 0;
end;

function TSyncConn.IsBusy : Boolean;
begin
	Result := TInterlocked.Read( mBusy ) = 1;
end;

function TSyncConn.GetAddress : string;
begin
	Result := mCodec.Address.ToString;
end;

function TSyncConn.Fail : Boolean;
begin
	TInterlocked.Increment( mFailed );
	Result := mFailed > 3;
end;

function TSyncConn.Status : TSyncConnectionStatus;
begin
	Result.Address := mPeer.Id.Brief + '@' + GetAddress;
	Result.Speed := IntToStr( mSpeed ) + ' Byte/s'; // Simplified formatting
	if IsBusy then Result.Task := mTask.ToString else Result.Task := '';
end;

function TSyncConn.Download( ParaT : TDownloadTask ) : Boolean;
begin
	// Download implementation logic...
	Result := False;
end;

procedure TSyncConn.Close;
begin
	if TInterlocked.CompareExchange( mClosed, 1, 0 ) = 0 then
	begin
		mCodec.Close;
	end;
end;

{ TDownloadConnPool }

constructor TDownloadConnPool.Create( ParaPeers : TPeerSet );
begin
	inherited Create;
	mPeers := ParaPeers;
	mMu := TCriticalSection.Create;
	mMapIdToIndex := TDictionary<TNodeID, Integer>.Create;
	mConnections := TList<TSyncConn>.Create;
	mBlackList := TDictionary<TNodeID, Int64>.Create;
end;

destructor TDownloadConnPool.Destroy;
begin
	Reset;
	mBlackList.Free;
	mConnections.Free;
	mMapIdToIndex.Free;
	mMu.Free;
	inherited Destroy;
end;

procedure TDownloadConnPool.BlockPeer( ParaId : TNodeID; ParaDuration : TTimeSpan );
begin
	mMu.Enter;
	try
		mBlackList.AddOrSetValue( ParaId, DateTimeToUnix( Now + ParaDuration.TotalDays ) );
	finally
		mMu.Leave;
	end;
end;

function TDownloadConnPool.IsBlocked( ParaId : TNodeID ) : Boolean;
var
	vNow : Int64;
	vTime : Int64;
begin
	vNow := DateTimeToUnix( Now );
	mMu.Enter;
	try
		if mBlackList.TryGetValue( ParaId, vTime ) then
		begin
			if vTime > vNow then Exit( True );
			mBlackList.Remove( ParaId );
		end;
		Result := False;
	finally
		mMu.Leave;
	end;
end;

function TDownloadConnPool.GetConnections : TArray<TSyncConnectionStatus>;
var
	vI : Integer;
begin
	mMu.Enter;
	try
		SetLength( Result, mConnections.Count );
		for vI := 0 to mConnections.Count - 1 do Result[vI] := mConnections[vI].Status;
	finally
		mMu.Leave;
	end;
end;

procedure TDownloadConnPool.AddConn( ParaC : TSyncConn );
begin
	mMu.Enter;
	try
		if mMapIdToIndex.ContainsKey( ParaC.mPeer.Id ) then raise Exception.Create( 'sync connection has exist' );
		mConnections.Add( ParaC );
		mMapIdToIndex.Add( ParaC.mPeer.Id, mConnections.Count - 1 );
	finally
		mMu.Leave;
	end;
end;

procedure TDownloadConnPool.DelConn( ParaC : TSyncConn );
begin
	ParaC.Close;
	mMu.Enter;
	try
		DelConnLocked( ParaC.mPeer.Id );
	finally
		mMu.Leave;
	end;
end;

procedure TDownloadConnPool.DelConnLocked( ParaId : TNodeID );
var
	vIndex : Integer;
begin
	if mMapIdToIndex.TryGetValue( ParaId, vIndex ) then
	begin
		mMapIdToIndex.Remove( ParaId );
		mConnections.Delete( vIndex );
		SortLocked; // simplified refresh
	end;
end;

procedure TDownloadConnPool.Sort;
begin
	mMu.Enter;
	try
		SortLocked;
	finally
		mMu.Leave;
	end;
end;

procedure TDownloadConnPool.SortLocked;
begin
	// sort logic
end;

function TDownloadConnPool.ChooseSource( ParaT : TDownloadTask; out ParaPeer : TPeer; out ParaConn : TSyncConn ) : Boolean;
begin
	// choice logic...
	Result := False;
end;

procedure TDownloadConnPool.Reset;
var
	vC : TSyncConn;
begin
	mMu.Enter;
	try
		for vC in mConnections do vC.Close;
		mConnections.Clear;
		mMapIdToIndex.Clear;
	finally
		mMu.Leave;
	end;
end;

end.
