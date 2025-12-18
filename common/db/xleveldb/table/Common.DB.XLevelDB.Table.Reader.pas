unit Common.Db.Xleveldb.Table.Reader;

interface

uses
  Common.Db.Xleveldb.Cache,
  Common.Db.Xleveldb.Comparer,
  Common.Db.Xleveldb.Errors,
  Common.Db.Xleveldb.Filter,
  Common.Db.Xleveldb.Iterator,
  Common.Db.Xleveldb.Opt,
  Common.Db.Xleveldb.Storage,
  Common.Db.Xleveldb.Table,
  Common.DB.XLevelDB.Table.Table,
  Common.DB.XLevelDB.Table.Writer,
  Common.Db.Xleveldb.Util,
  Common.Db.Xleveldb.Util.Crc32,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  ELevelDBTable = class(Exception);
  EReaderReleased = class(ELevelDBTable);
  EIterReleased = class(ELevelDBTable);

  ECorrupted = class(ELevelDBTable)
  public
    Pos: Int64;
    Size: Int64;
    Kind: string;
    Reason: string;
    constructor Create(APos, ASize: Int64; const AKind, AReason: string);
  end;

  TBlock = class
  private
    mBPool: TBufferPool;
    mBH: TBlockHandle;
    mData: TBytes;
    mRestartsLen: Integer;
    mRestartsOffset: Integer;
  public
    constructor Create(ABPool: TBufferPool; ABH: TBlockHandle; AData: TBytes);
    function Seek(Cmp: IComparer; RStart, RLimit: Integer; const Key: TBytes; out Index, Offset: Integer): Boolean;
    function RestartIndex(RStart, RLimit, Offset: Integer): Integer;
    function RestartOffset(Index: Integer): Integer;
    function Entry(Offset: Integer; out Key, Value: TBytes; out NShared, N: Integer): Boolean;
    procedure Release;
  end;

  TReader = class; // Forward declaration

  TBlockIter = class(TInterfacedObject, IIterator)
  private
    mTR: TReader;
    mBlock: TBlock;
    mBlockReleaser: IReleaser;
    mReleaser: IReleaser;
    mKey, mValue: TBytes;
    mOffset: Integer;
    mPrevOffset: Integer;
    mPrevNode: TArray<Integer>;
    mPrevKeys: TBytes;
    mRestartIndex: Integer;
    mDir: (dirReleased, dirSOI, dirEOI, dirBackward, dirForward);
    mRIStart, mRILimit: Integer;
    mOffsetStart, mOffsetRealStart, mOffsetLimit: Integer;
    mErr: Exception;
    procedure SErr(E: Exception);
    procedure Reset;
    function IsFirst: Boolean;
    function IsLast: Boolean;
  public
    constructor Create(ATR: TReader; ABlock: TBlock; ABlockReleaser: IReleaser; ASlice: PRange; AInclLimit: Boolean);
    destructor Destroy; override;
    function First: Boolean;
    function Last: Boolean;
    function Seek(const Key: TBytes): Boolean;
    function Next: Boolean;
    function Prev: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    procedure Release;
    procedure SetReleaser(Releaser: IReleaser);
    function Valid: Boolean;
    function Error: Exception;
  end;

  TIndexIter = class(TInterfacedObject, IIteratorIndexer)
  private
    mBlockIter: TBlockIter;
    mTR: TReader;
    mSlice: PRange;
    mFillCache: Boolean;
  public
    constructor Create(ABlockIter: TBlockIter; ATR: TReader; ASlice: PRange; AFillCache: Boolean);
    destructor Destroy; override;
    function Get: IIterator;
    // IIterator methods
    function First: Boolean;
    function Last: Boolean;
    function Seek(const Key: TBytes): Boolean;
    function Next: Boolean;
    function Prev: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    procedure Release;
    procedure SetReleaser(Releaser: IReleaser);
    function Valid: Boolean;
    function Error: Exception;
  end;

  TReader = class
  private
    mMu: TCriticalSection;
    mFd: TFileDesc;
    mReader: IReader;
    mCache: TNamespaceGetter;
    mErr: Exception;
    mBPool: TBufferPool;
    mO: TOptions;
    mCmp: IComparer;
    mFilter: IFilter;
    mVerifyChecksum: Boolean;
    mDataEnd: Int64;
    mMetaBH, mIndexBH, mFilterBH: TBlockHandle;
    mIndexBlock: TBlock;
    mFilterBlock: TObject; // TFilterBlock
    function BlockKind(const BH: TBlockHandle): string;
    function NewErrCorrupted(Pos, Size: Int64; const Kind, Reason: string): Exception;
    function NewErrCorruptedBH(const BH: TBlockHandle; const Reason: string): Exception;
    function FixErrCorruptedBH(const BH: TBlockHandle; E: Exception): Exception;
    function ReadRawBlock(const BH: TBlockHandle; VerifyChecksum: Boolean): TBytes;
    function ReadBlock(const BH: TBlockHandle; VerifyChecksum: Boolean): TBlock;
    function ReadBlockCached(const BH: TBlockHandle; VerifyChecksum, FillCache: Boolean; out Releaser: IReleaser): TBlock;
    function GetIndexBlock(FillCache: Boolean; out Releaser: IReleaser): TBlock;
    function GetDataIter(const DataBH: TBlockHandle; Slice: PRange; VerifyChecksum, FillCache: Boolean): IIterator;
    function FindInternal(const Key: TBytes; Filtered: Boolean; RO: TReadOptions; NoValue: Boolean; out RKey, Value: TBytes): Boolean;
  public
    constructor Create(AFile: IReader; ASize: Int64; const AFd: TFileDesc; ACache: TNamespaceGetter; ABPool: TBufferPool; AOptions: TOptions);
    destructor Destroy; override;
    function NewIterator(Slice: PRange; RO: TReadOptions): IIterator;
    function Find(const Key: TBytes; Filtered: Boolean; RO: TReadOptions; out RKey, Value: TBytes): Boolean;
    function FindKey(const Key: TBytes; Filtered: Boolean; RO: TReadOptions; out RKey: TBytes): Boolean;
    function Get(const Key: TBytes; RO: TReadOptions; out Value: TBytes): Boolean;
    function OffsetOf(const Key: TBytes): Int64;
    procedure Release;
  end;

