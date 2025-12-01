unit Tools.Circle.List.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Diagnostics,
  Tools.Circle.Base,
  Tools.Circle.List;

type
  [TestFixture]
  TListTests = class(TObject)
  public
    [Test]
    procedure TestList_Put;
    [Test]
    procedure TestList_Size;
    [Test]
    procedure TestList_Traverse;
    [Test]
    procedure TestList_TraverseR;
    [Test]
    procedure TestList_Reset;
    [Test]
    procedure TestList_Put_Concurrent;
  end;

implementation

{ TListTests }

procedure TListTests.TestList_Put;
var
  L: IList;
  I: Integer;
  Old: TKey;
  V: Integer;
begin
  L := NewList(3);
  for I := 1 to 3 do
  begin
    Old := L.Put(TObject(I));
    if Old <> nil then
      Fail('should be nil');
  end;

  Assert.AreEqual(3, L.Size, 'wrong size');

  Old := L.Put(TObject(4));
  Assert.IsNotNull(Old, 'Old should not be nil');
  V := Integer(Old);
  Assert.AreEqual(1, V, 'wrong old value');

  Old := L.Put(TObject(5));
  Assert.IsNotNull(Old, 'Old should not be nil');
  V := Integer(Old);
  Assert.AreEqual(2, V, 'wrong old value');

  Assert.AreEqual(3, L.Size, 'wrong size after more puts');
end;

procedure TListTests.TestList_Size;
var
  L: IList;
  I: Integer;
begin
  L := NewList(3);

  Assert.AreEqual(0, L.Size, 'initial size should be 0');

  for I := 1 to 3 do
  begin
    L.Put(TObject(I));
    Assert.AreEqual(I, L.Size, 'size should increment');
  end;

  for I := 1 to 3 do
  begin
    L.Put(TObject(I));
    Assert.AreEqual(3, L.Size, 'size should remain max');
  end;
end;

procedure TListTests.TestList_Traverse;
const
  Total = 3;
  Count = 10;
var
  L: IList;
  I: Integer;
  StartVal: Integer;
  Value: Integer;
begin
  L := NewList(Total);
  for I := 1 to Count - 1 do
  begin
    L.Put(TObject(I));
  end;

  StartVal := Count - Total;
  Value := 0;
  L.Traverse(function(Key: TKey): Boolean
  begin
    Value := Integer(Key);
    Assert.AreEqual(StartVal, Value, 'traverse value mismatch');
    Inc(StartVal);
    Result := True;
  end);

  Assert.AreEqual(Count - 1, Value, 'last traversed value mismatch');
end;

procedure TListTests.TestList_TraverseR;
const
  Total = 3;
  Count = 10;
var
  L: IList;
  I: Integer;
  StartVal: Integer;
  Value: Integer;
begin
  L := NewList(Total);
  for I := 1 to Count - 1 do
  begin
    L.Put(TObject(I));
  end;

  StartVal := Count - 1;
  Value := 0;
  L.TraverseR(function(Key: TKey): Boolean
  begin
    Value := Integer(Key);
    Assert.AreEqual(StartVal, Value, 'traverseR value mismatch');
    Dec(StartVal);
    Result := True;
  end);

  Assert.AreEqual(Count - Total, Value, 'last traversedR value mismatch');
end;

procedure TListTests.TestList_Reset;
const
  Total = 3;
  Count = 10;
var
  L: IList;
  I: Integer;
  K: Integer;
begin
  L := NewList(Total);
  for I := 1 to Count - 1 do
  begin
    L.Put(TObject(I));
  end;

  L.Reset;

  K := 0;
  L.Traverse(function(Key: TKey): Boolean
  begin
    K := Integer(Key);
    Result := True;
  end);

  Assert.AreEqual(0, K, 'K should be 0 after reset and traverse');
end;

procedure TListTests.TestList_Put_Concurrent;
const
  Total = 86400;
  NumGoRoutines = 5;
  PutsPerGoRoutine = 100000;
var
  L: IList;
  I: Integer;
  Tasks: array of ITask;
begin
  L := NewList(Total);

  SetLength(Tasks, NumGoRoutines);
  for I := 0 to NumGoRoutines - 1 do
  begin
    Tasks[I] := TTask.Run(procedure
    var
      J: Integer;
    begin
      for J := 0 to PutsPerGoRoutine - 1 do
      begin
        L.Put(TObject(J));
      end;
    end);
  end;
  TTask.WaitForAll(Tasks);

  TTask.Run(procedure
  var
    Amount: Integer;
    KeyVal: Integer;
  begin
    while True do
    begin
      Amount := 0;
      L.TraverseR(function(Key: TKey): Boolean
      begin
        if Key <> nil then
        begin
          KeyVal := Integer(Key);
          Amount := Amount + KeyVal;
        end;
        Result := True;
      end);
      TThread.Sleep(100);
    end;
  end);

  TThread.Sleep(5000);
end;

end.
