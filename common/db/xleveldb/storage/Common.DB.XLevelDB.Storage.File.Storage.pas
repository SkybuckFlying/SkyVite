unit Common.Db.Xleveldb.Storage.File_storage;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  Common.Db.Xleveldb.Storage;

type
  EFileStorageError = class(EStorageError);
  EFileOpen = class(EFileStorageError);
  EReadOnly = class(EFileStorageError);

  TFileStorage = class(TInterfacedObject, IStorage)
  private
    mPath: string;
    mReadOnly: Boolean;
    mMu: TCriticalSection;
    mFLock: THandle;
    mSLock: ILocker;
    mLogW: TFileStream;
    mLogSize: Int64;
    mBuf: TBytes;
    mOpen: Integer;
    mDay: Word;
    procedure DoLog(const ParaT: TDateTime; const ParaStr: string);
    procedure InternalLog(const ParaStr: string);
    function GenName(const ParaFd: TFileDesc): string;
    function ParseName(const ParaName: string; out ParaFd: TFileDesc): Boolean;
  public
    constructor Create(const ParaPath: string; ParaReadOnly: Boolean);
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

function OpenFile(const ParaPath: string; ParaReadOnly: Boolean): IStorage;

implementation

uses
  System.DateUtils,
  System.StrUtils;

const
  LogSizeThreshold = 1024 * 1024; // 1 MiB
  MOVEFILE_REPLACE_EXISTING = $00000001;

function MoveFileExW(lpExistingFileName, lpNewFileName: PWideChar; dwFlags: DWORD): BOOL; stdcall; external 'kernel32.dll';

function RenameFile(const ParaOldPath, ParaNewPath: string): Boolean;
begin
  Result := MoveFileExW(PWideChar(ParaOldPath), PWideChar(ParaNewPath), MOVEFILE_REPLACE_EXISTING);
end;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): THandle;
var
  vAccess, vShareMode: DWORD;
