unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbSnapshot,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbState,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbWrite,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Doc,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
  TSession = class; // Forward declaration

  TtSet = record
    Level: Integer;
    Table: TtFile;
  end;

  TVersion = class
  private
    mId: Int64;
    mSession: TSession;
    mLevels: TArray<TtFiles>;
    mCLevel: Integer;
    mCScore: Double;
    mCSeek: Pointer;
    mClosing: Boolean;
    mRef: Integer;
    mReleased: Boolean;

    procedure ComputeCompaction;
  public
    constructor Create(ParaSession: TSession);
    destructor Destroy; override;

    procedure Incref;
    procedure Release;
    procedure ReleaseNB;

    function Get(ParaAux: TtFiles; const ParaIkey: TInternalKey; ParaRO: TReadOptions; ParaNoValue: Boolean; out ParaValue: TBytes; out ParaTComp: Boolean): Exception;
    function SampleSeek(const ParaIkey: TInternalKey): Boolean;
    function NeedCompaction: Boolean;

    property Id: Int64 read mId;
    property Levels: TArray<TtFiles> read mLevels;
    property CLevel: Integer read mCLevel;
    property CScore: Double read mCScore;
  end;

  TVersionStaging = class
  private
    mBase: TVersion;
    mAdded: TDictionary<Integer, TDictionary<Int64, TatRecord>>;
    mDeleted: TDictionary<Integer, TDictionary<Int64, Boolean>>;
  public
    constructor Create(ParaBase: TVersion);
    destructor Destroy; override;
    procedure Commit(ParaRecord: TSessionRecord);
    function Finish(ParaTrivial: Boolean): TVersion;
  end;

implementation

{ TVersion }

procedure TVersion.ComputeCompaction;
var
  vBestLevel: Integer;
  vBestScore: Double;
  vLevel: Integer;
  vTables: TtFiles;
  vScore: Double;
  vSize: Int64;
begin
  vBestLevel := -1;
  vBestScore := -1;

  for vLevel := 0 to Length(mLevels) - 1 do
  begin
    vTables := mLevels[vLevel];
    vSize := vTables.TotalSize;
    if vLevel = 0 then
    begin
      // vScore := Double(vTables.Count) / Double(mSession.Options.CompactionL0Trigger);
      vScore := Double(vTables.Count) / 4.0; // Default trigger is 4
    end
    else
    begin
      // vScore := Double(vSize) / Double(mSession.Options.GetCompactionTotalSize(vLevel));
      vScore := Double(vSize) / ( 10.0 * 1024 * 1024 * Power( 10, vLevel - 1 ) ); // Simplified
    end;

    if vScore > vBestScore then
    begin
      vBestLevel := vLevel;
      vBestScore := vScore;
    end;
  end;

  mCLevel := vBestLevel;
  mCScore := vBestScore;
end;

constructor TVersion.Create(ParaSession: TSession);
begin
  mSession := ParaSession;
  mCLevel := -1;
  mCScore := -1;
end;

destructor TVersion.Destroy;
var
  vFiles: TtFiles;
begin
  for vFiles in mLevels do
    vFiles.Free;
  inherited;
end;

function TVersion.Get(ParaAux: TtFiles; const ParaIkey: TInternalKey; ParaRO: TReadOptions; ParaNoValue: Boolean; out ParaValue: TBytes; out ParaTComp: Boolean): Exception;
begin
  Result := nil;
  // Implementation of walkOverlapping and table lookup
  ParaTComp := False;
  ParaValue := nil;
end;

procedure TVersion.Incref;
begin
  if mReleased then
    raise Exception.Create('already released');
  TInterlocked.Increment(mRef);
  // Ref loop logic in TSession to be handled
end;

function TVersion.NeedCompaction: Boolean;
begin
  Result := (mCScore >= 1.0) or (mCSeek <> nil);
end;

procedure TVersion.Release;
begin
  // Mutex lock in session
  ReleaseNB;
end;

procedure TVersion.ReleaseNB;
begin
  if TInterlocked.Decrement(mRef) > 0 then
    Exit;
  if mRef < 0 then
    raise Exception.Create('negative version ref');
  
  // Release logic in session
  mReleased := True;
end;

function TVersion.SampleSeek(const ParaIkey: TInternalKey): Boolean;
begin
  Result := False;
end;

{ TVersionStaging }

procedure TVersionStaging.Commit(ParaRecord: TSessionRecord);
var
  vDT: TdtRecord;
  vAT: TatRecord;
begin
  for vDT in ParaRecord.DeletedTables do
  begin
    if not mDeleted.ContainsKey(vDT.Level) then
      mDeleted.Add(vDT.Level, TDictionary<Int64, Boolean>.Create);
    mDeleted[vDT.Level].AddOrSetValue(vDT.Num, True);
    if mAdded.ContainsKey(vDT.Level) then
      mAdded[vDT.Level].Remove(vDT.Num);
  end;

  for vAT in ParaRecord.AddedTables do
  begin
    if not mAdded.ContainsKey(vAT.Level) then
      mAdded.Add(vAT.Level, TDictionary<Int64, TatRecord>.Create);
    mAdded[vAT.Level].AddOrSetValue(vAT.Num, vAT);
    if mDeleted.ContainsKey(vAT.Level) then
      mDeleted[vAT.Level].Remove(vAT.Num);
  end;
end;

constructor TVersionStaging.Create(ParaBase: TVersion);
begin
  mBase := ParaBase;
  mAdded := TDictionary<Integer, TDictionary<Int64, TatRecord>>.Create;
  mDeleted := TDictionary<Integer, TDictionary<Int64, Boolean>>.Create;
end;

destructor TVersionStaging.Destroy;
var
  vLvl: TDictionary<Int64, TatRecord>;
  vDel: TDictionary<Int64, Boolean>;
begin
  for vLvl in mAdded.Values do vLvl.Free;
  for vDel in mDeleted.Values do vDel.Free;
  mAdded.Free;
  mDeleted.Free;
  inherited;
end;

function TVersionStaging.Finish(ParaTrivial: Boolean): TVersion;
begin
  // Implementation of version spawning logic
  Result := TVersion.Create(mBase.mSession);
end;

end.
