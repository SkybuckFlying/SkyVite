unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.IndexedIter;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors;

type
	IIteratorIndexer = interface( ICommonIterator )
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F76}']
		function Get : IIterator;
	end;

	TIndexedIterator = class( TBasicReleaser, IIteratorSeeker, ICommonIterator, IIterator, IErrorCallbackSetter )
	private
		mIndex : IIteratorIndexer;
		mStrict : Boolean;
		mData : IIterator;
		mErr : Exception;
		mErrf : TProc<Exception>;
		
		procedure SetData;
		procedure ClearData;
		procedure IndexErr;
		function DataErr : Boolean;
	public
		constructor Create( const ParaIndex : IIteratorIndexer; ParaStrict : Boolean );
		destructor Destroy; override;
		
		function Valid : Boolean; virtual;
		function First : Boolean; virtual;
		function Last : Boolean; virtual;
		function Seek( const ParaKey : TBytes ) : Boolean; virtual;
		function Next : Boolean; virtual;
		function Prev : Boolean; virtual;
		function Key : TBytes; virtual;
		function Value : TBytes; virtual;
		procedure Release; override;
		function Error : Exception; virtual;
		procedure SetErrorCallback( const ParaF : TProc<Exception> ); virtual;
	end;

function NewIndexedIterator( const ParaIndex : IIteratorIndexer; ParaStrict : Boolean ) : IIterator;

implementation

function NewIndexedIterator( const ParaIndex : IIteratorIndexer; ParaStrict : Boolean ) : IIterator;
begin
	Result := TIndexedIterator.Create( ParaIndex, ParaStrict );
end;

{ TIndexedIterator }

constructor TIndexedIterator.Create( const ParaIndex : IIteratorIndexer; ParaStrict : Boolean );
begin
	inherited Create;
	mIndex := ParaIndex;
	mStrict := ParaStrict;
end;

destructor TIndexedIterator.Destroy;
begin
	ClearData;
	inherited;
end;

procedure TIndexedIterator.SetData;
begin
	ClearData;
	mData := mIndex.Get;
end;

procedure TIndexedIterator.ClearData;
begin
	if mData <> nil then
	begin
		mData.Release;
		mData := nil;
	end;
end;

procedure TIndexedIterator.IndexErr;
var
	vErr : Exception;
begin
	vErr := mIndex.Error;
	if vErr <> nil then
	begin
		if Assigned( mErrf ) then mErrf( vErr );
		mErr := vErr;
	end;
end;

function TIndexedIterator.DataErr : Boolean;
var
	vErr : Exception;
begin
	vErr := mData.Error;
	if vErr <> nil then
	begin
		if Assigned( mErrf ) then mErrf( vErr );
		if mStrict or ( not ( vErr is ECorrupted ) ) then
		begin
			mErr := vErr;
			Exit( True );
		end;
	end;
	Result := False;
end;

function TIndexedIterator.Valid : Boolean;
begin
	Result := ( mData <> nil ) and mData.Valid;
end;

function TIndexedIterator.First : Boolean;
begin
	if mErr <> nil then Exit( False );
	if Released then begin mErr := Exception.Create( 'leveldb/table: iterator released' ); Exit( False ); end;
	
	if not mIndex.First then
	begin
		IndexErr;
		ClearData;
		Exit( False );
	end;
	SetData;
	Result := Next;
end;

function TIndexedIterator.Last : Boolean;
begin
	if mErr <> nil then Exit( False );
	if Released then begin mErr := Exception.Create( 'leveldb/table: iterator released' ); Exit( False ); end;
	
	if not mIndex.Last then
	begin
		IndexErr;
		ClearData;
		Exit( False );
	end;
	SetData;
	if not mData.Last then
	begin
		if DataErr() then Exit( False );
		ClearData;
		Exit( Prev );
	end;
	Result := True;
end;

function TIndexedIterator.Seek( const ParaKey : TBytes ) : Boolean;
begin
	if mErr <> nil then Exit( False );
	if Released then begin mErr := Exception.Create( 'leveldb/table: iterator released' ); Exit( False ); end;
	
	if not mIndex.Seek( ParaKey ) then
	begin
		IndexErr;
		ClearData;
		Exit( False );
	end;
	SetData;
	if not mData.Seek( ParaKey ) then
	begin
		if DataErr() then Exit( False );
		ClearData;
		Exit( Next );
	end;
	Result := True;
end;

function TIndexedIterator.Next : Boolean;
begin
	if mErr <> nil then Exit( False );
	if Released then begin mErr := Exception.Create( 'leveldb/table: iterator released' ); Exit( False ); end;
	
	if ( mData <> nil ) and ( not mData.Next ) then
	begin
		if DataErr() then Exit( False );
		ClearData;
	end;
	
	if mData = nil then
	begin
		if not mIndex.Next then
		begin
			IndexErr;
			Exit( False );
		end;
		SetData;
		Exit( Next );
	end;
	Result := True;
end;

function TIndexedIterator.Prev : Boolean;
begin
	if mErr <> nil then Exit( False );
	if Released then begin mErr := Exception.Create( 'leveldb/table: iterator released' ); Exit( False ); end;
	
	if ( mData <> nil ) and ( not mData.Prev ) then
	begin
		if DataErr() then Exit( False );
		ClearData;
	end;
	
	if mData = nil then
	begin
		if not mIndex.Prev then
		begin
			IndexErr;
			Exit( False );
		end;
		SetData;
		if not mData.Last then
		begin
			if DataErr() then Exit( False );
			ClearData;
			Exit( Prev );
		end;
	end;
	Result := True;
end;

function TIndexedIterator.Key : TBytes;
begin
	if mData = nil then Result := nil else Result := mData.Key;
end;

function TIndexedIterator.Value : TBytes;
begin
	if mData = nil then Result := nil else Result := mData.Value;
end;

procedure TIndexedIterator.Release;
begin
	ClearData;
	if mIndex <> nil then mIndex.Release;
	inherited Release;
end;

function TIndexedIterator.Error : Exception;
begin
	if mErr <> nil then Result := mErr else Result := mIndex.Error;
end;

procedure TIndexedIterator.SetErrorCallback( const ParaF : TProc<Exception> );
begin
	mErrf := ParaF;
end;

end.
