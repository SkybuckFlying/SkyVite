unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord;

interface

uses
  System.Classes,
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
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version;

type
  // These numbers are written to disk and should not be changed.
  TRecordType = (
    recComparer = 1,
    recJournalNum = 2,
    recNextFileNum = 3,
    recSeqNum = 4,
    recCompPtr = 5,
    recDelTable = 6,
    recAddTable = 7,
    // 8 was used for large value refs
    recPrevJournalNum = 9
  );

  TcpRecord = record
    Level: Integer;
    Ikey: TInternalKey;
  end;

  TatRecord = record
    Level: Integer;
    Num: Int64;
    Size: Int64;
    Imin: TInternalKey;
    Imax: TInternalKey;
  end;

  TdtRecord = record
    Level: Integer;
    Num: Int64;
  end;

  TSessionRecord = class
  private
    mHasRec: Integer;
    mComparer: string;
    mJournalNum: Int64;
    mPrevJournalNum: Int64;
    mNextFileNum: Int64;
    mSeqNum: UInt64;
    mCompPtrs: TArray<TcpRecord>;
    mAddedTables: TArray<TatRecord>;
    mDeletedTables: TArray<TdtRecord>;

    mScratch: array[0..9] of Byte; // MaxVarintLen64 is 10
    mErr: Exception;

    procedure PutUvarint(ParaW: TStream; ParaX: UInt64);
    procedure PutVarint(ParaW: TStream; ParaX: Int64);
    procedure PutBytes(ParaW: TStream; const ParaX: TBytes);
    function ReadUvarintMayEOF(const ParaField: string; ParaR: TStream; ParaMayEOF: Boolean): UInt64;
    function ReadUvarint(const ParaField: string; ParaR: TStream): UInt64;
    function ReadVarint(const ParaField: string; ParaR: TStream): Int64;
    function ReadBytes(const ParaField: string; ParaR: TStream): TBytes;
    function ReadLevel(const ParaField: string; ParaR: TStream): Integer;
  public
    function Has(ParaRec: TRecordType): Boolean;
    procedure SetComparer(const ParaName: string);
    procedure SetJournalNum(ParaNum: Int64);
    procedure SetPrevJournalNum(ParaNum: Int64);
    procedure SetNextFileNum(ParaNum: Int64);
    procedure SetSeqNum(ParaNum: UInt64);
    procedure AddCompPtr(ParaLevel: Integer; const ParaIkey: TInternalKey);
    procedure ResetCompPtrs;
    procedure AddTable(ParaLevel: Integer; ParaNum, ParaSize: Int64; const ParaImin, ParaImax: TInternalKey);
    procedure ResetAddedTables;
    procedure DelTable(ParaLevel: Integer; ParaNum: Int64);
    procedure ResetDeletedTables;

    function Encode(ParaW: TStream): Exception;
    function Decode(ParaR: TStream): Exception;

    property Comparer: string read mComparer;
    property JournalNum: Int64 read mJournalNum;
    property PrevJournalNum: Int64 read mPrevJournalNum;
    property NextFileNum: Int64 read mNextFileNum;
    property SeqNum: UInt64 read mSeqNum;
    property CompPtrs: TArray<TcpRecord> read mCompPtrs;
    property AddedTables: TArray<TatRecord> read mAddedTables;
    property DeletedTables: TArray<TdtRecord> read mDeletedTables;
  end;

  EManifestCorrupted = class(ECorrupted)
  public
    Field: string;
    Reason: string;
    constructor Create(const ParaField, ParaReason: string);
  end;

implementation

{ TSessionRecord }

procedure TSessionRecord.AddCompPtr(ParaLevel: Integer; const ParaIkey: TInternalKey);
begin
  mHasRec := mHasRec or (1 shl Ord(recCompPtr));
  SetLength(mCompPtrs, Length(mCompPtrs) + 1);
  mCompPtrs[High(mCompPtrs)].Level := ParaLevel;
  mCompPtrs[High(mCompPtrs)].Ikey := ParaIkey;
end;

procedure TSessionRecord.AddTable(ParaLevel: Integer; ParaNum, ParaSize: Int64; const ParaImin, ParaImax: TInternalKey);
begin
  mHasRec := mHasRec or (1 shl Ord(recAddTable));
  SetLength(mAddedTables, Length(mAddedTables) + 1);
  mAddedTables[High(mAddedTables)].Level := ParaLevel;
  mAddedTables[High(mAddedTables)].Num := ParaNum;
  mAddedTables[High(mAddedTables)].Size := ParaSize;
  mAddedTables[High(mAddedTables)].Imin := ParaImin;
  mAddedTables[High(mAddedTables)].Imax := ParaImax;
end;

