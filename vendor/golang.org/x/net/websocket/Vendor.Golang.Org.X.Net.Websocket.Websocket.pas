unit Vendor.Golang.Org.X.Net.Websocket.Websocket;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

const
  ProtocolVersionHybi13 = 13;
  ContinuationFrame = 0;
  TextFrame         = 1;
  BinaryFrame       = 2;
  CloseFrame        = 8;
  PingFrame         = 9;
  PongFrame         = 10;

type
  TConfig = class
    Location: string;
    Origin: string;
    Protocol: TArray<string>;
    Version: Integer;
  end;

  TConn = class
  private
    FConfig: TConfig;
    FRio: TCriticalSection;
    FWio: TCriticalSection;
  public
    constructor Create(AConfig: TConfig);
    destructor Destroy; override;
    function Read(var Msg: TBytes): Integer;
    function Write(const Msg: TBytes): Integer;
    procedure Close;
  end;

implementation

{ TConn }

constructor TConn.Create(AConfig: TConfig);
begin
  FConfig := AConfig;
  FRio := TCriticalSection.Create;
  FWio := TCriticalSection.Create;
end;

destructor TConn.Destroy;
begin
  FRio.Free;
  FWio.Free;
  inherited;
end;

function TConn.Read(var Msg: TBytes): Integer;
begin
  Result := 0;
end;

function TConn.Write(const Msg: TBytes): Integer;
begin
  Result := 0;
end;

procedure TConn.Close;
begin
end;

end.
