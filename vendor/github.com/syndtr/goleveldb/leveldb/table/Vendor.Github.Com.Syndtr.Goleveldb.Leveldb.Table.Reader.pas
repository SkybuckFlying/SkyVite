unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Reader;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Cache,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.IndexedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Writer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Buffer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
	TTableReader = class;

	TBlock = class( TBasicReleaser )
	public
		BH : TBlockHandle;
		Data : TBytes;
		RestartsLen : Integer;
		RestartsOffset : Integer;
		constructor Create( const ParaBH : TBlockHandle; const ParaData : TBytes );
		function Seek( const ParaCmp : IComparer; ParaKey : TBytes ) : Integer;
		function RestartOffset( ParaIndex : Integer ) : Integer;
		function Entry( ParaOffset : Integer; out ParaKey, ParaValue : TBytes; out ParaNShared, ParaN : Integer ) : Exception;
	end;

	TBlockIter = class( TBasicReleaser, IIteratorSeeker, ICommonIterator, IIterator )
	private
		mTR : TTableReader;
		mBlock : TBlock;
		mBlockReleaser : IReleaser;
		mKey, mValue : TBytes;
		mOffset : Integer;
		mPrevOffset : Integer;
		mRestartIndex : Integer;
		mRiStart, mRiLimit : Integer;
		mOffsetStart, mOffsetRealStart, mOffsetLimit : Integer;
		mErr : Exception;
		procedure SErr( ParaErr : Exception );
	public
		constructor Create( ParaTR : TTableReader; ParaBlock : TBlock; const ParaBlockReleaser : IReleaser );
		destructor Destroy; override;
		function Valid : Boolean; virtual;
		function First : Boolean; virtual;
		function Last : Boolean; virtual;
		function Seek( const ParaKey : TBytes ) : Boolean; virtual;
		function Next : Boolean; virtual;
		function Prev : Boolean; virtual;
		function Key : TBytes; virtual;
		function Value : TBytes; virtual;
		function Error : Exception; virtual;
		procedure Release; override;
	end;

	TFilterBlock = class( TBasicReleaser )
	public
		Data : TBytes;
		OOffset : Integer;
		BaseLg : Cardinal;
		FiltersNum : Integer;
		constructor Create( const ParaData : TBytes; ParaOOffset : Integer; ParaBaseLg : Cardinal );
		function Contains( const ParaFilter : IFilter; ParaOffset : UInt64; const ParaKey : TBytes ) : Boolean;
	end;

	TIndexIter = class( TInterfacedObject, IIteratorIndexer, IIteratorSeeker, ICommonIterator )
	private
		mBlockIter : TBlockIter;
		mTR : TTableReader;
		mFillCache : Boolean;
	public
		constructor Create( ParaBI : TBlockIter; ParaTR : TTableReader; ParaFillCache : Boolean );
		destructor Destroy; override;
		function First : Boolean;
		function Last : Boolean;
		function Seek( const ParaKey : TBytes ) : Boolean;
		function Next : Boolean;
		function Prev : Boolean;
		procedure Release;
		procedure SetReleaser( const ParaReleaser : IReleaser );
		function Valid : Boolean;
		function Error : Exception;
		function Get : IIterator;
	end;

	TTableReader = class( TBasicReleaser )
	private
		mMu : TCriticalSection;
		mFd : TFileDesc;
		mReader : TStream;
		mCache : TCache;
		mErr : Exception;
		mO : TOptions;
		mCmp : IComparer;
		mFilter : IFilter;
		mVerifyChecksum : Boolean;
		mDataEnd : Int64;
		mMetaBH, mIndexBH, mFilterBH : TBlockHandle;
		mIndexBlock : TBlock;
		mFilterBlock : TFilterBlock;
		
		function ReadRawBlock( const ParaBH : TBlockHandle; ParaVerifyChecksum : Boolean ) : TBytes;
		function ReadBlock( const ParaBH : TBlockHandle; ParaVerifyChecksum : Boolean ) : TBlock;
		function ReadBlockCached( const ParaBH : TBlockHandle; ParaVerifyChecksum, ParaFillCache : Boolean; out ParaRel : IReleaser ) : TBlock;
		function NewBlockIter( ParaB : TBlock; const ParaBReleaser : IReleaser ) : TBlockIter;
	public
		constructor Create( ParaF : TStream; ParaSize : Int64; const ParaFd : TFileDesc; ParaCache : TCache; ParaO : TOptions );
		destructor Destroy; override;
		function NewIterator( ParaRO : TReadOptions ) : IIterator;
		procedure Release; override;
	end;

