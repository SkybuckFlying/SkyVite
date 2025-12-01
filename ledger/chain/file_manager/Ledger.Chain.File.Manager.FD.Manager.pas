unit Ledger.Chain.FileManager.FdManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Vite.Common,
  Ledger.Chain.FileManager.Interfaces,
  Ledger.Chain.FileManager.CacheItem,
  Ledger.Chain.FileManager.Fd,
  Ledger.Chain.FileManager.Location;

type
  TFdManager = class(IFdManager)
  private
    mDirName: string;
    mDirFd: TFileStream;
    mFilenamePrefix: string;
    mFilenamePrefixSize: Integer;
    mFileCache: TList<TFileCacheItem>;
    mFileFdCache: TDictionary<UInt64, TFileDescription>;
    mFileCacheLength: Integer;
    mFileSize: Int64;
    mWriteFd: TFileDescription;
    mChangeFdMu: TRTLCriticalSection;
    mFileManager: IFileManager;
    function latestFileId: UInt64;
    function loadLatestLocation: ILocation;
    procedure reset;
    function getCacheItem(ParaFileId: UInt64): TFileCacheItem;
    function isCorrectFile(ParaFilename: string): Boolean;
    function filenameToFileId(ParaFilename: string): UInt64;
  public
    constructor Create(ParaFileManager: IFileManager; ParaDirName: string; ParaFileSize, ParaCacheLength: Integer);
    destructor Destroy; override;
    function LatestLocation: ILocation;
    function GetFd(ParaFileId: UInt64): TFileDescription;
    function GetTmpFlushFd(ParaFileId: UInt64): TFileDescription;
    function GetWriteFd: TFileDescription;
    procedure DeleteTo(ParaLocation: ILocation);
    function DiskDelete(ParaHighLocation, ParaLowLocation: ILocation): TError;
    function CreateNextFd: TError;
    procedure Close;
    function resetWriteFd(ParaLocation: ILocation): TError;
    function getFileFd(ParaFileId: UInt64): TFileStream;
    function createNewFile(ParaFileId: UInt64): TFileStream;
    function fileIdToAbsoluteFilename(ParaFileId: UInt64): string;
  end;

implementation

{ TFdManager }

constructor TFdManager.Create(ParaFileManager: IFileManager; ParaDirName: string; ParaFileSize, ParaCacheLength: Integer);
var
  vLocation: ILocation;
begin
  inherited Create;
  if ParaCacheLength <= 0 then
    ParaCacheLength := 1;
  mDirName := ParaDirName;
  mFileManager := ParaFileManager;
  mFilenamePrefix := 'f';
  mFilenamePrefixSize := 1;
  mFileCache := TList<TFileCacheItem>.Create;
  mFileCacheLength := ParaCacheLength;
  mFileFdCache := TDictionary<UInt64, TFileDescription>.Create;
  mFileSize := ParaFileSize;

  mDirFd := TFileStream.Create(ParaDirName, fmOpenReadWrite or fmShareDenyNone);

  vLocation := loadLatestLocation;
  if vLocation = nil then
    vLocation := TLocation.Create(1, 0);
  resetWriteFd(vLocation);
end;

destructor TFdManager.Destroy;
begin
  Close;
  mFileCache.Free;
  mFileFdCache.Free;
  inherited Destroy;
end;

function TFdManager.LatestLocation: ILocation;
var
  vWriteFd: TFileDescription;
begin
  vWriteFd := GetWriteFd;
  Result := TLocation.Create(vWriteFd.CacheItem.FileId, vWriteFd.CacheItem.BufferLen);
end;

function TFdManager.GetFd(ParaFileId: UInt64): TFileDescription;
var
  vFd: TFileDescription;
  vFileCacheItem: TFileCacheItem;
  vFileStream: TFileStream;
begin
  EnterCriticalSection(mChangeFdMu);
  try
    if ParaFileId > latestFileId then
    begin
      Result := nil;
      Exit;
    end;

    if mFileFdCache.TryGetValue(ParaFileId, vFd) then
    begin
      Result := vFd;
      Exit;
    end;

    vFileCacheItem := getCacheItem(ParaFileId);
    if vFileCacheItem <> nil then
    begin
      Result := TFileDescription.CreateByBuffer(Self, vFileCacheItem);
      Exit;
    end;

    vFileStream := getFileFd(ParaFileId);
    Result := TFileDescription.CreateByFile(vFileStream);
  finally
    LeaveCriticalSection(mChangeFdMu);
  end;
end;

function TFdManager.GetTmpFlushFd(ParaFileId: UInt64): TFileDescription;
var
  vFile: TFileStream;
begin
  vFile := getFileFd(ParaFileId);
  if vFile = nil then
    vFile := createNewFile(ParaFileId);

  Result := TFileDescription.CreateByBuffer(Self, TFileCacheItem.Create(ParaFileId, vFile));
end;

