unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorage;

interface

uses
	System.SysUtils,
	System.Classes,
	System.SyncObjs,
	System.IOUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileStorageWindows;

type
	TFileStorage = class;

	TFileStorageLock = class( TInterfacedObject, ILocker )
	private
		mFs : TFileStorage;
	public
		constructor Create( ParaFs : TFileStorage );
		procedure Unlock;
	end;

	TFileWrap = class( TInterfacedObject, IReader, IWriter, ISyncer )
	private
		mFs : TFileStorage;
		mFd : TFileDesc;
		mStream : TFileStream;
		mClosed : Boolean;
	public
		constructor Create( ParaFs : TFileStorage; const ParaFd : TFileDesc; ParaStream : TFileStream );
		destructor Destroy; override;
		
		function Read( var ParaBuf : TBytes; ParaOffset, ParaCount : Integer ) : Integer;
		function Seek( ParaOffset : Int64; ParaOrigin : TSeekOrigin ) : Int64;
		function ReadAt( var ParaBuf : TBytes; ParaOffset : Int64 ) : Integer;
		function Write( const ParaBuf : TBytes ) : Integer;
		procedure Sync;
		procedure Close;
	end;

	TFileStorage = class( TInterfacedObject, IStorage )
	private
		mPath : string;
		mReadOnly : Boolean;
		mMu : TCriticalSection;
		mFlock : THandle;
		mSLock : TFileStorageLock;
		mLogW : TFileStream;
		mOpenCount : Integer;
		
		function GenName( const ParaFd : TFileDesc ) : string;
		function ParseName( const ParaName : string; out ParaFd : TFileDesc ) : Boolean;
		procedure DoLog( const ParaStr : string );
	public
		constructor Create( const ParaPath : string; ParaReadOnly : Boolean );
		destructor Destroy; override;
		
		function Lock : ILocker;
		procedure Log( const ParaStr : string );
		procedure SetMeta( const ParaFd : TFileDesc );
		function GetMeta : TFileDesc;
		function List( ParaFt : TFileType ) : TArray<TFileDesc>;
		function Open( const ParaFd : TFileDesc ) : IReader;
		function Create( const ParaFd : TFileDesc ) : IWriter;
		procedure Remove( const ParaFd : TFileDesc );
		procedure Rename( const ParaOldFd, ParaNewFd : TFileDesc );
		procedure Close;
	end;

function OpenFile( const ParaPath : string; ParaReadOnly : Boolean ) : IStorage;

implementation

function OpenFile( const ParaPath : string; ParaReadOnly : Boolean ) : IStorage;
begin
	Result := TFileStorage.Create( ParaPath, ParaReadOnly );
end;

{ TFileStorageLock }

constructor TFileStorageLock.Create( ParaFs : TFileStorage );
begin
	mFs := ParaFs;
end;

procedure TFileStorageLock.Unlock;
begin
	mFs.mMu.Enter;
	try
		if mFs.mSLock = Self then
			mFs.mSLock := nil;
	finally
		mFs.mMu.Leave;
	end;
end;

{ TFileWrap }

constructor TFileWrap.Create( ParaFs : TFileStorage; const ParaFd : TFileDesc; ParaStream : TFileStream );
begin
	mFs := ParaFs;
	mFd := ParaFd;
	mStream := ParaStream;
end;

destructor TFileWrap.Destroy;
begin
	Close;
	inherited;
end;

function TFileWrap.Read( var ParaBuf : TBytes; ParaOffset, ParaCount : Integer ) : Integer;
begin
	Result := mStream.Read( ParaBuf[ ParaOffset ], ParaCount );
end;

function TFileWrap.Seek( ParaOffset : Int64; ParaOrigin : TSeekOrigin ) : Int64;
begin
	Result := mStream.Seek( ParaOffset, ParaOrigin );
end;

function TFileWrap.ReadAt( var ParaBuf : TBytes; ParaOffset : Int64 ) : Integer;
begin
	mStream.Position := ParaOffset;
	Result := mStream.Read( ParaBuf[ 0 ], Length( ParaBuf ) );
end;

