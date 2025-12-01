unit Common.Db.Xleveldb.Journal.Journal;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Db.Xleveldb.Errors,
  Common.Db.Xleveldb.Storage,
  Common.Db.Xleveldb.Util,
  Common.Db.Xleveldb.Util.Crc32;

const
  FullChunkType = 1;
  FirstChunkType = 2;
  MiddleChunkType = 3;
  LastChunkType = 4;

  BlockSize = 32 * 1024;
  HeaderSize = 7;

type
  EJournalCorrupted = class(Exception)
  public
    mSize: Integer;
    mReason: string;
    constructor Create(ParaSize: Integer; const ParaReason: string);
  end;

  IDropper = interface
    ['{E2B8B2A8-A8B8-4C8B-9A8B-8A9B8C7D6E5F}']
    procedure Drop(ParaE: Exception);
  end;

  TJournalReader = class; // Forward declaration

  TSingleReader = class(TStream)
  private
    mReader: TJournalReader;
    mSeq: Integer;
    mErr: Exception;
  public
    constructor Create(ParaReader: TJournalReader);
    function Read(var ParaBuffer; ParaCount: Longint): Longint; override;
  end;

  TJournalReader = class
  private
    mReader: TStream;
    mDropper: IDropper;
    mStrict: Boolean;
    mChecksum: Boolean;
    mSeq: Integer;
    mI, mJ: Integer;
    mN: Integer;
    mLast: Boolean;
    mErr: Exception;
    mBuf: TBytes;
    function Corrupt(ParaN: Integer; const ParaReason: string; ParaSkip: Boolean): Exception;
    function NextChunk(ParaFirst: Boolean): Exception;
  public
    constructor Create(ParaReader: TStream; ParaDropper: IDropper; ParaStrict, ParaChecksum: Boolean);
    destructor Destroy; override;
    function Next: TStream;
    function Reset(ParaReader: TStream; ParaDropper: IDropper; ParaStrict, ParaChecksum: Boolean): Exception;
    // Internal methods for TSingleReader
    function GetSeq: Integer;
    function GetError: Exception;
    function ReadFromBuffer(var ParaBuffer; ParaCount: Longint): Longint;
    function IsLastChunk: Boolean;
    procedure SetError(ParaErr: Exception);
  end;

  TJournalWriter = class; // Forward declaration

  TSingleWriter = class(TStream)
  private
    mWriter: TJournalWriter;
    mSeq: Integer;
  public
    constructor Create(ParaWriter: TJournalWriter);
    function Write(const ParaBuffer; ParaCount: Longint): Longint; override;
  end;

  TJournalWriter = class
  private
    mWriter: TStream;
    mSeq: Integer;
    mFlusher: IFlusher;
    mI, mJ: Integer;
    mWritten: Integer;
    mFirst: Boolean;
    mPending: Boolean;
    mErr: Exception;
    mBuf: TBytes;
    procedure FillHeader(ParaLast: Boolean);
    procedure WriteBlock;
    procedure WritePending;
  public
    constructor Create(ParaWriter: TStream);
    destructor Destroy; override;
    function Close: Exception;
    function Flush: Exception;
    function Reset(ParaWriter: TStream): Exception;
    function Next: TStream;
    // Internal methods for TSingleWriter
    function GetSeq: Integer;
    function GetError: Exception;
    procedure SetError(ParaErr: Exception);
    function WriteToBuffer(const ParaBuffer; ParaCount: Longint): Longint;
  end;

implementation

uses
  System.IOUtils;

{ EJournalCorrupted }

constructor EJournalCorrupted.Create(ParaSize: Integer; const ParaReason: string);
begin
  inherited CreateFmt('leveldb/journal: block/chunk corrupted: %s (%d bytes)', [ParaReason, ParaSize]);
  mSize := ParaSize;
  mReason := ParaReason;
end;

{ TJournalReader }

