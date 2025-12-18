unit Common.Db.XLevelDB.Cache;

interface

uses
  Common.DB.XLevelDB.Cache.Lru,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  IValue = interface
    ['{F4A3A2D2-8B5D-4C5D-9B5A-3D1B7A6D2C1B}']
  end;

  TNode = class;

  ICacher = interface
    ['{E5A9A86A-287A-4E6D-861E-5A692B4DA20D}']
    function Capacity: integer;
    procedure SetCapacity(capacity: integer);
    procedure Promote(n: TNode);
    procedure Ban(n: TNode);
    procedure Evict(n: TNode);
    procedure EvictNS(ns: uint64);
    procedure EvictAll;
    procedure Close;
  end;

  TSetFunc = reference to function: TPair<integer, IValue>;

  THandle = class
  private
    FNode: TNode;
  public
    constructor Create(ANode: TNode);
    function Value: IValue;
    procedure Release;
  end;

  TNode = class
  private
    FCache: TObject; // TCache, but forward declared
    FHash: uint32;
    FNS, FKey: uint64;
    FSize: integer;
    FValue: IValue;
    FRef: integer;
    FOnDel: TArray<TProc>;
    FCacheData: Pointer;
    procedure Unref;
  public
    constructor Create(ACache: TObject; AHash: uint32; ANS, AKey: uint64);
    function NS: uint64;
    function Key: uint64;
    function Size: integer;
    function Value: IValue;
    function Ref: integer;
    function GetHandle: THandle;
  end;

  TCache = class
  private
    FBuckets: TDictionary<uint32, TList<TNode>>;
    FCriticalSection: TCriticalSection;
    FNodes: integer;
    FSize: integer;
    FCacher: ICacher;
    FClosed: boolean;
    function GetBucket(hash: uint32): TList<TNode>;
    procedure DeleteNode(n: TNode);
  public
    constructor Create(ACacher: ICacher);
    destructor Destroy; override;
    function Nodes: integer;
    function Size: integer;
    function Capacity: integer;
    procedure SetCapacity(capacity: integer);
    function Get(ns, key: uint64; setFunc: TSetFunc): THandle;
    procedure Delete(ns, key: uint64; onDel: TProc);
    procedure Evict(ns, key: uint64);
    procedure EvictNS(ns: uint64);
    procedure EvictAll;
    procedure Close;
    procedure CloseWeak;
  end;

function Murmur32(ns, key: uint64; seed: uint32): uint32;

implementation

uses
  System.Types,
  System.Threading;

function Murmur32(ns, key: uint64; seed: uint32): uint32;
const
  m = $5bd1e995;
  r = 24;
var
  k1, k2, k3, k4, h: uint32;
begin
  k1 := uint32(ns shr 32);
  k2 := uint32(ns);
  k3 := uint32(key shr 32);
  k4 := uint32(key);

  k1 := k1 * m;
  k1 := k1 xor (k1 shr r);
  k1 := k1 * m;

  k2 := k2 * m;
  k2 := k2 xor (k2 shr r);
  k2 := k2 * m;

  k3 := k3 * m;
  k3 := k3 xor (k3 shr r);
  k3 := k3 * m;

  k4 := k4 * m;
  k4 := k4 xor (k4 shr r);
  k4 := k4 * m;

  h := seed;

  h := h * m;
  h := h xor k1;
  h := h * m;
  h := h xor k2;
  h := h * m;
  h := h xor k3;
  h := h * m;
  h := h xor k4;

  h := h xor (h shr 13);
  h := h * m;
  h := h xor (h shr 15);

  Result := h;
end;

{ TNode }

constructor TNode.Create(ACache: TObject; AHash: uint32; ANS, AKey: uint64);
begin
  inherited Create;
  FCache := ACache;
  FHash := AHash;
  FNS := ANS;
  FKey := AKey;
  FRef := 1;
end;

function TNode.NS: uint64;
begin
  Result := FNS;
end;

function TNode.Key: uint64;
begin
  Result := FKey;
end;

function TNode.Size: integer;
begin
  Result := FSize;
end;

function TNode.Value: IValue;
begin
  Result := FValue;
end;

function TNode.Ref: integer;
begin
  Result := TInterlocked.Add(FRef, 0);
end;

function TNode.GetHandle: THandle;
begin
  TInterlocked.Increment(FRef);
  Result := THandle.Create(Self);
end;

procedure TNode.Unref;
begin
  if TInterlocked.Decrement(FRef) = 0 then
    (FCache as TCache).DeleteNode(Self);
end;

{ THandle }

constructor THandle.Create(ANode: TNode);
begin
  inherited Create;
  FNode := ANode;
end;

function THandle.Value: IValue;
begin
  if FNode <> nil then
    Result := FNode.Value
  else
    Result := nil;
end;

procedure THandle.Release;
var
  node: TNode;
begin
  node := TInterlocked.Exchange(FNode, nil);
  if node <> nil then
    node.Unref;
