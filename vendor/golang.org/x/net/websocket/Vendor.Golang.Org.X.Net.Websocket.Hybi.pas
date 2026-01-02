unit Vendor.Golang.Org.X.Net.Websocket.Hybi;

interface

uses
  System.SysUtils, System.Classes,
  Vendor.Golang.Org.X.Net.Websocket.Websocket;

const
  WebsocketGUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

type
  THybiFrameHeader = record
    Fin: Boolean;
    Rsv: array[0..2] of Boolean;
    OpCode: Byte;
    Length: Int64;
    MaskingKey: TBytes;
    Data: TMemoryStream;
  end;

implementation

end.