function TSessionRecord.Decode(ParaR: TStream): Exception;
var
  vRec: UInt64;
  vX: TBytes;
  vLevel: Integer;
  vNum: Int64;
  vSize: Int64;
  vImin, vImax: TBytes;
begin
  mErr := nil;
  while mErr = nil do
  begin
    vRec := ReadUvarintMayEOF('field-header', ParaR, True);
    if mErr <> nil then
    begin
      // Go implementation returns nil if err == io.EOF
      // We check if it's an EOF exception (ReadUvarintMayEOF should handle it)
      // For now, if mErr is nil, it means EOF was reached successfully.
      if mErr is EEOF then
        Exit(nil);
      Exit(mErr);
    end;

    case TRecordType(vRec) of
      recComparer:
        begin
          vX := ReadBytes('comparer', ParaR);
          if mErr = nil then
            SetComparer(TEncoding.UTF8.GetString(vX));
        end;
      recJournalNum:
        SetJournalNum(ReadVarint('journal-num', ParaR));
      recPrevJournalNum:
        SetPrevJournalNum(ReadVarint('prev-journal-num', ParaR));
      recNextFileNum:
        SetNextFileNum(ReadVarint('next-file-num', ParaR));
      recSeqNum:
        SetSeqNum(ReadUvarint('seq-num', ParaR));
      recCompPtr:
        begin
          vLevel := ReadLevel('comp-ptr.level', ParaR);
          vX := ReadBytes('comp-ptr.ikey', ParaR);
          if mErr = nil then
            AddCompPtr(vLevel, TInternalKey(vX));
        end;
      recAddTable:
        begin
          vLevel := ReadLevel('add-table.level', ParaR);
          vNum := ReadVarint('add-table.num', ParaR);
          vSize := ReadVarint('add-table.size', ParaR);
          vImin := ReadBytes('add-table.imin', ParaR);
          vImax := ReadBytes('add-table.imax', ParaR);
          if mErr = nil then
            AddTable(vLevel, vNum, vSize, TInternalKey(vImin), TInternalKey(vImax));
        end;
      recDelTable:
        begin
          vLevel := ReadLevel('del-table.level', ParaR);
          vNum := ReadVarint('del-table.num', ParaR);
          if mErr = nil then
            DelTable(vLevel, vNum);
        end;
    end;
  end;
  Result := mErr;
end;

procedure TSessionRecord.DelTable(ParaLevel: Integer; ParaNum: Int64);
begin
  mHasRec := mHasRec or (1 shl Ord(recDelTable));
  SetLength(mDeletedTables, Length(mDeletedTables) + 1);
  mDeletedTables[High(mDeletedTables)].Level := ParaLevel;
  mDeletedTables[High(mDeletedTables)].Num := ParaNum;
end;

function TSessionRecord.Encode(ParaW: TStream): Exception;
var
  vCP: TcpRecord;
  vDT: TdtRecord;
  vAT: TatRecord;
begin
  mErr := nil;
  if Has(recComparer) then
  begin
    PutUvarint(ParaW, Ord(recComparer));
    PutBytes(ParaW, TEncoding.UTF8.GetBytes(mComparer));
  end;
  if Has(recJournalNum) then
  begin
    PutUvarint(ParaW, Ord(recJournalNum));
    PutVarint(ParaW, mJournalNum);
  end;
  if Has(recNextFileNum) then
  begin
    PutUvarint(ParaW, Ord(recNextFileNum));
    PutVarint(ParaW, mNextFileNum);
  end;
  if Has(recSeqNum) then
  begin
    PutUvarint(ParaW, Ord(recSeqNum));
    PutUvarint(ParaW, mSeqNum);
  end;
  for vCP in mCompPtrs do
  begin
    PutUvarint(ParaW, Ord(recCompPtr));
    PutUvarint(ParaW, UInt64(vCP.Level));
    PutBytes(ParaW, TBytes(vCP.Ikey));
  end;
  for vDT in mDeletedTables do
  begin
    PutUvarint(ParaW, Ord(recDelTable));
    PutUvarint(ParaW, UInt64(vDT.Level));
    PutVarint(ParaW, vDT.Num);
  end;
  for vAT in mAddedTables do
  begin
    PutUvarint(ParaW, Ord(recAddTable));
    PutUvarint(ParaW, UInt64(vAT.Level));
    PutVarint(ParaW, vAT.Num);
    PutVarint(ParaW, vAT.Size);
    PutBytes(ParaW, TBytes(vAT.Imin));
    PutBytes(ParaW, TBytes(vAT.Imax));
  end;
  Result := mErr;
end;

function TSessionRecord.Has(ParaRec: TRecordType): Boolean;
begin
  Result := (mHasRec and (1 shl Ord(ParaRec))) <> 0;
end;

