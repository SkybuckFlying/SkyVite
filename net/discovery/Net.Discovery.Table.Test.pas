unit Net.Discovery.Table.Test;

interface

uses
  DUnitX.TestFramework,
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
  Net.Discovery.Table,
  Net.VNode,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading;

type
  TMockPinger = class(TInterfacedObject, IPinger)
  private
    mFail: Boolean;
  public
    constructor Create(ParaFail: Boolean);
    procedure Ping(ParaN: TNode; ParaCallback: TProc<Exception>);
  end;

  [TestFixture]
  TTableTest = class(TObject)
  private
    FSelfNode: TVNode;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [Ignore('Skipped in Go and non-functional')]
    procedure TestTable_Add;
    [Test]
    procedure TestTable_Add2;
    [Test]
    [Ignore('Skipped in Go and non-functional')]
    procedure TestTable_Add3;
    [Test]
    [Ignore('Skipped in Go and non-functional')]
    procedure TestTable_Nodes;
    [Test]
    procedure TestTable_GetBucket;
    [Test]
    procedure TestCloset;
  end;

implementation

{ TMockPinger }

constructor TMockPinger.Create(ParaFail: Boolean);
begin
  mFail := ParaFail;
end;

procedure TMockPinger.Ping(ParaN: TNode; ParaCallback: TProc<Exception>);
begin
  if mFail then
    ParaCallback(Exception.Create('mock error'))
  else
    ParaCallback(nil);
end;

{ TTableTest }

procedure TTableTest.Setup;
begin
  FSelfNode := TVNode.MockNode(False, True);
end;

procedure TTableTest.TearDown;
begin
  FSelfNode.Free;
end;

procedure TTableTest.TestTable_Add;
var
  vMp: IPinger;
  vTab: INodeTable;
  vNode, vToCheck: TNode;
  vIndex: Integer;
  vOldest: TArray<TNode>;
begin
  vMp := TMockPinger.Create(False);
  vTab := NewTable(TVNodeID.ZERO, FSelfNode.Net, NewListBucket, vMp);

  for vIndex := 0 to BucketSize - 1 do
  begin
    vNode := TNode.Create;
    vNode.ID := TVNodeID.RandFromDistance(vTab.GetID, 100);
    vNode.EndPoint.Host := TBytes.Create(0, 0, 0, 0);
    vNode.EndPoint.Port := vIndex;
    vNode.EndPoint.Typ := THostIPv4.Create;
    vNode.Net := FSelfNode.Net;
    vToCheck := vTab.Add(vNode);
    Assert.IsNull(vToCheck, 'should not return toCheck');
  end;

  vNode := TNode.Create;
  vNode.ID := TVNodeID.RandFromDistance(vTab.GetID, 100);
  vNode.EndPoint.Host := TBytes.Create(0, 0, 0, 0);
  vNode.EndPoint.Port := 33;
  vNode.EndPoint.Typ := THostIPv4.Create;
  vNode.Net := FSelfNode.Net;

  Assert.IsNotNull(vTab.Add(vNode), 'should return the oldest node to check');
  TThread.Sleep(100);

  vOldest := vTab.Oldest;
  Assert.AreEqual(0, vOldest[0].EndPoint.Port, 'oldest node should be the first node');

  (vMp as TMockPinger).mFail := True;
  vToCheck := vTab.Add(vNode);
  Assert.IsNotNull(vToCheck, 'should return the oldest node to check');

  TThread.Sleep(100);
  vOldest := vTab.Oldest;
  Assert.AreEqual(vNode.EndPoint.Port, vOldest[0].EndPoint.Port, 'oldest node should be the new node');
end;

procedure TTableTest.TestTable_Add2;
var
  vMp: IPinger;
  vTab: INodeTable;
  vNode: TNode;
  vId: TVNodeID;
  vNodes: TArray<TNode>;
begin
  vMp := TMockPinger.Create(False);
  vTab := NewTable(TVNodeID.ZERO, FSelfNode.Net, NewListBucket, vMp);

  vNode := TNode.Create;
  vNode.ID := TVNodeID.ZERO;
  vTab.Add(vNode);
  Assert.AreEqual(0, vTab.Size, 'table should be empty');

  vId := TVNodeID.RandomNodeID;
  vNode := TNode.Create;
  vNode.ID := vId;
  vNode.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
  vNode.EndPoint.Port := 8483;
  vNode.EndPoint.Typ := THostIPv4.Create;
  vNode.Net := FSelfNode.Net;

  vTab.Add(vNode);
  Assert.AreEqual(1, vTab.Size, 'table size should be 1');

  vTab.Add(vNode);
  Assert.AreEqual(1, vTab.Size, 'table size should still be 1');

  vNodes := vTab.Nodes(0);
  Assert.AreEqual(1, Length(vNodes), 'should have 1 node');
  Assert.AreSame(vNode, vNodes[0], 'node should be the same');
end;

procedure TTableTest.TestTable_Add3;
var
  vMp: IPinger;
  vTab: INodeTable;
  vNode, vNode2, vToCheck: TNode;
  vStr: string;
  vN: TNode;
