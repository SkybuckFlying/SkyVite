unit Common.Db.Xleveldb.Storage.Mem_storage;

interface

uses
  Common.Db.Xleveldb.Storage,
  Common.DB.XLevelDB.Storage.File.Storage,
  Common.DB.XLevelDB.Storage.File.Storage.Nacl,
  Common.DB.XLevelDB.Storage.File.Storage.Plan9,
  Common.DB.XLevelDB.Storage.File.Storage.Solaris,
  Common.DB.XLevelDB.Storage.File.Storage.Unix,
  Common.DB.XLevelDB.Storage.File.Storage.Windows,
  Common.DB.XLevelDB.Storage.Storage,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TMemStorage = class; // Forward declaration

  TMemFile = class
  private
    mStream: TMemoryStream;
    mOpen: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function GetBytes: TBytes;
  end;

  TMemReader = class(TInterfacedObject, IReader)
  private
    mReader: TBytesStream;
    mMS: TMemStorage;
    mM: TMemFile;
    mClosed: Boolean;
  public
    constructor Create(ParaMS: TMemStorage; ParaM: TMemFile);
    destructor Destroy; override;
    function Read(var ParaBuffer; ParaCount: Longint): Longint;
    function Seek(ParaOffset: Longint; ParaOrigin: Word): Longint;
    function ReadAt(var ParaBuffer; ParaCount, ParaOffset: Longint): Longint;
    procedure Close;
  end;

  TMemWriter = class(TInterfacedObject, IWriter)
  private
    mMemFile: TMemFile;
    mMS: TMemStorage;
    mClosed: Boolean;
  public
    constructor Create(ParaMS: TMemStorage; ParaMemFile: TMemFile);
    destructor Destroy; override;
    function Write(const ParaBuffer; ParaCount: Longint): Longint;
    function Sync: Exception;
    procedure Close;
  end;

  TMemStorageLock = class(TInterfacedObject, ILocker)
  private
    mMS: TMemStorage;
  public
    constructor Create(ParaMS: TMemStorage);
    procedure Unlock;
  end;

  TMemStorage = class(TInterfacedObject, IStorage)
  private
    mMu: TCriticalSection;
    mSLock: TMemStorageLock;
    mFiles: TDictionary<UInt64, TMemFile>;
    mMeta: TFileDesc;
    procedure UnsetSLock(ParaLock: TMemStorageLock);
  public
    constructor Create;
    destructor Destroy; override;
    function Lock: ILocker;
    procedure Log(const ParaStr: string);
    procedure SetMeta(const ParaFd: TFileDesc);
    function GetMeta: TFileDesc;
    function List(ParaFT: TFileTypes): TArray<TFileDesc>;
    function Open(const ParaFd: TFileDesc): IReader;
    function Create(const ParaFd: TFileDesc): IWriter;
    procedure Remove(const ParaFd: TFileDesc);
    procedure Rename(const ParaOldFd, ParaNewFd: TFileDesc);
    procedure Close;
  end;

function NewMemStorage: IStorage;

implementation

const
  TypeShift = 4;

function PackFile(const ParaFd: TFileDesc): UInt64;
begin
  Result := (UInt64(ParaFd.FNum) shl TypeShift) or UInt64(Ord(ParaFd.FType));
end;

function UnpackFile(ParaX: UInt64): TFileDesc;
begin
  Result.FType := TFileType(ParaX and $F);
  Result.FNum := Int64(ParaX shr TypeShift);
end;

{ TMemFile }

constructor TMemFile.Create;
begin
  inherited Create;
  mStream := TMemoryStream.Create;
end;

destructor TMemFile.Destroy;
begin
  mStream.Free;
  inherited;
end;

procedure TMemFile.Reset;
begin
  mStream.Clear;
end;

function TMemFile.GetBytes: TBytes;
begin
  Result := mStream.Memory;
end;

{ TMemReader }

constructor TMemReader.Create(ParaMS: TMemStorage; ParaM: TMemFile);
begin
  inherited Create;
  mMS := ParaMS;
  mM := ParaM;
  mReader := TBytesStream.Create(mM.GetBytes);
end;

destructor TMemReader.Destroy;
begin
  mReader.Free;
  inherited;
end;

function TMemReader.Read(var ParaBuffer; ParaCount: Longint): Longint;
begin
  Result := mReader.Read(ParaBuffer, ParaCount);
end;

function TMemReader.Seek(ParaOffset: Longint; ParaOrigin: Word): Longint;
begin
  Result := mReader.Seek(ParaOffset, TSeekOrigin(ParaOrigin));
end;

function TMemReader.ReadAt(var ParaBuffer; ParaCount, ParaOffset: Longint): Longint;
begin
  mReader.Position := ParaOffset;
  Result := mReader.Read(ParaBuffer, ParaCount);
end;

procedure TMemReader.Close;
begin
  EnterCriticalSection(mMS.mMu);
  try
    if mClosed then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    mM.mOpen := False;
    mClosed := True;
  finally
    LeaveCriticalSection(mMS.mMu);
  end;
end;

{ TMemWriter }

constructor TMemWriter.Create(ParaMS: TMemStorage; ParaMemFile: TMemFile);
begin
  inherited Create;
  mMS := ParaMS;
  mMemFile := ParaMemFile;
end;

destructor TMemWriter.Destroy;
begin
  inherited;
end;

function TMemWriter.Write(const ParaBuffer; ParaCount: Longint): Longint;
begin
  Result := mMemFile.mStream.Write(ParaBuffer, ParaCount);
end;

function TMemWriter.Sync: Exception;
begin
  Result := nil;
end;

