unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.ArrayIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.IndexedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.MergedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
	IIteratorSeeker = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F72}']
		function First : Boolean;
		function Last : Boolean;
		function Seek( const ParaKey : TBytes ) : Boolean;
		function Next : Boolean;
		function Prev : Boolean;
	end;

	ICommonIterator = interface( IIteratorSeeker )
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F73}']
		procedure Release;
		procedure SetReleaser( const ParaReleaser : IReleaser );
		function Valid : Boolean;
		function Error : Exception;
	end;

	IIterator = interface( ICommonIterator )
		['{D5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F74}']
		function Key : TBytes;
		function Value : TBytes;
	end;

	IErrorCallbackSetter = interface
		['{F5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F75}']
		procedure SetErrorCallback( const ParaF : TProc<Exception> );
	end;

	TEmptyIterator = class( TBasicReleaser, IIteratorSeeker, ICommonIterator, IIterator )
	private
		mErr : Exception;
		procedure RErr;
	public
		constructor Create( const ParaErr : Exception );
		function Valid : Boolean; virtual;
		function First : Boolean; virtual;
		function Last : Boolean; virtual;
		function Seek( const ParaKey : TBytes ) : Boolean; virtual;
		function Next : Boolean; virtual;
		function Prev : Boolean; virtual;
		function Key : TBytes; virtual;
		function Value : TBytes; virtual;
		function Error : Exception; virtual;
	end;

function NewEmptyIterator( const ParaErr : Exception ) : IIterator;

implementation

{ TEmptyIterator }

constructor TEmptyIterator.Create( const ParaErr : Exception );
begin
	inherited Create;
	mErr := ParaErr;
end;

procedure TEmptyIterator.RErr;
begin
	if ( mErr = nil ) and Released then
		mErr := Exception.Create( 'leveldb/iterator: iterator released' );
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

function NewEmptyIterator( const ParaErr : Exception ) : IIterator;
begin
	Result := TEmptyIterator.Create( ParaErr );
end;

end.
