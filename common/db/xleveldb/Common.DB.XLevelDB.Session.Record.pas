unit Common.DB.XLevelDB.Session.Record;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Table;

type
  TDeletedTable = record
    Level: Integer;
    Num: Int64;
  end;

  TCompactionPointer = record
    Level: Integer;
    Key: TInternalKey;
  end;

  TNewTable = record
    Level: Integer;
    Table: TTable;
  end;

  TSessionRecord = class
  private
    mCompactionPointers: TList<TCompactionPointer>;
    mDeletedTables: TList<TDeletedTable>;
    mNewTables: TList<TNewTable>;
    mJournalNum: Int64;
    mPrevJournalNum: Int64;
    mNextNum: Int64;
    mSeqNum: UInt64;
    mComparer: string;
    mHasJournalNum: Boolean;
    mHasPrevJournalNum: Boolean;
    mHasNextNum: Boolean;
    mHasSeqNum: Boolean;
    mHasComparer: Boolean;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure SetJournalNum(ParaNum: Int64);
    procedure SetPrevJournalNum(ParaNum: Int64);
    procedure SetNextNum(ParaNum: Int64);
    procedure SetSeqNum(ParaSeq: UInt64);
    procedure SetComparer(const ParaName: string);
    procedure AddTableFile(ParaLevel: Integer; ParaTable: TTable);
    procedure DeleteTableFile(ParaLevel: Integer; ParaNum: Int64);
    procedure AddCompPtr(ParaLevel: Integer; ParaKey: TInternalKey);
    procedure EncodeTo(AStream: TStream);
    procedure Decode(const ParaData: TBytes);
    function Print: string;

    property HasJournalNum: Boolean read mHasJournalNum;
    property JournalNum: Int64 read mJournalNum;
    property HasPrevJournalNum: Boolean read mHasPrevJournalNum;
    property PrevJournalNum: Int64 read mPrevJournalNum;
    property HasNextNum: Boolean read mHasNextNum;
    property NextNum: Int64 read mNextNum;
    property HasSeqNum: Boolean read mHasSeqNum;
    property SeqNum: UInt64 read mSeqNum;
    property CompPtrs: TList<TCompactionPointer> read mCompactionPointers;
  end;

implementation

uses
  System.Math,
  System.Text,
  Common.DB.XLevelDB.Coding;

type
  TRecordType = (
    recComparer = 1,
    recJournalNum = 2,
    recNextNum = 3,
    recSeqNum = 4,
    recCompactionPtr = 5,
    recDeletedTable = 6,
    recNewTable = 7,
    recPrevJournalNum = 8
  );

{ TSessionRecord }

constructor TSessionRecord.Create;
begin
  inherited Create;
  mCompactionPointers := TList<TCompactionPointer>.Create;
  mDeletedTables := TList<TDeletedTable>.Create;
  mNewTables := TList<TNewTable>.Create;
  Reset;
end;

destructor TSessionRecord.Destroy;
begin
  mCompactionPointers.Free;
  mDeletedTables.Free;
  mNewTables.Free;
  inherited Destroy;
end;

procedure TSessionRecord.Reset;
begin
  mCompactionPointers.Clear;
  mDeletedTables.Clear;
  mNewTables.Clear;
  mJournalNum := 0;
  mPrevJournalNum := 0;
  mNextNum := 0;
  mSeqNum := 0;
  mComparer := '';
  mHasJournalNum := False;
  mHasPrevJournalNum := False;
  mHasNextNum := False;
  mHasSeqNum := False;
  mHasComparer := False;
end;

procedure TSessionRecord.SetJournalNum(ParaNum: Int64);
begin
  mJournalNum := ParaNum;
  mHasJournalNum := True;
end;

procedure TSessionRecord.SetPrevJournalNum(ParaNum: Int64);
begin
  mPrevJournalNum := ParaNum;
  mHasPrevJournalNum := True;
end;

procedure TSessionRecord.SetNextNum(ParaNum: Int64);
begin
  mNextNum := ParaNum;
  mHasNextNum := True;
end;

procedure TSessionRecord.SetSeqNum(ParaSeq: UInt64);
begin
  mSeqNum := ParaSeq;
  mHasSeqNum := True;
end;

procedure TSessionRecord.SetComparer(const ParaName: string);
begin
  mComparer := ParaName;
  mHasComparer := True;
end;

procedure TSessionRecord.AddTableFile(ParaLevel: Integer; ParaTable: TTable);
var
  vNewTable: TNewTable;
begin
  vNewTable.Level := ParaLevel;
  vNewTable.Table := ParaTable;
  mNewTables.Add(vNewTable);
end;

procedure TSessionRecord.DeleteTableFile(ParaLevel: Integer; ParaNum: Int64);
var
  vDeletedTable: TDeletedTable;
begin
  vDeletedTable.Level := ParaLevel;
  vDeletedTable.Num := ParaNum;
  mDeletedTables.Add(vDeletedTable);
end;

procedure TSessionRecord.AddCompPtr(ParaLevel: Integer; ParaKey: TInternalKey);
var
  vPtr: TCompactionPointer;
begin
  vPtr.Level := ParaLevel;
  vPtr.Key := ParaKey;
  mCompactionPointers.Add(vPtr);
end;

