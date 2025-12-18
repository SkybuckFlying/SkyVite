unit RpcApi.Api.Ledger;

interface

uses
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite Common.Types Common.BigInt Ledger.Chain Log15 Vm.Contracts.Dex,
  Vm.Db Vm Ledger Vm.Contracts.Abi Common.Upgrade Ledger.Chain.Plugins,
  Vm.Quota RpcApi.Api.LedgerModel System.Variants;

type
  TGcStatus = record
    Code: Byte;
    Description: string;
    ClearedHeight: UInt64;
    MarkedHeight: UInt64;
  end;

  TGetBalancesRes = TDictionary<TAddress, TDictionary<TTokenTypeId, PBigInt>>;

  TLedgerApi = class
  private
    FVite: TVite;
    FChain: IChain;
    FLog: ILogger;
    function LedgerChunksToRpcChunks(const List: TArray<PSnapshotChunk>): TArray<TSnapshotChunk>;
    function LedgerSnapshotBlockToRpcBlock(const Block: PSnapshotBlock): TSnapshotBlock;
    function LedgerSnapshotBlocksToRpcBlocks(const List: TArray<PSnapshotBlock>): TArray<TSnapshotBlock>;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function GetRawBlockByHash(const BlockHash: THash): PAccountBlock;
    function GetCompleteBlockByHash(const BlockHash: THash): TAccountBlock;
    function GetBlocksByHashInToken(const Addr: TAddress; OriginBlockHash: PHash; const TokenTypeId: TTokenTypeId; Count: UInt64): TArray<TAccountBlock>;
    function GetSnapshotBlockBeforeTime(Timestamp: Int64): TSnapshotBlock;
    function GetVmLogListByHash(const LogHash: THash): TArray<TVmLog>;
    function GetBlocksByHeight(const Addr: TAddress; Height: Variant; Count: UInt64): TArray<TAccountBlock>;
    function GetSnapshotBlockByHash(const Hash: THash): TSnapshotBlock;
    function GetSnapshotBlockByHeight(Height: Variant): TSnapshotBlock;
    function GetSnapshotBlocks(Height: Variant; Count: Integer): TArray<TSnapshotBlock>;
    function GetChunks(StartHeight, EndHeight: Variant): TArray<TSnapshotChunk>;
    function GetSnapshotChainHeight: string;
    function GetLatestSnapshotChainHash: PHash;
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetLatestBlock(const Addr: TAddress): TAccountBlock;
    function GetVmLogList(const BlockHash: THash): TArray<TVmLog>;
    function GetSeed(const SnapshotHash, FromHash: THash): UInt64;
    function GetChainStatus: TArray<IDBStatus>;
    function GetAllUnconfirmedBlocks: TArray<PAccountBlock>;
    function GetUnconfirmedBlocks(const Addr: TAddress): TArray<PAccountBlock>;
    function GetConfirmedBalances(const SnapshotHash: THash; const AddrList: TArray<TAddress>; const TokenIds: TArray<TTokenTypeId>): TGetBalancesRes;
    // Deprecated
    function GetBlockByHash(const BlockHash: THash): TAccountBlock;
    function GetBlocksByHash(const Addr: TAddress; OriginBlockHash: PHash; Count: UInt64): TArray<TAccountBlock>;
    function GetBlockByHeight(const Addr: TAddress; Height: Variant): TAccountBlock;
    function GetBlocksByAccAddr(const Addr: TAddress; Index, Count: Integer): TArray<TAccountBlock>;
    function GetAccountByAccAddr(const Addr: TAddress): TRpcAccountInfo;
  end;

implementation

uses System.DateUtils;

{ TLedgerApi }

constructor TLedgerApi.Create(AVite: TVite);
begin
  FVite := AVite;
  FChain := AVite.Chain;
  FLog := TLog.New('module', 'rpc_api/ledger_api');
end;

function TLedgerApi.GetString: string;
begin
  Result := 'LedgerApi';
end;

function TLedgerApi.LedgerChunksToRpcChunks(const List: TArray<PSnapshotChunk>): TArray<TSnapshotChunk>;
var
  Chunks: TArray<TSnapshotChunk>;
  I: Integer;
  Item: PSnapshotChunk;
  Sb: TSnapshotBlock;
begin
  SetLength(Chunks, Length(List));
  for I := 0 to High(List) do
  begin
    Item := List[I];
    Sb := LedgerSnapshotBlockToRpcBlock(Item.SnapshotBlock);
    Chunks[I].AccountBlocks := Item.AccountBlocks;
    Chunks[I].SnapshotBlock := Sb;
  end;
  Result := Chunks;
