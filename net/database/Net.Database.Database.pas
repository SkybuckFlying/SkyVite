unit net.database.database;

interface

uses
  common.bytes net.vnode,
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
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.SysUtils System.Classes System.Generics.Collections System.Net.Sockets;

type
  // ILevelDB is a placeholder interface for LevelDB operations.
  // In a real scenario, this would be replaced by a Delphi binding to LevelDB
  // or an equivalent embedded database library.
  ILevelDB = interface
    ['{YOUR_GUID_HERE}']
    function Get(const Key: TBytes): TBytes;
    procedure Put(const Key, Value: TBytes);
    procedure Delete(const Key: TBytes);
    function NewIterator(const Prefix: TBytes): ILevelDBIterator;
    procedure Close;
  end;

  ILevelDBIterator = interface
    ['{YOUR_GUID_HERE}']
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    procedure Release;
  end;

  TDB = class
  private
    FLevelDB: ILevelDB;
    FId: TVNodeID;
  public
    constructor Create(ALevelDB: ILevelDB; AId: TVNodeID);
    destructor Destroy; override;

    function RetrieveActiveAt(Id: TVNodeID): Int64;
    procedure StoreActiveAt(Id: TVNodeID; V: Int64);
    function RetrieveCheckAt(Id: TVNodeID): Int64;
    procedure StoreCheckAt(Id: TVNodeID; V: Int64);
    function RetrieveMark(Id: TVNodeID): Int64;
    procedure StoreMark(Id: TVNodeID; V: Int64);
    procedure BlockIP(IP: TBytes; Expiration: Int64);
    procedure BlockId(Id: TVNodeID; Expiration: Int64);
    function RetrieveNode(Id: TVNodeID): TVNode;
    function StoreNode(Node: TVNode): Exception;
    procedure RemoveNode(Id: TVNodeID);
    function ReadNodes(Expiration: Int64): TArray<TVNode>;
    function RetrieveInt64(const Key: TBytes): Int64;
    procedure StoreInt64(const Key: TBytes; N: Int64);
    procedure Clean(Expiration: Int64);
    procedure Iterate(const Prefix: TBytes; Fn: TIterateCallback);
    function Register(const Prefix: TBytes): IPrefixDB;
  end;

  IPrefixDB = interface
    ['{YOUR_GUID_HERE}']
    function Store(const Key, Value: TBytes): Exception;
    function Retrieve(const Key: TBytes): TBytes;
    procedure Remove(const Key: TBytes);
  end;

  TPrefixDB = class(TInterfacedObject, IPrefixDB)
  private
    FDB: ILevelDB;
    FPrefix: TBytes;
  public
    constructor Create(ADB: ILevelDB; const APrefix: TBytes);
    function Store(const Key, Value: TBytes): Exception;
    function Retrieve(const Key: TBytes): TBytes;
    procedure Remove(const Key: TBytes);
  end;

  TIterateCallback = reference to function(Key, Value: TBytes): Boolean;

function NewDB(Path: string; Version: Integer; Id: TVNodeID): TDB;
function DecodeVarint(const Varint: TBytes): Int64;
function EncodeVarint(I: Int64): TBytes;

implementation

uses
  System.IOUtils, System.DateUtils;

const
  VersionKey: TBytes = [ord('v'), ord('e'), ord('r'), ord('s'), ord('i'), ord('o'), ord('n')];

  NodeDataPrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('d'), ord('a'), ord('t'), ord('a'), ord(':')];
  NodeActivePrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('a'), ord('c'), ord('t'), ord('i'), ord('v'), ord('e'), ord(':')];
  NodeCheckPrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('c'), ord('h'), ord('e'), ord('c'), ord('k'), ord(':')];
  NodeMarkPrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('m'), ord('a'), ord('r'), ord('k'), ord(':')];

  NodeBlockIPPrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('b'), ord('l'), ord('o'), ord('c'), ord('k'), ord(':'), ord('i'), ord('p'), ord(':')];
  NodeBlockIDPrefix: TBytes = [ord('n'), ord('o'), ord('d'), ord('e'), ord(':'), ord('b'), ord('l'), ord('o'), ord('c'), ord('k'), ord('i'), ord('d'), ord(':')];

// Dummy implementation for ILevelDB for compilation. Replace with actual LevelDB binding.
type
  TDummyLevelDB = class(TInterfacedObject, ILevelDB)
  private
    FData: TDictionary<TBytes, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    function Get(const Key: TBytes): TBytes;
    procedure Put(const Key, Value: TBytes);
    procedure Delete(const Key: TBytes);
    function NewIterator(const Prefix: TBytes): ILevelDBIterator;
    procedure Close;
  end;

  TDummyLevelDBIterator = class(TInterfacedObject, ILevelDBIterator)
  private
    FData: TList<TPair<TBytes, TBytes>>;
    FCurrentIndex: Integer;
    FPrefix: TBytes;
  public
    constructor Create(const AData: TDictionary<TBytes, TBytes>; const APrefix: TBytes);
    destructor Destroy; override;
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    procedure Release;
  end;

