unit Common.Bloom.Bloom;

interface

uses
  Common.Bloom.Bloom.Test,
  Common.Bloom.Bucket,
  Common.Bloom.Util,
  System.SysUtils System.Hash System.Classes System.SyncObjs;

type
	IBuckets = interface
		['{B1F3E2D6-5A8B-4E7C-9F6A-3D2B1F3E2D6A}']
		function Get(ParaIndex: Cardinal): Byte;
		procedure Set(ParaIndex: Cardinal; ParaValue: Byte);
		function FullRatio: Double;
		procedure Reset;
	end;

	TBuckets = class(TInterfacedObject, IBuckets)
	private
		mBuckets: TBytes;
		mCount: Int64;
		mSize: Cardinal;
	public
		constructor Create(ParaM: Cardinal; ParaK: Cardinal);
		function Get(ParaIndex: Cardinal): Byte;
		procedure Set(ParaIndex: Cardinal; ParaValue: Byte);
		function FullRatio: Double;
		procedure Reset;
	end;

	IFilter = interface
		['{A2E1D0C5-9B8A-4F6D-8C7B-5A2E1D0C59B8}']
		function Test(const ParaData: TBytes): Boolean;
		procedure Add(const ParaData: TBytes);
		function TestAndAdd(const ParaData: TBytes): Boolean;
	end;

	TFilter = class(TInterfacedObject, IFilter)
	private
		mBuckets: array[0..1] of IBuckets;
		mHash: IHash;
		mM: Cardinal;
		mK: Cardinal;
		mRw: TRTLCriticalSection;
		function TestHashUnlocked(ParaLower, ParaUpper: UInt32): Boolean;
		procedure AddHashUnlocked(ParaLower, ParaUpper: UInt32);
	public
		constructor Create(ParaN: Cardinal; ParaFpRate: Double);
		function Test(const ParaData: TBytes): Boolean;
		procedure Add(const ParaData: TBytes);
		function TestAndAdd(const ParaData: TBytes): Boolean;
	end;

function NewBuckets(ParaM: Cardinal; ParaK: Cardinal): IBuckets;
function NewFilter(ParaN: Cardinal; ParaFpRate: Double): IFilter;
function OptimalM(ParaN: Cardinal; ParaFpRate: Double): Cardinal;
function OptimalK(ParaFpRate: Double): Cardinal;
procedure HashInternal(const ParaData: TBytes; const ParaHash: IHash; out ParaLower, ParaUpper: UInt32);

implementation

uses
	System.Math;

function NewBuckets(ParaM: Cardinal; ParaK: Cardinal): IBuckets;
begin
	Result := TBuckets.Create(ParaM, ParaK);
end;

function NewFilter(ParaN: Cardinal; ParaFpRate: Double): IFilter;
begin
	Result := TFilter.Create(ParaN, ParaFpRate);
end;

function OptimalM(ParaN: Cardinal; ParaFpRate: Double): Cardinal;
begin
	Result := Ceil(-1 * (ParaN * Ln(ParaFpRate)) / (Ln(2) * Ln(2)));
end;

function OptimalK(ParaFpRate: Double): Cardinal;
begin
	Result := Ceil(Ln(2) * (OptimalM(1, ParaFpRate) / 1));
end;

procedure HashInternal(const ParaData: TBytes; const ParaHash: IHash; out ParaLower, ParaUpper: UInt32);
var
	vSum: TBytes;
begin
	vSum := ParaHash.GetHashBytes(ParaData);
	ParaLower := (UInt32(vSum[3]) shl 24) or (UInt32(vSum[2]) shl 16) or (UInt32(vSum[1]) shl 8) or UInt32(vSum[0]);
	ParaUpper := (UInt32(vSum[7]) shl 24) or (UInt32(vSum[6]) shl 16) or (UInt32(vSum[5]) shl 8) or UInt32(vSum[4]);
end;

{ TBuckets }

constructor TBuckets.Create(ParaM: Cardinal; ParaK: Cardinal);
begin
	inherited Create;
	mSize := ParaM;
	SetLength(mBuckets, mSize);
end;

function TBuckets.Get(ParaIndex: Cardinal): Byte;
begin
	Result := mBuckets[ParaIndex];
end;

procedure TBuckets.Set(ParaIndex: Cardinal; ParaValue: Byte);
begin
	if mBuckets[ParaIndex] = 0 then
	begin
		if ParaValue <> 0 then
		begin
			mCount := mCount + 1;
		end;
	end
	else
	begin
		if ParaValue = 0 then
		begin
			mCount := mCount - 1;
		end;
	end;
	mBuckets[ParaIndex] := ParaValue;
end;

function TBuckets.FullRatio: Double;
begin
	Result := mCount / mSize;
end;

procedure TBuckets.Reset;
begin
	FillChar(mBuckets[0], mSize, 0);
	mCount := 0;
end;

{ TFilter }

constructor TFilter.Create(ParaN: Cardinal; ParaFpRate: Double);
begin
	inherited Create;
	mM := OptimalM(ParaN, ParaFpRate);
	mK := OptimalK(ParaFpRate);
	mBuckets[0] := NewBuckets(mM, mK);
	mBuckets[1] := NewBuckets(mM, mK);
	mHash := THashFactory.TCrc64.Create;
	InitializeCriticalSection(mRw);
end;

function TFilter.Test(const ParaData: TBytes): Boolean;
var
	vLower, vUpper: UInt32;
begin
	EnterCriticalSection(mRw);
	try
		HashInternal(ParaData, mHash, vLower, vUpper);
		Result := TestHashUnlocked(vLower, vUpper);
	finally
		LeaveCriticalSection(mRw);
	end;
end;

procedure TFilter.Add(const ParaData: TBytes);
var
	vLower, vUpper: UInt32;
begin
	EnterCriticalSection(mRw);
	try
		HashInternal(ParaData, mHash, vLower, vUpper);
		AddHashUnlocked(vLower, vUpper);
	finally
		LeaveCriticalSection(mRw);
	end;
end;

function TFilter.TestAndAdd(const ParaData: TBytes): Boolean;
var
	vLower, vUpper: UInt32;
begin
	EnterCriticalSection(mRw);
	try
		HashInternal(ParaData, mHash, vLower, vUpper);
		if TestHashUnlocked(vLower, vUpper) then
		begin
			Result := True;
		end
		else
		begin
			AddHashUnlocked(vLower, vUpper);
			Result := False;
		end;
	finally
		LeaveCriticalSection(mRw);
	end;
end;

function TFilter.TestHashUnlocked(ParaLower, ParaUpper: UInt32): Boolean;
var
	vBkt: IBuckets;
	vIndex: Cardinal;
begin
	for vBkt in mBuckets do
	begin
		Result := True;
		for vIndex := 0 to mK - 1 do
		begin
			if vBkt.Get((ParaLower + ParaUpper * vIndex) mod mM) = 0 then
			begin
				Result := False;
				break;
			end;
		end;
		if Result then
		begin
			Exit;
		end;
	end;
	Result := False;
end;

procedure TFilter.AddHashUnlocked(ParaLower, ParaUpper: UInt32);
var
	vTemp: IBuckets;
	vIndex: Cardinal;
begin
	if mBuckets[0].FullRatio > 0.8 then
	begin
		vTemp := mBuckets[0];
		mBuckets[0] := mBuckets[1];
		mBuckets[1] := vTemp;
		mBuckets[0].Reset;
	end;
	for vIndex := 0 to mK - 1 do
	begin
		mBuckets[0].Set((ParaLower + ParaUpper * vIndex) mod mM, 1);
	end;
end;

end.