end;

function TLedgerApi.LedgerSnapshotBlockToRpcBlock(const Block: PSnapshotBlock): TSnapshotBlock;
begin
  Result := RpcApi.Api.LedgerModel.LedgerSnapshotBlockToRpcBlock(Block);
end;

function TLedgerApi.LedgerSnapshotBlocksToRpcBlocks(const List: TArray<PSnapshotBlock>): TArray<TSnapshotBlock>;
var
  Blocks: TArray<TSnapshotBlock>;
  I: Integer;
  Item: PSnapshotBlock;
  RpcBlock: TSnapshotBlock;
begin
  SetLength(Blocks, Length(List));
  for I := 0 to High(List) do
  begin
    Item := List[I];
    RpcBlock := LedgerSnapshotBlockToRpcBlock(Item);
    Blocks[I] := RpcBlock;
  end;
  Result := Blocks;
end;

function TLedgerApi.GetRawBlockByHash(const BlockHash: THash): PAccountBlock;
begin
  Result := FChain.GetAccountBlockByHash(BlockHash);
end;

function TLedgerApi.GetCompleteBlockByHash(const BlockHash: THash): TAccountBlock;
var
  Block: PAccountBlock;
begin
  Block := FChain.GetCompleteBlockByHash(BlockHash);
  if Block = nil then
    Exit;
  Result := LedgerToRpcBlock(FChain, Block);
end;

function TLedgerApi.GetBlocksByHashInToken(const Addr: TAddress; OriginBlockHash: PHash; const TokenTypeId: TTokenTypeId; Count: UInt64): TArray<TAccountBlock>;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetAccountBlocks(Addr, @OriginBlockHash, @TokenTypeId, Count);
end;

function TLedgerApi.GetSnapshotBlockBeforeTime(Timestamp: Int64): TSnapshotBlock;
var
  Time: TDateTime;
  SbHeader: PSnapshotHeader;
  Sb: PSnapshotBlock;
begin
  Time := TDateTime(Timestamp);
  SbHeader := FChain.GetSnapshotHeaderBeforeTime(@Time);
  if SbHeader = nil then
    Exit;
  Sb := FChain.GetSnapshotBlockByHash(SbHeader.Hash);
  Result := LedgerSnapshotBlockToRpcBlock(Sb);
end;

function TLedgerApi.GetVmLogListByHash(const LogHash: THash): TArray<TVmLog>;
begin
  Result := FChain.GetVmLogList(@LogHash);
end;

function TLedgerApi.GetBlocksByHeight(const Addr: TAddress; Height: Variant; Count: UInt64): TArray<TAccountBlock>;
var
  HeightUint64: UInt64;
  AccountBlocks: TArray<PAccountBlock>;
  ApiV2: TLedgerApiV2;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  HeightUint64 := ParseHeight(Height);
  AccountBlocks := FChain.GetAccountBlocksByHeight(Addr, HeightUint64, Count);
  if Length(AccountBlocks) <= 0 then
    Exit;
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.LedgerBlocksToRpcBlocks(AccountBlocks);
end;

function TLedgerApi.GetSnapshotBlockByHash(const Hash: THash): TSnapshotBlock;
var
  Block: PSnapshotBlock;
begin
  Block := FChain.GetSnapshotBlockByHash(Hash);
  Result := LedgerSnapshotBlockToRpcBlock(Block);
end;

function TLedgerApi.GetSnapshotBlockByHeight(Height: Variant): TSnapshotBlock;
var
  HeightUint64: UInt64;
  Block: PSnapshotBlock;
begin
  HeightUint64 := ParseHeight(Height);
  Block := FChain.GetSnapshotBlockByHeight(HeightUint64);
  Result := LedgerSnapshotBlockToRpcBlock(Block);
end;

function TLedgerApi.GetSnapshotBlocks(Height: Variant; Count: Integer): TArray<TSnapshotBlock>;
var
  HeightUint64: UInt64;
  Blocks: TArray<PSnapshotBlock>;
begin
  if Count > 1000 then
    raise Exception.Create('count must be less than 1000');
  HeightUint64 := ParseHeight(Height);
  Blocks := FChain.GetSnapshotBlocksByHeight(HeightUint64, False, Count);
  Result := LedgerSnapshotBlocksToRpcBlocks(Blocks);
end;

