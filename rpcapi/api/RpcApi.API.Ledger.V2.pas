unit RpcApi.Api.LedgerV2;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.Types, Common.BigInt, Ledger.Chain, Log15, Vm.Contracts.Dex,
  Vm.Db, Vm, Ledger, Vm.Contracts.Abi, Common.Upgrade, Ledger.Chain.Plugins,
  Vm.Quota, RpcApi.Api.LedgerModel;

type
  TLedgerApiV2 = class
  private
    FChain: IChain;
    FVite: TVite;
    FLog: ILogger;
    function LedgerBlocksToRpcBlocks(const List: TArray<PAccountBlock>): TArray<TAccountBlock>;
    function LedgerBlockToRpcBlock(const Block: PAccountBlock): TAccountBlock;
    function GetAccountInfoByAddress(const Addr: TAddress): PAccountInfo;
    function LedgerChunksToRpcChunksV2(const Chunks: TArray<PSnapshotChunk>): TArray<TSnapshotChunkV2>;
  public
    constructor Create(AVite: TVite);
    function GetAccountBlocks(const Addr: TAddress; OriginBlockHash: PHash; TokenTypeId: PTokenTypeId; Count: UInt64): TArray<TAccountBlock>;
    function GetAccountBlockByHash(const BlockHash: THash): TAccountBlock;
    function GetAccountBlockByHeight(const Addr: TAddress; Height: Variant): TAccountBlock;
    function GetAccountBlocksByAddress(const Addr: TAddress; Index, Count: Integer): TArray<TAccountBlock>;
    function GetAccountBlocksByHeightRange(const Addr: TAddress; Start, &End: UInt64): TArray<TAccountBlock>;
    function GetAccountInfoByAddressV2(const Addr: TAddress): TAccountInfo;
    function GetLatestSnapshotHash: PHash;
    function GetLatestAccountBlock(const Addr: TAddress): TAccountBlock;
    function GetVmLogs(const BlockHash: THash): TArray<TVmLog>;
    procedure SendRawTransaction(const Block: TAccountBlock);
    function GetUnreceivedBlocksByAddress(const Address: TAddress; Index, Count: UInt64): TArray<TAccountBlock>;
    function GetUnreceivedTransactionSummaryByAddress(const Address: TAddress): TAccountInfo;
    function GetUnreceivedBlocksInBatch(const QueryList: TArray<TPagingQueryBatch>): TDictionary<TAddress, TArray<TAccountBlock>>;
    function GetUnreceivedTransactionSummaryInBatch(const AddressList: TArray<TAddress>): TArray<TAccountInfo>;
    function GetVmLogsByFilter(const Param: TVmLogFilterParam): TArray<TLogs>;
    function GetPoWDifficulty(const Param: TGetPoWDifficultyParam): TGetPoWDifficultyResult;
    function GetRequiredQuota(const Param: TGetQuotaRequiredParam): TGetQuotaRequiredResult;
    function GetChunksV2(StartHeight, EndHeight: Variant): TArray<TSnapshotChunkV2>;
    function GetUpgradeInfo: TObject;
  end;

implementation

uses System.StrUtils, System.Variants;

function ParseHeight(Height: Variant): UInt64;
begin
  if VarIsStr(Height) then
    Result := StrToUInt64(Height)
  else
    Result := Height;
end;

function CheckTxToAddressAvailable(const ToAddress: TAddress): Boolean;
begin
  // Implementation needed
  Result := True;
end;

function CheckTokenIdValid(AChain: IChain; TokenId: PTokenTypeId): Boolean;
begin
  // Implementation needed
  Result := True;
end;

function CheckSnapshotValid(Sb: PSnapshotBlock): Boolean;
begin
  // Implementation needed
  Result := True;
end;

function GetLogs(C: IChain; RangeMap: TDictionary<string, TRange>; Topics: TArray<TArray<THash>>; PageIndex, PageSize: UInt64): TArray<TLogs>;
begin
  // Implementation needed
end;

function FilterLog(Filter: PFilterParam; L: PVMMLog): Boolean;
begin
  // Implementation needed
end;

function GetHeightPage(Start, &End, Count: UInt64; out Offset: UInt64): Boolean;
begin
  // Implementation needed
end;

function CalcPoWDifficulty(C: IChain; Param: TCalcPoWDifficultyParam): TCalcPoWDifficultyResult;
begin
  // Implementation needed
end;

function CalcQuotaRequired(C: IChain; Param: TCalcQuotaRequiredParam): TCalcQuotaRequiredResult;
begin
  // Implementation needed
end;

{ TLedgerApiV2 }

constructor TLedgerApiV2.Create(AVite: TVite);
begin
  FVite := AVite;
  FChain := AVite.Chain;
  FLog := TLog.New('module', 'rpc_api/ledger_v2');
