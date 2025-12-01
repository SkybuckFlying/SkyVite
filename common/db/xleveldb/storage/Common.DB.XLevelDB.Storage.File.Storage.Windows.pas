unit Common.Db.XLevelDb.Storage.FileStorage.Windows;

{$IFDEF MSWINDOWS}

interface

uses
  System.SysUtils,
  Windows,
  Common.Db.XLevelDb.Storage;

type
  TWindowsFileLock = class(TInterfacedObject, IFileLock)
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

{ TWindowsFileLock }

constructor TWindowsFileLock.Create(ParaFile: THandle);
begin
  inherited Create;
  mFile := ParaFile;
end;

destructor TWindowsFileLock.Destroy;
begin
  Release;
  inherited;
end;

procedure TWindowsFileLock.Release;
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
  vAccess, vShareMode: Cardinal;
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

  vFile := CreateFile(PChar(ParaPath), vAccess, vShareMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if vFile = INVALID_HANDLE_VALUE then
  begin
    if GetLastError = ERROR_FILE_NOT_FOUND then
    begin
      vFile := CreateFile(PChar(ParaPath), vAccess, vShareMode, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
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
  Result := TWindowsFileLock.Create(vFile);
end;

function Rename(const ParaOldPath, ParaNewPath: string): Boolean;
begin
  Result := MoveFileEx(PChar(ParaOldPath), PChar(ParaNewPath), MOVEFILE_REPLACE_EXISTING);
end;

function SyncDir(const ParaName: string): Boolean;
begin
  Result := True;
end;

end.

{$ENDIF}
