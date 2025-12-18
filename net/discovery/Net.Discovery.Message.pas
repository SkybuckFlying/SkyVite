unit net.discovery.message;

interface

uses
  common.bytes crypto crypto.ed25519 net.vnode net.discovery.protos.message_pb,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  System.SysUtils System.Classes System.Generics.Collections System.DateUtils;

const
  Version: Byte = 0;
  Expiration = 10 * 1000; // 10 seconds in milliseconds
  MaxPacketLength = 1200;
  SignatureLength = 64;
  PacketHeadLength = 1 + 1 + Length(TVNodeID.ZERO.Bytes); // Version + Code + NodeID (32 bytes)
  MinPacketLength = PacketHeadLength + SignatureLength; // 98
  MaxPayloadLength = MaxPacketLength - MinPacketLength; // 1102

type
  TCode = Byte;

const
  CodePing = 0;
  CodePong = 1;
  CodeFindnode = 2;
  CodeNeighbors = 3;
  CodeException = 4;

var
  ErrDiffVersion: Exception;
  ErrPacketTooSmall: Exception;
  ErrInvalidSignature: Exception;

type
  IPacketBody = interface
    ['{YOUR_GUID_HERE}']
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
    function Expired: Boolean;
  end;

  TMessage = class
  public
    Code: TCode;
    Id: TVNodeID;
    Body: IPacketBody;
    constructor Create;
    destructor Destroy; override;
    function Pack(Key: TBytes; out Hash: TBytes): TBytes;
  end;

  TPingPacketBody = class(TInterfacedObject, IPacketBody)
  public
    FromNode: TVNodeEndPoint;
    ToNode: TVNodeEndPoint;
    Net: Integer;
    Ext: TBytes;
    Time: Int64; // Unix timestamp
    constructor Create;
    destructor Destroy; override;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
    function Expired: Boolean;
  end;

  TPongPacketBody = class(TInterfacedObject, IPacketBody)
  public
    FromNode: TVNodeEndPoint;
    ToNode: TVNodeEndPoint;
    Net: Integer;
    Ext: TBytes;
    Echo: TBytes;
    Time: Int64; // Unix timestamp
    constructor Create;
    destructor Destroy; override;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
    function Expired: Boolean;
  end;

  TFindNodePacketBody = class(TInterfacedObject, IPacketBody)
  public
    Target: TVNodeID;
    Count: Integer;
    Time: Int64; // Unix timestamp
    constructor Create;
    destructor Destroy; override;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
    function Expired: Boolean;
  end;

  TNeighborsPacketBody = class(TInterfacedObject, IPacketBody)
  public
    Endpoints: TArray<TVNodeEndPoint>;
    Last: Boolean;
    Time: Int64; // Unix timestamp
    constructor Create;
    destructor Destroy; override;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
    function Expired: Boolean;
  end;

type
  TPacket = class
  public
    Code: TCode;
    Id: TVNodeID;
    Body: IPacketBody;
    Hash: TBytes;
    constructor Create;
    destructor Destroy; override;
  end;

function Pack(PrivKey: TBytes; Code: TCode; Payload: TBytes; out Hash: TBytes): TBytes;
function RetrievePacket: TPacket;
procedure RecyclePacket(Pkt: TPacket);
function Unpack(Data: TBytes; P: TPacket): Exception;
function DecodePacketBody(Code: TCode; Payload: TBytes): IPacketBody;

implementation

uses
  System.Math;

initialization
  ErrDiffVersion := Exception.Create('different packet version');
  ErrPacketTooSmall := Exception.Create('packet is too small');
  ErrInvalidSignature := Exception.Create('validate discovery packet error: invalid signature');
end.

{ TMessage }

constructor TMessage.Create;
begin
  inherited;
  Id := TVNodeID.Create;
end;

destructor TMessage.Destroy;
begin
  Body := nil; // Release interface
  Id.Free;
  inherited;
end;

function TMessage.Pack(Key: TBytes; out Hash: TBytes): TBytes;
var
  Payload: TBytes;
  Err: Exception;
begin
  Payload := Body.Serialize;
  Result := net.discovery.message.Pack(Key, Code, Payload, Hash);
end;

{ TPingPacketBody }

constructor TPingPacketBody.Create;
begin
  inherited;
end;

destructor TPingPacketBody.Destroy;
begin
  FromNode.Free;
  ToNode.Free;
  inherited;
end;

function TPingPacketBody.Serialize: TBytes;
var
  Pb: TPing;
  Buf: TBytes;
begin
  Pb := TPing.Create;
  try
    Pb.Net := Self.Net;
    Pb.Ext := Self.Ext;
    Pb.Time := Self.Time;

    if Assigned(Self.FromNode) then
    begin
      Buf := Self.FromNode.Serialize;
      Pb.From_ := Buf;
    end;

    if Assigned(Self.ToNode) then
    begin
      Buf := Self.ToNode.Serialize;
      Pb.To_ := Buf;
    end;

    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TPingPacketBody.Deserialize(Buf: TBytes);