end;

function TLedgerApiV2.LedgerBlocksToRpcBlocks(const List: TArray<PAccountBlock>): TArray<TAccountBlock>;
var
  Blocks: TArray<TAccountBlock>;
  I: Integer;
begin
  SetLength(Blocks, Length(List));
  for I := 0 to High(List) do
    Blocks[I] := LedgerToRpcBlock(FChain, List[I]);
  Result := Blocks;
end;

function TLedgerApiV2.LedgerBlockToRpcBlock(const Block: PAccountBlock): TAccountBlock;
begin
  Result := LedgerToRpcBlock(FChain, Block);
end;

function TLedgerApiV2.GetAccountBlocks(const Addr: TAddress; OriginBlockHash: PHash; TokenTypeId: PTokenTypeId; Count: UInt64): TArray<TAccountBlock>;
var
  Block: PAccountBlock;
  List: TArray<PAccountBlock>;
  Plugins: IPlugins;
  Plugin: TFilterToken;
  Blocks: TArray<PAccountBlock>;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');

  if TokenTypeId = nil then
  begin
    if OriginBlockHash = nil then
    begin
      Block := FChain.GetLatestAccountBlock(Addr);
      if Block <> nil then
        OriginBlockHash := @Block.Hash;
    end;
    if OriginBlockHash = nil then
      Exit;
    List := FChain.GetAccountBlocks(OriginBlockHash^, Count);
    Result := LedgerBlocksToRpcBlocks(List);
  end
  else
  begin
    if Count = 0 then
      Exit;
    Plugins := FChain.Plugins;
    if Plugins = nil then
      raise Exception.Create('config.OpenPlugins is false, api can''t work');
    Plugin := Plugins.GetPlugin('filterToken') as TFilterToken;
    Blocks := Plugin.GetBlocks(Addr, TokenTypeId^, OriginBlockHash, Count);
    Result := LedgerBlocksToRpcBlocks(Blocks);
  end;
end;

function TLedgerApiV2.GetAccountBlockByHash(const BlockHash: THash): TAccountBlock;
var
  Block: PAccountBlock;
begin
  Block := FChain.GetAccountBlockByHash(BlockHash);
  if Block = nil then
    Exit;
  Result := LedgerBlockToRpcBlock(Block);
end;

function TLedgerApiV2.GetAccountBlockByHeight(const Addr: TAddress; Height: Variant): TAccountBlock;
var
  HeightUint64: UInt64;
  AccountBlock: PAccountBlock;
begin
  HeightUint64 := ParseHeight(Height);
  AccountBlock := FChain.GetAccountBlockByHeight(Addr, HeightUint64);
  if AccountBlock = nil then
    Exit;
  Result := LedgerBlockToRpcBlock(AccountBlock);
end;

function TLedgerApiV2.GetAccountBlocksByAddress(const Addr: TAddress; Index, Count: Integer): TArray<TAccountBlock>;
var
  Height, Num: UInt64;
  List: TArray<PAccountBlock>;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  Height := FChain.GetLatestAccountHeight(Addr);
  Num := UInt64(Index * Count);
  if Height < Num then
    Exit;
  List := FChain.GetAccountBlocksByHeight(Addr, Height - Num, Count);
  Result := LedgerBlocksToRpcBlocks(List);
end;

function TLedgerApiV2.GetAccountBlocksByHeightRange(const Addr: TAddress; Start, &End: UInt64): TArray<TAccountBlock>;
var
  List: TArray<PAccountBlock>;
begin
  if &End - Start > 1000 then
    raise Exception.Create('height range must be less than 1000');
  List := FChain.GetAccountBlocksByRange(Addr, Start, &End);
  Result := LedgerBlocksToRpcBlocks(List);
end;

function TLedgerApiV2.GetAccountInfoByAddress(const Addr: TAddress): PAccountInfo;
var
  LatestAccountBlock: PAccountBlock;
  TotalNum: UInt64;
  BalanceMap: TDictionary<TTokenTypeId, PBigInt>;
  TokenBalanceInfoMap: TDictionary<TTokenTypeId, PTokenBalanceInfo>;
  TokenId: TTokenTypeId;
  Amount: PBigInt;
  Token: PTokenInfo;
  TotalAmount: TBigInt;
