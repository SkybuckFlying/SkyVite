unit Ledger.Chain.Plugins.Filter.Token;

interface

uses
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.Plugins.DB.Key.Prefix,
  Ledger.Chain.Plugins.Interface,
  Ledger.Chain.Plugins.Onroad.Info,
  Ledger.Chain.Plugins.Onroad.Info.Test,
  Ledger.Chain.Plugins.Plugins,
  System.Generics.Collections,
  System.SysUtils;

type
  TFilterToken = class(TInterfacedObject, IPlugin)
  private
    FStore: TStore;
    FChain: IChain;
  public
    constructor Create(AStore: TStore; AChain: IChain);
    procedure SetStore(AStore: TStore);
    function InsertAccountBlock(ABatch: TBatch; AAccountBlock: TAccountBlock): HResult;
    function InsertSnapshotBlock(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
    function DeleteAccountBlocks(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
    function DeleteSnapshotBlocks(ABatch: TBatch; AChunks: TArray<TSnapshotChunk>): HResult;
    function RemoveNewUnconfirmed(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
    function GetBlocks(const AAddr: TAddress; const ATokenId: TTokenTypeId; ABlockHash: PHash; ACount: UInt64; out ABlocks: TArray<TAccountBlock>): HResult;
  end;

function NewFilterToken(AStore: TStore; AChain: IChain): IPlugin;

implementation

uses
  Ledger.Chain.Utils;

function CreateDiffTokenKey(const AAddr: TAddress; const ATokenId: TTokenTypeId; AHeight: UInt64): TBytes;
var
  vAddrBytes, vTokenIdBytes, vHeightBytes: TBytes;
begin
  vAddrBytes := AAddr.Bytes;
  vTokenIdBytes := ATokenId.Bytes;
  vHeightBytes := Uint64ToBytes(AHeight);
  SetLength(Result, 1 + Length(vAddrBytes) + Length(vTokenIdBytes) + Length(vHeightBytes));
  Result[0] := Ord(DiffTokenHash);
  System.Move(vAddrBytes[0], Result[1], Length(vAddrBytes));
  System.Move(vTokenIdBytes[0], Result[1 + Length(vAddrBytes)], Length(vTokenIdBytes));
  System.Move(vHeightBytes[0], Result[1 + Length(vAddrBytes) + Length(vTokenIdBytes)], Length(vHeightBytes));
end;

{ TFilterToken }

constructor TFilterToken.Create(AStore: TStore; AChain: IChain);
begin
  inherited Create;
  FStore := AStore;
  FChain := AChain;
end;

procedure TFilterToken.SetStore(AStore: TStore);
begin
  FStore := AStore;
end;

function TFilterToken.InsertAccountBlock(ABatch: TBatch; AAccountBlock: TAccountBlock): HResult;
var
  vTokenTypeId: TTokenTypeId;
  vSendBlock: TAccountBlock;
begin
  if AAccountBlock.BlockType = TBlockType.GenesisReceive then
  begin
    ABatch.Put(CreateDiffTokenKey(AAccountBlock.AccountAddress, ViteTokenId, AAccountBlock.Height), AAccountBlock.Hash.Bytes);
    ABatch.Put(CreateDiffTokenKey(AAccountBlock.AccountAddress, VCPTokenId, AAccountBlock.Height), AAccountBlock.Hash.Bytes);
    Exit(S_OK);
  end;

  if AAccountBlock.IsReceiveBlock then
  begin
    vSendBlock := FChain.GetAccountBlockByHash(AAccountBlock.FromBlockHash);
    if vSendBlock = nil then
      raise Exception.Create('send block is nil');
    vTokenTypeId := vSendBlock.TokenId;
  end
  else
  begin
    vTokenTypeId := AAccountBlock.TokenId;
  end;

  ABatch.Put(CreateDiffTokenKey(AAccountBlock.AccountAddress, vTokenTypeId, AAccountBlock.Height), AAccountBlock.Hash.Bytes);

  for var SendBlock in AAccountBlock.SendBlockList do
    ABatch.Put(CreateDiffTokenKey(AAccountBlock.AccountAddress, SendBlock.TokenId, AAccountBlock.Height), AAccountBlock.Hash.Bytes);

  Result := S_OK;
end;

function TFilterToken.InsertSnapshotBlock(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
begin
  Result := S_OK;
end;

function TFilterToken.DeleteAccountBlocks(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
var
  vSendBlocksMap: TDictionary<THash, TAccountBlock>;
begin
  vSendBlocksMap := TDictionary<THash, TAccountBlock>.Create;
  try
    Result := Self.DeleteAccountBlocks(ABatch, AAccountBlocks, vSendBlocksMap);
  finally
    vSendBlocksMap.Free;
  end;
end;

function TFilterToken.DeleteSnapshotBlocks(ABatch: TBatch; AChunks: TArray<TSnapshotChunk>): HResult;
var
  vSendBlocksMap: TDictionary<THash, TAccountBlock>;
  Chunk: TSnapshotChunk;
begin
  vSendBlocksMap := TDictionary<THash, TAccountBlock>.Create;
  try
    for Chunk in AChunks do
    begin
      if Self.DeleteAccountBlocks(ABatch, Chunk.AccountBlocks, vSendBlocksMap) <> S_OK then
        Exit(E_FAIL);
    end;
    Result := S_OK;
  finally
    vSendBlocksMap.Free;
  end;
end;

function TFilterToken.RemoveNewUnconfirmed(ABatch: TBatch; AAccountBlocks: TArray<TAccountBlock>): HResult;
begin
  Result := S_OK;
end;

function TFilterToken.GetBlocks(const AAddr: TAddress; const ATokenId: TTokenTypeId; ABlockHash: PHash; ACount: UInt64; out ABlocks: TArray<TAccountBlock>): HResult;
var
  vMaxHeight: UInt64;
  vBlock: TAccountBlock;
  vFromBlock: TAccountBlock;
  vBlockTokenId: TTokenTypeId;
  vIter: IIterator;
  vValue: TBytes;
  vHash: THash;
  vIndex: UInt64;
begin
  vMaxHeight := High(UInt64);
  if ABlockHash <> nil then
  begin
    vBlock := FChain.GetAccountBlockByHash(ABlockHash^);
    if vBlock = nil then
      raise Exception.Create(Format('block %s is not exited', [ABlockHash.ToString]));

    if vBlock.BlockType <> TBlockType.GenesisReceive then
    begin
      if vBlock.IsReceiveBlock then
      begin
        vFromBlock := FChain.GetAccountBlockByHash(vBlock.FromBlockHash);
        if vFromBlock = nil then
          raise Exception.Create(Format('from block %s is nil', [vBlock.FromBlockHash.ToString]));
        vBlockTokenId := vFromBlock.TokenId;
      end
      else
        vBlockTokenId := vBlock.TokenId;
      if vBlockTokenId <> ATokenId then
      begin
        SetLength(ABlocks, 0);
        Exit(S_OK);
      end;
    end;
    vMaxHeight := vBlock.Height + 1;
  end;

  vIter := FStore.NewIterator(TRange.Create(CreateDiffTokenKey(AAddr, ATokenId, 0), CreateDiffTokenKey(AAddr, ATokenId, vMaxHeight)));
  try
    var vIterOk := vIter.Last;
    vIndex := 0;
    SetLength(ABlocks, 0);
    while vIterOk and (vIndex < ACount) do
    begin
      vValue := vIter.Value;
      vHash := THash.FromBytes(vValue);
      vBlock := FChain.GetAccountBlockByHash(vHash);
      if vBlock <> nil then
      begin
        SetLength(ABlocks, Length(ABlocks) + 1);
        ABlocks[High(ABlocks)] := vBlock;
      end;
      Inc(vIndex);
      vIterOk := vIter.Prev;
    end;
  finally
    vIter := nil;
  end;
  Result := S_OK;
end;

function NewFilterToken(AStore: TStore; AChain: IChain): IPlugin;
begin
  Result := TFilterToken.Create(AStore, AChain);
end;

end.