implementation

{ TBlock }

constructor TBlock.Create( const ParaBH : TBlockHandle; const ParaData : TBytes );
begin
	BH := ParaBH;
	Data := ParaData;
	RestartsLen := Integer( PUint32( @Data[ Length( Data ) - 4 ] )^ );
	RestartsOffset := Length( Data ) - ( RestartsLen + 1 ) * 4;
end;

function TBlock.RestartOffset( ParaIndex : Integer ) : Integer;
begin
	Result := Integer( PUint32( @Data[ RestartsOffset + 4 * ParaIndex ] )^ );
end;

function TBlock.Seek( const ParaCmp : IComparer; ParaKey : TBytes ) : Integer;
var
	vLow, vHigh, vMid : Integer;
	vOffset : Integer;
	vN1, vN2 : Integer;
	vV1 : UInt64;
	vM : Integer;
begin
	vLow := 0;
	vHigh := RestartsLen - 1;
	while vLow <= vHigh do
	begin
		vMid := ( vLow + vHigh ) div 2;
		vOffset := RestartOffset( vMid );
		vOffset := vOffset + 1; // skip shared
		vN1 := Uvarint( Copy( Data, vOffset, Length( Data ) - vOffset ), vV1 );
		Uvarint( Copy( Data, vOffset + vN1, Length( Data ) - ( vOffset + vN1 ) ), UInt64( vN2 ) ); // value len placeholder
		vM := vOffset + vN1 + vN2;
		if ParaCmp.Compare( Copy( Data, vM, Integer( vV1 ) ), ParaKey ) <= 0 then
			vLow := vMid + 1
		else
			vHigh := vMid - 1;
	end;
	Result := vHigh;
	if Result < 0 then Result := 0;
end;

function TBlock.Entry( ParaOffset : Integer; out ParaKey, ParaValue : TBytes; out ParaNShared, ParaN : Integer ) : Exception;
var
	vV0, vV1, vV2 : UInt64;
	vN0, vN1, vN2 : Integer;
	vM : Integer;
begin
	Result := nil;
	if ParaOffset >= RestartsOffset then
	begin
		ParaN := 0;
		Exit;
	end;
	vN0 := Uvarint( Copy( Data, ParaOffset, Length( Data ) - ParaOffset ), vV0 );
	vN1 := Uvarint( Copy( Data, ParaOffset + vN0, Length( Data ) - ( ParaOffset + vN0 ) ), vV1 );
	vN2 := Uvarint( Copy( Data, ParaOffset + vN0 + vN1, Length( Data ) - ( ParaOffset + vN0 + vN1 ) ), vV2 );
	vM := vN0 + vN1 + vN2;
	ParaN := vM + Integer( vV1 ) + Integer( vV2 );
	ParaKey := Copy( Data, ParaOffset + vM, Integer( vV1 ) );
	ParaValue := Copy( Data, ParaOffset + vM + Integer( vV1 ), Integer( vV2 ) );
	ParaNShared := Integer( vV0 );
end;

{ TBlockIter }

constructor TBlockIter.Create( ParaTR : TTableReader; ParaBlock : TBlock; const ParaBlockReleaser : IReleaser );
begin
	inherited Create;
	mTR := ParaTR;
	mBlock := ParaBlock;
	mBlockReleaser := ParaBlockReleaser;
	mRiLimit := mBlock.RestartsLen;
	mOffsetLimit := mBlock.RestartsOffset;
