unit common.db.xleveldb.table.writer;

interface

uses
  common.db.xleveldb.comparer,
  common.db.xleveldb.filter,
  common.db.xleveldb.opt,
  common.db.xleveldb.table,
  Common.DB.XLevelDB.Table.Reader,
  Common.DB.XLevelDB.Table.Table,
  common.db.xleveldb.util,
  System.Classes,
  System.SysUtils;

type
  TBlockWriter = class
  private
    FRestartInterval: Integer;
    FBuf: TBuffer;
    FNEntries: Integer;
    FPrevKey: TBytes;
    FRestarts: TArray<UInt32>;
    FScratch: TBytes;
  public
    constructor Create(ARestartInterval: Integer);
    destructor Destroy; override;
    procedure Append(const Key, Value: TBytes);
    procedure Finish;
    procedure Reset;
    function BytesLen: Integer;
  end;

  TFilterWriter = class
  private
    FGenerator: IFilterGenerator;
    FBuf: TBuffer;
    FNKeys: Integer;
    FOffsets: TArray<UInt32>;
    procedure Generate;
  public
    constructor Create(AGenerator: IFilterGenerator);
    destructor Destroy; override;
    procedure Add(const Key: TBytes);
    procedure Flush(Offset: UInt64);
    procedure Finish;
  end;

  TWriter = class
  private
    FWriter: TStream;
    FErr: Exception;
    FCmp: IComparer;
    FFilter: IFilter;
    FCompression: TCompression;
    FBlockSize: Integer;
    FDataBlock: TBlockWriter;
    FIndexBlock: TBlockWriter;
    FFilterBlock: TFilterWriter;
    FPendingBH: TBlockHandle;
    FOffset: UInt64;
    FNEntries: Integer;
    FScratch: TBytes;
    FComparerScratch: TBytes;
    FCompressionScratch: TBytes;
    function WriteBlock(Buf: TBuffer; ACompression: TCompression): TBlockHandle;
    procedure FlushPendingBH(const Key: TBytes);
    procedure FinishBlock;
  public
    constructor Create(AWriter: TStream; AOptions: TOptions);
    destructor Destroy; override;
    procedure Append(const Key, Value: TBytes);
    function BlocksLen: Integer;
    function EntriesLen: Integer;
    function BytesLen: Integer;
    function Close: Exception;
  end;

function NewWriter(AWriter: TStream; AOptions: TOptions): TWriter;

implementation

uses
  System.Hash,
  Snappy;

function SharedPrefixLen(const A, B: TBytes): Integer;
var
  I, N: Integer;
begin
  I := 0;
  N := Length(A);
  if N > Length(B) then
    N := Length(B);
  while (I < N) and (A[I] = B[I]) do
    Inc(I);
  Result := I;
end;

{ TBlockWriter }

constructor TBlockWriter.Create(ARestartInterval: Integer);
begin
  inherited Create;
  FRestartInterval := ARestartInterval;
  FBuf := TBuffer.Create;
  SetLength(FRestarts, 0);
  SetLength(FScratch, 20);
end;

destructor TBlockWriter.Destroy;
begin
  FBuf.Free;
  inherited;
end;

procedure TBlockWriter.Append(const Key, Value: TBytes);
var
  NShared, N: Integer;
begin
  NShared := 0;
  if FNEntries mod FRestartInterval = 0 then
    SetLength(FRestarts, Length(FRestarts) + 1);
    FRestarts[High(FRestarts)] := FBuf.Len
  else
    NShared := SharedPrefixLen(FPrevKey, Key);

  N := TZip.WriteUvarint(FScratch, 0, NShared);
  N := N + TZip.WriteUvarint(FScratch, N, Length(Key) - NShared);
  N := N + TZip.WriteUvarint(FScratch, N, Length(Value));
  FBuf.Write(FScratch, 0, N);
  FBuf.Write(Key, NShared, Length(Key) - NShared);
  FBuf.Write(Value, 0, Length(Value));
  FPrevKey := Key;
  Inc(FNEntries);
end;

procedure TBlockWriter.Finish;
var
  I: Integer;
  Buf4: TBytes;
begin
  if FNEntries = 0 then
  begin
    SetLength(FRestarts, 1);
    FRestarts[0] := 0;
  end;
  SetLength(FRestarts, Length(FRestarts) + 1);
  FRestarts[High(FRestarts)] := Length(FRestarts) - 1;

  SetLength(Buf4, 4);
  for I := 0 to High(FRestarts) do
  begin
    TBitConverter.GetBytes(FRestarts[I]).CopyTo(Buf4, 0);
    FBuf.Write(Buf4, 0, 4);
  end;