begin
  if ParaReadOnly then
  begin
    vAccess := GENERIC_READ;
    vShareMode := FILE_SHARE_READ;
  end
  else
  begin
    vAccess := GENERIC_READ or GENERIC_WRITE;
    vShareMode := 0;
  end;
  Result := CreateFileW(PWideChar(ParaPath), vAccess, vShareMode, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;
end;

procedure ReleaseFileLock(ParaHandle: THandle);
begin
  CloseHandle(ParaHandle);
end;

procedure SyncDir(const ParaPath: string);
begin
  // No-op on Windows
end;

{ TFileWrap }

type
  TFileWrap = class(TInterfacedObject, IReader, IWriter)
  private
    mFS: TFileStorage;
    mFd: TFileDesc;
    mStream: TFileStream;
    mClosed: Boolean;
  public
    constructor Create(ParaFS: TFileStorage; const ParaFd: TFileDesc; ParaStream: TFileStream);
    destructor Destroy; override;
    // IReader/IWriter methods
    function Read(var ParaBuffer; ParaCount: Longint): Longint;
    function ReadAt(var ParaBuffer; ParaCount: Longint; ParaOffset: Int64): Longint;
    function Seek(ParaOffset: Longint; ParaOrigin: TSeekOrigin): Longint;
    function Write(const ParaBuffer; ParaCount: Longint): Longint;
    procedure Sync;
    procedure Close;
    function GetSize: Int64;
  end;

constructor TFileWrap.Create(ParaFS: TFileStorage; const ParaFd: TFileDesc; ParaStream: TFileStream);
begin
  inherited Create;
  mFS := ParaFS;
  mFd := ParaFd;
  mStream := ParaStream;
end;

destructor TFileWrap.Destroy;
begin
  Close;
  inherited;
end;

function TFileWrap.Read(var ParaBuffer; ParaCount: Longint): Longint;
begin
  Result := mStream.Read(ParaBuffer, ParaCount);
end;

function TFileWrap.ReadAt(var ParaBuffer; ParaCount: Longint; ParaOffset: Int64): Longint;
begin
  mStream.Position := ParaOffset;
  Result := mStream.Read(ParaBuffer, ParaCount);
end;

function TFileWrap.Seek(ParaOffset: Longint; ParaOrigin: TSeekOrigin): Longint;
begin
  Result := mStream.Seek(ParaOffset, ParaOrigin);
end;

function TFileWrap.Write(const ParaBuffer; ParaCount: Longint): Longint;
begin
  Result := mStream.Write(ParaBuffer, ParaCount);
end;

procedure TFileWrap.Sync;
begin
  mStream.Flush;
  if mFd.FType = TypeManifest then
  begin
    SyncDir(mFS.mPath);
  end;
end;

procedure TFileWrap.Close;
begin
  if mClosed then
  begin
    Exit;
  end;
  mClosed := True;
  mStream.Free;
  InterlockedDecrement(mFS.mOpen);
end;

function TFileWrap.GetSize: Int64;
begin
  Result := mStream.Size;
end;

{ TFileStorage }

constructor TFileStorage.Create(const ParaPath: string; ParaReadOnly: Boolean);
begin
  inherited Create;
  InitializeCriticalSection(mMu);
  mPath := ParaPath;
  mReadOnly := ParaReadOnly;

  if TDirectory.Exists(mPath) then
  begin
    // It's a directory, which is what we want.
  end
  else if not mReadOnly then
  begin
    TDirectory.CreateDirectory(mPath);
  end
  else
  begin
    raise EFileNotFound.CreateFmt('leveldb/storage: directory %s not found', [mPath]);
  end;

  mFLock := NewFileLock(TPath.Combine(mPath, 'LOCK'), mReadOnly);

  if not mReadOnly then
  begin
    mLogW := TFileStream.Create(TPath.Combine(mPath, 'LOG'), fmOpenWrite or fmCreate);
    mLogSize := mLogW.Seek(0, soEnd);
  end;
end;

destructor TFileStorage.Destroy;
begin
  Close;
  DeleteCriticalSection(mMu);
  inherited;
end;

function TFileStorage.Lock: ILocker;
begin
  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    if mReadOnly then
    begin
      Result := TInterfacedObject.Create as ILocker; // Dummy locker
      Exit;
    end;
    if mSLock <> nil then
    begin
      raise ELocked.Create('leveldb/storage: already locked');
    end;
    // mSLock := TFileStorageLock.Create(Self);
    // Result := mSLock;
    Result := nil; // Placeholder
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TFileStorage.DoLog(const ParaT: TDateTime; const ParaStr: string);
var
  vHour, vMin, vSec, vMSec: Word;
  vLogLine: string;
begin
  if mLogSize > LogSizeThreshold then
  begin
    mLogW.Free;
    mLogW := nil;
    mLogSize := 0;
    RenameFile(TPath.Combine(mPath, 'LOG'), TPath.Combine(mPath, 'LOG.old'));
  end;

  if mLogW = nil then
  begin
    mLogW := TFileStream.Create(TPath.Combine(mPath, 'LOG'), fmOpenWrite or fmCreate);
    mDay := 0; // Force printDay on new log file
  end;

  if mDay <> DayOfTheMonth(ParaT) then
  begin
    mDay := DayOfTheMonth(ParaT);
    vLogLine := '=============== ' + FormatDateTime('mmm d, yyyy (zzz)', ParaT) + ' ================' + sLineBreak;
    mLogW.Write(TEncoding.UTF8.GetBytes(vLogLine), 0, Length(vLogLine));
  end;

  DecodeTime(ParaT, vHour, vMin, vSec, vMSec);
  vLogLine := Format('%2.2d:%2.2d:%2.2d.%6.6d %s' + sLineBreak, [vHour, vMin, vSec, vMSec * 1000, ParaStr]);
  mBuf := TEncoding.UTF8.GetBytes(vLogLine);
  mLogW.Write(mBuf, 0, Length(mBuf));
  Inc(mLogSize, Length(mBuf));
end;

procedure TFileStorage.InternalLog(const ParaStr: string);
begin
  if not mReadOnly then
  begin
    DoLog(Now, ParaStr);
  end;
end;

procedure TFileStorage.Log(const ParaStr: string);
begin
  if not mReadOnly then
  begin
    EnterCriticalSection(mMu);
    try
      if mOpen < 0 then
      begin
        Exit;
      end;
      DoLog(Now, ParaStr);
    finally
      LeaveCriticalSection(mMu);
    end;
  end;
end;

function TFileStorage.GenName(const ParaFd: TFileDesc): string;
begin
  case ParaFd.FType of
    TypeManifest: Result := Format('MANIFEST-%6.6d', [ParaFd.FNum]);
    TypeJournal: Result := Format('%6.6d.log', [ParaFd.FNum]);
    TypeTable: Result := Format('%6.6d.ldb', [ParaFd.FNum]);
    TypeTemp: Result := Format('%6.6d.tmp', [ParaFd.FNum]);
  else
    raise EArgumentException.Create('Invalid file type');
  end;
end;

function TFileStorage.ParseName(const ParaName: string; out ParaFd: TFileDesc): Boolean;
var
  vNumStr, vTypeStr: string;
  vNum: Int64;
begin
  Result := False;
  if TryScan(ParaName, '%d.%s', [vNum, vTypeStr]) then
  begin
    ParaFd.FNum := vNum;
    if vTypeStr = 'log' then ParaFd.FType := TypeJournal
    else if (vTypeStr = 'ldb') or (vTypeStr = 'sst') then ParaFd.FType := TypeTable
    else if vTypeStr = 'tmp' then ParaFd.FType := TypeTemp
    else Exit;
    Result := True;
  end
  else if TryScan(ParaName, 'MANIFEST-%d', [vNum]) then
  begin
    ParaFd.FNum := vNum;
    ParaFd.FType := TypeManifest;
    Result := True;
  end;
end;

procedure TFileStorage.SetMeta(const ParaFd: TFileDesc);
var
  vPath, vContent: string;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;
  if mReadOnly then
  begin
    raise EReadOnly.Create('leveldb/storage: storage is read-only');
  end;

  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;

    vPath := TPath.Combine(mPath, 'CURRENT.' + ParaFd.FNum.ToString);
    vContent := GenName(ParaFd) + sLineBreak;

    TFile.WriteAllText(vPath, vContent);
    RenameFile(vPath, TPath.Combine(mPath, 'CURRENT'));
    SyncDir(mPath);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TFileStorage.GetMeta: TFileDesc;
var
  vFiles: TArray<string>;
  vName, vContent: string;
  vFd, vBestFd: TFileDesc;
  vPend: Boolean;
  vPendNum: Int64;
  vRem: TStringList;
  vCerr: Exception;
  vOk: Boolean;
begin
  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;

    vFiles := TDirectory.GetFiles(mPath, 'CURRENT*');
    vRem := TStringList.Create;
    try
      vBestFd.FNum := -1;
      for vName in vFiles do
      begin
        vName := TPath.GetFileName(vName);
        if vName.StartsWith('CURRENT') then
        begin
          vPend := Length(vName) > 7;
          if vPend then
          begin
            if (vName[8] <> '.') or (Length(vName) < 10) then
            begin
              InternalLog('skipping ' + vName + ': invalid file name');
              Continue;
            end;
            if not TryStrToInt64(Copy(vName, 10, Length(vName) - 9), vPendNum) then
            begin
              InternalLog('skipping ' + vName + ': invalid file num');
              Continue;
            end;
          end;

          vContent := TFile.ReadAllText(TPath.Combine(mPath, vName));
          if (Length(vContent) < 1) or (vContent[Length(vContent)] <> #10) or not ParseName(Copy(vContent, 1, Length(vContent) - 1), vFd) then
          begin
            InternalLog('skipping ' + vName + ': corrupted or incomplete');
            if vPend then vRem.Add(vName);
            if not vPend or (vCerr = nil) then
            begin
              ParseName(vName, vFd);
              vCerr := ECorrupted.Create(vFd, EStorageError.Create('leveldb/storage: corrupted or incomplete meta file'));
            end;
          end
          else if vPend and (vPendNum <> vFd.FNum) then
          begin
            InternalLog('skipping ' + vName + ': inconsistent pending-file num');
            vRem.Add(vName);
          end
          else if vFd.FNum < vBestFd.FNum then
          begin
            InternalLog('skipping ' + vName + ': obsolete');
            if vPend then vRem.Add(vName);
          end
          else
          begin
            vBestFd := vFd;
          end;
        end;
      end;

      if vBestFd.FNum = -1 then
      begin
        if vCerr <> nil then raise vCerr;
        raise EFileNotFound.Create('leveldb/storage: meta file not found');
      end;

      Result := vBestFd;

      if not mReadOnly then
      begin
        // Rename pending and remove obsolete files
      end;
    finally
      vRem.Free;
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TFileStorage.List(ParaFT: TFileTypes): TArray<TFileDesc>;
var
  vFiles: TArray<string>;
  vName: string;
  vFd: TFileDesc;
  vList: TList<TFileDesc>;
begin
  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;

    vFiles := TDirectory.GetFiles(mPath);
    vList := TList<TFileDesc>.Create;
    try
      for vName in vFiles do
      begin
        if ParseName(TPath.GetFileName(vName), vFd) and (vFd.FType in ParaFT) then
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

function TFileStorage.Open(const ParaFd: TFileDesc): IReader;
var
  vStream: TFileStream;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;

  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    vStream := TFileStream.Create(TPath.Combine(mPath, GenName(ParaFd)), fmOpenRead or fmShareDenyNone);
    InterlockedIncrement(mOpen);
    Result := TFileWrap.Create(Self, ParaFd, vStream);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TFileStorage.Create(const ParaFd: TFileDesc): IWriter;
var
  vStream: TFileStream;
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;
  if mReadOnly then
  begin
    raise EReadOnly.Create('leveldb/storage: storage is read-only');
  end;

  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    vStream := TFileStream.Create(TPath.Combine(mPath, GenName(ParaFd)), fmCreate);
    InterlockedIncrement(mOpen);
    Result := TFileWrap.Create(Self, ParaFd, vStream);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TFileStorage.Remove(const ParaFd: TFileDesc);
begin
  if not TFileDesc.Ok(ParaFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;
  if mReadOnly then
  begin
    raise EReadOnly.Create('leveldb/storage: storage is read-only');
  end;

  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    TFile.Delete(TPath.Combine(mPath, GenName(ParaFd)));
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TFileStorage.Rename(const ParaOldFd, ParaNewFd: TFileDesc);
begin
  if not TFileDesc.Ok(ParaOldFd) or not TFileDesc.Ok(ParaNewFd) then
  begin
    raise EInvalidFile.Create('leveldb/storage: invalid file for argument');
  end;
  if (ParaOldFd.FType = ParaNewFd.FType) and (ParaOldFd.FNum = ParaNewFd.FNum) then
  begin
    Exit;
  end;
  if mReadOnly then
  begin
    raise EReadOnly.Create('leveldb/storage: storage is read-only');
  end;

  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      raise EClosed.Create('leveldb/storage: closed');
    end;
    RenameFile(TPath.Combine(mPath, GenName(ParaOldFd)), TPath.Combine(mPath, GenName(ParaNewFd)));
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TFileStorage.Close;
begin
  EnterCriticalSection(mMu);
  try
    if mOpen < 0 then
    begin
      Exit;
    end;

    if mOpen > 0 then
    begin
      InternalLog(Format('close: warning, %d files still open', [mOpen]));
    end;

    mOpen := -1;
    if mLogW <> nil then
    begin
      mLogW.Free;
    end;
    ReleaseFileLock(mFLock);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function OpenFile(const ParaPath: string; ParaReadOnly: Boolean): IStorage;
begin
  Result := TFileStorage.Create(ParaPath, ParaReadOnly);
end;

end.