function NewReader(AFile: IReader; ASize: Int64; const AFd: TFileDesc; ACache: TNamespaceGetter; ABPool: TBufferPool; AOptions: TOptions): TReader;

implementation

uses
  System.Math,
  Snappy;

{ ECorrupted }

constructor ECorrupted.Create(APos, ASize: Int64; const AKind, AReason: string);
begin
  inherited CreateFmt('leveldb/table: corruption on %s (pos=%d): %s', [AKind, APos, AReason]);
  Pos := APos;
  Size := ASize;
  Kind := AKind;
  Reason := AReason;
end;

{ TBlock }

constructor TBlock.Create(ABPool: TBufferPool; ABH: TBlockHandle; AData: TBytes);
begin
  inherited Create;
  mBPool := ABPool;
  mBH := ABH;
  mData := AData;
  mRestartsLen := TBitConverter.ToUInt32(mData, Length(mData) - 4);
  mRestartsOffset := Length(mData) - (mRestartsLen + 1) * 4;
end;

function TBlock.Seek(Cmp: IComparer; RStart, RLimit: Integer; const Key: TBytes; out Index, Offset: Integer): Boolean;
var
  L, H, Mid, Region, MidOffset, N1, N2, M: Integer;
  KeyMid: TBytes;
begin
  L := RStart;
  H := RLimit - 1;
  while L < H do
  begin
    Mid := (L + H + 1) div 2;
    Region := TBitConverter.ToUInt32(mData, mRestartsOffset + Mid * 4);
    // Inlined Entry
    N1 := Varint.Decode(mData, Region, M);
    N2 := Varint.Decode(mData, Region + M, M);
    SetLength(KeyMid, N1);
    System.Move(mData[Region + M], KeyMid[0], N1);
    if Cmp.Compare(KeyMid, Key) < 0 then
      L := Mid
    else
      H := Mid - 1;
  end;

  Index := L;
  Offset := TBitConverter.ToUInt32(mData, mRestartsOffset + Index * 4);
  Result := True;