{ TDummyLevelDB }

constructor TDummyLevelDB.Create;
begin
  FData := TDictionary<TBytes, TBytes>.Create(TBytesComparer.Default);
end;

destructor TDummyLevelDB.Destroy;
begin
  FData.Free;
  inherited;
end;

function TDummyLevelDB.Get(const Key: TBytes): TBytes;
begin
  if FData.ContainsKey(Key) then
    Result := FData[Key]
  else
    Result := nil;
end;

procedure TDummyLevelDB.Put(const Key, Value: TBytes);
begin
  FData.AddOrSetValue(Key, Value);
end;

procedure TDummyLevelDB.Delete(const Key: TBytes);
begin
  FData.Remove(Key);
end;

function TDummyLevelDB.NewIterator(const Prefix: TBytes): ILevelDBIterator;
begin
  Result := TDummyLevelDBIterator.Create(FData, Prefix);
end;

procedure TDummyLevelDB.Close;
begin
  // Dummy close
end;

{ TDummyLevelDBIterator }

constructor TDummyLevelDBIterator.Create(const AData: TDictionary<TBytes, TBytes>; const APrefix: TBytes);
var
  Pair: TPair<TBytes, TBytes>;
begin
  FData := TList<TPair<TBytes, TBytes>>.Create;
  FPrefix := APrefix;
  for Pair in AData do
  begin
    if TBytes.StartsWith(Pair.Key, FPrefix) then
      FData.Add(Pair);
  end;
  FData.Sort(TComparer<TPair<TBytes, TBytes>>.Construct(function(const L, R: TPair<TBytes, TBytes>): Integer
  begin
    Result := TBytes.Compare(L.Key, R.Key);
  end));
  FCurrentIndex := -1;
end;

destructor TDummyLevelDBIterator.Destroy;
begin
  FData.Free;
  inherited;
end;

function TDummyLevelDBIterator.Next: Boolean;
begin
  Inc(FCurrentIndex);
  Result := FCurrentIndex < FData.Count;
end;

function TDummyLevelDBIterator.Key: TBytes;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < FData.Count) then
    Result := FData[FCurrentIndex].Key
  else
    Result := nil;
end;

function TDummyLevelDBIterator.Value: TBytes;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < FData.Count) then
    Result := FData[FCurrentIndex].Value
  else
    Result := nil;
end;

procedure TDummyLevelDBIterator.Release;
begin
  // Dummy release
end;

{ TDB }

constructor TDB.Create(ALevelDB: ILevelDB; AId: TVNodeID);
begin
  FLevelDB := ALevelDB;
  FId := AId;
end;

destructor TDB.Destroy;
begin
  FLevelDB.Close;
  inherited;
end;

function NewDB(Path: string; Version: Integer; Id: TVNodeID): TDB;
var
  LDB: ILevelDB;
  VBytes, OldVBytes: TBytes;
  Err: Exception;
begin
  if Path = '' then
  begin
    LDB := TDummyLevelDB.Create; // Use dummy for in-memory
  end
  else
  begin
    // In a real scenario, you would open/recover LevelDB here.
    // For now, we'll use the dummy and simulate file operations.
    LDB := TDummyLevelDB.Create;
    if TDirectory.Exists(Path) then
    begin
      // Simulate recovery/corruption check
      // If corrupted, TDirectory.Delete(Path, True) and re-create
    end;
  end;

  VBytes := EncodeVarint(Version);
  OldVBytes := LDB.Get(VersionKey);

  if OldVBytes = nil then // ErrNotFound
  begin
    LDB.Put(VersionKey, VBytes);
  end
  else
  begin
    if not TBytes.Equals(OldVBytes, VBytes) then
    begin
      LDB.Close;
      if TDirectory.Exists(Path) then
        TDirectory.Delete(Path, True);
      Result := NewDB(Path, Version, Id); // Recursive call to re-create
      Exit;
    end;
  end;

  Result := TDB.Create(LDB, Id);
end;

function DecodeVarint(const Varint: TBytes): Int64;
var
  I, N: Integer;
begin
  Result := 0;
  if Length(Varint) = 0 then
    Exit;

  // This is a simplified varint decoding. Go's binary.Varint handles signed integers.
  // For a full conversion, you might need a more robust varint implementation.
  N := 0;
  for I := 0 to Length(Varint) - 1 do
  begin
    Result := Result or (Int64(Varint[I]) shl N);
    Inc(N, 8);
  end;
end;

function EncodeVarint(I: Int64): TBytes;
var
  Data: TBytes;
  N: Integer;
