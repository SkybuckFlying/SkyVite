unit net.discovery.message.test;

interface

uses
  common.bytes,
  crypto.ed25519,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  net.discovery.discovery // For TNode and other types if needed,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  net.discovery.message,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  net.vnode,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.SysUtils,
  TestFramework;

type
  [TestFixture]
  TMessageTest = class(TObject)
  public
    [Test]
    procedure TestPing_Serialize;
    [Test]
    procedure TestPong_Serialize;
    [Test]
    procedure TestFindNode_Serialize;
    [Test]
    procedure TestNeighbors_Serialize;
    [Test]
    procedure TestMessage_Pack;
    [Test]
    procedure TestUnpack;
  end;

implementation

{ Helper functions for comparison }

function EqualPing(P1, P2: TPingPacketBody): Boolean;
begin
  Result := True;
  if Assigned(P1.FromNode) then
  begin
    if not Assigned(P2.FromNode) or not P1.FromNode.IsEqual(P2.FromNode) then
    begin
      Result := False;
      Exit;
    end;
  end
  else if Assigned(P2.FromNode) then
  begin
    Result := False;
    Exit;
  end;

  if Assigned(P1.ToNode) then
  begin
    if not Assigned(P2.ToNode) or not P1.ToNode.IsEqual(P2.ToNode) then
    begin
      Result := False;
      Exit;
    end;
  end
  else if Assigned(P2.ToNode) then
  begin
    Result := False;
    Exit;
  end;

  if P1.Net <> P2.Net then
    Result := False
  else if not TBytes.Equals(P1.Ext, P2.Ext) then
    Result := False
  else if P1.Time <> P2.Time then // Compare Unix timestamps
    Result := False;
end;

function EqualPong(P1, P2: TPongPacketBody): Boolean;
begin
  Result := True;
  if Assigned(P1.FromNode) then
  begin
    if not Assigned(P2.FromNode) or not P1.FromNode.IsEqual(P2.FromNode) then
    begin
      Result := False;
      Exit;
    end;
  end
  else if Assigned(P2.FromNode) then
  begin
    Result := False;
    Exit;
  end;

  if Assigned(P1.ToNode) then
  begin
    if not Assigned(P2.ToNode) or not P1.ToNode.IsEqual(P2.ToNode) then
    begin
      Result := False;
      Exit;
    end;
  end
  else if Assigned(P2.ToNode) then
  begin
    Result := False;
    Exit;
  end;

  if P1.Net <> P2.Net then
    Result := False
  else if not TBytes.Equals(P1.Ext, P2.Ext) then
    Result := False
  else if not TBytes.Equals(P1.Echo, P2.Echo) then
    Result := False
  else if P1.Time <> P2.Time then // Compare Unix timestamps
    Result := False;
end;

function EqualFindNode(P1, P2: TFindNodePacketBody): Boolean;
begin
  Result := (P1.Count = P2.Count) and
            P1.Target.IsEqual(P2.Target) and
            (P1.Time = P2.Time); // Compare Unix timestamps
end;

function EqualNeighbors(P1, P2: TNeighborsPacketBody): Boolean;
var
  I: Integer;
begin
  Result := (P1.Last = P2.Last) and
            (Length(P1.Endpoints) = Length(P2.Endpoints));
  if not Result then Exit;

  for I := 0 to High(P1.Endpoints) do
  begin
    if not P1.Endpoints[I].IsEqual(P2.Endpoints[I]) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function EqualMessage(M1, M2: TMessage): Boolean;
begin
  Result := (M1.Code = M2.Code) and (M1.Id.IsEqual(M2.Id));
  if not Result then Exit;

  case M1.Code of
    CodePing: Result := EqualPing(M1.Body as TPingPacketBody, M2.Body as TPingPacketBody);
    CodePong: Result := EqualPong(M1.Body as TPongPacketBody, M2.Body as TPongPacketBody);
    CodeFindnode: Result := EqualFindNode(M1.Body as TFindNodePacketBody, M2.Body as TFindNodePacketBody);
    CodeNeighbors: Result := EqualNeighbors(M1.Body as TNeighborsPacketBody, M2.Body as TNeighborsPacketBody);
  else
    Result := False;
  end;
end;

{ TMessageTest }

procedure TMessageTest.TestPing_Serialize;
var
  P, P2: TPingPacketBody;
  Data: TBytes;
  Err: Exception;
begin
  P := TPingPacketBody.Create;
  P.FromNode := nil;
  P.ToNode := nil;
  P.Net := 0;
  P.Ext := TBytes.Create(ord('h'), ord('e'), ord('l'), ord('l'), ord('o'));
  P.Time := DateTimeToUnix(IncHour(Now, 1));

  Data := P.Serialize;
  P2 := TPingPacketBody.Create;
  P2.Deserialize(Data);

  Assert.IsTrue(EqualPing(P, P2), 'Ping packets should be equal after serialize/deserialize');

  // Test with initialized endpoints
  P.FromNode := TVNodeEndPoint.Create;
  P.ToNode := TVNodeEndPoint.Create;
  Data := P.Serialize;
  P2.Deserialize(Data);

  Assert.IsNull(P2.FromNode, 'Endpoint should be nil after deserialize if not explicitly set in Go');
  Assert.IsNull(P2.ToNode, 'Endpoint should be nil after deserialize if not explicitly set in Go');

  P.Free;
  P2.Free;
