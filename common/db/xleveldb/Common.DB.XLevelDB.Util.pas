unit Common.Db.XLevelDb.Util;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Comparer,
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
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.Db.XLevelDb.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Version,
  System.Generics.Collections,
  System.SysUtils;

function Shorten(const ParaStr: string): string;
function ShortenB(ParaBytes: Integer): string;
function SShortenB(ParaBytes: Integer): string;
function SInt(ParaX: Integer): string;
function MinInt(ParaA, ParaB: Integer): Integer;
function MaxInt(ParaA, ParaB: Integer): Integer;
procedure SortFds(ParaFds: TArray<TFileDesc>);
function EnsureBuffer(ParaB: TBytes; ParaN: Integer): TBytes;

implementation

const
  BUnits: array[0..4] of string = ('', 'Ki', 'Mi', 'Gi', 'Ti');

function Shorten(const ParaStr: string): string;
begin
  if Length(ParaStr) <= 8 then
  begin
    Result := ParaStr;
  end
  else
  begin
    Result := Copy(ParaStr, 1, 3) + '..' + Copy(ParaStr, Length(ParaStr) - 2, 3);
  end;
end;

function ShortenB(ParaBytes: Integer): string;
var
  vI: Integer;
begin
  vI := 0;
  while (ParaBytes > 1024) and (vI < 4) do
  begin
    ParaBytes := ParaBytes div 1024;
    Inc(vI);
  end;
  Result := Format('%d%sB', [ParaBytes, BUnits[vI]]);
end;

function SShortenB(ParaBytes: Integer): string;
var
  vI: Integer;
  vSign: string;
begin
  if ParaBytes = 0 then
  begin
    Result := '~';
    Exit;
  end;
  vSign := '+';
  if ParaBytes < 0 then
  begin
    vSign := '-';
    ParaBytes := -ParaBytes;
  end;
  vI := 0;
  while (ParaBytes > 1024) and (vI < 4) do
  begin
    ParaBytes := ParaBytes div 1024;
    Inc(vI);
  end;
  Result := Format('%s%d%sB', [vSign, ParaBytes, BUnits[vI]]);
end;

function SInt(ParaX: Integer): string;
var
  vSign: string;
begin
  if ParaX = 0 then
  begin
    Result := '~';
    Exit;
  end;
  vSign := '+';
  if ParaX < 0 then
  begin
    vSign := '-';
    ParaX := -ParaX;
  end;
  Result := Format('%s%d', [vSign, ParaX]);
end;

function MinInt(ParaA, ParaB: Integer): Integer;
begin
  if ParaA < ParaB then
  begin
    Result := ParaA;
  end
  else
  begin
    Result := ParaB;
  end;
end;

function MaxInt(ParaA, ParaB: Integer): Integer;
begin
  if ParaA > ParaB then
  begin
    Result := ParaA;
  end
  else
  begin
    Result := ParaB;
  end;
end;

procedure SortFds(ParaFds: TArray<TFileDesc>);
begin
  TArray.Sort<TFileDesc>(ParaFds, TComparer<TFileDesc>.Construct(
    function(const Left, Right: TFileDesc): Integer
    begin
      if Left.Num < Right.Num then
        Result := -1
      else if Left.Num > Right.Num then
        Result := 1
      else
        Result := 0;
    end));
end;

function EnsureBuffer(ParaB: TBytes; ParaN: Integer): TBytes;
begin
  if Length(ParaB) < ParaN then
  begin
    SetLength(Result, ParaN);
  end
  else
  begin
    Result := ParaB;
    SetLength(Result, ParaN);
  end;
end;

end.
