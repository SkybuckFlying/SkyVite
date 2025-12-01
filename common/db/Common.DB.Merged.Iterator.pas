unit Common.Db.MergedIterator;

interface

uses
	System.SysUtils,
	System.Generics.Collections,
	interfaces,
	common.db.xleveldb.comparer,
	common.db.xleveldb.errors,
  Common.Db.Globals;

const
	iterPointHead = 0;
	iterPointerMiddle = 1;
	iterPointTail = 2;

type
	TIsDeleteFunc = reference to function( ParaKey : TBytes ) : boolean;

	TMergedIterator = class(TInterfacedObject, IStorageIterator)
	private
		mCmp : IBasicComparer;
		mIsDelete : TIsDeleteFunc;
		mIters : TArray<IStorageIterator>;
		mIterStatus : TArray<byte>;
		mIndex : integer;
		mKeys : TArray<TBytes>;
		mPrevKey : TBytes;
		mError : Exception;
		mDirectionToNext : boolean;
		procedure Reset;
		function Step( ParaToNext : boolean ) : boolean;
	public
		constructor Create( ParaIters : TArray<IStorageIterator>; ParaIsDelete : TIsDeleteFunc );
		destructor Destroy; override;
		function Last : boolean;
		function Prev : boolean;
		function Next : boolean;
		function Seek( ParaKey : TBytes ) : boolean;
		function Key : TBytes;
		function Value : TBytes;
		function Error : Exception;
		procedure Release;
	end;

implementation

uses
  common.db.xleveldb.errors,
  Common.Utils;

{ TMergedIterator }

constructor TMergedIterator.Create( ParaIters : TArray<IStorageIterator>; ParaIsDelete : TIsDeleteFunc );
begin
	mCmp := DefaultComparer;
	mIsDelete := ParaIsDelete;
	mDirectionToNext := true;
	mIters := ParaIters;
	SetLength(mIterStatus, Length(mIters));
	SetLength(mKeys, Length(mIters));
  mIndex := -1;
  mPrevKey := nil;
end;

destructor TMergedIterator.Destroy;
begin
	Release;
	inherited;
end;

procedure TMergedIterator.Reset;
var
	vIndex : integer;
begin
	SetLength(mIterStatus, Length(mIters));
	for vIndex := 0 to High(mIterStatus) do
	begin
		mIterStatus[vIndex] := iterPointerMiddle;
	end;

	mIndex := -1;

	SetLength(mKeys, Length(mIters));
	mPrevKey := nil;
end;

function TMergedIterator.Last : boolean;
var
	vIndex : integer;
begin
	Reset;
	mDirectionToNext := false;

	for vIndex := 0 to High(mIters) do
	begin
		if mIters[vIndex].Last then
		begin
			mIterStatus[vIndex] := iterPointTail;
			mKeys[vIndex] := mIters[vIndex].Key;
		end
		else
		begin
			mIterStatus[vIndex] := iterPointHead;
		end;
	end;

	Result := Prev;
end;

function TMergedIterator.Prev : boolean;
begin
	Result := Step(false);
end;

function TMergedIterator.Next : boolean;
begin
	Result := Step(true);
end;

function TMergedIterator.Seek( ParaKey : TBytes ) : boolean;
var
	vIndex : integer;
	vFitKeyIndex : integer;
	vFitKey : TBytes;
	vIterOk : boolean;
	vCompareResult : integer;