end;

procedure TMessageTest.TestPong_Serialize;
var
  P, P2: TPongPacketBody;
  Data: TBytes;
  Err: Exception;
begin
  P := TPongPacketBody.Create;
  P.Echo := TBytes.Create(ord('h'), ord('e'), ord('l'), ord('l'), ord('o'));
  P.FromNode := nil;
  P.ToNode := nil;
  P.Net := 0;
  P.Ext := TBytes.Create(ord('h'), ord('e'), ord('l'), ord('l'), ord('o'));
  P.Time := DateTimeToUnix(IncHour(Now, 1));

  Data := P.Serialize;
  P2 := TPongPacketBody.Create;
  P2.Deserialize(Data);

  Assert.IsTrue(EqualPong(P, P2), 'Pong packets should be equal after serialize/deserialize');

  // Test with initialized endpoints
  P.FromNode := TVNodeEndPoint.Create;
  P.ToNode := TVNodeEndPoint.Create;
  Data := P.Serialize;
  P2.Deserialize(Data);

  Assert.IsNull(P2.FromNode, 'Endpoint should be nil after deserialize if not explicitly set in Go');
  Assert.IsNull(P2.ToNode, 'Endpoint should be nil after deserialize if not explicitly set in Go');

  P.Free;
  P2.Free;
end;

procedure TMessageTest.TestFindNode_Serialize;
var
  P, P2: TFindNodePacketBody;
  Data: TBytes;
  Err: Exception;
begin
  P := TFindNodePacketBody.Create;
  P.Count := 10;
  P.Target := TVNodeID.ZERO;
  P.Target.SetBytes(TBytes.Create(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31)); // Mock random bytes
  P.Time := DateTimeToUnix(IncHour(Now, 1));

  Data := P.Serialize;
  P2 := TFindNodePacketBody.Create;
  P2.Deserialize(Data);

  Assert.IsTrue(EqualFindNode(P, P2), 'FindNode packets should be equal after serialize/deserialize');

  P.Free;
  P2.Free;
end;

procedure TMessageTest.TestNeighbors_Serialize;
var
  P, P2: TNeighborsPacketBody;
  Data: TBytes;
  Err: Exception;
  EP: TVNodeEndPoint;
begin
  P := TNeighborsPacketBody.Create;
  P.Last := True;
  P.Time := DateTimeToUnix(IncHour(Now, 1));

  EP := TVNodeEndPoint.Create;
  EP.Host := TBytes.Create(0, 0, 0, 0);
  EP.Port := 8888;
  EP.Typ := HostIPv4;
  P.Endpoints := P.Endpoints + [EP];

  EP := TVNodeEndPoint.Create;
  EP.Host := TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  EP.Port := 8889;
  EP.Typ := HostIPv6;
  P.Endpoints := P.Endpoints + [EP];

  EP := TVNodeEndPoint.Create;
  EP.Host := TBytes.Create(ord('v'), ord('i'), ord('t'), ord('e'), ord('.'), ord('o'), ord('r'), ord('g'));
  EP.Port := 9000;
  EP.Typ := HostDomain;
  P.Endpoints := P.Endpoints + [EP];

  Data := P.Serialize;
  P2 := TNeighborsPacketBody.Create;
  P2.Deserialize(Data);

  Assert.IsTrue(EqualNeighbors(P, P2), 'Neighbors packets should be equal after serialize/deserialize');

  P.Free;
  P2.Free;
end;

procedure TMessageTest.TestMessage_Pack;
var
  PublicKey, PrivateKey: TBytes;
  Id: TVNodeID;
  Messages: TArray<TMessage>;
  Msg: TMessage;
  Data, Hash: TBytes;
  Pkt: TPacket;
  Err: Exception;
