unit Ledger.Chain.Cache.DataSet;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  GoToDelphi.Helpers.GoCache, Vite.Common.Types, Interfaces.Core,
  Ledger.Chain.Utils, Interfaces;

type
  TDataSet = class
  private
    mStore: TGoCache<string, TObject>;
    mSnapshotKeepCount: UInt64;
    procedure InternalInsertAccountBlock(ParaAccountBlock: TAccountBlock; ParaDelay: Int64);
    procedure DeleteStaleSnapshotBlock(ParaHeight: UInt64);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Close;
    function IsLarge: Boolean;
    procedure InsertAccountBlock(ParaAccountBlock: TAccountBlock);
    procedure InsertSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
    procedure DeleteAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>);
    procedure DelayDeleteAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>; ParaDelay: Int64);
    procedure DeleteSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
    function GetAccountBlock(ParaHash: TBytes): TAccountBlock;
    function GetAccountBlockByHeight(ParaAddress: TAddress; ParaHeight: UInt64): TAccountBlock;
    function IsAccountBlockExisted(ParaHash: TBytes): Boolean;
    function GetSnapshotBlock(ParaHash: TBytes): TSnapshotBlock;
    function GetSnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
    function IsSnapshotBlockExisted(ParaHash: TBytes): Boolean;
    function GetStatus: TArray<IDBStatus>;
  end;

implementation

{ TDataSet }

constructor TDataSet.Create;
begin
  inherited Create;
  mStore := TGoCache<string, TObject>.Create(NoExpiration, 60 * 1000); // 1 minute cleanup
  mSnapshotKeepCount := 1800;
end;

destructor TDataSet.Destroy;
begin
  mStore.Free;
  inherited Destroy;
end;

procedure TDataSet.Close;
begin
  mStore.Flush;
  mStore := nil;
end;

function TDataSet.IsLarge: Boolean;
begin
  Result := mStore.ItemCount > 200000;
end;

procedure TDataSet.InsertAccountBlock(ParaAccountBlock: TAccountBlock);
begin
  InternalInsertAccountBlock(ParaAccountBlock, NoExpiration);
end;

procedure TDataSet.InsertSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
var
  vHashKey: string;
  vHeightKey: string;
begin
  vHashKey := CreateSnapshotBlockHashKey(ParaSnapshotBlock.Hash).ToString;
  vHeightKey := CreateSnapshotBlockHeightKey(ParaSnapshotBlock.Height).ToString;

  mStore.Set(vHashKey, ParaSnapshotBlock, 1800 * 1000);
  mStore.Set(vHeightKey, TObject(vHashKey), 1800 * 1000);

  DeleteStaleSnapshotBlock(ParaSnapshotBlock.Height);
end;

procedure TDataSet.DeleteAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>);
var
  vAccountBlock: TAccountBlock;
  vSendBlock: TAccountBlock;
  vHashKey: string;
  vHeightKey: string;
begin
  for vAccountBlock in ParaAccountBlocks do
  begin
    vHashKey := CreateAccountBlockHashKey(vAccountBlock.Hash).ToString;
    vHeightKey := CreateAccountBlockHeightKey(vAccountBlock.AccountAddress, vAccountBlock.Height).ToString;

    mStore.Delete(vHashKey);
    mStore.Delete(vHeightKey);

    for vSendBlock in vAccountBlock.SendBlockList do
    begin
      mStore.Delete(CreateAccountBlockHashKey(vSendBlock.Hash).ToString);
    end;
  end;
end;

procedure TDataSet.DelayDeleteAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>; ParaDelay: Int64);
var
  vAccountBlock: TAccountBlock;
begin
  for vAccountBlock in ParaAccountBlocks do
  begin
    InternalInsertAccountBlock(vAccountBlock, ParaDelay);
  end;
end;

procedure TDataSet.DeleteSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
var
  vHashKey: string;
  vHeightKey: string;
begin
  vHashKey := CreateSnapshotBlockHashKey(ParaSnapshotBlock.Hash).ToString;
  vHeightKey := CreateSnapshotBlockHeightKey(ParaSnapshotBlock.Height).ToString;

  mStore.Delete(vHashKey);
  mStore.Delete(vHeightKey);
end;

function TDataSet.GetAccountBlock(ParaHash: TBytes): TAccountBlock;
var
  vHashKey: string;
  vBlock: TObject;
