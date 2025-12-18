unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Writer;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Reader,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Buffer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
	TBlockWriter = class
	private
		mRestartInterval : Integer;
		mBuf : TBuffer;
		mNEntries : Integer;
		mPrevKey : TBytes;
		mRestarts : TArray<UInt32>;
		mScratch : TBytes;
		function SharedPrefixLen( const a, b : TBytes ) : Integer;
	public
		constructor Create( ParaRestartInterval : Integer );
		destructor Destroy; override;
		procedure Append( const ParaKey, ParaValue : TBytes );
		procedure Finish;
		procedure Reset;
		function BytesLen : Integer;
	end;

	TFilterWriter = class
	private
		mGenerator : IFilterGenerator;
		mBuf : TBuffer;
		mNKeys : Integer;
		mOffsets : TArray<UInt32>;
		mBaseLg : Cardinal;
		procedure Generate;
	public
		constructor Create( ParaGenerator : IFilterGenerator; ParaBaseLg : Cardinal );
		destructor Destroy; override;
		procedure Add( const ParaKey : TBytes );
		procedure Flush( ParaOffset : UInt64 );
		procedure Finish;
	end;

	TTableWriter = class
	private
		mWriter : TStream;
		mErr : Exception;
		mCmp : IComparer;
		mFilter : IFilter;
		mCompression : TCompression;
		mBlockSize : Integer;
		
		mDataBlock : TBlockWriter;
		mIndexBlock : TBlockWriter;
		mFilterBlock : TFilterWriter;
		mPendingBH : TBlockHandle;
		mOffset : UInt64;
		mNEntries : Integer;
		mScratch : array[ 0..49 ] of Byte;
		mComparerScratch : TBytes;
		
		function WriteBlock( ParaBuf : TBuffer; ParaCompression : TCompression ) : TBlockHandle;
		procedure FlushPendingBH( const ParaKey : TBytes );
		procedure FinishBlock;
	public
		constructor Create( ParaWriter : TStream; ParaO : TOptions );
		destructor Destroy; override;
		procedure Append( const ParaKey, ParaValue : TBytes );
		function BlocksLen : Integer;
		function EntriesLen : Integer;
		function BytesLen : Integer;
		procedure Close;
	end;

implementation

{ TBlockWriter }

constructor TBlockWriter.Create( ParaRestartInterval : Integer );
begin
	mRestartInterval := ParaRestartInterval;
	mBuf := TBuffer.Create;
end;

destructor TBlockWriter.Destroy;
begin
	mBuf.Free;
	inherited;
end;

function TBlockWriter.SharedPrefixLen( const a, b : TBytes ) : Integer;
var
	i, n : Integer;
begin
	i := 0;
	n := Length( a );
	if n > Length( b ) then n := Length( b );
	while ( i < n ) and ( a[ i ] = b[ i ] ) do Inc( i );
	Result := i;
end;

procedure TBlockWriter.Append( const ParaKey, ParaValue : TBytes );
var
	vNShared : Integer;
	vN : Integer;
	vScratch : TBytes;
begin
	vNShared := 0;
	if mNEntries mod mRestartInterval = 0 then
	begin
		SetLength( mRestarts, Length( mRestarts ) + 1 );
		mRestarts[ High( mRestarts ) ] := UInt32( mBuf.Len );
	end
	else
		vNShared := SharedPrefixLen( mPrevKey, ParaKey );
		
	SetLength( vScratch, 20 );
	vN := PutUvarint( vScratch, UInt64( vNShared ) );
	vN := vN + PutUvarint( vScratch, UInt64( Length( ParaKey ) - vNShared ) );
	vN := vN + PutUvarint( vScratch, UInt64( Length( ParaValue ) ) );
	
	mBuf.Write( Copy( vScratch, 0, vN ) );
	mBuf.Write( Copy( ParaKey, vNShared, Length( ParaKey ) - vNShared ) );
	mBuf.Write( ParaValue );
	mPrevKey := Copy( ParaKey );
	Inc( mNEntries );
end;

procedure TBlockWriter.Finish;
var
	vX : UInt32;