end;

destructor TBlockIter.Destroy;
begin
	Release;
	inherited;
end;

procedure TBlockIter.SErr( ParaErr : Exception );
begin
	mErr := ParaErr;
	mKey := nil;
	mValue := nil;
end;

function TBlockIter.Valid : Boolean;
begin
	Result := ( mErr = nil ) and ( mKey <> nil );
end;

function TBlockIter.First : Boolean;
begin
	mRestartIndex := 0;
	mOffset := 0;
	Result := Next;
end;

function TBlockIter.Last : Boolean;
begin
	mRestartIndex := mRiLimit - 1;
	mOffset := mBlock.RestartOffset( mRestartIndex );
	while Next do ; // simplified
	Result := Valid;
end;

function TBlockIter.Seek( const ParaKey : TBytes ) : Boolean;
begin
	mRestartIndex := mBlock.Seek( mTR.mCmp, ParaKey );
	mOffset := mBlock.RestartOffset( mRestartIndex );
	while Next do
	begin
		if mTR.mCmp.Compare( mKey, ParaKey ) >= 0 then Exit( True );
	end;
	Result := False;
end;

function TBlockIter.Next : Boolean;
var
	vKey, vValue : TBytes;
	vNShared, vN : Integer;
begin
	if mOffset >= mOffsetLimit then Exit( False );
	mErr := mBlock.Entry( mOffset, vKey, vValue, vNShared, vN );
	if mErr <> nil then Exit( False );
	if vN = 0 then Exit( False );
	
	SetLength( mKey, vNShared + Length( vKey ) );
	if vNShared > 0 then Move( mKey[ 0 ], mKey[ 0 ], vNShared ); // key persists in mKey
	Move( vKey[ 0 ], mKey[ vNShared ], Length( vKey ) );
	
	mValue := vValue;
	mPrevOffset := mOffset;
	mOffset := mOffset + vN;
	Result := True;
end;

function TBlockIter.Prev : Boolean;
begin
	// Simplified: restart from beginning of restart point if needed
	Result := False; // Placeholder for complexity
end;

function TBlockIter.Key : TBytes; begin Result := mKey; end;
function TBlockIter.Value : TBytes; begin Result := mValue; end;
function TBlockIter.Error : Exception; begin Result := mErr; end;

procedure TBlockIter.Release;
begin
	if mBlockReleaser <> nil then
	begin
		mBlockReleaser.Release;
		mBlockReleaser := nil;
	end;
	inherited Release;
end;

{ TFilterBlock }

constructor TFilterBlock.Create( const ParaData : TBytes; ParaOOffset : Integer; ParaBaseLg : Cardinal );
begin
	Data := ParaData;
	OOffset := ParaOOffset;
	BaseLg := ParaBaseLg;
	FiltersNum := ( OOffset - ( Length( Data ) - 5 ) ) div 4; // adjustment needed
end;

function TFilterBlock.Contains( const ParaFilter : IFilter; ParaOffset : UInt64; const ParaKey : TBytes ) : Boolean;
begin
	Result := True; // Placeholder
end;

{ TIndexIter }

constructor TIndexIter.Create( ParaBI : TBlockIter; ParaTR : TTableReader; ParaFillCache : Boolean );
begin
	mBlockIter := ParaBI;
	mTR := ParaTR;
	mFillCache := ParaFillCache;
end;

destructor TIndexIter.Destroy;
begin
	mBlockIter.Free;
	inherited;
end;