begin
  vHashKey := CreateAccountBlockHashKey(ParaHash).ToString;
  if mStore.Get(vHashKey, vBlock) then
  begin
    Result := vBlock as TAccountBlock;
  end
  else
  begin
    Result := nil;
  end;
end;

function TDataSet.GetAccountBlockByHeight(ParaAddress: TAddress; ParaHeight: UInt64): TAccountBlock;
var
  vHeightKey: string;
  vHashKeyObj: TObject;
  vHashKey: string;
  vBlock: TObject;
begin
  vHeightKey := CreateAccountBlockHeightKey(ParaAddress, ParaHeight).ToString;
  if mStore.Get(vHeightKey, vHashKeyObj) then
  begin
    vHashKey := string(vHashKeyObj);
    if mStore.Get(vHashKey, vBlock) then
    begin
      Result := vBlock as TAccountBlock;
    end
    else
    begin
      Result := nil;
    end;
  end
  else
  begin
    Result := nil;
  end;
end;

function TDataSet.IsAccountBlockExisted(ParaHash: TBytes): Boolean;
var
  vHashKey: string;
  vDummy: TObject;
begin
  vHashKey := CreateAccountBlockHashKey(ParaHash).ToString;
  Result := mStore.Get(vHashKey, vDummy);
end;

function TDataSet.GetSnapshotBlock(ParaHash: TBytes): TSnapshotBlock;
var
  vHashKey: string;
  vBlock: TObject;
begin
  vHashKey := CreateSnapshotBlockHashKey(ParaHash).ToString;
  if mStore.Get(vHashKey, vBlock) then
  begin
    Result := vBlock as TSnapshotBlock;
  end
  else
  begin
    Result := nil;
  end;
end;

function TDataSet.GetSnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
var
  vHeightKey: string;
  vHashKeyObj: TObject;
  vHashKey: string;
  vBlock: TObject;
begin
  vHeightKey := CreateSnapshotBlockHeightKey(ParaHeight).ToString;
  if mStore.Get(vHeightKey, vHashKeyObj) then
  begin
    vHashKey := string(vHashKeyObj);
    if mStore.Get(vHashKey, vBlock) then
    begin
      Result := vBlock as TSnapshotBlock;
    end
    else
    begin
      Result := nil;
    end;
  end
  else
  begin
    Result := nil;
  end;
end;

function TDataSet.IsSnapshotBlockExisted(ParaHash: TBytes): Boolean;
var
  vHashKey: string;
  vDummy: TObject;
begin
  vHashKey := CreateSnapshotBlockHashKey(ParaHash).ToString;
  Result := mStore.Get(vHashKey, vDummy);
end;

function TDataSet.GetStatus: TArray<IDBStatus>;
var
  vCount: UInt64;
begin
  vCount := mStore.ItemCount;
  SetLength(Result, 1);
  Result[0] := TDBStatus.Create('dataSet.store', vCount, vCount * 400, '');
end;

procedure TDataSet.InternalInsertAccountBlock(ParaAccountBlock: TAccountBlock; ParaDelay: Int64);
var
  vHashKey: string;
  vHeightKey: string;
  vSendBlock: TAccountBlock;
begin
  vHashKey := CreateAccountBlockHashKey(ParaAccountBlock.Hash).ToString;
  vHeightKey := CreateAccountBlockHeightKey(ParaAccountBlock.AccountAddress, ParaAccountBlock.Height).ToString;

  mStore.Set(vHashKey, ParaAccountBlock, ParaDelay);
  mStore.Set(vHeightKey, TObject(vHashKey), ParaDelay);

  for vSendBlock in ParaAccountBlock.SendBlockList do
  begin
    mStore.Set(CreateAccountBlockHashKey(vSendBlock.Hash).ToString, ParaAccountBlock, ParaDelay);
  end;
end;

procedure TDataSet.DeleteStaleSnapshotBlock(ParaHeight: UInt64);
var
  vStaleHeight: UInt64;
  vHeightKey: string;
  vHashObj: TObject;
  vHash: string;
begin
  if ParaHeight <= mSnapshotKeepCount then
  begin
    Exit;
  end;
  vStaleHeight := ParaHeight - mSnapshotKeepCount;
  vHeightKey := CreateSnapshotBlockHeightKey(vStaleHeight).ToString;
  if mStore.Get(vHeightKey, vHashObj) then
  begin
    vHash := string(vHashObj);
    mStore.Delete(vHeightKey);
    mStore.Delete(vHash);
  end;
end;

end.
