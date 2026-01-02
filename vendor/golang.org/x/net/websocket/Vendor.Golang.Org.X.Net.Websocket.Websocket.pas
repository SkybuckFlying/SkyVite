unit Vendor.Golang.Org.X.Net.Websocket.Websocket;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

const
  ProtocolVersionHybi13 = 13;
  SupportedProtocolVersion = '13';

  ContinuationFrame = 0;
  TextFrame = 1;
  BinaryFrame = 2;
  CloseFrame = 8;
  PingFrame = 9;
  PongFrame = 10;

type
  TProtocolError = class(Exception)
  public
    ErrorString: string;
    constructor Create(AErrorString: string);
  end;

  TConfig = record
    Location: IUrl;
    Origin: IUrl;
    Protocol: TArray<string>;
    Version: Integer;
    // TlsConfig: ITlsConfig;
    // Header: IHeader;
    // Dialer: IDialer;
  end;
  PConfig = ^TConfig;

  TConn = class
  private
    FConfig: PConfig;
    // ...
  public
    function Read(var AMsg: TBytes): Integer;
    function Write(const AMsg: TBytes): Integer;
    procedure Close;
  end;
  PConn = TConn;

implementation

{ TProtocolError }

constructor TProtocolError.Create(AErrorString: string);
begin
  inherited Create(AErrorString);
  ErrorString := AErrorString;
end;

{ TConn }

function TConn.Read(var AMsg: TBytes): Integer;
begin
  Result := 0;
end;

function TConn.Write(const AMsg: TBytes): Integer;
begin
  Result := 0;
end;

procedure TConn.Close;
begin
end;

end.
