unit Common.Db.Xleveldb.Iterator.Indexed_iter;

interface

uses
	System.SysUtils,
	System.Classes,
	Common.Db.Xleveldb.Errors,
	Common.Db.Xleveldb.Iterator.Iter,
	Common.Db.Xleveldb.Util;

type
	{
		IIteratorIndexer is the interface that wraps ICommonIterator and basic Get
		method. IIteratorIndexer provides index for indexed iterator.
	}
	IIteratorIndexer = interface( ICommonIterator )
		[ '{5A82A1A0-4E5A-4F3C-9C08-026F5E84E1F1}' ]
		{
			Get returns a new data iterator for the current position, or nil if
			done.
		}
		function Get : IIterator;
	end;

	TErrorCallback = procedure( E : Exception ) of object;

	TIndexedIterator = class( TInterfacedObject, IIterator )
	private
		mBasicReleaser : TBasicReleaser;
		mIndex : IIteratorIndexer;
		mStrict : Boolean;
		mData : IIterator;
		mErr : Exception;
		mErrF : TErrorCallback;
		mClosed : Boolean;
		procedure SetData;
		procedure ClearData;
		procedure IndexErr;
		function DataErr : Boolean;
	public
		constructor Create( ParaIndex : IIteratorIndexer; ParaStrict : Boolean );
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
		procedure SetErrorCallback( ParaF : TErrorCallback );
	end;

function NewIndexedIterator( ParaIndex : IIteratorIndexer; ParaStrict : Boolean ) : IIterator;

implementation

{ TIndexedIterator }

constructor TIndexedIterator.Create( ParaIndex : IIteratorIndexer; ParaStrict : Boolean );
begin
	inherited Create;
	mBasicReleaser := TBasicReleaser.Create;
	mIndex := ParaIndex;
	mStrict := ParaStrict;
end;

destructor TIndexedIterator.Destroy;
begin
	ClearData;
	mIndex := nil;
	mBasicReleaser.Free;
	inherited Destroy;
end;

procedure TIndexedIterator.SetData;
begin
	if mData <> nil then
	begin
		mData := nil;
	end;
	mData := mIndex.Get;
end;

procedure TIndexedIterator.ClearData;
begin
	if mData <> nil then
	begin
		mData := nil;
	end;
end;

procedure TIndexedIterator.IndexErr;
var
	vE : Exception;
begin
	vE := mIndex.Error;
	if vE <> nil then
	begin
		if Assigned( mErrF ) then
		begin
			mErrF( vE );
		end;
		mErr := vE;
	end;
end;

function TIndexedIterator.DataErr : Boolean;
var
	vE : Exception;
begin
	Result := False;
	vE := mData.Error;
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

function TIndexedIterator.Valid : Boolean;
begin
	Result := ( mData <> nil ) and mData.Valid;
end;

function TIndexedIterator.First : Boolean;
begin
	if mErr <> nil then
	begin
		Result := False;
		exit;
	end;
	if mBasicReleaser.Released then
	begin
		mErr := EErrIterReleased.Create( '' );
		Result := False;
		exit;
	end;

	if not mIndex.First then
	begin
		IndexErr;
		ClearData;
		Result := False;
		exit;
	end;
	SetData;
	Result := Next;
end;

function TIndexedIterator.Last : Boolean;
begin
	if mErr <> nil then
	begin
		Result := False;
		exit;
	end;
	if mBasicReleaser.Released then
	begin
		mErr := EErrIterReleased.Create( '' );
		Result := False;
		exit;
	end;

	if not mIndex.Last then
	begin
		IndexErr;
		ClearData;
		Result := False;
		exit;
	end;
	SetData;
	if not mData.Last then
	begin
		if DataErr then
		begin
			Result := False;
			exit;
		end;
		ClearData;
		Result := Prev;
	end
	else
	begin
		Result := True;
	end;
end;

function TIndexedIterator.Seek( const ParaKey : TBytes ) : Boolean;
begin
	if mErr <> nil then
	begin
		Result := False;
		exit;
	end;
	if mBasicReleaser.Released then
	begin
		mErr := EErrIterReleased.Create( '' );
		Result := False;
		exit;
	end;

	if not mIndex.Seek( ParaKey ) then
	begin
		IndexErr;
		ClearData;
		Result := False;
		exit;
	end;
	SetData;
	if not mData.Seek( ParaKey ) then
	begin
		if DataErr then
		begin
			Result := False;
			exit;
		end;
		ClearData;
		Result := Next;
	end
	else
	begin
		Result := True;
	end;
end;

function TIndexedIterator.Next : Boolean;
begin
	if mErr <> nil then
	begin
		Result := false;
		Exit;
	end;
	if mBasicReleaser.Released then
	begin
		mErr := EErrIterReleased.Create( '' );
		Result := false;
		Exit;
	end;

	while True do
	begin
		if mData <> nil then
		begin
			if mData.Next then
			begin
				Result := True;
				Exit;
			end;

			if DataErr then
			begin
				Result := False;
				Exit;
			end;
			ClearData;
		end;

		if not mIndex.Next then
		begin
			IndexErr;
			Result := False;
			Exit;
		end;
		SetData;
	end;
end;

function TIndexedIterator.Prev : Boolean;
begin
	if mErr <> nil then
	begin
		Result := false;
		Exit;
	end;
	if mBasicReleaser.Released then
	begin
		mErr := EErrIterReleased.Create( '' );
		Result := false;
		Exit;
	end;

	while True do
	begin
		if mData <> nil then
		begin
			if mData.Prev then
			begin
				Result := True;
				Exit;
			end;

			if DataErr then
			begin
				Result := False;
				Exit;
			end;
			ClearData;
		end;

		if not mIndex.Prev then
		begin
			IndexErr;
			Result := False;
			Exit;
		end;
		SetData;
		if not mData.Last then
		begin
			if DataErr then
			begin
				Result := False;
				Exit;
			end;
			ClearData;
			// continue the loop
		end
		else
		begin
			Result := True;
			Exit;
		end;
	end;
end;

function TIndexedIterator.Key : TBytes;
begin
	if mData = nil then
	begin
		Result := nil;
		exit;
	end;
	Result := mData.Key;
end;

function TIndexedIterator.Value : TBytes;
begin
	if mData = nil then
	begin
		Result := nil;
		exit;
	end;
	Result := mData.Value;
end;

procedure TIndexedIterator.Release;
begin
	ClearData;
	if mIndex <> nil then
	begin
		mIndex.Release;
		mIndex := nil;
	end;
	mBasicReleaser.Release;
end;

procedure TIndexedIterator.SetReleaser( ParaReleaser : IReleaser );
begin
	mBasicReleaser.SetReleaser( ParaReleaser );
end;

function TIndexedIterator.Error : Exception;
begin
	if mErr <> nil then
	begin
		Result := mErr;
		exit;
	end;
	if ( mIndex <> nil ) and ( mIndex.Error <> nil ) then
	begin
		Result := mIndex.Error;
		exit;
	end;
	Result := nil;
end;

procedure TIndexedIterator.SetErrorCallback( ParaF : TErrorCallback );
begin
	mErrF := ParaF;
end;

function NewIndexedIterator( ParaIndex : IIteratorIndexer; ParaStrict : Boolean ) : IIterator;
begin
	Result := TIndexedIterator.Create( ParaIndex, ParaStrict );
end;

end.