unit Tools.MockConn.MockConn;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Threading, GoToDelphi.Helpers.TChannel;

type
  TMockConnAddress = class
  private
    FName: string;
  public
    constructor Create(Name: string);
    function Network: string;
    function ToString: string; override;
  end;

  IMockConn = interface
    ['{E1E2E3E4-E5E6-E7E8-E9EAEBECEDEF}']
    function Read(var Buf: TBytes; Count: Integer): Integer;
    function Write(const Buf: TBytes; Count: Integer): Integer;
    procedure Close;
    function LocalAddr: TMockConnAddress;
    function RemoteAddr: TMockConnAddress;
    procedure SetDeadline(T: TDateTime);
    procedure SetReadDeadline(T: TDateTime);
    procedure SetWriteDeadline(T: TDateTime);
  end;

  TMockConn = class(TInterfacedObject, IMockConn)
  private
    FClosed: Integer;
    FName: string;
    FRName: string;
    FRead: TChannel<Byte>;
    FWrite: TChannel<Byte>;
    FTerm: TEvent;
    FRTimeout: TDateTime;
    FWTimeout: TDateTime;
  public
    constructor Create(Name, RName: string; Read, Write: TChannel<Byte>);
    destructor Destroy; override;
    function Read(var Buf: TBytes; Count: Integer): Integer;
    function Write(const Buf: TBytes; Count: Integer): Integer;
    procedure Close;
    function LocalAddr: TMockConnAddress;
    function RemoteAddr: TMockConnAddress;
    procedure SetDeadline(T: TDateTime);
    procedure SetReadDeadline(T: TDateTime);
    procedure SetWriteDeadline(T: TDateTime);
  end;

procedure Pipe(out C1, C2: IMockConn);

implementation

{ TMockConnAddress }

constructor TMockConnAddress.Create(Name: string);
begin
  FName := Name;
end;

function TMockConnAddress.Network: string;
begin
  Result := 'mock';
end;

function TMockConnAddress.ToString: string;
begin
  Result := FName;
end;

{ TMockConn }

constructor TMockConn.Create(Name, RName: string; Read, Write: TChannel<Byte>);
begin
  FName := Name;
  FRName := RName;
  FRead := Read;
  FWrite := Write;
  FTerm := TEvent.Create(nil, True, False, '');
end;

destructor TMockConn.Destroy;
begin
  FTerm.Free;
  inherited;
end;

function TMockConn.Read(var Buf: TBytes; Count: Integer): Integer;
var
  Timer: ITask;
  Timeout: Boolean;
  B: Byte;
begin
  Timeout := False;
  if FRTimeout <> 0 then
  begin
    if Now > FRTimeout then
      raise Exception.Create('read timeout');
    Timer := TTask.Run(procedure
    begin
      TThread.Sleep(Round((FRTimeout - Now) * MSecsPerDay));
      Timeout := True;
    end);
  end;

  Result := 0;
  while Result < Count do
  begin
    if Timeout then
      raise Exception.Create('read timeout');
    if FTerm.WaitFor(0) = TWaitResult.wrSignaled then
      raise Exception.Create('mock conn closed');

    if FRead.TryReceive(B) then
    begin
      Buf[Result] := B;
      Inc(Result);
    end;
  end;
end;

function TMockConn.Write(const Buf: TBytes; Count: Integer): Integer;
var
  Timer: ITask;
  Timeout: Boolean;
begin
  Timeout := False;
  if FWTimeout <> 0 then
  begin
    if Now > FWTimeout then
      raise Exception.Create('write timeout');
    Timer := TTask.Run(procedure
    begin
      TThread.Sleep(Round((FWTimeout - Now) * MSecsPerDay));
      Timeout := True;
    end);
  end;

  Result := 0;
  while Result < Count do
  begin
    if Timeout then
      raise Exception.Create('write timeout');
    if FTerm.WaitFor(0) = TWaitResult.wrSignaled then
      raise Exception.Create('mock conn closed');

    FWrite.Send(Buf[Result]);
    Inc(Result);
  end;
end;

procedure TMockConn.Close;
begin
  if TInterlocked.CompareExchange(FClosed, 1, 0) = 0 then
    FTerm.SetEvent;
end;

function TMockConn.LocalAddr: TMockConnAddress;
begin
  Result := TMockConnAddress.Create(FName);
end;

function TMockConn.RemoteAddr: TMockConnAddress;
begin
  Result := TMockConnAddress.Create(FRName);
end;

procedure TMockConn.SetDeadline(T: TDateTime);
begin
  FRTimeout := T;
  FWTimeout := T;
end;

procedure TMockConn.SetReadDeadline(T: TDateTime);
begin
  FRTimeout := T;
end;

procedure TMockConn.SetWriteDeadline(T: TDateTime);
begin
  FWTimeout := T;
end;

procedure Pipe(out C1, C2: IMockConn);
var
  Ch1, Ch2: TChannel<Byte>;
begin
  Ch1 := TChannel<Byte>.Create(10);
  Ch2 := TChannel<Byte>.Create(10);
  C1 := TMockConn.Create('c1', 'c2', Ch1, Ch2);
  C2 := TMockConn.Create('c2', 'c1', Ch2, Ch1);
end;

end.