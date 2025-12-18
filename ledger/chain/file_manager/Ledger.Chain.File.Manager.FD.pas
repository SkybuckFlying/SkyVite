unit Ledger.Chain.FileManager.Fd;

interface

uses
  Ledger.Chain.File.Manager.FD.Manager,
  Ledger.Chain.File.Manager.File.Manager,
  Ledger.Chain.File.Manager.Interface,
  Ledger.Chain.File.Manager.Location,
  Ledger.Chain.FileManager.CacheItem,
  Ledger.Chain.FileManager.Interfaces,
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  Vite.Common;

type
  TFileDescription = class
  private
    mFdSet: IFdManager;
    mFileReader: TFileStream;
    mCacheItem: TFileCacheItem;
    mFileId: UInt64;
    mWriteMaxSize: Int64;
    function readAt(ParaBuffer: TBytes; ParaOffset: Int64): Integer;
  public
    constructor CreateByFile(ParaFile: TFileStream); overload;
    constructor CreateByBuffer(ParaFdSet: IFdManager; ParaCacheItem: TFileCacheItem); overload;
    destructor Destroy; override;
    function ReadAt(ParaBuffer: TBytes; ParaOffset: Int64): Integer;
    function Write(ParaBuf: TBytes): Integer;
    function Flush(ParaStartOffset: Int64; ParaBuf: TBytes): Integer;
    procedure Close;
  end;

implementation

{ TFileDescription }

constructor TFileDescription.CreateByFile(ParaFile: TFileStream);
begin
  inherited Create;
  mFileReader := ParaFile;
end;

constructor TFileDescription.CreateByBuffer(ParaFdSet: IFdManager; ParaCacheItem: TFileCacheItem);
begin
  inherited Create;
  mFdSet := ParaFdSet;
  mCacheItem := ParaCacheItem;
  mFileId := ParaCacheItem.FileId;
  mWriteMaxSize := Length(ParaCacheItem.Buffer);
end;

destructor TFileDescription.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TFileDescription.ReadAt(ParaBuffer: TBytes; ParaOffset: Int64): Integer;
begin
  if mFileReader <> nil then
  begin
    mFileReader.Position := ParaOffset;
    Result := mFileReader.Read(ParaBuffer, 0, Length(ParaBuffer));
    Exit;
  end;

  Result := readAt(ParaBuffer, ParaOffset);
end;

function TFileDescription.Write(ParaBuf: TBytes): Integer;
var
  vBufLen, vFreeSpaceLength, vCount: Integer;
  vNextPointer: Int64;
begin
  EnterCriticalSection(mCacheItem.Mu);
  try
    if mFileId <> mCacheItem.FileId then
      raise Exception.CreateFmt('fd.fileId is %d, cacheItem.FileId is %d', [mFileId, mCacheItem.FileId]);

    if mCacheItem.BufferLen >= mWriteMaxSize then
    begin
      Result := 0;
      Exit;
    end;

    vBufLen := Length(ParaBuf);
    vFreeSpaceLength := mWriteMaxSize - mCacheItem.BufferLen;

    if vFreeSpaceLength < vBufLen then
      vCount := vFreeSpaceLength
    else
      vCount := vBufLen;

    vNextPointer := mCacheItem.BufferLen + vCount;
    System.Move(ParaBuf[0], mCacheItem.Buffer[mCacheItem.BufferLen], vCount);
    mCacheItem.BufferLen := vNextPointer;

    Result := vCount;
  finally
    LeaveCriticalSection(mCacheItem.Mu);
  end;
end;

function TFileDescription.Flush(ParaStartOffset: Int64; ParaBuf: TBytes): Integer;
var
  vFd: TFileStream;
begin
  if mCacheItem = nil then
    raise Exception.Create('cacheItem is nil');

  EnterCriticalSection(mCacheItem.Mu);
  try
    if mFileId <> mCacheItem.FileId then
      raise Exception.CreateFmt('fd.fileId is %d, cacheItem.FileId is %d', [mFileId, mCacheItem.FileId]);

    if mCacheItem.FileWriter = nil then
    begin
      vFd := mFdSet.createNewFile(mCacheItem.FileId);
      if vFd = nil then
        raise Exception.Create('fd is nil');
      mCacheItem.FileWriter := vFd;
    end;

    mCacheItem.FileWriter.Position := ParaStartOffset;
    Result := mCacheItem.FileWriter.Write(ParaBuf, 0, Length(ParaBuf));
    mCacheItem.FileWriter.Flush;
  finally
    LeaveCriticalSection(mCacheItem.Mu);
  end;
end;

procedure TFileDescription.Close;
begin
  if mFileReader <> nil then
    mFileReader.Free;
end;

function TFileDescription.readAt(ParaBuffer: TBytes; ParaOffset: Int64): Integer;
var
  vReadN, vOffsetInt, vRestLen: Integer;
begin
  EnterCriticalSection(mCacheItem.Mu);
  try
    if mCacheItem.FileId <> mFileId then
    begin
      if Length(mCacheItem.Buffer) <= 0 then
      begin
        Result := 0;
        Exit;
      end;
      mFileReader := mFdSet.getFileFd(mFileId);
      if mFileReader = nil then
        raise Exception.CreateFmt('can''t open fileReader, fileReader id is %d', [mFileId]);

      mFileReader.Position := ParaOffset;
      Result := mFileReader.Read(ParaBuffer, 0, Length(ParaBuffer));
      Exit;
    end;

    if ParaOffset > mCacheItem.BufferLen then
    begin
      Result := 0;
      Exit;
    end;

    vReadN := Length(ParaBuffer);
    vOffsetInt := ParaOffset;
    vRestLen := mCacheItem.BufferLen - vOffsetInt;

    if vReadN > vRestLen then
      vReadN := vRestLen;

    System.Move(mCacheItem.Buffer[vOffsetInt], ParaBuffer[0], vReadN);
    if vReadN < Length(ParaBuffer) then
      Result := vReadN
    else
      Result := vReadN;
  finally
    LeaveCriticalSection(mCacheItem.Mu);
  end;
end;

end.
