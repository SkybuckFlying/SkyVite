unit Net.Discovery.Table;

interface

uses
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
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table.Test,
  Net.VNode,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.Threading;

const
  BucketSize = 64;
  BucketNum = 32;

type
  TNodeFunc = reference to function(ParaNode: TNode): Boolean;
  TBucketFactory = reference to function(ParaCap: Integer): IBucket;

  INodeCollector = interface
    ['{E5F6A1B2-C3D4-E5F6-A1B2-C3D4E5F6A1B2}']
    procedure Reset;
    function Bubble(ParaId: TVNodeID): Boolean;
    function Add(ParaNode: TNode): TNode;
    function Remove(ParaId: TVNodeID): TNode;
    function Nodes(ParaCount: Integer): TArray<TNode>;
    function Resolve(ParaId: TVNodeID): TNode;
    function Size: Integer;
    procedure Iterate(ParaFn: TNodeFunc);
    function Max: Integer;
  end;

  IBucket = interface(INodeCollector)
    ['{A1B2C3D4-E5F6-A1B2-C3D4-E5F6A1B2C3D4}']
    function Oldest: TNode;
    function Replace(ParaId: TVNodeID; ParaN: TNode): Boolean;
  end;

  ISubscriber = interface
    ['{C3D4E5F6-A1B2-C3D4-E5F6-A1B2C3D4E5F6}']
    function Sub(ParaReceiver: TProc<TVNode>): Integer;
    procedure UnSub(ParaSubId: Integer);
  end;

  INodeStore = interface
    ['{D4E5F6A1-B2C3-D4E5-F6A1-B2C3D4E5F6A1}']
    function StoreNode(ParaNode: TNode): Exception;
  end;

  IPinger = interface
    ['{F6A1B2C3-D4E5-F6A1-B2C3-D4E5F6A1B2C3}']
    procedure Ping(ParaN: TNode; ParaCallback: TProc<Exception>);
  end;

  INodeTable = interface(INodeCollector, ISubscriber)
    ['{B2C3D4E5-F6A1-B2C3-D4E5-F6A1B2C3D4E5}']
    procedure AddNodes(ParaNodes: TArray<TNode>);
    function Oldest: TArray<TNode>;
    function FindNeighbors(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
    function FindSource(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
    procedure Store(ParaDB: INodeStore);
    function ResolveAddr(ParaAddress: string): TNode;
    function SubTreeToFind: Cardinal;
  end;

  TElement = class
  public
    Node: TNode;
    Next: TElement;
    constructor Create(ParaNode: TNode);
  end;

  TListBucket = class(TInterfacedObject, IBucket)
  private
    mHead: TElement;
    mTail: TElement;
    mCap: Integer;
    mCount: Integer;
  public
    constructor Create(ParaMax: Integer);
    destructor Destroy; override;
    procedure Reset;
    function Replace(ParaId: TVNodeID; ParaN: TNode): Boolean;
    function Bubble(ParaId: TVNodeID): Boolean;
    function Add(ParaNode: TNode): TNode;
    function Remove(ParaId: TVNodeID): TNode;
    function Nodes(ParaCount: Integer): TArray<TNode>;
    function Oldest: TNode;
    function Resolve(ParaId: TVNodeID): TNode;
    function Size: Integer;
    procedure Iterate(ParaFn: TNodeFunc);
    function Max: Integer;
  end;

  TNodeTable = class(TInterfacedObject, INodeTable)
  private
    mRw: TMultiReadExclusiveWriteSynchronizer;
    mBucketSize, mBucketNum: Integer;
    mMinDistance: Cardinal;
    mBuckets: TArray<IBucket>;
    mNodeMap: TDictionary<string, TNode>;
    mBucketFact: TBucketFactory;
    mId: TVNodeID;
    mNetId: Integer;
    mSubId: Integer;
    mReceivers: TDictionary<Integer, TProc<TVNode>>;
    mSocket: IPinger;

    function GetBucket(ParaId: TVNodeID): IBucket;
    function RemoveLocked(ParaId: TVNodeID): TNode;
    procedure CheckRemove(ParaNode: TNode);
    procedure CheckReplace(ParaBucket: IBucket; ParaOldNode, ParaNewNode: TNode);
    procedure Notify(ParaN: TVNode);
  public
    constructor Create(ParaId: TVNodeID; ParaNetId: Integer; ParaFact: TBucketFactory; ParaSocket: IPinger);
    destructor Destroy; override;
    procedure Reset;
    function Nodes(ParaCount: Integer): TArray<TNode>;
    function Sub(ParaReceiver: TProc<TVNode>): Integer;
    procedure UnSub(ParaSubId: Integer);
    function Add(ParaNode: TNode): TNode;
    procedure AddNodes(ParaNodes: TArray<TNode>);
    function Remove(ParaId: TVNodeID): TNode;
    function Bubble(ParaId: TVNodeID): Boolean;
    function FindNeighbors(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
    function FindSource(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
    function Oldest: TArray<TNode>;
    function Size: Integer;
    function Resolve(ParaId: TVNodeID): TNode;
    function ResolveAddr(ParaAddress: string): TNode;
    procedure Store(ParaDB: INodeStore);
    procedure Iterate(ParaFn: TNodeFunc);
    function SubTreeToFind: Cardinal;
    function Max: Integer;
  end;

  TCloset = class
  private
    mNodes: TArray<TNode>;
    mPivot: TVNodeID;
  public
    constructor Create(ParaPivot: TVNodeID; ParaCapacity: Integer);
    procedure Push(ParaN: TNode);
    function GetNodes: TArray<TNode>;
  end;

function NewListBucket(ParaMax: Integer): IBucket;
function NewTable(ParaId: TVNodeID; ParaNetId: Integer; ParaFact: TBucketFactory; ParaSocket: IPinger): INodeTable;

implementation

{ TElement }

constructor TElement.Create(ParaNode: TNode);
begin
  Node := ParaNode;
end;

{ TListBucket }

constructor TListBucket.Create(ParaMax: Integer);
begin
  mHead := TElement.Create(nil);
  mTail := mHead;
  mCap := ParaMax;
end;

destructor TListBucket.Destroy;
begin
  Reset;
  mHead.Free;
  inherited;
end;

procedure TListBucket.Reset;
var
  vCurrent, vNext: TElement;
begin
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    vNext := vCurrent.Next;
    vCurrent.Free;
    vCurrent := vNext;
  end;
  mCount := 0;
  mHead.Next := nil;
  mTail := mHead;
end;

function TListBucket.Replace(ParaId: TVNodeID; ParaN: TNode): Boolean;
var
  vCurrent: TElement;
begin
  Result := False;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vCurrent.Node.ID.IsEqual(ParaId) then
    begin
      vCurrent.Node := ParaN;
      Result := True;
      Exit;
    end;
    vCurrent := vCurrent.Next;
  end;
end;

function TListBucket.Bubble(ParaId: TVNodeID): Boolean;
var
  vPrev, vCurrent: TElement;
begin
  Result := False;
  if mCount = 0 then
    Exit;

  if mTail.Node.ID.IsEqual(ParaId) then
  begin
    mTail.Node.activeAt := Round(Now * 86400);
    Result := True;
    Exit;
  end;

  vPrev := mHead;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vCurrent.Node.ID.IsEqual(ParaId) then
    begin
      vPrev.Next := vCurrent.Next;
      vCurrent.Next := nil;
      vCurrent.Node.activeAt := Round(Now * 86400);
      mTail.Next := vCurrent;
      mTail := vCurrent;
      Result := True;
      Exit;
    end;
    vPrev := vCurrent;
    vCurrent := vCurrent.Next;
  end;
end;

function TListBucket.Add(ParaNode: TNode): TNode;
var
  vCurrent: TElement;
begin
  Result := nil;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vCurrent.Node.ID.IsEqual(ParaNode.ID) then
    begin
      Result := vCurrent.Node;
      Exit;
    end;
    vCurrent := vCurrent.Next;
  end;

  if mCount < mCap then
  begin
    ParaNode.addAt := Round(Now * 86400);
    vCurrent := TElement.Create(ParaNode);
    mTail.Next := vCurrent;
    mTail := vCurrent;
    Inc(mCount);
  end
  else
    Result := Oldest;
end;

function TListBucket.Remove(ParaId: TVNodeID): TNode;
var
  vPrev, vCurrent: TElement;
begin
  Result := nil;
  vPrev := mHead;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vCurrent.Node.ID.IsEqual(ParaId) then
    begin
      Result := vCurrent.Node;
      vPrev.Next := vCurrent.Next;
      if mTail = vCurrent then
        mTail := vPrev;
      Dec(mCount);
      vCurrent.Free;
      Exit;
    end;
    vPrev := vCurrent;
    vCurrent := vCurrent.Next;
  end;
end;

function TListBucket.Nodes(ParaCount: Integer): TArray<TNode>;
var
  vStart, vIndex: Integer;
  vCurrent: TElement;
begin
  if (ParaCount = 0) or (mCount < ParaCount) then
  begin
    SetLength(Result, mCount);
    vStart := 0;
  end
  else
  begin
    SetLength(Result, ParaCount);
    vStart := mCount - ParaCount;
  end;

  vIndex := 0;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vIndex >= vStart then
      Result[vIndex - vStart] := vCurrent.Node;
    Inc(vIndex);
    vCurrent := vCurrent.Next;
  end;
end;

function TListBucket.Oldest: TNode;
begin
  if mHead.Next <> nil then
    Result := mHead.Next.Node
  else
    Result := nil;
end;

function TListBucket.Resolve(ParaId: TVNodeID): TNode;
var
  vCurrent: TElement;
begin
  Result := nil;
  vCurrent := mHead.Next;
  while vCurrent <> nil do
  begin
    if vCurrent.Node.ID.IsEqual(ParaId) then
    begin
      Result := vCurrent.Node;
      Exit;
    end;
    vCurrent := vCurrent.Next;
  end;
end;

function TListBucket.Size: Integer;
begin
  Result := mCount;
end;

function TListBucket.Max: Integer;
begin
  Result := mCap;
end;

function NewListBucket(ParaMax: Integer): IBucket;
begin
  Result := TListBucket.Create(ParaMax);
end;

{ TNodeTable }

constructor TNodeTable.Create(ParaId: TVNodeID; ParaNetId: Integer; ParaFact: TBucketFactory; ParaSocket: IPinger);
var
  vIndex: Integer;
begin
  mRw := TMultiReadExclusiveWriteSynchronizer.Create;
  mId := ParaId;
  mNetId := ParaNetId;
  mBucketSize := BucketSize;
  mBucketNum := BucketNum;
  mMinDistance := TVNodeID.IDBits - Cardinal(mBucketNum) + 1;
  SetLength(mBuckets, mBucketNum);
  mNodeMap := TDictionary<string, TNode>.Create;
  mBucketFact := ParaFact;
  mReceivers := TDictionary<Integer, TProc<TVNode>>.Create;
  mSocket := ParaSocket;

  for vIndex := 0 to High(mBuckets) do
    mBuckets[vIndex] := mBucketFact(mBucketSize);
end;

destructor TNodeTable.Destroy;
begin
  mRw.Free;
  mNodeMap.Free;
  mReceivers.Free;
  inherited;
end;

procedure TNodeTable.Reset;
var
  vBkt: IBucket;
begin
  mRw.BeginWrite;
  try
    for vBkt in mBuckets do
      vBkt.Reset;
    mNodeMap.Clear;
  finally
    mRw.EndWrite;
  end;
end;

function TNodeTable.Nodes(ParaCount: Integer): TArray<TNode>;
var
  vNodes: TList<TNode>;
  vPerm: TArray<Integer>;
  vIndex, vIdx: Integer;
  vBkt: IBucket;
  vNs: TArray<TNode>;
begin
  if ParaCount = 0 then
    ParaCount := mBucketNum * mBucketSize;

  vNodes := TList<TNode>.Create;
  try
    mRw.BeginRead;
    try
      SetLength(vPerm, mBucketNum);
      for vIndex := 0 to High(vPerm) do
        vPerm[vIndex] := vIndex;
      // Fisher-Yates shuffle
      for vIndex := High(vPerm) downto 1 do
      begin
        vIdx := Random(vIndex + 1);
        TGenerics.Swap<Integer>(vPerm[vIndex], vPerm[vIdx]);
      end;

      for vIdx in vPerm do
      begin
        vBkt := mBuckets[vIdx];
        vNs := vBkt.Nodes(ParaCount);
        vNodes.AddRange(vNs);
        ParaCount := ParaCount - Length(vNs);
        if ParaCount <= 0 then
          Break;
      end;
    finally
      mRw.EndRead;
    end;
    Result := vNodes.ToArray;
  finally
    vNodes.Free;
  end;
end;

function TNodeTable.Sub(ParaReceiver: TProc<TVNode>): Integer;
begin
  mRw.BeginWrite;
  try
    Result := mSubId;
    Inc(mSubId);
    mReceivers.Add(Result, ParaReceiver);
  finally
    mRw.EndWrite;
  end;
end;

procedure TNodeTable.UnSub(ParaSubId: Integer);
begin
  mRw.BeginWrite;
  try
    mReceivers.Remove(ParaSubId);
  finally
    mRw.EndWrite;
  end;
end;

procedure TNodeTable.Notify(ParaN: TVNode);
var
  vRec: TProc<TVNode>;
begin
  mRw.BeginRead;
  try
    for vRec in mReceivers.Values do
      vRec(ParaN);
  finally
    mRw.EndRead;
  end;
end;

function TNodeTable.Add(ParaNode: TNode): TNode;
var
  vAddr: string;
  vBkt: IBucket;
  vOld: TNode;
begin
  Result := nil;
  if ParaNode.ID.IsEqual(mId) or ParaNode.ID.IsEqual(TVNodeID.ZERO) then
    Exit;

  TThread.CreateAnonymousThread(procedure begin Notify(ParaNode); end).Start;

  vAddr := ParaNode.Address;
  vBkt := GetBucket(ParaNode.ID);

  mRw.BeginRead;
  try
    vOld := vBkt.Resolve(ParaNode.ID);
    if vOld = nil then
      mNodeMap.TryGetValue(vAddr, vOld);
  finally
    mRw.EndRead;
  end;

  if vOld <> nil then
  begin
    if vOld.Equal(ParaNode) then
    begin
      mRw.BeginWrite;
      try
        vBkt.Bubble(ParaNode.ID);
      finally
        mRw.EndWrite;
      end;
      Exit;
    end;

    if vOld.needCheck then
      TThread.CreateAnonymousThread(procedure begin CheckRemove(vOld); end).Start;
    Result := vOld;
    Exit;
  end;

  mRw.BeginWrite;
  try
    Result := vBkt.Add(ParaNode);
    if Result = nil then
      mNodeMap.Add(vAddr, ParaNode)
    else if Result.needCheck then
      TThread.CreateAnonymousThread(procedure begin CheckReplace(vBkt, Result, ParaNode); end).Start;
  finally
    mRw.EndWrite;
  end;
end;

procedure TNodeTable.CheckRemove(ParaNode: TNode);
begin
  mSocket.Ping(ParaNode,
    procedure(ParaErr: Exception)
    begin
      if ParaErr <> nil then
      begin
        Remove(ParaNode.ID);
        // log removal
      end;
    end);
end;

procedure TNodeTable.CheckReplace(ParaBucket: IBucket; ParaOldNode, ParaNewNode: TNode);
begin
  mSocket.Ping(ParaOldNode,
    procedure(ParaErr: Exception)
    begin
      if ParaErr <> nil then
      begin
        mRw.BeginWrite;
        try
          if ParaBucket.Replace(ParaOldNode.ID, ParaNewNode) then
          begin
            mNodeMap.Remove(ParaOldNode.Address);
            mNodeMap.Add(ParaNewNode.Address, ParaNewNode);
          end;
        finally
          mRw.EndWrite;
        end;
        // log replacement
      end;
    end);
end;

procedure TNodeTable.AddNodes(ParaNodes: TArray<TNode>);
var
  vNode: TNode;
begin
  for vNode in ParaNodes do
    Add(vNode);
end;

function TNodeTable.GetBucket(ParaId: TVNodeID): IBucket;
var
  vD: Cardinal;
begin
  vD := TVNodeID.Distance(mId, ParaId);
  if vD < mMinDistance then
    Result := mBuckets[0]
  else
    Result := mBuckets[vD - mMinDistance];
end;

function TNodeTable.Remove(ParaId: TVNodeID): TNode;
begin
  mRw.BeginWrite;
  try
    Result := RemoveLocked(ParaId);
  finally
    mRw.EndWrite;
  end;
end;

function TNodeTable.RemoveLocked(ParaId: TVNodeID): TNode;
var
  vBkt: IBucket;
  vAddr: string;
begin
  vBkt := GetBucket(ParaId);
  Result := vBkt.Remove(ParaId);
  if Result <> nil then
  begin
    vAddr := Result.Address;
    mNodeMap.Remove(vAddr);
  end;
end;

function TNodeTable.Bubble(ParaId: TVNodeID): Boolean;
var
  vBkt: IBucket;
begin
  vBkt := GetBucket(ParaId);
  mRw.BeginWrite;
  try
    Result := vBkt.Bubble(ParaId);
  finally
    mRw.EndWrite;
  end;
end;

function TNodeTable.FindNeighbors(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
var
  vNs: TCloset;
  vBkt: IBucket;
begin
  vNs := TCloset.Create(ParaId, ParaCount);
  try
    mRw.BeginRead;
    try
      for vBkt in mBuckets do
        vBkt.Iterate(
          function(ParaNode: TNode): Boolean
          begin
            if not ParaNode.ID.IsEqual(ParaId) then
              vNs.Push(ParaNode);
            Result := True;
          end);
    finally
      mRw.EndRead;
    end;
    Result := vNs.GetNodes;
  finally
    vNs.Free;
  end;
end;

function TNodeTable.FindSource(ParaId: TVNodeID; ParaCount: Integer): TArray<TNode>;
var
  vNodes: TList<TNode>;
  vBkt: IBucket;
  vExit: Boolean;
begin
  vNodes := TList<TNode>.Create;
  try
    vExit := False;
    mRw.BeginRead;
    try
      for vBkt in mBuckets do
      begin
        vBkt.Iterate(
          function(ParaNode: TNode): Boolean
          begin
            if ParaNode.couldFind then
              vNodes.Add(ParaNode);
            if vNodes.Count > ParaCount then
            begin
              vExit := True;
              Result := False;
            end
            else
              Result := True;
          end);
        if vExit then
          Break;
      end;
    finally
      mRw.EndRead;
    end;
    Result := vNodes.ToArray;
  finally
    vNodes.Free;
  end;
end;

function TNodeTable.Oldest: TArray<TNode>;
var
  vNodes: TList<TNode>;
  vNow: Int64;
  vBkt: IBucket;
  vN: TNode;
begin
  vNodes := TList<TNode>.Create;
  try
    vNow := Round(Now * 86400);
    mRw.BeginRead;
    try
      for vBkt in mBuckets do
      begin
        vN := vBkt.Oldest;
        if (vN <> nil) and ((vNow - vN.activeAt) > CheckExpiration) then
          vNodes.Add(vN);
      end;
    finally
      mRw.EndRead;
    end;
    Result := vNodes.ToArray;
  finally
    vNodes.Free;
  end;
end;

function TNodeTable.Size: Integer;
var
  vCount: Integer;
  vBkt: IBucket;
begin
  vCount := 0;
  mRw.BeginRead;
  try
    for vBkt in mBuckets do
      vCount := vCount + vBkt.Size;
  finally
    mRw.EndRead;
  end;
  Result := vCount;
end;

function TNodeTable.Resolve(ParaId: TVNodeID): TNode;
var
  vBkt: IBucket;
begin
  vBkt := GetBucket(ParaId);
  mRw.BeginRead;
  try
    Result := vBkt.Resolve(ParaId);
  finally
    mRw.EndRead;
  end;
end;

function TNodeTable.ResolveAddr(ParaAddress: string): TNode;
begin
  mRw.BeginRead;
  try
    mNodeMap.TryGetValue(ParaAddress, Result);
  finally
    mRw.EndRead;
  end;
end;

procedure TNodeTable.Store(ParaDB: INodeStore);
var
  vNodes: TArray<TNode>;
  vN: TNode;
  vNow: Int64;
begin
  vNodes := Self.Nodes(0);
  vNow := Round(Now * 86400);
  for vN in vNodes do
    if (vNow - vN.addAt) > StayInTable then
      ParaDB.StoreNode(vN);
end;

procedure TNodeTable.Iterate(ParaFn: TNodeFunc);
var
  vNodes: TArray<TNode>;
  vN: TNode;
begin
  vNodes := Self.Nodes(0);
  for vN in vNodes do
    if not ParaFn(vN) then
      Break;
end;

function TNodeTable.SubTreeToFind: Cardinal;
var
  vPerm: TArray<Integer>;
  vIndex, vI: Integer;
begin
  SetLength(vPerm, Length(mBuckets));
  for vI := 0 to High(vPerm) do
    vPerm[vI] := vI;
  // Fisher-Yates shuffle
  for vI := High(vPerm) downto 1 do
  begin
    vIndex := Random(vI + 1);
    TGenerics.Swap<Integer>(vPerm[vI], vPerm[vIndex]);
  end;

  mRw.BeginRead;
  try
    for vIndex in vPerm do
      if mBuckets[vIndex].Size < (mBucketSize div 2) then
        Exit(Cardinal(vIndex) + mMinDistance);
  finally
    mRw.EndRead;
  end;
  Result := 0;
end;

function TNodeTable.Max: Integer;
begin
  Result := mBucketNum * mBucketSize;
end;

function NewTable(ParaId: TVNodeID; ParaNetId: Integer; ParaFact: TBucketFactory; ParaSocket: IPinger): INodeTable;
begin
  Result := TNodeTable.Create(ParaId, ParaNetId, ParaFact, ParaSocket);
end;

{ TCloset }

constructor TCloset.Create(ParaPivot: TVNodeID; ParaCapacity: Integer);
begin
  mPivot := ParaPivot;
  SetLength(mNodes, 0, ParaCapacity);
end;

procedure TCloset.Push(ParaN: TNode);
var
  vLen, vFurther, vI: Integer;
  vDist: Cardinal;
begin
  if ParaN = nil then
    Exit;

  vLen := Length(mNodes);
  vDist := TVNodeID.Distance(mPivot, ParaN.ID);

  vFurther := vLen;
  for vI := 0 to vLen - 1 do
    if TVNodeID.Distance(mPivot, mNodes[vI].ID) > vDist then
    begin
      vFurther := vI;
      Break;
    end;

  if vLen >= Cap(mNodes) then
  begin
    if vFurther < vLen then
      mNodes[vFurther] := ParaN;
  end
  else
  begin
    SetLength(mNodes, vLen + 1);
    System.Move(mNodes[vFurther], mNodes[vFurther + 1], (vLen - vFurther) * SizeOf(TNode));
    mNodes[vFurther] := ParaN;
  end;
end;

function TCloset.GetNodes: TArray<TNode>;
begin
  Result := mNodes;
end;

end.
