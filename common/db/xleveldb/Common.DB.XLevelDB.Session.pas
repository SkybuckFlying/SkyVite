unit Common.Db.XLevelDB.Session;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.Db.XLevelDB.Comparer,
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
  Common.Db.XLevelDB.Filter,
  Common.Db.XLevelDB.Internal,
  Common.Db.XLevelDB.Iterator,
  Common.Db.XLevelDB.Journal,
  Common.Db.XLevelDB.Key,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Opt.Options,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.Db.XLevelDB.SessionRecord,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.Db.XLevelDB.Version,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  EManifestCorrupted = class(Exception)
  private
    FField: string;
    FReason: string;
  public
    constructor Create(const AField, AReason: string);
    property Field: string read FField;
    property Reason: string read FReason;
  end;

  TCachedOptions = class
  private
    mOptions: TOptions;
    mCompactionExpandLimit: TArray<integer>;
    mCompactionGPOverlaps: TArray<integer>;
    mCompactionSourceLimit: TArray<integer>;
    mCompactionTableSize: TArray<integer>;
    mCompactionTotalSize: TArray<int64>;
    procedure Cache;
  public
    constructor Create(const ParaOptions: TOptions);
    function GetCompactionExpandLimit(const ParaLevel: integer): integer;
    function GetCompactionGPOverlaps(const ParaLevel: integer): integer;
    function GetCompactionSourceLimit(const ParaLevel: integer): integer;
    function GetCompactionTableSize(const ParaLevel: integer): integer;
    function GetCompactionTotalSize(const ParaLevel: integer): int64;
    property Options: TOptions read mOptions;
  end;

  TSession = class; // Forward declaration

  TCompaction = class
  private
    mSession: TSession;
    mVersion: TVersion;
    mSourceLevel: Integer;
    mLevels: array[0..1] of TTFiles;
    mMaxGPOverlaps: Int64;
    mGrandparents: TTFiles;
    mGrandparentIndex: Integer;
    mSeenKey: Boolean;
    mGPOverlappedBytes: Int64;
    mImin, mImax: TInternalKey;
    mTPtrs: TArray<Integer>;
    mReleased: Boolean;
    mSnapGPI: Integer;
    mSnapSeenKey: Boolean;
    mSnapGPOverlappedBytes: Int64;
    mSnapTPtrs: TArray<Integer>;
    procedure Expand;
    procedure Save;
    procedure Restore;
  public
    constructor Create(ParaSession: TSession; ParaVersion: TVersion; ParaSourceLevel: Integer; ParaT0: TTFiles);
    destructor Destroy; override;
    procedure Release;
    function IsTrivial: Boolean;
    function IsBaseLevelForKey(ParaUkey: TBytes): Boolean;
    function ShouldStopBefore(ParaIkey: TInternalKey): Boolean;
    function NewIterator: IIterator;
  end;

  TSession = class
  private
    FStNextFileNum: int64;
    FStJournalNum: int64;
    FStPrevJournalNum: int64;
    FStTempFileNum: int64;
    FStSeqNum: uint64;

    FStor: IStorage;
    FStorLock: ILocker;
    FOptions: TCachedOptions;
    FComparer: IInternalComparer;
    FTops: TObject; // TTableOps
    FFileRef: TDictionary<int64, TObject>;

    FManifest: TJournalWriter;
    FManifestWriter: IWriter;
    FManifestFd: TFileDesc;

    FStCompPtrs: TArray<TInternalKey>;
    FStVersion: TVersion;
    FVmu: TCriticalSection;

    procedure SetOptions(const ParaOptions: TOptions);
    procedure Log(const str: string);
    procedure Logf(const fmt: string; args: array of const);

  public:
    // from Session.pas
    constructor Create(AStor: IStorage; AOptions: TOptions);
    destructor Destroy; override;
    procedure Close;
    procedure Release;
    function CreateSession: boolean;
    function Recover: boolean;
    function Commit(r: TSessionRecord): boolean;
    function Version: TVersion;
    procedure SetVersion(AVersion: TVersion);


    // from Compaction.pas
    function PickMemdbLevel(const ParaUMin, ParaUMax: TBytes; ParaMaxLevel: Integer): Integer;
    function FlushMemdb(ParaRec: TSessionRecord; ParaMDB: TMemDB; ParaMaxLevel: Integer): Integer;
    function PickCompaction: TCompaction;
    function GetCompactionRange(ParaSourceLevel: Integer; const ParaUMin, ParaUMax: TBytes; ParaNoLimit: Boolean): TCompaction;

    // from Util.pas
    function NewTemp: TFileDesc;
    function AddFileRef(AFD: TFileDesc; ARef: Integer): Integer;
    function GetTableLen(ALevel: Integer): Integer;
    function GetNextFileNum: Int64;
    procedure SetNextFileNum(ANum: Int64);
    procedure MarkFileNum(ANum: Int64);
    function AllocFileNum: Int64;
    procedure ReuseFileNum(ANum: Int64);
    procedure SetCompPtr(ALevel: Integer; AIK: TInternalKey);
    function GetCompPtr(ALevel: Integer): TInternalKey;
    procedure FillRecord(ARecord: TSessionRecord; ASnapshot: Boolean);
    procedure RecordCommited(ARecord: TSessionRecord);
    function NewManifest(ARecord: TSessionRecord; AVersion: TVersion): HResult;
    function FlushManifest(ARecord: TSessionRecord): HResult;

    property Options: TCachedOptions read FOptions;
    property Comparer: IInternalComparer read FComparer;
    property Tops: TObject read FTops;
  end;

