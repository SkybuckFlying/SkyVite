unit Cmd.Utils.Flock.Flock.Windows;

interface

uses
  Cmd.Utils.Flock.Flock,
  Cmd.Utils.Flock.Flock.Darwin,
  Cmd.Utils.Flock.Flock.Linux,
  Cmd.Utils.Flock.Flock.Plan9,
  Cmd.Utils.Flock.Flock.Solaris,
  System.SysUtils;

type
  IReleaser = interface
    ['{C5B6B3F4-2D1A-4D4F-8D4C-0D1D2C2B2A29}']
    procedure Release;
  end;

function NewLock(const ParaFileName: string): IReleaser;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;

type
  TWindowsLock = class(TInterfacedObject, IReleaser)
  private
    mFileHandle: THandle;
  public
    constructor Create(ParaFileHandle: THandle);
    destructor Destroy; override;
    procedure Release;
  end;

{ TWindowsLock }

constructor TWindowsLock.Create(ParaFileHandle: THandle);
begin
  inherited Create;
  mFileHandle := ParaFileHandle;
end;

destructor TWindowsLock.Destroy;
begin
  if mFileHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(mFileHandle);
  end;
  inherited Destroy;
end;

procedure TWindowsLock.Release;
begin
  if mFileHandle <> INVALID_HANDLE_VALUE then
  begin
    if not CloseHandle(mFileHandle) then
    begin
      RaiseLastOSError;
    end;
    mFileHandle := INVALID_HANDLE_VALUE;
  end;
end;

function NewLock(const ParaFileName: string): IReleaser;
var
  vFileHandle: THandle;
begin
  vFileHandle := CreateFile(
    PChar(ParaFileName),
    GENERIC_READ or GENERIC_WRITE,
    0, // Exclusive access
    nil,
    CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    0
  );

  if vFileHandle = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;

  Result := TWindowsLock.Create(vFileHandle);
end;

{$ELSE}
function NewLock(const ParaFileName: string): IReleaser;
begin
  raise ENotSupportedException.Create('File locking is not supported on this platform.');
end;
{$ENDIF}

end.
