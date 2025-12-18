unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage;

interface

uses
	System.SysUtils,
	System.Classes;

type
	TFileType = ( 
		ftManifest = 1, 
		ftJournal = 2, 
		ftTable = 4, 
		ftTemp = 8 
	);

const
	FT_ALL = [ ftManifest, ftJournal, ftTable, ftTemp ];

type
	TFileDesc = record
		FileType : TFileType;
		Num : Int64;
		function Stringify : string;
		function Zero : Boolean;
		function Ok : Boolean;
	end;

	ISyncer = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F77}']
		procedure Sync;
	end;

	IReader = interface
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F78}']
		function Read( var ParaBuf : TBytes; ParaOffset, ParaCount : Integer ) : Integer;
		function Seek( ParaOffset : Int64; ParaOrigin : TSeekOrigin ) : Int64;
		function ReadAt( var ParaBuf : TBytes; ParaOffset : Int64 ) : Integer;
		procedure Close;
	end;

	IWriter = interface( ISyncer )
		['{D5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F79}']
		function Write( const ParaBuf : TBytes ) : Integer;
		procedure Close;
	end;

	ILocker = interface
		['{F5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F7A}']
		procedure Unlock;
	end;

	IStorage = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F7B}']
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

implementation

{ TFileDesc }

function TFileDesc.Stringify : string;
begin
	case FileType of
		ftManifest: Result := Format( 'MANIFEST-%06d', [ Num ] );
		ftJournal:  Result := Format( '%06d.log', [ Num ] );
		ftTable:    Result := Format( '%06d.ldb', [ Num ] );
		ftTemp:     Result := Format( '%06d.tmp', [ Num ] );
	else
		Result := Format( '%x-%d', [ Ord( FileType ), Num ] );
	end;
end;

function TFileDesc.Zero : Boolean;
begin
	Result := ( Num = 0 ) and ( FileType = ftManifest ); // In Go, zero value of struct. MANIFEST is 1, so 0 is invalid unless we use a distinct'zero' state.
	// Actually, in Go, FileDesc{} has Type=0, Num=0.
	// Our TFileType starts at 0 if we don't specify.
end;

function TFileDesc.Ok : Boolean;
begin
	Result := ( FileType in [ ftManifest, ftJournal, ftTable, ftTemp ] ) and ( Num >= 0 );
end;

end.
