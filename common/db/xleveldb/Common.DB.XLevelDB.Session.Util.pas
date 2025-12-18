unit Common.DB.XLevelDB.Session.Util;

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
  Common.DB.XLevelDB.Journal,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.SessionRecord,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.SysUtils;

type
  TSession = partial class
  private
    procedure Log(const AStrs: array of const);
    procedure LogF(const AFormat: string; const AArgs: array of const);
  public
    function NewTemp: TFileDesc;
    function AddFileRef(AFD: TFileDesc; ARef: Integer): Integer;
    function GetVersion: TVersion;
    procedure SetVersion(AVersion: TVersion);
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
  end;

  TJournalDropper = class(IJournalDropper)
  private
    mSession: TSession;
    mFD: TFileDesc;
  public
    constructor Create(ASession: TSession; AFD: TFileDesc);
    procedure Drop(AErr: Exception); override;
  end;

implementation

{ TJournalDropper }

constructor TJournalDropper.Create(ASession: TSession; AFD: TFileDesc);
begin
  inherited Create;
  mSession := ASession;
  mFD := AFD;
end;

procedure TJournalDropper.Drop(AErr: Exception);
begin
  // if AErr is EJournalCorrupted then
  //   mSession.LogF('journal@drop %s-%d S·%s "%s"', [mFD.Type.ToString, mFD.Num, ShortenB(EJournalCorrupted(AErr).Size), EJournalCorrupted(AErr).Reason])
  // else
  //   mSession.LogF('journal@drop %s-%d "%s"', [mFD.Type.ToString, mFD.Num, AErr.Message]);
end;

{ TSession }

procedure TSession.Log(const AStrs: array of const);
begin
  // Implementation assumes a logging mechanism on the storage object
  // Self.mStorage.Log(System.SysUtils.Format(AStrs));
end;

procedure TSession.LogF(const AFormat: string; const AArgs: array of const);
begin
  // Self.mStorage.Log(System.SysUtils.Format(AFormat, AArgs));
end;

function TSession.NewTemp: TFileDesc;
var
  vNum: Int64;
begin
  vNum := TInterlocked.Add(mTempFileNum, 1) - 1;
  Result := TFileDesc.Create(vNum, TFileType.Temp, '');
end;

function TSession.AddFileRef(AFD: TFileDesc; ARef: Integer): Integer;
var
  vRef: Integer;
begin
  if mFileRef.TryGetValue(AFD.Num, vRef) then
    ARef := ARef + vRef;

  if ARef > 0 then
    mFileRef.AddOrSetValue(AFD.Num, ARef)
  else if ARef = 0 then
    mFileRef.Remove(AFD.Num)
  else
    raise Exception.Create(Format('negative ref: %s', [AFD.ToString]));
  Result := ARef;
end;

function TSession.GetVersion: TVersion;
begin
  mVersionMutex.Acquire;
  try
    mVersion.IncRef;
    Result := mVersion;
  finally
    mVersionMutex.Release;
  end;
end;

procedure TSession.SetVersion(AVersion: TVersion);
var
  vOldVersion: TVersion;
begin
  mVersionMutex.Acquire;
  try
    AVersion.IncRef;
    vOldVersion := mVersion;
    mVersion := AVersion;
  finally
    mVersionMutex.Release;
  end;
  if vOldVersion <> nil then
    vOldVersion.ReleaseNB;
end;

function TSession.GetTableLen(ALevel: Integer): Integer;
begin
  mVersionMutex.Acquire;
  try
    Result := mVersion.GetTableLen(ALevel);
  finally
    mVersionMutex.Release;
  end;
end;

function TSession.GetNextFileNum: Int64;
begin
  Result := TInterlocked.Read(mNextFileNum);
end;

procedure TSession.SetNextFileNum(ANum: Int64);
begin
  TInterlocked.Exchange(mNextFileNum, ANum);
end;

procedure TSession.MarkFileNum(ANum: Int64);
var
  vNextFileNum, vOld, vX: Int64;
begin
  vNextFileNum := ANum + 1;
  repeat
    vOld := mNextFileNum;
    vX := vNextFileNum;
    if vOld > vX then
      vX := vOld;
  until TInterlocked.CompareExchange(mNextFileNum, vX, vOld) = vOld;
