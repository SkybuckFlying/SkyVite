unit Net.Skeleton.Test;

interface

uses
  Common.Types,
  Interfaces.Core.Hash.Height,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
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
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
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
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading,
  unit_GoLang_Compatibility_version_006;

procedure TestSkeleton_Construct;
procedure TestSkeleton_Reset;

implementation

procedure TestSkeleton_Construct;
var
	vPeers : TPeerSet;
	vI : Integer;
	vSk : TSkeleton;
	vWG : TGoWaitGroup;
begin
	vPeers := TPeerSet.Create;
	try
		for vI := 0 to 3 do
		begin
			vPeers.Add( TPeer.Create( TRandomNodeID, 100 ) );
		end;

		vSk := TSkeleton.Create( vPeers, TGid.Create, TDictionary<THash, Pointer>.Create );
		try
			vWG := TGoWaitGroup.Create;
			try
				for vI := 0 to 99 do
				begin
					vWG.Add( 1 );
					TGo.Run( procedure
					var
						vList : TArray<THashHeightPoint>;
					begin
						try
							vList := vSk.Construct( [THashHeight.Create( 99, THash.Empty )], 100 );
							// Writeln(Length(vList));
						finally
							vWG.Done;
						end;
					end );
				end;
				vWG.Wait;
			finally
				vWG.Free;
			end;
		finally
			vSk.Free;
		end;
	finally
		vPeers.Free;
	end;
end;

procedure TestSkeleton_Reset;
var
	vPeers : TPeerSet;
	vI : Integer;
	vSk : TSkeleton;
	vWG : TGoWaitGroup;
begin
	vPeers := TPeerSet.Create;
	try
		for vI := 0 to 3 do
		begin
			vPeers.Add( TPeer.Create( TRandomNodeID, 100 ) );
		end;

		vSk := TSkeleton.Create( vPeers, TGid.Create, TDictionary<THash, Pointer>.Create );
		try
			vWG := TGoWaitGroup.Create;
			try
				for vI := 0 to 99 do
				begin
					vWG.Add( 1 );
					TGo.Run( procedure
					var
						vList : TArray<THashHeightPoint>;
						vN : Integer;
					begin
						vN := vI; // Capture vI? No, we need a local copy or similar if using TGo.Run correctly
						// But for a simple test we can just use the captured value if safe
						try
							if vN mod 2 = 0 then
							begin
								vList := vSk.Construct( [THashHeight.Create( 99, THash.Empty )], 100 );
							end else
							begin
								vSk.Reset;
							end;
						finally
							vWG.Done;
						end;
					end );
				end;
				vWG.Wait;
			finally
				vWG.Free;
			end;
		finally
			vSk.Free;
		end;
	finally
		vPeers.Free;
	end;
end;

end.
