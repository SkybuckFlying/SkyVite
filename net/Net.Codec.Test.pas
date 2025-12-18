unit Net.Codec.Test;

interface

uses
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
  System.Classes,
  System.Generics.Collections,
  System.Net.Sockets,
  System.SysUtils,
  TestFramework;

type
  [TestFixture]
  TCodecTest = class(TObject)
  public
    [Test]
    procedure TestCodec_PutVarint;
    [Test]
    procedure TestCodec_Varint;
    [Test]
    procedure TestCodec_IdLengthConversion;
    [Test]
    procedure TestCodec_PutId;
    [Test]
    procedure TestCodec_RetrieveStoreMeta;
    [Test]
    procedure TestCodec_EndToEnd;
  end;

implementation

uses
  System.Math,
  System.Threading,
  System.Net.Socket;

{ TCodecTest }

procedure TCodecTest.TestCodec_PutVarint;
const
  MaxLen = 8;
var
  Buf: TBytes;
  I: Cardinal;
  M: Byte;
  Offset: Cardinal;
  Length: Byte;
begin
  SetLength(Buf, MaxLen);

  I := 0;
  M := PutVarint(Buf, I);
  Assert.AreEqual(0, M, '0 should be 0 byte');

  I := 1;
  for Offset := 0 to MaxLen * 8 - 1 do
  begin
    I := 1 shl Offset;
    Length := Byte(Offset div 8 + 1);
    M := PutVarint(Buf, I);
    Assert.IsFalse(M > Length, Format('%d should be %d bytes, but not %d bytes', [I, Length, M]));
  end;
end;

procedure TCodecTest.TestCodec_Varint;
const
  MaxLen = 8;
var
  Buf: TBytes;
  I, I2: Cardinal;
  M: Byte;
  Offset: Cardinal;
begin
  SetLength(Buf, MaxLen);

  I := 0;
  M := PutVarint(Buf, I);
  I2 := Varint(Copy(Buf, 0, M));
  Assert.AreEqual(I, I2, Format('put %d, but not get %d', [I, I2]));

  I := 1;
  for Offset := 0 to MaxLen * 8 - 1 do
  begin
    I := 1 shl Offset;
    M := PutVarint(Buf, I);
    I2 := Varint(Copy(Buf, 0, M));
    Assert.AreEqual(I, I2, Format('put %d, but get %d', [I, I2]));
  end;
end;

procedure TCodecTest.TestCodec_IdLengthConversion;
var
  Sizes: TArray<Byte>;
  Bits: TArray<Byte>;
  I: Integer;
  Bit: Byte;
begin
  Sizes := [0, 1, 2, 4];
  Bits := [0, 1, 2, 3];

  for I := 0 to High(Sizes) do
  begin
    Bit := IdLengthToBits(Sizes[I]);
    Assert.AreEqual(Bits[I], Bit, Format('wrong length to bit %d --> %d', [Sizes[I], Bit]));
    Assert.AreEqual(Sizes[I], BitsToIdLength(Bit), Format('wrong bit to length %d --> %d', [Bit, Sizes[I]]));
  end;
end;

procedure TCodecTest.TestCodec_PutId;
var
  Ids: TArray<TMsgId>;
  Lengths: TArray<Byte>;
  Buf: TBytes;
  I: Integer;
  N: Byte;
begin
  Ids := [0, 222, 666, 77777];
  Lengths := [0, 1, 2, 4];

  SetLength(Buf, 4);
  for I := 0 to High(Ids) do
  begin
    N := PutId(Ids[I], Buf);
    Assert.AreEqual(Lengths[I], N, Format('wrong id %d length: %d', [Ids[I], N]));
  end;
end;

procedure TCodecTest.TestCodec_RetrieveStoreMeta;
var
  ISizes: TArray<Byte>;
  LSizes: TArray<Byte>;
  CS: TArray<Boolean>;
  ISize, LSize, ISize2, LSize2, Meta: Byte;
  C, C2: Boolean;
begin
  ISizes := [0, 1, 2, 4];
  LSizes := [0, 1, 2, 3];
  CS := [True, False];

  for ISize in ISizes do
  begin
    for LSize in LSizes do
    begin
      for C in CS do
      begin
        Meta := StoreMeta(ISize, LSize, C);
        RetrieveMeta(Meta, ISize2, LSize2, C2);
        Assert.AreEqual(ISize, ISize2, Format('wrong isize: %d %d', [ISize, ISize2]));
        Assert.AreEqual(LSize, LSize2, Format('wrong lsize: %d %d', [LSize, LSize2]));
        Assert.AreEqual(C, C2, Format('wrong compress: %s %s', [BoolToStr(C, True), BoolToStr(C2, True)]));
      end;
    end;
  end;
end;

procedure TCodecTest.TestCodec_EndToEnd;
const
  Addr = '127.0.0.1';
  Port = 10000;
var
  Listener: TSocket;
  Client: TSocket;
  ServerTask: ITask;
  ClientTask: ITask;
  Channel: TChannel<TMsg>;
  ServerCodec: ICodec;
  ClientCodec: ICodec;
  I: Integer;
  Buf: TBytes;
  Msg, Msg2: TMsg;
begin
  Channel := TChannel<TMsg>.Create;
  Listener := TSocket.Create(TSocketType.TCP);
  Listener.Bind(Addr, Port);
  Listener.Listen;

  ServerTask := TTask.Run(procedure
  var
    Conn: TSocket;
  begin
    Conn := Listener.Accept;
    try
      ServerCodec := NewTransport(Conn, 100, ReadMsgTimeout, WriteMsgTimeout);
      for I := 0 to 10 do
      begin
        SetLength(Buf, I * 100);
        RandomBytes(Buf);
        Msg.Code := I;
        Msg.Id := I;
        Msg.Payload := Buf;
        ServerCodec.WriteMsg(Msg);
        Channel.Send(Msg);
      end;
    finally
      Conn.Free;
    end;
  end);

  ClientTask := TTask.Run(procedure
  begin
    Client := TSocket.Create(TSocketType.TCP);
    try
      Client.Connect(Addr, Port);
      ClientCodec := NewTransport(Client, 100, ReadMsgTimeout, WriteMsgTimeout);
      for I := 0 to 10 do
      begin
        Msg := ClientCodec.ReadMsg;
        Msg2 := Channel.Receive;
        Assert.AreEqual(Msg.Code, Msg2.Code);
        Assert.AreEqual(Msg.Id, Msg2.Id);
        Assert.AreEqual(Length(Msg.Payload), Length(Msg2.Payload));
        Assert.IsTrue(TBytes.Equals(Msg.Payload, Msg2.Payload));
      end;
    finally
      Client.Free;
    end;
  end);

  TTask.WaitForAll([ServerTask, ClientTask]);
  Listener.Free;
end;

initialization
  RegisterTestFixture(TCodecTest);
end.