constructor TJournalReader.Create(ParaReader: TStream; ParaDropper: IDropper; ParaStrict, ParaChecksum: Boolean);
begin
  inherited Create;
  mReader := ParaReader;
  mDropper := ParaDropper;
  mStrict := ParaStrict;
  mChecksum := ParaChecksum;
  mLast := True;
  SetLength(mBuf, BlockSize);
end;

destructor TJournalReader.Destroy;
begin
  inherited Destroy;
end;

function TJournalReader.Corrupt(ParaN: Integer; const ParaReason: string; ParaSkip: Boolean): Exception;
var
  vErr: EJournalCorrupted;
begin
  vErr := EJournalCorrupted.Create(ParaN, ParaReason);
  if mDropper <> nil then
  begin
    mDropper.Drop(vErr);
  end;
  if mStrict and not ParaSkip then
  begin
    mErr := NewErrCorrupted(TFileDesc.Create(0, ftUnknown), vErr);
    Result := mErr;
  end
  else
  begin
    Result := vErr; // Special error to indicate skipping
  end;
end;

function TJournalReader.NextChunk(ParaFirst: Boolean): Exception;
var
  vChecksum: Cardinal;
  vLength: Word;
  vChunkType: Byte;
  vUnprocBlock: Integer;
  vCRC: CRC;
  vBufPtr: PByte;
begin
  Result := nil;
  while True do
  begin
    if mJ + HeaderSize <= mN then
    begin
      vBufPtr := @mBuf[0];
      vChecksum := TBitConverter.ToUInt32(mBuf, mJ);
      vLength := TBitConverter.ToUInt16(mBuf, mJ + 4);
      vChunkType := mBuf[mJ + 6];
      vUnprocBlock := mN - mJ;

      if (vChecksum = 0) and (vLength = 0) and (vChunkType = 0) then
      begin
        mI := mN;
        mJ := mN;
        Result := Corrupt(vUnprocBlock, 'zero header', False);
        Exit;
      end;

      if (vChunkType < FullChunkType) or (vChunkType > LastChunkType) then
      begin
        mI := mN;
        mJ := mN;
        Result := Corrupt(vUnprocBlock, Format('invalid chunk type %#x', [vChunkType]), False);
        Exit;
      end;

      mI := mJ + HeaderSize;
      mJ := mJ + HeaderSize + vLength;

      if mJ > mN then
      begin
        mI := mN;
        mJ := mN;
        Result := Corrupt(vUnprocBlock, 'chunk length overflows block', False);
        Exit;
      end;

      if mChecksum then
      begin
        vCRC := NewCRC(@mBuf[mI - 1], mJ - (mI - 1));
        if vChecksum <> vCRC.Value then
        begin
          mI := mN;
          mJ := mN;
          Result := Corrupt(vUnprocBlock, 'checksum mismatch', False);
          Exit;
        end;
      end;

      if ParaFirst and (vChunkType <> FullChunkType) and (vChunkType <> FirstChunkType) then
      begin
        Result := Corrupt(mJ - mI + HeaderSize, 'orphan chunk', True);
        mI := mJ;
        Exit;
      end;

      mLast := (vChunkType = FullChunkType) or (vChunkType = LastChunkType);
      Exit;
    end;

    if (mN < BlockSize) and (mN > 0) then
    begin
      if not ParaFirst then
      begin
        Result := Corrupt(0, 'missing chunk part', False);
        Exit;
      end;
      mErr := Eof;
      Result := mErr;
      Exit;
    end;

    mN := mReader.Read(mBuf, 0, Length(mBuf));
    if mN = 0 then
    begin
      if not ParaFirst then
      begin
        Result := Corrupt(0, 'missing chunk part', False);
        Exit;
      end;
      mErr := Eof;
      Result := mErr;
      Exit;
    end;
    mI := 0;
    mJ := 0;
  end;
end;

function TJournalReader.Next: TStream;
var
  vErr: Exception;
begin
  Inc(mSeq);
  if mErr <> nil then
  begin
    Result := nil;
    Exit;
  end;

  mI := mJ;
  while True do
  begin
    vErr := NextChunk(True);
    if vErr = nil then
    begin
      Break;
    end;
    if not (vErr is EJournalCorrupted) then
    begin
      Result := nil;
      Exit;
    end;
  end;
  Result := TSingleReader.Create(Self);
