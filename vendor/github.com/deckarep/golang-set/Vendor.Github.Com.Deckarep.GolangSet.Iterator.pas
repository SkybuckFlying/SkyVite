unit Vendor.Github.Com.Deckarep.GolangSet.Iterator;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections;

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
