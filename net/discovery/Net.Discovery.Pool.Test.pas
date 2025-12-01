unit Net.Discovery.Pool.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Net.Sockets,
  System.Threading,
  System.DateUtils,
  Common.Bytes,
  Net.VNode,
  Net.Discovery.Message,
  Net.Discovery.Node,
  Net.Discovery.Pool;

type
  [TestFixture]
  TPoolTest = class(TObject)
  public
    [Test]
    procedure TestPool_Add;
    [Test]
    procedure TestPool_Rec;
    [Test]
    [Ignore('Skipped in Go and requires complex channel handling')]
    procedure TestPool_Rec2;
  end;

implementation

{ TPoolTest }

procedure TPoolTest.TestPool_Add;
var
  vP: IRequestPool;
  vReq: TRequest;
begin
  vP := NewRequestPool;
  vP.Start;

  vReq := TRequest.Create;
  vReq.ExpectFrom := '127.0.0.1:8483';
  vReq.ExpectID := TVNodeID.Create;
  vReq.ExpectCode := 0;
  vReq.Handler := nil;
  vReq.Expiration := IncHour(Now, 1);
  vP.Add(vReq);

  vReq := TRequest.Create;
  vReq.ExpectFrom := '127.0.0.1:8483';
  vReq.ExpectID := TVNodeID.Create;
  vReq.ExpectCode := 0;
  vReq.Handler := nil;
  vReq.Expiration := IncHour(Now, 1);
  vP.Add(vReq);

  vReq := TRequest.Create;
  vReq.ExpectFrom := '127.0.0.1:8484';
  vReq.ExpectID := TVNodeID.Create;
  vReq.ExpectCode := 0;
  vReq.Handler := nil;
  vReq.Expiration := IncHour(Now, 1);
  vP.Add(vReq);

  Assert.AreEqual(3, vP.Size, 'Should have 3 requests');
end;

procedure TPoolTest.TestPool_Rec;
var
  vP: IRequestPool;
  vNode: TNode;
  vReq: TRequest;
  vPkt: TPacket;
  vPongBody: TPongPacketBody;
  vFromEP: TVNodeEndPoint;
  vFromAddr: TSocketAddress;
  vDoneEvent: TEvent;
begin
  vP := NewRequestPool;
  vP.Start;
  vDoneEvent := TEvent.Create;

  vNode := nil;
  vReq := TRequest.Create;
  vReq.ExpectFrom := '127.0.0.1:8483';
  vReq.ExpectID := TVNodeID.ZERO;
  vReq.ExpectCode := TCode.Pong;
  vReq.Handler := TPingRequest.Create(
    TEncoding.UTF8.GetBytes('hello'),
    procedure(ParaNode: TNode; ParaErr: Exception)
    begin
      vNode := ParaNode;
      vDoneEvent.SetEvent;
    end);
  vReq.Expiration := IncSecond(Now, 1);
  vP.Add(vReq);

  vPkt := TPacket.Create;
  vPkt.c := TCode.Pong;
  vPkt.id := TVNodeID.Create(TBytes.Create(1));
  vPongBody := TPongPacketBody.Create;
  vFromEP := TVNodeEndPoint.Create;
  vFromEP.Host := TBytes.Create(127, 0, 0, 1);
  vFromEP.Port := 8888;
  vFromEP.Typ := THostIPv4.Create;
  vPongBody.from := vFromEP;
  vPongBody.to_ := nil;
  vPongBody.net := 0;
  vPongBody.ext := TEncoding.UTF8.GetBytes('world');
  vPongBody.echo := TEncoding.UTF8.GetBytes('hello');
  vPongBody.time := Now;
  vPkt.body := vPongBody;

  vFromAddr := TSocketAddress.Create('127.0.0.1', 8483);
  vPkt.from := vFromAddr;

  vP.Rec(vPkt);

  // Wait for the async callback to execute
  if vDoneEvent.WaitFor(1000) = wrTimeout then
    Assert.Fail('Timeout waiting for pong');

  Assert.IsNotNull(vNode, 'Node should not be nil');
  Assert.AreEqual(1, vNode.ID.Bytes[0], 'Wrong ID');
  Assert.IsTrue(TBytes.Equals(TEncoding.UTF8.GetBytes('world'), vNode.Ext), 'Wrong Ext');
  Assert.AreEqual('127.0.0.1:8888', vNode.Address, 'Wrong address');
end;

procedure TPoolTest.TestPool_Rec2;
begin
  // This test is skipped in Go and requires complex channel handling.
end;

initialization
  TDUnitX.RegisterTestFixture(TPoolTest);
end.
