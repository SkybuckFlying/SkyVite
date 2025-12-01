unit Net.Codec;

interface

uses
  System.SysUtils, System.Classes, System.Net.Sockets,
  net.interface, libsnappy;

const
  MaxPayloadLength = 3;
  MaxPayloadSize = (1 shl (MaxPayloadLength * 8)) - 1;
  ReadMsgTimeout = 30 * 1000;
  WriteMsgTimeout = 30 * 1000;

var
  ErrMsgPayloadTooLarge: Exception;

type
  ICodec = interface(IMsgReadWriter)
    ['{E1E2E3E4-E5E6-E7E8-E9EA-EBECEDEEEFE1}']
    procedure Close;
    procedure SetReadTimeout(Timeout: Cardinal);
    procedure SetWriteTimeout(Timeout: Cardinal);
    procedure SetTimeout(Timeout: Cardinal);
    function Address: TSocketAddress;
  end;

  ICodecFactory = interface
    ['{F1F2F3F4-F5F6-F7F8-F9FA-FBFCFDFEFFE1}']
    function CreateCodec(Conn: TSocket): ICodec;
  end;

  TTransport = class(TInterfacedObject, ICodec)
  private
    FConn: TSocket;
    FReadTimeout: Cardinal;
    FWriteTimeout: Cardinal;
    FMinCompressLength: Integer;
    FReadHeadBuf: TBytes;
    FWriteHeadBuf: TBytes;
    FWriteBuf: TBytes;
    procedure ReadFull(var Buf: TBytes; Count: Integer);
  public
    constructor Create(Conn: TSocket; MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal);
    destructor Destroy; override;
    function ReadMsg: TMsg;
    procedure WriteMsg(Msg: TMsg);
    procedure Close;
    procedure SetReadTimeout(Timeout: Cardinal);
    procedure SetWriteTimeout(Timeout: Cardinal);
    procedure SetTimeout(Timeout: Cardinal);
    function Address: TSocketAddress;
  end;

  TTransportFactory = class(TInterfacedObject, ICodecFactory)
  private
    FMinCompressLength: Integer;
    FReadTimeout: Cardinal;
    FWriteTimeout: Cardinal;
  public
    constructor Create(MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal);
    function CreateCodec(Conn: TSocket): ICodec;
  end;

function NewTransport(Conn: TSocket; MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal): ICodec;
function Varint(Buf: TBytes): Cardinal;
function PutVarint(Buf: TBytes; N: Cardinal): Byte;

implementation

uses
  System.Math;

function IdLengthToBits(IdLength: Byte): Byte;
begin
  case IdLength of
    4: Result := 3;
  else
    Result := IdLength;
  end;
end;

function BitsToIdLength(Bits: Byte): Byte;
begin
  case Bits of
    3: Result := 4;
  else
    Result := Bits;
  end;
end;

function PutId(Id: TMsgId; Buf: TBytes): Byte;
begin
  if Id = 0 then
    Exit(0);

  if Id > 65535 then
  begin
    Buf[0] := Byte(Id shr 24);
    Buf[1] := Byte(Id shr 16);
    Buf[2] := Byte(Id shr 8);
    Buf[3] := Byte(Id);
    Exit(4);
  end;

  if Id > 255 then
  begin
    Buf[0] := Byte(Id shr 8);
    Buf[1] := Byte(Id);
    Exit(2);
  end;

  Buf[0] := Byte(Id);
  Result := 1;
end;

procedure RetrieveMeta(Meta: Byte; out ISize, LSize: Byte; out Compressed: Boolean);
begin
  ISize := BitsToIdLength(Meta shr 6);
  LSize := (Meta shl 2) shr 6;
  Compressed := ((Meta shl 4) shr 7) > 0;
end;

function StoreMeta(ISize, LSize: Byte; Compressed: Boolean): Byte;
begin
  Result := 0;
  Result := Result or (IdLengthToBits(ISize) shl 6);
  Result := Result or (LSize shl 4);
  if Compressed then
    Result := Result or 8;
end;

{ TTransport }

constructor TTransport.Create(Conn: TSocket; MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal);
begin
  FConn := Conn;
  FMinCompressLength := MinCompressLength;
  FReadTimeout := ReadTimeout;
  FWriteTimeout := WriteTimeout;
  SetLength(FReadHeadBuf, 4);
  SetLength(FWriteHeadBuf, 9);
end;

destructor TTransport.Destroy;
begin
  FConn.Free;
  inherited;
end;

procedure TTransport.ReadFull(var Buf: TBytes; Count: Integer);
var
  BytesRead, TotalBytesRead: Integer;
begin
  TotalBytesRead := 0;
  while TotalBytesRead < Count do
  begin
    BytesRead := FConn.Receive(Buf, Count - TotalBytesRead, TotalBytesRead);
    if BytesRead <= 0 then
      raise Exception.Create('connection closed');
    Inc(TotalBytesRead, BytesRead);
  end;
