unit Net.Discovery.Socket.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Net.Sockets,
  System.Threading,
  System.DateUtils,
  Crypto.Ed25519,
  Net.VNode,
  Net.Discovery.Message,
  Net.Discovery.Node,
  Net.Discovery.Pool,
  Net.Discovery.Socket,
  GoToDelphi.Helpers.TChannel;

type
  [TestFixture]
  TSocketTest = class(TObject)
  public
    [Test]
    [Ignore('Skipped in Go and requires complex channel handling')]
    procedure TestSocket_SendNeighbors;
    [Test]
    procedure TestSplitEndPoints;
  end;

function MockAgent(ParaPort: Integer; ParaHandler: TPacketHandler): ISocket;

implementation

uses
  System.Net.IP;

function MockAgent(ParaPort: Integer; ParaHandler: TPacketHandler): ISocket;
var
  vPub: TEd25519PublicKey;
  vPrv: TEd25519PrivateKey;
  vId: TVNodeID;
  vNode: TVNode;
begin
  TEd25519.GenerateKey(vPub, vPrv);
  vId := TVNodeID.FromBytes(vPub);
  vNode := TVNode.Create;
  vNode.ID := vId;
  vNode.EndPoint.Host := TBytes.Create(127, 0, 0, 1);
  vNode.EndPoint.Port := ParaPort;
  vNode.EndPoint.Typ := THostIPv4.Create;
  vNode.Net := 2;
  vNode.Ext := TEncoding.UTF8.GetBytes('hello');
  Result := NewAgent(vPrv, vNode, '127.0.0.1:' + IntToStr(ParaPort), ParaHandler);
end;

{ TSocketTest }

procedure TSocketTest.TestSocket_SendNeighbors;
var
  vS1, vS2: ISocket;
  vErr: Exception;
  vReceived: TChannel<TArray<TVNodeEndPoint>>;
  vTotal: Integer;
  vSent: TArray<TVNodeEndPoint>;
  vIndex: Integer;
  vUDPAddr: TSocketAddress;
  vReq: TRequest;
  vFindReq: TFindNodeRequest;
  vEps2: TArray<TVNodeEndPoint>;
begin
  // This test is skipped in the original Go codebase due to being non-functional.
  // It is included here for completeness of conversion but will also be skipped.
  Assert.Ignore('TestSocket_SendNeighbors is currently non-functional and skipped in Go.');

  vS1 := MockAgent(8483, nil);
  vErr := vS1.Start;
  Assert.IsNull(vErr, 'S1 Start should not return an error');

  vReceived := TChannel<TArray<TVNodeEndPoint>>.Create;
  vS2 := MockAgent(8484,
    procedure(ParaPkt: TPacket)
    var
      vNs: TNeighborsPacketBody;
    begin
      if ParaPkt.c = TCode.Neighbors then
      begin
        vNs := ParaPkt.body as TNeighborsPacketBody;
        Writeln(Format('received %d %s', [Length(vNs.endpoints), BoolToStr(vNs.last, True)]));
      end;
    end);
  vErr := vS2.Start;
  Assert.IsNull(vErr, 'S2 Start should not return an error');

  vTotal := 1000;
  SetLength(vSent, vTotal);
  for vIndex := 0 to vTotal - 1 do
  begin
    vSent[vIndex] := TVNodeEndPoint.Create;
    vSent[vIndex].Host := TBytes.Create(0, 0, 0, 0);
    vSent[vIndex].Port := vIndex;
    vSent[vIndex].Typ := THostIPv4.Create;
  end;

  TThread.CreateAnonymousThread(
    procedure
    begin
      vUDPAddr := TSocketAddress.Create((vS2 as TAgent).mNode.Address);
      vReq := TRequest.Create;
      vReq.ExpectFrom := (vS1 as TAgent).mNode.Address;
      vReq.ExpectID := (vS1 as TAgent).mNode.ID;
      vReq.ExpectCode := TCode.Neighbors;
      vFindReq := TFindNodeRequest.Create(vTotal, vReceived);
      vReq.Handler := vFindReq;
      vReq.Expiration := IncSecond(Now, 2 * Expiration);
      (vS2 as TAgent).mPool.Add(vReq);
      vErr := vS1.SendNodes(vSent, vUDPAddr);
      Assert.IsNull(vErr, 'SendNodes should not return an error');
    end).Start;

  vEps2 := vReceived.Receive;
  Assert.AreEqual(Length(vSent), Length(vEps2), Format('Expected %d but received %d endpoints', [Length(vSent), Length(vEps2)]));
  Writeln(Format('MaxPayloadLength: %d', [MaxPayloadLength]));
  vS1.Stop;
  vS2.Stop;
end;

procedure TSocketTest.TestSplitEndPoints;
const
  Total = 1000;
var
  vSent: TArray<TVNodeEndPoint>;
  vIndex, vCount: Integer;
  vEpt: TArray<TArray<TVNodeEndPoint>>;
  vN: TNeighborsPacketBody;
  vPub: TEd25519PublicKey;
  vPrv: TEd25519PrivateKey;
  vId: TVNodeID;
  vMsg: TMessage;
  vData, vHash: TBytes;
  vEps: TArray<TVNodeEndPoint>;
  vEp: TVNodeEndPoint;
begin
  SetLength(vSent, Total);
  for vIndex := 0 to Total - 1 do
  begin
    vSent[vIndex] := TVNodeEndPoint.Create;
    vSent[vIndex].Host := TBytes.Create(0, 0, 0, 0);
    vSent[vIndex].Port := vIndex;
    vSent[vIndex].Typ := THostIPv4.Create;
  end;

  vEpt := SplitEndPoints(vSent);

  vN := TNeighborsPacketBody.Create;
  vN.last := False;
  vN.time := Now;

  TEd25519.GenerateKey(vPub, vPrv);
  vId := TVNodeID.FromBytes(vPub);

  vMsg := TMessage.Create;
  vMsg.c := TCode.Neighbors;
  vMsg.id := vId;
  vMsg.body := vN;

  vIndex := 0;
  vCount := 0;
  for vEps in vEpt do
  begin
    vCount := vCount + Length(vEps);
    for vEp in vEps do
    begin
      Assert.AreSame(vSent[vIndex], vEp, 'Endpoint should match original');
      Inc(vIndex);
    end;

    vN.endpoints := vEps;
    vData := vMsg.Pack(vPrv, vHash);

    if Length(vData) > MaxPacketLength then
      Assert.Fail(Format('Packet too large: %d bytes', [Length(vData)]))
    else
      Writeln(Format('%d bytes UDP packet', [Length(vData)]));
  end;

  Assert.AreEqual(Length(vSent), vCount, Format('Wrong total length: %d', [vCount]));
end;

initialization
  TDUnitX.RegisterTestFixture(TSocketTest);
end.
