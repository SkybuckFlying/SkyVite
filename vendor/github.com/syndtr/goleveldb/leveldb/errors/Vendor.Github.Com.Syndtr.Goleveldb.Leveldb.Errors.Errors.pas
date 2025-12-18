unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage;

type
	ENotFound = class( Exception );
	
	// Corrupted error type would normally depend on storage.FileDesc
	// For now, we'll provide a simplified version or a placeholder if storage is not yet converted.
	// The Go code uses storage.FileDesc which is mapped to Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.FileDesc.pas
	
	ECorrupted = class( Exception )
	private
		mFd : TFileDesc;
	public
		constructor Create( const ParaFd : TFileDesc; const ParaMsg : string ); reintroduce;
		property Fd : TFileDesc read mFd;
	end;

function IsCorrupted( const ParaError : Exception ) : Boolean;
function New( const ParaText : string ) : Exception;

implementation

{ ECorrupted }

constructor ECorrupted.Create( const ParaFd : TFileDesc; const ParaMsg : string );
begin
	inherited Create( ParaMsg );
	mFd := ParaFd;
end;

function IsCorrupted( const ParaError : Exception ) : Boolean;
begin
	Result := ParaError is ECorrupted;
	// Also check for storage.ECorrupted if it exists
end;

function New( const ParaText : string ) : Exception;
begin
	Result := Exception.Create( ParaText );
end;

end.
