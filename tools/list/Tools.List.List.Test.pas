unit Tools.List.List.Test;

interface

uses
  DUnitX.TestFramework,
  Tools.List.List;

type
  [TestFixture]
  TListTests = class(TObject)
  public
    [Test]
    procedure TestList_Append;
    [Test]
    procedure TestList_Shift;
    [Test]
    procedure TestList_UnShift;
    [Test]
    procedure TestList_Traverse;
    [Test]
    procedure TestList_Filter;
  end;

implementation

uses
  System.SysUtils;

{ TListTests }

procedure TListTests.TestList_Append;
var
  L: IList;
  I: Integer;
begin
  L := New;
  const Total = 10;
  for I := 0 to Total - 1 do
    L.Append(TObject(I));

  Assert.AreEqual(Total, L.Size);

  I := 0;
  L.Traverse(
    function(Value: TObject): Boolean
    begin
      Assert.AreEqual(I, Integer(Value));
      Inc(I);
      Result := True;
    end
  );
end;

procedure TListTests.TestList_Shift;
var
  L: IList;
  I, J: Integer;
  E, V: TObject;
begin
  L := New;
  L.Shift;

  const Total = 30;
  const Batch = 10;

  for I := 0 to Total - 1 do
    L.Append(TObject(I));

  for I := 0 to Batch - 1 do
  begin
    E := L.Shift;
    Assert.AreEqual(I, Integer(E));
  end;

  Assert.AreEqual(Total - Batch, L.Size, Format('size %d should be %d', [L.Size, Total - Batch]));

  for I := Total to Total + Batch - 1 do
    L.Append(TObject(I));

  // shift all elements
  J := Batch;
  V := L.Shift;
  while V <> nil do
  begin
    Assert.AreEqual(J, Integer(V));
    Inc(J);
    V := L.Shift;
  end;

  Assert.AreEqual(0, L.Size, Format('size should be 0, but is %d', [L.Size]));

  // append again
  for I := 0 to Total - 1 do
    L.Append(TObject(I));

  for I := 0 to Batch - 1 do
  begin
    E := L.Shift;
    Assert.AreEqual(I, Integer(E));
  end;
end;

procedure TListTests.TestList_UnShift;
var
  L: IList;
  I: Integer;
  E: TObject;
begin
  L := New;

  const Total = 30;
  const Batch = 10;

  for I := 0 to Total - 1 do
    L.UnShift(TObject(I));

  Assert.AreEqual(Total, L.Size);

  for I := 1 to Batch do
  begin
    E := L.Shift;
    Assert.AreEqual(Total - I, Integer(E));
  end;
end;

procedure TListTests.TestList_Traverse;
var
  L: IList;
  I: Integer;
begin
  L := New;
  L.Traverse(
    function(Value: TObject): Boolean
    begin
      Result := True;
    end
  );

  const Total = 30;

  for I := 0 to Total - 1 do
    L.Append(TObject(I));

  I := 0;
  L.Traverse(
    function(Value: TObject): Boolean
    begin
      Assert.AreEqual(I, Integer(Value), 'traverse fail');
      Inc(I);
      Result := True;
    end
  );
end;

procedure TListTests.TestList_Filter;
var
  L: IList;
  I: Integer;
begin
  L := New;
  L.Filter(
    function(V: TObject): Boolean
    begin
      Result := True;
    end
  );

  const Total = 30;

  for I := 0 to Total - 1 do
    L.Append(TObject(I));

  // remove some elements
  const Threshold = 10;
  L.Filter(
    function(Value: TObject): Boolean
    begin
      Result := Integer(Value) < Threshold;
    end
  );

  Assert.AreEqual(Total - Threshold, L.Size, 'remove fail');

  // append again
  for I := Total to Total + Threshold - 1 do
    L.Append(TObject(I));

  // rest elements
  I := Threshold;
  L.Traverse(
    function(Value: TObject): Boolean
    begin
      Assert.AreEqual(I, Integer(Value), 'rest fail');
      Inc(I);
      Result := True;
    end
  );

  // remove all elements
  L.Filter(
    function(Value: TObject): Boolean
    begin
      Result := True;
    end
  );
  Assert.AreEqual(0, L.Size, 'remove all fail');

  // append again
  for I := 0 to Total - 1 do
    L.Append(TObject(I));
  I := 0;
  L.Traverse(
    function(Value: TObject): Boolean
    begin
      Assert.AreEqual(I, Integer(Value));
      Inc(I);
      Result := True;
    end
  );
end;

end.