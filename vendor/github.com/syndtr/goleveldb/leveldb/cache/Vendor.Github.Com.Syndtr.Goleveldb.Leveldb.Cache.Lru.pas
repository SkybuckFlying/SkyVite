unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Lru;

interface

uses
	System.SysUtils,
	System.SyncObjs,
	System.Generics.Collections,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Cache;

type
	TLRUNode = class
	public
		N : TNode;
		H : THandle;
		Ban : Boolean;
		Next, Prev : TLRUNode;
		constructor Create( ParaN : TNode; ParaH : THandle; ParaBan : Boolean );
		procedure Insert( ParaAt : TLRUNode );
		procedure Remove;
	end;

	TLRU = class( TInterfacedObject, ICacher )
	private
		mMu : TCriticalSection;
		mCapacity : Integer;
		mUsed : Integer;
		mRecent : TLRUNode;
		procedure ResetRecent;
	public
		constructor Create( ParaCapacity : Integer );
		destructor Destroy; override;
		
		function Capacity : Integer;
		procedure SetCapacity( ParaCapacity : Integer );
		procedure Promote( ParaN : TNode );
		procedure Ban( ParaN : TNode );
		procedure Evict( ParaN : TNode );
		procedure EvictNS( ParaNs : UInt64 );
		procedure EvictAll;
		procedure Close;
	end;

function NewLRU( ParaCapacity : Integer ) : ICacher;

implementation

function NewLRU( ParaCapacity : Integer ) : ICacher;
begin
	Result := TLRU.Create( ParaCapacity );
end;

{ TLRUNode }

constructor TLRUNode.Create( ParaN : TNode; ParaH : THandle; ParaBan : Boolean );
begin
	N := ParaN;
	H := ParaH;
	Ban := ParaBan;
end;

procedure TLRUNode.Insert( ParaAt : TLRUNode );
var
	vX : TLRUNode;
begin
	vX := ParaAt.Next;
	ParaAt.Next := Self;
	Self.Prev := ParaAt;
	Self.Next := vX;
	vX.Prev := Self;
end;

procedure TLRUNode.Remove;
begin
	if Prev <> nil then
	begin
		Prev.Next := Next;
		Next.Prev := Prev;
		Prev := nil;
		Next := nil;
	end;
end;

{ TLRU }

constructor TLRU.Create( ParaCapacity : Integer );
begin
	mMu := TCriticalSection.Create;
	mCapacity := ParaCapacity;
	mRecent := TLRUNode.Create( nil, nil, False );
	ResetRecent;
end;

destructor TLRU.Destroy;
begin
	EvictAll;
	mRecent.Free;
	mMu.Free;
	inherited;
end;

procedure TLRU.ResetRecent;
begin
	mRecent.Next := mRecent;
	mRecent.Prev := mRecent;
	mUsed := 0;
end;

function TLRU.Capacity : Integer;
begin
	mMu.Enter;
	try
		Result := mCapacity;
	finally
		mMu.Leave;
	end;
end;

procedure TLRU.SetCapacity( ParaCapacity : Integer );
var
	vEvicted : TList<TLRUNode>;
	vRn : TLRUNode;
begin
	vEvicted := TList<TLRUNode>.Create;
	try
		mMu.Enter;
		try
			mCapacity := ParaCapacity;
			while mUsed > mCapacity do
			begin
				vRn := mRecent.Prev;
				if vRn = mRecent then Break;
				vRn.Remove;
				vRn.N.mCacheData := nil;
				Dec( mUsed, vRn.N.Size );
				vEvicted.Add( vRn );
			end;
		finally
			mMu.Leave;
		end;
		
		for vRn in vEvicted do
		begin
			vRn.H.Release;
			vRn.Free;
		end;
	finally
		vEvicted.Free;
	end;
end;

procedure TLRU.Promote( ParaN : TNode );
var
	vEvicted : TList<TLRUNode>;
	vRn : TLRUNode;
