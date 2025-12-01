unit Common.Db.XLevelDB.Session;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.Options,
  Common.Db.XLevelDB.Comparer,
  Common.Db.XLevelDB.Internal,
  Common.Db.XLevelDB.Journal,
  Common.Db.XLevelDB.Version;

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
    FFileRef: TDictionary<int64, integer>;

    FManifest: TJournalWriter;
    FManifestWriter: IWriter;
    FManifestFd: TFileDesc;

    FStCompPtrs: TArray<TInternalKey>;
    FStVersion: TVersion;
    FVmu: TCriticalSection;

    procedure SetVersion(AVersion: TVersion);
    procedure SetNextFileNum(ANum: int64);
    procedure SetCompPtr(level: integer; ikey: TInternalKey);
    procedure Log(const str: string);
    procedure Logf(const fmt: string; args: array of const);
    procedure RecordCommited(r: TSessionRecord);
    function NewManifest(r: TSessionRecord; v: TVersion): boolean;
    function FlushManifest(r: TSessionRecord): boolean;
  public
    constructor Create(AStor: IStorage; AOptions: TOptions);
    destructor Destroy; override;
    procedure Close;
    procedure Release;
    function CreateSession: boolean;
    function Recover: boolean;
    function Commit(r: TSessionRecord): boolean;
    function Version: TVersion;
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
  FFileRef := TDictionary<int64, integer>.Create;
  FVmu := TCriticalSection.Create;

  // SetOptions is a method of TSession from options.go, but I put it in a separate unit
  // so I will call it here.
  var sessionForOpts: Common.Db.XLevelDB.Options.TSession;
  sessionForOpts := Common.Db.XLevelDB.Options.TSession.Create;
  try
    sessionForOpts.SetOptions(AOptions);
    FOptions := sessionForOpts.Options;
    FComparer := sessionForOpts.Comparer;
  finally
    sessionForOpts.Free;
  end;

  // FTops := TTableOps.Create(Self);
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
begin
  Result := NewManifest(nil, nil);
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
      fds := FStor.List(TypeAll);
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
begin
  v := Version;
  try
    nv := v.Spawn(r);
    try
      if FManifest = nil then
        Result := NewManifest(r, nv)
      else
        Result := FlushManifest(r);

      if Result then
        SetVersion(nv)
      else
        nv.Free;
    except
      nv.Free;
      raise;
    end;
  finally
    v.Free;
  end;
end;

procedure TSession.SetVersion(AVersion: TVersion);
begin
  FVmu.Enter;
  try
    FStVersion := AVersion;
  finally
    FVmu.Leave;
  end;
end;

function TSession.Version: TVersion;
begin
  FVmu.Enter;
  try
    // AddRef
    Result := FStVersion;
  finally
    FVmu.Leave;
  end;
end;

procedure TSession.SetNextFileNum(ANum: int64);
begin
  FStNextFileNum := ANum;
end;

procedure TSession.SetCompPtr(level: integer; ikey: TInternalKey);
begin
  if level >= Length(FStCompPtrs) then
  begin
    var newCompPtrs: TArray<TInternalKey>;
    SetLength(newCompPtrs, level + 1);
    System.Move(FStCompPtrs[0], newCompPtrs[0], Length(FStCompPtrs));
    FStCompPtrs := newCompPtrs;
  end;
  FStCompPtrs[level] := ikey;
end;

procedure TSession.Log(const str: string);
begin
  FStor.Log(str);
end;

procedure TSession.Logf(const fmt: string; args: array of const);
begin
  Log(Format(fmt, args));
end;

procedure TSession.RecordCommited(r: TSessionRecord);
begin
  if r.HasJournalNum then
    FStJournalNum := r.JournalNum;
  if r.HasPrevJournalNum then
    FStPrevJournalNum := r.PrevJournalNum;
  if r.HasSeqNum then
    FStSeqNum := r.SeqNum;
end;

function TSession.NewManifest(r: TSessionRecord; v: TVersion): boolean;
begin
  // implementation missing
  Result := false;
end;

function TSession.FlushManifest(r: TSessionRecord): boolean;
begin
  // implementation missing
  Result := false;
end;

end.
