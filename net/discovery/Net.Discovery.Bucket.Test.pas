unit net.discovery.bucket.test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  net.vnode,
  net.discovery.discovery,
  net.discovery.bucket;

type
  [TestFixture]
  TBucketTest = class(TObject)
  public
    [Test]
    procedure TestBuck_Add;
    [Test]
    procedure TestBuck_Reset;
    [Test]
    procedure TestBuck_Bubble;
    [Test]
    procedure TestBuck_Remove;
    [Test]
    procedure TestBuck_Nodes;
    [Test]
    procedure TestBuck_Resolve;
    [Test]
    procedure TestBuck_Size;
    [Test]
    procedure TestBuck_Oldest;
  end;

implementation

{ TBucketTest }

procedure TBucketTest.TestBuck_Add;
const
  Total = 5;
var
  Bkt: IBucket;
  Node, First: TNode;
  I: Integer;
begin
  Bkt := TListBucket.Create(Total);

  First := nil;
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Assert.IsNull(Bkt.Add(Node), 'Add should return nil for new nodes');

    if First = nil then
      First := Node;
  end;

  // Node already in bucket, should return the existing node
  Assert.AreSame(Node, Bkt.Add(Node), 'Add should return existing node');

  // Node not in bucket, should return the oldest node (first added)
  Node := TNode.Create(TVNode.MockNode(False, False));
  Assert.AreSame(First, Bkt.Add(Node), 'Add should return the oldest node when full');
end;

procedure TBucketTest.TestBuck_Reset;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I, Index: Integer;
begin
  Bkt := TListBucket.Create(Total);

  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
  end;

  Bkt.Reset;

  Assert.AreEqual(0, Bkt.Size, 'Bucket size should be 0 after reset');

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  Index := 0;
  Bkt.Iterate(procedure(ANode: TNode): Boolean
  begin
    Assert.AreSame(Nodes[Index], ANode, 'Iterated node should match original');
    Inc(Index);
    Result := False; // Continue iteration
  end);
end;

procedure TBucketTest.TestBuck_Bubble;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I, NextIndex: Integer;
begin
  Bkt := TListBucket.Create(Total);

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  for I := 0 to Total - 1 do
  begin
    Node := Nodes[I];
    Assert.IsTrue(Bkt.Bubble(Node.ID), 'Bubble should return true for existing node');

    NextIndex := (I + 1) mod Total;
    Assert.AreSame(Nodes[NextIndex], Bkt.Oldest, Format('Oldest node is wrong after bubbling %s. Expected %s, got %s', [Node.ID.ToString, Nodes[NextIndex].ID.ToString, Bkt.Oldest.ID.ToString]));
  end;
end;

procedure TBucketTest.TestBuck_Remove;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I, J: Integer;
begin
  Bkt := TListBucket.Create(Total);

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  for I := 0 to Total - 1 do
  begin
    Node := Nodes[I];
    Assert.AreSame(Node, Bkt.Remove(Node.ID), 'Remove should return the removed node');
    Assert.AreEqual(Total - I - 1, Bkt.Size, 'Bucket size should decrease after removal');

    J := I + 1;
    Bkt.Iterate(procedure(ANode: TNode): Boolean
    begin
      Assert.AreSame(Nodes[J], ANode, 'Iterated node should match remaining nodes');
      Inc(J);
      Result := False;
    end);
  end;

  Assert.IsNull(Bkt.Remove(TVNodeID.ZERO), 'Removing non-existent node should return nil');

  // Add again to test iteration after removals and re-adds
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  I := 0;
  Bkt.Iterate(procedure(ANode: TNode): Boolean
  begin
    Assert.AreSame(Nodes[I], ANode, 'Iterated node should match re-added nodes');
    Inc(I);
    Result := False;
  end);
end;

procedure TBucketTest.TestBuck_Nodes;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes, Nodes2: TArray<TNode>;
  I: Integer;
begin
  Bkt := TListBucket.Create(Total);

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  // Test with count = Total / 2
  Nodes2 := Bkt.Nodes(Total div 2);
  Assert.AreEqual(Total div 2, Length(Nodes2), 'Length should be half of total');
  for I := 0 to Length(Nodes2) - 1 do
    Assert.AreSame(Nodes[Total - Length(Nodes2) + I], Nodes2[I], 'Nodes should be the newest ones');

  // Test with count > Total
  Nodes2 := Bkt.Nodes(Total + 10);
  Assert.AreEqual(Total, Length(Nodes2), 'Length should be total when count is too high');
  for I := 0 to Length(Nodes2) - 1 do
    Assert.AreSame(Nodes[I], Nodes2[I], 'Nodes should be all nodes');

  // Test with count = 0
  Nodes2 := Bkt.Nodes(0);
  Assert.AreEqual(Total, Length(Nodes2), 'Length should be total when count is 0');
  for I := 0 to Length(Nodes2) - 1 do
    Assert.AreSame(Nodes[I], Nodes2[I], 'Nodes should be all nodes');
end;

procedure TBucketTest.TestBuck_Resolve;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I: Integer;
begin
  Bkt := TListBucket.Create(Total);

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  for I := 0 to Total - 1 do
  begin
    Node := Nodes[I];
    Assert.AreSame(Node, Bkt.Resolve(Node.ID), 'Resolve should return the correct node');
  end;

  Assert.IsNull(Bkt.Resolve(TVNodeID.ZERO), 'Resolve should return nil for non-existent ID');
end;

procedure TBucketTest.TestBuck_Size;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I: Integer;
begin
  Bkt := TListBucket.Create(Total);
  Assert.AreEqual(0, Bkt.Size, 'Initial size should be 0');

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
    Assert.AreEqual(I + 1, Bkt.Size, 'Size should increment after add');
  end;

  for I := 0 to Total - 1 do
  begin
    Node := Nodes[I];
    Bkt.Remove(Node.ID);
    Assert.AreEqual(Total - 1 - I, Bkt.Size, 'Size should decrement after remove');
  end;
end;

procedure TBucketTest.TestBuck_Oldest;
const
  Total = 5;
var
  Bkt: IBucket;
  Node: TNode;
  Nodes: TArray<TNode>;
  I, NextIndex: Integer;
begin
  Bkt := TListBucket.Create(Total);
  Assert.IsNull(Bkt.Oldest, 'Oldest should be nil for empty bucket');

  SetLength(Nodes, Total);
  for I := 0 to Total - 1 do
  begin
    Node := TNode.Create(TVNode.MockNode(False, False));
    Bkt.Add(Node);
    Nodes[I] := Node;
  end;

  for I := 0 to Total - 1 do
  begin
    Node := Nodes[I];
    Bkt.Bubble(Node.ID);
    NextIndex := (I + 1) mod Total;
    Assert.AreSame(Nodes[NextIndex], Bkt.Oldest, Format('Oldest node is wrong after bubbling %s. Expected %s, got %s', [Node.ID.ToString, Nodes[NextIndex].ID.ToString, Bkt.Oldest.ID.ToString]));
  end;
end;

initialization
  RegisterTest(TBucketTest.Suite);
end.
