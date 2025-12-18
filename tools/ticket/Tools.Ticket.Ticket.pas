unit Tools.Ticket.Ticket;

interface

uses
  GoToDelphi.Helpers.TChannel,
  System.Classes,
  System.SysUtils,
  System.Threading,
  Tools.Ticket.Ticket.Test;

type
  ETicketClosed = class(Exception)
  public
    constructor Create;
  end;

  ITicket = interface
    ['{A1A2A3A4-A5A6-A7A8-A9AAABACADAE}']
    procedure Take;
    procedure Return;
    function Remainder: Integer;
    function Total: Integer;
    function Close: Exception;
    procedure Reset;
  end;

  TTicket = class(TInterfacedObject, ITicket)
  private
    FTotal: Integer;
    FChannel: TChannel<Byte>;
    FClosed: Integer;
    function IsClosed: Boolean;
  public
    constructor Create(ATotal: Integer);
    destructor Destroy; override;
    procedure Take;
    procedure Return;
    function Remainder: Integer;
    function Total: Integer;
    function Close: Exception;
    procedure Reset;
  end;

function NewTicket(ATotal: Integer): ITicket;

implementation

{ ETicketClosed }

constructor ETicketClosed.Create;
begin
  inherited Create('ticket has already closed');
end;

{ TTicket }

constructor TTicket.Create(ATotal: Integer);
var
  I: Integer;
begin
  FTotal := ATotal;
  FChannel := TChannel<Byte>.Create(ATotal);
  for I := 0 to ATotal - 1 do
  begin
    FChannel.Send(0);
  end;
  FClosed := 0;
end;

destructor TTicket.Destroy;
begin
  FChannel.Free;
  inherited;
end;

function TTicket.IsClosed: Boolean;
begin
  Result := TInterlocked.Read(FClosed) = 1;
end;

procedure TTicket.Take;
begin
  if IsClosed then
    Exit;

  FChannel.Receive;
end;

procedure TTicket.Return;
begin
  if IsClosed then
    Exit;

  FChannel.Send(0);
end;

function TTicket.Remainder: Integer;
begin
  Result := FChannel.Count;
end;

function TTicket.Total: Integer;
begin
  Result := FTotal;
end;

function TTicket.Close: Exception;
begin
  Result := nil;
  if TInterlocked.CompareExchange(FClosed, 1, 0) = 0 then
  begin
    FChannel.Close;
  end
  else
  begin
    Result := ETicketClosed.Create;
  end;
end;

procedure TTicket.Reset;
var
  I: Integer;
begin
  FChannel.Free;
  FChannel := TChannel<Byte>.Create(FTotal);
  for I := 0 to FTotal - 1 do
  begin
    FChannel.Send(0);
  end;
  TInterlocked.Exchange(FClosed, 0);
end;

function NewTicket(ATotal: Integer): ITicket;
begin
  Result := TTicket.Create(ATotal);
end;

end.
