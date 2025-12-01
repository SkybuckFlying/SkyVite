unit Common.Db.Xleveldb.Iterator.Iter;

interface

uses
	System.SysUtils,
	Common.Db.Xleveldb.Util;

var
	ErrIterReleased : Exception;

type
	// IIteratorSeeker is the interface that wraps the 'seeks method'.
	IIteratorSeeker = interface
		[ '{B8E62B43-1B4E-4B4A-82F7-23A4A7426775}' ]
		// First moves the iterator to the first key/value pair. If the iterator
		// only contains one key/value pair then First and Last would moves
		// to the same key/value pair.
		// It returns whether such pair exist.
		function First : Boolean;

		// Last moves the iterator to the last key/value pair. If the iterator
		// only contains one key/value pair then First and Last would moves
		// to the same key/value pair.
		// It returns whether such pair exist.
		function Last : Boolean;

		// Seek moves the iterator to the first key/value pair whose key is greater
		// than or equal to the given key.
		// It returns whether such pair exist.
		//
		// It is safe to modify the contents of the argument after Seek returns.
		function Seek( const ParaKey : TBytes ) : Boolean;

		// Next moves the iterator to the next key/value pair.
		// It returns whether the iterator is exhausted.
		function Next : Boolean;

		// Prev moves the iterator to the previous key/value pair.
		// It returns whether the iterator is exhausted.
		function Prev : Boolean;
	end;

	// ICommonIterator is the interface that wraps common iterator methods.
	ICommonIterator = interface( IIteratorSeeker, IReleaser, IReleaseSetter )
		[ '{A1BD3C3D-E5E0-4E7A-B035-31A4B4A5B6B7}' ]
		// TODO: Remove this when ready.
		function Valid : Boolean;

		// Error returns any accumulated error. Exhausting all the key/value pairs
		// is not considered to be an error.
		function Error : Exception;
	end;

	// IIterator iterates over a DB's key/value pairs in key order.
	//
	// When encounter an error any 'seeks method' will return false and will
	// yield no key/value pairs. The error can be queried by calling the Error
	// method. Calling Release is still necessary.
	//
	// An iterator must be released after use, but it is not necessary to read
	// an iterator until exhaustion.
	// Also, an iterator is not necessarily safe for concurrent use, but it is
	// safe to use multiple iterators concurrently, with each in a dedicated
	// goroutine.
	IIterator = interface( ICommonIterator )
		[ '{C7A9E3A9-8A9E-4D8C-B5A8-2B9A8A9B8C7D}' ]
		// Key returns the key of the current key/value pair, or nil if done.
		// The caller should not modify the contents of the returned slice, and
		// its contents may change on the next call to any 'seeks method'.
		function Key : TBytes;

		// Value returns the value of the current key/value pair, or nil if done.
		// The caller should not modify the contents of the returned slice, and
		// its contents may change on the next call to any 'seeks method'.
		function Value : TBytes;
	end;

	TErrorCallbackFunc = procedure( E : Exception ) of object;

	// IErrorCallbackSetter is the interface that wraps basic SetErrorCallback
	// method.
	//
	// IErrorCallbackSetter implemented by indexed and merged iterator.
	IErrorCallbackSetter = interface
		[ '{D2B8C8B8-A8B8-4C8B-9A8B-8A9B8C7D6E5F}' ]
		// SetErrorCallback allows set an error callback of the corresponding
		// iterator. Use nil to clear the callback.
		procedure SetErrorCallback( ParaF : TErrorCallbackFunc );
	end;

	TEmptyIterator = class( TInterfacedObject, IIterator )
	private
		mBasicReleaser : TBasicReleaser;
		mErr : Exception;
		procedure RErr;
	public
		constructor Create( ParaErr : Exception );
		destructor Destroy; override;
		function Valid : Boolean;
		function First : Boolean;
		function Last : Boolean;
		function Seek( const ParaKey : TBytes ) : Boolean;
		function Next : Boolean;
		function Prev : Boolean;
		function Key : TBytes;
		function Value : TBytes;
		function Error : Exception;
		procedure Release;
		procedure SetReleaser( ParaReleaser : IReleaser );
	end;

function NewEmptyIterator( ParaErr : Exception ) : IIterator;

implementation

{ TEmptyIterator }

constructor TEmptyIterator.Create( ParaErr : Exception );
begin
	inherited Create;
	mBasicReleaser := TBasicReleaser.Create;
	mErr := ParaErr;
end;

destructor TEmptyIterator.Destroy;
begin
	mBasicReleaser.Free;
	inherited Destroy;
end;

procedure TEmptyIterator.RErr;
begin
	if ( mErr = nil ) and mBasicReleaser.Released then
	begin
		mErr := ErrIterReleased;
	end;
end;

function TEmptyIterator.Valid : Boolean;
begin
	Result := False;
end;

function TEmptyIterator.First : Boolean;
begin
	RErr;
	Result := False;
end;

function TEmptyIterator.Last : Boolean;
begin
	RErr;
	Result := False;
end;

function TEmptyIterator.Seek( const ParaKey : TBytes ) : Boolean;
begin
	RErr;
	Result := False;
end;

function TEmptyIterator.Next : Boolean;
begin
	RErr;
	Result := False;
end;

function TEmptyIterator.Prev : Boolean;
begin
	RErr;
	Result := False;
end;

function TEmptyIterator.Key : TBytes;
begin
	Result := nil;
end;

function TEmptyIterator.Value : TBytes;
begin
	Result := nil;
end;

function TEmptyIterator.Error : Exception;
begin
	Result := mErr;
end;

procedure TEmptyIterator.Release;
begin
	mBasicReleaser.Release;
end;

procedure TEmptyIterator.SetReleaser( ParaReleaser : IReleaser );
begin
	mBasicReleaser.SetReleaser( ParaReleaser );
end;

function NewEmptyIterator( ParaErr : Exception ) : IIterator;
begin
	Result := TEmptyIterator.Create( ParaErr );
end;

initialization
	ErrIterReleased := Exception.Create( 'leveldb/iterator: iterator released' );

finalization
	ErrIterReleased.Free;

end.