function TIndexIter.First : Boolean; begin Result := mBlockIter.First; end;
function TIndexIter.Last : Boolean; begin Result := mBlockIter.Last; end;
function TIndexIter.Seek( const ParaKey : TBytes ) : Boolean; begin Result := mBlockIter.Seek( ParaKey ); end;
function TIndexIter.Next : Boolean; begin Result := mBlockIter.Next; end;
function TIndexIter.Prev : Boolean; begin Result := mBlockIter.Prev; end;
procedure TIndexIter.Release; begin mBlockIter.Release; end;
procedure TIndexIter.SetReleaser( const ParaReleaser : IReleaser ); begin mBlockIter.SetReleaser( ParaReleaser ); end;
function TIndexIter.Valid : Boolean; begin Result := mBlockIter.Valid; end;
function TIndexIter.Error : Exception; begin Result := mBlockIter.Error; end;

function TIndexIter.Get : IIterator;
var
	vDataBH : TBlockHandle;
begin
	if not Valid then Exit( nil );
	DecodeBlockHandle( mBlockIter.Value, vDataBH );
	Result := mTR.NewBlockIter( mTR.ReadBlockCached( vDataBH, True, mFillCache, IReleaser( nil^ ) ), nil ); // Releaser handling needed
end;

{ TTableReader }

constructor TTableReader.Create( ParaF : TStream; ParaSize : Int64; const ParaFd : TFileDesc; ParaCache : TCache; ParaO : TOptions );
var
	vFooter : array[ 0..FOOTER_LEN - 1 ] of Byte;
	vN : Integer;
begin
	mMu := TCriticalSection.Create;
	mFd := ParaFd;
	mReader := ParaF;
	mCache := ParaCache;
	mO := ParaO;
	mCmp := mO.GetComparer;
	mVerifyChecksum := mO.GetStrict( StrictBlockChecksum );
	
	mReader.Position := ParaSize - FOOTER_LEN;
	mReader.Read( vFooter[ 0 ], FOOTER_LEN );
	
	vN := DecodeBlockHandle( TBytes( @vFooter ), mMetaBH );
	DecodeBlockHandle( Copy( TBytes( @vFooter ), vN, FOOTER_LEN - vN ), mIndexBH );
end;

destructor TTableReader.Destroy;
begin
	Release;
	mMu.Free;
	inherited;
end;

function TTableReader.ReadRawBlock( const ParaBH : TBlockHandle; ParaVerifyChecksum : Boolean ) : TBytes;
begin
	SetLength( Result, Integer( ParaBH.Length ) );
	mReader.Position := Int64( ParaBH.Offset );
	mReader.Read( Result[ 0 ], Integer( ParaBH.Length ) );
end;

function TTableReader.ReadBlock( const ParaBH : TBlockHandle; ParaVerifyChecksum : Boolean ) : TBlock;
begin
	Result := TBlock.Create( ParaBH, ReadRawBlock( ParaBH, ParaVerifyChecksum ) );
end;

function TTableReader.ReadBlockCached( const ParaBH : TBlockHandle; ParaVerifyChecksum, ParaFillCache : Boolean; out ParaRel : IReleaser ) : TBlock;
begin
	Result := ReadBlock( ParaBH, ParaVerifyChecksum ); // No cache integration in this snippet
	ParaRel := nil;
end;

function TTableReader.NewBlockIter( ParaB : TBlock; const ParaBReleaser : IReleaser ) : TBlockIter;
begin
	Result := TBlockIter.Create( Self, ParaB, ParaBReleaser );
end;

function TTableReader.NewIterator( ParaRO : TReadOptions ) : IIterator;
var
	vIndexBlock : TBlock;
	vRel : IReleaser;
	vIndex : TIndexIter;
begin
	vIndexBlock := ReadBlockCached( mIndexBH, True, not ParaRO.DontFillCache, vRel );
	vIndex := TIndexIter.Create( NewBlockIter( vIndexBlock, vRel ), Self, not ParaRO.DontFillCache );
	Result := NewIndexedIterator( vIndex, GetStrict( mO, ParaRO, StrictReader ) );
end;

procedure TTableReader.Release;
begin
	inherited Release;
end;

end.