begin
  GenerateKey(PublicKey, PrivateKey);
  Id := TVNodeID.FromBytes(PublicKey);

  SetLength(Messages, 4);

  Messages[0] := TMessage.Create;
  Messages[0].Code := CodePing;
  Messages[0].Id := Id;
  Messages[0].Body := TPingPacketBody.Create;
  (Messages[0].Body as TPingPacketBody).FromNode := TVNodeEndPoint.Create;
  (Messages[0].Body as TPingPacketBody).FromNode.Host := TBytes.Create(127, 0, 0, 1);
  (Messages[0].Body as TPingPacketBody).FromNode.Port := 8483;
  (Messages[0].Body as TPingPacketBody).FromNode.Typ := HostIPv4;
  (Messages[0].Body as TPingPacketBody).ToNode := TVNodeEndPoint.Create;
  (Messages[0].Body as TPingPacketBody).ToNode.Host := TBytes.Create(127, 0, 0, 1);
  (Messages[0].Body as TPingPacketBody).ToNode.Port := 8484;
  (Messages[0].Body as TPingPacketBody).ToNode.Typ := HostIPv4;
  (Messages[0].Body as TPingPacketBody).Net := 1;
  (Messages[0].Body as TPingPacketBody).Ext := TBytes.Create(ord('h'), ord('e'), ord('l'), ord('l'), ord('o'), ord(' '), ord('w'), ord('o'), ord('r'), ord('l'), ord('d'));
  (Messages[0].Body as TPingPacketBody).Time := DateTimeToUnix(IncHour(Now, 1));

  Messages[1] := TMessage.Create;
  Messages[1].Code := CodePong;
  Messages[1].Id := Id;
  Messages[1].Body := TPongPacketBody.Create;
  (Messages[1].Body as TPongPacketBody).FromNode := TVNodeEndPoint.Create;
  (Messages[1].Body as TPongPacketBody).FromNode.Host := TBytes.Create(127, 0, 0, 1);
  (Messages[1].Body as TPongPacketBody).FromNode.Port := 8483;
  (Messages[1].Body as TPongPacketBody).FromNode.Typ := HostIPv4;
  (Messages[1].Body as TPongPacketBody).ToNode := TVNodeEndPoint.Create;
  (Messages[1].Body as TPongPacketBody).ToNode.Host := TBytes.Create(127, 0, 0, 1);
  (Messages[1].Body as TPongPacketBody).ToNode.Port := 8484;
  (Messages[1].Body as TPongPacketBody).ToNode.Typ := HostIPv4;
  (Messages[1].Body as TPongPacketBody).Net := 1;
  (Messages[1].Body as TPongPacketBody).Ext := TBytes.Create(ord('h'), ord('e'), ord('l'), ord('l'), ord('o'), ord(' '), ord('w'), ord('o'), ord('r'), ord('l'), ord('d'));
  (Messages[1].Body as TPongPacketBody).Time := DateTimeToUnix(IncHour(Now, 2));
  (Messages[1].Body as TPongPacketBody).Echo := TBytes.Create(ord('w'), ord('o'), ord('r'), ord('l'), ord('d'));

  Messages[2] := TMessage.Create;
  Messages[2].Code := CodeFindnode;
  Messages[2].Id := Id;
  Messages[2].Body := TFindNodePacketBody.Create;
  (Messages[2].Body as TFindNodePacketBody).Target := TVNodeID.ZERO;
  (Messages[2].Body as TFindNodePacketBody).Count := 100;
  (Messages[2].Body as TFindNodePacketBody).Time := DateTimeToUnix(IncHour(Now, 3));

  Messages[3] := TMessage.Create;
  Messages[3].Code := CodeNeighbors;
  Messages[3].Id := Id;
  Messages[3].Body := TNeighborsPacketBody.Create;
  (Messages[3].Body as TNeighborsPacketBody).Last := True;
  (Messages[3].Body as TNeighborsPacketBody).Time := DateTimeToUnix(IncHour(Now, 1));
  EP := TVNodeEndPoint.Create;
  EP.Host := TBytes.Create(ord('v'), ord('i'), ord('t'), ord('e'), ord('.'), ord('o'), ord('r'), ord('g'));
  EP.Port := 8888;
  EP.Typ := HostDomain;
  (Messages[3].Body as TNeighborsPacketBody).Endpoints := [(EP)];

  for Msg in Messages do
  begin
    Data := Msg.Pack(PrivateKey, Hash);
    Pkt := RetrievePacket;
    Err := Unpack(Data, Pkt);
    Assert.IsNull(Err, Format('Unpack should not return an error: %s', [Err.Message]));

    Assert.IsTrue(EqualMessage(Pkt.Message, Msg), 'Messages should be equal after pack/unpack');
    Assert.IsTrue(TBytes.Equals(Pkt.Hash, Hash), 'Hashes should be equal');

    Pkt.Free;
  end;

  for Msg in Messages do
    Msg.Free;
end;

procedure TMessageTest.TestUnpack;
var
  Buf: TBytes;
  P: TPacket;
  I: Integer;
  Err: Exception;
begin
  P := RetrievePacket;
  try
    SetLength(Buf, 0);
    for I := 0 to MinPacketLength - 1 do
    begin
      SetLength(Buf, Length(Buf) + 1);
      Buf[High(Buf)] := 1;
      Err := Unpack(Buf, P);
      Assert.IsNotNull(Err, Format('Unpack should return error for too short buffer at length %d', [Length(Buf)]));
    end;
    // Test with exactly minPacketLength
    Err := Unpack(Buf, P);
    Assert.IsNotNull(Err, Format('Unpack should return error for minPacketLength without valid data', [Length(Buf)]));

  finally
    P.Free;
  end;
end;

initialization
  RegisterTest(TMessageTest.Suite);
end.
