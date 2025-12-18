unit tools.toposort.topsort;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Tools.Toposort.Sort,
  Tools.Toposort.Topsort.Test;

type
  TNode = class
  public
    Id: string;
    Alias: TArray<string>;
    Inputs: TArray<string>;

    Index: Integer;

    InputCnt: Integer;
    Outputs: TArray<string>;
    SortedIndex: Integer;

    constructor Create;
    destructor Destroy; override;
  end;

  TGraph = class
  private
    FSorted: TList<TNode>;
    FUnsorted: TDictionary<string, TNode>;
    function FilterZero: TArray<TNode>;
    procedure Move(ANode: TNode);
    function UnsortedResult: string;
  public
    constructor Create(ANodes: TDictionary<string, TNode>);
    destructor Destroy; override;
    function TpSort: TArray<TNode>; // Returns sorted nodes or raises exception
  end;

function NewGraph(ANodes: TDictionary<string, TNode>): TGraph;

implementation

uses
  System.Generics.Defaults; // For TComparer

{ TNode }

constructor TNode.Create;
begin
  SetLength(Alias, 0);
  SetLength(Inputs, 0);
  SetLength(Outputs, 0);
end;

destructor TNode.Destroy;
begin
  // No owned objects to free here, TArray<string> are managed types
  inherited;
end;

{ TGraph }

constructor TGraph.Create(ANodes: TDictionary<string, TNode>);
begin
  FSorted := TList<TNode>.Create;
  FUnsorted := TDictionary<string, TNode>.Create;
  // Copy nodes from input dictionary (shallow copy of TNode references)
  for var LNode in ANodes.Values do
    FUnsorted.Add(LNode.Id, LNode);
end;

destructor TGraph.Destroy;
begin
  // FUnsorted and FSorted hold references to TNode objects. 
  // The TNode objects themselves are created and managed by the TopoSort function.
  // So, we don't free the TNode objects here to avoid double freeing.
  FSorted.Free;
  FUnsorted.Free;
  inherited;
end;

function TGraph.FilterZero: TArray<TNode>;
var
  N: TNode;
  ResultList: TList<TNode>;
  ByIdComparer: IComparer<TNode>;
begin
  ResultList := TList<TNode>.Create;
  try
    for N in FUnsorted.Values do
    begin
      if N.InputCnt = 0 then
      begin
        ResultList.Add(N);
      end;
    end;

    // Sort by Id
    ByIdComparer := TComparer<TNode>.Construct(
      function(A, B: TNode): Integer
      begin
        Result := System.SysUtils.CompareStr(A.Id, B.Id);
      end
    );
    ResultList.Sort(ByIdComparer);
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

procedure TGraph.Move(ANode: TNode);
begin
  FSorted.Add(ANode);
  FUnsorted.Remove(ANode.Id);
end;

function TGraph.UnsortedResult: string;
var
  Ids: TStringDynArray;
  NodeId: string;
begin
  SetLength(Ids, FUnsorted.Count);
  var I := 0;
  for NodeId in FUnsorted.Keys do
  begin
    Ids[I] := NodeId;
    Inc(I);
  end;
  TArray.Sort<string>(Ids);

  Result := '';
  for var Id in Ids do
  begin
    Result := Result + Id + ' ';
  end;
  Result := Trim(Result);
end;

function TGraph.TpSort: TArray<TNode>;
var
  Waitings: TArray<TNode>;
  N: TNode;
  Output: string;
  RefNode: TNode;
begin
  while True do
  begin
    Waitings := FilterZero;

    if (Length(Waitings) = 0) and (FUnsorted.Count <> 0) then
    begin
      raise Exception.Create(Format('cycle error %s', [UnsortedResult]));
    end;

    for N in Waitings do
    begin
      for Output in N.Outputs do
      begin
        if FUnsorted.TryGetValue(Output, RefNode) then
        begin
          RefNode.InputCnt := RefNode.InputCnt - 1;
        end;
      end;
      Move(N);
    end;

    if FUnsorted.Count = 0 then
      Break;
  end;
  Result := FSorted.ToArray;
end;

function NewGraph(ANodes: TDictionary<string, TNode>): TGraph;
begin
  Result := TGraph.Create(ANodes);
end;

end.
