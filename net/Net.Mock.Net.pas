unit Net.Mock.Net;

interface

uses
	System.SysUtils,
	Common.Types,
	Crypto.Ed25519,
	Interfaces.Core.Snapshot.Block,
	Interfaces.Core.Account.Block,
	Net.Interface,
	Net.Vnode;

type
	TMockNet = class(TInterfacedObject, INet)
	private
		mChain : IChain;
	public
		constructor Create( ParaChain : IChain );

		function PeerKey : TPrivateKey;
		function SubscribeSyncStatus( ParaFn : TSyncStateCallback ) : Integer;
		procedure UnsubscribeSyncStatus( ParaSubId : Integer );
		function SyncState : TSyncState;
		function Peek : TChunk;
		procedure Pop( ParaEndHash : THash );
		function Status : TSyncStatus;
		function Detail : TSyncDetail;
		procedure FetchSnapshotBlocks( ParaStart : THash; ParaCount : UInt64 );
		procedure FetchSnapshotBlocksWithHeight( ParaHash : THash; ParaHeight, ParaCount : UInt64 );
		procedure FetchAccountBlocks( ParaStart : THash; ParaCount : UInt64; ParaAddress : TAddress );
		procedure FetchAccountBlocksWithHeight( ParaStart : THash; ParaCount : UInt64; ParaAddress : TAddress; ParaSHeight : UInt64 );
		procedure BroadcastSnapshotBlock( ParaBlock : TSnapshotBlock );
		procedure BroadcastSnapshotBlocks( ParaBlocks : TArray<TSnapshotBlock> );
		procedure BroadcastAccountBlock( ParaBlock : TAccountBlock );
		procedure BroadcastAccountBlocks( ParaBlocks : TArray<TAccountBlock> );
		function SubscribeAccountBlock( ParaFn : TAccountBlockCallback ) : Integer;
		procedure UnsubscribeAccountBlock( ParaSubId : Integer );
		function SubscribeSnapshotBlock( ParaFn : TSnapshotBlockCallback ) : Integer;
		procedure UnsubscribeSnapshotBlock( ParaSubId : Integer );
		function Stop : Boolean;
		function Start : Boolean;
		function Info : TNodeInfo;
		function Nodes : TArray<TVnode>;
		function PeerCount : Integer;
	end;

function Mock( ParaChain : IChain ) : INet;

implementation

{ TMockNet }

constructor TMockNet.Create( ParaChain : IChain );
begin
	inherited Create;
	mChain := ParaChain;
end;

function TMockNet.PeerKey : TPrivateKey;
begin
	Result := nil;
end;

function TMockNet.SubscribeSyncStatus( ParaFn : TSyncStateCallback ) : Integer;
begin
	Result := 0;
end;

procedure TMockNet.UnsubscribeSyncStatus( ParaSubId : Integer );
begin
end;

function TMockNet.SyncState : TSyncState;
begin
	Result := TSyncState.SyncDone;
end;

function TMockNet.Peek : TChunk;
begin
	Result := nil;
end;

procedure TMockNet.Pop( ParaEndHash : THash );
begin
end;

function TMockNet.Status : TSyncStatus;
begin
	Result.Current := mChain.GetLatestSnapshotBlock.Height;
	Result.State := TSyncState.SyncDone;
end;

function TMockNet.Detail : TSyncDetail;
begin
	Result.SyncStatus := Status;
	// DownloaderStatus initialization
end;

procedure TMockNet.FetchSnapshotBlocks( ParaStart : THash; ParaCount : UInt64 );
begin
end;

procedure TMockNet.FetchSnapshotBlocksWithHeight( ParaHash : THash; ParaHeight, ParaCount : UInt64 );
begin
end;

procedure TMockNet.FetchAccountBlocks( ParaStart : THash; ParaCount : UInt64; ParaAddress : TAddress );
begin
end;

procedure TMockNet.FetchAccountBlocksWithHeight( ParaStart : THash; ParaCount : UInt64; ParaAddress : TAddress; ParaSHeight : UInt64 );
begin
end;

procedure TMockNet.BroadcastSnapshotBlock( ParaBlock : TSnapshotBlock );
begin
end;

procedure TMockNet.BroadcastSnapshotBlocks( ParaBlocks : TArray<TSnapshotBlock> );
begin
end;

procedure TMockNet.BroadcastAccountBlock( ParaBlock : TAccountBlock );
begin
end;

procedure TMockNet.BroadcastAccountBlocks( ParaBlocks : TArray<TAccountBlock> );
begin
end;

function TMockNet.SubscribeAccountBlock( ParaFn : TAccountBlockCallback ) : Integer;
begin
	Result := 0;
end;

procedure TMockNet.UnsubscribeAccountBlock( ParaSubId : Integer );
begin
end;

function TMockNet.SubscribeSnapshotBlock( ParaFn : TSnapshotBlockCallback ) : Integer;
begin
	Result := 0;
end;

procedure TMockNet.UnsubscribeSnapshotBlock( ParaSubId : Integer );
begin
end;

function TMockNet.Stop : Boolean;
begin
	Result := True;
end;

function TMockNet.Start : Boolean;
begin
	Result := True;
end;

function TMockNet.Info : TNodeInfo;
begin
	// NodeInfo initialization
end;

function TMockNet.Nodes : TArray<TVnode>;
begin
	Result := nil;
end;

function TMockNet.PeerCount : Integer;
begin
	Result := 0;
end;

function Mock( ParaChain : IChain ) : INet;
begin
	Result := TMockNet.Create( ParaChain );
end;

end.
