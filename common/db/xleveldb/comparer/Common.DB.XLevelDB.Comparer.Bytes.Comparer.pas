unit bytes_comparer;

interface

uses
  SysUtils, Classes, comparer;

type
  TBytesComparer = class(TInterfacedObject, IComparer)
  public
    function Compare(const A, B: TBytes): Integer;
    function Name: string;
    function Separator(Dst, A, B: TBytes): TBytes;
    function Successor(Dst, B: TBytes): TBytes;
  end;

var
  DefaultComparer: IComparer;

implementation

function TBytesComparer.Compare(const A, B: TBytes): Integer;
begin
  // Stub: Use CompareMem or custom logic
  if Length(A) < Length(B) then
    Result := -1
  else if Length(A) > Length(B) then
    Result := 1
  else if CompareMem(@A[0], @B[0], Length(A)) then
    Result := 0
  else
    Result := CompareStr(BytesToString(A), BytesToString(B));
end;

function TBytesComparer.Name: string;
begin
  Result := 'leveldb.BytewiseComparator';
end;

function TBytesComparer.Separator(Dst, A, B: TBytes): TBytes;
var
  I, N: Integer;
begin
  N := Length(A);
  if N > Length(B) then N := Length(B);
  I := 0;
  while (I < N) and (A[I] = B[I]) do Inc(I);
  if I >= N then
    Result := nil
  else if (A[I] < $FF) and (A[I] + 1 < B[I]) then
  begin
    SetLength(Result, I + 1);
    Move(A[0], Result[0], I + 1);
    Inc(Result[I]);
    Exit;
  end;
  Result := nil;
end;

function TBytesComparer.Successor(Dst, B: TBytes): TBytes;
var
  I: Integer;
begin
  for I := 0 to High(B) do
    if B[I] <> $FF then
    begin
      SetLength(Result, I + 1);
      Move(B[0], Result[0], I + 1);
      Inc(Result[I]);
      Exit;
    end;
  Result := nil;
end;

initialization
  DefaultComparer := TBytesComparer.Create;

end.
