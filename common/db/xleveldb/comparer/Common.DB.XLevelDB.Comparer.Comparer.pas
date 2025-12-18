unit Common.Db.XLevelDB.Comparer.Comparer;

interface

uses
  Common.DB.XLevelDB.Comparer.Bytes.Comparer,
  GoToDelphi.Helpers.BigInt,
  System.SysUtils;

type
  // BasicComparer is the interface that wraps the basic Compare method.
  IBasicComparer = interface
    ['{A4A3A2D2-8B5D-4C5D-9B5A-3D1B7A6D2C1B}']
    // Compare returns -1, 0, or +1 depending on whether a is 'less than',
    // 'equal to' or 'greater than' b. The two arguments can only be 'equal'
    // if their contents are exactly equal. Furthermore, the empty slice
    // must be 'less than' any non-empty slice.
    function Compare(const ParaA, ParaB: TBytes): integer;
  end;

  // Comparer defines a total ordering over the space of []byte keys: a 'less
  // than' relationship.
  IComparer = interface(IBasicComparer)
    ['{B5A9A86A-287A-4E6D-861E-5A692B4DA20D}']
    // Name returns name of the comparer.
    //
    // The Level-DB on-disk format stores the comparer name, and opening a
    // database with a different comparer from the one it was created with
    // will result in an error.
    //
    // An implementation to a new name whenever the comparer implementation
    // changes in a way that will cause the relative ordering of any two keys
    // to change.
    //
    // Names starting with "leveldb." are reserved and should not be used
    // by any users of this package.
    function Name: string;

    // Bellow are advanced functions used used to reduce the space requirements
    // for internal data structures such as index blocks.

    // Separator appends a sequence of bytes x to dst such that a <= x && x < b,
    // where 'less than' is consistent with Compare. An implementation should
    // return nil if x equal to a.
    //
    // Either contents of a or b should not by any means modified. Doing so
    // may cause corruption on the internal state.
    function Separator(const ParaDst, ParaA, ParaB: TBytes): TBytes;

    // Successor appends a sequence of bytes x to dst such that x >= b, where
    // 'less than' is consistent with Compare. An implementation should return
    // nil if x equal to b.
    //
    // Contents of b should not by any means modified. Doing so may cause
    // corruption on the internal state.
    function Successor(const ParaDst, ParaB: TBytes): TBytes;
  end;

  TBytesComparer = class(TInterfacedObject, IComparer)
  public
    function Compare(const ParaA, ParaB: TBytes): integer;
    function Name: string;
    function Separator(const ParaDst, ParaA, ParaB: TBytes): TBytes;
    function Successor(const ParaDst, ParaB: TBytes): TBytes;
  end;

var
  DefaultComparer: IComparer;

implementation

uses
  System.Types;

{ TBytesComparer }

function TBytesComparer.Compare(const ParaA, ParaB: TBytes): integer;
begin
  Result := TBytes.Compare(ParaA, ParaB);
end;

function TBytesComparer.Name: string;
begin
  Result := 'leveldb.BytewiseComparator';
end;

function TBytesComparer.Separator(const ParaDst, ParaA, ParaB: TBytes): TBytes;
var
  vIndex, vN: integer;
  vC: byte;
  vDst: TBytes;
begin
  vDst := ParaDst;
  vN := Length(ParaA);
  if vN > Length(ParaB) then
  begin
    vN := Length(ParaB);
  end;
  vIndex := 0;
  while (vIndex < vN) and (ParaA[vIndex] = ParaB[vIndex]) do
  begin
    inc(vIndex);
  end;
  if vIndex >= vN then
  begin
    // Do not shorten if one string is a prefix of the other
  end
  else
  begin
    vC := ParaA[vIndex];
    if (vC < $FF) and (vC + 1 < ParaB[vIndex]) then
    begin
      SetLength(vDst, vIndex + 1);
      System.Move(ParaA[0], vDst[0], vIndex + 1);
      vDst[vIndex] := vDst[vIndex] + 1;
      Result := vDst;
      Exit;
    end;
  end;
  Result := nil;
end;

function TBytesComparer.Successor(const ParaDst, ParaB: TBytes): TBytes;
var
  vIndex: integer;
  vC: byte;
  vDst: TBytes;
begin
  vDst := ParaDst;
  for vIndex := 0 to Length(ParaB) - 1 do
  begin
    vC := ParaB[vIndex];
    if vC <> $FF then
    begin
      SetLength(vDst, vIndex + 1);
      System.Move(ParaB[0], vDst[0], vIndex + 1);
      vDst[vIndex] := vDst[vIndex] + 1;
      Result := vDst;
      Exit;
    end;
  end;
  Result := nil;
end;

initialization
  DefaultComparer := TBytesComparer.Create;
end.