end;

function TSession.AllocFileNum: Int64;
begin
  Result := TInterlocked.Add(mNextFileNum, 1) - 1;
end;

procedure TSession.ReuseFileNum(ANum: Int64);
var
  vOld, vX: Int64;
begin
  repeat
    vOld := mNextFileNum;
    vX := ANum;
    if vOld <> vX + 1 then
      vX := vOld;
  until TInterlocked.CompareExchange(mNextFileNum, vX, vOld) = vOld;
end;

procedure TSession.SetCompPtr(ALevel: Integer; AIK: TInternalKey);
var
  vNewCompPtrs: TArray<TInternalKey>;
begin
  if ALevel >= Length(mCompPtrs) then
  begin
    SetLength(vNewCompPtrs, ALevel + 1);
    System.Move(mCompPtrs[0], vNewCompPtrs[0], Length(mCompPtrs) * SizeOf(TInternalKey));
    mCompPtrs := vNewCompPtrs;
  end;
  mCompPtrs[ALevel] := Copy(AIK);
end;

function TSession.GetCompPtr(ALevel: Integer): TInternalKey;
begin
  if ALevel >= Length(mCompPtrs) then
    Result := nil
  else
    Result := mCompPtrs[ALevel];
end;

procedure TSession.FillRecord(ARecord: TSessionRecord; ASnapshot: Boolean);
begin
  ARecord.SetNextFileNum(GetNextFileNum);
  if ASnapshot then
  begin
    if not ARecord.HasJournalNum then
      ARecord.SetJournalNum(mJournalNum);
    if not ARecord.HasSeqNum then
      ARecord.SetSeqNum(mSeqNum);
    for var i := 0 to High(mCompPtrs) do
      if mCompPtrs[i] <> nil then
        ARecord.AddCompPtr(i, mCompPtrs[i]);
    ARecord.SetComparer(mComparer.Name);
  end;
end;

procedure TSession.RecordCommited(ARecord: TSessionRecord);
begin
  if ARecord.HasJournalNum then
    mJournalNum := ARecord.JournalNum;
  if ARecord.HasPrevJournalNum then
    mPrevJournalNum := ARecord.PrevJournalNum;
  if ARecord.HasSeqNum then
    mSeqNum := ARecord.SeqNum;
  for var Ptr in ARecord.CompPtrs do
    SetCompPtr(Ptr.Level, Ptr.Key);
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
  vWriter := mStorage.Create(vFD);
  if vWriter = nil then
  begin
    Result := E_FAIL;
    Exit;
  end;

  vJW := TJournalWriter.Create(vWriter);
  try
    if AVersion = nil then
    begin
      AVersion := GetVersion;
      try
        if ARecord = nil then
          ARecord := TSessionRecord.Create;
        FillRecord(ARecord, True);
        AVersion.FillRecord(ARecord);

        vW := vJW.Next;
        ARecord.EncodeTo(vW);
        vJW.Flush;
        mStorage.SetMeta(vFD);

        RecordCommited(ARecord);
        if mManifest <> nil then
          mManifest.Close;
        if mManifestWriter <> nil then
          mManifestWriter.Close;
        if not mManifestFD.IsZero then
          mStorage.Remove(mManifestFD);
        mManifestFD := vFD;
        mManifestWriter := vWriter;
        mManifest := vJW;
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
      mStorage.SetMeta(vFD);

      RecordCommited(ARecord);
      if mManifest <> nil then
        mManifest.Close;
      if mManifestWriter <> nil then
        mManifestWriter.Close;
      if not mManifestFD.IsZero then
        mStorage.Remove(mManifestFD);
      mManifestFD := vFD;
      mManifestWriter := vWriter;
      mManifest := vJW;
    end;
  except
    on E: Exception do
    begin
      vWriter.Close;
      mStorage.Remove(vFD);
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
    vW := mManifest.Next;
    ARecord.EncodeTo(vW);
    mManifest.Flush;
    if not mOptions.GetNoSync then
      mManifestWriter.Sync;
    RecordCommited(ARecord);
  except
    on E: Exception do
      Result := E_FAIL;
  end;
end;

end.