implementation

uses
  System.IOUtils;

{ EManifestCorrupted }

constructor EManifestCorrupted.Create(const AField, AReason: string);
begin
  FField := AField;
  FReason := AReason;
  inherited CreateFmt('leveldb: manifest corrupted (field ''%s''): %s', [AField, AReason]);
end;

{ TCachedOptions }
function DupOptions(const ParaO: TOptions): TOptions;
begin
  Result := ParaO;
  if Result.Strict = [] then
  begin
    Result.Strict := DefaultStrict;
  end;
end;

constructor TCachedOptions.Create(const ParaOptions: TOptions);
begin
  inherited Create;
  mOptions := ParaOptions;
  Cache;
end;

procedure TCachedOptions.Cache;
var
  vIndex: integer;
begin
  SetLength(mCompactionExpandLimit, OptCachedLevel);
  SetLength(mCompactionGPOverlaps, OptCachedLevel);
  SetLength(mCompactionSourceLimit, OptCachedLevel);
  SetLength(mCompactionTableSize, OptCachedLevel);
  SetLength(mCompactionTotalSize, OptCachedLevel);

  for vIndex := 0 to OptCachedLevel - 1 do
  begin
    mCompactionExpandLimit[vIndex] := mOptions.GetCompactionExpandLimit(vIndex);
    mCompactionGPOverlaps[vIndex] := mOptions.GetCompactionGPOverlaps(vIndex);
    mCompactionSourceLimit[vIndex] := mOptions.GetCompactionSourceLimit(vIndex);
    mCompactionTableSize[vIndex] := mOptions.GetCompactionTableSize(vIndex);
    mCompactionTotalSize[vIndex] := mOptions.GetCompactionTotalSize(vIndex);
  end;
end;