procedure TSessionRecord.EncodeTo(AStream: TStream);
var
  vPtr: TCompactionPointer;
  vDeleted: TDeletedTable;
  vNew: TNewTable;
begin
  if mHasComparer then
  begin
    PutUvarint(AStream, Ord(TRecordType.recComparer));
    PutBytes(AStream, TEncoding.UTF8.GetBytes(mComparer));
  end;
  if mHasJournalNum then
  begin
    PutUvarint(AStream, Ord(TRecordType.recJournalNum));
    PutUvarint(AStream, mJournalNum);
  end;
  if mHasPrevJournalNum then
  begin
    PutUvarint(AStream, Ord(TRecordType.recPrevJournalNum));
    PutUvarint(AStream, mPrevJournalNum);
  end;
  if mHasNextNum then
  begin
    PutUvarint(AStream, Ord(TRecordType.recNextNum));
    PutUvarint(AStream, mNextNum);
  end;
  if mHasSeqNum then
  begin
    PutUvarint(AStream, Ord(TRecordType.recSeqNum));
    PutUvarint(AStream, mSeqNum);
  end;
  for vPtr in mCompactionPointers do
  begin
    PutUvarint(AStream, Ord(TRecordType.recCompactionPtr));
    PutUvarint(AStream, vPtr.Level);
    PutBytes(AStream, vPtr.Key);
  end;
  for vDeleted in mDeletedTables do
  begin
    PutUvarint(AStream, Ord(TRecordType.recDeletedTable));
    PutUvarint(AStream, vDeleted.Level);
    PutUvarint(AStream, vDeleted.Num);
  end;
  for vNew in mNewTables do
  begin
    PutUvarint(AStream, Ord(TRecordType.recNewTable));
    PutUvarint(AStream, vNew.Level);
    PutUvarint(AStream, vNew.Table.FD.Num);
    PutUvarint(AStream, vNew.Table.Size);
    PutBytes(AStream, vNew.Table.IMin);
    PutBytes(AStream, vNew.Table.IMax);
  end;
end;

procedure TSessionRecord.Decode(const ParaData: TBytes);
var
  vReader: TBytesReader;
  vTag, vLevel, vNum, vSize: UInt64;
  vKey, vMin, vMax, vComparerBytes: TBytes;
  vTable: TTable;
begin
  Reset;
  vReader := TBytesReader.Create(ParaData);
  try
    while not vReader.Eof do
    begin
      vTag := vReader.ReadUvarint;
      case TRecordType(vTag) of
        TRecordType.recComparer:
        begin
          vComparerBytes := vReader.ReadBytes(vReader.ReadUvarint);
          SetComparer(TEncoding.UTF8.GetString(vComparerBytes));
        end;
        TRecordType.recJournalNum:
          SetJournalNum(vReader.ReadUvarint);
        TRecordType.recPrevJournalNum:
          SetPrevJournalNum(vReader.ReadUvarint);
        TRecordType.recNextNum:
          SetNextNum(vReader.ReadUvarint);
        TRecordType.recSeqNum:
          SetSeqNum(vReader.ReadUvarint);
        TRecordType.recCompactionPtr:
        begin
          vLevel := vReader.ReadUvarint;
          vKey := vReader.ReadBytes(vReader.ReadUvarint);
          AddCompPtr(vLevel, vKey);
        end;
        TRecordType.recDeletedTable:
        begin
          vLevel := vReader.ReadUvarint;
          vNum := vReader.ReadUvarint;
          DeleteTableFile(vLevel, vNum);
        end;
        TRecordType.recNewTable:
        begin
          vLevel := vReader.ReadUvarint;
          vNum := vReader.ReadUvarint;
          vSize := vReader.ReadUvarint;
          vMin := vReader.ReadBytes(vReader.ReadUvarint);
          vMax := vReader.ReadBytes(vReader.ReadUvarint);
          vTable := TTable.Create(TFileDesc.Create(vNum, TFileType.FileTypeTable, ''), vSize, vMin, vMax);
          AddTableFile(vLevel, vTable);
        end;
      else
        raise Exception.Create('Unknown record tag');
      end;
    end;
  finally
    vReader.Free;
  end;
end;

function TSessionRecord.Print: string;
var
  vBuilder: TStringBuilder;
  vPtr: TCompactionPointer;
  vDeleted: TDeletedTable;
  vNew: TNewTable;
begin
  vBuilder := TStringBuilder.Create;
  try
    if mHasJournalNum then
      vBuilder.AppendFormat('journal-num: %d, ', [mJournalNum]);
    if mHasNextNum then
      vBuilder.AppendFormat('next-num: %d, ', [mNextNum]);
    if mHasSeqNum then
      vBuilder.AppendFormat('seq-num: %d, ', [mSeqNum]);

    for vPtr in mCompactionPointers do
      vBuilder.AppendFormat('compaction-ptr: %d -> "%s", ', [vPtr.Level, BytesToHex(vPtr.Key)]);
    for vDeleted in mDeletedTables do
      vBuilder.AppendFormat('del-table: %d/%d, ', [vDeleted.Level, vDeleted.Num]);
    for vNew in mNewTables do
      vBuilder.AppendFormat('new-table: %d/%d, ', [vNew.Level, vNew.Table.FD.Num]);
    Result := vBuilder.ToString.TrimRight([',', ' ']);
  finally
    vBuilder.Free;
  end;
end;

end.
