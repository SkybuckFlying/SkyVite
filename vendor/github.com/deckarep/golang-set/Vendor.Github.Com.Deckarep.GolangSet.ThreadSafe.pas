unit Vendor.Github.Com.Deckarep.GolangSet.ThreadSafe;

interface

uses
	System.Classes,
	System.SysUtils,
	System.SyncObjs,
	Vendor.Github.Com.Deckarep.GolangSet.Set,
	Vendor.Github.Com.Deckarep.GolangSet.ThreadUnsafe,
	Vendor.Github.Com.Deckarep.GolangSet.Iterator;

type
	TthreadSafeSet = class( TInterfacedObject, ISet )
	private
		mS : TthreadUnsafeSet;
		mLock : TLightweightMvx;
	public
		constructor Create;
		destructor Destroy; override;

		function Add( ParaI : TObject ) : Boolean;
		function Cardinality : Integer;
		procedure Clear;
		function Clone : ISet;
		function Contains( ParaI : array of TObject ) : Boolean;
		function Difference( ParaOther : ISet ) : ISet;
		function Equal( ParaOther : ISet ) : Boolean;
		function Intersect( ParaOther : ISet ) : ISet;
		function IsProperSubset( ParaOther : ISet ) : Boolean;
		function IsProperSuperset( ParaOther : ISet ) : Boolean;
		function IsSubset( ParaOther : ISet ) : Boolean;
		function IsSuperset( ParaOther : ISet ) : Boolean;
		procedure Each( ParaFunc : TFunc<TObject, Boolean> );
		function Iterator : TIterator;
		procedure Remove( ParaI : TObject );
		function ToString : string; override;
		function SymmetricDifference( ParaOther : ISet ) : ISet;
		function Union( ParaOther : ISet ) : ISet;
		function Pop : TObject;
		function PowerSet : ISet;
		function CartesianProduct( ParaOther : ISet ) : ISet;
		function ToSlice : TArray<TObject>;
	end;

implementation

constructor TthreadSafeSet.Create;
begin
	inherited Create;
	mS := TthreadUnsafeSet.Create;
	// TLightweightMvx doesn't need Create
end;

destructor TthreadSafeSet.Destroy;
begin
	mS.Free;
	inherited Destroy;
end;

function TthreadSafeSet.Add( ParaI : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		Result := mS.Add( ParaI );
	finally
		mLock.EndWrite;
	end;
end;

function TthreadSafeSet.Cardinality : Integer;
begin
	mLock.BeginRead;
	try
		Result := mS.Cardinality;
	finally
		mLock.EndRead;
	end;
end;

procedure TthreadSafeSet.Clear;
begin
	mLock.BeginWrite;
	try
		mS.Clear;
	finally
		mLock.EndWrite;
	end;
end;

function TthreadSafeSet.Clone : ISet;
var
	vNewSafe : TthreadSafeSet;
begin
	mLock.BeginRead;
	try
		vNewSafe := TthreadSafeSet.Create;
		vNewSafe.mS.Free;
		vNewSafe.mS := TthreadUnsafeSet( mS.Clone );
		Result := vNewSafe;
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Contains( ParaI : array of TObject ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.Contains( ParaI );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Difference( ParaOther : ISet ) : ISet;
begin
	// This would need careful locking of 'other' if it's also thread-safe
	mLock.BeginRead;
	try
		Result := mS.Difference( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Equal( ParaOther : ISet ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.Equal( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Intersect( ParaOther : ISet ) : ISet;
begin
	mLock.BeginRead;
	try
		Result := mS.Intersect( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.IsProperSubset( ParaOther : ISet ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.IsProperSubset( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.IsProperSuperset( ParaOther : ISet ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.IsProperSuperset( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.IsSubset( ParaOther : ISet ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.IsSubset( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.IsSuperset( ParaOther : ISet ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mS.IsSuperset( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

procedure TthreadSafeSet.Each( ParaFunc : TFunc<TObject, Boolean> );
begin
	mLock.BeginRead;
	try
		mS.Each( ParaFunc );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Iterator : TIterator;
begin
	// Note: It's hard to make Iterator thread-safe without holding the lock
	// Usually Iterators in thread-safe collections in Delphi take a snapshot or 
	// expect external synchronization.
	mLock.BeginRead;
	try
		Result := mS.Iterator;
	finally
		mLock.EndRead;
	end;
end;

procedure TthreadSafeSet.Remove( ParaI : TObject );
begin
	mLock.BeginWrite;
	try
		mS.Remove( ParaI );
	finally
		mLock.EndWrite;
	end;
end;

function TthreadSafeSet.ToString : string;
begin
	mLock.BeginRead;
	try
		Result := mS.ToString;
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.SymmetricDifference( ParaOther : ISet ) : ISet;
begin
	mLock.BeginRead;
	try
		Result := mS.SymmetricDifference( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Union( ParaOther : ISet ) : ISet;
begin
	mLock.BeginRead;
	try
		Result := mS.Union( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.Pop : TObject;
begin
	mLock.BeginWrite;
	try
		Result := mS.Pop;
	finally
		mLock.EndWrite;
	end;
end;

function TthreadSafeSet.PowerSet : ISet;
begin
	mLock.BeginRead;
	try
		Result := mS.PowerSet;
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.CartesianProduct( ParaOther : ISet ) : ISet;
begin
	mLock.BeginRead;
	try
		Result := mS.CartesianProduct( ParaOther );
	finally
		mLock.EndRead;
	end;
end;

function TthreadSafeSet.ToSlice : TArray<TObject>;
begin
	mLock.BeginRead;
	try
		Result := mS.ToSlice;
	finally
		mLock.EndRead;
	end;
end;

end.