end;

procedure TBlockWriter.Reset;
begin
  FBuf.Clear;
  FNEntries := 0;
  SetLength(FRestarts, 0);
end;

function TBlockWriter.BytesLen: Integer;
var
  RestartsLen: Integer;
begin
  RestartsLen := Length(FRestarts);
  if RestartsLen = 0 then
    RestartsLen := 1;
  Result := FBuf.Len + 4 * RestartsLen + 4;
end;

{ TFilterWriter }

constructor TFilterWriter.Create(AGenerator: IFilterGenerator);
begin
  inherited Create;
  FGenerator := AGenerator;
  FBuf := TBuffer.Create;
  SetLength(FOffsets, 0);
end;

destructor TFilterWriter.Destroy;
begin
  FBuf.Free;
  inherited;
end;

procedure TFilterWriter.Add(const Key: TBytes);
begin
  if FGenerator <> nil then
  begin
    FGenerator.Add(Key);
    Inc(FNKeys);
  end;
end;

procedure TFilterWriter.Flush(Offset: UInt64);
var
  X: Integer;
begin
  if FGenerator <> nil then
  begin
    X := Offset div FilterBase;
    while X > Length(FOffsets) do
      Generate;
  end;
end;

procedure TFilterWriter.Finish;
var
  I: Integer;
  Buf4: TBytes;
begin
  if FGenerator <> nil then
  begin
    if FNKeys > 0 then
      Generate;
    SetLength(FOffsets, Length(FOffsets) + 1);
    FOffsets[High(FOffsets)] := FBuf.Len;

    SetLength(Buf4, 4);
    for I := 0 to High(FOffsets) do
    begin
      TBitConverter.GetBytes(FOffsets[I]).CopyTo(Buf4, 0);
      FBuf.Write(Buf4, 0, 4);
    end;
    FBuf.WriteByte(FilterBaseLg);
  end;
end;

procedure TFilterWriter.Generate;
begin
  SetLength(FOffsets, Length(FOffsets) + 1);
  FOffsets[High(FOffsets)] := FBuf.Len;
  if FNKeys > 0 then
  begin
    FGenerator.Generate(FBuf);
    FNKeys := 0;
  end;
end;

{ TWriter }

constructor TWriter.Create(AWriter: TStream; AOptions: TOptions);
begin
  inherited Create;
  FWriter := AWriter;
  FCmp := AOptions.GetComparer;
  FFilter := AOptions.GetFilter;
  FCompression := AOptions.GetCompression;
  FBlockSize := AOptions.GetBlockSize;
  FDataBlock := TBlockWriter.Create(AOptions.GetBlockRestartInterval);
  FIndexBlock := TBlockWriter.Create(1);
  if FFilter <> nil then
    FFilterBlock := TFilterWriter.Create(FFilter.NewGenerator);
  SetLength(FScratch, 50);
end;

destructor TWriter.Destroy;
begin
  FDataBlock.Free;
  FIndexBlock.Free;
  if FFilterBlock <> nil then
    FFilterBlock.Free;
  inherited;
end;

function TWriter.WriteBlock(Buf: TBuffer; ACompression: TCompression): TBlockHandle;
var
  B: TBytes;
  N: Integer;
  Checksum: Cardinal;
  Compressed: TBytes;
begin
  if ACompression = opt.SnappyCompression then
  begin
    N := TSnappy.MaxEncodedLen(Buf.Len) + BlockTrailerLen;
    if Length(FCompressionScratch) < N then
      SetLength(FCompressionScratch, N);
    SetLength(Compressed, TSnappy.Encode(Buf.Bytes, 0, Buf.Len, FCompressionScratch, 0));
    N := Length(Compressed);
    SetLength(B, N + BlockTrailerLen);
    System.Move(Compressed[0], B[0], N);
    B[N] := BlockTypeSnappyCompression;
  end
  else
  begin
    B := Buf.Bytes;
    SetLength(B, Length(B) + BlockTrailerLen);
    B[Length(B) - BlockTrailerLen] := BlockTypeNoCompression;
  end;

  N := Length(B) - 4;
  Checksum := THashCRC32.GetHashValue(B, 0, N);
  TBitConverter.GetBytes(Checksum).CopyTo(B, N);

  FWriter.Write(B, 0, Length(B));
  Result.Offset := FOffset;
  Result.Length := Length(B) - BlockTrailerLen;
  Inc(FOffset, Length(B));
