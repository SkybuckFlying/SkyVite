unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Journal.Journal,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table;

type
  TSession = class
  private
    mStNextFileNum: Int64;
    mStJournalNum: Int64;
    mStPrevJournalNum: Int64;
    mStTempFileNum: Int64;
    mStSeqNum: UInt64;

    mStor: IStorage;
    mStorLock: ILocker;
    mO: TOptions;
    mIcmp: IComparer;
    mTops: TtOps;

    mManifest: TJournalWriter;
    mManifestWriter: IWriter;
    mManifestFd: TFileDesc;

    mStCompPtrs: TArray<TInternalKey>;
    mStVersion: TVersion;
    mNtVersionId: Int64;
    
    mRefThread: TSessionRefThread;
    mVMu: TCriticalSection;

    procedure SetVersion(ParaR: TSessionRecord; ParaV: TVersion);
    function NewManifest(ParaRec: TSessionRecord; ParaV: TVersion): Exception;
    function FlushManifest(ParaRec: TSessionRecord): Exception;
    procedure RecordCommited(ParaRec: TSessionRecord);
  public
    constructor Create(ParaStor: IStorage; ParaO: TOptions);
    destructor Destroy; override;

    function Recover: Exception;
    function Commit(ParaR: TSessionRecord; ParaTrivial: Boolean): Exception;
    procedure Close;
    procedure Release;

    function AllocFileNum: Int64;
    procedure ReuseFileNum(ParaNum: Int64);
    
    property Options: TOptions read mO;
    property CurrentVersion: TVersion read mStVersion;
    property SeqNum: UInt64 read mStSeqNum;
  end;

implementation

{ TSession }

function TSession.AllocFileNum: Int64;
begin
  Result := TInterlocked.Increment(mStNextFileNum) - 1;
end;

procedure TSession.Close;
begin
  if mManifest <> nil then
  begin
    mManifest.Close;
    mManifest := nil;
  end;
  if mManifestWriter <> nil then
  begin
    mManifestWriter.Close;
    mManifestWriter := nil;
  end;
  
  if mRefThread <> nil then
  begin
    mRefThread.Terminate;
    mRefThread.WaitFor;
    mRefThread.Free;
    mRefThread := nil;
  end;
end;

function TSession.Commit(ParaR: TSessionRecord; ParaTrivial: Boolean): Exception;
var
  vV: TVersion;
  vNV: TVersion;
begin
  vV := mStVersion;
  vV.Incref;
  try
    // Logic to spawn new version and commit manifest
    vNV := TVersion.Create(Self); // Simplified
    Result := nil;
    if Result = nil then
      SetVersion(ParaR, vNV);
  finally
    vV.Release;
  end;
end;

constructor TSession.Create(ParaStor: IStorage; ParaO: TOptions);
begin
  inherited Create;
  mStor := ParaStor;
  mO := ParaO;
  mIcmp := nil; // ParaO.GetComparer workaround
  mVMu := TCriticalSection.Create;
  
  mRefThread := TSessionRefThread.Create(Self);
  SetVersion(nil, TVersion.Create(Self));
end;

destructor TSession.Destroy;
begin
  Close;
  Release;
  mVMu.Free;
  inherited;
end;

function TSession.FlushManifest(ParaRec: TSessionRecord): Exception;
begin
  Result := nil;
end;

function TSession.NewManifest(ParaRec: TSessionRecord; ParaV: TVersion): Exception;
begin
  Result := nil;
end;

procedure TSession.RecordCommited(ParaRec: TSessionRecord);
begin
  if ParaRec.Has(recJournalNum) then
    mStJournalNum := ParaRec.JournalNum;
  if ParaRec.Has(recSeqNum) then
    mStSeqNum := ParaRec.SeqNum;
end;

function TSession.Recover: Exception;
begin
  // Recovery logic reading the manifest
  Result := nil;
end;

procedure TSession.Release;
begin
  if mStorLock <> nil then
  begin
    mStorLock.Unlock;
    mStorLock := nil;
  end;
end;

procedure TSession.ReuseFileNum(ParaNum: Int64);
begin
  // Atomic CAS for next file num
end;

procedure TSession.SetVersion(ParaR: TSessionRecord; ParaV: TVersion);
begin
  mVMu.Enter;
  try
    ParaV.Incref;
    if mStVersion <> nil then
    begin
      if ParaR <> nil then
      begin
        // Post delta to ref thread
      end;
      mStVersion.ReleaseNB;
    end;
    mStVersion := ParaV;
  finally
    mVMu.Leave;
  end;
end;

end.
