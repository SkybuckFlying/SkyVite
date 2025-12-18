unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.MemStorage;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	System.SyncObjs,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage;

type
	TMemFile = class
	public
		Data : TMemoryStream;
		Opened : Boolean;
		constructor Create;
		destructor Destroy; override;
		procedure Reset;
	end;

	TMemStorage = class;

	TMemStorageLock = class( TInterfacedObject, ILocker )
	private
		mMs : TMemStorage;
	public
		constructor Create( ParaMs : TMemStorage );
		procedure Unlock;
	end;

	TMemReader = class( TInterfacedObject, IReader )
	private
		mMs : TMemStorage;
		mFile : TMemFile;
		mPos : Int64;
		mClosed : Boolean;
	public
		constructor Create( ParaMs : TMemStorage; ParaFile : TMemFile );
		function Read( var ParaBuf : TBytes; ParaOffset, ParaCount : Integer ) : Integer;
		function Seek( ParaOffset : Int64; ParaOrigin : TSeekOrigin ) : Int64;
		function ReadAt( var ParaBuf : TBytes; ParaOffset : Int64 ) : Integer;
		procedure Close;
	end;

	TMemWriter = class( TInterfacedObject, IWriter, ISyncer )
	private
		mMs : TMemStorage;
		mFile : TMemFile;
		mClosed : Boolean;
	public
		constructor Create( ParaMs : TMemStorage; ParaFile : TMemFile );
		function Write( const ParaBuf : TBytes ) : Integer;
		procedure Sync;
		procedure Close;
	end;

	TMemStorage = class( TInterfacedObject, IStorage )
	private
		mMu : TCriticalSection;
		mSLock : TMemStorageLock;
		mFiles : TDictionary<UInt64, TMemFile>;
		mMeta : TFileDesc;
		function PackFile( const ParaFd : TFileDesc ) : UInt64;
		function UnpackFile( ParaX : UInt64 ) : TFileDesc;
	public
		constructor Create;
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

function NewMemStorage : IStorage;

implementation

function NewMemStorage : IStorage;
begin
	Result := TMemStorage.Create;
end;

{ TMemFile }

constructor TMemFile.Create;
begin
	Data := TMemoryStream.Create;
end;

destructor TMemFile.Destroy;
begin
	Data.Free;
	inherited;
end;

procedure TMemFile.Reset;
begin
	Data.Clear;
end;

{ TMemStorageLock }

constructor TMemStorageLock.Create( ParaMs : TMemStorage );
begin
	mMs := ParaMs;
end;

procedure TMemStorageLock.Unlock;
begin
	mMs.mMu.Enter;
	try
		if mMs.mSLock = Self then
			mMs.mSLock := nil;
	finally
		mMs.mMu.Leave;
	end;
end;

{ TMemReader }

constructor TMemReader.Create( ParaMs : TMemStorage; ParaFile : TMemFile );
begin
	mMs := ParaMs;
	mFile := ParaFile;
	mPos := 0;
end;

function TMemReader.Read( var ParaBuf : TBytes; ParaOffset, ParaCount : Integer ) : Integer;
begin
	mFile.Data.Position := mPos;
	Result := mFile.Data.Read( ParaBuf[ ParaOffset ], ParaCount );
	mPos := mFile.Data.Position;
end;

function TMemReader.Seek( ParaOffset : Int64; ParaOrigin : TSeekOrigin ) : Int64;
begin
	case ParaOrigin of
		soBeginning: mPos := ParaOffset;
		soCurrent:   mPos := mPos + ParaOffset;
		soEnd:       mPos := mFile.Data.Size + ParaOffset;
	end;
	Result := mPos;
end;

function TMemReader.ReadAt( var ParaBuf : TBytes; ParaOffset : Int64 ) : Integer;
begin
	mFile.Data.Position := ParaOffset;
	Result := mFile.Data.Read( ParaBuf[ 0 ], Length( ParaBuf ) );
end;

procedure TMemReader.Close;
begin
	mMs.mMu.Enter;
	try
		if not mClosed then
		begin
			mFile.Opened := False;
			mClosed := True;
		end;
	finally
		mMs.mMu.Leave;
	end;
end;

{ TMemWriter }

constructor TMemWriter.Create( ParaMs : TMemStorage; ParaFile : TMemFile );
begin
	mMs := ParaMs;
	mFile := ParaFile;
end;

function TMemWriter.Write( const ParaBuf : TBytes ) : Integer;
begin
	Result := mFile.Data.Write( ParaBuf[ 0 ], Length( ParaBuf ) );
end;

procedure TMemWriter.Sync;
begin
end;

procedure TMemWriter.Close;
begin
	mMs.mMu.Enter;
	try
		if not mClosed then
		begin
			mFile.Opened := False;
			mClosed := True;
		end;
	finally
		mMs.mMu.Leave;
	end;
end;

{ TMemStorage }

constructor TMemStorage.Create;
begin
	mMu := TCriticalSection.Create;
	mFiles := TDictionary<UInt64, TMemFile>.Create;
end;

destructor TMemStorage.Destroy;
var
	vFile : TMemFile;