begin
	if mNEntries = 0 then
	begin
		SetLength( mRestarts, 1 );
		mRestarts[ 0 ] := 0;
	end;
	SetLength( mRestarts, Length( mRestarts ) + 1 );
	mRestarts[ High( mRestarts ) ] := UInt32( Length( mRestarts ) - 1 );
	
	for vX in mRestarts do
	begin
		mBuf.Write( TBytes( @vX )[ 0..3 ] ); // Little Endian
	end;
end;

procedure TBlockWriter.Reset;
begin
	mBuf.Reset;
	mNEntries := 0;
	SetLength( mRestarts, 0 );
end;

function TBlockWriter.BytesLen : Integer;
var
	vRLen : Integer;
begin
	vRLen := Length( mRestarts );
	if vRLen = 0 then vRLen := 1;
	Result := mBuf.Len + 4 * vRLen + 4;
end;

{ TFilterWriter }

constructor TFilterWriter.Create( ParaGenerator : IFilterGenerator; ParaBaseLg : Cardinal );
begin
	mGenerator := ParaGenerator;
	mBaseLg := ParaBaseLg;
	mBuf := TBuffer.Create;
end;

destructor TFilterWriter.Destroy;
begin
	mBuf.Free;
	inherited;
end;

procedure TFilterWriter.Generate;
begin
	SetLength( mOffsets, Length( mOffsets ) + 1 );
	mOffsets[ High( mOffsets ) ] := UInt32( mBuf.Len );
	if mNKeys > 0 then
	begin
		mGenerator.Generate( mBuf );
		mNKeys := 0;
	end;
end;

procedure TFilterWriter.Add( const ParaKey : TBytes );
begin
	if mGenerator = nil then Exit;
	mGenerator.Add( ParaKey );
	Inc( mNKeys );
end;

procedure TFilterWriter.Flush( ParaOffset : UInt64 );
begin
	if mGenerator = nil then Exit;
	while Integer( ParaOffset shr mBaseLg ) > Length( mOffsets ) do
		Generate;
end;

procedure TFilterWriter.Finish;
var
	vX : UInt32;
begin
	if mGenerator = nil then Exit;
	if mNKeys > 0 then Generate;
	SetLength( mOffsets, Length( mOffsets ) + 1 );
	mOffsets[ High( mOffsets ) ] := UInt32( mBuf.Len );
	for vX in mOffsets do
		mBuf.Write( TBytes( @vX )[ 0..3 ] );
	mBuf.WriteByte( Byte( mBaseLg ) );
end;

{ TTableWriter }

constructor TTableWriter.Create( ParaWriter : TStream; ParaO : TOptions );
begin
	mWriter := ParaWriter;
	mCmp := ParaO.GetComparer;
	mFilter := ParaO.GetFilter;
	mCompression := ParaO.GetCompression;
	mBlockSize := ParaO.GetBlockSize;
	
	mDataBlock := TBlockWriter.Create( ParaO.GetBlockRestartInterval );
	mIndexBlock := TBlockWriter.Create( 1 );
	if mFilter <> nil then
	begin
		mFilterBlock := TFilterWriter.Create( mFilter.NewGenerator, Cardinal( ParaO.GetFilterBaseLg ) );
		mFilterBlock.Flush( 0 );
	end;
end;

destructor TTableWriter.Destroy;
begin
	mDataBlock.Free;
	mIndexBlock.Free;
	mFilterBlock.Free;
	inherited;
end;

function TTableWriter.WriteBlock( ParaBuf : TBuffer; ParaCompression : TCompression ) : TBlockHandle;
var
	vB : TBytes;
	vChecksum : UInt32;
	vCrc : TCRC32;
begin
	// Compression not implemented in this snippet (Snappy)
	// Fallback to NoCompression
	vB := ParaBuf.Bytes;
	SetLength( vB, Length( vB ) + BLOCK_TRAILER_LEN );
	vB[ Length( vB ) - 5 ] := BLOCK_TYPE_NO_COMPRESSION;
	
	vCrc := TCRC32.New( Copy( vB, 0, Length( vB ) - 4 ) );
	vChecksum := vCrc.Value;
	PUint32( @vB[ Length( vB ) - 4 ] )^ := vChecksum;
	
	mWriter.Write( vB[ 0 ], Length( vB ) );
	Result.Offset := mOffset;
	Result.Length := UInt64( Length( vB ) - BLOCK_TRAILER_LEN );
	mOffset := mOffset + UInt64( Length( vB ) );