function TCachedOptions.GetCompactionExpandLimit(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionExpandLimit[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionExpandLimit(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionGPOverlaps(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionGPOverlaps[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionGPOverlaps(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionSourceLimit(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionSourceLimit[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionSourceLimit(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionTableSize(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionTableSize[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionTableSize(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionTotalSize(const ParaLevel: integer): int64;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionTotalSize[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionTotalSize(ParaLevel);
  end;
end;


{ TSession }

constructor TSession.Create(AStor: IStorage; AOptions: TOptions);
begin
  inherited Create;
  if AStor = nil then
    raise EIllegalArgumentException.Create('storage cannot be nil');
  FStorLock := AStor.Lock;
  if FStorLock = nil then
    raise Exception.Create('could not lock storage');

  FStor := AStor;
  FFileRef := TDictionary<int64, TObject>.Create;
  FVmu := TCriticalSection.Create;

  SetOptions(AOptions);

  FTops := TTableOps.Create(Self);
  SetVersion(TVersion.Create(Self));
  Log('log@legend F·NumFile S·FileSize N·Entry C·BadEntry B·BadBlock Ke·KeyError D·DroppedEntry L·Level Q·SeqNum T·TimeElapsed');
end;

destructor TSession.Destroy;
begin
  Close;
  FFileRef.Free;
  FVmu.Free;
  inherited;
end;

procedure TSession.Close;
begin
  // FTops.Close;
  if FManifest <> nil then
    FManifest.Close;
  if FManifestWriter <> nil then
    FManifestWriter.Close;
  FManifest := nil;
  FManifestWriter := nil;
  SetVersion(TVersion.Create(Self, true));
end;

procedure TSession.Release;
begin
  FStorLock.Unlock;
end;

function TSession.CreateSession: boolean;
var
  rec: TSessionRecord;
begin
  rec := TSessionRecord.Create;
  try
    Result := NewManifest(rec, nil) = S_OK;
  finally
    rec.Free;
  end;
end;

function TSession.Recover: boolean;
var
  fd: TFileDesc;
  reader: IReader;
  jr: TJournalReader;
  rec: TSessionRecord;
  staging: TVersionStaging;
  r: TStream;
begin
  try
    fd := FStor.GetMeta;
  except
    on E: EFileNotFoundException do
    begin
      var fds: TArray<TFileDesc>;
      fds := FStor.List(TFileType.All);
      if Length(fds) > 0 then
        raise EManifestCorrupted.Create('', 'missing files')
      else
        raise;
    end;
  end;

  reader := FStor.Open(fd);
  try
    // jr := TJournalReader.Create(reader, dropper, strict, true);
    rec := TSessionRecord.Create;
    staging := FStVersion.NewStaging;
    try
      while jr.Next(r) do
      begin
        if rec.Decode(r) then
        begin
          // save compact pointers
          for var cp in rec.CompPtrs do
            SetCompPtr(cp.Level, cp.IKey);
          // commit record to version staging
          staging.Commit(rec);
        end
        else
        begin
          // handle error
        end;
        rec.ResetCompPtrs;
        rec.ResetAddedTables;
        rec.ResetDeletedTables;
      end;
    finally
      rec.Free;
      staging.Free;
    end;

    if not rec.HasComparer then
      raise EManifestCorrupted.Create('comparer', 'missing');
    if rec.Comparer <> FComparer.GetName then
      raise EManifestCorrupted.Create('comparer', Format('mismatch: want ''%s'', got ''%s''', [FComparer.GetName, rec.Comparer]));
    if not rec.HasNextFileNum then
      raise EManifestCorrupted.Create('next-file-num', 'missing');
    if not rec.HasJournalNum then
      raise EManifestCorrupted.Create('journal-file-num', 'missing');
    if not rec.HasSeqNum then
      raise EManifestCorrupted.Create('seq-num', 'missing');

    FManifestFd := fd;
    SetVersion(staging.Finish);
    SetNextFileNum(rec.NextFileNum);
    RecordCommited(rec);
    Result := true;
  finally
    reader.Close;
  end;
end;

function TSession.Commit(r: TSessionRecord): boolean;
var
  v, nv: TVersion;
  err: HResult;
begin
  v := Version;
  try
    nv := v.Spawn(r);
    try
      if FManifest = nil then
        err := NewManifest(r, nv)
      else
        err := FlushManifest(r);

      if err = S_OK then
        SetVersion(nv)
      else
        nv.Free;
      Result := err = S_OK;
    except
      nv.Free;
      raise;
    end;
  finally
    v.Free;
  end;
end;

procedure TSession.SetVersion(AVersion: TVersion);
var
  oldVersion: TVersion;
begin
  FVmu.Enter;
  try
    AVersion.IncRef;
    oldVersion := FStVersion;
    FStVersion := AVersion;
  finally
    FVmu.Leave;
  end;
  if oldVersion <> nil then
    oldVersion.ReleaseNB;
end;

function TSession.Version: TVersion;
begin
  FVmu.Enter;
  try
    FStVersion.IncRef;
    Result := FStVersion;
  finally
    FVmu.Leave;
  end;
end;


procedure TSession.SetOptions(const ParaOptions: TOptions);
var
  vNo: TOptions;
  vIndex: integer;
  vF: IFilter;
begin
  vNo := DupOptions(ParaOptions);
  // Alternative filters.
  if Length(ParaOptions.GetAltFilters) > 0 then
  begin
    SetLength(vNo.AltFilters, Length(ParaOptions.GetAltFilters));
    for vIndex := 0 to Length(ParaOptions.GetAltFilters) - 1 do
    begin
      vF := ParaOptions.GetAltFilters[vIndex];
      vNo.AltFilters[vIndex] := TIFilter.Create(vF);
    end;
  end;
  // Comparer.
  FComparer := NewIComparer(ParaOptions.GetComparer);
  vNo.Comparer := FComparer;
  // Filter.
  if ParaOptions.GetFilter <> nil then
  begin
    vNo.Filter := TIFilter.Create(ParaOptions.GetFilter);
  end;

  FOptions := TCachedOptions.Create(vNo);
end;


procedure TSession.Log(const str: string);
begin
  FStor.Log(str);
end;

procedure TSession.Logf(const fmt: string; args: array of const);
begin
  Log(Format(fmt, args));
end;


function TSession.PickMemdbLevel(const ParaUMin, ParaUMax: TBytes; ParaMaxLevel: Integer): Integer;
var
  vVersion: TVersion;
begin
  vVersion := Version;
  try
    Result := vVersion.PickMemdbLevel(ParaUMin, ParaUMax, ParaMaxLevel);
  finally
    vVersion.Release;
  end;
end;

function TSession.FlushMemdb(ParaRec: TSessionRecord; ParaMDB: TMemDB; ParaMaxLevel: Integer): Integer;
var
  vIterator: IIterator;
  vTable: TTable;
  vNumEntries: Int64;
  vFlushLevel: Integer;
begin
  vIterator := ParaMDB.NewIterator(nil);
  try
    //mTableOps.CreateFrom(vIterator, vTable, vNumEntries);
  finally
    vIterator := nil; // Release
  end;

  vFlushLevel := PickMemdbLevel(vTable.IMin.UKey, vTable.IMax.UKey, ParaMaxLevel);
  ParaRec.AddTableFile(vFlushLevel, vTable);

  Log(Format('memdb@flush created L%d@%d N·%d S·%s %s:%s',
    [vFlushLevel, vTable.FD.Num, vNumEntries, ShortenB(vTable.Size), vTable.IMin.ToString, vTable.IMax.ToString]));
  Result := vFlushLevel;
end;

function TSession.PickCompaction: TCompaction;
var
  vVersion: TVersion;
  vSourceLevel: Integer;
  vT0: TTFiles;
  vCompPtr: TInternalKey;
  vTables: TTFiles;
  //vTableSet: PTSet;
begin
  vVersion := Version;
  try
    vT0 := nil;
    if vVersion.CScore >= 1 then
    begin
      vSourceLevel := vVersion.CLevel;
      vCompPtr := GetCompPtr(vSourceLevel);
      vTables := vVersion.Levels[vSourceLevel];
      for var t in vTables do
      begin
        if (vCompPtr = nil) or (FComparer.Compare(t.IMax, vCompPtr) > 0) then
        begin
          SetLength(vT0, 1);
          vT0[0] := t;
          break;
        end;
      end;
      if Length(vT0) = 0 then
      begin
        SetLength(vT0, 1);
        vT0[0] := vTables[0];
      end;
    end
    else
    begin
      // vTableSet := PTSet(TInterlocked.ExchangePointer(vVersion.CSeek, nil));
      // if vTableSet <> nil then
      // begin
      //   vSourceLevel := vTableSet.Level;
      //   SetLength(vT0, 1);
      //   vT0[0] := vTableSet.Table;
      // end
      // else
      begin
        vVersion.Release;
        Result := nil;
        Exit;
      end;
    end;
    Result := TCompaction.Create(Self, vVersion, vSourceLevel, vT0);
    // Note: TCompaction now owns the vVersion reference
  except
    vVersion.Release;
    raise;
  end;
end;

function TSession.GetCompactionRange(ParaSourceLevel: Integer; const ParaUMin, ParaUMax: TBytes; ParaNoLimit: Boolean): TCompaction;
var
  vVersion: TVersion;
  vT0: TTFiles;
  vLimit: Int64;
  vTotal: Int64;
begin
  vVersion := Version;
  try
    if ParaSourceLevel >= Length(vVersion.Levels) then
    begin
      Result := nil;
      Exit;
    end;

    vT0 := vVersion.Levels[ParaSourceLevel].GetOverlaps(nil, FComparer, ParaUMin, ParaUMax, ParaSourceLevel = 0);
    if Length(vT0) = 0 then
    begin
      Result := nil;
      Exit;
    end;

    if not ParaNoLimit and (ParaSourceLevel > 0) then
    begin
      vLimit := FOptions.GetCompactionSourceLimit(ParaSourceLevel);
      vTotal := 0;
      for var i := 0 to High(vT0) do
      begin
        vTotal := vTotal + vT0[i].Size;
        if vTotal >= vLimit then
        begin
          Log(Format('table@compaction limiting F·%d -> F·%d', [Length(vT0), i + 1]));
          SetLength(vT0, i + 1);
          break;
        end;
      end;
    end;

    Result := TCompaction.Create(Self, vVersion, ParaSourceLevel, vT0);
    // Note: TCompaction now owns the vVersion reference
  except
    vVersion.Release;
    raise;
  end;
end;

function TSession.NewTemp: TFileDesc;
var
  vNum: Int64;
begin
  vNum := TInterlocked.Add(FStTempFileNum, 1) - 1;
  Result := TFileDesc.Create(vNum, TFileType.Temp, '');
end;

function TSession.AddFileRef(AFD: TFileDesc; ARef: Integer): Integer;
var
  vRefObj: TObject;
  vRef: Integer;
begin
  if FFileRef.TryGetValue(AFD.Num, vRefObj) then
  begin
    vRef := Integer(vRefObj);
    ARef := ARef + vRef;
  end;

  if ARef > 0 then
    FFileRef.AddOrSetValue(AFD.Num, TObject(ARef))
  else if ARef = 0 then
    FFileRef.Remove(AFD.Num)
  else
    raise Exception.Create(Format('negative ref: %s', [AFD.ToString]));
  Result := ARef;
end;

function TSession.GetTableLen(ALevel: Integer): Integer;
begin
  FVmu.Enter;
  try
    Result := FStVersion.GetTableLen(ALevel);
  finally
    FVmu.Leave;
  end;
end;

function TSession.GetNextFileNum: Int64;
begin
  Result := TInterlocked.Read(FStNextFileNum);
end;

procedure TSession.SetNextFileNum(ANum: Int64);
begin
  TInterlocked.Exchange(FStNextFileNum, ANum);
end;

procedure TSession.MarkFileNum(ANum: Int64);
var
  vNextFileNum, vOld, vX: Int64;
begin
  vNextFileNum := ANum + 1;
  repeat
    vOld := FStNextFileNum;
    vX := vNextFileNum;
    if vOld > vX then
      vX := vOld;
  until TInterlocked.CompareExchange(FStNextFileNum, vX, vOld) = vOld;
end;

function TSession.AllocFileNum: Int64;
begin
  Result := TInterlocked.Add(FStNextFileNum, 1) - 1;
end;

procedure TSession.ReuseFileNum(ANum: Int64);
var
  vOld, vX: Int64;
begin
  repeat
    vOld := FStNextFileNum;
    vX := ANum;
    if vOld <> vX + 1 then
      vX := vOld;
  until TInterlocked.CompareExchange(FStNextFileNum, vX, vOld) = vOld;
end;

procedure TSession.SetCompPtr(ALevel: Integer; AIK: TInternalKey);
var
  vNewCompPtrs: TArray<TInternalKey>;
begin
  if ALevel >= Length(FStCompPtrs) then
  begin
    SetLength(vNewCompPtrs, ALevel + 1);
    System.Move(FStCompPtrs[0], vNewCompPtrs[0], Length(FStCompPtrs) * SizeOf(TInternalKey));
    FStCompPtrs := vNewCompPtrs;
  end;
  FStCompPtrs[ALevel] := Copy(AIK);
end;

function TSession.GetCompPtr(ALevel: Integer): TInternalKey;
begin
  if ALevel >= Length(FStCompPtrs) then
    Result := nil
  else
    Result := FStCompPtrs[ALevel];
end;

procedure TSession.FillRecord(ARecord: TSessionRecord; ASnapshot: Boolean);
begin
  ARecord.SetNextFileNum(GetNextFileNum);
  if ASnapshot then
  begin
    if not ARecord.HasJournalNum then
      ARecord.SetJournalNum(FStJournalNum);
    if not ARecord.HasSeqNum then
      ARecord.SetSeqNum(FStSeqNum);
    for var i := 0 to High(FStCompPtrs) do
      if FStCompPtrs[i] <> nil then
        ARecord.AddCompPtr(i, FStCompPtrs[i]);
    ARecord.SetComparer(FComparer.GetName);
  end;
end;

procedure TSession.RecordCommited(ARecord: TSessionRecord);
begin
  if ARecord.HasJournalNum then
    FStJournalNum := ARecord.JournalNum;
  if ARecord.HasPrevJournalNum then
    FStPrevJournalNum := ARecord.PrevJournalNum;
  if ARecord.HasSeqNum then
    FStSeqNum := ARecord.SeqNum;
  for var Ptr in ARecord.CompPtrs do
    SetCompPtr(Ptr.Level, Ptr.IKey);
end;

function TSession.NewManifest(ARecord: TSessionRecord; AVersion: TVersion): HResult;
var
  vFD: TFileDesc;
  vWriter: IWriter;
  vJW: TJournalWriter;
  vW: IWriter;
begin
  Result := S_OK;
  vFD := TFileDesc.Create(AllocFileNum, TFileType.Manifest, '');
  vWriter := FStor.Create(vFD);
  if vWriter = nil then
  begin
    Result := E_FAIL;
    Exit;
  end;

  vJW := TJournalWriter.Create(vWriter);
  try
    if AVersion = nil then
    begin
      AVersion := Version;
      try
        if ARecord = nil then
          ARecord := TSessionRecord.Create;
        FillRecord(ARecord, True);
        AVersion.FillRecord(ARecord);

        vW := vJW.Next;
        ARecord.EncodeTo(vW);
        vJW.Flush;
        FStor.SetMeta(vFD);

        RecordCommited(ARecord);
        if FManifest <> nil then
          FManifest.Close;
        if FManifestWriter <> nil then
          FManifestWriter.Close;
        if not FManifestFD.IsZero then
          FStor.Remove(FManifestFD);
        FManifestFD := vFD;
        FManifestWriter := vWriter;
        FManifest := vJW;
      finally
        AVersion.Release;
      end;
    end
    else
    begin
      if ARecord = nil then
        ARecord := TSessionRecord.Create;
      FillRecord(ARecord, True);
      AVersion.FillRecord(ARecord);

      vW := vJW.Next;
      ARecord.EncodeTo(vW);
      vJW.Flush;
      FStor.SetMeta(vFD);

      RecordCommited(ARecord);
      if FManifest <> nil then
        FManifest.Close;
      if FManifestWriter <> nil then
        FManifestWriter.Close;
      if not FManifestFD.IsZero then
        FStor.Remove(FManifestFD);
      FManifestFD := vFD;
      FManifestWriter := vWriter;
      FManifest := vJW;
    end;
  except
    on E: Exception do
    begin
      vWriter.Close;
      FStor.Remove(vFD);
      ReuseFileNum(vFD.Num);
      Result := E_FAIL;
    end;
  end;
end;

function TSession.FlushManifest(ARecord: TSessionRecord): HResult;
var
  vW: IWriter;
begin
  Result := S_OK;
  try
    FillRecord(ARecord, False);
    vW := FManifest.Next;
    ARecord.EncodeTo(vW);
    FManifest.Flush;
    if not FOptions.Options.GetNoSync then
      FManifestWriter.Sync;
    RecordCommited(ARecord);
  except
    on E: Exception do
      Result := E_FAIL;
  end;
end;


{ TCompaction }

constructor TCompaction.Create(ParaSession: TSession; ParaVersion: TVersion; ParaSourceLevel: Integer; ParaT0: TTFiles);
begin
  inherited Create;
  mSession := ParaSession;
  mVersion := ParaVersion; // Take ownership of the version reference
  mSourceLevel := ParaSourceLevel;
  mLevels[0] := ParaT0;
  mLevels[1] := nil;
  mMaxGPOverlaps := mSession.Options.GetCompactionGPOverlaps(mSourceLevel);
  SetLength(mTPtrs, Length(mVersion.Levels));
  Expand;
  Save;
end;

destructor TCompaction.Destroy;
begin
  Release;
  inherited;
end;

procedure TCompaction.Release;
begin
  if not mReleased then
  begin
    mReleased := True;
    mVersion.Release;
  end;
end;

procedure TCompaction.Expand;
var
  vLimit: Int64;
  vT0, vT1, vExp0, vExp1: TTFiles;
  vIMin, vIMax, vAMin, vAMax, vXMin, vXMax: TInternalKey;
  vSourcePlus1Level, vSourcePlus2Level: Integer;
begin
  vLimit := mSession.Options.GetCompactionExpandLimit(mSourceLevel);
  vT0 := mVersion.Levels[mSourceLevel];
  vT1 := nil;
  vSourcePlus1Level := mSourceLevel + 1;
  if vSourcePlus1Level < Length(mVersion.Levels) then
    vT1 := mVersion.Levels[vSourcePlus1Level];

  mLevels[0] := vT0.GetOverlaps(mLevels[0], mSession.Comparer, mLevels[0].GetRange(vIMin, vIMax).UKey, vIMax.UKey, mSourceLevel = 0);

  if Length(mLevels[0]) <> Length(vT0) then
    mLevels[0].GetRange(vIMin, vIMax);

  mLevels[1] := vT1.GetOverlaps(mLevels[1], mSession.Comparer, vIMin.UKey, vIMax.UKey, False);
  TTFiles(mLevels).GetRange(vAMin, vAMax);

  if Length(mLevels[1]) > 0 then
  begin
    vExp0 := vT0.GetOverlaps(nil, mSession.Comparer, vAMin.UKey, vAMax.UKey, mSourceLevel = 0);
    if (Length(vExp0) > Length(mLevels[0])) and (mLevels[1].Size + vExp0.Size < vLimit) then
    begin
      vExp0.GetRange(vXMin, vXMax);
      vExp1 := vT1.GetOverlaps(nil, mSession.Comparer, vXMin.UKey, vXMax.UKey, False);
      if Length(vExp1) = Length(mLevels[1]) then
      begin
        mSession.Log(Format('table@compaction expanding L%d+L%d (F·%d S·%s)+(F·%d S·%s) -> (F·%d S·%s)+(F·%d S·%s)',
          [mSourceLevel, mSourceLevel + 1, Length(mLevels[0]), ShortenB(mLevels[0].Size), Length(mLevels[1]), ShortenB(mLevels[1].Size),
          Length(vExp0), ShortenB(vExp0.Size), Length(vExp1), ShortenB(vExp1.Size)]));
        vIMin := vXMin;
        vIMax := vXMax;
        mLevels[0] := vExp0;
        mLevels[1] := vExp1;
        TTFiles(mLevels).GetRange(vAMin, vAMax);
      end;
    end;
  end;

  vSourcePlus2Level := mSourceLevel + 2;
  if vSourcePlus2Level < Length(mVersion.Levels) then
    mGrandparents := mVersion.Levels[vSourcePlus2Level].GetOverlaps(mGrandparents, mSession.Comparer, vAMin.UKey, vAMax.UKey, False);

  mImin := vIMin;
  mImax := vIMax;
end;

function TCompaction.IsBaseLevelForKey(ParaUkey: TBytes): Boolean;
var
  vTables: TTFiles;
  t: TTable;
begin
  Result := True;
  for var level := mSourceLevel + 2 to High(mVersion.Levels) do
  begin
    vTables := mVersion.Levels[level];
    while mTPtrs[level] < Length(vTables) do
    begin
      t := vTables[mTPtrs[level]];
      if mSession.Comparer.UCompare(ParaUkey, t.IMax.UKey) <= 0 then
      begin
        if mSession.Comparer.UCompare(ParaUkey, t.IMin.UKey) >= 0 then
        begin
          Result := False;
          Exit;
        end;
        break;
      end;
      mTPtrs[level] := mTPtrs[level] + 1;
    end;
  end;
end;

function TCompaction.IsTrivial: Boolean;
begin
  Result := (Length(mLevels[0]) = 1) and (Length(mLevels[1]) = 0) and (mGrandparents.Size <= mMaxGPOverlaps);
end;

function TCompaction.NewIterator: IIterator;
var
  vIterators: TArray<IIterator>;
  vRO: TReadOptions;
  vStrict: Boolean;
  vIt: IIterator;
  iCap: Integer;
begin
  if mSourceLevel = 0 then
    iCap := Length(mLevels[0]) + 1
  else
    iCap := Length(mLevels);

  SetLength(vIterators, 0);

  vRO.DontFillCache := True;
  vRO.Strict := TStrictModes(Ord(TStrictModes.StrictOverride));
  vStrict := mSession.Options.Options.GetStrict(TStrictModes.StrictCompaction);
  if vStrict then
    vRO.Strict := TStrictModes(Ord(vRO.Strict) or Ord(TStrictModes.StrictReader));

  for var i := 0 to High(mLevels) do
  begin
    if Length(mLevels[i]) = 0 then
      Continue;

    if (mSourceLevel + i) = 0 then
    begin
      for var t in mLevels[i] do
      begin
        SetLength(vIterators, Length(vIterators) + 1);
        //vIterators[High(vIterators)] := mSession.Tops.NewIterator(t, nil, @vRO);
      end;
    end
    else
    begin
      // vIt := TIndexedIterator.Create(mLevels[i].NewIndexIterator(mSession.Tops, mSession.Comparer, nil, @vRO), vStrict);
      SetLength(vIterators, Length(vIterators) + 1);
      vIterators[High(vIterators)] := vIt;
    end;
  end;

  Result := TMergedIterator.Create(vIterators, mSession.Comparer, vStrict);
end;

procedure TCompaction.Restore;
begin
  mGrandparentIndex := mSnapGPI;
  mSeenKey := mSnapSeenKey;
  mGPOverlappedBytes := mSnapGPOverlappedBytes;
  mTPtrs := Copy(mSnapTPtrs);
end;

procedure TCompaction.Save;
begin
  mSnapGPI := mGrandparentIndex;
  mSnapSeenKey := mSeenKey;
  mSnapGPOverlappedBytes := mGPOverlappedBytes;
  mSnapTPtrs := Copy(mSnapTPtrs);
end;

function TCompaction.ShouldStopBefore(ParaIkey: TInternalKey): Boolean;
var
  gp: TTable;
begin
  while mGrandparentIndex < Length(mGrandparents) do
  begin
    gp := mGrandparents[mGrandparentIndex];
    if mSession.Comparer.Compare(ParaIkey, gp.IMax) <= 0 then
      break;
    if mSeenKey then
      mGPOverlappedBytes := mGPOverlappedBytes + gp.Size;
    mGrandparentIndex := mGrandparentIndex + 1;
  end;
  mSeenKey := True;

  if mGPOverlappedBytes > mMaxGPOverlaps then
  begin
    mGPOverlappedBytes := 0;
    Result := True;
  end
  else
    Result := False;
end;

end.
