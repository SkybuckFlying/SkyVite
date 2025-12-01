unit net.message;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  common.types, common.vitepb, interfaces.core, net.interface;

const
  CodeDisconnect = 1;
  CodeHandshake = 2;
  CodeControlFlow = 3;
  CodeHeartBeat = 4;
  CodeGetHashList = 25;
  CodeHashList = 26;
  CodeGetSnapshotBlocks = 27;
  CodeSnapshotBlocks = 28;
  CodeGetAccountBlocks = 29;
  CodeAccountBlocks = 30;
  CodeNewSnapshotBlock = 31;
  CodeNewAccountBlock = 32;
  CodeSyncHandshake = 60;
  CodeSyncHandshakeOK = 61;
  CodeSyncRequest = 62;
  CodeSyncReady = 63;
  CodeException = 127;
  CodeTrace = 128;

type
  TCode = Byte;
  TMsgId = Cardinal;

  TMsg = record
    Code: TCode;
    Id: TMsgId;
    Payload: TBytes;
    ReceivedAt: Int64;
    Sender: IPeer;
    procedure Recycle;
  end;

  IMsgReader = interface
    ['{YOUR_GUID_HERE}']
    function ReadMsg: TMsg;
  end;

  IMsgWriter = interface
    ['{YOUR_GUID_HERE}']
    procedure WriteMsg(Msg: TMsg);
  end;

  IMsgReadWriter = interface(IMsgReader, IMsgWriter)
    ['{YOUR_GUID_HERE}']
  end;

  IMsgWriteCloser = interface(IMsgWriter)
    ['{YOUR_GUID_HERE}']
    procedure Close;
  end;

  ISerializable = interface
    ['{YOUR_GUID_HERE}']
    function Serialize: TBytes;
  end;

  TGetSnapshotBlocks = class
  public
    From: THashHeight;
    Count: UInt64;
    Forward: Boolean;
    function ToString: string;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  TSnapshotBlocks = class
  public
    Blocks: TArray<ISnapshotBlock>;
    function ToString: string;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  TGetAccountBlocks = class
  public
    Address: TAddress;
    From: THashHeight;
    Count: UInt64;
    Forward: Boolean;
    function ToString: string;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  TAccountBlocks = class
  public
    Blocks: TArray<IAccountBlock>;
    TTL: Integer;
    function ToString: string;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  TNewSnapshotBlock = class
  public
    Block: ISnapshotBlock;
    TTL: Integer;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  TNewAccountBlock = class
  public
    Block: IAccountBlock;
    TTL: Integer;
    function Serialize: TBytes;
    procedure Deserialize(Buf: TBytes);
  end;

  THashHeightPoint = class
  public
    HashHeight: THashHeight;
    Size: UInt64;
    function Proto: TViteHashHeightPoint;
    procedure DeProto(Pb: TViteHashHeightPoint);
  end;

  THashHeightPointList = class
  public
    Points: TArray<THashHeightPoint>;
    function Serialize: TBytes;
    procedure Deserialize(Data: TBytes);
  end;

  TGetHashHeightList = class
  public
    From: TArray<THashHeight>;
    Step: UInt64;
    To: UInt64;
    function Serialize: TBytes;
    procedure Deserialize(Data: TBytes);
  end;

function Disconnect(C: IMsgWriteCloser; Err: Exception): Exception;

implementation

uses
  System.Net.Socket;

var
  ErrDeserialize: Exception;
  ErrMissingPoints: Exception;
  ErrNilPoint: Exception;

procedure TMsg.Recycle;
begin
  // No-op in Delphi
end;

function Disconnect(C: IMsgWriteCloser; Err: Exception): Exception;
var
  Msg: TMsg;
  Pe: TPeerError;
begin
  Msg.Code := CodeDisconnect;
  if (Err <> nil) and (Err is TPeerError) then
  begin
    Pe := Err as TPeerError;
    Msg.Payload := Pe.Serialize;
  end
  else
    Msg.Payload := TPeerError.Create(PeerQuitting).Serialize;
  Result := nil;
  try
    C.WriteMsg(Msg);
    C.Close;
  except
    on E: Exception do
      Result := E;
  end;
end;

{ TGetSnapshotBlocks }

function TGetSnapshotBlocks.ToString: string;
var
  FromStr: string;
begin
  if From.Hash.IsZero then
    FromStr := IntToStr(From.Height)
  else
    FromStr := From.Hash.ToString;
  Result := 'GetSnapshotBlocks<' + FromStr + '/' + IntToStr(Count) + '/' + BoolToStr(Forward, True) + '>';
end;

function TGetSnapshotBlocks.Serialize: TBytes;
var
  Pb: TGetSnapshotBlocks;
