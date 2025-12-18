unit RPC_Utils_Test;

interface

procedure RunUtilsTest;

implementation

uses
  System.SysUtils,
  System.Character,
  RPC, // Assumes NewID function is here
  DUnitX.TestFramework;

procedure TestNewID;
var
  I: Integer;
  Id: string;
  C: Char;
begin
  for I := 1 to 100 do
  begin
    Id := NewID;
    Assert.IsTrue(Id.StartsWith('0x'), 'ID should start with "0x", got ' + Id);

    Id := Id.Substring(2);
    Assert.IsTrue((Length(Id) > 0) and (Length(Id) <= 32), 'Invalid ID length: ' + IntToStr(Length(Id)));

    for C in Id do
    begin
      Assert.IsTrue(IsHexDigit(C), 'Invalid character in ID: ' + C);
    end;
  end;
end;

procedure RunUtilsTest;
begin
  TestNewID;
end;

end.