begin
  SetLength(Data, 8); // MaxVarintLen64
  N := 0;
  // Simplified encoding. Go's binary.PutVarint handles signed integers.
  // For a full conversion, you might need a more robust varint implementation.
  if I = 0 then
  begin
    Result := [];
    Exit;
  end;

  while I > 0 do
  begin
    Data[N] := Byte(I and $FF);
    I := I shr 8;
    Inc(N);
  end;
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := Data[N - 1 - I]; // Reverse for big-endian like behavior
end;

function TDB.RetrieveActiveAt(Id: TVNodeID): Int64;
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeActivePrefix, Id.Bytes);
  Result := RetrieveInt64(Key);
end;

procedure TDB.StoreActiveAt(Id: TVNodeID; V: Int64);
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeActivePrefix, Id.Bytes);
  StoreInt64(Key, V);
end;

function TDB.RetrieveCheckAt(Id: TVNodeID): Int64;
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeCheckPrefix, Id.Bytes);
  Result := RetrieveInt64(Key);
end;

procedure TDB.StoreCheckAt(Id: TVNodeID; V: Int64);
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeCheckPrefix, Id.Bytes);
  StoreInt64(Key, V);
end;

function TDB.RetrieveMark(Id: TVNodeID): Int64;
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeMarkPrefix, Id.Bytes);
  Result := RetrieveInt64(Key);
end;

procedure TDB.StoreMark(Id: TVNodeID; V: Int64);
var
  Key: TBytes;
  Value: TBytes;
  Now: Int64;
begin
  Key := TBytes.Concat(NodeMarkPrefix, Id.Bytes);
  SetLength(Value, 16);
  Now := DateTimeToUnix(Now);
  // Assuming BigEndian for PutUint64
  Move(V, Value[0], 8);
  Move(Now, Value[8], 8);
  FLevelDB.Put(Key, Value);
end;

procedure TDB.BlockIP(IP: TBytes; Expiration: Int64);
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeBlockIPPrefix, IP);
  StoreInt64(Key, Expiration);
end;

procedure TDB.BlockId(Id: TVNodeID; Expiration: Int64);
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeBlockIDPrefix, Id.Bytes);
  StoreInt64(Key, Expiration);
end;

function TDB.RetrieveNode(Id: TVNodeID): TVNode;
var
  Key, Data: TBytes;
begin
  Key := TBytes.Concat(NodeDataPrefix, Id.Bytes);
  Data := FLevelDB.Get(Key);
  if Data = nil then
    raise Exception.Create('Node not found'); // Or return nil and handle error outside

  Result := TVNode.Create;
  Result.Deserialize(Data);
end;

function TDB.StoreNode(Node: TVNode): Exception;
var
  Data, Key: TBytes;
begin
  Result := nil;
  try
    Data := Node.Serialize;
    Key := TBytes.Concat(NodeDataPrefix, Node.ID.Bytes);
    FLevelDB.Put(Key, Data);
  except
    on E: Exception do
      Result := E;
  end;
end;

procedure TDB.RemoveNode(Id: TVNodeID);
var
  Key: TBytes;
begin
  Key := TBytes.Concat(NodeDataPrefix, Id.Bytes);
  FLevelDB.Delete(Key);

  Key := TBytes.Concat(NodeActivePrefix, Id.Bytes);
  FLevelDB.Delete(Key);

  Key := TBytes.Concat(NodeCheckPrefix, Id.Bytes);
  FLevelDB.Delete(Key);

  Key := TBytes.Concat(NodeMarkPrefix, Id.Bytes);
  FLevelDB.Delete(Key);
end;

function TDB.ReadNodes(Expiration: Int64): TArray<TVNode>;
var
  Itr: ILevelDBIterator;
  Now: Int64;
  PrefixLen: Integer;
  Key: TBytes;
  Id: TVNodeID;
  Active: Int64;
  Node: TVNode;
begin
  SetLength(Result, 0);
  Itr := FLevelDB.NewIterator(NodeActivePrefix);
  try
    Now := DateTimeToUnix(Now);
    PrefixLen := Length(NodeActivePrefix);

    while Itr.Next do
    begin
      Key := Itr.Key;
      Id := TVNodeID.FromBytes(Copy(Key, PrefixLen, Length(Key) - PrefixLen));

      Active := DecodeVarint(Itr.Value);
      if Now - Active > Expiration then
      begin
        RemoveNode(Id);
        Continue;
      end;

      try
        Node := RetrieveNode(Id);
        Result := Result + [Node];
      except
        on E: Exception do
        begin
          RemoveNode(Id);
          Continue;
        end;
      end;
    end;
  finally
    Itr.Release;
  end;
end;

function TDB.RetrieveInt64(const Key: TBytes): Int64;
var
  Buf: TBytes;
