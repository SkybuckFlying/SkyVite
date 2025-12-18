unit common.db.xleveldb.cache.lru;

interface

uses
  Common.DB.XLevelDB.Cache.Cache,
  common.db.xleveldb.cache.cache // For TNode THandle ICacher,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  TLruNode = class
  public
    N: TNode;
    H: THandle;
    Ban: Boolean;

    Next, Prev: TLruNode;

    procedure Insert(At: TLruNode);
    procedure Remove;
  end;

type
  TLru = class(TInterfacedObject, ICacher)
  private
    FMu: TCriticalSection;
    FCapacity: Integer;
    FUsed: Integer;
    FRecent: TLruNode;
    procedure Reset;
  public
    constructor Create(Capacity: Integer);
    destructor Destroy; override;
    function Capacity: Integer;
    procedure SetCapacity(Capacity: Integer);
    procedure Promote(N: TNode);
    procedure Ban(N: TNode);
    procedure Evict(N: TNode);
    procedure EvictNS(NS: UInt64);
    procedure EvictAll;
    function Close: Exception;
  end;

function NewLRU(Capacity: Integer): ICacher;

implementation

{ TLruNode }

procedure TLruNode.Insert(At: TLruNode);
begin
  Self.Next := At.Next;
  Self.Prev := At;
  At.Next.Prev := Self;
  At.Next := Self;
end;

procedure TLruNode.Remove;
begin
  if Self.Prev = nil then
    raise Exception.Create('BUG: removing removed node');
  Self.Prev.Next := Self.Next;
  Self.Next.Prev := Self.Prev;
  Self.Prev := nil;
  Self.Next := nil;
end;

{ TLru }

constructor TLru.Create(Capacity: Integer);
begin
  FMu := TCriticalSection.Create;
  FCapacity := Capacity;
  FRecent := TLruNode.Create; // Sentinel node
  Reset;
end;

destructor TLru.Destroy;
var
  RN: TLruNode;
begin
  FMu.Acquire;
  try
    // Release all handles and free all lruNodes
    RN := FRecent.Next;
    while RN <> FRecent do
    begin
      RN.H.Release;
      RN.N.CacheData := nil; // Clear CacheData pointer
      var TempRN := RN;
      RN := RN.Next;
      TempRN.Free;
    end;
    FRecent.Free; // Free the sentinel node
  finally
    FMu.Release;
  end;
  FMu.Free;
  inherited;
end;

procedure TLru.Reset;
begin
  FRecent.Next := FRecent;
  FRecent.Prev := FRecent;
  FUsed := 0;
end;

function TLru.Capacity: Integer;
begin
  FMu.Acquire;
  try
    Result := FCapacity;
  finally
    FMu.Release;
  end;
end;

procedure TLru.SetCapacity(Capacity: Integer);
var
  Evicted: TList<TLruNode>;
  RN: TLruNode;
begin
  Evicted := TList<TLruNode>.Create;
  try
    FMu.Acquire;
    try
      FCapacity := Capacity;
      while FUsed > FCapacity do
      begin
        RN := FRecent.Prev;
        if RN = nil then
          raise Exception.Create('BUG: invalid LRU used or capacity counter');
        RN.Remove;
        RN.N.CacheData := nil;
        FUsed := FUsed - RN.N.Size;
        Evicted.Add(RN);
      end;
    finally
      FMu.Release;
    end;

    for RN in Evicted do
      RN.H.Release;
  finally
    Evicted.Free;
  end;
end;

procedure TLru.Promote(N: TNode);
var
  Evicted: TList<TLruNode>;
  RN: TLruNode;
begin
  Evicted := TList<TLruNode>.Create;
  try
    FMu.Acquire;
    try
      if N.CacheData = nil then
      begin
        if N.Size <= FCapacity then
        begin
          RN := TLruNode.Create;
          RN.N := N;
          RN.H := N.GetHandle;
          RN.Insert(FRecent);
          N.CacheData := Pointer(RN);
          FUsed := FUsed + N.Size;

          while FUsed > FCapacity do
          begin
            RN := FRecent.Prev;
            if RN = nil then
              raise Exception.Create('BUG: invalid LRU used or capacity counter');
            RN.Remove;
            RN.N.CacheData := nil;
            FUsed := FUsed - RN.N.Size;
            Evicted.Add(RN);
          end;
        end;
      end
      else
      begin
        RN := TLruNode(N.CacheData);
        if not RN.Ban then
        begin
          RN.Remove;
          RN.Insert(FRecent);
        end;
      end;
    finally
      FMu.Release;
    end;

    for RN in Evicted do
      RN.H.Release;
  finally
    Evicted.Free;
  end;
end;

procedure TLru.Ban(N: TNode);
var
  RN: TLruNode;
begin
  FMu.Acquire;
  try
    if N.CacheData = nil then
    begin
      RN := TLruNode.Create;
      RN.N := N;
      RN.Ban := True;
      N.CacheData := Pointer(RN);
    end
    else
    begin
      RN := TLruNode(N.CacheData);
      if not RN.Ban then
      begin
        RN.Remove;
        RN.Ban := True;
        FUsed := FUsed - RN.N.Size;
        FMu.Release; // Release mutex before releasing handle to avoid deadlock

        RN.H.Release;
        RN.H := nil;
        Exit; // Exit after releasing mutex
      end;
    end;
  finally
    FMu.Release;
  end;
end;

procedure TLru.Evict(N: TNode);
var
  RN: TLruNode;
begin
  FMu.Acquire;
  try
    RN := TLruNode(N.CacheData);
    if (RN = nil) or RN.Ban then
      Exit;
    N.CacheData := nil;
  finally
    FMu.Release;
  end;

  RN.H.Release;
end;

procedure TLru.EvictNS(NS: UInt64);
var
  Evicted: TList<TLruNode>;
  E: TLruNode;
  RN: TLruNode;
begin
  Evicted := TList<TLruNode>.Create;
  try
    FMu.Acquire;
    try
      E := FRecent.Prev;
      while E <> FRecent do
      begin
        RN := E;
        E := E.Prev;
        if RN.N.NS = NS then
        begin
          RN.Remove;
          RN.N.CacheData := nil;
          FUsed := FUsed - RN.N.Size;
          Evicted.Add(RN);
        end;
      end;
    finally
      FMu.Release;
    end;

    for RN in Evicted do
      RN.H.Release;
  finally
    Evicted.Free;
  end;
end;

procedure TLru.EvictAll;
var
  Back: TLruNode;
  RN: TLruNode;
begin
  FMu.Acquire;
  try
    Back := FRecent.Prev;
    RN := Back;
    while RN <> FRecent do
    begin
      RN.N.CacheData := nil;
      RN := RN.Prev;
    end;
    Reset;
  finally
    FMu.Release;
  end;

  RN := Back;
  while RN <> FRecent do
  begin
    RN.H.Release;
    RN := RN.Prev;
  end;
end;

function TLru.Close: Exception;
begin
  Result := nil; // Go implementation returns nil, so no error
end;

function NewLRU(Capacity: Integer): ICacher;
begin
  Result := TLru.Create(Capacity);
end;

end.