begin
	vEvicted := TList<TLRUNode>.Create;
	try
		mMu.Enter;
		try
			if ParaN.mCacheData = nil then
			begin
				if ParaN.Size <= mCapacity then
				begin
					vRn := TLRUNode.Create( ParaN, ParaN.GetHandle, False );
					vRn.Insert( mRecent );
					ParaN.mCacheData := vRn;
					Inc( mUsed, ParaN.Size );
					
					while mUsed > mCapacity do
					begin
						vRn := mRecent.Prev;
						if vRn = mRecent then Break;
						vRn.Remove;
						vRn.N.mCacheData := nil;
						Dec( mUsed, vRn.N.Size );
						vEvicted.Add( vRn );
					end;
				end;
			end
			else
			begin
				vRn := TLRUNode( ParaN.mCacheData );
				if not vRn.Ban then
				begin
					vRn.Remove;
					vRn.Insert( mRecent );
				end;
			end;
		finally
			mMu.Leave;
		end;
		
		for vRn in vEvicted do
		begin
			vRn.H.Release;
			vRn.Free;
		end;
	finally
		vEvicted.Free;
	end;
end;

procedure TLRU.Ban( ParaN : TNode );
var
	vRn : TLRUNode;
begin
	mMu.Enter;
	try
		if ParaN.mCacheData = nil then
		begin
			ParaN.mCacheData := TLRUNode.Create( ParaN, nil, True );
		end
		else
		begin
			vRn := TLRUNode( ParaN.mCacheData );
			if not vRn.Ban then
			begin
				vRn.Remove;
				vRn.Ban := True;
				Dec( mUsed, ParaN.Size );
				mMu.Leave;
				try
					vRn.H.Release;
					vRn.H := nil;
				finally
					mMu.Enter;
				end;
			end;
		end;
	finally
		mMu.Leave;
	end;
end;

procedure TLRU.Evict( ParaN : TNode );
var
	vRn : TLRUNode;
begin
	mMu.Enter;
	try
		vRn := TLRUNode( ParaN.mCacheData );
		if ( vRn = nil ) or vRn.Ban then Exit;
		ParaN.mCacheData := nil;
		Dec( mUsed, ParaN.Size );
		vRn.Remove;
	finally
		mMu.Leave;
	end;
	
	if vRn <> nil then
	begin
		vRn.H.Release;
		vRn.Free;
	end;
end;

procedure TLRU.EvictNS( ParaNs : UInt64 );
var
	vEvicted : TList<TLRUNode>;
	vE, vRn : TLRUNode;
begin
	vEvicted := TList<TLRUNode>.Create;
	try
		mMu.Enter;
		try
			vE := mRecent.Prev;
			while vE <> mRecent do
			begin
				vRn := vE;
				vE := vE.Prev;
				if vRn.N.NS = ParaNs then
				begin
					vRn.Remove;
					vRn.N.mCacheData := nil;
					Dec( mUsed, vRn.N.Size );
					vEvicted.Add( vRn );
				end;
			end;
		finally
			mMu.Leave;
		end;
		
		for vRn in vEvicted do
		begin
			vRn.H.Release;
			vRn.Free;
		end;
	finally
		vEvicted.Free;
	end;
end;

procedure TLRU.EvictAll;
var
	vEvicted : TList<TLRUNode>;
	vE, vRn : TLRUNode;
begin
	vEvicted := TList<TLRUNode>.Create;
	try
		mMu.Enter;
		try
			vE := mRecent.Prev;
			while vE <> mRecent do
			begin
				vRn := vE;
				vE := vE.Prev;
				vRn.Remove;
				vRn.N.mCacheData := nil;
				vEvicted.Add( vRn );
			end;
			mUsed := 0;
		finally
			mMu.Leave;
		end;
		
		for vRn in vEvicted do
		begin
			if vRn.H <> nil then vRn.H.Release;
			vRn.Free;
		end;
	finally
		vEvicted.Free;
	end;
end;

procedure TLRU.Close;
begin
	EvictAll;
end;

end.
