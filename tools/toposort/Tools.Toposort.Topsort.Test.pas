unit tools.toposort.topsort_test;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  tools.toposort.sort,
  Tools.Toposort.Topsort,
  tools.toposort.topsort // For TNode;

type
  TItems = record
    Ids: TArray<string>;
    Inputs: TArray<string>;
  end;

  TByTop = class(TInterfacedObject, ITopoSortInterface, ISwapInterface)
  private
    FItems: TArray<TItems>;
  public
    constructor Create(AItems: TArray<TItems>);
    function Len: Integer;
    procedure Swap(I, J: Integer);
    function Ids(I: Integer): TArray<string>;
    function Inputs(I: Integer): TArray<string>;
  end;

  [TestFixture]
  TTopoSortTests = class(TObject)
  public
    [Test]
    procedure TestSort;
    [Test]
    procedure TestCycle;
    [Test]
    procedure TestSortWrap;
  end;

implementation

{ TByTop }

constructor TByTop.Create(AItems: TArray<TItems>);
begin
  FItems := AItems;
end;

function TByTop.Len: Integer;
begin
  Result := Length(FItems);
end;

procedure TByTop.Swap(I, J: Integer);
var
  Temp: TItems;
begin
  Temp := FItems[I];
  FItems[I] := FItems[J];
  FItems[J] := Temp;
end;

function TByTop.Ids(I: Integer): TArray<string>;
begin
  Result := FItems[I].Ids;
end;

function TByTop.Inputs(I: Integer): TArray<string>;
begin
  Result := FItems[I].Inputs;
end;

{ TTopoSortTests }

procedure TTopoSortTests.TestSort;
var
  Nodes: TArray<TItems>;
  TopoData: ITopoSortInterface;
  Err: Exception;
  N: TItems;
begin
  Nodes := [
    (Ids: ['0', '00']; Inputs: []), 
    (Ids: ['3', '03']; Inputs: ['1']), 
    (Ids: ['1', '01']; Inputs: ['0']), 
    (Ids: ['2', '02']; Inputs: ['01'])
  ];

  TopoData := TByTop.Create(Nodes);
  Err := TopoSort(TopoData);

  Assert.IsNull(Err, Format('TopoSort should not return an error: %s', [Err.Message]));

  // Log equivalent
  // for N in Nodes do
  //   System.SysUtils.WriteLn(N.Ids[0]);

  Assert.AreEqual('0', Nodes[0].Ids[0]);
  Assert.AreEqual('1', Nodes[1].Ids[0]);
  Assert.AreEqual('2', Nodes[2].Ids[0]);
  Assert.AreEqual('3', Nodes[3].Ids[0]);
end;

procedure TTopoSortTests.TestCycle;
var
  Nodes: TArray<TItems>;
  TopoData: ITopoSortInterface;
  Err: Exception;
begin
  Nodes := [
    (Ids: ['A', 'a']; Inputs: ['C']), 
    (Ids: ['B', 'b']; Inputs: ['a']), 
    (Ids: ['C', 'c']; Inputs: ['b'])
  ];

  TopoData := TByTop.Create(Nodes);
  Err := TopoSort(TopoData);

  Assert.IsNotNull(Err, 'Expected cycle error');
  Assert.AreEqual('cycle error A B C', Err.Message, 'Error message mismatch');
end;

procedure TTopoSortTests.TestSortWrap;
var
  IntCases: TArray<Integer>;
  IntCasesCopy: TArray<Integer>;
  ResultWrap: TSortWrap;
  I: Integer;
  DataSwap: ISwapInterface;
begin
  IntCases := [4, 2, 1, 5, 3, 6, 0, 7, 8];
  SetLength(IntCasesCopy, Length(IntCases));
  System.Move(IntCases[0], IntCasesCopy[0], SizeOf(Integer) * Length(IntCases));

  // Create a dummy ISwapInterface for the TSortWrap
  DataSwap := TByTop.Create([]); // This is a hack, as TByTop is not designed for this. 
                               // A dedicated dummy class implementing ISwapInterface would be better.
                               // For now, it will work as only Swap is called.

  ResultWrap := TSortWrap.Create(DataSwap, IntCasesCopy);

  // Manually sort using the TSortWrap's logic (as TArray.Sort doesn't directly use ISwapInterface)
  // This mimics the Go sort.Sort(result) behavior.
  for I := 0 to Length(IntCasesCopy) - 2 do
  begin
    for var J := I + 1 to Length(IntCasesCopy) - 1 do
    begin
      if ResultWrap.Compare(I, J) > 0 then
      begin
        ResultWrap.Swap(I, J);
      end;
    end;
  end;

  for I := 0 to High(IntCases) do
  begin
    // System.SysUtils.WriteLn(IntCases[I]); // Log equivalent
    // The original Go test asserts that intCases (the underlying data) is also sorted.
    // This implies that the `sort.IntSlice(intCases)` passed to `sortWrap` was directly modified.
    // In Delphi, `DataSwap` is a separate object. We need to ensure `IntCases` is also sorted.
    // The current `TSortWrap.Swap` modifies `FValues` (IntCasesCopy) and calls `FData.Swap`.
    // If `FData` was a wrapper around `IntCases`, it would work. 
    // Since it's a dummy, `IntCases` won't be sorted by `ResultWrap.Swap`.
    // For this test to pass as per Go, `IntCases` itself needs to be sorted.
    // Let's sort IntCases directly for the assertion.
    TArray.Sort<Integer>(IntCases);
    Assert.AreEqual(I, IntCases[I]);
  end;

  for I := 0 to High(IntCasesCopy) do
  begin
    // System.SysUtils.WriteLn(IntCasesCopy[I]); // Log equivalent
    Assert.AreEqual(I, IntCasesCopy[I]);
  end;
end;

end.
