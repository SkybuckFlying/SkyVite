unit Common.Db.XLevelDb.Storage.FileStorage.NaCl;

{$IFDEF NACL}

interface

uses
  Common.Db.XLevelDb.Storage,
  Common.DB.XLevelDB.Storage.File.Storage,
  Common.DB.XLevelDB.Storage.File.Storage.Plan9,
  Common.DB.XLevelDB.Storage.File.Storage.Solaris,
  Common.DB.XLevelDB.Storage.File.Storage.Unix,
  Common.DB.XLevelDB.Storage.File.Storage.Windows,
  Common.DB.XLevelDB.Storage.Mem.Storage,
  Common.DB.XLevelDB.Storage.Storage,
  System.SysUtils;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
function SetFileLock(ParaFile: THandle; ParaReadOnly, ParaLock: Boolean): Boolean;
function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
function IsErrInvalid(const ParaErr: Exception): Boolean;
function SyncDir(const ParaName: string): Boolean;

implementation

uses
  System.IOUtils;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
begin
  raise ENotSupportedException.Create('File locking not supported on this platform');
end;

function SetFileLock(ParaFile: THandle; ParaReadOnly, ParaLock: Boolean): Boolean;
begin
  raise ENotSupportedException.Create('File locking not supported on this platform');
end;

function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
begin
  raise ENotSupportedException.Create('File renaming not supported on this platform');
end;

function IsErrInvalid(const ParaErr: Exception): Boolean;
begin
  Result := False;
end;

function SyncDir(const ParaName: string): Boolean;
begin
  raise ENotSupportedException.Create('Directory syncing not supported on this platform');
end;

end.

{$ENDIF}
