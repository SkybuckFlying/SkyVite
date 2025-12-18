unit Common.DB.XLevelDB.DBUtil;

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
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.DB.XLevelDB.Iterator,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Opt,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session // For TSession TVersion,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TDB = class; // Forward declaration for circular reference

  // Reader is the interface that wraps basic Get and NewIterator methods.
  // This interface implemented by both DB and Snapshot.
  IReader = interface
    ['{B5B0E6A2-6C6C-4A5A-9B8E-3A9E2B6C8B6F}'] // New GUID
    function Get(const ParaKey: TBytes; ParaRo: TReadOptions): TBytes;
    function NewIterator(ParaSlice: TUtilRange; ParaRo: TReadOptions): IIterator;
  end;

  // Sizes is list of size.
  TSizes = TArray<Int64>;

  function Sum(const ParaSizes: TSizes): Int64;

  TDBUtil = class helper for TDB
  public
    procedure Log(const ParaV: array of const);
    procedure Logf(const ParaFormat: string; const ParaV: array of const);
    function CheckAndCleanFiles: Exception;
  end;

implementation

function Sum(const ParaSizes: TSizes): Int66;
var
  vSize: Int64;
begin
  Result := 0;
  for vSize in ParaSizes do
  begin
    Result := Result + vSize;
  end;
end;

{ TDBUtil }

procedure TDBUtil.Log(const ParaV: array of const);
begin
  Self.FS.Log(ParaV);
end;

procedure TDBUtil.Logf(const ParaFormat: string; const ParaV: array of const);
begin
  Self.FS.Logf(ParaFormat, ParaV);
end;

function TDBUtil.CheckAndCleanFiles: Exception;
var
  v: TVersion;
  vTMap: TDictionary<Int64, Boolean>;
  vTables: TArray<TTable>;
  vT: TTable;
  vFds: TArray<TFileDesc>;
  vFd: TFileDesc;
  vKeep: Boolean;
  vNt: Integer;
  vRem: TList<TFileDesc>;
  vMfds: TList<TFileDesc>;
  vNum: Int64;
  vPresent: Boolean;
begin
  Result := nil;
  v := Self.FS.Version;
  try
    vTMap := TDictionary<Int64, Boolean>.Create;
    try
      for vTables in v.Levels do
      begin
        for vT in vTables do
        begin
          vTMap.AddOrSetValue(vT.Fd.Num, False);
        end;
      end;

      vFds := Self.FS.Stor.List(TFileType.TypeAll);

      vNt := 0;
      vRem := TList<TFileDesc>.Create;
      try
        for vFd in vFds do
        begin
          vKeep := True;
          case vFd.FType of
            TFileType.TypeManifest:
              vKeep := vFd.Num >= Self.FS.FManifestFd.Num;
            TFileType.TypeJournal:
              if not Self.FFrozenJournalFd.Zero then
              begin
                vKeep := vFd.Num >= Self.FFrozenJournalFd.Num
              end
              else
              begin
                vKeep := vFd.Num >= Self.FJournalFd.Num;
              end;
            TFileType.TypeTable:
              if vTMap.TryGetValue(vFd.Num, vPresent) then
              begin
                vKeep := True;
                vTMap[vFd.Num] := True;
                Inc(vNt);
              end
              else
              begin
                vKeep := False;
              end;
          end;

          if not vKeep then
          begin
            vRem.Add(vFd);
          end;
        end;

        if vNt <> vTMap.Count then
        begin
          vMfds := TList<TFileDesc>.Create;
          try
            for vNum in vTMap.Keys do
            begin
              if not vTMap[vNum] then
              begin
                vMfds.Add(TFileDesc.Create(TFileType.TypeTable, vNum));
                Self.Logf('db@janitor table missing @%d', [vNum]);
              end;
            end;
            Result := EErrCorrupted.Create(TFileDesc.Create(TFileType.TypeInvalid, 0), EErrMissingFiles.Create(vMfds.ToArray));
            Exit;
          finally
            vMfds.Free;
          end;
        end;

        Self.Logf('db@janitor F·%d G·%d', [Length(vFds), vRem.Count]);
        for vFd in vRem do
        begin
          Self.Logf('db@janitor removing %s-%d', [vFd.FType.ToString, vFd.Num]);
          Result := Self.FS.Stor.Remove(vFd);
          if Result <> nil then
          begin
            Exit;
          end;
        end;
      finally
        vRem.Free;
      end;
    finally
      vTMap.Free;
    end;
  finally
    v.Release;
  end;
end;

end.
