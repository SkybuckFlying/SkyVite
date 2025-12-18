unit Cmd.Utils.Flock.Flock.Solaris;

interface

uses
  Cmd.Utils.Flock.Flock,
  Cmd.Utils.Flock.Flock.Darwin,
  Cmd.Utils.Flock.Flock.Linux,
  Cmd.Utils.Flock.Flock.Plan9,
  Cmd.Utils.Flock.Flock.Windows,
  System.SysUtils;

type
  IReleaser = interface
    ['{C5B6B3F4-2D1A-4D4F-8D4C-0D1D2C2B2A29}']
    procedure Release;
  end;

function NewLock(const ParaFileName: string): IReleaser;

implementation

{$IFDEF SOLARIS}
uses
  Posix.Fnctl,
  Posix.Unistd;

type
  TUnixLock = class(TInterfacedObject, IReleaser)
  private
    mFile: THandle;
    function SetLock(ParaLock: Boolean): Integer;
  public
    constructor Create(ParaFile: THandle);
    destructor Destroy; override;
    procedure Release;
  end;

{ TUnixLock }

constructor TUnixLock.Create(ParaFile: THandle);
begin
  inherited Create;
  mFile := ParaFile;
end;

destructor TUnixLock.Destroy;
begin
  if mFile <> -1 then
  begin
    Posix.Unistd.close(mFile);
  end;
  inherited Destroy;
end;

procedure TUnixLock.Release;
begin
  if SetLock(False) <> 0 then
  begin
    raise Exception.Create('Failed to release file lock.');
  end;
  if Posix.Unistd.close(mFile) <> 0 then
  begin
    raise Exception.Create('Failed to close file.');
  end;
  mFile := -1; // Invalidate the handle
end;

function TUnixLock.SetLock(ParaLock: Boolean): Integer;
var
  vFlock: TFlock;
begin
  vFlock.l_start := 0;
  vFlock.l_len := 0;
  vFlock.l_whence := SEEK_SET;
  if ParaLock then
  begin
    vFlock.l_type := F_WRLCK;
  end
  else
  begin
    vFlock.l_type := F_UNLCK;
  end;
  Result := Posix.Fnctl.fcntl(mFile, F_SETLK, vFlock);
end;

function NewLock(const ParaFileName: string): IReleaser;
var
  vFile: THandle;
  vLock: TUnixLock;
  vError: Integer;
begin
  vFile := Posix.Fnctl.open(PAnsiChar(AnsiString(ParaFileName)), O_RDWR or O_CREAT, $0644);
  if vFile = -1 then
  begin
    RaiseLastOSError;
  end;

  vLock := TUnixLock.Create(vFile);
  try
    vError := vLock.SetLock(True);
    if vError <> 0 then
    begin
      vLock.Free;
      RaiseLastOSError;
    end;
    Result := vLock;
  except
    on E: Exception do
    begin
      vLock.Free;
      raise;
    end;
  end;
end;

{$ELSE}
function NewLock(const ParaFileName: string): IReleaser;
begin
  raise ENotSupportedException.Create('File locking is not supported on this platform.');
end;
{$ENDIF}

end.