end;

function TJournalReader.Reset(ParaReader: TStream; ParaDropper: IDropper; ParaStrict, ParaChecksum: Boolean): Exception;
begin
  Inc(mSeq);
  Result := mErr;
  mReader := ParaReader;
  mDropper := ParaDropper;
  mStrict := ParaStrict;
  mChecksum := ParaChecksum;
  mI := 0;
  mJ := 0;
  mN := 0;
  mLast := True;
  mErr := nil;
end;

function TJournalReader.GetSeq: Integer;
begin
  Result := mSeq;
end;

function TJournalReader.GetError: Exception;
begin
  Result := mErr;
end;

function TJournalReader.ReadFromBuffer(var ParaBuffer; ParaCount: Longint): Longint;
var
  vBytesToCopy: Longint;
begin
  vBytesToCopy := mJ - mI;
  if vBytesToCopy > ParaCount then
  begin
    vBytesToCopy := ParaCount;
  end;
  System.Move(mBuf[mI], ParaBuffer, vBytesToCopy);
  mI := mI + vBytesToCopy;
  Result := vBytesToCopy;
end;

function TJournalReader.IsLastChunk: Boolean;
begin
  Result := mLast;
end;

procedure TJournalReader.SetError(ParaErr: Exception);
begin
  mErr := ParaErr;
end;

{ TSingleReader }

constructor TSingleReader.Create(ParaReader: TJournalReader);
begin
  inherited Create;
  mReader := ParaReader;
  mSeq := mReader.GetSeq;
end;

function TSingleReader.Read(var ParaBuffer; ParaCount: Longint): Longint;
var
  vErr: Exception;
begin
  if mReader.GetSeq <> mSeq then
  begin
    raise Exception.Create('leveldb/journal: stale reader');
  end;
  if mErr <> nil then
  begin
    Result := 0;
    Exit;
  end;
  if mReader.GetError <> nil then
  begin
    Result := 0;
    Exit;
  end;

  if mReader.mI = mReader.mJ then
  begin
    if mReader.IsLastChunk then
    begin
      Result := 0; // EOF
      Exit;
    end;
    vErr := mReader.NextChunk(False);
    if vErr <> nil then
    begin
      if vErr is EJournalCorrupted then
      begin
        mErr := TIOException.Create('Unexpected EOF');
      end
      else
      begin
        mErr := vErr;
      end;
      Result := 0;
      Exit;
    end;
  end;

  Result := mReader.ReadFromBuffer(ParaBuffer, ParaCount);
end;

{ TJournalWriter }

constructor TJournalWriter.Create(ParaWriter: TStream);
begin
  inherited Create;
  mWriter := ParaWriter;
  if not Supports(ParaWriter, IFlusher, mFlusher) then
  begin
    mFlusher := nil;
  end;
  SetLength(mBuf, BlockSize);
end;

destructor TJournalWriter.Destroy;
begin
  inherited Destroy;
end;

procedure TJournalWriter.FillHeader(ParaLast: Boolean);
var
  vCRC: CRC;
begin
  if (mI + HeaderSize > mJ) or (mJ > BlockSize) then
  begin
    raise Exception.Create('leveldb/journal: bad writer state');
  end;

  if ParaLast then
  begin
    if mFirst then
    begin
      mBuf[mI + 6] := FullChunkType
    end
    else
    begin
      mBuf[mI + 6] := LastChunkType;
    end;
  end
  else
  begin
    if mFirst then
    begin
      mBuf[mI + 6] := FirstChunkType
    end
    else
    begin
      mBuf[mI + 6] := MiddleChunkType;
    end;
  end;

  vCRC := NewCRC(@mBuf[mI + 6], mJ - (mI + 6));
  TBitConverter.GetBytes(vCRC.Value).CopyTo(mBuf, mI);
  TBitConverter.GetBytes(Word(mJ - mI - HeaderSize)).CopyTo(mBuf, mI + 4);
