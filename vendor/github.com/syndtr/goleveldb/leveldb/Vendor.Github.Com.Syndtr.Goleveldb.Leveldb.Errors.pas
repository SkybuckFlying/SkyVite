unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors;

var
	ErrNotFound         : Exception;
	ErrReadOnly         : Exception;
	ErrSnapshotReleased : Exception;
	ErrIterReleased     : Exception;
	ErrClosed           : Exception;

implementation

initialization
	ErrNotFound := ENotFound.Create( 'leveldb: not found' );
	ErrReadOnly := Exception.Create( 'leveldb: read-only mode' );
	ErrSnapshotReleased := Exception.Create( 'leveldb: snapshot released' );
	ErrIterReleased := Exception.Create( 'leveldb: iterator released' );
	ErrClosed := Exception.Create( 'leveldb: closed' );

end.