end;

function TBlock.RestartIndex(RStart, RLimit, Offset: Integer): Integer;
var
  L, H, Mid: Integer;
begin
  L := RStart;
  H := RLimit - 1;
  while L < H do
  begin
    Mid := (L + H + 1) div 2;
    if TBitConverter.ToUInt32(mData, mRestartsOffset + Mid * 4) < Offset then
      L := Mid
    else
      H := Mid - 1;
  end;
  Result := L;
end;

function TBlock.RestartOffset(Index: Integer): Integer;
begin
  Result := TBitConverter.ToUInt32(mData, mRestartsOffset + 4 * Index);
end;

function TBlock.Entry(Offset: Integer; out Key, Value: TBytes; out NShared, N: Integer): Boolean;
var
  V0, V1, V2, M: Integer;
begin
  Result := False;
  if Offset >= mRestartsOffset then
  begin
    if Offset <> mRestartsOffset then
      raise ECorrupted.Create(0, 0, '', 'entries offset not aligned');
    Exit;
  end;

  V0 := Varint.Decode(mData, Offset, M);
  V1 := Varint.Decode(mData, Offset + M, M);
  V2 := Varint.Decode(mData, Offset + M, M);
  N := M + V1 + V2;
  if (V0 <= 0) or (V1 <= 0) or (V2 <= 0) or (Offset + N > mRestartsOffset) then
    raise ECorrupted.Create(0, 0, '', 'entries corrupted');

  SetLength(Key, V1);
  System.Move(mData[Offset + M], Key[0], V1);
  SetLength(Value, V2);
  System.Move(mData[Offset + M + V1], Value[0], V2);
  NShared := V0;
  Result := True;
end;

procedure TBlock.Release;
begin
  if mBPool <> nil then
    mBPool.Put(mData);
  mBPool := nil;
  mData := nil;
end;

// ... implementation of TBlock ...

// ... implementation of TBlockIter ...

{ TIndexIter }

constructor TIndexIter.Create(ABlockIter: TBlockIter; ATR: TReader; ASlice: PRange; AFillCache: Boolean);
begin
  inherited Create;
  mBlockIter := ABlockIter;
  mTR := ATR;
  mSlice := ASlice;
  mFillCache := AFillCache;
end;

destructor TIndexIter.Destroy;
begin
  mBlockIter.Release;
  inherited;
end;

function TIndexIter.Get: IIterator;
var
  Value: TBytes;
  DataBH: TBlockHandle;
  Slice: PRange;
begin
  Value := mBlockIter.Value;
  if Value = nil then
    Result := nil
  else
  begin
    DecodeBlockHandle(Value, DataBH);
    if mSlice <> nil then
    begin
      if mBlockIter.IsFirst or mBlockIter.IsLast then
        Slice := mSlice
      else
        Slice := nil;
    end
    else
      Slice := nil;
    Result := mTR.GetDataIter(DataBH, Slice, mTR.mVerifyChecksum, mFillCache);
  end;
end;

function TIndexIter.First: Boolean;
begin
  Result := mBlockIter.First;
end;

function TIndexIter.Last: Boolean;
begin
  Result := mBlockIter.Last;
end;

function TIndexIter.Seek(const Key: TBytes): Boolean;
begin
  Result := mBlockIter.Seek(Key);
end;

function TIndexIter.Next: Boolean;
begin
  Result := mBlockIter.Next;
end;

function TIndexIter.Prev: Boolean;
begin
  Result := mBlockIter.Prev;
end;

function TIndexIter.Key: TBytes;
begin
  Result := mBlockIter.Key;
end;

function TIndexIter.Value: TBytes;
begin
  Result := mBlockIter.Value;
