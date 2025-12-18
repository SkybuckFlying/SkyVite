unit Vendor.Github.Com.Deckarep.GolangSet.Set;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Deckarep.GolangSet.Iterator,
  Vendor.Github.Com.Deckarep.GolangSet.ThreadSafe,
  Vendor.Github.Com.Deckarep.GolangSet.ThreadUnsafe;

type
	ISet = interface;

	TIterator = class;

	ISet = interface
		['{4E1B3A0E-8C9B-4B7E-9D2A-F3B1A2C3D4E5}']
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
		function ToString : string;
		function SymmetricDifference( ParaOther : ISet ) : ISet;
		function Union( ParaOther : ISet ) : ISet;
		function Pop : TObject;
		function PowerSet : ISet;
		function CartesianProduct( ParaOther : ISet ) : ISet;
		function ToSlice : TArray<TObject>;
	end;

implementation

end.
