unit Cmd.Utils.Flock;

interface

uses
	System.SysUtils;

type
	IReleaser = interface
		['{E77A75A5-6F6B-422A-84E3-6E3A59B5E1A2}']
		function Release: boolean;
	end;

function New(const ParaFileName: string; out ParaExisted: boolean): IReleaser;

implementation

uses
	System.IOUtils;

{$IFDEF MSWINDOWS}
uses
	Winapi.Windows;

type
	TFlock = class(TInterfacedObject, IReleaser)
	private
		mHandle: THandle;
	public
		constructor Create(const ParaFileName: string);
		destructor Destroy; override;
		function Release: boolean;
	end;

constructor TFlock.Create(const ParaFileName: string);
begin
	inherited Create;
	mHandle := CreateFile(PChar(ParaFileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
end;

destructor TFlock.Destroy;
begin
	if mHandle <> INVALID_HANDLE_VALUE then
	begin
		CloseHandle(mHandle);
	end;
	inherited;
end;

function TFlock.Release: boolean;
begin
	if mHandle <> INVALID_HANDLE_VALUE then
	begin
		CloseHandle(mHandle);
		mHandle := INVALID_HANDLE_VALUE;
		Result := True;
	end
	else
	begin
		Result := False;
	end;
end;

function newLock(const ParaFileName: string): IReleaser;
begin
	Result := TFlock.Create(ParaFileName);
end;

{$ELSEIF DEFINED(LINUX) or DEFINED(MACOS)}
uses
	Posix.Fcntl, Posix.Errno, Posix.SysTypes, Posix.Unistd;

type
	TUnixLock = class(TInterfacedObject, IReleaser)
	private
		mFile: TFileStream;
		function SetLock(ParaLock: boolean): boolean;
	public
		constructor Create(const ParaFileName: string);
		destructor Destroy; override;
		function Release: boolean;
	end;

constructor TUnixLock.Create(const ParaFileName: string);
begin
	inherited Create;
	mFile := TFileStream.Create(ParaFileName, fmOpenReadWrite or fmCreate);
	if not SetLock(True) then
	begin
		mFile.Free;
		raise Exception.Create('Failed to lock file.');
	end;
end;

destructor TUnixLock.Destroy;
begin
	if mFile <> nil then
	begin
		SetLock(False);
		mFile.Free;
	end;
	inherited;
end;

function TUnixLock.Release: boolean;
begin
	if mFile <> nil then
	begin
		Result := SetLock(False);
		mFile.Free;
		mFile := nil;
	end
	else
	begin
		Result := False;
	end;
end;

function TUnixLock.SetLock(ParaLock: boolean): boolean;
var
	vHow: Integer;
begin
	if ParaLock then
	begin
		vHow := LOCK_EX or LOCK_NB;
	end
	else
	begin
		vHow := LOCK_UN;
	end;
	Result := flock(mFile.Handle, vHow) = 0;
end;

function newLock(const ParaFileName: string): IReleaser;
begin
	Result := TUnixLock.Create(ParaFileName);
end;

{$ELSE}
function newLock(const ParaFileName: string): IReleaser;
begin
	raise ENotSupportedException.Create('File locking not supported on this platform');
end;
{$ENDIF}

function New(const ParaFileName: string; out ParaExisted: boolean): IReleaser;
var
	vDirectory: string;
begin
	try
		vDirectory := TPath.GetDirectoryName(ParaFileName);
		if not TDirectory.Exists(vDirectory) then
		begin
			TDirectory.CreateDirectory(vDirectory);
		end;

		ParaExisted := TFile.Exists(ParaFileName);

		Result := newLock(ParaFileName);
	except
		on E: Exception do
		begin
			Result := nil;
			raise;
		end;
	end;
end;

end.