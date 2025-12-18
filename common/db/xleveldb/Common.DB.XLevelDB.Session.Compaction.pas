unit Common.DB.XLevelDB.Session.Compaction;

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
  Common.DB.XLevelDB.Iterator,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.MemDB,
  Common.DB.XLevelDB.Opt,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.SessionRecord,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.SysUtils;

type
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

  TSession = partial class
  public
    function PickMemdbLevel(const ParaUMin, ParaUMax: TBytes; ParaMaxLevel: Integer): Integer;
    function FlushMemdb(ParaRec: TSessionRecord; ParaMDB: TMemDB; ParaMaxLevel: Integer): Integer;
    function PickCompaction: TCompaction;
    function GetCompactionRange(ParaSourceLevel: Integer; const ParaUMin, ParaUMax: TBytes; ParaNoLimit: Boolean): TCompaction;
  end;

implementation

uses
  System.Classes,
  Common.DB.XLevelDB.Comparer;

{ TSession }

function TSession.PickMemdbLevel(const ParaUMin, ParaUMax: TBytes; ParaMaxLevel: Integer): Integer;
var
  vVersion: TVersion;
begin
  vVersion := GetVersion;
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
    mTableOps.CreateFrom(vIterator, vTable, vNumEntries);
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
  vTableSet: PTSet;
begin
  vVersion := GetVersion;
  try
    vT0 := nil;
    if vVersion.CScore >= 1 then
    begin
      vSourceLevel := vVersion.CLevel;
      vCompPtr := GetCompPtr(vSourceLevel);
      vTables := vVersion.Levels[vSourceLevel];
      for var t in vTables do
      begin
        if (vCompPtr = nil) or (mComparer.Compare(t.IMax, vCompPtr) > 0) then
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
      vTableSet := PTSet(TInterlocked.ExchangePointer(vVersion.CSeek, nil));
      if vTableSet <> nil then
      begin
        vSourceLevel := vTableSet.Level;
        SetLength(vT0, 1);
        vT0[0] := vTableSet.Table;
      end
      else
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
  vVersion := GetVersion;
  try
    if ParaSourceLevel >= Length(vVersion.Levels) then
    begin
      Result := nil;
      Exit;
    end;

    vT0 := vVersion.Levels[ParaSourceLevel].GetOverlaps(nil, mComparer, ParaUMin, ParaUMax, ParaSourceLevel = 0);
    if Length(vT0) = 0 then
    begin
      Result := nil;
      Exit;
    end;

    if not ParaNoLimit and (ParaSourceLevel > 0) then
    begin
      vLimit := mOptions.GetCompactionSourceLimit(ParaSourceLevel);
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
  vStrict := mSession.Options.GetStrict(TStrictModes.StrictCompaction);
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
        vIterators[High(vIterators)] := mSession.Tops.NewIterator(t, nil, @vRO);
      end;
    end
    else
    begin
      vIt := TIndexedIterator.Create(mLevels[i].NewIndexIterator(mSession.Tops, mSession.Comparer, nil, @vRO), vStrict);
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
  mSnapTPtrs := Copy(mTPtrs);
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
