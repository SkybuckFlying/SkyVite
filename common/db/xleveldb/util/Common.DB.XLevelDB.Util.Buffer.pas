unit common.db.xleveldb.util.buffer;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TBuffer = class
  private
    FBuf: TBytes;
    FOff: Integer;
    FBootstrap: array [0 .. 63] of Byte;
    function Grow(N: Integer): Integer;
  public
    constructor Create; overload;
    constructor Create(ABuf: TBytes); overload;
    function Bytes: TBytes;
    function ToString: string;
    function Len: Integer;
    procedure Truncate(N: Integer);
    procedure Reset;
    function Alloc(N: Integer): TBytes;
    procedure Grow(N: Integer);
    function Write(const P: TBytes): Integer;
    function ReadFrom(R: TStream): Int64;
    procedure WriteTo(W: TStream);
    procedure WriteByte(C: Byte);
    function Read(var P: TBytes): Integer;
    function Next(N: Integer): TBytes;
    function ReadByte(out C: Byte): Boolean;
    function ReadBytes(Delim: Byte; out Line: TBytes): Boolean;
  end;

function NewBuffer(ABuf: TBytes): TBuffer;

implementation

const
  MinRead = 512;

{ TBuffer }

constructor TBuffer.Create;
begin
  inherited;
end;

constructor TBuffer.Create(ABuf: TBytes);
begin
  inherited Create;
  FBuf := ABuf;
end;

function TBuffer.Bytes: TBytes;
begin
  SetLength(Result, Length(FBuf) - FOff);
  if Length(Result) > 0 then
    System.Move(FBuf[FOff], Result[0], Length(Result));
end;

function TBuffer.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(FBuf, FOff, Length(FBuf) - FOff);
end;

function TBuffer.Len: Integer;
begin
  Result := Length(FBuf) - FOff;
end;

procedure TBuffer.Truncate(N: Integer);
begin
  if (N < 0) or (N > Len) then
    raise Exception.Create('leveldb/util.Buffer: truncation out of range');
  if N = 0 then
    FOff := 0;
  SetLength(FBuf, FOff + N);
end;

procedure TBuffer.Reset;
begin
  Truncate(0);
end;

function TBuffer.Grow(N: Integer): Integer;
var
  M: Integer;
  NewBuf: TBytes;
begin
  M := Len;
  if (M = 0) and (FOff <> 0) then
    Truncate(0);

  if Length(FBuf) + N > System.Capacity(FBuf) then
  begin
    if (FBuf = nil) and (N <= Length(FBootstrap)) then
      NewBuf := Copy(FBootstrap)
    else if M + N <= System.Capacity(FBuf) div 2 then
    begin
      System.Move(FBuf[FOff], FBuf[0], M);
      NewBuf := FBuf;
      SetLength(NewBuf, M);
    end
    else
    begin
      SetLength(NewBuf, 2 * System.Capacity(FBuf) + N);
      System.Move(FBuf[FOff], NewBuf[0], M);
    end;
    FBuf := NewBuf;
    FOff := 0;
  end;
  SetLength(FBuf, FOff + M + N);
  Result := FOff + M;
end;

function TBuffer.Alloc(N: Integer): TBytes;
var
  M: Integer;
begin
  if N < 0 then
    raise Exception.Create('leveldb/util.Buffer.Alloc: negative count');
  M := Grow(N);
  SetLength(Result, N);
  System.Move(FBuf[M], Result[0], N);
end;

procedure TBuffer.Grow(N: Integer);
var
  M: Integer;
begin
  if N < 0 then
    raise Exception.Create('leveldb/util.Buffer.Grow: negative count');
  M := Grow(N);
  SetLength(FBuf, M);
end;

function TBuffer.Write(const P: TBytes): Integer;
var
  M: Integer;
begin
  M := Grow(Length(P));
  System.Move(P[0], FBuf[M], Length(P));
  Result := Length(P);
end;

function TBuffer.ReadFrom(R: TStream): Int64;
var
  Free, M: Integer;
  NewBuf: TBytes;
begin
  Result := 0;
  if FOff >= Length(FBuf) then
    Truncate(0);

  while True do
  begin
    Free := System.Capacity(FBuf) - Length(FBuf);
    if Free < MinRead then
    begin
      NewBuf := FBuf;
      if FOff + Free < MinRead then
        SetLength(NewBuf, 2 * System.Capacity(FBuf) + MinRead);
      System.Move(FBuf[FOff], NewBuf[0], Length(FBuf) - FOff);
      FBuf := NewBuf;
      SetLength(FBuf, Length(FBuf) - FOff);
      FOff := 0;
    end;
    M := R.Read(FBuf, Length(FBuf), System.Capacity(FBuf) - Length(FBuf));
    SetLength(FBuf, Length(FBuf) + M);
    Inc(Result, M);
    if M = 0 then // EOF
      Break;
  end;
end;

procedure TBuffer.WriteTo(W: TStream);
var
  NBytes, M: Integer;
begin
  if FOff < Length(FBuf) then
  begin
    NBytes := Len;
    M := W.Write(FBuf, FOff, NBytes);
    if M > NBytes then
      raise Exception.Create('leveldb/util.Buffer.WriteTo: invalid Write count');
    Inc(FOff, M);
    if M <> NBytes then
      raise Exception.Create('short write');
  end;
  Truncate(0);
end;

procedure TBuffer.WriteByte(C: Byte);
var
  M: Integer;
begin
  M := Grow(1);
  FBuf[M] := C;
end;

function TBuffer.Read(var P: TBytes): Integer;
begin
  if FOff >= Length(FBuf) then
  begin
    Truncate(0);
    if Length(P) = 0 then
      Result := 0
    else
      Result := -1; // EOF
    Exit;
  end;
  Result := Min(Length(P), Len);
  System.Move(FBuf[FOff], P[0], Result);
  Inc(FOff, Result);
end;

function TBuffer.Next(N: Integer): TBytes;
var
  M: Integer;
begin
  M := Len;
  if N > M then
    N := M;
  SetLength(Result, N);
  System.Move(FBuf[FOff], Result[0], N);
  Inc(FOff, N);
end;

function TBuffer.ReadByte(out C: Byte): Boolean;
begin
  if FOff >= Length(FBuf) then
  begin
    Truncate(0);
    Result := False;
    Exit;
  end;
  C := FBuf[FOff];
  Inc(FOff);
  Result := True;
end;

function TBuffer.ReadBytes(Delim: Byte; out Line: TBytes): Boolean;
var
  I, EndPos: Integer;
begin
  I := -1;
  for EndPos := FOff to Length(FBuf) - 1 do
  begin
    if FBuf[EndPos] = Delim then
    begin
      I := EndPos - FOff;
      Break;
    end;
  end;

  EndPos := FOff + I + 1;
  if I < 0 then
  begin
    EndPos := Length(FBuf);
    Result := False;
  end
  else
    Result := True;

  SetLength(Line, EndPos - FOff);
  System.Move(FBuf[FOff], Line[0], Length(Line));
  FOff := EndPos;
end;

function NewBuffer(ABuf: TBytes): TBuffer;
begin
  Result := TBuffer.Create(ABuf);
end;

end.