begin
  Pb := TGetSnapshotBlocks.Create;
  try
    Pb.From := From.Proto;
    Pb.Count := Count;
    Pb.Forward := Forward;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TGetSnapshotBlocks.Deserialize(Buf: TBytes);
var
  Pb: TGetSnapshotBlocks;
begin
  Pb := TGetSnapshotBlocks.Create;
  try
    Pb.FromBytes(Buf);
    if Pb.From = nil then
      raise ErrDeserialize;
    From.DeProto(Pb.From);
    Count := Pb.Count;
    Forward := Pb.Forward;
  finally
    Pb.Free;
  end;
end;

{ TSnapshotBlocks }

function TSnapshotBlocks.ToString: string;
begin
  Result := 'SnapshotBlocks<' + IntToStr(Length(Blocks)) + '>';
end;

function TSnapshotBlocks.Serialize: TBytes;
var
  Pb: TSnapshotBlocks;
  I: Integer;
  Block: ISnapshotBlock;
begin
  Pb := TSnapshotBlocks.Create;
  try
    SetLength(Pb.Blocks, Length(Blocks));
    for I := 0 to Length(Blocks) - 1 do
    begin
      Block := Blocks[I];
      Pb.Blocks[I] := Block.Proto;
    end;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TSnapshotBlocks.Deserialize(Buf: TBytes);
var
  Pb: TSnapshotBlocks;
  J: Integer;
  Bp: TViteSnapshotBlock;
  Block: ISnapshotBlock;
  Err: Exception;
begin
  Pb := TSnapshotBlocks.Create;
  try
    Pb.FromBytes(Buf);
    SetLength(Blocks, Length(Pb.Blocks));
    J := 0;
    for Bp in Pb.Blocks do
    begin
      if Bp = nil then
        raise ErrDeserialize;
      Block := TSnapshotBlock.Create;
      Err := Block.DeProto(Bp);
      if Err <> nil then
        raise Err;
      Blocks[J] := Block;
      Inc(J);
    end;
  finally
    Pb.Free;
  end;
end;

{ TGetAccountBlocks }

function TGetAccountBlocks.ToString: string;
var
  FromStr: string;
begin
  if From.Hash.IsZero then
    FromStr := IntToStr(From.Height)
  else
    FromStr := From.Hash.ToString;
  Result := 'GetAccountBlocks<' + FromStr + '/' + IntToStr(Count) + '/' + BoolToStr(Forward, True) + '>';
end;

function TGetAccountBlocks.Serialize: TBytes;
var
  Pb: TGetAccountBlocks;
begin
  Pb := TGetAccountBlocks.Create;
  try
    Pb.Address := Address.Bytes;
    Pb.From := From.Proto;
    Pb.Count := Count;
    Pb.Forward := Forward;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TGetAccountBlocks.Deserialize(Buf: TBytes);
var
  Pb: TGetAccountBlocks;
begin
  Pb := TGetAccountBlocks.Create;
  try
    Pb.FromBytes(Buf);
    if Pb.From = nil then
      raise ErrDeserialize;
    From.DeProto(Pb.From);
    Count := Pb.Count;
    Forward := Pb.Forward;
    Address.FromBytes(Pb.Address);
  finally
    Pb.Free;
  end;
end;

{ TAccountBlocks }

function TAccountBlocks.ToString: string;
begin
  Result := 'AccountBlocks<' + IntToStr(Length(Blocks)) + '>';
end;

function TAccountBlocks.Serialize: TBytes;
var
  Pb: TAccountBlocks;
  I: Integer;
  Block: IAccountBlock;
begin
  Pb := TAccountBlocks.Create;
  try
    SetLength(Pb.Blocks, Length(Blocks));
    for I := 0 to Length(Blocks) - 1 do
    begin
      Block := Blocks[I];
      Pb.Blocks[I] := Block.Proto;
    end;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TAccountBlocks.Deserialize(Buf: TBytes);
var
  Pb: TAccountBlocks;
  J: Integer;
  Bp: TViteAccountBlock;
  Block: IAccountBlock;
  Err: Exception;
begin
  Pb := TAccountBlocks.Create;
  try
    Pb.FromBytes(Buf);
    SetLength(Blocks, Length(Pb.Blocks));
    J := 0;
    for Bp in Pb.Blocks do
    begin
      if Bp = nil then
        raise ErrDeserialize;
      Block := TAccountBlock.Create;
      Err := Block.DeProto(Bp);
      if Err <> nil then
        raise Err;
      Blocks[J] := Block;
      Inc(J);
    end;
  finally
    Pb.Free;
  end;
end;

{ TNewSnapshotBlock }

function TNewSnapshotBlock.Serialize: TBytes;
var
  Pb: TNewSnapshotBlock;
begin
  Pb := TNewSnapshotBlock.Create;
  try
    Pb.Block := Block.Proto;
    Pb.TTL := TTL;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TNewSnapshotBlock.Deserialize(Buf: TBytes);