function TLedgerApi.GetChunks(StartHeight, EndHeight: Variant): TArray<TSnapshotChunk>;
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
  if (Length(Chunks) > 0) and ((Chunks[0].SnapshotBlock = nil) or (Chunks[0].SnapshotBlock.Height = StartHeightUint64 - 1)) then
    Chunks := Copy(Chunks, 1, Length(Chunks) - 1);
  Result := LedgerChunksToRpcChunks(Chunks);
end;

function TLedgerApi.GetSnapshotChainHeight: string;
begin
  Result := IntToStr(FChain.GetLatestSnapshotBlock.Height);
end;

function TLedgerApi.GetLatestSnapshotChainHash: PHash;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetLatestSnapshotHash;
end;

function TLedgerApi.GetLatestSnapshotBlock: TSnapshotBlock;
var
  Block: PSnapshotBlock;
begin
  Block := FChain.GetLatestSnapshotBlock;
  Result := LedgerSnapshotBlockToRpcBlock(Block);
end;

function TLedgerApi.GetLatestBlock(const Addr: TAddress): TAccountBlock;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetLatestAccountBlock(Addr);
end;

function TLedgerApi.GetVmLogList(const BlockHash: THash): TArray<TVmLog>;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetVmLogs(BlockHash);
end;

function TLedgerApi.GetSeed(const SnapshotHash, FromHash: THash): UInt64;
var
  Sb: PSnapshotBlock;
begin
  Sb := FChain.GetSnapshotBlockByHash(SnapshotHash);
  Result := FChain.GetSeed(Sb, FromHash);
end;

function TLedgerApi.GetChainStatus: TArray<IDBStatus>;
begin
  Result := FChain.GetStatus;
end;

function TLedgerApi.GetAllUnconfirmedBlocks: TArray<PAccountBlock>;
begin
  Result := FChain.GetAllUnconfirmedBlocks;
end;

function TLedgerApi.GetUnconfirmedBlocks(const Addr: TAddress): TArray<PAccountBlock>;
begin
  Result := FChain.GetUnconfirmedBlocks(Addr);
end;

function TLedgerApi.GetConfirmedBalances(const SnapshotHash: THash; const AddrList: TArray<TAddress>; const TokenIds: TArray<TTokenTypeId>): TGetBalancesRes;
var
  Res: TGetBalancesRes;
  TokenId: TTokenTypeId;
  Balances: TDictionary<TAddress, PBigInt>;
  Addr: TAddress;
  Balance: PBigInt;
  AddrBalances: TDictionary<TTokenTypeId, PBigInt>;
begin
  if (Length(AddrList) <= 0) or (Length(TokenIds) <= 0) then
    Exit;
  Res := TGetBalancesRes.Create;
  for TokenId in TokenIds do
  begin
    Balances := FChain.GetConfirmedBalanceList(AddrList, TokenId, SnapshotHash);
    if Balances = nil then
      raise Exception.Create(Format('snapshot block %s is not existed.', [SnapshotHash.ToString]));
    for Addr in Balances.Keys do
    begin
      Balance := Balances[Addr];
      if not Res.TryGetValue(Addr, AddrBalances) then
      begin
        AddrBalances := TDictionary<TTokenTypeId, PBigInt>.Create;
        Res.Add(Addr, AddrBalances);
      end;
      AddrBalances.Add(TokenId, Balance);
    end;
  end;
  Result := Res;
end;

function TLedgerApi.GetBlockByHash(const BlockHash: THash): TAccountBlock;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetAccountBlockByHash(BlockHash);
end;

function TLedgerApi.GetBlocksByHash(const Addr: TAddress; OriginBlockHash: PHash; Count: UInt64): TArray<TAccountBlock>;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetAccountBlocks(Addr, @OriginBlockHash, nil, Count);
end;

function TLedgerApi.GetBlockByHeight(const Addr: TAddress; Height: Variant): TAccountBlock;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetAccountBlockByHeight(Addr, Height);
end;

function TLedgerApi.GetBlocksByAccAddr(const Addr: TAddress; Index, Count: Integer): TArray<TAccountBlock>;
var
  ApiV2: TLedgerApiV2;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Result := ApiV2.GetAccountBlocksByAddress(Addr, Index, Count);
end;

function TLedgerApi.GetAccountByAccAddr(const Addr: TAddress): TRpcAccountInfo;
var
  ApiV2: TLedgerApiV2;
  Info: PAccountInfo;
begin
  ApiV2 := TLedgerApiV2.Create(FVite);
  Info := ApiV2.GetAccountInfoByAddress(Addr);
  Result := ToRpcAccountInfo(FChain, Info);
end;

end.