var
  Pb: TPing;
  FromEP, ToEP: TVNodeEndPoint;
begin
  Pb := TPing.Create;
  try
    Pb.FromBytes(Buf);

    Self.Net := Pb.Net;
    Self.Ext := Pb.Ext;
    Self.Time := Pb.Time;

    if Length(Pb.From_) > 0 then
    begin
      FromEP := TVNodeEndPoint.Create;
      try
        FromEP.Deserialize(Pb.From_);
        Self.FromNode := FromEP;
      except
        // Handle deserialization error, set to nil
        Self.FromNode := nil;
      end;
    end
    else
      Self.FromNode := nil;

    if Length(Pb.To_) > 0 then
    begin
      ToEP := TVNodeEndPoint.Create;
      try
        ToEP.Deserialize(Pb.To_);
        Self.ToNode := ToEP;
      except
        // Handle deserialization error, set to nil
        Self.ToNode := nil;
      end;
    end
    else
      Self.ToNode := nil;
  finally
    Pb.Free;
  end;
end;

function TPingPacketBody.Expired: Boolean;
var
  NowUnix: Int64;
begin
  NowUnix := DateTimeToUnix(Now);
  if NowUnix < Self.Time then
    Result := False
  else
    Result := (NowUnix - Self.Time) > (2 * Expiration div 1000); // Convert Expiration to seconds
end;

{ TPongPacketBody }

constructor TPongPacketBody.Create;
begin
  inherited;
end;

destructor TPongPacketBody.Destroy;
begin
  FromNode.Free;
  ToNode.Free;
  inherited;
end;

function TPongPacketBody.Serialize: TBytes;
var
  Pb: TPong;
  Buf: TBytes;
begin
  Pb := TPong.Create;
  try
    Pb.Net := Self.Net;
    Pb.Ext := Self.Ext;
    Pb.Echo := Self.Echo;
    Pb.Time := Self.Time;

    if Assigned(Self.FromNode) then
    begin
      Buf := Self.FromNode.Serialize;
      Pb.From_ := Buf;
    end;

    if Assigned(Self.ToNode) then
    begin
      Buf := Self.ToNode.Serialize;
      Pb.To_ := Buf;
    end;

    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TPongPacketBody.Deserialize(Buf: TBytes);
var
  Pb: TPong;
  FromEP, ToEP: TVNodeEndPoint;
begin
  Pb := TPong.Create;
  try
    Pb.FromBytes(Buf);

    Self.Net := Pb.Net;
    Self.Ext := Pb.Ext;
    Self.Echo := Pb.Echo;
    Self.Time := Pb.Time;

    if Length(Pb.From_) > 0 then
    begin
      FromEP := TVNodeEndPoint.Create;
      try
        FromEP.Deserialize(Pb.From_);
        Self.FromNode := FromEP;
      except
        Self.FromNode := nil;
      end;
    end
    else
      Self.FromNode := nil;

    if Length(Pb.To_) > 0 then
    begin
      ToEP := TVNodeEndPoint.Create;
      try
        ToEP.Deserialize(Pb.To_);
        Self.ToNode := ToEP;
      except
        Self.ToNode := nil;
      end;
    end
    else
      Self.ToNode := nil;
  finally
    Pb.Free;
  end;
end;

function TPongPacketBody.Expired: Boolean;
var
  NowUnix: Int64;
begin
  NowUnix := DateTimeToUnix(Now);
  if NowUnix < Self.Time then
    Result := False
  else
    Result := (NowUnix - Self.Time) > (2 * Expiration div 1000); // Convert Expiration to seconds
end;

{ TFindNodePacketBody }

constructor TFindNodePacketBody.Create;
begin
  inherited;
  Target := TVNodeID.Create;
end;

destructor TFindNodePacketBody.Destroy;
begin
  Target.Free;
  inherited;
end;

function TFindNodePacketBody.Serialize: TBytes;
var
  Pb: TFindnode;
begin
  Pb := TFindnode.Create;
  try
    Pb.Target := Self.Target.Bytes;
    Pb.Count := Self.Count;
    Pb.Time := Self.Time;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TFindNodePacketBody.Deserialize(Buf: TBytes);
var
  Pb: TFindnode;
begin
  Pb := TFindnode.Create;
  try
    Pb.FromBytes(Buf);
    Self.Target := TVNodeID.FromBytes(Pb.Target);
    Self.Count := Pb.Count;
    Self.Time := Pb.Time;
  finally
    Pb.Free;
  end;
end;

function TFindNodePacketBody.Expired: Boolean;
var
  NowUnix: Int64;
begin
  NowUnix := DateTimeToUnix(Now);
  if NowUnix < Self.Time then
    Result := False
  else
    Result := (NowUnix - Self.Time) > (2 * Expiration div 1000); // Convert Expiration to seconds