function TFdManager.GetWriteFd: TFileDescription;
begin
  EnterCriticalSection(mChangeFdMu);
  try
    Result := mWriteFd;
  finally
    LeaveCriticalSection(mChangeFdMu);
  end;
end;

procedure TFdManager.DeleteTo(ParaLocation: ILocation);
var
  i: UInt64;
  vCacheItem: TFileCacheItem;
begin
  EnterCriticalSection(mChangeFdMu);
  try
    for i := latestFileId downto ParaLocation.FileId + 1 do
    begin
      if mWriteFd <> nil then
      begin
        mWriteFd.CacheItem.FileWriter.Free;
        mWriteFd.Free;
        mWriteFd := nil;
      end;

      vCacheItem := mFileCache.Last;
      if vCacheItem <> nil then
      begin
        mFileFdCache.Remove(vCacheItem.FileId);
        EnterCriticalSection(vCacheItem.Mu);
        try
          vCacheItem.FileWriter.Free;
          vCacheItem.FileId := 0;
          SetLength(vCacheItem.Buffer, 0);
          vCacheItem.BufferLen := 0;
        finally
          LeaveCriticalSection(vCacheItem.Mu);
        end;
        mFileCache.Delete(mFileCache.Count - 1);
      end;
    end;
    resetWriteFd(ParaLocation);
  finally
    LeaveCriticalSection(mChangeFdMu);
  end;
end;

function TFdManager.DiskDelete(ParaHighLocation, ParaLowLocation: ILocation): TError;
var
  i: UInt64;
  vFd: TFileStream;
begin
  Result := nil;
  for i := ParaHighLocation.FileId downto ParaLowLocation.FileId + 1 do
    if TFile.Exists(fileIdToAbsoluteFilename(i)) then
      TFile.Delete(fileIdToAbsoluteFilename(i));

  vFd := getFileFd(ParaLowLocation.FileId);
  if vFd = nil then
    Exit;
  try
    vFd.Size := ParaLowLocation.Offset;
  finally
    vFd.Free;
  end;
end;

function TFdManager.CreateNextFd: TError;
var
  vNewLocation: ILocation;
begin
  Result := nil;
  EnterCriticalSection(mChangeFdMu);
  try
    vNewLocation := TLocation.Create(latestFileId + 1, 0);
    mWriteFd := nil;
    Result := resetWriteFd(vNewLocation);
  finally
    LeaveCriticalSection(mChangeFdMu);
  end;
end;

procedure TFdManager.Close;
begin
  EnterCriticalSection(mChangeFdMu);
  try
    reset;
    if mDirFd <> nil then
    begin
      mDirFd.Free;
      mDirFd := nil;
    end;
  finally
    LeaveCriticalSection(mChangeFdMu);
  end;
end;

function TFdManager.resetWriteFd(ParaLocation: ILocation): TError;
var
  vFileId: UInt64;
  vCacheFd: TFileDescription;
  vFd: TFileStream;
  vNextFlushStartLocation: ILocation;
  vNewItem: TFileCacheItem;
  vItem: TFileCacheItem;
  vBufferLen: Int64;
  n: Integer;
begin
  Result := nil;
  if mWriteFd <> nil then
  begin
    EnterCriticalSection(mWriteFd.CacheItem.Mu);
    try
      if mWriteFd.CacheItem.BufferLen > ParaLocation.Offset then
        mWriteFd.CacheItem.BufferLen := ParaLocation.Offset;
    finally
      LeaveCriticalSection(mWriteFd.CacheItem.Mu);
    end;
    Exit;
  end;

  vFileId := ParaLocation.FileId;
  if mFileFdCache.TryGetValue(vFileId, vCacheFd) then
  begin
    mWriteFd := vCacheFd;
    EnterCriticalSection(vCacheFd.CacheItem.Mu);
    try
      vCacheFd.CacheItem.BufferLen := ParaLocation.Offset;
    finally
      LeaveCriticalSection(vCacheFd.CacheItem.Mu);
    end;
    Exit;
  end;

  vFd := nil;
  if ParaLocation.Offset > 0 then
  begin
    vFd := getFileFd(vFileId);
    if vFd = nil then
    begin
      Result := TError.CreateFmt('fd is nil, fileId is %d, location is %s', [vFileId, ParaLocation.ToString]);
      Exit;
    end;
  end;

  vNextFlushStartLocation := mFileManager.NextFlushStartLocation;
  vNewItem := nil;
  if vNextFlushStartLocation <> nil then
  begin
    while mFileCache.Count > mFileCacheLength do
    begin
      vItem := mFileCache.First;
      if vItem.FileId >= vNextFlushStartLocation.FileId then
        Break;
      mFileCache.Delete(0);
      mFileFdCache.Remove(vItem.FileId);
    end;

    if mFileCache.Count >= mFileCacheLength then
    begin
      vNewItem := mFileCache.First;
      if vNewItem.FileId < vNextFlushStartLocation.FileId then
      begin
        mFileCache.Add(vNewItem);
        mFileCache.Delete(0);
        mFileFdCache.Remove(vNewItem.FileId);
      end
      else
        vNewItem := nil;
    end;
  end;

  if vNewItem = nil then
  begin
    vNewItem := TFileCacheItem.Create;
    SetLength(vNewItem.Buffer, mFileSize);
    mFileCache.Add(vNewItem);
  end;

  EnterCriticalSection(vNewItem.Mu);
  try
    if vNewItem.FileWriter <> nil then
      vNewItem.FileWriter.Free;

    vBufferLen := ParaLocation.Offset;
    vNewItem.FileWriter := vFd;
    vNewItem.FileId := vFileId;
    vNewItem.BufferLen := vBufferLen;
  finally
    LeaveCriticalSection(vNewItem.Mu);
  end;

  if (vBufferLen > 0) and (vFd <> nil) then
  begin
    n := vFd.Read(vNewItem.Buffer, 0, vBufferLen);
    if n <> vBufferLen then
    begin
      Result := TError.CreateFmt('fd.Read, bufferLen is %d, n is %d, fileId is %d', [vBufferLen, n, vFileId]);
      Exit;
    end;
  end;

  mWriteFd := TFileDescription.CreateByBuffer(Self, vNewItem);
  mFileFdCache.Add(vNewItem.FileId, mWriteFd);