begin
  vMp := TMockPinger.Create(False);
  vTab := NewTable(TVNodeID.ZERO, FSelfNode.Net, NewListBucket, vMp);

  vNode := TNode.Create;
  vNode.ID := TVNodeID.RandomNodeID;
  vNode.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
  vNode.EndPoint.Port := 8483;
  vNode.EndPoint.Typ := THostIPv4.Create;
  vNode.Net := FSelfNode.Net;

  vToCheck := vTab.Add(vNode);
  Assert.IsNull(vToCheck, 'check node should be nil');

  vNode2 := TNode.Create;
  vNode2.ID := vNode.ID;
  vNode2.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
  vNode2.EndPoint.Port := 8485;
  vNode2.EndPoint.Typ := THostIPv4.Create;
  vNode2.Net := FSelfNode.Net;

  vToCheck := vTab.Add(vNode2);
  Assert.AreSame(vNode, vToCheck, 'check node should be the old node');
  TThread.Sleep(100);
  vStr := vTab.Resolve(vNode.ID).ToString;
  Assert.AreEqual(vNode.ToString, vStr, 'should be the old node string');

  vN := vTab.ResolveAddr(vNode.Address);
  Assert.AreSame(vNode, vN, 'error resolve by address');
  vN := vTab.ResolveAddr(vNode2.Address);
  Assert.IsNull(vN, 'should be nil');

  (vMp as TMockPinger).mFail := True;
  vToCheck := vTab.Add(vNode2);
  Assert.AreSame(vNode, vToCheck, 'check node should be the old node');
  TThread.Sleep(100);
  vStr := vTab.Resolve(vNode.ID).ToString;
  Assert.AreEqual(vNode2.ToString, vStr, 'should be the new node string');
  vN := vTab.ResolveAddr(vNode.Address);
  Assert.IsNull(vN, 'should be removed');
  vN := vTab.ResolveAddr(vNode2.Address);
  Assert.AreSame(vNode2, vN, 'should be the new node');
end;

procedure TTableTest.TestTable_Nodes;
var
  vId: TVNodeID;
  vMp: IPinger;
  vTab: INodeTable;
  vI, vD, vD2: Cardinal;
  vNode: TNode;
  vNodes: TArray<TNode>;
  vSet: Boolean;
begin
  vId := TVNodeID.Create;
  vMp := TMockPinger.Create(False);
  vTab := NewTable(vId, FSelfNode.Net, NewListBucket, vMp);

  for vI := vTab.GetMinDistance to TVNodeID.IDBits - 1 do
  begin
    vNode := TNode.Create;
    vNode.ID := TVNodeID.RandFromDistance(vId, vI);
    vNode.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
    vNode.EndPoint.Port := vI;
    vNode.EndPoint.Typ := THostIPv4.Create;
    vNode.Net := FSelfNode.Net;
    vTab.Add(vNode);
  end;

  vNodes := vTab.Nodes(0);
  Assert.AreEqual(BucketNum, Length(vNodes), 'nodes count should be bucket num');

  vD := 0;
  vSet := False;
  for vNode in vNodes do
  begin
    vD2 := TVNodeID.Distance(vId, vNode.ID);
    if vSet and (vD2 < vD) then
      Assert.Fail('should be sorted from near to faraway');
    vD := vD2;
    vSet := True;
  end;
end;

procedure TTableTest.TestTable_GetBucket;
var
  vId, vId2: TVNodeID;
  vTab: INodeTable;
  vBkt: IBucket;
  vI: Cardinal;
begin
  vId := TVNodeID.RandomNodeID;
  vTab := NewTable(vId, FSelfNode.Net, NewListBucket, nil);

  for vI := 0 to TVNodeID.IDBits - 1 do
  begin
    vId2 := TVNodeID.RandFromDistance(vId, vI);
    vBkt := (vTab as TNodeTable).GetBucket(vId2);
    if vI <= (vTab as TNodeTable).mMinDistance then
      Assert.AreSame((vTab as TNodeTable).mBuckets[0], vBkt, 'should be near bucket')
    else
      Assert.AreNotSame((vTab as TNodeTable).mBuckets[0], vBkt, 'should not be near bucket');
  end;
end;

procedure TTableTest.TestCloset;
const
  Total = 5;
var
  vId: TVNodeID;
  vCls: TCloset;
  vNode: TNode;
  vI, vD, vD2: Cardinal;
  vSet: Boolean;
  vNodes: TArray<TNode>;
begin
  vId := TVNodeID.RandomNodeID;
  vCls := TCloset.Create(vId, Total);
  try
    for vI := Total + 1 downto 1 do
    begin
      vNode := TNode.Create;
      vNode.ID := TVNodeID.RandFromDistance(vId, vI);
      vCls.Push(vNode);
    end;

    vD := 0;
    vSet := False;
    vNodes := vCls.GetNodes;
    for vNode in vNodes do
    begin
      vD2 := TVNodeID.Distance(vId, vNode.ID);
      if vSet and (vD2 < vD) then
        Assert.Fail('not sorted');
      vD := vD2;
      vSet := True;
    end;
  finally
    vCls.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTableTest);
end.