begin
	Reset;
	mDirectionToNext := true;

	vFitKeyIndex := -1;
	vFitKey := nil;

	for vIndex := 0 to High(mIters) do
	begin
		vIterOk := mIters[vIndex].Seek(ParaKey);
		if not vIterOk then
		begin
			mIterStatus[vIndex] := iterPointTail;
			Continue;
		end;

		while vIterOk do
		begin
			if ( mIsDelete = nil ) or not mIsDelete(mIters[vIndex].Key) then
			begin
				break;
			end;
			vIterOk := mIters[vIndex].Next;
		end;

		if not vIterOk then
		begin
			mIterStatus[vIndex] := iterPointTail;
			Continue;
		end;

		mKeys[vIndex] := mIters[vIndex].Key;

		vCompareResult := mCmp.Compare(mKeys[vIndex], vFitKey);
		if ( vCompareResult < 0 ) or ( Length(vFitKey) <= 0 ) then
		begin
			vFitKey := mKeys[vIndex];
			vFitKeyIndex := vIndex;
		end;
	end;

	if vFitKeyIndex < 0 then
	begin
		mPrevKey := nil;
		Result := false;
		Exit;
	end;

	mIndex := vFitKeyIndex;
	mPrevKey := vFitKey;

	Result := true;
end;

function TMergedIterator.Key : TBytes;
begin
	if ( mError <> nil ) or ( mIndex < 0 ) then
	begin
		Result := nil;
	end
	else
	begin
		Result := mKeys[mIndex];
	end;
end;

function TMergedIterator.Value : TBytes;
begin
	if ( mIndex < 0 ) or ( Length(mKeys[mIndex]) <= 0 ) or ( mError <> nil ) then
	begin
		Result := nil;
	end
	else
	begin
		Result := mIters[mIndex].Value;
	end;
end;

function TMergedIterator.Error : Exception;
begin
	Result := mError;
end;

procedure TMergedIterator.Release;
var
	vIter : IStorageIterator;
begin
	for vIter in mIters do
	begin
		vIter.Release;
	end;
end;

function TMergedIterator.Step( ParaToNext : boolean ) : boolean;
var
	vIndex : integer;
	vFitKeyIndex : integer;
	vFitKey : TBytes;
	vCompareResult : integer;
begin
	if mError <> nil then
	begin
		Result := false;
		Exit;
	end;

	if ( mDirectionToNext and not ParaToNext ) or ( not mDirectionToNext and ParaToNext ) then
	begin
		Reset;
	end;

	if mIndex >= 0 then
	begin
		mKeys[mIndex] := nil;
		mIndex := -1;
	end;

	vFitKeyIndex := -1;
	vFitKey := nil;

	for vIndex := 0 to High(mIters) do
	begin
		if ( ParaToNext and ( mIterStatus[vIndex] = iterPointTail ) ) or ( not ParaToNext and ( mIterStatus[vIndex] = iterPointHead ) ) then
		begin
			Continue;
		end;

		while true do
		begin
			if mKeys[vIndex] = nil then
			begin
				if ( ParaToNext and not mIters[vIndex].Next ) or ( not ParaToNext and not mIters[vIndex].Prev ) then
				begin
					if ( mIters[vIndex].Error <> nil ) and (mIters[vIndex].Error <> ErrNotFound) then
					begin
						mError := mIters[vIndex].Error;
						Result := false;
						Exit;
					end;

					if ParaToNext then
					begin
						mIterStatus[vIndex] := iterPointTail;
					end
					else
					begin
						mIterStatus[vIndex] := iterPointHead;
					end;
					break;
				end;
				mKeys[vIndex] := mIters[vIndex].Key;
			end;

			if ( ( mIsDelete <> nil ) and mIsDelete(mKeys[vIndex]) ) or ( BytesEqual(mKeys[vIndex], mPrevKey) ) then
			begin
				mKeys[vIndex] := nil;
				Continue;
			end;

			break;
		end;

		if mKeys[vIndex] <> nil then
		begin
			vCompareResult := mCmp.Compare(mKeys[vIndex], vFitKey);
			if ( ParaToNext and ( vCompareResult < 0 ) ) or ( not ParaToNext and ( vCompareResult > 0 ) ) or ( Length(vFitKey) <= 0 ) then
			begin
				vFitKey := mKeys[vIndex];
				vFitKeyIndex := vIndex;
			end;
		end;
	end;

	if vFitKeyIndex < 0 then
	begin
		mPrevKey := nil;
		Result := false;
		Exit;
	end;

	mIndex := vFitKeyIndex;
	mPrevKey := vFitKey;

	Result := true;
end;

end.