procedure TSessionRecord.PutBytes(ParaW: TStream; const ParaX: TBytes);
begin
  if mErr <> nil then Exit;
  PutUvarint(ParaW, UInt64(Length(ParaX)));
  if mErr <> nil then Exit;
  try
    ParaW.WriteBuffer(ParaX[0], Length(ParaX));
  except
    on E: Exception do mErr := E;
  end;
end;

procedure TSessionRecord.PutUvarint(ParaW: TStream; ParaX: UInt64);
var
  vN: Integer;
begin
  if mErr <> nil then Exit;
  vN := Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.PutUvarint(mScratch, ParaX);
  try
    ParaW.WriteBuffer(mScratch[0], vN);
  except
    on E: Exception do mErr := E;
  end;
end;

procedure TSessionRecord.PutVarint(ParaW: TStream; ParaX: Int64);
begin
  if ParaX < 0 then
    raise Exception.Create('invalid negative value');
  PutUvarint(ParaW, UInt64(ParaX));
end;

function TSessionRecord.ReadBytes(const ParaField: string; ParaR: TStream): TBytes;
var
  vN: UInt64;
begin
  if mErr <> nil then Exit(nil);
  vN := ReadUvarint(ParaField, ParaR);
  if mErr <> nil then Exit(nil);
  SetLength(Result, vN);
  try
    if ParaR.Read(Result[0], Integer(vN)) <> Integer(vN) then
      mErr := EManifestCorrupted.Create(ParaField, 'short read');
  except
    on E: Exception do mErr := E;
  end;
end;

function TSessionRecord.ReadLevel(const ParaField: string; ParaR: TStream): Integer;
begin
  if mErr <> nil then Exit(0);
  Result := Integer(ReadUvarint(ParaField, ParaR));
end;

function TSessionRecord.ReadUvarint(const ParaField: string; ParaR: TStream): UInt64;
begin
  Result := ReadUvarintMayEOF(ParaField, ParaR, False);
end;

function TSessionRecord.ReadUvarintMayEOF(const ParaField: string; ParaR: TStream; ParaMayEOF: Boolean): UInt64;
var
  vN: Integer;
begin
  if mErr <> nil then Exit(0);
  try
    vN := Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Uvarint(ParaR, Result);
    if vN <= 0 then
    begin
      if (not ParaMayEOF) then
        mErr := EManifestCorrupted.Create(ParaField, 'short read')
      else
        mErr := EEOF.Create('EOF'); // Custom exception for EOF
    end;
  except
    on E: Exception do mErr := E;
  end;
end;

function TSessionRecord.ReadVarint(const ParaField: string; ParaR: TStream): Int64;
begin
  Result := Int64(ReadUvarintMayEOF(ParaField, ParaR, False));
  if Result < 0 then
    mErr := EManifestCorrupted.Create(ParaField, 'invalid negative value');
end;

procedure TSessionRecord.ResetAddedTables;
begin
  mHasRec := mHasRec and (not (1 shl Ord(recAddTable)));
  mAddedTables := nil;
end;

procedure TSessionRecord.ResetCompPtrs;
begin
  mHasRec := mHasRec and (not (1 shl Ord(recCompPtr)));
  mCompPtrs := nil;
end;

procedure TSessionRecord.ResetDeletedTables;
begin
  mHasRec := mHasRec and (not (1 shl Ord(recDelTable)));
  mDeletedTables := nil;
end;

procedure TSessionRecord.SetComparer(const ParaName: string);
begin
  mHasRec := mHasRec or (1 shl Ord(recComparer));
  mComparer := ParaName;
end;

procedure TSessionRecord.SetJournalNum(ParaNum: Int64);
begin
  mHasRec := mHasRec or (1 shl Ord(recJournalNum));
  mJournalNum := ParaNum;
end;

procedure TSessionRecord.SetNextFileNum(ParaNum: Int64);
begin
  mHasRec := mHasRec or (1 shl Ord(recNextFileNum));
  mNextFileNum := ParaNum;
end;

procedure TSessionRecord.SetPrevJournalNum(ParaNum: Int64);
begin
  mHasRec := mHasRec or (1 shl Ord(recPrevJournalNum));
  mPrevJournalNum := ParaNum;
end;

procedure TSessionRecord.SetSeqNum(ParaNum: UInt64);
begin
  mHasRec := mHasRec or (1 shl Ord(recSeqNum));
  mSeqNum := ParaNum;
end;

{ EManifestCorrupted }

constructor EManifestCorrupted.Create(const ParaField, ParaReason: string);
begin
  inherited Create(Format('leveldb: manifest corrupted (field ''%s''): %s', [ParaField, ParaReason]));
  Field := ParaField;
  Reason := ParaReason;
end;

end.
