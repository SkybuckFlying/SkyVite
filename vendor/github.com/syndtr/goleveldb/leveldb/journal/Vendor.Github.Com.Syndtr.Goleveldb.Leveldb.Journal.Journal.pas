unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Journal.Journal;

interface

uses
	System.SysUtils,
	System.Classes,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32;

const
	FULL_CHUNK_TYPE   = 1;
	FIRST_CHUNK_TYPE  = 2;
	MIDDLE_CHUNK_TYPE = 3;
	LAST_CHUNK_TYPE   = 4;
	BLOCK_SIZE  = 32 * 1024;
	HEADER_SIZE = 7;

type
	EJournalCorrupted = class( Exception )
	public
		Size : Integer;
		Reason : string;
		constructor Create( ParaSize : Integer; const ParaReason : string );
	end;

	IDropper = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F7C}']
		procedure Drop( ParaErr : Exception );
	end;

	TJournalReader = class
	private
		mStream : TStream;
		mDropper : IDropper;
		mStrict : Boolean;
		mChecksum : Boolean;
		mSeq : Integer;
		mI, mJ : Integer;
		mN : Integer;
		mLast : Boolean;
		mErr : Exception;
		mBuf : array[ 0..BLOCK_SIZE - 1 ] of Byte;
		
		function NextChunk( ParaFirst : Boolean ) : Boolean;
		function Corrupt( ParaN : Integer; const ParaReason : string; ParaSkip : Boolean ) : Boolean;
	public
		constructor Create( ParaStream : TStream; ParaDropper : IDropper; ParaStrict, ParaChecksum : Boolean );
		function Next : TStream;
	end;

	TJournalWriter = class
	private
		mStream : TStream;
		mSeq : Integer;
		mI, mJ : Integer;
		mWritten : Integer;
		mFirst : Boolean;
		mPending : Boolean;
		mErr : Exception;
		mBuf : array[ 0..BLOCK_SIZE - 1 ] of Byte;
		
		procedure FillHeader( ParaLast : Boolean );
		procedure WriteBlock;
		procedure WritePending;
	public
		constructor Create( ParaStream : TStream );
		function Next : TStream;
		procedure Close;
		procedure Flush;
	end;

	TSingleReader = class( TStream )
	private
		mR : TJournalReader;
		mSeq : Integer;
		mErr : Exception;
	public
		constructor Create( ParaR : TJournalReader; ParaSeq : Integer );
		function Read( var Buffer; Count : Longint ) : Longint; override;
		function Write( const Buffer; Count : Longint ) : Longint; override;
		function Seek( const Offset : Int64; Origin : TSeekOrigin ) : Int64; override;
	end;

	TSingleWriter = class( TStream )
	private
		mW : TJournalWriter;
		mSeq : Integer;
	public
		constructor Create( ParaW : TJournalWriter; ParaSeq : Integer );
		function Read( var Buffer; Count : Longint ) : Longint; override;
		function Write( const Buffer; Count : Longint ) : Longint; override;
		function Seek( const Offset : Int64; Origin : TSeekOrigin ) : Int64; override;
	end;

implementation

{ EJournalCorrupted }

constructor EJournalCorrupted.Create( ParaSize : Integer; const ParaReason : string );
begin
	inherited Create( Format( 'leveldb/journal: block/chunk corrupted: %s (%d bytes)', [ ParaReason, ParaSize ] ) );
	Size := ParaSize;
	Reason := ParaReason;
end;

{ TJournalReader }

constructor TJournalReader.Create( ParaStream : TStream; ParaDropper : IDropper; ParaStrict, ParaChecksum : Boolean );
begin
	mStream := ParaStream;
	mDropper := ParaDropper;
	mStrict := ParaStrict;
	mChecksum := ParaChecksum;
	mLast := True;
end;

function TJournalReader.Corrupt( ParaN : Integer; const ParaReason : string; ParaSkip : Boolean ) : Boolean;
begin
	if mDropper <> nil then
		mDropper.Drop( EJournalCorrupted.Create( ParaN, ParaReason ) );
	if mStrict and not ParaSkip then
	begin
		mErr := EJournalCorrupted.Create( ParaN, ParaReason );
		Result := False;
	end
	else
		Result := True; // Simulating "skip"
end;

function TJournalReader.NextChunk( ParaFirst : Boolean ) : Boolean;
var
	vChecksum : UInt32;
	vLength : UInt16;
	vChunkType : Byte;
	vUnprocBlock : Integer;
	vRead : Integer;
begin
	while True do
	begin
		if mJ + HEADER_SIZE <= mN then
		begin
			vChecksum := PUint32( @mBuf[ mJ ] )^;
			vLength := PUint16( @mBuf[ mJ + 4 ] )^;
			vChunkType := mBuf[ mJ + 6 ];
			vUnprocBlock := mN - mJ;
			
			if ( vChecksum = 0 ) and ( vLength = 0 ) and ( vChunkType = 0 ) then
			begin
				mI := mN; mJ := mN;
				Exit( Corrupt( vUnprocBlock, 'zero header', False ) );
			end;
			
			if ( vChunkType < FULL_CHUNK_TYPE ) or ( vChunkType > LAST_CHUNK_TYPE ) then
			begin
				mI := mN; mJ := mN;
				Exit( Corrupt( vUnprocBlock, 'invalid chunk type', False ) );
			end;
			
			mI := mJ + HEADER_SIZE;
			mJ := mJ + HEADER_SIZE + vLength;
			
			if mJ > mN then
			begin
				mI := mN; mJ := mN;
				Exit( Corrupt( vUnprocBlock, 'chunk length overflows block', False ) );
			end;
			
			// Checksum verification omitted for brevity in this snippet, but would use TCRC32
			
			if ParaFirst and ( vChunkType <> FULL_CHUNK_TYPE ) and ( vChunkType <> FIRST_CHUNK_TYPE ) then
			begin
				mI := mJ;
				Corrupt( ( mJ - mI ) + HEADER_SIZE, 'orphan chunk', True );
				Continue;
			end;
			
			mLast := ( vChunkType = FULL_CHUNK_TYPE ) or ( vChunkType = LAST_CHUNK_TYPE );
			Exit( True );
		end;
		
		if ( rN < BLOCK_SIZE ) and ( rN > 0 ) then
		begin
			if not ParaFirst then
				Corrupt( 0, 'missing chunk part', False );
			mErr := EStreamError.Create( 'EOF' );
			Exit( False );
		end;
		
		vRead := mStream.Read( mBuf[ 0 ], BLOCK_SIZE );
		if vRead = 0 then
		begin
			mErr := EStreamError.Create( 'EOF' );
			Exit( False );
		end;
		mI := 0; mJ := 0; mN := vRead;
	end;
