unit tools.unique_list.unique_list_test;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  Tools.Unique.List.Unique.List,
  tools.unique_list.unique_list;

type
  [TestFixture]
  TUniqueListTests = class(TObject)
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

{ TUniqueListTests }

procedure TUniqueListTests.TestList_Append;
const
  Total = 10;
var
  L: IUniqueList;
  I: Integer;
  Key: string;
  Value: TObject;
  Names: TArray<string>;
  UniqueNames: TArray<string>;
  UniqueValues: TArray<Integer>;
  K: string;
  V: TObject;
begin
  L := NewUniqueList;
  try
    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    Assert.AreEqual(Total, L.Size, 'Size after initial append mismatch');

    I := 0;
    L.Traverse(function(Key: string; Value: TObject): Boolean
    begin
      if (Integer(Value) <> I) or (Key <> IntToStr(I)) then
        Fail('Traverse value or key mismatch');
      Inc(I);
      Result := True;
    end);

    // clear retry
    L.Clear;
    // System.SysUtils.WriteLn(Format('%s', [L.ToString])); // Delphi equivalent for fmt.Printf

    Names := ['foo', 'bar', 'foo', 'hello', 'bar', 'world'];
    UniqueNames := ['foo', 'bar', 'hello', 'world'];
    UniqueValues := [0, 1, 3, 5];

    for I := 0 to High(Names) do
    begin
      L.Append(Names[I], TObject(I));
    end;

    Assert.AreEqual(Length(UniqueNames), L.Size, 'Size after unique append mismatch');

    L.Traverse(function(Key: string; Data: TObject): Boolean
    begin
      Result := True;
    end);

    for I := 0 to High(UniqueNames) do
    begin
      if not L.Shift(K, V) then
        Fail('Shift should return true');
      Assert.AreEqual(UniqueNames[I], K, 'Shifted key mismatch');
      Assert.AreEqual(UniqueValues[I], Integer(V), 'Shifted value mismatch');
    end;
  finally
    L := nil; // Release interface
  end;
end;

procedure TUniqueListTests.TestList_Shift;
const
  Total = 30;
  Batch = 10;
var
  L: IUniqueList;
  I: Integer;
  K: string;
  E: TObject;
  J: Integer;
begin
  L := NewUniqueList;
  try
    L.Shift(K, E); // Should not fail, just return false

    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    for I := 0 to Batch - 1 do
    begin
      if not L.Shift(K, E) then
        Fail('Shift should return true');
      if (Integer(E) <> I) or (K <> IntToStr(I)) then
      begin
        // System.SysUtils.WriteLn(Format('element %d %d', [I, Integer(E)])); // For debugging
        Fail('Shifted element mismatch');
      end;
    end;

    Assert.AreEqual(Total - Batch, L.Size, Format('size %d should be %d', [L.Size, Total - Batch]));

    for I := Total to Total + Batch - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    // shift all elements
    J := Batch;
    while L.Shift(K, E) do
    begin
      if (K <> IntToStr(J)) or (Integer(E) <> J) then
        Fail('Shifted element mismatch during full shift');
      Inc(J);
    end;

    Assert.AreEqual(0, L.Size, Format('size should be 0, but is %d', [L.Size]));

    // append again
    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    for I := 0 to Batch - 1 do
    begin
      if not L.Shift(K, E) then
        Fail('Shift should return true');
      if (Integer(E) <> I) or (K <> IntToStr(I)) then
      begin
        // System.SysUtils.WriteLn(Format('element %d %d', [I, Integer(E)])); // For debugging
        Fail('Shifted element mismatch after re-append');
      end;
    end;
  finally
    L := nil; // Release interface
  end;
end;

procedure TUniqueListTests.TestList_UnShift;
const
  Total = 30;
  Batch = 10;
var
  L: IUniqueList;
  I: Integer;
  K: string;
  E: TObject;
begin
  L := NewUniqueList;
  try
    for I := 0 to Total - 1 do
    begin
      L.UnShift(IntToStr(I), TObject(I));
    end;

    Assert.AreEqual(Total, L.Size, 'Size after unshift mismatch');

    for I := 1 to Batch do
    begin
      if not L.Shift(K, E) then
        Fail('Shift should return true');
      if (Integer(E) <> Total - I) or (K <> IntToStr(Total - I)) then
        Fail('Unshifted element mismatch');
    end;
  finally
    L := nil; // Release interface
  end;
end;

procedure TUniqueListTests.TestList_Traverse;
const
  Total = 30;
var
  L: IUniqueList;
  I: Integer;
begin
  L := NewUniqueList;
  try
    L.Traverse(function(Key: string; Value: TObject): Boolean
    begin
      Result := True;
    end);

    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    I := 0;
    L.Traverse(function(Key: string; Value: TObject): Boolean
    begin
      if (Integer(Value) <> I) or (Key <> IntToStr(I)) then
      begin
        // System.SysUtils.WriteLn('traverse fail'); // For debugging
        Fail('Traverse value or key mismatch after append');
      end;
      Inc(I);
      Result := True;
    end);
  finally
    L := nil; // Release interface
  end;
end;

procedure TUniqueListTests.TestList_Filter;
const
  Total = 30;
  Threshold = 10;
var
  L: IUniqueList;
  I: Integer;
begin
  L := NewUniqueList;
  try
    L.Filter(function(Key: string; V: TObject): Boolean
    begin
      Result := True;
    end);

    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    // remove some elements
    L.Filter(function(Key: string; Value: TObject): Boolean
    begin
      Result := Integer(Value) < Threshold;
    end);

    Assert.AreEqual(Total - Threshold, L.Size, 'Size after partial filter mismatch');

    // append again
    for I := Total to Total + Threshold - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;

    // rest elements
    I := Threshold;
    L.Traverse(function(Key: string; Value: TObject): Boolean
    begin
      if (Integer(Value) <> I) or (Key <> IntToStr(I)) then
      begin
        // System.SysUtils.WriteLn('rest fail'); // For debugging
        Fail('Traverse value or key mismatch after re-append and filter');
      end;
      Inc(I);
      Result := True;
    end);

    // remove all elements
    L.Filter(function(Key: string; Value: TObject): Boolean
    begin
      Result := True;
    end);
    Assert.AreEqual(0, L.Size, 'Size after full filter mismatch');

    // append again
    for I := 0 to Total - 1 do
    begin
      L.Append(IntToStr(I), TObject(I));
    end;
    I := 0;
    L.Traverse(function(Key: string; Value: TObject): Boolean
    begin
      if (Integer(Value) <> I) or (Key <> IntToStr(I)) then
        Fail('Traverse value or key mismatch after final re-append');
      Inc(I);
      Result := True;
    end);
  finally
    L := nil; // Release interface
  end;
end;

end.
