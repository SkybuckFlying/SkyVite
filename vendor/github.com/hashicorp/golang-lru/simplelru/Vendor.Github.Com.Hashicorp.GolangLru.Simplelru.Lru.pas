unit Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.Lru;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface;

type
	TEvictCallback = procedure( ParaKey, ParaValue : TObject ) of object;

	TEntry = class
	public
		mKey   : TObject;
		mValue : TObject;
		constructor Create( ParaKey, ParaValue : TObject );
	end;

	TLRU = class( TInterfacedObject, ILRUCache )
	private
		mSize      : Integer;
		mEvictList : TLinkedList<TEntry>;
		mItems     : TDictionary<TObject, TLinkedListNode<TEntry>>;
		mOnEvict   : TEvictCallback;

		procedure RemoveElement( ParaE : TLinkedListNode<TEntry> );
		procedure RemoveOldestInternal;
	public
		constructor Create( ParaSize : Integer; ParaOnEvict : TEvictCallback );
		destructor Destroy; override;

		function Add( ParaKey, ParaValue : TObject ) : Boolean;
		function Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Contains( ParaKey : TObject ) : Boolean;
		function Peek( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Remove( ParaKey : TObject ) : Boolean;
		function RemoveOldest( out ParaKey, ParaValue : TObject ) : Boolean;
		function GetOldest( out ParaKey, ParaValue : TObject ) : Boolean;
		function Keys : TArray<TObject>;
		function Len : Integer;
		procedure Purge;
		function Resize( ParaSize : Integer ) : Integer;
	end;

implementation

{ TEntry }

constructor TEntry.Create( ParaKey, ParaValue : TObject );
begin
	inherited Create;
	mKey := ParaKey;
	mValue := ParaValue;
end;

{ TLRU }

constructor TLRU.Create( ParaSize : Integer; ParaOnEvict : TEvictCallback );
begin
	inherited Create;
	mSize := ParaSize;
	mEvictList := TLinkedList<TEntry>.Create;
	mItems := TDictionary<TObject, TLinkedListNode<TEntry>>.Create;
	mOnEvict := ParaOnEvict;
end;

destructor TLRU.Destroy;
begin
	Purge;
	mItems.Free;
	mEvictList.Free;
	inherited;
end;

procedure TLRU.Purge;
var
	vNode : TLinkedListNode<TEntry>;
begin
	while mEvictList.Count > 0 do
	begin
		vNode := mEvictList.First;
		RemoveElement( vNode );
	end;
end;

function TLRU.Add( ParaKey, ParaValue : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
	vEvict : Boolean;
begin
	if mItems.TryGetValue( ParaKey, vNode ) then
	begin
		mEvictList.Remove( vNode );
		mEvictList.AddFirst( vNode );
		vNode.Value.mValue := ParaValue;
		Exit( False );
	end;

	vNode := mEvictList.AddFirst( TEntry.Create( ParaKey, ParaValue ) );
	mItems.Add( ParaKey, vNode );

	vEvict := mEvictList.Count > mSize;
	if vEvict then
		RemoveOldestInternal;
	Result := vEvict;
end;

function TLRU.Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
begin
	if mItems.TryGetValue( ParaKey, vNode ) then
	begin
		mEvictList.Remove( vNode );
		mEvictList.AddFirst( vNode );
		ParaValue := vNode.Value.mValue;
		Exit( True );
	end;
	ParaValue := nil;
	Result := False;
end;

function TLRU.Contains( ParaKey : TObject ) : Boolean;
begin
	Result := mItems.ContainsKey( ParaKey );
end;

function TLRU.Peek( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
begin
	if mItems.TryGetValue( ParaKey, vNode ) then
	begin
		ParaValue := vNode.Value.mValue;
		Exit( True );
	end;
	ParaValue := nil;
	Result := False;
end;

function TLRU.Remove( ParaKey : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
begin
	if mItems.TryGetValue( ParaKey, vNode ) then
	begin
		RemoveElement( vNode );
		Exit( True );
	end;
	Result := False;
end;

function TLRU.RemoveOldest( out ParaKey, ParaValue : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
begin
	vNode := mEvictList.Last;
	if vNode <> nil then
	begin
		ParaKey := vNode.Value.mKey;
		ParaValue := vNode.Value.mValue;
		RemoveElement( vNode );
		Exit( True );
	end;
	ParaKey := nil;
	ParaValue := nil;
	Result := False;
end;

function TLRU.GetOldest( out ParaKey, ParaValue : TObject ) : Boolean;
var
	vNode : TLinkedListNode<TEntry>;
begin
	vNode := mEvictList.Last;
	if vNode <> nil then
	begin
		ParaKey := vNode.Value.mKey;
		ParaValue := vNode.Value.mValue;
		Exit( True );
	end;
	ParaKey := nil;
	ParaValue := nil;
	Result := False;
end;

function TLRU.Keys : TArray<TObject>;
var
	vNode : TLinkedListNode<TEntry>;
	vI : Integer;
begin
	SetLength( Result, mEvictList.Count );
	vI := 0;
	vNode := mEvictList.Last;
	while vNode <> nil do
	begin
		Result[ vI ] := vNode.Value.mKey;
		Inc( vI );
		vNode := vNode.Previous;
	end;
end;

function TLRU.Len : Integer;
begin
	Result := mEvictList.Count;
end;

function TLRU.Resize( ParaSize : Integer ) : Integer;
var
	vDiff : Integer;
	vI : Integer;
begin
	vDiff := mEvictList.Count - ParaSize;
	if vDiff < 0 then
		vDiff := 0;
	for vI := 0 to vDiff - 1 do
		RemoveOldestInternal;
	mSize := ParaSize;
	Result := vDiff;
end;

procedure TLRU.RemoveOldestInternal;
var
	vNode : TLinkedListNode<TEntry>;
begin
	vNode := mEvictList.Last;
	if vNode <> nil then
		RemoveElement( vNode );
end;

procedure TLRU.RemoveElement( ParaE : TLinkedListNode<TEntry> );
var
	vEntry : TEntry;
begin
	vEntry := ParaE.Value;
	mItems.Remove( vEntry.mKey );
	mEvictList.Remove( ParaE );
	if Assigned( mOnEvict ) then
		mOnEvict( vEntry.mKey, vEntry.mValue );
	vEntry.Free;
end;

end.