begin
  LatestAccountBlock := FChain.GetLatestAccountBlock(Addr);
  TotalNum := 0;
  if LatestAccountBlock <> nil then
    TotalNum := LatestAccountBlock.Height;
  BalanceMap := FChain.GetBalanceMap(Addr);
  TokenBalanceInfoMap := TDictionary<TTokenTypeId, PTokenBalanceInfo>.Create;
  for TokenId in BalanceMap.Keys do
  begin
    Amount := BalanceMap[TokenId];
    Token := FChain.GetTokenInfoById(TokenId);
    if Token = nil then
      Continue;
    TotalAmount := TBigInteger.Create(0);
    if Amount <> nil then
      TotalAmount := Amount^;
    TokenBalanceInfoMap.Add(TokenId, TTokenBalanceInfo.Create(TotalAmount, 0));
  end;
  Result := TAccountInfo.Create(Addr, TotalNum, TokenBalanceInfoMap);
end;

function TLedgerApiV2.GetAccountInfoByAddressV2(const Addr: TAddress): TAccountInfo;
var
  Info: PAccountInfo;
begin
  Info := GetAccountInfoByAddress(Addr);
  Result := ToAccountInfo(FChain, Info);
end;

function TLedgerApiV2.GetLatestSnapshotHash: PHash;
begin
  Result := @FChain.GetLatestSnapshotBlock.Hash;
end;

function TLedgerApiV2.GetLatestAccountBlock(const Addr: TAddress): TAccountBlock;
var
  Block: PAccountBlock;
begin
  Block := FChain.GetLatestAccountBlock(Addr);
  if Block = nil then
    Exit;
  Result := LedgerBlockToRpcBlock(Block);
end;

function TLedgerApiV2.GetVmLogs(const BlockHash: THash): TArray<TVmLog>;
var
  Block: PAccountBlock;
begin
  Block := FChain.GetAccountBlockByHash(BlockHash);
  if Block = nil then
    raise Exception.Create('get block failed');
  Result := FChain.GetVmLogList(Block.LogHash);
end;

procedure TLedgerApiV2.SendRawTransaction(const Block: TAccountBlock);
var
  Lb: TAccountBlock;
  LatestSb: PSnapshotBlock;
  Result: PAccountBlock;
begin
  if not CheckTxToAddressAvailable(Block.ToAddress) then
    raise Exception.Create('ToAddress is invalid');
  Lb := Block.RpcToLedgerBlock;
  if not CheckTokenIdValid(FChain, @Lb.TokenId) then
    raise Exception.Create('Invalid token id');
  LatestSb := FChain.GetLatestSnapshotBlock;
  if LatestSb = nil then
    raise Exception.Create('failed to get latest snapshotBlock');
  if not CheckSnapshotValid(LatestSb) then
    raise Exception.Create('Invalid snapshot');
  if (Lb.ToAddress = TAddress.DexFund) and (not TDex.VerifyNewOrderPriceForRpc(Lb.Data)) then
    raise Exception.Create(SInvalidOrderPriceErr);
  Result := FVite.Verifier.VerifyRPCAccountBlock(Lb, LatestSb);
  if Result <> nil then
    FVite.Pool.AddDirectAccountBlock(Result.AccountAddress, Result)
  else
    raise Exception.Create('generator gen an empty block');
end;

function TLedgerApiV2.GetUnreceivedBlocksByAddress(const Address: TAddress; Index, Count: UInt64): TArray<TAccountBlock>;
var
  BlockList: TArray<PAccountBlock>;
  A: TArray<TAccountBlock>;
  Sum: Integer;
  V: PAccountBlock;
  AccountBlock: TAccountBlock;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  BlockList := FChain.GetOnRoadBlocksByAddr(Address, Integer(Index), Integer(Count));
  SetLength(A, Length(BlockList));
  Sum := 0;
  for V in BlockList do
  begin
    if V <> nil then
    begin
      AccountBlock := LedgerToRpcBlock(FChain, V);
      A[Sum] := AccountBlock;
      Inc(Sum);
    end;
  end;
  Result := Copy(A, 0, Sum);
end;

function TLedgerApiV2.GetUnreceivedTransactionSummaryByAddress(const Address: TAddress): TAccountInfo;
var
  Info: PAccountInfo;
begin
  Info := FChain.GetAccountOnRoadInfo(Address);
  if Info = nil then
    Exit;
  Result := ToAccountInfo(FChain, Info);
end;

function TLedgerApiV2.GetUnreceivedBlocksInBatch(const QueryList: TArray<TPagingQueryBatch>): TDictionary<TAddress, TArray<TAccountBlock>>;
var
  ResultMap: TDictionary<TAddress, TArray<TAccountBlock>>;
  Q: TPagingQueryBatch;
  L: TArray<TAccountBlock>;
  BlockList: TArray<TAccountBlock>;