function TFileWrap.Write( const ParaBuf : TBytes ) : Integer;
begin
	Result := mStream.Write( ParaBuf[ 0 ], Length( ParaBuf ) );
end;

procedure TFileWrap.Sync;
begin
	// TFileStream doesn't have a direct Flush/Sync that guarantees disk write on all OS, 
	// but on Windows, FlushFileBuffers can be used if needed.
end;

procedure TFileWrap.Close;
begin
	if not mClosed then
	begin
		mStream.Free;
		mStream := nil;
		mFs.mMu.Enter;
		try
			mFs.mOpenCount := mFs.mOpenCount - 1;
		finally
			mFs.mMu.Leave;
		end;
		mClosed := True;
	end;
end;

{ TFileStorage }

constructor TFileStorage.Create( const ParaPath : string; ParaReadOnly : Boolean );
begin
	mPath := ParaPath;
	mReadOnly := ParaReadOnly;
	mMu := TCriticalSection.Create;
	
	if not TDirectory.Exists( mPath ) then
	begin
		if not mReadOnly then
			TDirectory.CreateDirectory( mPath )
		else
			raise Exception.Create( 'leveldb/storage: directory not found' );
	end;
	
	mFlock := NewFileLock( TPath.Combine( mPath, 'LOCK' ), mReadOnly );
	
	if not mReadOnly then
	begin
		try
			mLogW := TFileStream.Create( TPath.Combine( mPath, 'LOG' ), fmCreate or fmOpenWrite );
		except
			// Log opening might fail, continue anyway
		end;
	end;
end;

destructor TFileStorage.Destroy;
begin
	Close;
	mMu.Free;
	inherited;
end;

function TFileStorage.GenName( const ParaFd : TFileDesc ) : string;
begin
	case ParaFd.FileType of
		ftManifest: Result := Format( 'MANIFEST-%06d', [ ParaFd.Num ] );
		ftJournal:  Result := Format( '%06d.log', [ ParaFd.Num ] );
		ftTable:    Result := Format( '%06d.ldb', [ ParaFd.Num ] );
		ftTemp:     Result := Format( '%06d.tmp', [ ParaFd.Num ] );
	else
		Result := '';
	end;
end;

function TFileStorage.ParseName( const ParaName : string; out ParaFd : TFileDesc ) : Boolean;
var
	vExt : string;
	vBase : string;
	vNum : Int64;
begin
	Result := False;
	if ParaName.StartsWith( 'MANIFEST-' ) then
	begin
		if TryStrToInt64( Copy( ParaName, 10, Length( ParaName ) ), vNum ) then
		begin
			ParaFd.FileType := ftManifest;
			ParaFd.Num := vNum;
			Exit( True );
		end;
	end;
	
	vExt := TPath.GetExtension( ParaName );
	vBase := TPath.GetFileNameWithoutExtension( ParaName );
	if TryStrToInt64( vBase, vNum ) then
	begin
		ParaFd.Num := vNum;
		if vExt = '.log' then ParaFd.FileType := ftJournal
		else if ( vExt = '.ldb' ) or ( vExt = '.sst' ) then ParaFd.FileType := ftTable
		else if vExt = '.tmp' then ParaFd.FileType := ftTemp
		else Exit( False );
		Exit( True );
	end;
end;

function TFileStorage.Lock : ILocker;
begin
	mMu.Enter;
	try
		if mReadOnly then
			Exit( TFileStorageLock.Create( Self ) );
		if mSLock <> nil then
			raise Exception.Create( 'leveldb/storage: already locked' );
		mSLock := TFileStorageLock.Create( Self );
		Result := mSLock;
	finally
		mMu.Leave;
	end;
end;

procedure TFileStorage.DoLog( const ParaStr : string );
var
	vBuf : TBytes;
