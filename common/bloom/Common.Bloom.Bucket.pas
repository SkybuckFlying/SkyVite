unit Common.Bloom.Bucket;

interface

uses
  Common.Bloom.Bloom,
  Common.Bloom.Bloom.Test,
  Common.Bloom.Util,
  System.Classes,
  System.SysUtils;

type
  // TBuckets is a fast, space-efficient array of buckets where each bucket can
  // store up to a configured maximum value.
  TBuckets = class
  private
    mData: TBytes;
    mBucketSize: Byte;
    mMax: Byte;
    mCount: Cardinal;
    mTotal: Cardinal;
    // getBits returns the bits at the specified offset and length.
    function GetBits( ParaOffset : Cardinal; ParaLength : Cardinal ): Cardinal;
    // setBits sets bits at the specified offset and length.
    procedure SetBits( ParaOffset : Cardinal; ParaLength : Cardinal; ParaBits : Cardinal );
  public
    // Create creates a new Buckets with the provided number of buckets where
    // each bucket is the specified number of bits.
    constructor Create( ParaCount : Cardinal; ParaBucketSize : Byte );
    // MaxBucketValue returns the maximum value that can be stored in a bucket.
    function MaxBucketValue: Byte;
    function FullRatio: Double;
    // Set will set the bucket value. The value is clamped to zero and the maximum
    // bucket value. Returns itself to allow for chaining.
    function SetValue( ParaBucket : Cardinal; ParaValue : Byte ): TBuckets;
    // Get returns the value in the specified bucket.
    function GetValue( ParaBucket : Cardinal ): Cardinal;
    // Reset restores the Buckets to the original state. Returns itself to allow
    // for chaining.
    function Reset: TBuckets;
  end;

// NewBuckets creates a new Buckets with the provided number of buckets where
// each bucket is the specified number of bits.
function NewBuckets( ParaCount : Cardinal; ParaBucketSize : Byte ): TBuckets;

implementation

{ TBuckets }

constructor TBuckets.Create( ParaCount : Cardinal; ParaBucketSize : Byte );
begin
	inherited Create;
	mTotal := ParaCount;
	mCount := 0;
	try
		SetLength( mData, ( ParaCount * Cardinal( ParaBucketSize ) + 7) div 8 );
	except
		on EOutOfMemory do
		begin
			// Handle exception
		end;
	end;
	mBucketSize := ParaBucketSize;
	mMax := (1 shl ParaBucketSize) - 1;
end;

function TBuckets.MaxBucketValue: Byte;
begin
	Result := mMax;
end;

function TBuckets.FullRatio: Double;
begin
	if mTotal = 0 then
	begin
		Result := 0.0;
	end
	else
	begin
		Result := mCount / mTotal;
	end;
end;

// Set will set the bucket value. The value is clamped to zero and the maximum
// bucket value. Returns itself to allow for chaining.
function TBuckets.SetValue( ParaBucket : Cardinal; ParaValue : Byte ): TBuckets;
begin
	if ParaValue > mMax then
	begin
		ParaValue := mMax;
	end;

	SetBits( ParaBucket * mBucketSize, mBucketSize, ParaValue );
	Inc( mCount );
	Result := Self;
end;

// Get returns the value in the specified bucket.
function TBuckets.GetValue( ParaBucket : Cardinal ): Cardinal;
begin
	Result := GetBits( ParaBucket * mBucketSize, mBucketSize );
end;

// Reset restores the Buckets to the original state. Returns itself to allow
// for chaining.
function TBuckets.Reset: TBuckets;
begin
	FillChar( mData[0], Length( mData ), 0 );
	mCount := 0;
	Result := Self;
end;

// getBits returns the bits at the specified offset and length.
function TBuckets.GetBits( ParaOffset : Cardinal; ParaLength : Cardinal ): Cardinal;
var
  vByteIndex: Cardinal;
  vByteOffset: Cardinal;
  vRem: Cardinal;
  vBitMask: Cardinal;
begin
	vByteIndex := ParaOffset div 8;
	vByteOffset := ParaOffset mod 8;
	if vByteOffset + ParaLength > 8 then
	begin
		vRem := 8 - vByteOffset;
		Result := GetBits( ParaOffset, vRem ) or ( GetBits( ParaOffset + vRem, ParaLength - vRem ) shl vRem );
	end
	else
	begin
		vBitMask := (1 shl ParaLength) - 1;
		Result := (Cardinal( mData[vByteIndex] ) and ( vBitMask shl vByteOffset )) shr vByteOffset;
	end;
end;

// setBits sets bits at the specified offset and length.
procedure TBuckets.SetBits( ParaOffset : Cardinal; ParaLength : Cardinal; ParaBits : Cardinal );
var
  vByteIndex: Cardinal;
  vByteOffset: Cardinal;
  vRem: Cardinal;
  vBitMask: Cardinal;
begin
	vByteIndex := ParaOffset div 8;
	vByteOffset := ParaOffset mod 8;
	if vByteOffset + ParaLength > 8 then
	begin
		vRem := 8 - vByteOffset;
		SetBits( ParaOffset, vRem, ParaBits );
		SetBits( ParaOffset + vRem, ParaLength - vRem, ParaBits shr vRem );
	end
	else
	begin
		vBitMask := (1 shl ParaLength) - 1;
		mData[vByteIndex] := Byte( Cardinal( mData[vByteIndex] ) and (not ( vBitMask shl vByteOffset ) ) );
		mData[vByteIndex] := Byte( Cardinal( mData[vByteIndex] ) or ( ( ParaBits and vBitMask ) shl vByteOffset ) );
	end;
end;

// NewBuckets creates a new Buckets with the provided number of buckets where
// each bucket is the specified number of bits.
function NewBuckets( ParaCount : Cardinal; ParaBucketSize : Byte ): TBuckets;
begin
	Result := TBuckets.Create( ParaCount, ParaBucketSize );
end;

end.
