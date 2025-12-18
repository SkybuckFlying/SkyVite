unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageWindows;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageNacl,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStoragePlan9,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageSolaris,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageUnix,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.MemStorage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Winapi.Windows;

function NewFileLock( const ParaPath : string; ParaReadOnly : Boolean ) : THandle;
procedure ReleaseFileLock( ParaHandle : THandle );
procedure RenameFile( const ParaOldPath, ParaNewPath : string );

implementation

function NewFileLock( const ParaPath : string; ParaReadOnly : Boolean ) : THandle;
var
	vAccess, vShareMode : DWORD;
begin
	if ParaReadOnly then
	begin
		vAccess := GENERIC_READ;
		vShareMode := FILE_SHARE_READ or FILE_SHARE_WRITE;
	end
	else
	begin
		vAccess := GENERIC_READ or GENERIC_WRITE;
		vShareMode := 0; // Exclusive lock
	end;
	
	Result := CreateFile( PChar( ParaPath ), vAccess, vShareMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0 );
	if Result = INVALID_HANDLE_VALUE then
	begin
		if GetLastError = ERROR_FILE_NOT_FOUND then
			Result := CreateFile( PChar( ParaPath ), vAccess, vShareMode, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0 );
	end;
	
	if Result = INVALID_HANDLE_VALUE then
		raise Exception.Create( 'leveldb/storage: could not create or open lock file' );
end;

procedure ReleaseFileLock( ParaHandle : THandle );
begin
	if ParaHandle <> INVALID_HANDLE_VALUE then
		CloseHandle( ParaHandle );
end;

procedure RenameFile( const ParaOldPath, ParaNewPath : string );
begin
	if not MoveFileEx( PChar( ParaOldPath ), PChar( ParaNewPath ), MOVEFILE_REPLACE_EXISTING ) then
		RaiseLastOSError;
end;

end.
