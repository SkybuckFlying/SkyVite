unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Cache;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Lru,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
	TNode = class;
	THandle = class;

	ICacher = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F7D}']
		function Capacity : Integer;
		procedure SetCapacity( ParaCapacity : Integer );
		procedure Promote( ParaN : TNode );
		procedure Ban( ParaN : TNode );
		procedure Evict( ParaN : TNode );
		procedure EvictNS( ParaNs : UInt64 );
		procedure EvictAll;
		procedure Close;
	end;

	TCache = class
	private
		mMu : TCriticalSection;
		mNodes : TDictionary<UInt64, TNode>; // Hash-based key
		mNodeCount : Integer;
		mSize : Integer;
		mCacher : ICacher;
		mClosed : Boolean;
		
		function Murmur32( ParaNs, ParaKey : UInt64; ParaSeed : UInt32 ) : UInt32;
		procedure DeleteNode( ParaN : TNode );
	public
		constructor Create( ParaCacher : ICacher );
		destructor Destroy; override;
		
		function Nodes : Integer;
		function Size : Integer;
		function Capacity : Integer;
		procedure SetCapacity( ParaCapacity : Integer );
		
		function Get( ParaNs, ParaKey : UInt64; ParaSetFunc : TFunc<TPair<Integer, Pointer>> ) : THandle;
		function Delete( ParaNs, ParaKey : UInt64; ParaOnDel : TProc ) : Boolean;
		function Evict( ParaNs, ParaKey : UInt64 ) : Boolean;
		procedure EvictNS( ParaNs : UInt64 );
		procedure EvictAll;
		procedure Close;
	end;

	TNode = class
	private
		mR : TCache;
		mHash : UInt32;
		mNs, mKeyRef : UInt64;
		mMu : TCriticalSection;
		mSize : Integer;
		mValue : Pointer;
		mRef : Integer;
		mOnDel : TList<TProc>;
		
		procedure Unref;
		procedure UnrefLocked;
	public
		mCacheData : Pointer;
		
		constructor Create( ParaR : TCache; ParaHash : UInt32; ParaNs, ParaKey : UInt64 );
		destructor Destroy; override;
		
		function NS : UInt64;
		function Key : UInt64;
		function Size : Integer;
		function Value : Pointer;
		function Ref : Integer;
		function GetHandle : THandle;
	end;

	THandle = class
	private
		mN : TNode;
	public
		constructor Create( ParaN : TNode );
		destructor Destroy; override;
		function Value : Pointer;
		procedure Release;
	end;

implementation

{ TCache }

constructor TCache.Create( ParaCacher : ICacher );
begin
	mMu := TCriticalSection.Create;
	mNodes := TDictionary<UInt64, TNode>.Create;
	mCacher := ParaCacher;
end;

destructor TCache.Destroy;
begin
	Close;
	mNodes.Free;
	mMu.Free;
	inherited;
end;

function TCache.Murmur32( ParaNs, ParaKey : UInt64; ParaSeed : UInt32 ) : UInt32;
const
	m = UInt32( $5BD1E995 );
	r = 24;
var
	k1, k2, k3, k4 : UInt32;
	h : UInt32;
begin
	k1 := UInt32( ParaNs shr 32 );
	k2 := UInt32( ParaNs );
	k3 := UInt32( ParaKey shr 32 );
	k4 := UInt32( ParaKey );

	k1 := k1 * m; k1 := k1 xor ( k1 shr r ); k1 := k1 * m;
	k2 := k2 * m; k2 := k2 xor ( k2 shr r ); k2 := k2 * m;
	k3 := k3 * m; k3 := k3 xor ( k3 shr r ); k3 := k3 * m;
	k4 := k4 * m; k4 := k4 xor ( k4 shr r ); k4 := k4 * m;

	h := ParaSeed;
	h := h * m; h := h xor k1;
	h := h * m; h := h xor k2;
	h := h * m; h := h xor k3;
	h := h * m; h := h xor k4;

	h := h xor ( h shr 13 ); h := h * m; h := h xor ( h shr 15 );
	Result := h;
end;

procedure TCache.DeleteNode( ParaN : TNode );
var
	vHashKey : UInt64;
	vDeleted : Boolean;
begin
	vHashKey := ( UInt64( ParaN.mHash ) shl 32 ) or ( ParaN.mNs xor ParaN.mKeyRef ); // Simplified combined key
	mMu.Enter;
	try
		vDeleted := mNodes.Remove( vHashKey );
		if vDeleted then
		begin
			Dec( mNodeCount );
			Dec( mSize, ParaN.mSize );
		end;
	finally
		mMu.Leave;
	end;
	
	if vDeleted then
	begin
		ParaN.Free;
	end;
end;

function TCache.Nodes : Integer;
begin
	Result := mNodeCount;
end;

function TCache.Size : Integer;
begin
	Result := mSize;
end;

function TCache.Capacity : Integer;
begin
	if mCacher <> nil then Result := mCacher.Capacity else Result := 0;
end;

procedure TCache.SetCapacity( ParaCapacity : Integer );
begin
	if mCacher <> nil then mCacher.SetCapacity( ParaCapacity );
end;

function TCache.Get( ParaNs, ParaKey : UInt64; ParaSetFunc : TFunc<TPair<Integer, Pointer>> ) : THandle;
var
	vHash : UInt32;
	vHashKey : UInt64;
	vNode : TNode;
	vRes : TPair<Integer, Pointer>;