begin
  for Q in QueryList do
    if Q.PageCount > 1000 then
      raise Exception.Create('pageCount must be less than 1000');
  ResultMap := TDictionary<TAddress, TArray<TAccountBlock>>.Create;
  for Q in QueryList do
  begin
    if ResultMap.TryGetValue(Q.Address, L) and (L <> nil) then
      Continue;
    BlockList := GetUnreceivedBlocksByAddress(Q.Address, Q.PageNumber, Q.PageCount);
    if Length(BlockList) <= 0 then
      Continue;
    ResultMap.Add(Q.Address, BlockList);
  end;
  Result := ResultMap;
end;

function TLedgerApiV2.GetUnreceivedTransactionSummaryInBatch(const AddressList: TArray<TAddress>): TArray<TAccountInfo>;
var
  AddrMap: TDictionary<TAddress, Boolean>;
  V, Addr: TAddress;
  ResultList: TArray<TAccountInfo>;
  Info: TAccountInfo;
begin
  AddrMap := TDictionary<TAddress, Boolean>.Create;
  for V in AddressList do
    AddrMap.Add(V, True);
  SetLength(ResultList, 0);
  for Addr in AddrMap.Keys do
  begin
    Info := GetUnreceivedTransactionSummaryByAddress(Addr);
    ResultList := ResultList + [Info];
  end;
  Result := ResultList;
end;

function TLedgerApiV2.GetVmLogsByFilter(const Param: TVmLogFilterParam): TArray<TLogs>;
begin
  Result := GetLogs(FChain, Param.AddrRange, Param.Topics, Param.PageIndex, Param.PageSize);
end;

function TLedgerApiV2.GetPoWDifficulty(const Param: TGetPoWDifficultyParam): TGetPoWDifficultyResult;
var
  Res: TCalcPoWDifficultyResult;
begin
  Res := CalcPoWDifficulty(FChain, TCalcPoWDifficultyParam.Create(Param.SelfAddr, Param.PrevHash, Param.BlockType, Param.ToAddr, Param.Data, True, Param.Multiple));
  Result.Quota := Res.QuotaRequired;
  Result.Difficulty := Res.Difficulty;
  Result.Qc := Res.Qc;
  Result.IsCongestion := Res.IsCongestion;
end;

function TLedgerApiV2.GetRequiredQuota(const Param: TGetQuotaRequiredParam): TGetQuotaRequiredResult;
var
  Res: TCalcQuotaRequiredResult;
begin
  Res := CalcQuotaRequired(FChain, TCalcQuotaRequiredParam.Create(Param.SelfAddr, Param.BlockType, Param.ToAddr, Param.Data));
  Result.QuotaRequired := Res.QuotaRequired;
end;

function TLedgerApiV2.LedgerChunksToRpcChunksV2(const Chunks: TArray<PSnapshotChunk>): TArray<TSnapshotChunkV2>;
var
  RpcChunks: TArray<TSnapshotChunkV2>;
  I: Integer;
  Chunk: PSnapshotChunk;
  RpcChunk: TSnapshotChunkV2;
  J: Integer;
  Block: PAccountBlock;
begin
  SetLength(RpcChunks, Length(Chunks));
  for I := 0 to High(Chunks) do
  begin
    Chunk := Chunks[I];
    SetLength(RpcChunk.AccountBlocks, Length(Chunk.AccountBlocks));
    for J := 0 to High(Chunk.AccountBlocks) do
    begin
      Block := Chunk.AccountBlocks[J];
      RpcChunk.AccountBlocks[J] := LedgerToRpcBlock(FChain, Block);
    end;
    RpcChunk.SnapshotBlock := LedgerSnapshotBlockToRpcBlock(Chunk.SnapshotBlock);
    RpcChunks[I] := RpcChunk;
  end;
  Result := RpcChunks;
end;

function TLedgerApiV2.GetChunksV2(StartHeight, EndHeight: Variant): TArray<TSnapshotChunkV2>;
var
  StartHeightUint64, EndHeightUint64: UInt64;
  Chunks: TArray<PSnapshotChunk>;
begin
  StartHeightUint64 := ParseHeight(StartHeight);
  EndHeightUint64 := ParseHeight(EndHeight);
  if StartHeightUint64 > EndHeightUint64 then
    raise Exception.Create('startHeight must be less than endHeight');
  if EndHeightUint64 - StartHeightUint64 > 1000 then
    raise Exception.Create('height range must be less than 1000');
  Chunks := FChain.GetSubLedger(StartHeightUint64 - 1, EndHeightUint64);
  if (Length(Chunks) > 0) and (Chunks[0].SnapshotBlock <> nil) and (Chunks[0].SnapshotBlock.Height = StartHeightUint64 - 1) then
    Chunks := Copy(Chunks, 1, Length(Chunks) - 1);
  Result := LedgerChunksToRpcChunksV2(Chunks);
end;

function TLedgerApiV2.GetUpgradeInfo: TObject;
begin
  Result := TUpgrade.GetAllPoints;
end;

end.