end;

{ TNeighborsPacketBody }

constructor TNeighborsPacketBody.Create;
begin
  inherited;
  SetLength(Endpoints, 0);
end;

destructor TNeighborsPacketBody.Destroy;
var
  EP: TVNodeEndPoint;
begin
  for EP in Endpoints do
    EP.Free;
  inherited;
end;

function TNeighborsPacketBody.Serialize: TBytes;
var
  Pb: TNeighbors;
  EP: TVNodeEndPoint;
begin
  Pb := TNeighbors.Create;
  try
    Pb.Last := Self.Last;
    Pb.Time := Self.Time;
    SetLength(Pb.Nodes, Length(Self.Endpoints));
    for var I := 0 to High(Self.Endpoints) do
    begin
      EP := Self.Endpoints[I];
      Pb.Nodes[I] := EP.Serialize;
    end;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TNeighborsPacketBody.Deserialize(Buf: TBytes);
var
  Pb: TNeighbors;
  NodeBuf: TBytes;
  EP: TVNodeEndPoint;
begin
  Pb := TNeighbors.Create;
  try
    Pb.FromBytes(Buf);
    Self.Last := Pb.Last;
    Self.Time := Pb.Time;
    SetLength(Self.Endpoints, Length(Pb.Nodes));
    for var I := 0 to High(Pb.Nodes) do
    begin
      NodeBuf := Pb.Nodes[I];
      EP := TVNodeEndPoint.Create;
      try
        EP.Deserialize(NodeBuf);
        Self.Endpoints[I] := EP;
      except
        EP.Free;
        // Handle deserialization error, skip this endpoint
      end;
    end;
  finally
    Pb.Free;
  end;
end;

function TNeighborsPacketBody.Expired: Boolean;
var
  NowUnix: Int64;
begin
  NowUnix := DateTimeToUnix(Now);
  if NowUnix < Self.Time then
    Result := False
  else
    Result := (NowUnix - Self.Time) > (2 * Expiration div 1000); // Convert Expiration to seconds
end;

{ TPacket }

constructor TPacket.Create;
begin
  inherited;
  Id := TVNodeID.Create;
end;

destructor TPacket.Destroy;
begin
  Id.Free;
  Body := nil; // Release interface
  inherited;
end;

function Pack(PrivKey: TBytes; Code: TCode; Payload: TBytes; out Hash: TBytes): TBytes;
var
  Signature: TBytes;
  PublicKey: TBytes;
begin
  Hash := Crypto.Hash256(Payload);
  Signature := Ed25519.Sign(PrivKey, Payload);
  PublicKey := Ed25519.GetPublicKey(PrivKey);

  Result := TBytes.Create(Version, Code);
  Result := TBytes.Concat(Result, PublicKey);
  Result := TBytes.Concat(Result, Payload);
  Result := TBytes.Concat(Result, Signature);
end;

function RetrievePacket: TPacket;
begin
  Result := TPacket.Create;
end;

procedure RecyclePacket(Pkt: TPacket);
begin
  Pkt.Free;
end;

function Unpack(Data: TBytes; P: TPacket): Exception;
var
  C: TCode;
  IdBytes: TBytes;
  Payload: TBytes;
  Signature: TBytes;
  Valid: Boolean;
  FromId: TVNodeID;
  M: IPacketBody;
begin
  Result := nil;
  if Length(Data) < MinPacketLength then
    Exit(ErrPacketTooSmall);

  if Data[0] <> Version then
    Exit(ErrDiffVersion);

  C := Data[1];
  IdBytes := Copy(Data, 2, Length(TVNodeID.ZERO.Bytes));
  Payload := Copy(Data, PacketHeadLength, Length(Data) - PacketHeadLength - SignatureLength);
  Signature := Copy(Data, Length(Data) - SignatureLength, SignatureLength);

  Valid := Crypto.VerifySig(IdBytes, Payload, Signature);
  if not Valid then
    Exit(ErrInvalidSignature);

  FromId := TVNodeID.FromBytes(IdBytes);

  M := DecodePacketBody(C, Payload);
  if M = nil then
    Exit(Exception.Create(Format('decode packet error: unknown code %d', [C])));

  P.Code := C;
  P.Id := FromId;
  P.Body := M;
  P.Hash := Crypto.Hash256(Payload);

  Result := nil;
end;

function DecodePacketBody(Code: TCode; Payload: TBytes): IPacketBody;
var
  M: IPacketBody;
begin
  case Code of
    CodePing: M := TPingPacketBody.Create;
    CodePong: M := TPongPacketBody.Create;
    CodeFindnode: M := TFindNodePacketBody.Create;
    CodeNeighbors: M := TNeighborsPacketBody.Create;
  else
    Exit(nil);
  end;

  M.Deserialize(Payload);
  Result := M;
end;
