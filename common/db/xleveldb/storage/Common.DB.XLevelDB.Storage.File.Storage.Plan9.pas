unit Common.Db.XLevelDb.Storage.FileStorage.Plan9;

{$IFDEF PLAN9}

interface

uses
  Common.Db.XLevelDb.Storage,
  Common.DB.XLevelDB.Storage.File.Storage,
  Common.DB.XLevelDB.Storage.File.Storage.Nacl,
  Common.DB.XLevelDB.Storage.File.Storage.Solaris,
  Common.DB.XLevelDB.Storage.File.Storage.Unix,
  Common.DB.XLevelDB.Storage.File.Storage.Windows,
  Common.DB.XLevelDB.Storage.Mem.Storage,
  Common.DB.XLevelDB.Storage.Storage,
  System.SysUtils;

type
  TPlan9FileLock = class(TInterfacedObject, IFileLock)
  private
    mFile: THandle;
  public
    constructor Create(ParaFile: THandle);
    destructor Destroy; override;
    procedure Release;
  end;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
function SyncDir(const ParaName: string): Boolean;

implementation

uses
  System.IOUtils;

{ TPlan9FileLock }

constructor TPlan9FileLock.Create(ParaFile: THandle);
begin
  inherited Create;
  mFile := ParaFile;
end;

destructor TPlan9FileLock.Destroy;
begin
  Release;
  inherited;
end;

procedure TPlan9FileLock.Release;
begin
  if mFile <> 0 then
  begin
    CloseHandle(mFile);
    mFile := 0;
  end;
end;

function NewFileLock(const ParaPath: string; ParaReadOnly: Boolean): IFileLock;
var
  vFile: THandle;
  vMode: Cardinal;
begin
  if ParaReadOnly then
  begin
    vMode := fmOpenRead;
  end
  else
  begin
    vMode := fmOpenReadWrite or fmShareExclusive;
  end;

  vFile := FileCreate(ParaPath, vMode);
  if vFile = INVALID_HANDLE_VALUE then
  begin
    if GetLastError = ERROR_FILE_NOT_FOUND then
    begin
      vFile := FileCreate(ParaPath, vMode or fmCreate);
      if vFile = INVALID_HANDLE_VALUE then
      begin
        RaiseLastOSError;
      end;
    end
    else
    begin
      RaiseLastOSError;
    end;
  end;
  Result := TPlan9FileLock.Create(vFile);
end;

function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
begin
  if TFile.Exists(ParaNewPath) then
  begin
    TFile.Delete(ParaNewPath);
  end;
  Result := TFile.Rename(ParaOldPath, ParaNewPath);
end;

function SyncDir(const ParaName: string): Boolean;
var
  vFile: THandle;
begin
  vFile := FileOpen(ParaName, fmOpenRead);
  if vFile = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;
  try
    Result := FlushFileBuffers(vFile);
  finally
    FileClose(vFile);
  end;
end;

end.

{$ENDIF}
