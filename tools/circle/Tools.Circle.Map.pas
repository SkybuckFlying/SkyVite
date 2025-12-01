unit Tools.Circle.Map;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Tools.Circle.Base, Tools.Circle.List;

type
  TTraverseFn = TFunc<TKey, TValue, Boolean>;

  IMap = interface
    ['{C1C2C3C4-C5C6-C7C8-C9CACBCCCDCE}']
    function Get(Key: TKey): TValue;
    function TryGetValue(Key: TKey; out Value: TValue): Boolean;
    procedure Put(Key: TKey; Value: TValue);
    procedure Traverse(Fn: TTraverseFn);
    function Size: Integer;
  end;

  TCircleMap = class(TInterfacedObject, IMap)
  private
    FM: TDictionary<TKey, TValue>;
    FL: IList;
  public
    constructor Create(Total: Integer);
    destructor Destroy; override;
    function Get(Key: TKey): TValue;
    function TryGetValue(Key: TKey; out Value: TValue): Boolean;
    procedure Put(Key: TKey; Value: TValue);
    procedure Traverse(Fn: TTraverseFn);
    function Size: Integer;
  end;

function NewMap(Total: Integer): IMap;

implementation

{ TCircleMap }

constructor TCircleMap.Create(Total: Integer);
begin
  FM := TDictionary<TKey, TValue>.Create(Total);
  FL := NewList(Total);
end;

destructor TCircleMap.Destroy;
begin
  FM.Free;
  inherited;
end;

function TCircleMap.Get(Key: TKey): TValue;
begin
  Result := FM[Key];
end;

function TCircleMap.TryGetValue(Key: TKey; out Value: TValue): Boolean;
begin
  Result := FM.TryGetValue(Key, Value);
end;

procedure TCircleMap.Put(Key: TKey; Value: TValue);
var
  Old: TKey;
begin
  if FM.ContainsKey(Key) then
  begin
    FM[Key] := Value;
    Exit;
  end;

  Old := FL.Put(Key);
  if Old <> nil then
    FM.Remove(Old);
  FM.Add(Key, Value);
end;

procedure TCircleMap.Traverse(Fn: TTraverseFn);
begin
  FL.Traverse(
    function(Key: TKey): Boolean
    var
      V: TValue;
    begin
      if FM.TryGetValue(Key, V) then
        Result := Fn(Key, V)
      else
        Result := True;
    end);
end;

function TCircleMap.Size: Integer;
begin
  Result := FL.Size;
end;

function NewMap(Total: Integer): IMap;
begin
  Result := TCircleMap.Create(Total);
end;

end.