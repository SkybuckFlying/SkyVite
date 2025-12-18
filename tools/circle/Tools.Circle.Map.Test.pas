unit Tools.Circle.Map.Test;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  Tools.Circle.Base,
  Tools.Circle.List,
  Tools.Circle.List.Test,
  Tools.Circle.Map;

type
  [TestFixture]
  TCircleMapTests = class(TObject)
  public
    [Test]
    procedure TestCircleMap_Size;
    [Test]
    procedure TestCircleMap_Get;
    [Test]
    procedure TestCircleMap_Traverse;
  end;

implementation

{ TCircleMapTests }

procedure TCircleMapTests.TestCircleMap_Size;
const
  Total = 5;
var
  CM: IMap;
  I, J: Integer;
begin
  CM := NewMap(Total);

  for I := 1 to Total - 1 do
  begin
    J := 10 + I - 1;
    CM.Put(TObject(I), TObject(J));
    Assert.AreEqual(I, CM.Size, 'Size should match number of elements added');
  end;

  for I := 10 to Total + 10 - 1 do
  begin
    J := 10 + I - 1;
    CM.Put(TObject(I), TObject(J));
    Assert.AreEqual(Total, CM.Size, 'Size should be capped at total');
  end;
end;

procedure TCircleMapTests.TestCircleMap_Get;
const
  Total = 5;
var
  CM: IMap;
  I, J: Integer;
  Value: TValue;
  Ok: Boolean;
begin
  CM := NewMap(Total);

  // Add some elements
  for I := 1 to Total - 1 do
  begin
    J := 10 + I - 1;
    CM.Put(TObject(I), TObject(J));
  end;

  // Test getting existing elements
  for I := 1 to Total - 1 do
  begin
    J := 10 + I - 1;
    Ok := CM.TryGetValue(TObject(I), Value);
    Assert.IsTrue(Ok, Format('Value for key %d should exist', [I]));
    Assert.AreEqual(J, Integer(Value), Format('Value for key %d mismatch', [I]));
  end;

  // Test getting a non-existent element
  Ok := CM.TryGetValue(TObject(99), Value);
  Assert.IsFalse(Ok, 'Getting non-existent key should return false');

  // Test getting an element that was pushed out due to capacity
  CM.Put(TObject(Total), TObject(100)); // This will push out key 1
  Ok := CM.TryGetValue(TObject(1), Value);
  Assert.IsFalse(Ok, 'Key 1 should not exist after being pushed out');

  Ok := CM.TryGetValue(TObject(Total), Value);
  Assert.IsTrue(Ok, 'New key should exist');
  Assert.AreEqual(100, Integer(Value), 'New key value mismatch');
end;

procedure TCircleMapTests.TestCircleMap_Traverse;
const
  Total = 5;
var
  CM: IMap;
  I, J: Integer;
  K, V: Integer;
begin
  CM := NewMap(Total);

  for I := 1 to Total - 1 do
  begin
    J := 10 + I - 1;
    CM.Put(TObject(I), TObject(J));
  end;

  K := 1;
  V := 10;
  CM.Traverse(function(Key: TKey; Value: TValue): Boolean
  begin
    Assert.AreEqual(K, Integer(Key), 'Traverse key mismatch');
    Assert.AreEqual(V, Integer(Value), 'Traverse value mismatch');
    Inc(K);
    Inc(V);
    Result := True;
  end);

  for I := 5 to 9 do
  begin
    J := 10 + I - 5;
    CM.Put(TObject(I), TObject(J));
  end;

  K := 5;
  V := 10;
  CM.Traverse(function(Key: TKey; Value: TValue): Boolean
  begin
    Assert.AreEqual(K, Integer(Key), 'Traverse key mismatch after more puts');
    Assert.AreEqual(V, Integer(Value), 'Traverse value mismatch after more puts');
    Inc(K);
    Inc(V);
    Result := True;
  end);

  Assert.AreEqual(10, K, 'Final K mismatch');
  Assert.AreEqual(15, V, 'Final V mismatch');
end;

end.