end;

function TFdManager.latestFileId: UInt64;
begin
  Result := mWriteFd.CacheItem.FileId;
end;

function TFdManager.loadLatestLocation: ILocation;
var
  vAllFilename: TArray<string>;
  vMaxFileId: UInt64;
  vFilename: string;
  vFileId: UInt64;
  vFd: TFileStream;
  vFileSize: Int64;
begin
  vAllFilename := TDirectory.GetFiles(mDirName);
  vMaxFileId := 0;
  for vFilename in vAllFilename do
  begin
    if not isCorrectFile(vFilename) then
      Continue;
    vFileId := filenameToFileId(vFilename);
    if vFileId > vMaxFileId then
      vMaxFileId := vFileId;
  end;

  vFd := getFileFd(vMaxFileId);
  if vFd = nil then
  begin
    Result := nil;
    Exit;
  end;
  try
    vFileSize := vFd.Size;
  finally
    vFd.Free;
  end;
  Result := TLocation.Create(vMaxFileId, vFileSize);
end;

procedure TFdManager.reset;
var
  vFileFd: TFileDescription;
begin
  for vFileFd in mFileFdCache.Values do
  begin
    vFileFd.Close;
    if (vFileFd.CacheItem <> nil) and (vFileFd.CacheItem.FileWriter <> nil) then
      vFileFd.CacheItem.FileWriter.Free;
  end;
  mFileCache := nil;
  mWriteFd := nil;
  mFileFdCache := nil;
end;

function TFdManager.getCacheItem(ParaFileId: UInt64): TFileCacheItem;
var
  vCurrent: TFileCacheItem;
begin
  Result := nil;
  if mFileCache.Count <= 0 then
    Exit;
  if mFileCache.First.FileId > ParaFileId then
    Exit;
  if mFileCache.Last.FileId < ParaFileId then
    Exit;

  for vCurrent in mFileCache do
  begin
    if vCurrent.FileId = ParaFileId then
    begin
      Result := vCurrent;
      Exit;
    end;
  end;
end;

function TFdManager.getFileFd(ParaFileId: UInt64): TFileStream;
var
  vAbsoluteFilename: string;
begin
  vAbsoluteFilename := fileIdToAbsoluteFilename(ParaFileId);
  if TFile.Exists(vAbsoluteFilename) then
    Result := TFileStream.Create(vAbsoluteFilename, fmOpenReadWrite or fmShareDenyNone)
  else
    Result := nil;
end;

function TFdManager.createNewFile(ParaFileId: UInt64): TFileStream;
var
  vAbsoluteFilename: string;
begin
  vAbsoluteFilename := fileIdToAbsoluteFilename(ParaFileId);
  Result := TFileStream.Create(vAbsoluteFilename, fmCreate);
end;

function TFdManager.isCorrectFile(ParaFilename: string): Boolean;
begin
  Result := TPath.GetFileName(ParaFilename).StartsWith(mFilenamePrefix);
end;

function TFdManager.fileIdToAbsoluteFilename(ParaFileId: UInt64): string;
begin
  Result := TPath.Combine(mDirName, mFilenamePrefix + ParaFileId.ToString);
end;

function TFdManager.filenameToFileId(ParaFilename: string): UInt64;
var
  vFileIdStr: string;
begin
  vFileIdStr := TPath.GetFileName(ParaFilename).Substring(mFilenamePrefixSize);
  Result := StrToUInt64(vFileIdStr);
end;

end.
