unit Vendor.Github.Com.Allegro.BigCache.Queue.BytesQueue;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Diagnostics;

type
	EQueueError = class(Exception);

	TBytesQueue = class
	private
		mArray           : TBytes;
		mCapacity        : Integer;
		mMaxCapacity     : Integer;
		mHead            : Integer;
		mTail            : Integer;
		mCount           : Integer;
		mRightMargin     : Integer;
		mHeaderBuffer    : TBytes;
		mVerbose         : Boolean;
		mInitialCapacity : Integer;

		procedure AllocateAdditionalMemory( ParaMinimum : Integer );
		procedure InternalPush( const ParaData : TBytes; ParaLen : Integer );
		procedure InternalCopy( const ParaData : TBytes; ParaLen : Integer );
		function AvailableSpaceAfterTail : Integer;
		function AvailableSpaceBeforeHead : Integer;
		function PeekInternal( ParaIndex : Integer; out ParaSize : Integer; out ParaData : TBytes ) : Boolean;
	public
		constructor Create( ParaInitialCapacity : Integer; ParaMaxCapacity : Integer; ParaVerbose : Boolean );
		procedure Reset;
		function Push( const ParaData : TBytes ) : Integer;
		function Pop : TBytes;
		function Peek : TBytes;
		function Get( ParaIndex : Integer ) : TBytes;
		function CheckGet( ParaIndex : Integer ) : Boolean;
		property Capacity : Integer read mCapacity;
		property Count : Integer read mCount;
	end;

implementation

const
	Const_HeaderEntrySize = 4;
	Const_LeftMarginIndex = 1;
	Const_MinimumEmptyBlobSize = 32 + Const_HeaderEntrySize;

constructor TBytesQueue.Create( ParaInitialCapacity : Integer; ParaMaxCapacity : Integer; ParaVerbose : Boolean );
begin
	inherited Create;
	mInitialCapacity := ParaInitialCapacity;
	mCapacity := ParaInitialCapacity;
	mMaxCapacity := ParaMaxCapacity;
	mVerbose := ParaVerbose;
	SetLength( mArray, mCapacity );
	SetLength( mHeaderBuffer, Const_HeaderEntrySize );
	mTail := Const_LeftMarginIndex;
	mHead := Const_LeftMarginIndex;
	mRightMargin := Const_LeftMarginIndex;
end;

procedure TBytesQueue.Reset;
begin
	mTail := Const_LeftMarginIndex;
	mHead := Const_LeftMarginIndex;
	mRightMargin := Const_LeftMarginIndex;
	mCount := 0;
end;

function TBytesQueue.Push( const ParaData : TBytes ) : Integer;
var
	vDataLen : Integer;
begin
	vDataLen := Length( ParaData );

	if AvailableSpaceAfterTail < vDataLen + Const_HeaderEntrySize then
	begin
		if AvailableSpaceBeforeHead >= vDataLen + Const_HeaderEntrySize then
		begin
			mTail := Const_LeftMarginIndex;
		end else if ( mCapacity + Const_HeaderEntrySize + vDataLen >= mMaxCapacity ) and ( mMaxCapacity > 0 ) then
		begin
			raise EQueueError.Create( 'Full queue. Maximum size limit reached.' );
		end else
		begin
			AllocateAdditionalMemory( vDataLen + Const_HeaderEntrySize );
		end;
	end;

	Result := mTail;
	InternalPush( ParaData, vDataLen );
end;

procedure TBytesQueue.AllocateAdditionalMemory( ParaMinimum : Integer );
var
	vStopwatch : TStopwatch;
	vOldArray : TBytes;
	vEmptyBlobLen : Integer;
	vEmptyData : TBytes;