end;

{ TCache }

constructor TCache.Create(ACacher: ICacher);
begin
  inherited Create;
  FBuckets := TDictionary<uint32, TList<TNode>>.Create;
  FCriticalSection := TCriticalSection.Create;
  FCacher := ACacher;
end;

destructor TCache.Destroy;
begin
  Close;
  FBuckets.Free;
  FCriticalSection.Free;
  inherited;
end;

function TCache.GetBucket(hash: uint32): TList<TNode>;
begin
  FCriticalSection.Enter;
  try
    if not FBuckets.TryGetValue(hash, Result) then
    begin
      Result := TList<TNode>.Create;
      FBuckets.Add(hash, Result);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TCache.DeleteNode(n: TNode);
var
  bucket: TList<TNode>;
  i: integer;
begin
  FCriticalSection.Enter;
  try
    if FBuckets.TryGetValue(n.FHash, bucket) then
    begin
      i := bucket.IndexOf(n);
      if i >= 0 then
      begin
        bucket.Delete(i);
        TInterlocked.Decrement(FNodes);
        TInterlocked.Add(FSize, -n.FSize);
        // Call OnDel
        for var proc in n.FOnDel do
          proc();
        n.Free;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TCache.Nodes: integer;
begin
  Result := TInterlocked.Add(FNodes, 0);
end;

function TCache.Size: integer;
begin
  Result := TInterlocked.Add(FSize, 0);
end;

function TCache.Capacity: integer;
begin
  if FCacher <> nil then
    Result := FCacher.Capacity
  else
    Result := 0;
end;

procedure TCache.SetCapacity(capacity: integer);
begin
  if FCacher <> nil then
    FCacher.SetCapacity(capacity);
end;

function TCache.Get(ns, key: uint64; setFunc: TSetFunc): THandle;
var
  hash: uint32;
  bucket: TList<TNode>;
  node: TNode;
  pair: TPair<integer, IValue>;
begin
  Result := nil;
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    hash := Murmur32(ns, key, $F00);
    bucket := GetBucket(hash);
    for node in bucket do
    begin
      if (node.FNS = ns) and (node.FKey = key) then
      begin
        TInterlocked.Increment(node.FRef);
        Result := THandle.Create(node);
        Exit;
      end;
    end;

    if setFunc <> nil then
    begin
      node := TNode.Create(Self, hash, ns, key);
      pair := setFunc();
      node.FSize := pair.Key;
      node.FValue := pair.Value;
      if node.FValue <> nil then
      begin
        bucket.Add(node);
        TInterlocked.Increment(FNodes);
        TInterlocked.Add(FSize, node.FSize);
        if FCacher <> nil then
          FCacher.Promote(node);
        Result := THandle.Create(node);
      end
      else
        node.Free;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TCache.Delete(ns, key: uint64; onDel: TProc);
var
  hash: uint32;
  bucket: TList<TNode>;
  node: TNode;
  found: boolean;
begin
  found := false;
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    hash := Murmur32(ns, key, $F00);
    bucket := GetBucket(hash);
    for node in bucket do
    begin
      if (node.FNS = ns) and (node.FKey = key) then
      begin
        if onDel <> nil then
          node.FOnDel := node.FOnDel + [onDel];
        if FCacher <> nil then
          FCacher.Ban(node);
        node.Unref;
        found := true;
        break;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
  if not found and (onDel <> nil) then
    onDel();
end;

procedure TCache.Evict(ns, key: uint64);
var
  hash: uint32;
  bucket: TList<TNode>;
  node: TNode;
begin
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    hash := Murmur32(ns, key, $F00);
    bucket := GetBucket(hash);
    for node in bucket do
    begin
      if (node.FNS = ns) and (node.FKey = key) then
      begin
        if FCacher <> nil then
          FCacher.Evict(node);
        break;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TCache.EvictNS(ns: uint64);
begin
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    if FCacher <> nil then
      FCacher.EvictNS(ns);
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TCache.EvictAll;
begin
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    if FCacher <> nil then
      FCacher.EvictAll;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TCache.Close;
var
  bucket: TList<TNode>;
  node: TNode;
begin
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    FClosed := true;
    for bucket in FBuckets.Values do
    begin
      for node in bucket do
      begin
        // Call OnDel
        for var proc in node.FOnDel do
          proc();
        node.FOnDelfree;
      end;
      bucket.Clear;
    end;
    FBuckets.Clear;
  finally
    FCriticalSection.Leave;
  end;
  if FCacher <> nil then
    FCacher.Close;
end;

procedure TCache.CloseWeak;
begin
  FCriticalSection.Enter;
  try
    if FClosed then
      Exit;
    FClosed := true;
  finally
    FCriticalSection.Leave;
  end;
  if FCacher <> nil then
  begin
    FCacher.EvictAll;
    FCacher.Close;
  end;
end;

end.
