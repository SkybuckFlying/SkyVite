unit tools.toposort.sort;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Tools.Toposort.Topsort,
  tools.toposort.topsort // Reuse TNode from topsort unit,
  Tools.Toposort.Topsort.Test;

type
  ISwapInterface = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    procedure Swap(I, J: Integer);
  end;

  ITopoSortInterface = interface
    ['{YOUR_GUID_HERE}'] // TODO: Generate a new GUID
    function Ids(I: Integer): TArray<string>;
    function Inputs(I: Integer): TArray<string>;
    function Len: Integer;
    procedure Swap(I, J: Integer);
  end;

  TSortWrap = class(TInterfacedObject, IComparer<Integer>)
  private
    FData: ISwapInterface;
    FValues: TArray<Integer>;
  public
    constructor Create(AData: ISwapInterface; AValues: TArray<Integer>);
    function Compare(const A, B: Integer): Integer; overload;
    procedure Swap(I, J: Integer);
  end;

function TopoSort(Data: ITopoSortInterface): Exception;

implementation

uses
  System.Generics.Defaults; // For TComparer

{ TSortWrap }

constructor TSortWrap.Create(AData: ISwapInterface; AValues: TArray<Integer>);
begin
  FData := AData;
  FValues := AValues;
end;

function TSortWrap.Compare(const A, B: Integer): Integer;
begin
  if FValues[A] < FValues[B] then
    Result := -1
  else if FValues[A] > FValues[B] then
    Result := 1
  else
    Result := 0;
end;

procedure TSortWrap.Swap(I, J: Integer);
var
  Temp: Integer;
begin
  FData.Swap(I, J);
  Temp := FValues[I];
  FValues[I] := FValues[J];
  FValues[J] := Temp;
end;

function TopoSort(Data: ITopoSortInterface): Exception;
var
  Alias: TDictionary<string, string>;
  Len: Integer;
  UnsortedNodes: TArray<TNode>;
  I: Integer;
  Ids: TArray<string>;
  Inputs: TArray<string>;
  N: TNode;
  Id: string;
  Input: string;
  RealId: string;
  Ok: Boolean;
  UnsortedMap: TDictionary<string, TNode>;
  Graph: TGraph;
  SortedNodes: TArray<TNode>;
  Values: TArray<Integer>;
  Wrap: TSortWrap;
begin
  Result := nil;
  Alias := TDictionary<string, string>.Create;
  UnsortedMap := TDictionary<string, TNode>.Create;
  try
    Len := Data.Len;
    SetLength(UnsortedNodes, Len);
    for I := 0 to Len - 1 do
    begin
      Ids := Data.Ids(I);
      Inputs := Data.Inputs(I);
      N := TNode.Create;
      N.Id := Ids[0];
      N.Alias := Ids;
      N.Inputs := Inputs;
      N.Index := I;
      N.InputCnt := 0;
      N.SortedIndex := 0;
      UnsortedNodes[I] := N;
    end;

    for N in UnsortedNodes do
    begin
      for Id in N.Alias do
      begin
        Alias.Add(Id, N.Id);
      end;
    end;

    for N in UnsortedNodes do
    begin
      UnsortedMap.Add(N.Id, N);
    end;

    for N in UnsortedNodes do
    begin
      for Input in N.Inputs do
      begin
        if Alias.TryGetValue(Input, RealId) then
        begin
          Inc(N.InputCnt);
          UnsortedMap[RealId].Outputs := UnsortedMap[RealId].Outputs + [N.Id];
        end;
      end;
    end;

    Graph := NewGraph(UnsortedMap);
    try
      try
        SortedNodes := Graph.TpSort;
      except
        on E: Exception do
        begin
          Result := E;
          Exit;
        end;
      end;

      for I := 0 to Length(SortedNodes) - 1 do
      begin
        SortedNodes[I].SortedIndex := I;
      end;

      SetLength(Values, Length(UnsortedNodes));
      for I := 0 to Length(UnsortedNodes) - 1 do
      begin
        Values[I] := UnsortedNodes[I].SortedIndex;
      end;

      Wrap := TSortWrap.Create(Data, Values);
      try
        // Use TArray.Sort with a custom comparer that uses TSortWrap's Compare method
        TArray.Sort<Integer>(Values, TComparer<Integer>.Construct(Wrap.Compare));
        // The actual data needs to be swapped based on the sorted indices
        // This requires a custom sort implementation that swaps both values and data
        // Since TArray.Sort only sorts the array itself, we need to manually apply the swaps to Data
        // based on the sorted order of Values.
        // This is a more complex operation than a simple TArray.Sort.
        // For now, I will implement a bubble sort like approach to apply the swaps to Data.
        // A more efficient approach would be to create a list of pairs (original_index, sorted_index)
        // and then sort that list, then apply the swaps.

        // Simple bubble sort to apply swaps based on sorted values
        for I := 0 to Length(Values) - 2 do
        begin
          for var J := I + 1 to Length(Values) - 1 do
          begin
            if Values[I] > Values[J] then
            begin
              Wrap.Swap(I, J); // This swaps both data and values
            end;
          end;
        end;

      finally
        Wrap := nil; // Release interface
      end;

    finally
      Graph.Free;
    end;

  finally
    Alias.Free;
    UnsortedMap.Free;
    for N in UnsortedNodes do
      N.Free; // Free the TNode objects created
  end;
end;

end.