end;

procedure TWriter.FlushPendingBH(const Key: TBytes);
var
  Separator: TBytes;
  N: Integer;
begin
  if FPendingBH.Length = 0 then
    Exit;

  if Length(Key) = 0 then
    Separator := FCmp.Successor(FComparerScratch, FDataBlock.FPrevKey)
  else
    Separator := FCmp.Separator(FComparerScratch, FDataBlock.FPrevKey, Key);

  if Separator = nil then
    Separator := FDataBlock.FPrevKey
  else
    FComparerScratch := Separator;

  N := EncodeBlockHandle(FScratch, FPendingBH);
  FIndexBlock.Append(Separator, Copy(FScratch, 0, N));
  FDataBlock.FPrevKey := nil;
  FPendingBH.Length := 0;
end;

procedure TWriter.FinishBlock;
var
  BH: TBlockHandle;
begin
  FDataBlock.Finish;
  BH := WriteBlock(FDataBlock.FBuf, FCompression);
  FPendingBH := BH;
  FDataBlock.Reset;
  if FFilterBlock <> nil then
    FFilterBlock.Flush(FOffset);
end;

procedure TWriter.Append(const Key, Value: TBytes);
begin
  if FErr <> nil then
    raise FErr;
  if (FNEntries > 0) and (FCmp.Compare(FDataBlock.FPrevKey, Key) >= 0) then
  begin
    FErr := Exception.CreateFmt('leveldb/table: Writer: keys are not in increasing order: "%s", "%s"', [TEncoding.UTF8.GetString(FDataBlock.FPrevKey), TEncoding.UTF8.GetString(Key)]);
    raise FErr;
  end;

  FlushPendingBH(Key);
  FDataBlock.Append(Key, Value);
  if FFilterBlock <> nil then
    FFilterBlock.Add(Key);

  if FDataBlock.BytesLen >= FBlockSize then
    FinishBlock;

  Inc(FNEntries);
end;

function TWriter.BlocksLen: Integer;
begin
  Result := FIndexBlock.FNEntries;
  if FPendingBH.Length > 0 then
    Inc(Result);
end;

function TWriter.EntriesLen: Integer;
begin
  Result := FNEntries;
end;

function TWriter.BytesLen: Integer;
begin
  Result := FOffset;
end;

function TWriter.Close: Exception;
var
  FilterBH, MetaindexBH, IndexBH: TBlockHandle;
  Key: TBytes;
  N: Integer;
  Footer: TBytes;
begin
  Result := nil;
  if FErr <> nil then
    Exit(FErr);

  if (FDataBlock.FNEntries > 0) or (FNEntries = 0) then
    FinishBlock;
  FlushPendingBH(nil);

  if FFilterBlock <> nil then
  begin
    FFilterBlock.Finish;
    if FFilterBlock.FBuf.Len > 0 then
      FilterBH := WriteBlock(FFilterBlock.FBuf, opt.NoCompression);
  end;

  if FilterBH.Length > 0 then
  begin
    Key := TEncoding.UTF8.GetBytes('filter.' + FFilter.Name);
    N := EncodeBlockHandle(FScratch, FilterBH);
    FDataBlock.Append(Key, Copy(FScratch, 0, N));
  end;
  FDataBlock.Finish;
  MetaindexBH := WriteBlock(FDataBlock.FBuf, FCompression);

  FIndexBlock.Finish;
  IndexBH := WriteBlock(FIndexBlock.FBuf, FCompression);

  SetLength(Footer, FooterLen);
  FillChar(Footer[0], FooterLen, 0);
  N := EncodeBlockHandle(Footer, MetaindexBH);
  EncodeBlockHandle(Copy(Footer, N, Length(Footer) - N), IndexBH);
  System.Move(Magic[1], Footer[FooterLen - Length(Magic)], Length(Magic));
  FWriter.Write(Footer, 0, FooterLen);
  Inc(FOffset, FooterLen);

  FErr := Exception.Create('leveldb/table: writer is closed');
end;

function NewWriter(AWriter: TStream; AOptions: TOptions): TWriter;
begin
  Result := TWriter.Create(AWriter, AOptions);
end;

end.
