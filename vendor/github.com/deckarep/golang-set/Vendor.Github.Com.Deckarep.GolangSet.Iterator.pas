unit Vendor.Github.Com.Deckarep.GolangSet.Iterator;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Vendor.Github.Com.Deckarep.GolangSet.Set,
  Vendor.Github.Com.Deckarep.GolangSet.ThreadSafe,
  Vendor.Github.Com.Deckarep.GolangSet.ThreadUnsafe;

type
	TIterator = class
	private
		mSource : TEnumerable<TObject>;
		mEnumerator : TEnumerator<TObject>;
	public
		constructor Create( ParaSource : TEnumerable<TObject> );
		destructor Destroy; override;
		function Next( var ParaItem : TObject ) : Boolean;
	end;

implementation

constructor TIterator.Create( ParaSource : TEnumerable<TObject> );
begin
	inherited Create;
	mSource := ParaSource;
	mEnumerator := mSource.GetEnumerator;
end;

destructor TIterator.Destroy;
begin
	mEnumerator.Free;
	inherited Destroy;
end;

function TIterator.Next( var ParaItem : TObject ) : Boolean;
begin
	Result := mEnumerator.MoveNext;
	if Result then
		ParaItem := mEnumerator.Current;
end;

end.
