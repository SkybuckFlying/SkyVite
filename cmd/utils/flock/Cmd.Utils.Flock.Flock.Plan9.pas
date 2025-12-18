unit Cmd.Utils.Flock.Flock.Plan9;

interface

uses
  Cmd.Utils.Flock.Flock,
  Cmd.Utils.Flock.Flock.Darwin,
  Cmd.Utils.Flock.Flock.Linux,
  Cmd.Utils.Flock.Flock.Solaris,
  Cmd.Utils.Flock.Flock.Windows,
  System.SysUtils;

type
  IReleaser = interface
    ['{C5B6B3F4-2D1A-4D4F-8D4C-0D1D2C2B2A29}']
    procedure Release;
  end;

function NewLock(const ParaFileName: string): IReleaser;

implementation

{$IFDEF PLAN9}
uses
  Posix.Fnctl,
  Posix.Unistd;

type
  TPlan9Lock = class(TInterfacedObject, IReleaser)
  private
    mFile: THandle;
    mFileName: string;
  public
    constructor Create(ParaFile: THandle; const ParaFileName: string);
    destructor Destroy; override;
    procedure Release;
  end;

{ TPlan9Lock }

constructor TPlan9Lock.Create(ParaFile: THandle; const ParaFileName: string);
begin
  inherited Create;
  mFile := ParaFile;
  mFileName := ParaFileName;
end;

destructor TPlan9Lock.Destroy;
begin
  if mFile <> -1 then
  begin
    Posix.Unistd.close(mFile);
    // Attempt to remove the lock file on finalization as a safeguard
    DeleteFile(mFileName);
  end;
  inherited Destroy;
end;

procedure TPlan9Lock.Release;
begin
  if mFile <> -1 then
  begin
    if Posix.Unistd.close(mFile) <> 0 then
    begin
      // Even if close fails, still attempt to delete the lock file
      DeleteFile(mFileName);
      raise Exception.Create('Failed to close file.');
    end;
    mFile := -1; // Invalidate handle
    if not DeleteFile(mFileName) then
    begin
      raise Exception.CreateFmt('Failed to delete lock file: %s', [mFileName]);
    end;
  end;
end;

function NewLock(const ParaFileName: string): IReleaser;
var
  vFile: THandle;
begin
  vFile := Posix.Fnctl.open(PAnsiChar(AnsiString(ParaFileName)), O_RDWR or O_CREAT or O_EXCL, $0644);
  if vFile = -1 then
  begin
    RaiseLastOSError;
  end;
  Result := TPlan9Lock.Create(vFile, ParaFileName);
end;

{$ELSE}
function NewLock(const ParaFileName: string): IReleaser;
begin
  raise ENotSupportedException.Create('File locking is not supported on this platform.');
end;
{$ENDIF}

end.
