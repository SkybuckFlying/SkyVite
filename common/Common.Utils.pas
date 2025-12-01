unit Common.Utils;

interface

uses
<<<<<<< HEAD
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

// SyncMapLen calculates the length of a dictionary.
// Note: Unlike Go's sync.Map, the caller must ensure that the dictionary
// is accessed in a thread-safe manner (e.g., by using TThreadedDictionary).
function SyncMapLen<TKey, TValue>(const ParaM: TDictionary<TKey, TValue>): UInt64;

// ToJson serializes an item to a JSON string.
function ToJson<T>(const ParaItem: T): string;

// Crit logs a critical error, sleeps, and then logs a critical error again,
// which will terminate the application via the logger.
procedure Crit(const ParaMsg: string; const ParaCtx: array of const);

// Min returns the smaller of x or y.
function Min(const ParaX, ParaY: Integer): Integer;

// Max returns the larger of x or y.
function Max(const ParaX, ParaY: Integer): Integer;

implementation

uses
  System.Threading,
  System.JSON,
  Log15;

function SyncMapLen<TKey, TValue>(const ParaM: TDictionary<TKey, TValue>): UInt64;
begin
  if not Assigned(ParaM) then
  begin
    Result := 0;
  end
  else
  begin
    Result := ParaM.Count;
  end;
end;

function ToJson<T>(const ParaItem: T): string;
begin
  try
    Result := TJson.ObjectToJsonString(ParaItem);
  except
    on E: Exception do
    begin
      Result := 'err: ' + E.Message;
    end;
  end;
end;

procedure Crit(const ParaMsg: string; const ParaCtx: array of const);
var
  vLog: ILogger;
begin
  // In a real application, a logger instance should be managed more centrally.
  vLog := NewLogger('module', 'crit');
  vLog.Error(ParaMsg, ParaCtx);
  WriteLn(ParaMsg);
  TThread.Sleep(2000);
  // The Crit level in log15 is designed to be fatal.
  vLog.Crit(ParaMsg, ParaCtx);
end;

function Min(const ParaX, ParaY: Integer): Integer;
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

function Max(const ParaX, ParaY: Integer): Integer;
begin
  if ParaX > ParaY then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaY;
  end;
=======
  System.SysUtils;

function BytesEqual(b1, b2: TBytes): Boolean;
function GetUvarint(const Data: TBytes; var Offset: Integer; out BytesRead: Integer): UInt64;
function PutUvarint(var Data: TBytes; var Offset: Integer; Value: UInt64): Integer;
function EnsureBuffer(Dst: TBytes; N: Integer): TBytes;

implementation

function BytesEqual(b1, b2: TBytes): Boolean;
var
  i: Integer;
begin
  if Length(b1) <> Length(b2) then
    Exit(False);
  for i := 0 to Length(b1) - 1 do
    if b1[i] <> b2[i] then
      Exit(False);
  Result := True;
end;

function GetUvarint(const Data: TBytes; var Offset: Integer; out BytesRead: Integer): UInt64;
var
  Result64: UInt64;
  Shift: Integer;
  B: Byte;
begin
  Result64 := 0;
  Shift := 0;
  BytesRead := 0;
  while Offset < Length(Data) do
  begin
    B := Data[Offset];
    Inc(Offset);
    Inc(BytesRead);
    Result64 := Result64 or (UInt64(B and $7F) shl Shift);
    if (B and $80) = 0 then
    begin
      Result := Result64;
      Exit;
    end;
    Shift := Shift + 7;
    if Shift >= 64 then
    begin
      // Overflow or invalid varint
      Result := 0;
      BytesRead := 0;
      Exit;
    end;
  end;
  // Incomplete varint
  Result := 0;
  BytesRead := 0;
end;

function PutUvarint(var Data: TBytes; var Offset: Integer; Value: UInt64): Integer;
var
  StartOffset: Integer;
  Buf: TBytes;
  I: Integer;
begin
  StartOffset := Offset;
  SetLength(Buf, 10); // Max 10 bytes for UInt64
  I := 0;
  while True do
  begin
    Buf[I] := Byte(Value and $7F);
    Value := Value shr 7;
    if Value = 0 then
    begin
      if I > 0 then
        Buf[I-1] := Buf[I-1] or $80;
      Break;
    end;
    Buf[I] := Buf[I] or $80;
    Inc(I);
  end;

  // Ensure Data has enough capacity and copy bytes
  if (Offset + I + 1) > Length(Data) then
    SetLength(Data, Offset + I + 1); // Extend if needed

  Move(Buf[0], Data[Offset], I + 1);
  Inc(Offset, I + 1);
  Result := I + 1;
end;

function EnsureBuffer(Dst: TBytes; N: Integer): TBytes;
var
  OldLen: Integer;
  NewCap: Integer;
begin
  OldLen := Length(Dst);
  if CapLength(Dst) - OldLen < N then
  begin
    NewCap := OldLen + N + OldLen div 1; // Simple grow strategy
    SetLength(Dst, OldLen, NewCap); // Resize with new capacity
  end;
  Result := Dst;
>>>>>>> origin/AI0003
end;

end.