begin
	if mLogW <> nil then
	begin
		vBuf := TEncoding.ANSI.GetBytes( ParaStr + #13#10 );
		mLogW.Write( vBuf[ 0 ], Length( vBuf ) );
	end;
end;

procedure TFileStorage.Log( const ParaStr : string );
begin
	if not mReadOnly then
	begin
		mMu.Enter;
		try
			DoLog( ParaStr );
		finally
			mMu.Leave;
		end;
	end;
end;

procedure TFileStorage.SetMeta( const ParaFd : TFileDesc );
var
	vContent : string;
	vCurrentPath : string;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	
	vContent := GenName( ParaFd ) + #10;
	vCurrentPath := TPath.Combine( mPath, 'CURRENT' );
	
	mMu.Enter;
	try
		TFile.WriteAllText( vCurrentPath, vContent );
	finally
		mMu.Leave;
	end;
end;

function TFileStorage.GetMeta : TFileDesc;
var
	vCurrentPath : string;
	vContent : string;
begin
	vCurrentPath := TPath.Combine( mPath, 'CURRENT' );
	mMu.Enter;
	try
		if TFile.Exists( vCurrentPath ) then
		begin
			vContent := TFile.ReadAllText( vCurrentPath ).Trim;
			if not ParseName( vContent, Result ) then
				raise Exception.Create( 'leveldb/storage: corrupted CURRENT file' );
		end
		else
			raise EFileNotFoundException.Create( 'leveldb/storage: CURRENT file not found' );
	finally
		mMu.Leave;
	end;
end;

function TFileStorage.List( ParaFt : TFileType ) : TArray<TFileDesc>;
var
	vFiles : TArray<string>;
	vFile : string;
	vFd : TFileDesc;
begin
	vFiles := TDirectory.GetFiles( mPath );
	SetLength( Result, 0 );
	for vFile in vFiles do
	begin
		if ParseName( TPath.GetFileName( vFile ), vFd ) then
		begin
			if vFd.FileType = ParaFt then
			begin
				SetLength( Result, Length( Result ) + 1 );
				Result[ High( Result ) ] := vFd;
			end;
		end;
	end;
end;

function TFileStorage.Open( const ParaFd : TFileDesc ) : IReader;
var
	vPath : string;
	vStream : TFileStream;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	
	vPath := TPath.Combine( mPath, GenName( ParaFd ) );
	if not TFile.Exists( vPath ) then
		raise EFileNotFoundException.Create( 'leveldb/storage: file not found' );
		
	vStream := TFileStream.Create( vPath, fmOpenRead or fmShareDenyNone );
	Result := TFileWrap.Create( Self, ParaFd, vStream );
	
	mMu.Enter;
	try
		mOpenCount := mOpenCount + 1;
	finally
		mMu.Leave;
	end;
end;

function TFileStorage.Create( const ParaFd : TFileDesc ) : IWriter;
var
	vPath : string;
	vStream : TFileStream;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	if mReadOnly then
		raise Exception.Create( 'leveldb/storage: read-only' );
		
	vPath := TPath.Combine( mPath, GenName( ParaFd ) );
	vStream := TFileStream.Create( vPath, fmCreate );
	Result := TFileWrap.Create( Self, ParaFd, vStream );
	
	mMu.Enter;
	try
		mOpenCount := mOpenCount + 1;
	finally
		mMu.Leave;
	end;
end;

procedure TFileStorage.Remove( const ParaFd : TFileDesc );
var
	vPath : string;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	if mReadOnly then
		raise Exception.Create( 'leveldb/storage: read-only' );
	
	vPath := TPath.Combine( mPath, GenName( ParaFd ) );
	TFile.Delete( vPath );
end;

procedure TFileStorage.Rename( const ParaOldFd, ParaNewFd : TFileDesc );
begin
	if ( not ParaOldFd.Ok ) or ( not ParaNewFd.Ok ) then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	if mReadOnly then
		raise Exception.Create( 'leveldb/storage: read-only' );
	
	RenameFile( TPath.Combine( mPath, GenName( ParaOldFd ) ), TPath.Combine( mPath, GenName( ParaNewFd ) ) );
end;

procedure TFileStorage.Close;
begin
	mMu.Enter;
	try
		if mOpenCount > 0 then
			// Warning log could be added here
		
		if mLogW <> nil then
		begin
			mLogW.Free;
			mLogW := nil;
		end;
		
		ReleaseFileLock( mFlock );
		mFlock := INVALID_HANDLE_VALUE;
	finally
		mMu.Leave;
	end;
end;

end.