end;

procedure TIndexIter.Release;
begin
  mBlockIter.Release;
end;

procedure TIndexIter.SetReleaser(Releaser: IReleaser);
begin
  mBlockIter.SetReleaser(Releaser);
end;

function TIndexIter.Valid: Boolean;
begin
  Result := mBlockIter.Valid;
end;

function TIndexIter.Error: Exception;
begin
  Result := mBlockIter.Error;
end;

// ... implementation of other classes ...

constructor TBlockIter.Create(ATR: TReader; ABlock: TBlock; ABlockReleaser: IReleaser; ASlice: PRange; AInclLimit: Boolean);
begin
  inherited Create;
  mTR := ATR;
  mBlock := ABlock;
  mBlockReleaser := ABlockReleaser;
  mKey := TBytes.Create;
  mDir := dirSOI;
  mRIStart := 0;
  mRILimit := mBlock.mRestartsLen;
  mOffsetStart := 0;
  mOffsetRealStart := 0;
  mOffsetLimit := mBlock.mRestartsOffset;

  if ASlice <> nil then
  begin
    if ASlice.Start <> nil then
    begin
      if Seek(ASlice.Start) then
      begin
        mRIStart := mBlock.RestartIndex(mRestartIndex, mBlock.mRestartsLen, mPrevOffset);
        mOffsetStart := mBlock.RestartOffset(mRIStart);
        mOffsetRealStart := mPrevOffset;
      end
      else
      begin
        mRIStart := mBlock.mRestartsLen;
        mOffsetStart := mBlock.mRestartsOffset;
        mOffsetRealStart := mBlock.mRestartsOffset;
      end;
    end;
    if ASlice.Limit <> nil then
    begin
      if Seek(ASlice.Limit) and (not AInclLimit or Next) then
      begin
        mOffsetLimit := mPrevOffset;
        mRILimit := mRestartIndex + 1;
      end;
    end;
    Reset;
    if mOffsetStart > mOffsetLimit then
      SErr(ELevelDBTable.Create('leveldb/table: invalid slice range'));
  end;
end;

destructor TBlockIter.Destroy;
begin
  Release;
  inherited;
end;

procedure TBlockIter.SErr(E: Exception);
begin
  mErr := E;
  mKey := nil;
  mValue := nil;
  mPrevNode := nil;
  mPrevKeys := nil;
end;

procedure TBlockIter.Reset;
begin
  if mDir = dirBackward then
  begin
    SetLength(mPrevNode, 0);
    SetLength(mPrevKeys, 0);
  end;
  mRestartIndex := mRIStart;
  mOffset := mOffsetStart;
  mDir := dirSOI;
  SetLength(mKey, 0);
  mValue := nil;
end;

function TBlockIter.IsFirst: Boolean;
begin
  case mDir of
    dirForward: Result := mPrevOffset = mOffsetRealStart;
    dirBackward: Result := (Length(mPrevNode) = 1) and (mRestartIndex = mRIStart);
  else
    Result := False;
  end;
end;

function TBlockIter.IsLast: Boolean;
begin
  case mDir of
    dirForward, dirBackward: Result := mOffset = mOffsetLimit;
  else
    Result := False;
  end;
end;

function TBlockIter.First: Boolean;
begin
  Result := False;
  if mErr <> nil then Exit;
  if mDir = dirReleased then
  begin
    mErr := EIterReleased.Create('leveldb/table: iterator released');
    Exit;
  end;

  if mDir = dirBackward then
  begin
    SetLength(mPrevNode, 0);
    SetLength(mPrevKeys, 0);
  end;
  mDir := dirSOI;
  Result := Next;
end;

function TBlockIter.Last: Boolean;
begin
  Result := False;
  if mErr <> nil then Exit;
  if mDir = dirReleased then
  begin
    mErr := EIterReleased.Create('leveldb/table: iterator released');
    Exit;
  end;

  if mDir = dirBackward then
  begin
    SetLength(mPrevNode, 0);
    SetLength(mPrevKeys, 0);
  end;
  mDir := dirEOI;
  Result := Prev;
