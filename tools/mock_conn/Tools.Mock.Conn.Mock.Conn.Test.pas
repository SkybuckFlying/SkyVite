unit Tools.MockConn.MockConn.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Threading,
  Tools.MockConn.MockConn;

type
  [TestFixture]
  TMockConnTests = class(TObject)
  public
    [Test]
    procedure TestMockConn_Read;
    [Test]
    procedure TestMockConn_SetReadDeadline;
  end;

implementation

{ TMockConnTests }

procedure TMockConnTests.TestMockConn_Read;
var
  C1, C2: IMockConn;
  Writer, Reader: ITask;
  BufWrite: TBytes;
  BufRead: TBytes;
begin
  Pipe(C1, C2);

  Writer := TTask.Run(procedure
  begin
    BufWrite := TEncoding.UTF8.GetBytes('hello world1 hello world2 hello world3 hello world4 hello world5');
    while True do
    begin
      try
        var N := C1.Write(BufWrite, Length(BufWrite));
        if N <> Length(BufWrite) then
          Fail('too short');
      except
        on E: Exception do
        begin
          if E.Message = 'mock conn closed' then Break;
          raise;
        end;
      end;
    end;
  end);

  Reader := TTask.Run(procedure
  begin
    SetLength(BufRead, 11);
    while True do
    begin
      try
        var N := C2.Read(BufRead, Length(BufRead));
        // System.SysUtils.WriteLn(TEncoding.UTF8.GetString(BufRead, 0, N));
      except
        on E: Exception do
        begin
          if E.Message = 'mock conn closed' then Break;
          raise;
        end;
      end;
    end;
  end);

  TTask.Run(procedure
  begin
    TThread.Sleep(3000);
    C1.Close;
    C2.Close;
  end);

  TTask.WaitForAll([Writer, Reader]);
end;

procedure TMockConnTests.TestMockConn_SetReadDeadline;
var
  C1, C2: IMockConn;
  Buf: TBytes;
  N: Integer;
  Err: Exception;
begin
  Pipe(C1, C2);
  try
    C1.SetReadDeadline(Now + EncodeTime(0, 0, 2, 0));
  except
    on E: Exception do
      Fail(Format('SetReadDeadline should not panic: %s', [E.Message]));
  end;

  SetLength(Buf, 1024);
  N := 0;
  Err := nil;
  try
    N := C1.Read(Buf, Length(Buf));
  except
    on E: Exception do
      Err := E;
  end;

  Assert.IsNotNull(Err, 'should read timeout');
  Assert.AreEqual('read timeout', Err.Message, 'error message should be "read timeout"');
  Assert.AreEqual(0, N, 'should read 0 bytes');
end;

end.