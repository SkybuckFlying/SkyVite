unit common.db.xleveldb.util.range;

interface

uses
  System.SysUtils;

type
  PRange = ^TRange;
  TRange = record
    Start: TBytes;
    Limit: TBytes;
  end;

function BytesPrefix(const APrefix: TBytes): PRange;

implementation

function BytesPrefix(const APrefix: TBytes): PRange;
var
  Limit: TBytes;
  I: Integer;
  C: Byte;
begin
  for I := Length(APrefix) - 1 downto 0 do
  begin
    C := APrefix[I];
    if C < $FF then
    begin
      SetLength(Limit, I + 1);
      System.Move(APrefix[0], Limit[0], I + 1);
      Limit[I] := C + 1;
      Break;
    end;
  end;
  New(Result);
  Result.Start := APrefix;
  Result.Limit := Limit;
end;

end.