end;

procedure TJournalWriter.WriteBlock;
begin
  mWriter.Write(mBuf, mWritten, Length(mBuf) - mWritten);
  mI := 0;
  mJ := HeaderSize;
  mWritten := 0;
end;

procedure TJournalWriter.WritePending;
begin
  if mErr <> nil then
  begin
    Exit;
  end;
  if mPending then
  begin
    FillHeader(True);
    mPending := False;
  end;
  mWriter.Write(mBuf, mWritten, mJ - mWritten);
  mWritten := mJ;
end;

function TJournalWriter.Close: Exception;
begin
  Inc(mSeq);
  WritePending;
  if mErr <> nil then
  begin
    Result := mErr;
    Exit;
  end;
  mErr := Exception.Create('leveldb/journal: closed Writer');
  Result := nil;
end;

function TJournalWriter.Flush: Exception;
begin
  Inc(mSeq);
  WritePending;
  if mErr <> nil then
  begin
    Result := mErr;
    Exit;
  end;
  if mFlusher <> nil then
  begin
    mErr := mFlusher.Flush;
    Result := mErr;
  end
  else
  begin
    Result := nil;
  end;
end;

function TJournalWriter.Reset(ParaWriter: TStream): Exception;
begin
  Inc(mSeq);
  if mErr = nil then
  begin
    WritePending;
    Result := mErr;
  end
  else
  begin
    Result := nil;
  end;

  mWriter := ParaWriter;
  if not Supports(ParaWriter, IFlusher, mFlusher) then
  begin
    mFlusher := nil;
  end;
  mI := 0;
  mJ := 0;
  mWritten := 0;
  mFirst := False;
  mPending := False;
  mErr := nil;
end;

function TJournalWriter.Next: TStream;
begin
  Inc(mSeq);
  if mErr <> nil then
  begin
    Result := nil;
    Exit;
  end;
  if mPending then
  begin
    FillHeader(True);
  end;
  mI := mJ;
  mJ := mJ + HeaderSize;
  if mJ > BlockSize then
  begin
    FillChar(mBuf[mI], BlockSize - mI, 0);
    WriteBlock;
    if mErr <> nil then
    begin
      Result := nil;
      Exit;
    end;
  end;
  mFirst := True;
  mPending := True;
  Result := TSingleWriter.Create(Self);
end;

function TJournalWriter.GetSeq: Integer;
begin
  Result := mSeq;
end;

function TJournalWriter.GetError: Exception;
begin
  Result := mErr;
end;

procedure TJournalWriter.SetError(ParaErr: Exception);
begin
  mErr := ParaErr;
end;

function TJournalWriter.WriteToBuffer(const ParaBuffer; ParaCount: Longint): Longint;
var
  p: PByte;
  n: Integer;
begin
  p := PByte(ParaBuffer);
  n := ParaCount;
  while n > 0 do
  begin
    if mJ = BlockSize then
    begin
      FillHeader(False);
      WriteBlock;
      if mErr <> nil then
      begin
        Result := 0;
        Exit;
      end;
      mFirst := False;
    end;
    // Copy bytes into the buffer.
    n := Min(n, BlockSize - mJ);
    System.Move(p^, mBuf[mJ], n);
    mJ := mJ + n;
    Inc(p, n);
    Dec(n, n);
  end;
  Result := ParaCount;
end;

{ TSingleWriter }

constructor TSingleWriter.Create(ParaWriter: TJournalWriter);
begin
  inherited Create;
  mWriter := ParaWriter;
  mSeq := mWriter.GetSeq;
end;

function TSingleWriter.Write(const ParaBuffer; ParaCount: Longint): Longint;
begin
  if mWriter.GetSeq <> mSeq then
  begin
    raise Exception.Create('leveldb/journal: stale writer');
  end;
  if mWriter.GetError <> nil then
  begin
    Result := 0;
    Exit;
  end;
  Result := mWriter.WriteToBuffer(ParaBuffer, ParaCount);
end;

end.