end;

function TBlockIter.Seek(const Key: TBytes): Boolean;
var
  RI, Offset: Integer;
begin
  Result := False;
  if mErr <> nil then Exit;
  if mDir = dirReleased then
  begin
    mErr := EIterReleased.Create('leveldb/table: iterator released');
    Exit;
  end;

  if not mBlock.Seek(mTR.mCmp, mRIStart, mRILimit, Key, RI, Offset) then
  begin
    SErr(ECorrupted.Create(0, 0, '', 'seek failed'));
    Exit;
  end;
  mRestartIndex := RI;
  mOffset := Max(mOffsetStart, Offset);
  if (mDir = dirSOI) or (mDir = dirEOI) then
    mDir := dirForward;
  while Next do
  begin
    if mTR.mCmp.Compare(mKey, Key) >= 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TBlockIter.Next: Boolean;
var
  NShared, N: Integer;
  LKey, LValue: TBytes;
begin
  Result := False;
  if (mDir = dirEOI) or (mErr <> nil) then Exit;
  if mDir = dirReleased then
  begin
    mErr := EIterReleased.Create('leveldb/table: iterator released');
    Exit;
  end;

  if mDir = dirSOI then
  begin
    mRestartIndex := mRIStart;
    mOffset := mOffsetStart;
  end
  else if mDir = dirBackward then
  begin
    SetLength(mPrevNode, 0);
    SetLength(mPrevKeys, 0);
  end;

  while mOffset < mOffsetRealStart do
  begin
    if not mBlock.Entry(mOffset, LKey, LValue, NShared, N) then
    begin
      mDir := dirEOI;
      Exit;
    end;
    SetLength(mKey, NShared + Length(LKey));
    System.Move(LKey[0], mKey[NShared], Length(LKey));
    mValue := LValue;
    mOffset := mOffset + N;
  end;

  if mOffset >= mOffsetLimit then
  begin
    mDir := dirEOI;
    if mOffset <> mOffsetLimit then
      SErr(mTR.NewErrCorruptedBH(mBlock.mBH, 'entries offset not aligned'));
    Exit;
  end;

  if not mBlock.Entry(mOffset, LKey, LValue, NShared, N) then
  begin
    mDir := dirEOI;
    Exit;
  end;
  SetLength(mKey, NShared + Length(LKey));
  System.Move(LKey[0], mKey[NShared], Length(LKey));
  mValue := LValue;
  mPrevOffset := mOffset;
  mOffset := mOffset + N;
  mDir := dirForward;
  Result := True;
end;

function TBlockIter.Prev: Boolean;
var
  RI, Offset, NShared, N, Ko, Vo, Vl, NodeLen: Integer;
  LKey, LValue: TBytes;