procedure TMemWriter.Close;
begin
  EnterCriticalSection(mMS.mMu);
  try
    if mClosed then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    mMemFile.mOpen := False;
    mClosed := True;
  finally
    LeaveCriticalSection(mMS.mMu);
  end;
end;

{ TMemStorageLock }

constructor TMemStorageLock.Create(ParaMS: TMemStorage);
begin
  inherited Create;
  mMS := ParaMS;
end;

procedure TMemStorageLock.Unlock;
begin
  mMS.UnsetSLock(Self);
end;

{ TMemStorage }

constructor TMemStorage.Create;
begin
  inherited Create;
  InitializeCriticalSection(mMu);
  mFiles := TDictionary<UInt64, TMemFile>.Create;
end;

destructor TMemStorage.Destroy;
var
  vFile: TMemFile;
begin
  for vFile in mFiles.Values do
  begin
    vFile.Free;
  end;
  mFiles.Free;
  DeleteCriticalSection(mMu);
  inherited;
end;

procedure TMemStorage.UnsetSLock(ParaLock: TMemStorageLock);
begin
  EnterCriticalSection(mMu);
  try
    if mSLock = ParaLock then
    begin
      mSLock := nil;
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TMemStorage.Lock: ILocker;
begin
  EnterCriticalSection(mMu);
  try
    if mSLock <> nil then
    begin
      raise ELocked.Create('leveldb/storage: already locked');
    end;
    mSLock := TMemStorageLock.Create(Self);
    Result := mSLock;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TMemStorage.Log(const ParaStr: string);
begin
  // No-op
end;

procedure TMemStorage.SetMeta(const ParaFd: TFileDesc);
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;

  EnterCriticalSection(mMu);
  try
    mMeta := ParaFd;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TMemStorage.GetMeta: TFileDesc;
begin
  EnterCriticalSection(mMu);
  try
    if mMeta.IsZero then
    begin
      raise EFileNotFound.Create('leveldb/storage: meta file not found');
    end;
    Result := mMeta;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TMemStorage.List(ParaFT: TFileTypes): TArray<TFileDesc>;
var
  vList: TList<TFileDesc>;
  vKey: UInt64;
  vFd: TFileDesc;
begin
  EnterCriticalSection(mMu);
  try
    vList := TList<TFileDesc>.Create;
    try
      for vKey in mFiles.Keys do
      begin
        vFd := UnpackFile(vKey);
        if vFd.FType in ParaFT then
        begin
          vList.Add(vFd);
        end;
      end;
      Result := vList.ToArray;
    finally
      vList.Free;
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TMemStorage.Open(const ParaFd: TFileDesc): IReader;
var
  vMemFile: TMemFile;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;

  EnterCriticalSection(mMu);
  try
    if mFiles.TryGetValue(PackFile(ParaFd), vMemFile) then
    begin
      if vMemFile.mOpen then
      begin
        raise EFileOpen.Create('leveldb/storage: file still open');
      end;
      vMemFile.mOpen := True;
      Result := TMemReader.Create(Self, vMemFile);
    end
    else
    begin
      raise EFileNotFound.Create('leveldb/storage: file not found');
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TMemStorage.Create(const ParaFd: TFileDesc): IWriter;
var
  vMemFile: TMemFile;
  vKey: UInt64;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;

  vKey := PackFile(ParaFd);
  EnterCriticalSection(mMu);
  try
    if mFiles.TryGetValue(vKey, vMemFile) then
    begin
      if vMemFile.mOpen then
      begin
        raise EFileOpen.Create('leveldb/storage: file still open');
      end;
      vMemFile.Reset;
    end
    else
    begin
      vMemFile := TMemFile.Create;
      mFiles.Add(vKey, vMemFile);
    end;
    vMemFile.mOpen := True;
    Result := TMemWriter.Create(Self, vMemFile);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TMemStorage.Remove(const ParaFd: TFileDesc);
var
  vKey: UInt64;
  vMemFile: TMemFile;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;

  vKey := PackFile(ParaFd);
  EnterCriticalSection(mMu);
  try
    if mFiles.TryGetValue(vKey, vMemFile) then
    begin
      vMemFile.Free;
      mFiles.Remove(vKey);
    end
    else
    begin
      raise EFileNotFound.Create('leveldb/storage: file not found');
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TMemStorage.Rename(const ParaOldFd, ParaNewFd: TFileDesc);
var
  vOldKey, vNewKey: UInt64;
  vMemFile: TMemFile;
begin
  if not TFileDesc.Ok(ParaOldFd) or not TFileDesc.Ok(ParaNewFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;
  if (ParaOldFd.FType = ParaNewFd.FType) and (ParaOldFd.FNum = ParaNewFd.FNum) then
  begin
    Exit;
  end;

  vOldKey := PackFile(ParaOldFd);
  vNewKey := PackFile(ParaNewFd);
  EnterCriticalSection(mMu);
  try
    if mFiles.TryGetValue(vOldKey, vMemFile) then
    begin
      if vMemFile.mOpen then
      begin
        raise EFileOpen.Create('leveldb/storage: file still open');
      end;
      if mFiles.ContainsKey(vNewKey) then
      begin
        if mFiles[vNewKey].mOpen then
        begin
          raise EFileOpen.Create('leveldb/storage: file still open');
        end;
        mFiles[vNewKey].Free;
        mFiles.Remove(vNewKey);
      end;
      mFiles.Remove(vOldKey);
      mFiles.Add(vNewKey, vMemFile);
    end
    else
    begin
      raise EFileNotFound.Create('leveldb/storage: file not found');
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TMemStorage.Close;
begin
  // No-op
end;

function NewMemStorage: IStorage;
begin
  Result := TMemStorage.Create;
end;

end.
