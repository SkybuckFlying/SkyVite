unit Vendor.Github.Com.Deckarep.GolangSet.ThreadUnsafe;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  Vendor.Github.Com.Deckarep.GolangSet.Iterator,
  Vendor.Github.Com.Deckarep.GolangSet.Set,
  Vendor.Github.Com.Deckarep.GolangSet.ThreadSafe;

type
	TthreadUnsafeSet = class( TInterfacedObject, ISet )
	private
		mMap : TDictionary<TObject, Pointer>;
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

constructor TthreadUnsafeSet.Create;
begin
	inherited Create;
	mMap := TDictionary<TObject, Pointer>.Create;
end;

destructor TthreadUnsafeSet.Destroy;
begin
	mMap.Free;
	inherited Destroy;
end;

function TthreadUnsafeSet.Add( ParaI : TObject ) : Boolean;
begin
	if mMap.ContainsKey( ParaI ) then
		Exit( False );
	mMap.Add( ParaI, nil );
	Result := True;
end;

function TthreadUnsafeSet.Cardinality : Integer;
begin
	Result := mMap.Count;
end;

procedure TthreadUnsafeSet.Clear;
begin
	mMap.Clear;
end;

function TthreadUnsafeSet.Clone : ISet;
var
	vNewSet : TthreadUnsafeSet;
	vItem : TObject;
begin
	vNewSet := TthreadUnsafeSet.Create;
	for vItem in mMap.Keys do
		vNewSet.Add( vItem );
	Result := vNewSet;
end;

function TthreadUnsafeSet.Contains( ParaI : array of TObject ) : Boolean;
var
	vItem : TObject;
begin
	for vItem in ParaI do
		if not mMap.ContainsKey( vItem ) then
			Exit( False );
	Result := True;
end;

function TthreadUnsafeSet.Difference( ParaOther : ISet ) : ISet;
var
	vDiff : TthreadUnsafeSet;
	vItem : TObject;
begin
	vDiff := TthreadUnsafeSet.Create;
	for vItem in mMap.Keys do
		if not ParaOther.Contains( [ vItem ] ) then
			vDiff.Add( vItem );
	Result := vDiff;
end;

function TthreadUnsafeSet.Equal( ParaOther : ISet ) : Boolean;
var
	vItem : TObject;
begin
	if Cardinality <> ParaOther.Cardinality then
		Exit( False );
	for vItem in mMap.Keys do
		if not ParaOther.Contains( [ vItem ] ) then
			Exit( False );
	Result := True;
end;

function TthreadUnsafeSet.Intersect( ParaOther : ISet ) : ISet;
var
	vIntersect : TthreadUnsafeSet;
	vItem : TObject;
begin
	vIntersect := TthreadUnsafeSet.Create;
	for vItem in mMap.Keys do
		if ParaOther.Contains( [ vItem ] ) then
			vIntersect.Add( vItem );
	Result := vIntersect;
end;

function TthreadUnsafeSet.IsProperSubset( ParaOther : ISet ) : Boolean;
begin
	Result := IsSubset( ParaOther ) and not Equal( ParaOther );
end;

function TthreadUnsafeSet.IsProperSuperset( ParaOther : ISet ) : Boolean;
begin
	Result := IsSuperset( ParaOther ) and not Equal( ParaOther );
end;

function TthreadUnsafeSet.IsSubset( ParaOther : ISet ) : Boolean;
var
	vItem : TObject;
begin
	for vItem in mMap.Keys do
		if not ParaOther.Contains( [ vItem ] ) then
			Exit( False );
	Result := True;
end;

function TthreadUnsafeSet.IsSuperset( ParaOther : ISet ) : Boolean;
begin
	Result := ParaOther.IsSubset( Self );
end;

procedure TthreadUnsafeSet.Each( ParaFunc : TFunc<TObject, Boolean> );
var
	vItem : TObject;
begin
	for vItem in mMap.Keys do
		if ParaFunc( vItem ) then
			Break;
end;

function TthreadUnsafeSet.Iterator : TIterator;
begin
	Result := TIterator.Create( mMap.Keys );
end;

procedure TthreadUnsafeSet.Remove( ParaI : TObject );
begin
	mMap.Remove( ParaI );
end;

function TthreadUnsafeSet.ToString : string;
var
	vItems : TStringList;
	vItem : TObject;
begin
	vItems := TStringList.Create;
	try
		for vItem in mMap.Keys do
			vItems.Add( vItem.ToString );
		Result := 'Set{' + vItems.CommaText + '}';
	finally
		vItems.Free;
	end;
end;

function TthreadUnsafeSet.SymmetricDifference( ParaOther : ISet ) : ISet;
begin
	Result := Difference( ParaOther ).Union( ParaOther.Difference( Self ) );
end;

function TthreadUnsafeSet.Union( ParaOther : ISet ) : ISet;
var
	vUnion : TthreadUnsafeSet;
	vItem : TObject;
	vOtherSlice : TArray<TObject>;
begin
	vUnion := TthreadUnsafeSet( Clone );
	vOtherSlice := ParaOther.ToSlice;
	for vItem in vOtherSlice do
		vUnion.Add( vItem );
	Result := vUnion;
end;

function TthreadUnsafeSet.Pop : TObject;
var
	vItem : TObject;
begin
	Result := nil;
	for vItem in mMap.Keys do
	begin
		Result := vItem;
		mMap.Remove( vItem );
		Break;
	end;
end;

function TthreadUnsafeSet.PowerSet : ISet;
begin
	// Simplified PowerSet
	Result := nil;
end;

function TthreadUnsafeSet.CartesianProduct( ParaOther : ISet ) : ISet;
begin
	// Simplified CartesianProduct
	Result := nil;
end;

function TthreadUnsafeSet.ToSlice : TArray<TObject>;
begin
	Result := mMap.Keys.ToArray;
end;

end.
