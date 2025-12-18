unit Vendor.Github.Com.GolangCollections.Collections.Stack.Stack;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections;

type
	TStack = class
	private
		mList : TList<Pointer>;
	public
		constructor Create;
		destructor Destroy; override;

		procedure Push( ParaValue : Pointer );
		function Pop : Pointer;
		function Peek : Pointer;
		function Len : Integer;
	end;

implementation

{ TStack }

constructor TStack.Create;
begin
	inherited Create;
	mList := TList<Pointer>.Create;
end;

destructor TStack.Destroy;
begin
	mList.Free;
	inherited;
end;

procedure TStack.Push( ParaValue : Pointer );
begin
	mList.Add( ParaValue );
end;

function TStack.Pop : Pointer;
begin
	if mList.Count = 0 then
		Exit( nil );
	Result := mList[ mList.Count - 1 ];
	mList.Delete( mList.Count - 1 );
end;

function TStack.Peek : Pointer;
begin
	if mList.Count = 0 then
		Exit( nil );
	Result := mList[ mList.Count - 1 ];
end;

function TStack.Len : Integer;
begin
	Result := mList.Count;
end;

end.
