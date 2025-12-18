unit Tools.Circle.List;

interface

uses
  System.SysUtils System.Classes Tools.Circle.Base,
  Tools.Circle.Base,
  Tools.Circle.List.Test,
  Tools.Circle.Map,
  Tools.Circle.Map.Test;

type
  IList = interface
    ['{B1B2B3B4-B5B6-B7B8-B9BA-BCBDBEBFC0C1}']
    function Size: Integer;
    function Put(Key: TKey): TKey;
    procedure Traverse(Fn: TFunc<TKey, Boolean>);
    procedure TraverseR(Fn: TFunc<TKey, Boolean>);
    procedure Reset;
  end;

  TList = class(TInterfacedObject, IList)
  private
    FFront: Integer;
    FRear: Integer;
    FTotal: Integer;
    FL: TArray<TKey>;
  public
    constructor Create(Total: Integer);
    function Size: Integer;
    function Put(Key: TKey): TKey;
    procedure Traverse(Fn: TFunc<TKey, Boolean>);
    procedure TraverseR(Fn: TFunc<TKey, Boolean>);
    procedure Reset;
  end;

function NewList(Total: Integer): IList;

implementation

{ TList }

constructor TList.Create(Total: Integer);
begin
  FFront := 0;
  FRear := 0;
  FTotal := Total + 1;
  SetLength(FL, FTotal);
end;

function TList.Size: Integer;
begin
  Result := (FRear - FFront + FTotal) mod FTotal;
end;

function TList.Put(Key: TKey): TKey;
begin
  Result := nil;
  if (FRear + 1) mod FTotal = FFront then
  begin
    Result := FL[FFront];
    FFront := (FFront + 1) mod FTotal;
  end;
  FL[FRear] := Key;
  FRear := (FRear + 1) mod FTotal;
end;

procedure TList.Traverse(Fn: TFunc<TKey, Boolean>);
var
  I: Integer;
begin
  I := FFront;
  while I <> FRear do
  begin
    if not Fn(FL[I]) then
      Break;
    I := (I + 1) mod FTotal;
  end;
end;

procedure TList.TraverseR(Fn: TFunc<TKey, Boolean>);
var
  I, Index: Integer;
begin
  I := FRear;
  while I <> FFront do
  begin
    Index := (I - 1 + FTotal) mod FTotal;
    if not Fn(FL[Index]) then
      Break;
    I := Index;
  end;
end;

procedure TList.Reset;
begin
  FFront := 0;
  FRear := 0;
end;

function NewList(Total: Integer): IList;
begin
  Result := TList.Create(Total);
end;

end.