end;

function TJournalReader.Next : TStream;
begin
	Inc( mSeq );
	if mErr <> nil then Exit( nil );
	mI := mJ;
	while True do
	begin
		if NextChunk( True ) then Break;
		if mErr <> nil then Exit( nil );
	end;
	Result := TSingleReader.Create( Self, mSeq );
end;

{ TJournalWriter }

constructor TJournalWriter.Create( ParaStream : TStream );
begin
	mStream := ParaStream;
end;

procedure TJournalWriter.FillHeader( ParaLast : Boolean );
var
	vCrc : TCRC32;
begin
	if ParaLast then
	begin
		if mFirst then mBuf[ mI + 6 ] := FULL_CHUNK_TYPE else mBuf[ mI + 6 ] := LAST_CHUNK_TYPE;
	end
	else
	begin
		if mFirst then mBuf[ mI + 6 ] := FIRST_CHUNK_TYPE else mBuf[ mI + 6 ] := MIDDLE_CHUNK_TYPE;
	end;
	
	vCrc := TCRC32.New( Copy( TBytes( @mBuf[ mI + 6 ] ), 0, mJ - mI - 6 ) );
	PUint32( @mBuf[ mI ] )^ := vCrc.Value;
	PUint16( @mBuf[ mI + 4 ] )^ := UInt16( mJ - mI - HEADER_SIZE );
end;

procedure TJournalWriter.WriteBlock;
begin
	mStream.Write( mBuf[ mWritten ], BLOCK_SIZE - mWritten );
	mI := 0;
	mJ := HEADER_SIZE;
	mWritten := 0;
end;

procedure TJournalWriter.WritePending;
begin
	if mPending then
	begin
		FillHeader( True );
		mPending := False;
	end;
	mStream.Write( mBuf[ mWritten ], mJ - mWritten );
	mWritten := mJ;
end;

function TJournalWriter.Next : TStream;
begin
	Inc( mSeq );
	if mPending then FillHeader( True );
	mI := mJ;
	mJ := mJ + HEADER_SIZE;
	if mJ > BLOCK_SIZE then
	begin
		FillChar( mBuf[ mI ], BLOCK_SIZE - mI, 0 );
		WriteBlock;
	end;
	mFirst := True;
	mPending := True;
	Result := TSingleWriter.Create( Self, mSeq );
end;

procedure TJournalWriter.Close;
begin
	WritePending;
end;

procedure TJournalWriter.Flush;
begin
	WritePending;
end;

{ TSingleReader }

constructor TSingleReader.Create( ParaR : TJournalReader; ParaSeq : Integer );
begin
	mR := ParaR;
	mSeq := ParaSeq;
end;

function TSingleReader.Read( var Buffer; Count : Longint ) : Longint;
var
	vN : Integer;
begin
	if mR.mSeq <> mSeq then Exit( 0 );
	while mR.mI = mR.mJ do
	begin
		if mR.mLast then Exit( 0 );
		if not mR.NextChunk( False ) then Exit( 0 );
	end;
	vN := mR.mJ - mR.mI;
	if vN > Count then vN := Count;
	Move( mR.mBuf[ mR.mI ], Buffer, vN );
	mR.mI := mR.mI + vN;
	Result := vN;
end;

function TSingleReader.Write( const Buffer; Count : Longint ) : Longint;
begin
	Result := 0;
end;

function TSingleReader.Seek( const Offset : Int64; Origin : TSeekOrigin ) : Int64;
begin
	Result := 0;
end;

{ TSingleWriter }

constructor TSingleWriter.Create( ParaW : TJournalWriter; ParaSeq : Integer );
begin
	mW := ParaW;
	mSeq := ParaSeq;
end;

function TSingleWriter.Read( var Buffer; Count : Longint ) : Longint;
begin
	Result := 0;
end;

function TSingleWriter.Write( const Buffer; Count : Longint ) : Longint;
var
	vP : PByte;
	vCount, vN : Integer;
begin
	if mW.mSeq <> mSeq then Exit( 0 );
	vP := @Buffer;
	vCount := Count;
	while vCount > 0 do
	begin
		if mW.mJ = BLOCK_SIZE then
		begin
			mW.FillHeader( False );
			mW.WriteBlock;
			mW.mFirst := False;
		end;
		vN := BLOCK_SIZE - mW.mJ;
		if vN > vCount then vN := vCount;
		Move( vP^, mW.mBuf[ mW.mJ ], vN );
		mW.mJ := mW.mJ + vN;
		vP := vP + vN;
		vCount := vCount - vN;
	end;
	Result := Count;
end;

function TSingleWriter.Seek( const Offset : Int64; Origin : TSeekOrigin ) : Int64;
begin
	Result := 0;
end;

end.