begin
  Result := False;
  if (mDir = dirSOI) or (mErr <> nil) then Exit;
  if mDir = dirReleased then
  begin
    mErr := EIterReleased.Create('leveldb/table: iterator released');
    Exit;
  end;

  if mDir = dirForward then
  begin
    mOffset := mPrevOffset;
    if mOffset = mOffsetRealStart then
    begin
      mDir := dirSOI;
      Exit;
    end;
    RI := mBlock.RestartIndex(mRestartIndex, mRILimit, mOffset);
    mDir := dirBackward;
  end
  else if mDir = dirEOI then
  begin
    mRestartIndex := mRILimit;
    mOffset := mOffsetLimit;
    if mOffset = mOffsetRealStart then
    begin
      mDir := dirSOI;
      Exit;
    end;
    RI := mRILimit - 1;
    mDir := dirBackward;
  end
  else if Length(mPrevNode) = 1 then
  begin
    mOffset := mPrevNode[0];
    SetLength(mPrevNode, 0);
    if mRestartIndex = mRIStart then
    begin
      mDir := dirSOI;
      Exit;
    end;
    Dec(mRestartIndex);
    RI := mRestartIndex;
  end
  else
  begin
    NodeLen := Length(mPrevNode) - 3;
    Ko := mPrevNode[NodeLen];
    SetLength(mKey, Length(mPrevKeys) - Ko);
    System.Move(mPrevKeys[Ko], mKey[0], Length(mKey));
    SetLength(mPrevKeys, Ko);
    Vo := mPrevNode[NodeLen + 1];
    Vl := Vo + mPrevNode[NodeLen + 2];
    SetLength(mValue, Vl - Vo);
    System.Move(mBlock.mData[Vo], mValue[0], Length(mValue));
    mOffset := Vl;
    SetLength(mPrevNode, NodeLen);
    Result := True;
    Exit;
  end;

  SetLength(mKey, 0);
  mValue := nil;
  Offset := mBlock.RestartOffset(RI);
  if Offset = mOffset then
  begin
    Dec(RI);
    if RI < 0 then
    begin
      mDir := dirSOI;
      Exit;
    end;
    Offset := mBlock.RestartOffset(RI);
  end;
  SetLength(mPrevNode, 1);
  mPrevNode[0] := Offset;

  while True do
  begin
    if not mBlock.Entry(Offset, LKey, LValue, NShared, N) then
    begin
      SErr(mTR.NewErrCorruptedBH(mBlock.mBH, 'entry read failed'));
      Exit;
    end;
    if Offset >= mOffsetRealStart then
    begin
      if mValue <> nil then
      begin
        SetLength(mPrevNode, Length(mPrevNode) + 3);
        mPrevNode[Length(mPrevNode) - 3] := Length(mPrevKeys);
        mPrevNode[Length(mPrevNode) - 2] := Offset - Length(mValue);
        mPrevNode[Length(mPrevNode) - 1] := Length(mValue);
        SetLength(mPrevKeys, Length(mPrevKeys) + Length(mKey));
        System.Move(mKey[0], mPrevKeys[Length(mPrevKeys) - Length(mKey)], Length(mKey));
      end;
      mValue := LValue;
    end;
    SetLength(mKey, NShared + Length(LKey));
    System.Move(LKey[0], mKey[NShared], Length(LKey));
    Offset := Offset + N;
    if Offset >= mOffset then
    begin
      if Offset <> mOffset then
      begin
        SErr(mTR.NewErrCorruptedBH(mBlock.mBH, 'entries offset not aligned'));
        Exit;
      end;
      Break;
    end;
  end;
  mRestartIndex := RI;
  mOffset := Offset;
  Result := True;
end;

function TBlockIter.Key: TBytes;
begin
  if (mErr <> nil) or (mDir <= dirEOI) then
    Result := nil
  else
    Result := mKey;
end;

function TBlockIter.Value: TBytes;
begin
  if (mErr <> nil) or (mDir <= dirEOI) then
    Result := nil
  else
    Result := mValue;
end;

procedure TBlockIter.Release;
begin
  if mDir <> dirReleased then
  begin
    mTR := nil;
    mBlock := nil;
    mPrevNode := nil;
    mPrevKeys := nil;
    mKey := nil;
    mValue := nil;
    mDir := dirReleased;
    if mBlockReleaser <> nil then
    begin
      mBlockReleaser.Release;
      mBlockReleaser := nil;
    end;
    if mReleaser <> nil then
    begin
      mReleaser.Release;
      mReleaser := nil;
    end;
  end;
end;

procedure TBlockIter.SetReleaser(Releaser: IReleaser);
begin
  if mDir = dirReleased then
    raise EReleased.Create('leveldb/util: released');
  if (mReleaser <> nil) and (Releaser <> nil) then
    raise EHasReleaser.Create('leveldb/util: releaser already defined');
  mReleaser := Releaser;
end;

function TBlockIter.Valid: Boolean;
begin
  Result := (mErr = nil) and ((mDir = dirBackward) or (mDir = dirForward));
end;

function TBlockIter.Error: Exception;
begin
  Result := mErr;
end;

// ... implementation of other classes ...


end.
