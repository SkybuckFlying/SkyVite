unit Common.Helper.Math.Integer;

interface

uses
  System.SysUtils;

type
  TIntegerHelper = class
  public
    class function SafeMul(ParaX, ParaY: UInt64): record Value: UInt64; Overflow: Boolean; end;
    class function SafeAdd(ParaX, ParaY: UInt64): record Value: UInt64; Overflow: Boolean; end;
    class function Min(ParaX, ParaY: UInt64): UInt64;
    class function Max(ParaX, ParaY: UInt64): UInt64;
    class function MinInt(ParaX, ParaY: Integer): Integer;
    class function MinInt64(ParaX, ParaY: Int64): Int64;
  end;

implementation

const
  ConstMaxUint64 = High(UInt64);

{ TIntegerHelper }

// SafeMul returns multiplication result and whether overflow occurred.
class function TIntegerHelper.SafeMul(ParaX, ParaY: UInt64): record Value: UInt64; Overflow: Boolean; end;
begin
  if (ParaX = 0) or (ParaY = 0) then
  begin
    Result.Value := 0;
    Result.Overflow := False;
  end
  else
  begin
    Result.Value := ParaX * ParaY;
    Result.Overflow := ParaY > ConstMaxUint64 div ParaX;
  end;
end;

// SafeAdd returns the result and whether overflow occurred.
class function TIntegerHelper.SafeAdd(ParaX, ParaY: UInt64): record Value: UInt64; Overflow: Boolean; end;
begin
  Result.Value := ParaX + ParaY;
  Result.Overflow := ParaY > ConstMaxUint64 - ParaX;
end;

class function TIntegerHelper.Min(ParaX, ParaY: UInt64): UInt64;
begin
  if ParaX < ParaY then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaY;
  end;
end;

class function TIntegerHelper.Max(ParaX, ParaY: UInt64): UInt64;
begin
  if ParaX > ParaY then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaY;
  end;
end;

class function TIntegerHelper.MinInt(ParaX, ParaY: Integer): Integer;
begin
  if ParaX < ParaY then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaY;
  end;
end;

class function TIntegerHelper.MinInt64(ParaX, ParaY: Int64): Int64;
begin
  if ParaX < ParaY then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaY;
  end;
end;

end.