var
  Pb: TNewSnapshotBlock;
  Err: Exception;
begin
  Pb := TNewSnapshotBlock.Create;
  try
    Pb.FromBytes(Buf);
    if Pb.Block = nil then
      raise ErrDeserialize;
    Block := TSnapshotBlock.Create;
    Err := Block.DeProto(Pb.Block);
    if Err <> nil then
      raise Err;
    TTL := Pb.TTL;
  finally
    Pb.Free;
  end;
end;

{ TNewAccountBlock }

function TNewAccountBlock.Serialize: TBytes;
var
  Pb: TNewAccountBlock;
begin
  Pb := TNewAccountBlock.Create;
  try
    Pb.Block := Block.Proto;
    Pb.TTL := TTL;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TNewAccountBlock.Deserialize(Buf: TBytes);
var
  Pb: TNewAccountBlock;
  Err: Exception;
begin
  Pb := TNewAccountBlock.Create;
  try
    Pb.FromBytes(Buf);
    if Pb.Block = nil then
      raise ErrDeserialize;
    Block := TAccountBlock.Create;
    Err := Block.DeProto(Pb.Block);
    if Err <> nil then
      raise Err;
    TTL := Pb.TTL;
  finally
    Pb.Free;
  end;
end;

{ THashHeightPoint }

function THashHeightPoint.Proto: TViteHashHeightPoint;
begin
  Result := TViteHashHeightPoint.Create;
  Result.Point := TViteHashHeight.Create;
  Result.Point.Hash := HashHeight.Hash.Bytes;
  Result.Point.Height := HashHeight.Height;
  Result.Size := Size;
end;

procedure THashHeightPoint.DeProto(Pb: TViteHashHeightPoint);
var
  Err: Exception;
begin
  if (Pb = nil) or (Pb.Point = nil) then
    raise ErrNilPoint;
  HashHeight.Hash := THash.FromBytes(Pb.Point.Hash, Err);
  if Err <> nil then
    raise Err;
  HashHeight.Height := Pb.Point.Height;
  Size := Pb.Size;
end;

{ THashHeightPointList }

function THashHeightPointList.Serialize: TBytes;
var
  Pb: THashHeightList;
  I: Integer;
  H: THashHeightPoint;
begin
  Pb := THashHeightList.Create;
  try
    SetLength(Pb.Points, Length(Points));
    for I := 0 to Length(Points) - 1 do
    begin
      H := Points[I];
      Pb.Points[I] := H.Proto;
    end;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure THashHeightPointList.Deserialize(Data: TBytes);
var
  Pb: THashHeightList;
  J: Integer;
  H: TViteHashHeightPoint;
  Hh: THashHeightPoint;
  Err: Exception;
begin
  Pb := THashHeightList.Create;
  try
    Pb.FromBytes(Data);
    SetLength(Points, Length(Pb.Points));
    J := 0;
    for H in Pb.Points do
    begin
      if H = nil then
        raise ErrNilPoint;
      Hh := THashHeightPoint.Create;
      Hh.DeProto(H);
      Points[J] := Hh;
      Inc(J);
    end;
  finally
    Pb.Free;
  end;
end;

{ TGetHashHeightList }

function TGetHashHeightList.Serialize: TBytes;
var
  Pb: TGetHashHeightList;
  I: Integer;
  H: THashHeight;
begin
  Pb := TGetHashHeightList.Create;
  try
    SetLength(Pb.From, Length(From));
    for I := 0 to Length(From) - 1 do
    begin
      H := From[I];
      Pb.From[I] := H.Proto;
    end;
    Pb.Step := Step;
    Pb.To := To;
    Result := Pb.ToBytes;
  finally
    Pb.Free;
  end;
end;

procedure TGetHashHeightList.Deserialize(Data: TBytes);
var
  Pb: TGetHashHeightList;
  J: Integer;
  H: TViteHashHeight;
  Hh: THashHeight;
  Err: Exception;
begin
  Pb := TGetHashHeightList.Create;
  try
    Pb.FromBytes(Data);
    if Length(Pb.From) = 0 then
      raise ErrMissingPoints;
    SetLength(From, Length(Pb.From));
    J := 0;
    for H in Pb.From do
    begin
      if H = nil then
        raise ErrNilPoint;
      Hh := THashHeight.Create;
      Hh.DeProto(H);
      From[J] := Hh;
      Inc(J);
    end;
    Step := Pb.Step;
    To := Pb.To;
  finally
    Pb.Free;
  end;
end;

initialization
  ErrDeserialize := Exception.Create('deserialize error');
  ErrMissingPoints := Exception.Create('missing from points');
  ErrNilPoint := Exception.Create('nil HashHeightPoint');
end.
