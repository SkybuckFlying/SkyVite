unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32;

interface

uses
	System.SysUtils;

type
	TCRC32 = record
	private
		mValue : UInt32;
		class var mTable : array[ 0..255 ] of UInt32;
		class constructor Create;
	public
		class function New( const ParaB : TBytes ) : TCRC32; static;
		function Update( const ParaB : TBytes ) : TCRC32;
		function Value : UInt32;
	end;

implementation

{ TCRC32 }

class constructor TCRC32.Create;
var
	vI, vJ : Integer;
	vR : UInt32;
begin
	// Castagnoli polynomial: 0x82f63b78 (reversed: 0xedb88320 is for IEEE)
	// Go's crc32.Castagnoli is 0x82f63b78
	for vI := 0 to 255 do
	begin
		vR := vI;
		for vJ := 0 to 7 do
		begin
			if ( vR and 1 ) <> 0 then
				vR := ( vR shr 1 ) xor $82F63B78
			else
				vR := vR shr 1;
		end;
		mTable[ vI ] := vR;
	end;
end;

class function TCRC32.New( const ParaB : TBytes ) : TCRC32;
begin
	Result.mValue := 0;
	Result := Result.Update( ParaB );
end;

function TCRC32.Update( const ParaB : TBytes ) : TCRC32;
var
	vB : Byte;
begin
	mValue := not mValue;
	for vB in ParaB do
		mValue := mTable[ ( mValue xor vB ) and $FF ] xor ( mValue shr 8 );
	mValue := not mValue;
	Result := Self;
end;

function TCRC32.Value : UInt32;
begin
	// Masking: uint32(c>>15|c<<17) + 0xa282ead8
	Result := ( mValue shr 15 ) or ( mValue shl 17 );
	Result := Result + $A282EAD8;
end;

end.