begin
  Buf := FLevelDB.Get(Key);
  if Buf = nil then
    Result := 0
  else
    Result := DecodeVarint(Buf);
end;

procedure TDB.StoreInt64(const Key: TBytes; N: Int64);
var
  Buf: TBytes;
begin
  Buf := EncodeVarint(N);
  FLevelDB.Put(Key, Buf);
end;

procedure TDB.Clean(Expiration: Int64);
var
  Itr: ILevelDBIterator;
  Now: Int64;
  PrefixLen: Integer;
  Key: TBytes;
  Id: TVNodeID;
  Active: Int64;
begin
  Itr := FLevelDB.NewIterator(NodeActivePrefix);
  try
    Now := DateTimeToUnix(Now);
    PrefixLen := Length(NodeActivePrefix);

    while Itr.Next do
    begin
      Key := Itr.Key;
      Id := TVNodeID.FromBytes(Copy(Key, PrefixLen, Length(Key) - PrefixLen));

      Active := DecodeVarint(Itr.Value);
      if Now - Active > Expiration then
      begin
        RemoveNode(Id);
        Continue;
      end;
    end;
  finally
    Itr.Release;
  end;
end;

type
  TMark = record
    Id: TVNodeID;
    Weight: Int64;
  end;

  TMarks = TList<TMark>;

function TDB.ReadMarkNodes(N: Integer): TArray<TVNode>;
var
  Itr: ILevelDBIterator;
  Ms: TMarks;
  PrefixLen: Integer;
  Now: Int64;
  Key: TBytes;
  Id: TVNodeID;
  Data: TBytes;
  MarkValue, MarkAt: Int64;
  M: TMark;
  Node: TVNode;
begin
  SetLength(Result, 0);
  Itr := FLevelDB.NewIterator(NodeMarkPrefix);
  try
    Ms := TMarks.Create;
    try
      PrefixLen := Length(NodeMarkPrefix);
      Now := DateTimeToUnix(Now);

      while Itr.Next do
      begin
        Key := Itr.Key;
        Id := TVNodeID.FromBytes(Copy(Key, PrefixLen, Length(Key) - PrefixLen));

        Data := Itr.Value;
        if Length(Data) < 16 then
        begin
          FLevelDB.Delete(Key);
          Continue;
        end;

        // Assuming BigEndian for Uint64
        Move(Data[0], MarkValue, 8);
        Move(Data[8], MarkAt, 8);

        // 7 days expiration
        if Now - MarkAt > 24 * 3600 * 7 then
        begin
          FLevelDB.Delete(Key);
          Continue;
        end;

        Ms.Add(TMark.Create(Id, MarkValue));
      end;

      Ms.Sort(TComparer<TMark>.Construct(function(const L, R: TMark): Integer
      begin
        Result := -CompareValue(L.Weight, R.Weight); // Descending sort
      end));

      if Ms.Count > N then
        Ms.DeleteRange(N, Ms.Count - N);

      for M in Ms do
      begin
        try
          Node := RetrieveNode(M.Id);
          Result := Result + [Node];
        except
          on E: Exception do
          begin
            RemoveNode(M.Id);
            Continue;
          end;
        end;
      end;
    finally
      Ms.Free;
    end;
  finally
    Itr.Release;
  end;
end;

procedure TDB.Iterate(const Prefix: TBytes; Fn: TIterateCallback);
var
  Itr: ILevelDBIterator;
begin
  Itr := FLevelDB.NewIterator(Prefix);
  try
    while Itr.Next do
    begin
      if not Fn(Itr.Key, Itr.Value) then
        Break;
    end;
  finally
    Itr.Release;
  end;
end;

function TDB.Register(const Prefix: TBytes): IPrefixDB;
begin
  Result := TPrefixDB.Create(FLevelDB, Prefix);
end;

{ TPrefixDB }

constructor TPrefixDB.Create(ADB: ILevelDB; const APrefix: TBytes);
begin
  FDB := ADB;
  FPrefix := APrefix;
end;

function TPrefixDB.Store(const Key, Value: TBytes): Exception;
var
  FullKey: TBytes;
begin
  Result := nil;
  try
    FullKey := TBytes.Concat(FPrefix, Key);
    FDB.Put(FullKey, Value);
  except
    on E: Exception do
      Result := E;
  end;
end;

function TPrefixDB.Retrieve(const Key: TBytes): TBytes;
var
  FullKey: TBytes;
begin
  FullKey := TBytes.Concat(FPrefix, Key);
  Result := FDB.Get(FullKey);
end;

procedure TPrefixDB.Remove(const Key: TBytes);
var
  FullKey: TBytes;
begin
  FullKey := TBytes.Concat(FPrefix, Key);
  FDB.Delete(FullKey);
end;

end.