begin
	vHash := Murmur32( ParaNs, ParaKey, $F00 );
	vHashKey := ( UInt64( vHash ) shl 32 ) or ( ParaNs xor ParaKey );
	
	mMu.Enter;
	try
		if mClosed then Exit( nil );
		
		if not mNodes.TryGetValue( vHashKey, vNode ) then
		begin
			if ParaSetFunc = nil then Exit( nil );
			
			vNode := TNode.Create( Self, vHash, ParaNs, ParaKey );
			mNodes.Add( vHashKey, vNode );
			Inc( mNodeCount );
		end;
		
		vNode.mMu.Enter;
		try
			Inc( vNode.mRef );
			if vNode.mValue = nil then
			begin
				if ParaSetFunc = nil then
				begin
					vNode.mMu.Leave; // Must leave before unref
					vNode.Unref; 
					Exit( nil );
				end;
				
				vRes := ParaSetFunc();
				vNode.mSize := vRes.Key;
				vNode.mValue := vRes.Value;
				
				if vNode.mValue = nil then
				begin
					vNode.mSize := 0;
					vNode.mMu.Leave;
					vNode.Unref;
					Exit( nil );
				end;
				Inc( mSize, vNode.mSize );
			end;
		finally
			vNode.mMu.Leave;
		end;
		
		if mCacher <> nil then mCacher.Promote( vNode );
		Result := THandle.Create( vNode );
	finally
		mMu.Leave;
	end;
end;

function TCache.Delete( ParaNs, ParaKey : UInt64; ParaOnDel : TProc ) : Boolean;
var
	vHash : UInt32;
	vHashKey : UInt64;
	vNode : TNode;
begin
	vHash := Murmur32( ParaNs, ParaKey, $F00 );
	vHashKey := ( UInt64( vHash ) shl 32 ) or ( ParaNs xor ParaKey );
	
	mMu.Enter;
	try
		if mClosed then Exit( False );
		if mNodes.TryGetValue( vHashKey, vNode ) then
		begin
			if ParaOnDel <> nil then
			begin
				vNode.mMu.Enter;
				vNode.mOnDel.Add( ParaOnDel );
				vNode.mMu.Leave;
			end;
			if mCacher <> nil then mCacher.Ban( vNode );
			vNode.Unref;
			Result := True;
		end
		else
		begin
			if ParaOnDel <> nil then ParaOnDel();
			Result := False;
		end;
	finally
		mMu.Leave;
	end;
end;

function TCache.Evict( ParaNs, ParaKey : UInt64 ) : Boolean;
var
	vHash : UInt32;
	vHashKey : UInt64;
	vNode : TNode;
begin
	vHash := Murmur32( ParaNs, ParaKey, $F00 );
	vHashKey := ( UInt64( vHash ) shl 32 ) or ( ParaNs xor ParaKey );
	
	mMu.Enter;
	try
		if mClosed then Exit( False );
		if mNodes.TryGetValue( vHashKey, vNode ) then
		begin
			if mCacher <> nil then mCacher.Evict( vNode );
			vNode.Unref;
			Result := True;
		end
		else
			Result := False;
	finally
		mMu.Leave;
	end;
end;

procedure TCache.EvictNS( ParaNs : UInt64 );
begin
	mMu.Enter;
	try
		if mClosed then Exit;
		if mCacher <> nil then mCacher.EvictNS( ParaNs );
	finally
		mMu.Leave;
	end;
end;

procedure TCache.EvictAll;
begin
	mMu.Enter;
	try
		if mClosed then Exit;
		if mCacher <> nil then mCacher.EvictAll;
	finally
		mMu.Leave;
	end;
end;

procedure TCache.Close;
var
	vNode : TNode;
begin
	mMu.Enter;
	try
		if not mClosed then
		begin
			mClosed := True;
			for vNode in mNodes.Values do
			begin
				vNode.mMu.Enter;
				try
					// Call releaser logic if vNode.mValue implements it
					// In this simplified version, we'll assume the onDel handlers deal with it
					vNode.mValue := nil;
				finally
					vNode.mMu.Leave;
				end;
			end;
		end;
	finally
		mMu.Leave;
	end;
	
	if mCacher <> nil then mCacher.Close;
end;

{ TNode }

constructor TNode.Create( ParaR : TCache; ParaHash : UInt32; ParaNs, ParaKey : UInt64 );
begin
	mR := ParaR;
	mHash := ParaHash;
	mNs := ParaNs;
	mKeyRef := ParaKey;
	mRef := 0; // Starts with 0, incremented in Get
	mMu := TCriticalSection.Create;
	mOnDel := TList<TProc>.Create;
end;

destructor TNode.Destroy;
var
	vProc : TProc;
begin
	for vProc in mOnDel do vProc();
	mOnDel.Free;
	mMu.Free;
	inherited;
end;

function TNode.NS : UInt64; begin Result := mNs; end;
function TNode.Key : UInt64; begin Result := mKeyRef; end;
function TNode.Size : Integer; begin Result := mSize; end;
function TNode.Value : Pointer; begin Result := mValue; end;
function TNode.Ref : Integer; begin Result := mRef; end;

function TNode.GetHandle : THandle;
begin
	mMu.Enter;
	try
		Inc( mRef );
		Result := THandle.Create( Self );
	finally
		mMu.Leave;
	end;
end;

procedure TNode.Unref;
begin
	mMu.Enter;
	try
		Dec( mRef );
		if mRef = 0 then
			mR.DeleteNode( Self );
	finally
		mMu.Leave;
	end;
end;

procedure TNode.UnrefLocked;
begin
	Unref; // Our implementation handles it via DeleteNode and mMu in TCache
end;

{ THandle }

constructor THandle.Create( ParaN : TNode );
begin
	mN := ParaN;
end;

destructor THandle.Destroy;
begin
	Release;
	inherited;
end;

function THandle.Value : Pointer;
begin
	if mN <> nil then Result := mN.Value else Result := nil;
end;

procedure THandle.Release;
begin
	if mN <> nil then
	begin
		mN.Unref;
		mN := nil;
	end;
end;

end.
