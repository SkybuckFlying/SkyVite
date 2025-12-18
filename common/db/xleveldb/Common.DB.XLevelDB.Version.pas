unit Common.Db.XLevelDB.Version;

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
  Common.DB.XLevelDB.Filter,
  Common.Db.XLevelDB.Internal,
  Common.Db.XLevelDB.Iterator,
  Common.DB.XLevelDB.Key,
  Common.Db.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  GoToDelphi.Helpers.BigInt,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TSessionRecord = class;
  TVersion = class;
  tSet = record
    level: integer;
    table: TTableFile;
  end;

  TVersionStaging = class
  private
    mBase: TVersion;
    mLevels: TArray<TDictionary<int64, TObject>>; // TAddedTableRecord or boolean for deleted
  public
    constructor Create(ParaBase: TVersion);
    destructor Destroy; override;
    procedure Commit(ParaRecord: TSessionRecord);
    function Finish: TVersion;
  end;

  TVersion = class
  private
    mSession: TObject; // TSession
    mLevels: TArray<TTableFiles>;
    // Level that should be compacted next and its compaction score.
    // Score < 1 means compaction is not strictly needed. These fields
    // are initialized by computeCompaction()
    mCLevel: integer;
    mCScore: double;
    mCSeek: Pointer;
    mClosing: boolean;
    mRef: integer;
    mReleased: boolean;
    procedure ReleaseNB;
    procedure ComputeCompaction;
  public
    constructor Create(ParaSession: TObject; ParaClosing: boolean = false);
    destructor Destroy; override;
    procedure IncRef;
    procedure Release;
    procedure WalkOverlapping(ParaAux: TTableFiles; ParaIkey: TInternalKey; ParaFunc: TFunc<integer, TTableFile, boolean>; ParaLFunc: TFunc<integer, boolean>);
    function Get(ParaAux: TTableFiles; ParaIkey: TInternalKey; ParaRo: TReadOptions; ParaNoValue: boolean; out ParaValue: TBytes; out ParaTcomp: boolean): boolean;
    function SampleSeek(ParaIkey: TInternalKey): boolean;
    function GetIterators(ParaSlice: TRange; ParaRo: TReadOptions): TArray<IIterator>;
    function NewStaging: TVersionStaging;
    function Spawn(ParaRecord: TSessionRecord): TVersion;
    procedure FillRecord(ParaRecord: TSessionRecord);
    function TLen(ParaLevel: integer): integer;
    function OffsetOf(ParaIkey: TInternalKey): int64;
    function PickMemDBLevel(ParaUmin, ParaUmax: TBytes; ParaMaxLevel: integer): integer;
    function NeedCompaction: boolean;
  end;

  TVersionReleaser = class
  private
    mVersion: TVersion;
    mOnce: boolean;
  public
    constructor Create(ParaVersion: TVersion);
    procedure Release;
  end;

implementation

uses
  System.Math,
  System.Threading;

{ TVersionStaging }

constructor TVersionStaging.Create(ParaBase: TVersion);
begin
  inherited Create;
  mBase := ParaBase;
end;

destructor TVersionStaging.Destroy;
var
  vIndex: integer;
begin
  for vIndex := 0 to High(mLevels) do
  begin
    mLevels[vIndex].Free;
  end;
  inherited;
end;

procedure TVersionStaging.Commit(ParaRecord: TSessionRecord);
begin
  // implementation missing
end;

function TVersionStaging.Finish: TVersion;
begin
  // implementation missing
  Result := nil;
end;

{ TVersion }

constructor TVersion.Create(ParaSession: TObject; ParaClosing: boolean = false);
begin
  inherited Create;
  mSession := ParaSession;
  mClosing := ParaClosing;
end;

destructor TVersion.Destroy;
begin
  Release;
  inherited;
end;

procedure TVersion.IncRef;
begin
  if mReleased then
  begin
    raise Exception.Create('already released');
  end;
  TInterlocked.Increment(mRef);
  if mRef = 1 then
  begin
    // Incr file ref.
  end;
end;

procedure TVersion.ReleaseNB;
begin
  if TInterlocked.Decrement(mRef) > 0 then
  begin
    Exit;
  end;
  if mRef < 0 then
  begin
    raise Exception.Create('negative version ref');
  end;

  // Decr file ref.
  mReleased := true;
end;

procedure TVersion.Release;
begin
  // mSession.FVmu.Enter;
  try
    ReleaseNB;
  finally
    // mSession.FVmu.Leave;
  end;
end;

procedure TVersion.WalkOverlapping(ParaAux: TTableFiles; ParaIkey: TInternalKey; ParaFunc: TFunc<integer, TTableFile, boolean>; ParaLFunc: TFunc<integer, boolean>);
begin
  // implementation missing
end;

function TVersion.Get(ParaAux: TTableFiles; ParaIkey: TInternalKey; ParaRo: TReadOptions; ParaNoValue: boolean; out ParaValue: TBytes; out ParaTcomp: boolean): boolean;
begin
  // implementation missing
  Result := false;
end;

function TVersion.SampleSeek(ParaIkey: TInternalKey): boolean;
begin
  // implementation missing
  Result := false;
end;

function TVersion.GetIterators(ParaSlice: TRange; ParaRo: TReadOptions): TArray<IIterator>;
begin
  // implementation missing
  Result := nil;
end;

function TVersion.NewStaging: TVersionStaging;
begin
  Result := TVersionStaging.Create(Self);
end;

function TVersion.Spawn(ParaRecord: TSessionRecord): TVersion;
var
  vStaging: TVersionStaging;
begin
  vStaging := NewStaging;
  try
    vStaging.Commit(ParaRecord);
    Result := vStaging.Finish;
  finally
    vStaging.Free;
  end;
end;

procedure TVersion.FillRecord(ParaRecord: TSessionRecord);
begin
  // implementation missing
end;

function TVersion.TLen(ParaLevel: integer): integer;
begin
  if ParaLevel < Length(mLevels) then
  begin
    Result := mLevels[ParaLevel].Count
  end
  else
  begin
    Result := 0;
  end;
end;

function TVersion.OffsetOf(ParaIkey: TInternalKey): int64;
begin
  // implementation missing
  Result := 0;
end;

function TVersion.PickMemDBLevel(ParaUmin, ParaUmax: TBytes; ParaMaxLevel: integer): integer;
begin
  // implementation missing
  Result := 0;
end;

procedure TVersion.ComputeCompaction;
begin
  // implementation missing
end;

function TVersion.NeedCompaction: boolean;
begin
  Result := (mCScore >= 1) or (mCSeek <> nil);
end;

{ TVersionReleaser }

constructor TVersionReleaser.Create(ParaVersion: TVersion);
begin
  inherited Create;
  mVersion := ParaVersion;
end;

procedure TVersionReleaser.Release;
begin
  // mVersion.mSession.FVmu.Enter;
  try
    if not mOnce then
    begin
      mVersion.ReleaseNB;
      mOnce := true;
    end;
  finally
    // mVersion.mSession.FVmu.Leave;
  end;
end;

end.