begin
	vStopwatch := TStopwatch.StartNew;
	
	if mCapacity < ParaMinimum then
	begin
		mCapacity := mCapacity + ParaMinimum;
	end;
	mCapacity := mCapacity * 2;
	
	if ( mCapacity > mMaxCapacity ) and ( mMaxCapacity > 0 ) then
	begin
		mCapacity := mMaxCapacity;
	end;

	vOldArray := mArray;
	SetLength( mArray, mCapacity );

	if Const_LeftMarginIndex <> mRightMargin then
	begin
		Move( vOldArray[0], mArray[0], mRightMargin );

		if mTail < mHead then
		begin
			vEmptyBlobLen := mHead - mTail - Const_HeaderEntrySize;
			vEmptyData := nil;
			SetLength( vEmptyData, vEmptyBlobLen );
			InternalPush( vEmptyData, vEmptyBlobLen );
			mHead := Const_LeftMarginIndex;
			mTail := mRightMargin;
		end;
	end;

	if mVerbose then
	begin
		WriteLn( Format( 'Allocated new queue in %d ms; Capacity: %d', [ vStopwatch.ElapsedMilliseconds, mCapacity ] ) );
	end;
end;

procedure TBytesQueue.InternalPush( const ParaData : TBytes; ParaLen : Integer );
begin
	Move( ParaLen, mHeaderBuffer[0], 4 );
	InternalCopy( mHeaderBuffer, Const_HeaderEntrySize );
	InternalCopy( ParaData, ParaLen );

	if mTail > mHead then
	begin
		mRightMargin := mTail;
	end;

	Inc( mCount );
end;

procedure TBytesQueue.InternalCopy( const ParaData : TBytes; ParaLen : Integer );
begin
	Move( ParaData[0], mArray[mTail], ParaLen );
	mTail := mTail + ParaLen;
end;

function TBytesQueue.Pop : TBytes;
var
	vSize : Integer;
begin
	if not PeekInternal( mHead, vSize, Result ) then
	begin
		raise EQueueError.Create( 'Empty queue' );
	end;

	mHead := mHead + Const_HeaderEntrySize + vSize;
	Dec( mCount );

	if mHead = mRightMargin then
	begin
		mHead := Const_LeftMarginIndex;
		if mTail = mRightMargin then
		begin
			mTail := Const_LeftMarginIndex;
		end;
		mRightMargin := mTail;
	end;
end;

function TBytesQueue.Peek : TBytes;
var
	vSize : Integer;
begin
	if not PeekInternal( mHead, vSize, Result ) then
	begin
		raise EQueueError.Create( 'Empty queue' );
	end;
end;

function TBytesQueue.Get( ParaIndex : Integer ) : TBytes;
var
	vSize : Integer;
begin
	if not PeekInternal( ParaIndex, vSize, Result ) then
	begin
		raise EQueueError.Create( 'Invalid index' );
	end;
end;

function TBytesQueue.CheckGet( ParaIndex : Integer ) : Boolean;
var
	vSize : Integer;
	vData : TBytes;
begin
	Result := PeekInternal( ParaIndex, vSize, vData );
end;

function TBytesQueue.PeekInternal( ParaIndex : Integer; out ParaSize : Integer; out ParaData : TBytes ) : Boolean;
begin
	ParaData := nil;
	ParaSize := 0;
	
	if mCount = 0 then
	begin
		Exit( False );
	end;

	if ParaIndex <= 0 then
	begin
		Exit( False );
	end;

	if ParaIndex + Const_HeaderEntrySize >= Length( mArray ) then
	begin
		Exit( False );
	end;

	Move( mArray[ParaIndex], ParaSize, 4 );
	ParaData := Copy( mArray, ParaIndex + Const_HeaderEntrySize, ParaSize );
	Result := True;
end;

function TBytesQueue.AvailableSpaceAfterTail : Integer;
begin
	if mTail >= mHead then
	begin
		Result := mCapacity - mTail;
	end else
	begin
		Result := mHead - mTail - Const_MinimumEmptyBlobSize;
	end;
end;

function TBytesQueue.AvailableSpaceBeforeHead : Integer;
begin
	if mTail >= mHead then
	begin
		Result := mHead - Const_LeftMarginIndex - Const_MinimumEmptyBlobSize;
	end else
	begin
		Result := mHead - mTail - Const_MinimumEmptyBlobSize;
	end;
end;

end.
