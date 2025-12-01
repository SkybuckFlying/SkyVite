unit Ledger.Pool.Face;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Interfaces.Core.AccountBlock, Common.Types;

type
  TAccBlocksSort = class
  private
    FBlocks: TArray<TAccountBlock>;
  public
    constructor Create(const ABlocks: TArray<TAccountBlock>);
    function Len: Integer;
    function Ids(i: Integer): TArray<string>;
    procedure Swap(i, j: Integer);
    function Inputs(i: Integer): TArray<string>;
    procedure Sort;
  end;

implementation

uses
  System.Generics.Defaults;

{ TAccBlocksSort }

constructor TAccBlocksSort.Create(const ABlocks: TArray<TAccountBlock>);
begin
  FBlocks := ABlocks;
end;

function TAccBlocksSort.Len: Integer;
begin
  Result := Length(FBlocks);
end;

function TAccBlocksSort.Ids(i: Integer): TArray<string>;
var
  vBlock: TAccountBlock;
begin
  SetLength(Result, 0);
  Result := Result + [FBlocks[i].Hash.ToString];
  if Length(FBlocks[i].SendBlockList) > 0 then
  begin
    for vBlock in FBlocks[i].SendBlockList do
    begin
      Result := Result + [vBlock.Hash.ToString];
    end;
  end;
end;

procedure TAccBlocksSort.Swap(i, j: Integer);
var
  vTemp: TAccountBlock;
begin
  vTemp := FBlocks[i];
  FBlocks[i] := FBlocks[j];
  FBlocks[j] := vTemp;
end;

function TAccBlocksSort.Inputs(i: Integer): TArray<string>;
var
  vBlock: TAccountBlock;
begin
  SetLength(Result, 0);
  vBlock := FBlocks[i];
  if vBlock.Height > 1 then // GenesisHeight
  begin
    Result := Result + [vBlock.PrevHash.ToString];
  end;
  if vBlock.IsReceiveBlock and not vBlock.IsGenesisBlock then
  begin
    Result := Result + [vBlock.FromBlockHash.ToString];
  end;
end;

procedure TAccBlocksSort.Sort;
var
  vInDegree: TDictionary<string, Integer>;
  vGraph: TDictionary<string, TArray<string>>;
  vQueue: TQueue<string>;
  vIndexMap: TDictionary<string, Integer>;
  i: Integer;
  vIds, vInputs: TArray<string>;
  vId, vInput: string;
  vSortedList: TArray<TAccountBlock>;
  vCurrentId: string;
  vNeighbor: string;
  vBlock: TAccountBlock;
begin
  // Topological Sort Implementation
  vInDegree := TDictionary<string, Integer>.Create;
  vGraph := TDictionary<string, TArray<string>>.Create;
  vIndexMap := TDictionary<string, Integer>.Create;

  // Initialize graph and in-degree map
  for i := 0 to Len - 1 do
  begin
    vIds := Ids(i);
    for vId in vIds do
    begin
      if not vGraph.ContainsKey(vId) then
        vGraph.Add(vId, []);
      if not vInDegree.ContainsKey(vId) then
        vInDegree.Add(vId, 0);
      vIndexMap.Add(vId, i);
    end;
  end;

  // Build graph and in-degree map
  for i := 0 to Len - 1 do
  begin
    vInputs := Inputs(i);
    vIds := Ids(i);
    for vId in vIds do
    begin
      for vInput in vInputs do
      begin
        if vGraph.ContainsKey(vInput) then
        begin
          vGraph[vInput] := vGraph[vInput] + [vId];
          vInDegree[vId] := vInDegree[vId] + 1;
        end;
      end;
    end;
  end;

  // Initialize queue with nodes having in-degree of 0
  vQueue := TQueue<string>.Create;
  for i := 0 to Len - 1 do
  begin
    vIds := Ids(i);
    for vId in vIds do
      if vInDegree[vId] = 0 then
        vQueue.Enqueue(vId);
  end;


  SetLength(vSortedList, 0);
  while vQueue.Count > 0 do
  begin
    vCurrentId := vQueue.Dequeue;
    if vIndexMap.ContainsKey(vCurrentId) then
    begin
        vBlock := FBlocks[vIndexMap[vCurrentId]];
        vSortedList := vSortedList + [vBlock];
    end;


    if vGraph.ContainsKey(vCurrentId) then
    begin
      for vNeighbor in vGraph[vCurrentId] do
      begin
        vInDegree[vNeighbor] := vInDegree[vNeighbor] - 1;
        if vInDegree[vNeighbor] = 0 then
          vQueue.Enqueue(vNeighbor);
      end;
    end;
  end;

  if Length(vSortedList) <> Len then
  begin
    // Cycle detected, handle error or fallback
  end
  else
  begin
    FBlocks := vSortedList;
  end;
end;

end.
