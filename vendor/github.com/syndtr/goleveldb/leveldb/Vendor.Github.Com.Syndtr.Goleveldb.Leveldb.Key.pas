unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors;

type
	EInternalKeyCorrupted = class( ECorrupted )
	private
		mIkey : TBytes;
		mReason : string;
	public
		constructor Create( const ParaIkey : TBytes; const ParaReason : string ); reintroduce;
		property Ikey : TBytes read mIkey;
		property Reason : string read mReason;
	end;

	TKeyType = ( ktDel = 0, ktVal = 1 );

const
	ktSeek = ktVal;
	KEY_MAX_SEQ = ( UInt64( 1 ) shl 56 ) - 1;
	KEY_MAX_NUM = ( KEY_MAX_SEQ shl 8 ) or UInt64( ktSeek );

var
	KeyMaxNumBytes : TBytes;

type
	TInternalKey = TBytes;

	TInternalKeyHelper = record helper for TInternalKey
	public
		procedure Assert;
		function Ukey : TBytes;
		function Num : UInt64;
		procedure ParseNum( out ParaSeq : UInt64; out ParaKt : TKeyType );
		function ToString : string;
	end;

function MakeInternalKey( const ParaDst, ParaUkey : TBytes; ParaSeq : UInt64; ParaKt : TKeyType ) : TInternalKey;
function ParseInternalKey( const ParaIk : TBytes; out ParaUkey : TBytes; out ParaSeq : UInt64; out ParaKt : TKeyType ) : Exception;
function ValidInternalKey( const ParaIk : TBytes ) : Boolean;
function Shorten( const ParaStr : string ) : string;

implementation

{ EInternalKeyCorrupted }

constructor EInternalKeyCorrupted.Create( const ParaIkey : TBytes; const ParaReason : string );
begin
	inherited Create( Format( 'leveldb: internal key corrupted: %s', [ ParaReason ] ) );
	mIkey := ParaIkey;
	mReason := ParaReason;
end;

{ TInternalKeyHelper }

procedure TInternalKeyHelper.Assert;
begin
	if Self = nil then
		raise Exception.Create( 'leveldb: nil internalKey' );
	if Length( Self ) < 8 then
		raise Exception.Create( 'leveldb: internal key invalid length' );
end;

function TInternalKeyHelper.Ukey : TBytes;
begin
	Assert;
	Result := Copy( Self, 0, Length( Self ) - 8 );
end;

function TInternalKeyHelper.Num : UInt64;
begin
	Assert;
	Result := PUInt64( @Self[ Length( Self ) - 8 ] )^;
end;

procedure TInternalKeyHelper.ParseNum( out ParaSeq : UInt64; out ParaKt : TKeyType );
var
	vNum : UInt64;
begin
	vNum := Num;
	ParaSeq := vNum shr 8;
	ParaKt := TKeyType( vNum and $FF );
	if ParaKt > ktVal then
		raise Exception.Create( 'leveldb: internal key invalid type' );
end;

function TInternalKeyHelper.ToString : string;
var
	vUkey : TBytes;
	vSeq : UInt64;
	vKt : TKeyType;
begin
	if Self = nil then
		Exit( '<nil>' );
	
	if ParseInternalKey( Self, vUkey, vSeq, vKt ) = nil then
		Result := Format( '%s,%d%d', [ Shorten( TEncoding.ANSI.GetString( vUkey ) ), Ord( vKt ), vSeq ] )
	else
		Result := '<invalid>';
end;

function Shorten( const ParaStr : string ) : string;
begin
	if Length( ParaStr ) <= 8 then
		Result := ParaStr
	else
		Result := Copy( ParaStr, 1, 3 ) + '..' + Copy( ParaStr, Length( ParaStr ) - 2, 3 );
end;

function MakeInternalKey( const ParaDst, ParaUkey : TBytes; ParaSeq : UInt64; ParaKt : TKeyType ) : TInternalKey;
begin
	if ParaSeq > KEY_MAX_SEQ then
		raise Exception.Create( 'leveldb: invalid sequence number' );
	
	Result := Copy( ParaUkey );
	SetLength( Result, Length( ParaUkey ) + 8 );
	PUInt64( @Result[ Length( ParaUkey ) ] )^ := ( ParaSeq shl 8 ) or UInt64( ParaKt );
end;

function ParseInternalKey( const ParaIk : TBytes; out ParaUkey : TBytes; out ParaSeq : UInt64; out ParaKt : TKeyType ) : Exception;
var
	vNum : UInt64;
begin
	Result := nil;
	if Length( ParaIk ) < 8 then
	begin
		Result := EInternalKeyCorrupted.Create( ParaIk, 'invalid length' );
		Exit;
	end;
	
	vNum := PUInt64( @ParaIk[ Length( ParaIk ) - 8 ] )^;
	ParaSeq := vNum shr 8;
	ParaKt := TKeyType( vNum and $FF );
	
	if ParaKt > ktVal then
	begin
		Result := EInternalKeyCorrupted.Create( ParaIk, 'invalid type' );
		Exit;
	end;
	
	ParaUkey := Copy( ParaIk, 0, Length( ParaIk ) - 8 );
end;

function ValidInternalKey( const ParaIk : TBytes ) : Boolean;
var
	vUkey : TBytes;
	vSeq : UInt64;
	vKt : TKeyType;
begin
	Result := ParseInternalKey( ParaIk, vUkey, vSeq, vKt ) = nil;
end;

initialization
	SetLength( KeyMaxNumBytes, 8 );
	PUInt64( @KeyMaxNumBytes[ 0 ] )^ := KEY_MAX_NUM;

end.
