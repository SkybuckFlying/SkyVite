unit Tools.Ticket.Ticket.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TChannel,
  System.Classes,
  System.SysUtils,
  System.Threading,
  Tools.Ticket.Ticket;

type
  [TestFixture]
  TTicketTests = class(TObject)
  public
    [Test]
    procedure TestTicket_Remainder;
    [Test]
    procedure TestTicket_Take;
    [Test]
    procedure TestTicket_Return;
    [Test]
    procedure TestTicket_Close;
    [Test]
    procedure TestTicket_Reset;
  end;

implementation

{ TTicketTests }

procedure TTicketTests.TestTicket_Remainder;
const
  Total = 5;
  I = 3;
var
  Pool: ITicket;
  J: Integer;
begin
  Pool := NewTicket(Total);
  for J := 0 to I - 1 do
  begin
    Pool.Take;
  end;

  Assert.AreEqual(Total - I, Pool.Remainder, Format('Remainder should be %d, but get %d', [Total - I, Pool.Remainder]));

  Pool.Return;
  Assert.AreEqual(Total - I + 1, Pool.Remainder, Format('Remainder should be %d, but get %d', [Total - I + 1, Pool.Remainder]));
end;

procedure TTicketTests.TestTicket_Take;
const
  Total = 5;
var
  Pool: ITicket;
  Ch: TChannel<Integer>;
  I: Integer;
  Task: ITask;
  Value: Integer;
begin
  Pool := NewTicket(Total);
  Ch := TChannel<Integer>.Create(1);
  try
    Task := TTask.Run(procedure
    begin
      for I := 0 to Total - 1 do
      begin
        Pool.Take;
      end;
      Pool.Take;
      Ch.Send(1);
    end);

    if Ch.TryReceive(Value, 3000) then
      Fail('Take should be blocked');
  finally
    Ch.Free;
  end;
end;

procedure TTicketTests.TestTicket_Return;
const
  Total = 5;
var
  Pool: ITicket;
  I: Integer;
begin
  Pool := NewTicket(Total);
  for I := 0 to Total - 1 do
  begin
    Pool.Take;
  end;
  for I := 0 to Total - 1 do
  begin
    Pool.Return;
  end;
  Assert.AreEqual(Total, Pool.Remainder, Format('should be %d resources in pool, but get %d', [Total, Pool.Remainder]));
end;

procedure TTicketTests.TestTicket_Close;
const
  Total = 5;
var
  Pool: ITicket;
  Err: Exception;
  I: Integer;
begin
  Pool := NewTicket(Total);
  Err := Pool.Close;
  Assert.IsNull(Err, Format('First close should not return error: %s', [Err.Message]));

  Err := Pool.Close;
  Assert.IsNotNull(Err, 'Second close should return error');
  Assert.IsType<ETicketClosed>(Err, 'Error should be ETicketClosed');

  Pool.Reset;
  for I := 0 to Total - 2 do
  begin
    Pool.Take;
  end;

  Pool.Close;
  for I := 0 to Total - 1 do
  begin
    Pool.Return;
  end;

  Assert.AreEqual(2, Pool.Remainder, 'Remainder after close and return should be 2');
end;

procedure TTicketTests.TestTicket_Reset;
const
  Total = 5;
var
  Pool: ITicket;
  I: Integer;
begin
  Pool := NewTicket(Total);
  for I := 0 to Total - 1 do
  begin
    Pool.Take;
  end;

  Assert.AreEqual(0, Pool.Remainder, 'Remainder should be 0 after all tickets taken');

  Pool.Reset;
  Assert.AreEqual(Total, Pool.Remainder, 'Remainder should be total after reset');
end;

end.
