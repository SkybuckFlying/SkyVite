{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Host.Internal.Common.Binary;

interface

{$IFDEF FPC}
uses
	SysUtils, Classes
;
{$ELSE}
uses
	System.SysUtils, System.Classes
;
{$ENDIF}

type
	IByteOrder = interface
		function Uint16( ParaB : TArray<Byte> ) : Word;
		function Uint32( ParaB : TArray<Byte> ) : Cardinal;
		function Uint64( ParaB : TArray<Byte> ) : UInt64;
		procedure PutUint16( ParaB : TArray<Byte>; ParaV : Word );
		procedure PutUint32( ParaB : TArray<Byte>; ParaV : Cardinal );
		procedure PutUint64( ParaB : TArray<Byte>; ParaV : UInt64 );
		function Stringify : string;
	end;

	TLittleEndian = class( TInterfacedObject, IByteOrder )
	public
		function Uint16( ParaB : TArray<Byte> ) : Word;
		function Uint32( ParaB : TArray<Byte> ) : Cardinal;
		function Uint64( ParaB : TArray<Byte> ) : UInt64;
		procedure PutUint16( ParaB : TArray<Byte>; ParaV : Word );
		procedure PutUint32( ParaB : TArray<Byte>; ParaV : Cardinal );
		procedure PutUint64( ParaB : TArray<Byte>; ParaV : UInt64 );
		function Stringify : string;
	end;

	TBigEndian = class( TInterfacedObject, IByteOrder )
	public
		function Uint16( ParaB : TArray<Byte> ) : Word;
		function Uint32( ParaB : TArray<Byte> ) : Cardinal;
		function Uint64( ParaB : TArray<Byte> ) : UInt64;
		procedure PutUint16( ParaB : TArray<Byte>; ParaV : Word );
		procedure PutUint32( ParaB : TArray<Byte>; ParaV : Cardinal );
		procedure PutUint64( ParaB : TArray<Byte>; ParaV : UInt64 );
		function Stringify : string;
	end;

var
	LittleEndian : IByteOrder;
	BigEndian    : IByteOrder;

implementation

{ TLittleEndian }

function TLittleEndian.Uint16( ParaB : TArray<Byte> ) : Word;
begin
	Result := Word( ParaB[ 0 ] ) or ( Word( ParaB[ 1 ] ) shl 8 );
end;

function TLittleEndian.Uint32( ParaB : TArray<Byte> ) : Cardinal;
begin
	Result := Cardinal( ParaB[ 0 ] ) or ( Cardinal( ParaB[ 1 ] ) shl 8 ) or ( Cardinal( ParaB[ 2 ] ) shl 16 ) or ( Cardinal( ParaB[ 3 ] ) shl 24 );
end;

function TLittleEndian.Uint64( ParaB : TArray<Byte> ) : UInt64;
begin
	Result := UInt64( ParaB[ 0 ] ) or ( UInt64( ParaB[ 1 ] ) shl 8 ) or ( UInt64( ParaB[ 2 ] ) shl 16 ) or ( UInt64( ParaB[ 3 ] ) shl 24 ) or
		( UInt64( ParaB[ 4 ] ) shl 32 ) or ( UInt64( ParaB[ 5 ] ) shl 40 ) or ( UInt64( ParaB[ 6 ] ) shl 48 ) or ( UInt64( ParaB[ 7 ] ) shl 56 );
end;

procedure TLittleEndian.PutUint16( ParaB : TArray<Byte>; ParaV : Word );
begin
	ParaB[ 0 ] := Byte( ParaV );
	ParaB[ 1 ] := Byte( ParaV shr 8 );
end;

procedure TLittleEndian.PutUint32( ParaB : TArray<Byte>; ParaV : Cardinal );
begin
	ParaB[ 0 ] := Byte( ParaV );
	ParaB[ 1 ] := Byte( ParaV shr 8 );
	ParaB[ 2 ] := Byte( ParaV shr 16 );
	ParaB[ 3 ] := Byte( ParaV shr 24 );
end;

procedure TLittleEndian.PutUint64( ParaB : TArray<Byte>; ParaV : UInt64 );
begin
	ParaB[ 0 ] := Byte( ParaV );
	ParaB[ 1 ] := Byte( ParaV shr 8 );
	ParaB[ 2 ] := Byte( ParaV shr 16 );
	ParaB[ 3 ] := Byte( ParaV shr 24 );
	ParaB[ 4 ] := Byte( ParaV shr 32 );
	ParaB[ 5 ] := Byte( ParaV shr 40 );
	ParaB[ 6 ] := Byte( ParaV shr 48 );
	ParaB[ 7 ] := Byte( ParaV shr 56 );
end;

function TLittleEndian.Stringify : string;
begin
	Result := 'LittleEndian';
end;

{ TBigEndian }

function TBigEndian.Uint16( ParaB : TArray<Byte> ) : Word;
begin
	Result := Word( ParaB[ 1 ] ) or ( Word( ParaB[ 0 ] ) shl 8 );
end;

function TBigEndian.Uint32( ParaB : TArray<Byte> ) : Cardinal;
begin
	Result := Cardinal( ParaB[ 3 ] ) or ( Cardinal( ParaB[ 2 ] ) shl 8 ) or ( Cardinal( ParaB[ 1 ] ) shl 16 ) or ( Cardinal( ParaB[ 0 ] ) shl 24 );
end;

function TBigEndian.Uint64( ParaB : TArray<Byte> ) : UInt64;
begin
	Result := UInt64( ParaB[ 7 ] ) or ( UInt64( ParaB[ 6 ] ) shl 8 ) or ( UInt64( ParaB[ 5 ] ) shl 16 ) or ( UInt64( ParaB[ 4 ] ) shl 24 ) or
		( UInt64( ParaB[ 3 ] ) shl 32 ) or ( UInt64( ParaB[ 2 ] ) shl 40 ) or ( UInt64( ParaB[ 1 ] ) shl 48 ) or ( UInt64( ParaB[ 0 ] ) shl 56 );
end;

procedure TBigEndian.PutUint16( ParaB : TArray<Byte>; ParaV : Word );
begin
	ParaB[ 0 ] := Byte( ParaV shr 8 );
	ParaB[ 1 ] := Byte( ParaV );
end;

procedure TBigEndian.PutUint32( ParaB : TArray<Byte>; ParaV : Cardinal );
begin
	ParaB[ 0 ] := Byte( ParaV shr 24 );
	ParaB[ 1 ] := Byte( ParaV shr 16 );
	ParaB[ 2 ] := Byte( ParaV shr 8 );
	ParaB[ 3 ] := Byte( ParaV );
end;

procedure TBigEndian.PutUint64( ParaB : TArray<Byte>; ParaV : UInt64 );
begin
	ParaB[ 0 ] := Byte( ParaV shr 56 );
	ParaB[ 1 ] := Byte( ParaV shr 48 );
	ParaB[ 2 ] := Byte( ParaV shr 40 );
	ParaB[ 3 ] := Byte( ParaV shr 32 );
	ParaB[ 4 ] := Byte( ParaV shr 24 );
	ParaB[ 5 ] := Byte( ParaV shr 16 );
	ParaB[ 6 ] := Byte( ParaV shr 8 );
	ParaB[ 7 ] := Byte( ParaV );
end;

function TBigEndian.Stringify : string;
begin
	Result := 'BigEndian';
end;

initialization
	LittleEndian := TLittleEndian.Create;
	BigEndian := TBigEndian.Create;

end.
