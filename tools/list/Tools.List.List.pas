unit Tools.List.List;

interface

uses
  System.SysUtils, System.Classes;

type
  TElement = class
  public
    Value: TObject;
    Next: TElement;
  end;

  IList = interface
    ['{D1D2D3D4-D5D6-D7D8-D9DADBDCDEDF}']
    procedure Append(Data: TObject);
    function Shift: TObject;
    procedure UnShift(Data: TObject);
    procedure Remove(Prev, Current: TElement);
    procedure Traverse(Handler: TFunc<TObject, Boolean>);
    procedure Filter(FilterFunc: TFunc<TObject, Boolean>);
    function Size: Integer;
    procedure Clear;
  end;

  TList = class(TInterfacedObject, IList)
  private
    FHead: TElement;
    FTail: TElement;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(Data: TObject);
    function Shift: TObject;
    procedure UnShift(Data: TObject);
    procedure Remove(Prev, Current: TElement);
    procedure Traverse(Handler: TFunc<TObject, Boolean>);
    procedure Filter(FilterFunc: TFunc<TObject, Boolean>);
    function Size: Integer;
    procedure Clear;
  end;

function New: IList;

implementation

{ TList }

constructor TList.Create;
begin
  FHead := TElement.Create;
  FTail := FHead;
end;

destructor TList.Destroy;
begin
  Clear;
  FHead.Free;
  inherited;
end;

procedure TList.Append(Data: TObject);
var
  E: TElement;
begin
  E := TElement.Create;
  E.Value := Data;
  FTail.Next := E;
  FTail := E;
  Inc(FCount);
end;

function TList.Shift: TObject;
var
  E: TElement;
begin
  E := FHead.Next;
  if E = nil then
    Exit(nil);
  Remove(FHead, E);
  Result := E.Value;
  E.Free;
end;

procedure TList.UnShift(Data: TObject);
var
  E: TElement;
begin
  E := TElement.Create;
  E.Value := Data;
  E.Next := FHead.Next;
  FHead.Next := E;
  if E.Next = nil then
    FTail := E;
  Inc(FCount);
end;

procedure TList.Remove(Prev, Current: TElement);
begin
  Prev.Next := Current.Next;
  if Current.Next = nil then
    FTail := Prev;
  Dec(FCount);
end;

procedure TList.Traverse(Handler: TFunc<TObject, Boolean>);
var
  Current: TElement;
begin
  Current := FHead.Next;
  while Current <> nil do
  begin
    if not Handler(Current.Value) then
      Break;
    Current := Current.Next;
  end;
end;

procedure TList.Filter(FilterFunc: TFunc<TObject, Boolean>);
var
  Prev, Current: TElement;
begin
  Prev := FHead;
  Current := FHead.Next;
  while Current <> nil do
  begin
    if FilterFunc(Current.Value) then
    begin
      Remove(Prev, Current);
      Current.Free;
      Current := Prev.Next;
    end
    else
    begin
      Prev := Current;
      Current := Current.Next;
    end;
  end;
end;

function TList.Size: Integer;
begin
  Result := FCount;
end;

procedure TList.Clear;
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
  FHead.Next := nil;
  FTail := FHead;
  FCount := 0;
end;

function New: IList;
begin
  Result := TList.Create;
end;

end.