unit Common.Db.Xleveldb.Iterator.Merged_iter;

interface

uses
	System.SysUtils,
	System.Classes,
	Common.Db.Xleveldb.Comparer,
	Common.Db.Xleveldb.Errors,
	Common.Db.Xleveldb.Iterator.Iter,
	Common.Db.Xleveldb.Util;

type
	TDir = ( dirReleased, dirSOI, dirEOI, dirBackward, dirForward );

	TMergedIterator = class( TInterfacedObject, IIterator, IErrorCallbackSetter )
	private
		mCmp : IComparer;
		mIters : TArray<IIterator>;
		mStrict : Boolean;
		mKeys : TArray<TBytes>;
		mIndex : Integer;
		mDir : TDir;
		mErr : Exception;
		mErrF : TErrorCallbackFunc;
		mReleaser : IReleaser;
		function IterErr( ParaIter : IIterator ) : Boolean;
		function NextInternal : Boolean;
		function PrevInternal : Boolean;
	public
		constructor Create( ParaIters : TArray<IIterator>; ParaCmp : IComparer; ParaStrict : Boolean );
		destructor Destroy; override;
		function Valid : Boolean;
		function First : Boolean;
		function Last : Boolean;
		function Seek( const ParaKey : TBytes ) : Boolean;
		function Next : Boolean;
		function Prev : Boolean;
		function Key : TBytes;
		function Value : TBytes;
		procedure Release;
		procedure SetReleaser( ParaReleaser : IReleaser );
		function Error : Exception;
		procedure SetErrorCallback( ParaF : TErrorCallbackFunc );
	end;

function NewMergedIterator( ParaIters : TArray<IIterator>; ParaCmp : IComparer; ParaStrict : Boolean ) : IIterator;

implementation

function AssertKey( ParaKey : TBytes ) : TBytes;
begin
	if ParaKey = nil then
	begin
		raise Exception.Create( 'leveldb/iterator: nil key' );
	end;
	Result := ParaKey;
end;

{ TMergedIterator }

constructor TMergedIterator.Create( ParaIters : TArray<IIterator>; ParaCmp : IComparer; ParaStrict : Boolean );
var
	vIndex : Integer;
begin
	inherited Create;
	mIters := ParaIters;
	mCmp := ParaCmp;
	mStrict := ParaStrict;
	SetLength( mKeys, Length( mIters ) );
	for vIndex := 0 to High( mIters ) do
	begin
		mKeys[vIndex] := nil;
	end;
end;

destructor TMergedIterator.Destroy;
begin
	Release;
	inherited Destroy;
end;

function TMergedIterator.IterErr( ParaIter : IIterator ) : Boolean;
var
	vE : Exception;
begin
	Result := False;
	vE := ParaIter.Error;
	if vE <> nil then
	begin
		if Assigned( mErrF ) then
		begin
			mErrF( vE );
		end;
		if mStrict or not IsCorrupted( vE ) then
		begin
			mErr := vE;
			Result := True;
		end;
	end;
end;

function TMergedIterator.Valid : Boolean;
begin
	Result := ( mErr = nil ) and ( mDir > dirEOI );
end;

function TMergedIterator.First : Boolean;
var
	vIndex : Integer;
begin
	Result := False;
	if mErr <> nil then
	begin
		exit;
	end;
	if mDir = dirReleased then
	begin
		mErr := ErrIterReleased;
		exit;
	end;

	for vIndex := 0 to High( mIters ) do
	begin
		if mIters[vIndex].First then
		begin
			mKeys[vIndex] := AssertKey( mIters[vIndex].Key )
		end
		else if IterErr( mIters[vIndex] ) then
		begin
			exit
		end
		else
		begin
			mKeys[vIndex] := nil;
		end;
	end;
	mDir := dirSOI;
	Result := NextInternal;
end;

function TMergedIterator.Last : Boolean;
var
	vIndex : Integer;
begin
	Result := False;
	if mErr <> nil then
	begin
		exit;
	end;
	if mDir = dirReleased then
	begin
		mErr := ErrIterReleased;
		exit;
	end;

	for vIndex := 0 to High( mIters ) do
	begin
		if mIters[vIndex].Last then
		begin
			mKeys[vIndex] := AssertKey( mIters[vIndex].Key )
		end
		else if IterErr( mIters[vIndex] ) then
		begin
			exit
		end
		else
		begin
			mKeys[vIndex] := nil;
		end;
	end;
	mDir := dirEOI;
	Result := PrevInternal;
end;

function TMergedIterator.Seek( const ParaKey : TBytes ) : Boolean;
var
	vIndex : Integer;
begin
	Result := False;
	if mErr <> nil then
	begin
		exit;
	end;
	if mDir = dirReleased then
	begin
		mErr := ErrIterReleased;
		exit;
	end;

	for vIndex := 0 to High( mIters ) do
	begin
		if mIters[vIndex].Seek( ParaKey ) then
		begin
			mKeys[vIndex] := AssertKey( mIters[vIndex].Key )
		end
		else if IterErr( mIters[vIndex] ) then
		begin
			exit
		end
		else
		begin
			mKeys[vIndex] := nil;
		end;
	end;
	mDir := dirSOI;
	Result := NextInternal;
end;

function TMergedIterator.NextInternal : Boolean;
var
	vKey : TBytes;
	vIndex : Integer;
begin
	vKey := nil;
	if mDir = dirForward then
	begin
		vKey := mKeys[mIndex];
	end;

	for vIndex := 0 to High( mKeys ) do
	begin
		if ( mKeys[vIndex] <> nil ) and ( ( vKey = nil ) or ( mCmp.Compare( mKeys[vIndex], vKey ) < 0 ) ) then
		begin
			vKey := mKeys[vIndex];
			mIndex := vIndex;
		end;
	end;

	if vKey = nil then
	begin
		mDir := dirEOI;
		Result := False;
	end
	else
	begin
		mDir := dirForward;
		Result := True;
	end;
