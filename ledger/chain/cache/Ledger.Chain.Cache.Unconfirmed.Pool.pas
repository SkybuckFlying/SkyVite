unit Ledger.Chain.Cache.UnconfirmedPool;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Cache.DataSet;

type
  TUnconfirmedPool = class
  private
    mDs: TDataSet;
    mInsertedList: TList<TBytes>;
    mInsertedMap: TDictionary<TAddress, TList<TBytes>>;
  public
    constructor Create(ParaDs: TDataSet);
    destructor Destroy; override;
    procedure InsertAccountBlock(ParaBlock: TAccountBlock);
    function GetBlocks: TArray<TAccountBlock>;
    function GetBlocksByAddress(ParaAddr: TAddress): TArray<TAccountBlock>;
    procedure DeleteBlocks(ParaBlocks: TArray<TAccountBlock>);
    procedure DeleteAllBlocks;
  end;

implementation

{ TUnconfirmedPool }

constructor TUnconfirmedPool.Create(ParaDs: TDataSet);
begin
  inherited Create;
  mDs := ParaDs;
  mInsertedList := TList<TBytes>.Create;
  mInsertedMap := TDictionary<TAddress, TList<TBytes>>.Create;
end;

destructor TUnconfirmedPool.Destroy;
begin
  mInsertedList.Free;
  mInsertedMap.Free;
  inherited Destroy;
end;

procedure TUnconfirmedPool.InsertAccountBlock(ParaBlock: TAccountBlock);
var
  vList: TList<TBytes>;
begin
  mInsertedList.Add(ParaBlock.Hash);
  if not mInsertedMap.TryGetValue(ParaBlock.AccountAddress, vList) then
  begin
    vList := TList<TBytes>.Create;
    mInsertedMap.Add(ParaBlock.AccountAddress, vList);
  end;
  vList.Add(ParaBlock.Hash);
end;

function TUnconfirmedPool.GetBlocks: TArray<TAccountBlock>;
var
  vBlocks: TList<TAccountBlock>;
  vHash: TBytes;
begin
  vBlocks := TList<TAccountBlock>.Create;
  try
    for vHash in mInsertedList do
    begin
      vBlocks.Add(mDs.GetAccountBlock(vHash));
    end;
    Result := vBlocks.ToArray;
  finally
    vBlocks.Free;
  end;
end;

function TUnconfirmedPool.GetBlocksByAddress(ParaAddr: TAddress): TArray<TAccountBlock>;
var
  vList: TList<TBytes>;
  vBlocks: TList<TAccountBlock>;
  vHash: TBytes;
begin
  if mInsertedMap.TryGetValue(ParaAddr, vList) then
  begin
    vBlocks := TList<TAccountBlock>.Create;
    try
      for vHash in vList do
      begin
        vBlocks.Add(mDs.GetAccountBlock(vHash));
      end;
      Result := vBlocks.ToArray;
    finally
      vBlocks.Free;
    end;
  end
  else
  begin
    Result := nil;
  end;
end;

procedure TUnconfirmedPool.DeleteBlocks(ParaBlocks: TArray<TAccountBlock>);
var
  vNewInsertedList: TList<TBytes>;
  vNewInsertedMap: TDictionary<TAddress, TList<TBytes>>;
  vHashMapToDelete: TDictionary<TBytes, Boolean>;
  vBlock: TAccountBlock;
  vHash: TBytes;
  vList: TList<TBytes>;
begin
  if Length(ParaBlocks) <= 0 then
  begin
    Exit;
  end;

  vNewInsertedList := TList<TBytes>.Create;
  vNewInsertedMap := TDictionary<TAddress, TList<TBytes>>.Create;
  vHashMapToDelete := TDictionary<TBytes, Boolean>.Create;
  try
    for vBlock in ParaBlocks do
    begin
      vHashMapToDelete.Add(vBlock.Hash, True);
    end;

    for vHash in mInsertedList do
    begin
      if not vHashMapToDelete.ContainsKey(vHash) then
      begin
        vNewInsertedList.Add(vHash);
        vBlock := mDs.GetAccountBlock(vHash);
        if not vNewInsertedMap.TryGetValue(vBlock.AccountAddress, vList) then
        begin
          vList := TList<TBytes>.Create;
          vNewInsertedMap.Add(vBlock.AccountAddress, vList);
        end;
        vList.Add(vHash);
      end;
    end;

    mInsertedList.Free;
    mInsertedMap.Free;
    mInsertedList := vNewInsertedList;
    mInsertedMap := vNewInsertedMap;
  finally
    vHashMapToDelete.Free;
  end;
end;

procedure TUnconfirmedPool.DeleteAllBlocks;
begin
  mInsertedList.Clear;
  mInsertedMap.Clear;
end;

end.
