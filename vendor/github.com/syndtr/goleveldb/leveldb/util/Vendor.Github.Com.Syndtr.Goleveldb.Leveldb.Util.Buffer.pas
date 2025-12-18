unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Buffer;

interface

uses
	System.SysUtils,
	System.Classes;

type
	TBuffer = class
	private
		mBuf : TBytes;
		mOff : Integer;
		procedure Grow( ParaN : Integer );
	public
		constructor Create;
		constructor CreateWith( const ParaBuf : TBytes );
		
		function Bytes : TBytes;
		function Len : Integer;
		procedure Reset;
		procedure Truncate( ParaN : Integer );
		
		function Alloc( ParaN : Integer ) : TBytes;
		function Write( const ParaP : TBytes ) : Integer;
		procedure WriteByte( ParaC : Byte );
		
		function Read( var ParaP : TBytes ) : Integer;
		function ReadByte : Byte;
		function Next( ParaN : Integer ) : TBytes;
	end;

implementation

{ TBuffer }

constructor TBuffer.Create;
begin
	SetLength( mBuf, 0 );
	mOff := 0;
end;

constructor TBuffer.CreateWith( const ParaBuf : TBytes );
begin
	mBuf := Copy( ParaBuf );
	mOff := 0;
end;

function TBuffer.Bytes : TBytes;
begin
	Result := Copy( mBuf, mOff, Length( mBuf ) - mOff );
end;

function TBuffer.Len : Integer;
begin
	Result := Length( mBuf ) - mOff;
end;

procedure TBuffer.Reset;
begin
	SetLength( mBuf, 0 );
	mOff := 0;
end;

procedure TBuffer.Truncate( ParaN : Integer );
begin
	if ParaN = 0 then
	begin
		Reset;
		Exit;
	end;
	if ( ParaN < 0 ) or ( ParaN > Len ) then
		raise Exception.Create( 'leveldb/util.Buffer: truncation out of range' );
	SetLength( mBuf, mOff + ParaN );
end;

procedure TDB.Grow( ParaN : Integer );
var
	vM, vC : Integer;
	vNewBuf : TBytes;
begin
	vM := Len;
	if ( vM = 0 ) and ( mOff <> 0 ) then
		Reset;
	
	vC := Length( mBuf );
	if ( mOff + vM + ParaN ) <= vC then
	begin
		// No need to grow capacity, just reslice if needed
	end
	else if vM + ParaN <= vC div 2 then
	begin
		// Slide down
		Move( mBuf[ mOff ], mBuf[ 0 ], vM );
		mOff := 0;
	end
	else
	begin
		// Reallocate
		SetLength( vNewBuf, 2 * vC + ParaN + 64 );
		Move( mBuf[ mOff ], vNewBuf[ 0 ], vM );
		mBuf := vNewBuf;
		mOff := 0;
	end;
	SetLength( mBuf, vM + ParaN );
end;

function TBuffer.Alloc( ParaN : Integer ) : TBytes;
var
	vM : Integer;
begin
	if ParaN < 0 then
		raise Exception.Create( 'leveldb/util.Buffer.Alloc: negative count' );
	vM := Len;
	Grow( ParaN );
	Result := Copy( mBuf, mOff + vM, ParaN );
end;

function TBuffer.Write( const ParaP : TBytes ) : Integer;
var
	vM : Integer;
begin
	vM := Len;
	Grow( Length( ParaP ) );
	Move( ParaP[ 0 ], mBuf[ mOff + vM ], Length( ParaP ) );
	Result := Length( ParaP );
end;

procedure TBuffer.WriteByte( ParaC : Byte );
var
	vM : Integer;
begin
	vM := Len;
	Grow( 1 );
	mBuf[ mOff + vM ] := ParaC;
end;

function TBuffer.Read( var ParaP : TBytes ) : Integer;
begin
	if mOff >= Length( mBuf ) then
	begin
		Reset;
		Exit( 0 );
	end;
	Result := Length( ParaP );
	if Result > Len then Result := Len;
	Move( mBuf[ mOff ], ParaP[ 0 ], Result );
	mOff := mOff + Result;
end;

function TBuffer.ReadByte : Byte;
begin
	if mOff >= Length( mBuf ) then
	begin
		Reset;
		raise Exception.Create( 'EOF' );
	end;
	Result := mBuf[ mOff ];
	Inc( mOff );
end;

function TBuffer.Next( ParaN : Integer ) : TBytes;
var
	vM : Integer;
begin
	vM := Len;
	if ParaN > vM then ParaN := vM;
	Result := Copy( mBuf, mOff, ParaN );
	mOff := mOff + ParaN;
end;

end.