begin
	for vFile in mFiles.Values do
		vFile.Free;
	mFiles.Free;
	mMu.Free;
	inherited;
end;

function TMemStorage.PackFile( const ParaFd : TFileDesc ) : UInt64;
begin
	Result := ( UInt64( ParaFd.Num ) shl 4 ) or UInt64( ParaFd.FileType );
end;

function TMemStorage.UnpackFile( ParaX : UInt64 ) : TFileDesc;
begin
	Result.FileType := TFileType( ParaX and $F );
	Result.Num := Int64( ParaX shr 4 );
end;

function TMemStorage.Lock : ILocker;
begin
	mMu.Enter;
	try
		if mSLock <> nil then
			raise Exception.Create( 'leveldb/storage: already locked' );
		mSLock := TMemStorageLock.Create( Self );
		Result := mSLock;
	finally
		mMu.Leave;
	end;
end;

procedure TMemStorage.Log( const ParaStr : string );
begin
end;

procedure TMemStorage.SetMeta( const ParaFd : TFileDesc );
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	mMu.Enter;
	try
		mMeta := ParaFd;
	finally
		mMu.Leave;
	end;
end;

function TMemStorage.GetMeta : TFileDesc;
begin
	mMu.Enter;
	try
		if mMeta.Zero then
			raise EFileNotFoundException.Create( 'leveldb/storage: meta not found' );
		Result := mMeta;
	finally
		mMu.Leave;
	end;
end;

function TMemStorage.List( ParaFt : TFileType ) : TArray<TFileDesc>;
var
	vPack : UInt64;
	vFd : TFileDesc;
begin
	mMu.Enter;
	try
		SetLength( Result, 0 );
		for vPack in mFiles.Keys do
		begin
			vFd := UnpackFile( vPack );
			if vFd.FileType = ParaFt then
			begin
				SetLength( Result, Length( Result ) + 1 );
				Result[ High( Result ) ] := vFd;
			end;
		end;
	finally
		mMu.Leave;
	end;
end;

function TMemStorage.Open( const ParaFd : TFileDesc ) : IReader;
var
	vFile : TMemFile;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	mMu.Enter;
	try
		if mFiles.TryGetValue( PackFile( ParaFd ), vFile ) then
		begin
			if vFile.Opened then
				raise Exception.Create( 'leveldb/storage: file still open' );
			vFile.Opened := True;
			Result := TMemReader.Create( Self, vFile );
		end
		else
			raise EFileNotFoundException.Create( 'leveldb/storage: file not found' );
	finally
		mMu.Leave;
	end;
end;

function TMemStorage.Create( const ParaFd : TFileDesc ) : IWriter;
var
	vFile : TMemFile;
	vPack : UInt64;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	vPack := PackFile( ParaFd );
	mMu.Enter;
	try
		if mFiles.TryGetValue( vPack, vFile ) then
		begin
			if vFile.Opened then
				raise Exception.Create( 'leveldb/storage: file still open' );
			vFile.Reset;
		end
		else
		begin
			vFile := TMemFile.Create;
			mFiles.Add( vPack, vFile );
		end;
		vFile.Opened := True;
		Result := TMemWriter.Create( Self, vFile );
	finally
		mMu.Leave;
	end;
end;

procedure TMemStorage.Remove( const ParaFd : TFileDesc );
var
	vFile : TMemFile;
	vPack : UInt64;
begin
	if not ParaFd.Ok then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	vPack := PackFile( ParaFd );
	mMu.Enter;
	try
		if mFiles.TryGetValue( vPack, vFile ) then
		begin
			vFile.Free;
			mFiles.Remove( vPack );
		end
		else
			raise EFileNotFoundException.Create( 'leveldb/storage: file not found' );
	finally
		mMu.Leave;
	end;
end;

procedure TMemStorage.Rename( const ParaOldFd, ParaNewFd : TFileDesc );
var
	vOldFile, vNewFile : TMemFile;
	vOldPack, vNewPack : UInt64;
begin
	if ( not ParaOldFd.Ok ) or ( not ParaNewFd.Ok ) then
		raise Exception.Create( 'leveldb/storage: invalid file for argument' );
	if ParaOldFd.Num = ParaNewFd.Num then
		Exit;
	
	vOldPack := PackFile( ParaOldFd );
	vNewPack := PackFile( ParaNewFd );
	
	mMu.Enter;
	try
		if not mFiles.TryGetValue( vOldPack, vOldFile ) then
			raise EFileNotFoundException.Create( 'leveldb/storage: file not found' );
		
		if vOldFile.Opened then
			raise Exception.Create( 'leveldb/storage: file still open' );
		
		if mFiles.TryGetValue( vNewPack, vNewFile ) then
		begin
			if vNewFile.Opened then
				raise Exception.Create( 'leveldb/storage: file still open' );
			vNewFile.Free;
			mFiles.Remove( vNewPack );
		end;
		
		mFiles.Remove( vOldPack );
		mFiles.Add( vNewPack, vOldFile );
	finally
		mMu.Leave;
	end;
end;

procedure TMemStorage.Close;
begin
end;

end.
