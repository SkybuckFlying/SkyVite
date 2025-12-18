<<<<<<< HEAD
unit Common.Db.XLevelDB.Comparer;
=======
unit Common.Db.XLevelDb.Comparer;
>>>>>>> origin/AI0004

interface

uses
  <<<<<<< HEAD,
  Common.DB.XLevelDB.Batch,
  Common.Db.XLevelDB.Comparer.Comparer,
  Common.DB.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Iter,
  Common.DB.XLevelDB.DB.Snapshot,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.Db.XLevelDB.Internal,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.SysUtils;

type
  IInternalComparer = interface(IComparer)
    ['{E7E6D57A-5B5A-4B4F-8B3E-1F2B0E8D7F3B}']
  end;

  TInternalComparer = class(TInterfacedObject, IInternalComparer)
  private
    mUcmp: IComparer;
    function GetName: string;
    function Compare(a, b: TBytes): Integer;
    function Separator(dst, a, b: TBytes): TBytes;
    function Successor(dst, b: TBytes): TBytes;
  public
    constructor Create(ParaUcmp: IComparer);
  end;

function NewIComparer(ParaUcmp: IComparer): IInternalComparer;

implementation

{ TInternalComparer }

constructor TInternalComparer.Create(ParaUcmp: IComparer);
begin
  inherited Create;
  mUcmp := ParaUcmp;
end;

function TInternalComparer.GetName: string;
begin
  Result := mUcmp.Name;
end;

function TInternalComparer.Compare(a, b: TBytes): Integer;
var
  m, n: UInt64;
begin
  Result := mUcmp.Compare(UKey(a), UKey(b));
  if Result = 0 then
  begin
    m := Num(a);
    n := Num(b);
    if m > n then
      Result := -1
    else if m < n then
      Result := 1;
  end;
end;

function TInternalComparer.Separator(dst, a, b: TBytes): TBytes;
=======
  Common.Db.XLevelDb.Internal;

type
  IComparer = interface
    ['{F0A1B2C3-D4E5-F6A7-B8C9-0D1E2F3A4B5C}']
    function Compare(ParaA, ParaB: TInternalKey): Integer;
    function UCompare(ParaA, ParaB: TBytes): Integer;
    function Name: string;
    function Separator(ParaA, ParaB: TBytes): TBytes;
    function Successor(ParaB: TBytes): TBytes;
  end;

  TComparer = class(TInterfacedObject, IComparer)
  public
    function Compare(ParaA, ParaB: TInternalKey): Integer;
    function UCompare(ParaA, ParaB: TBytes): Integer;
    function Name: string;
    function Separator(ParaA, ParaB: TBytes): TBytes;
    function Successor(ParaB: TBytes): TBytes;
  end;

implementation

uses
  System.Classes;

{ TComparer }

function TComparer.Compare(ParaA, ParaB: TInternalKey): Integer;
begin
  Result := UCompare(UKey(ParaA), UKey(ParaB));
  if Result = 0 then
  begin
    // Compare sequence numbers
  end;
end;

function TComparer.UCompare(ParaA, ParaB: TBytes): Integer;
>>>>>>> origin/AI0004
var
  vLen: Integer;
  vI: Integer;
begin
<<<<<<< HEAD
  ua := UKey(a);
  ub := UKey(b);
  dst := mUcmp.Separator(dst, ua, ub);
  if (dst <> nil) and (Length(dst) < Length(ua)) and (mUcmp.Compare(ua, dst) < 0) then
  begin
    // Append earliest possible number.
    Result := dst + KeyMaxNumBytes;
  end
  else
    Result := nil;
end;

function TInternalComparer.Successor(dst, b: TBytes): TBytes;
var
  ub: TBytes;
begin
  ub := UKey(b);
  dst := mUcmp.Successor(dst, ub);
  if (dst <> nil) and (Length(dst) < Length(ub)) and (mUcmp.Compare(ub, dst) < 0) then
  begin
    // Append earliest possible number.
    Result := dst + KeyMaxNumBytes;
  end
  else
    Result := nil;
end;

function NewIComparer(ParaUcmp: IComparer): IInternalComparer;
begin
  Result := TInternalComparer.Create(ParaUcmp);
=======
  vLen := Min(Length(ParaA), Length(ParaB));
  for vI := 0 to vLen - 1 do
  begin
    if ParaA[vI] < ParaB[vI] then
    begin
      Result := -1;
      Exit;
    end
    else if ParaA[vI] > ParaB[vI] then
    begin
      Result := 1;
      Exit;
    end;
  end;

  if Length(ParaA) < Length(ParaB) then
  begin
    Result := -1;
  end
  else if Length(ParaA) > Length(ParaB) then
  begin
    Result := 1;
  end
  else
  begin
    Result := 0;
  end;
end;

function TComparer.Name: string;
begin
  Result := 'leveldb.BytewiseComparator';
>>>>>>> origin/AI0004
end;

function TComparer.Separator(ParaA, ParaB: TBytes): TBytes;
var
  vI, vLen: Integer;
begin
  vLen := Min(Length(ParaA), Length(ParaB));
  SetLength(Result, vLen);
  for vI := 0 to vLen - 1 do
  begin
    if (ParaA[vI] <> ParaB[vI]) and (ParaA[vI] + 1 < ParaB[vI]) then
    begin
      SetLength(Result, vI + 1);
      Result[vI] := ParaA[vI] + 1;
      Exit;
    end;
    Result[vI] := ParaA[vI];
  end;
end;

function TComparer.Successor(ParaB: TBytes): TBytes;
var
  vI: Integer;
begin
  for vI := 0 to Length(ParaB) - 1 do
  begin
    if ParaB[vI] <> $FF then
    begin
      SetLength(Result, vI + 1);
      System.Move(ParaB[0], Result[0], vI);
      Result[vI] := ParaB[vI] + 1;
      Exit;
    end;
  end;
  Result := ParaB;
end;

end.