end;

function TTransport.ReadMsg: TMsg;
var
  Buf: TBytes;
  Meta: Byte;
  ISize, LSize: Byte;
  Compressed: Boolean;
  Length: Cardinal;
  PayloadUncompressed: TBytes;
begin
  FConn.ReadTimeout := FReadTimeout;
  Buf := FReadHeadBuf;
  ReadFull(Buf, 2);
  Meta := Buf[0];
  Result.Code := Buf[1];
  RetrieveMeta(Meta, ISize, LSize, Compressed);

  if ISize > 0 then
  begin
    ReadFull(Buf, ISize);
    Result.Id := Varint(Copy(Buf, 0, ISize));
  end;

  if LSize > 0 then
  begin
    ReadFull(Buf, LSize);
    Length := Varint(Copy(Buf, 0, LSize));
    if Length > MaxPayloadSize then
      raise ErrMsgPayloadTooLarge;
    SetLength(Result.Payload, Length);
    ReadFull(Result.Payload, Length);
  end;

  if Compressed then
  begin
    if SnappyUncompress(Result.Payload, PayloadUncompressed) <> SNAPPY_OK then
      raise Exception.Create('failed to decompress message payload');
    Result.Payload := PayloadUncompressed;
  end;
end;

procedure TTransport.WriteMsg(Msg: TMsg);
var
  Head: TBytes;
  HeadLen: Byte;
  ISize: Byte;
  Compress: Boolean;
  PayloadLen: Integer;
  PayloadCompressed: TBytes;
  LSize: Byte;
  WSize: Integer;
begin
  FConn.WriteTimeout := FWriteTimeout;
  Head := FWriteHeadBuf;
  Head[1] := Msg.Code;
  HeadLen := 2;
  ISize := PutId(Msg.Id, Copy(Head, 2, Length(Head) - 2));
  HeadLen := HeadLen + ISize;

  Compress := False;
  PayloadLen := Length(Msg.Payload);
  if PayloadLen > FMinCompressLength then
  begin
    if SnappyCompress(Msg.Payload, PayloadCompressed) = SNAPPY_OK then
    begin
      if Length(PayloadCompressed) < PayloadLen then
      begin
        Msg.Payload := PayloadCompressed;
        PayloadLen := Length(PayloadCompressed);
        Compress := True;
      end;
    end;
  end;

  LSize := PutVarint(Copy(Head, HeadLen, Length(Head) - HeadLen), PayloadLen);
  HeadLen := HeadLen + LSize;
  Head[0] := StoreMeta(ISize, LSize, Compress);

  WSize := FConn.Send(Head, HeadLen);
  if WSize <> HeadLen then
    raise Exception.Create('write too short');

  WSize := FConn.Send(Msg.Payload, PayloadLen);
  if WSize <> PayloadLen then
    raise Exception.Create('write too short');
end;

procedure TTransport.Close;
begin
  FConn.Close;
end;

procedure TTransport.SetReadTimeout(Timeout: Cardinal);
begin
  FReadTimeout := Timeout;
end;

procedure TTransport.SetWriteTimeout(Timeout: Cardinal);
begin
  FWriteTimeout := Timeout;
end;

procedure TTransport.SetTimeout(Timeout: Cardinal);
begin
  FReadTimeout := Timeout;
  FWriteTimeout := Timeout;
end;

function TTransport.Address: TSocketAddress;
begin
  Result := FConn.RemoteAddress;
end;

{ TTransportFactory }

constructor TTransportFactory.Create(MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal);
begin
  FMinCompressLength := MinCompressLength;
  FReadTimeout := ReadTimeout;
  FWriteTimeout := WriteTimeout;
end;

function TTransportFactory.CreateCodec(Conn: TSocket): ICodec;
begin
  Result := NewTransport(Conn, FMinCompressLength, FReadTimeout, FWriteTimeout);
end;

function NewTransport(Conn: TSocket; MinCompressLength: Integer; ReadTimeout, WriteTimeout: Cardinal): ICodec;
begin
  Result := TTransport.Create(Conn, MinCompressLength, ReadTimeout, WriteTimeout);
end;

function Varint(Buf: TBytes): Cardinal;
var
  T, I: Integer;
begin
  Result := 0;
  T := Length(Buf);
  for I := 0 to T - 1 do
    Result := Result or (Buf[I] shl ((T - I - 1) * 8));
end;

function PutVarint(Buf: TBytes; N: Cardinal): Byte;
var
  I: Byte;
begin
  Result := 0;
  if N = 0 then
    Exit;
  Result := 1;
  while (N shr (Result * 8)) > 0 do
    Inc(Result);
  for I := 0 to Result - 1 do
    Buf[I] := Byte(N shr ((Result - I - 1) * 8));
end;

initialization
  ErrMsgPayloadTooLarge := Exception.Create('message payload is too large');
end.
