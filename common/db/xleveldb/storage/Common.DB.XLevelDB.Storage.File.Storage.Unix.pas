unit Common.Db.XLevelDb.Storage.FileStorage.Unix;

{$IFDEF UNIX}

interface

uses
  Common.Db.XLevelDb.Storage,
  Common.DB.XLevelDB.Storage.File.Storage,
  Common.DB.XLevelDB.Storage.File.Storage.Nacl,
  Common.DB.XLevelDB.Storage.File.Storage.Plan9,
  Common.DB.XLevelDB.Storage.File.Storage.Solaris,
  Common.DB.XLevelDB.Storage.File.Storage.Windows,
  Common.DB.XLevelDB.Storage.Mem.Storage,
  Common.DB.XLevelDB.Storage.Storage,
  Posix.Fcntl,
  Posix.SysTypes,
  Posix.Unistd,
  System.SysUtils;

type
  TUnixFileLock = class(TInterfacedObject, IFileLock)
  private
    mFile: THandle;
  public
    constructor Create(ParaFile: THandle);
    destructor Destroy; override;
    procedure Release;
  end;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
function SetFileLock(ParaFile: THandle; ParaReadOnly, ParaLock: Boolean): Boolean;
function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
function IsErrInvalid(const ParaErr: Exception): Boolean;
function SyncDir(const ParaName: string): Boolean;

implementation

uses
  System.IOUtils,
  Posix.Base,
  Posix.SysErrno;

{ TUnixFileLock }

constructor TUnixFileLock.Create(ParaFile: THandle);
begin
  inherited Create;
  mFile := ParaFile;
end;

destructor TUnixFileLock.Destroy;
begin
  Release;
  inherited;
end;

procedure TUnixFileLock.Release;
begin
  if mFile <> 0 then
  begin
    SetFileLock(mFile, False, False);
    Close(mFile);
    mFile := 0;
  end;
end;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
var
  vFile: THandle;
  vFlags: Integer;
begin
  if ParaReadOnly then
  begin
    vFlags := O_RDONLY;
  end
  else
  begin
    vFlags := O_RDWR;
  end;

  vFile := Open(PAnsiChar(ParaPath), vFlags);
  if vFile < 0 then
  begin
    if fpgeterrno = ENOENT then
    begin
      vFile := Open(PAnsiChar(ParaPath), vFlags or O_CREAT, S_IRUSR or S_IWUSR);
      if vFile < 0 then
      begin
        RaiseLastOSError;
      end;
    end
    else
    begin
      RaiseLastOSError;
    end;
  end;

  if not SetFileLock(vFile, ParaReadOnly, True) then
  begin
    Close(vFile);
    RaiseLastOSError;
  end;

  Result := TUnixFileLock.Create(vFile);
end;

function SetFileLock(ParaFile: THandle; ParaReadOnly, ParaLock: Boolean): Boolean;
var
  vHow: Integer;
begin
  vHow := LOCK_UN;
  if ParaLock then
  begin
    if ParaReadOnly then
    begin
      vHow := LOCK_SH;
    end
    else
    begin
      vHow := LOCK_EX;
    end;
  end;
  Result := flock(ParaFile, vHow or LOCK_NB) = 0;
end;

function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
begin
  Result := System.Rename(ParaOldPath, ParaNewPath);
end;

function IsErrInvalid(const ParaErr: Exception): Boolean;
begin
  if ParaErr is EOSError then
  begin
    Result := EOSError(ParaErr).ErrorCode = EINVAL;
  end
  else
  begin
    Result := False;
  end;
end;

function SyncDir(const ParaName: string): Boolean;
var
  vFile: THandle;
begin
  vFile := Open(PAnsiChar(ParaName), O_RDONLY);
  if vFile < 0 then
  begin
    RaiseLastOSError;
  end;
  try
    if fsync(vFile) <> 0 then
    begin
      if not IsErrInvalid(Exception(ExceptObject)) then
      begin
        RaiseLastOSError;
      end;
    end;
    Result := True;
  finally
    Close(vFile);
  end;
end;

end.

{$ENDIF}