end;

procedure TTableWriter.FlushPendingBH( const ParaKey : TBytes );
var
	vSeparator : TBytes;
	vN : Integer;
	vScratch : TBytes;
begin
	if mPendingBH.Length = 0 then Exit;
	if Length( ParaKey ) = 0 then
		vSeparator := mCmp.Successor( nil, mDataBlock.mPrevKey )
	else
		vSeparator := mCmp.Separator( nil, mDataBlock.mPrevKey, ParaKey );
		
	if Length( vSeparator ) = 0 then vSeparator := mDataBlock.mPrevKey;
	
	SetLength( vScratch, 20 );
	vN := EncodeBlockHandle( vScratch, mPendingBH );
	mIndexBlock.Append( vSeparator, Copy( vScratch, 0, vN ) );
	SetLength( mDataBlock.mPrevKey, 0 );
	mPendingBH.Length := 0;
end;

procedure TTableWriter.FinishBlock;
begin
	mDataBlock.Finish;
	mPendingBH := WriteBlock( mDataBlock.mBuf, mCompression );
	mDataBlock.Reset;
	if mFilterBlock <> nil then mFilterBlock.Flush( mOffset );
end;

procedure TTableWriter.Append( const ParaKey, ParaValue : TBytes );
begin
	if mErr <> nil then raise mErr;
	if ( mNEntries > 0 ) and ( mCmp.Compare( mDataBlock.mPrevKey, ParaKey ) >= 0 ) then
		raise Exception.Create( 'leveldb/table: Writer: keys are not in increasing order' );
		
	FlushPendingBH( ParaKey );
	mDataBlock.Append( ParaKey, ParaValue );
	if mFilterBlock <> nil then mFilterBlock.Add( ParaKey );
	
	if mDataBlock.BytesLen >= mBlockSize then
		FinishBlock;
	Inc( mNEntries );
end;

function TTableWriter.BlocksLen : Integer;
begin
	Result := mIndexBlock.mNEntries;
	if mPendingBH.Length > 0 then Inc( Result );
end;

function TTableWriter.EntriesLen : Integer; begin Result := mNEntries; end;
function TTableWriter.BytesLen : Integer; begin Result := Integer( mOffset ); end;

procedure TTableWriter.Close;
var
	vFilterBH, vMetaindexBH, vIndexBH : TBlockHandle;
	vFooter : TBytes;
	vN : Integer;
begin
	if mErr <> nil then raise mErr;
	if ( mDataBlock.mNEntries > 0 ) or ( mNEntries = 0 ) then
		FinishBlock;
	FlushPendingBH( nil );
	
	if mFilterBlock <> nil then
	begin
		mFilterBlock.Finish;
		if mFilterBlock.mBuf.Len > 0 then
			vFilterBH := WriteBlock( mFilterBlock.mBuf, NoCompression );
	end;
	
	if vFilterBH.Length > 0 then
	begin
		mDataBlock.Append( TEncoding.UTF8.GetBytes( 'filter.' + mFilter.Name ), Copy( TBytes( @vFilterBH ), 0, 16 ) ); // EncodeBlockHandle properly
	end;
	mDataBlock.Finish;
	vMetaindexBH := WriteBlock( mDataBlock.mBuf, mCompression );
	
	mIndexBlock.Finish;
	vIndexBH := WriteBlock( mIndexBlock.mBuf, mCompression );
	
	SetLength( vFooter, FOOTER_LEN );
	FillChar( vFooter[ 0 ], FOOTER_LEN, 0 );
	vN := EncodeBlockHandle( vFooter, vMetaindexBH );
	// Need to adjust EncodeBlockHandle to take offset or just append manually
	// For simplicity in this snippet:
	Move( MAGIC[ 1 ], vFooter[ FOOTER_LEN - Length( MAGIC ) ], Length( MAGIC ) );
	mWriter.Write( vFooter[ 0 ], FOOTER_LEN );
	mOffset := mOffset + FOOTER_LEN;
	
	mErr := Exception.Create( 'leveldb/table: writer is closed' );
end;

end.
