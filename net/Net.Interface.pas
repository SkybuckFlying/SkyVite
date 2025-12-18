unit net.interface;

interface

uses
  common.types crypto.ed25519 interfaces interfaces.core,
  ledger.consensus net.vnode,
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
  System.SysUtils System.Classes System.Generics.Collections;

type
  ISnapshotBlockReader = interface
    ['{YOUR_GUID_HERE}']
    function GetSnapshotBlockByHeight(Height: UInt64): ISnapshotBlock;
    function GetSnapshotBlockByHash(Hash: THash): ISnapshotBlock;
    function GetSnapshotBlocks(BlockHash: THash; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
  end;

  IAccountBlockReader = interface
    ['{YOUR_GUID_HERE}']
    function GetAccountBlockByHeight(Addr: TAddress; Height: UInt64): IAccountBlock;
    function GetAccountBlockByHash(BlockHash: THash): IAccountBlock;
    function GetAccountBlocks(BlockHash: THash; Count: UInt64): TArray<IAccountBlock>;
    function GetAccountBlocksByHeight(Addr: TAddress; Height: UInt64; Count: UInt64): TArray<IAccountBlock>;
    function GetConfirmedTimes(BlockHash: THash): UInt64;
  end;

  ILedgerReaderProvider = interface
    ['{YOUR_GUID_HERE}']
    function GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
  end;

  IChainReader = interface
    ['{YOUR_GUID_HERE}']
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
  end;

  ISyncCacher = interface
    ['{YOUR_GUID_HERE}']
    function GetSyncCache: ISyncCache;
  end;

  ISyncChain = interface(ISyncCacher, IChainReader)
    ['{YOUR_GUID_HERE}']
    function GetSnapshotBlockByHeight(Height: UInt64): ISnapshotBlock;
  end;

  IChain = interface(ISnapshotBlockReader, IAccountBlockReader, IChainReader, ILedgerReaderProvider, ISyncCacher)
    ['{YOUR_GUID_HERE}']
  end;

  IIrreversibleReader = interface
    ['{YOUR_GUID_HERE}']
    function GetIrreversibleBlock: ISnapshotBlock;
  end;

  IConsensus = interface
    ['{YOUR_GUID_HERE}']
    procedure SubscribeProducers(Gid: TGid; Id: string; Fn: TProducersEvent);
    procedure UnSubscribe(Gid: TGid; Id: string);
    function API: IConsensusAPIReader;
  end;

  IVerifier = interface
    ['{YOUR_GUID_HERE}']
    function VerifyNetSnapshotBlock(Block: ISnapshotBlock): Exception;
    function VerifyNetAccountBlock(Block: IAccountBlock): Exception;
  end;

  TSnapshotBlockCallback = procedure(Block: ISnapshotBlock; Source: TBlockSource);
  TAccountBlockCallback = procedure(Addr: TAddress; Block: IAccountBlock; Source: TBlockSource);
  TSyncStateCallback = procedure(State: TSyncState);

  IChunkReader = interface
    ['{YOUR_GUID_HERE}']
    function Peek: IChunk;
    procedure Pop(EndHash: THash);
  end;

  IChunk = interface
    ['{YOUR_GUID_HERE}']
    function GetSnapshotChunks: TArray<ISnapshotChunk>;
    function GetSnapshotRange: TArray<IHashHeight>;
    function GetAccountRange: TDictionary<TAddress, TArray<IHashHeight>>;
    function GetHashMap: TDictionary<THash, Boolean>;
    function GetSource: TBlockSource;
    function GetSize: Int64;
    function AddSnapshotBlock(Block: ISnapshotBlock): Exception;
    function AddAccountBlock(Block: IAccountBlock): Exception;
    function Done: Exception;
  end;

  TChunk = class(TInterfacedObject, IChunk)
  private
    FSnapshotChunks: TArray<ISnapshotChunk>;
    FSnapshotRange: TArray<IHashHeight>;
    FAccountRange: TDictionary<TAddress, TArray<IHashHeight>>;
    FHashMap: TDictionary<THash, Boolean>;
    FSource: TBlockSource;
    FSize: Int64;
  public
    constructor Create(Chunks: TArray<ISnapshotChunk>; Source: TBlockSource); overload;
    constructor Create(PrevHash: THash; PrevHeight: UInt64; EndHash: THash; EndHeight: UInt64; Source: TBlockSource); overload;
    destructor Destroy; override;
    function GetSnapshotChunks: TArray<ISnapshotChunk>;
    function GetSnapshotRange: TArray<IHashHeight>;
    function GetAccountRange: TDictionary<TAddress, TArray<IHashHeight>>;
    function GetHashMap: TDictionary<THash, Boolean>;
    function GetSource: TBlockSource;
    function GetSize: Int64;
    function AddSnapshotBlock(Block: ISnapshotBlock): Exception;
    function AddAccountBlock(Block: IAccountBlock): Exception;
    function Done: Exception;
  end;

  IBlockSubscriber = interface
    ['{YOUR_GUID_HERE}']
    function SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
    procedure UnsubscribeAccountBlock(SubId: Integer);
    function SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
    procedure UnsubscribeSnapshotBlock(SubId: Integer);
  end;

  ISyncStateSubscriber = interface
    ['{YOUR_GUID_HERE}']
    function SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
    procedure UnsubscribeSyncStatus(SubId: Integer);
    function SyncState: TSyncState;
  end;

  ISubscriber = interface(IBlockSubscriber, ISyncStateSubscriber)
    ['{YOUR_GUID_HERE}']
  end;

  IBroadcaster = interface
    ['{YOUR_GUID_HERE}']
    procedure BroadcastSnapshotBlock(Block: ISnapshotBlock);
    procedure BroadcastSnapshotBlocks(Blocks: TArray<ISnapshotBlock>);
    procedure BroadcastAccountBlock(Block: IAccountBlock);
    procedure BroadcastAccountBlocks(Blocks: TArray<IAccountBlock>);
  end;

  IFetcher = interface
    ['{YOUR_GUID_HERE}']
    procedure FetchSnapshotBlocks(Start: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
  end;

  ISyncer = interface(ISyncStateSubscriber, IChunkReader)
    ['{YOUR_GUID_HERE}']
    function Status: TSyncStatus;
    function Detail: TSyncDetail;
  end;

  INet = interface(ISyncer, IFetcher, IBroadcaster, IBlockSubscriber)
    ['{YOUR_GUID_HERE}']
    procedure Start;
    procedure Stop;
    function Info: INodeInfo;
    function Nodes: TArray<IVNode>;
    function PeerCount: Integer;
    function PeerKey: TPrivateKey;
  end;

implementation

{ TChunk }

constructor TChunk.Create(Chunks: TArray<ISnapshotChunk>; Source: TBlockSource);
var
  SnapshotChunk: ISnapshotChunk;
  Block: IAccountBlock;
  Addr: TAddress;
  Rng: TArray<IHashHeight>;
begin
  if Length(Chunks) = 0 then
    Exit;
  FSnapshotChunks := Chunks;
  SetLength(FSnapshotRange, 2);
  FSnapshotRange[0] := THashHeight.Create(Chunks[0].SnapshotBlock.PrevHash, Chunks[0].SnapshotBlock.Height - 1);
  FSnapshotRange[1] := THashHeight.Create(Chunks[High(Chunks)].SnapshotBlock.Hash, Chunks[High(Chunks)].SnapshotBlock.Height);
  FAccountRange := TDictionary<TAddress, TArray<IHashHeight>>.Create;
  FHashMap := TDictionary<THash, Boolean>.Create;
  FSource := Source;
  FSize := Length(Chunks);
  for SnapshotChunk in Chunks do
  begin
    FHashMap.Add(SnapshotChunk.SnapshotBlock.Hash, True);
    for Block in SnapshotChunk.AccountBlocks do
    begin
      FHashMap.Add(Block.Hash, True);
      Addr := Block.AccountAddress;
      if FAccountRange.TryGetValue(Addr, Rng) then
      begin
        Rng[1].Height := Block.Height;
        Rng[1].Hash := Block.Hash;
      end
      else
      begin
        SetLength(Rng, 2);
        Rng[0] := THashHeight.Create(Block.PrevHash, Block.Height - 1);
        Rng[1] := THashHeight.Create(Block.Hash, Block.Height);
        FAccountRange.Add(Addr, Rng);
      end;
    end;
  end;
end;

constructor TChunk.Create(PrevHash: THash; PrevHeight: UInt64; EndHash: THash; EndHeight: UInt64; Source: TBlockSource);
begin
  SetLength(FSnapshotChunks, 1, EndHeight - PrevHeight);
  SetLength(FSnapshotRange, 2);
  FSnapshotRange[0] := THashHeight.Create(PrevHash, PrevHeight);
  FSnapshotRange[1] := THashHeight.Create(EndHash, EndHeight);
  FAccountRange := TDictionary<TAddress, TArray<IHashHeight>>.Create;
  FHashMap := TDictionary<THash, Boolean>.Create;
  FSource := Source;
end;

destructor TChunk.Destroy;
begin
  FAccountRange.Free;
  FHashMap.Free;
  inherited;
end;

function TChunk.GetSnapshotChunks: TArray<ISnapshotChunk>;
begin
  Result := FSnapshotChunks;
end;

function TChunk.GetSnapshotRange: TArray<IHashHeight>;
begin
  Result := FSnapshotRange;
end;

function TChunk.GetAccountRange: TDictionary<TAddress, TArray<IHashHeight>>;
begin
  Result := FAccountRange;
end;

function TChunk.GetHashMap: TDictionary<THash, Boolean>;
begin
  Result := FHashMap;
end;

function TChunk.GetSource: TBlockSource;
begin
  Result := FSource;
end;

function TChunk.GetSize: Int64;
begin
  Result := FSize;
end;

function TChunk.AddSnapshotBlock(Block: ISnapshotBlock): Exception;
var
  PrevHash: THash;
  PrevHeight: UInt64;
  ChunkLength: Integer;
  PrevBlock: ISnapshotBlock;
begin
  Result := nil;
  ChunkLength := Length(FSnapshotChunks);
  if ChunkLength < 2 then
  begin
    PrevHash := FSnapshotRange[0].Hash;
    PrevHeight := FSnapshotRange[0].Height;
  end
  else
  begin
    PrevBlock := FSnapshotChunks[ChunkLength - 2].SnapshotBlock;
    PrevHash := PrevBlock.Hash;
    PrevHeight := PrevBlock.Height;
  end;
  if (not Block.PrevHash.IsEqual(PrevHash)) or (Block.Height <> PrevHeight + 1) then
    Exit(Exception.Create(Format('snapshot blocks not continuous: %s/%d %s/%s/%d', [PrevHash.ToString, PrevHeight, Block.PrevHash.ToString, Block.Hash.ToString, Block.Height])));
  if Block.Height > FSnapshotRange[1].Height then
    Exit(Exception.Create(Format('chunk overflow: %d %d', [FSnapshotRange[1].Height, Block.Height])));
  FSnapshotChunks[ChunkLength - 1].SnapshotBlock := Block;
  if ChunkLength < Cap(FSnapshotChunks) then
    SetLength(FSnapshotChunks, ChunkLength + 1);
  FHashMap.Add(Block.Hash, True);
end;

function TChunk.AddAccountBlock(Block: IAccountBlock): Exception;
var
  Addr: TAddress;
  Rng: TArray<IHashHeight>;
  ChunkLength: Integer;
begin
  Result := nil;
  Addr := Block.AccountAddress;
  if FAccountRange.TryGetValue(Addr, Rng) then
  begin
    if (not Rng[1].Hash.IsEqual(Block.PrevHash)) or (Rng[1].Height + 1 <> Block.Height) then
      Exit(Exception.Create(Format('account blocks not continuous: %s/%d %s/%s/%d', [Rng[1].Hash.ToString, Rng[1].Height, Block.PrevHash.ToString, Block.Hash.ToString, Block.Height])));
    Rng[1].Height := Block.Height;
    Rng[1].Hash := Block.Hash;
  end
  else
  begin
    SetLength(Rng, 2);
    Rng[0] := THashHeight.Create(Block.PrevHash, Block.Height - 1);
    Rng[1] := THashHeight.Create(Block.Hash, Block.Height);
    FAccountRange.Add(Addr, Rng);
  end;
  ChunkLength := Length(FSnapshotChunks);
  FSnapshotChunks[ChunkLength - 1].AccountBlocks := FSnapshotChunks[ChunkLength - 1].AccountBlocks + [Block];
  FHashMap.Add(Block.Hash, True);
end;

function TChunk.Done: Exception;
var
  EndHash: THash;
  EndHeight: UInt64;
  LastChunk: ISnapshotChunk;
  LastBlock: ISnapshotBlock;
  LastHash: THash;
  LastHeight: UInt64;
begin
  Result := nil;
  EndHash := FSnapshotRange[1].Hash;
  EndHeight := FSnapshotRange[1].Height;
  LastChunk := FSnapshotChunks[High(FSnapshotChunks)];
  LastBlock := LastChunk.SnapshotBlock;
  if LastBlock = nil then
    Exit(Exception.Create('missing end snapshot block'));
  LastHash := LastBlock.Hash;
  LastHeight := LastBlock.Height;
  if (not EndHash.IsEqual(LastHash)) or (EndHeight <> LastHeight) then
    Result := Exception.Create(Format('error end: %s/%d %s/%d', [EndHash.ToString, EndHeight, LastHash.ToString, LastHeight]));
end;

end.
