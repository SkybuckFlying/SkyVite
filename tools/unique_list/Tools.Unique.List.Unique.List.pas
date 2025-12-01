unit tools.unique_list.unique_list;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TElement = class
  public
    Key: string;
    Next: TElement;
  end;

  IUniqueList = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    procedure Append(const Key: string; Data: TObject);
    function Shift(out Key: string; out Data: TObject): Boolean;
    procedure UnShift(const Key: string; Data: TObject);
    procedure Traverse(Handler: TFunc<string, TObject, Boolean>);
    procedure Filter(FilterFunc: TFunc<string, TObject, Boolean>);
    function Size: Integer;
    procedure Clear;
  end;

  TUniqueList = class(TInterfacedObject, IUniqueList)
  private
    FMap: TDictionary<string, TObject>;
    FHead: TElement;
    FTail: TElement;
    procedure Remove(Prev, Current: TElement);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(const Key: string; Data: TObject);
    function Shift(out Key: string; out Data: TObject): Boolean;
    procedure UnShift(const Key: string; Data: TObject);
    procedure Traverse(Handler: TFunc<string, TObject, Boolean>);
    procedure Filter(FilterFunc: TFunc<string, TObject, Boolean>);
    function Size: Integer;
    procedure Clear;
  end;

function NewUniqueList: IUniqueList;

implementation

{ TElement }

{ TUniqueList }

constructor TUniqueList.Create;
begin
  FMap := TDictionary<string, TObject>.Create;
  FHead := TElement.Create;
  FTail := FHead;
end;

destructor TUniqueList.Destroy;
begin
  Clear; // Clear elements and free TObjects if they are owned
  FHead.Free; // Free the head element
  FMap.Free;
  inherited;
end;

procedure TUniqueList.Append(const Key: string; Data: TObject);
var
  E: TElement;
begin
  if FMap.ContainsKey(Key) then
    Exit;

  FMap.Add(Key, Data);
  E := TElement.Create;
  E.Key := Key;

  FTail.Next := E;
  FTail := E;
end;

function TUniqueList.Shift(out Key: string; out Data: TObject): Boolean;
var
  E: TElement;
begin
  Result := False;
  Key := '';
  Data := nil;

  E := FHead.Next;
  if E = nil then
    Exit;

  Data := FMap[E.Key];
  Key := E.Key;

  Remove(FHead, E);
  E.Free; // Free the element node
  Result := True;
end;

procedure TUniqueList.UnShift(const Key: string; Data: TObject);
var
  E: TElement;
begin
  if FMap.ContainsKey(Key) then
    Exit;

  FMap.Add(Key, Data);

  E := TElement.Create;
  E.Key := Key;

  E.Next := FHead.Next;
  FHead.Next := E;

  if E.Next = nil then
    FTail := E;
end;

procedure TUniqueList.Remove(Prev, Current: TElement);
begin
  Prev.Next := Current.Next;
  if Current.Next = nil then
    FTail := Prev;

  FMap.Remove(Current.Key);
end;

procedure TUniqueList.Traverse(Handler: TFunc<string, TObject, Boolean>);
var
  Current: TElement;
begin
  Current := FHead.Next;
  while Current <> nil do
  begin
    if not Handler(Current.Key, FMap[Current.Key]) then
      Break;
    Current := Current.Next;
  end;
end;

procedure TUniqueList.Filter(FilterFunc: TFunc<string, TObject, Boolean>);
var
  Prev, Current, NextNode: TElement;
begin
  Prev := FHead;
  Current := FHead.Next;
  while Current <> nil do
  begin
    NextNode := Current.Next; // Store next before potential removal
    if FilterFunc(Current.Key, FMap[Current.Key]) then
    begin
      Remove(Prev, Current);
      Current.Free; // Free the element node
      Current := NextNode; // Move to the next node that was originally after the removed one
    end
    else
    begin
      Prev := Current;
      Current := NextNode;
    end;
  end;
end;

function TUniqueList.Size: Integer;
begin
  Result := FMap.Count;
end;

procedure TUniqueList.Clear;
var
  Current, NextNode: TElement;
begin
  Current := FHead.Next;
  while Current <> nil do
  begin
    NextNode := Current.Next;
    Current.Free;
    Current := NextNode;
  end;
  FMap.Clear;
  FHead.Next := nil;
  FTail := FHead;
end;

function NewUniqueList: IUniqueList;
begin
  Result := TUniqueList.Create;
end;

end.
