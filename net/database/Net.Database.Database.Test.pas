unit net.database.database.test;

interface

uses
  common.bytes,
  net.database.database,
  net.vnode,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  TestFramework;

type
  [TestFixture]
  TDatabaseTest = class(TObject)
  public
    [Test]
    procedure TestNodeDB_Store;
  end;

implementation

{ TDatabaseTest }

procedure TDatabaseTest.TestNodeDB_Store;
var
  Id: TVNodeID;
  DB: TDB;
  Node, Node2: TVNode;
  Err: Exception;
begin
  Id := TVNodeID.RandomNodeID;
  DB := NewDB('', 1, Id); // Use in-memory dummy DB
  try
    Node := TVNode.MockNode(False, True);

    Err := DB.StoreNode(Node);
    Assert.IsNull(Err, 'StoreNode should not return an error');

    Node2 := DB.RetrieveNode(Node.ID);
    Assert.IsNotNull(Node2, 'RetrieveNode should return a node');

    Assert.IsTrue(Node2.ID.IsEqual(Node.ID), 'IDs should be equal');
    Assert.AreEqual(Node2.EndPoint.ToString, Node.EndPoint.ToString, 'Endpoints should be equal');
    Assert.IsTrue(TBytes.Equals(Node2.Ext, Node.Ext), 'Extensions should be equal');
    Assert.AreEqual(Node2.Net, Node.Net, 'Net values should be equal');
  finally
    DB.Free;
  end;
end;

initialization
  RegisterTest(TDatabaseTest.Suite);
end.