end;

function TMergedIterator.Next : Boolean;
var
	vX : Integer;
	vIter : IIterator;
	vKey : TBytes;
begin
	Result := False;
	if ( mDir = dirEOI ) or ( mErr <> nil ) then
	begin
		exit;
	end;
	if mDir = dirReleased then
	begin
		mErr := ErrIterReleased;
		exit;
	end;

	case mDir of
		dirSOI :
			begin
				Result := First;
			end;
		dirBackward :
			begin
				SetLength( vKey, Length( mKeys[mIndex] ) );
				System.Move( mKeys[mIndex][0], vKey[0], Length( mKeys[mIndex] ) );
				if not Seek( vKey ) then
				begin
					exit;
				end;
				Result := Next;
			end;
		dirForward :
			begin
				vX := mIndex;
				vIter := mIters[vX];
				if vIter.Next then
				begin
					mKeys[vX] := AssertKey( vIter.Key )
				end
				else if IterErr( vIter ) then
				begin
					exit
				end
				else
				begin
					mKeys[vX] := nil;
				end;
				Result := NextInternal;
			end;
	end;
end;

function TMergedIterator.PrevInternal : Boolean;
var
	vKey : TBytes;
	vIndex : Integer;
begin
	vKey := nil;
	if mDir = dirBackward then
	begin
		vKey := mKeys[mIndex];
	end;

	for vIndex := 0 to High( mKeys ) do
	begin
		if ( mKeys[vIndex] <> nil ) and ( ( vKey = nil ) or ( mCmp.Compare( mKeys[vIndex], vKey ) > 0 ) ) then
		begin
			vKey := mKeys[vIndex];
			mIndex := vIndex;
		end;
	end;

	if vKey = nil then
	begin
		mDir := dirSOI;
		Result := False;
	end
	else
	begin
		mDir := dirBackward;
		Result := True;
	end;
end;

function TMergedIterator.Prev : Boolean;
var
	vX : Integer;
	vIter : IIterator;
	vKey : TBytes;
	vSeekResult : Boolean;
begin
	Result := False;
	if ( mDir = dirSOI ) or ( mErr <> nil ) then
	begin
		exit;
	end;
	if mDir = dirReleased then
	begin
		mErr := ErrIterReleased;
		exit;
	end;

	case mDir of
		dirEOI :
			begin
				Result := Last;
				exit;
			end;
		dirForward :
			begin
				SetLength( vKey, Length( mKeys[mIndex] ) );
				System.Move( mKeys[mIndex][0], vKey[0], Length( mKeys[mIndex] ) );
				for vX := 0 to High( mIters ) do
				begin
					if vX = mIndex then
					begin
						continue;
					end;
					vIter := mIters[vX];
					vSeekResult := vIter.Seek( vKey );
					if vSeekResult then
					begin
						if vIter.Prev then
						begin
							mKeys[vX] := AssertKey( vIter.Key )
						end
						else if IterErr( vIter ) then
						begin
							exit;
						end
						else
						begin
							mKeys[vX] := nil;
						end;
					end
					else
					begin
						if IterErr( vIter ) then
						begin
							exit;
						end;
						if vIter.Last then
						begin
							mKeys[vX] := AssertKey( vIter.Key )
						end
						else if IterErr( vIter ) then
						begin
							exit;
						end
						else
						begin
							mKeys[vX] := nil;
						end;
					end;
				end;
			end;
	end;

	vX := mIndex;
	vIter := mIters[vX];
	if vIter.Prev then
	begin
		mKeys[vX] := AssertKey( vIter.Key )
	end
	else if IterErr( vIter ) then
	begin
		exit
	end
	else
	begin
		mKeys[vX] := nil;
	end;
	Result := PrevInternal;
end;

function TMergedIterator.Key : TBytes;
begin
	if ( mErr <> nil ) or ( mDir <= dirEOI ) then
	begin
		Result := nil;
		exit;
	end;
	Result := mKeys[mIndex];
end;

function TMergedIterator.Value : TBytes;
begin
	if ( mErr <> nil ) or ( mDir <= dirEOI ) then
	begin
		Result := nil;
		exit;
	end;
	Result := mIters[mIndex].Value;
end;

procedure TMergedIterator.Release;
var
	vIndex : Integer;
begin
	if mDir <> dirReleased then
	begin
		mDir := dirReleased;
		for vIndex := 0 to High( mIters ) do
		begin
			mIters[vIndex].Release;
		end;
		mIters := nil;
		mKeys := nil;
		if mReleaser <> nil then
		begin
			mReleaser.Release;
			mReleaser := nil;
		end;
	end;
end;

procedure TMergedIterator.SetReleaser( ParaReleaser : IReleaser );
begin
	if mDir = dirReleased then
	begin
		raise EReleased.Create( '' );
	end;
	if ( mReleaser <> nil ) and ( ParaReleaser <> nil ) then
	begin
		raise EHasReleaser.Create( '' );
	end;
	mReleaser := ParaReleaser;
end;

function TMergedIterator.Error : Exception;
begin
	Result := mErr;
end;

procedure TMergedIterator.SetErrorCallback( ParaF : TErrorCallbackFunc );
begin
	mErrF := ParaF;
end;

function NewMergedIterator( ParaIters : TArray<IIterator>; ParaCmp : IComparer; ParaStrict : Boolean ) : IIterator;
begin
	Result := TMergedIterator.Create( ParaIters, ParaCmp, ParaStrict );
end;

end.