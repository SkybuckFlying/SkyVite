unit chain.unconfirmed;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  Vite.Common,
  Vite.Core,
  Vite.Types,
  Vite.Upgrade,
  Vite.Vm.Quota,
  consensus.core;

type
  TChainUnconfirmed = class(TObject)
  private
    FChain: TChain;
    function CheckQuota(QuotaUnusedCache, QuotaUsedCache: TDictionary<TAddress, UInt64>; Block: TAccountBlock; SbHeight: UInt64): Boolean;
    function FilterConsensusFailed(const Blocks: TArray<TAccountBlock>): TArray<TAccountBlock>;
  public
    constructor Create(AChain: TChain);
    function GetAllUnconfirmedBlocks: TArray<TAccountBlock>;
    function GetUnconfirmedBlocks(const Addr: TAddress): TArray<TAccountBlock>;
    function GetContentNeedSnapshot: TSnapshotContent;
    function GetContentNeedSnapshotRange: TDictionary<TAddress, THeightRange>;
    function FilterUnconfirmedBlocks(SnapshotBlock: TSnapshotBlock; CheckConsensus: Boolean): TArray<TAccountBlock>;
    function ComputeDependencies(const AccountBlocks: TArray<TAccountBlock>): TArray<TAccountBlock>;
  end;

implementation

{ TChainUnconfirmed }

constructor TChainUnconfirmed.Create(AChain: TChain);
begin
  FChain := AChain;
end;

function TChainUnconfirmed.GetAllUnconfirmedBlocks: TArray<TAccountBlock>;
begin
  Result := FChain.Cache.GetUnconfirmedBlocks;
end;

function TChainUnconfirmed.GetUnconfirmedBlocks(const Addr: TAddress): TArray<TAccountBlock>;
begin
  Result := FChain.Cache.GetUnconfirmedBlocksByAddress(Addr);
end;

function TChainUnconfirmed.GetContentNeedSnapshot: TSnapshotContent;
const
  MaxSnapshotLength = 40000;
var
  UnconfirmedBlocks: TArray<TAccountBlock>;
  Sc: TSnapshotContent;
  I: Integer;
  Block: TAccountBlock;
begin
  UnconfirmedBlocks := FChain.Cache.GetUnconfirmedBlocks;
  Sc := TSnapshotContent.Create;
  if Length(UnconfirmedBlocks) > MaxSnapshotLength then
    SetLength(UnconfirmedBlocks, MaxSnapshotLength);

  for I := High(UnconfirmedBlocks) downto 0 do
  begin
    Block := UnconfirmedBlocks[I];
    if not Sc.ContainsKey(Block.AccountAddress) then
      Sc.Add(Block.AccountAddress, THashHeight.Create(Block.Hash, Block.Height));
  end;
  Result := Sc;
end;

function TChainUnconfirmed.GetContentNeedSnapshotRange: TDictionary<TAddress, THeightRange>;
const
  MaxSnapshotLength = 40000;
var
  UnconfirmedBlocks: TArray<TAccountBlock>;
  ResultMap: TDictionary<TAddress, THeightRange>;
  Block: TAccountBlock;
  Rg: THeightRange;
begin
  UnconfirmedBlocks := FChain.Cache.GetUnconfirmedBlocks;
  ResultMap := TDictionary<TAddress, THeightRange>.Create;
  if Length(UnconfirmedBlocks) > MaxSnapshotLength then
    SetLength(UnconfirmedBlocks, MaxSnapshotLength);

  for Block in UnconfirmedBlocks do
  begin
    if ResultMap.TryGetValue(Block.AccountAddress, Rg) then
      Rg.Update(Block.Height, Block.Hash)
    else
      ResultMap.Add(Block.AccountAddress, THeightRange.Create(Block.Height, Block.Hash));
  end;
  Result := ResultMap;
end;

function TChainUnconfirmed.FilterUnconfirmedBlocks(SnapshotBlock: TSnapshotBlock; CheckConsensus: Boolean): TArray<TAccountBlock>;
var
  Blocks: TArray<TAccountBlock>;
  InvalidConsensusBlocks: TDictionary<THash, TAccountBlock>;
  InvalidBlocks: TArray<TAccountBlock>;
  InvalidAddrSet: TDictionary<TAddress, Boolean>;
  InvalidHashSet: TDictionary<THash, Boolean>;
  QuotaUsedCache: TDictionary<TAddress, UInt64>;
  QuotaUnusedCache: TDictionary<TAddress, UInt64>;
  Block: TAccountBlock;
  Valid: Boolean;
  Addr: TAddress;
  Enough: Boolean;
  CErr: string;
begin
  Blocks := FChain.Cache.GetUnconfirmedBlocks;
  if Length(Blocks) <= 0 then
    Exit(nil);

  if IsUpgradePoint(SnapshotBlock.Height) then
    Exit(Blocks);

  InvalidConsensusBlocks := TDictionary<THash, TAccountBlock>.Create;
  if CheckConsensus then
  begin
    try
      InvalidBlocks := FilterConsensusFailed(Blocks);
      for Block in InvalidBlocks do
        InvalidConsensusBlocks.Add(Block.Hash, Block);
    except
      on E: Exception do
      begin
        FChain.Log.Error(Format('filterConsensusFailed. Error: %s', [E.Message]), 'method', 'filterInvalidUnconfirmedBlocks');
        Exit(Blocks);
      end;
    end;
  end;

  SetLength(InvalidBlocks, 0);
  InvalidAddrSet := TDictionary<TAddress, Boolean>.Create;
  InvalidHashSet := TDictionary<THash, Boolean>.Create;
  QuotaUsedCache := TDictionary<TAddress, UInt64>.Create;
  QuotaUnusedCache := TDictionary<TAddress, UInt64>.Create;

  for Block in Blocks do
  begin
    Valid := True;
    Addr := Block.AccountAddress;

    if InvalidAddrSet.ContainsKey(Addr) then
      Valid := False;

    if Valid and Block.IsReceiveBlock then
    begin
      if Block.BlockType = TBlockType.ReceiveError then
        Valid := False
      else if InvalidHashSet.ContainsKey(Block.FromBlockHash) then
        Valid := False;
    end;

    if Valid and CheckConsensus then
    begin
      if InvalidConsensusBlocks.ContainsKey(Block.Hash) then
      begin
        Valid := False;
        FChain.Log.Info(Format('will delete block %s, height is %d, addr is %s, invalid consensus', [Block.Hash.ToString, Block.Height, Block.AccountAddress.ToString]), 'method', 'filterInvalidUnconfirmedBlocks');
      end;
    end;

    if Valid then
    begin
      try
        Block.Quota := CalcBlockQuotaUsed(FChain, Block, SnapshotBlock.Height);
      except
        on E: Exception do
        begin
          FChain.Log.Error(Format('quota.CalcBlockQuotaUsed failed when filterUnconfirmedBlocks. Error: %s', [E.Message]), 'method', 'filterInvalidUnconfirmedBlocks');
          Valid := False;
        end;
      end;

      if Valid then
      begin
        try
          Enough := CheckQuota(QuotaUnusedCache, QuotaUsedCache, Block, SnapshotBlock.Height);
          if not Enough then
          begin
            Valid := False;
            FChain.Log.Info(Format('will delete block %s, height is %d, addr is %s, quota is not enough.', [Block.Hash.ToString, Block.Height, Block.AccountAddress.ToString]), 'method', 'filterInvalidUnconfirmedBlocks');
          end;
        except
          on E: Exception do
          begin
            CErr := Format('FChain.checkQuota failed, block is %s. Error: %s', [Block.ToString, E.Message]);
            FChain.Log.Error(CErr, 'method', 'filterInvalidUnconfirmedBlocks');
            Valid := False;
          end;
        end;
      end;
    end;

    if not Valid then
    begin
      InvalidAddrSet.Add(Block.AccountAddress, True);
      if Block.IsSendBlock then
        InvalidHashSet.Add(Block.Hash, True);
      for var SendBlock in Block.SendBlockList do
        InvalidHashSet.Add(SendBlock.Hash, True);
      InvalidBlocks := Concat(InvalidBlocks, [Block]);
    end;
  end;

  Result := InvalidBlocks;
end;

function TChainUnconfirmed.CheckQuota(QuotaUnusedCache, QuotaUsedCache: TDictionary<TAddress, UInt64>; Block: TAccountBlock; SbHeight: UInt64): Boolean;
var
  QuotaUnused: UInt64;
  Amount: TBigInteger;
begin
  if not QuotaUnusedCache.TryGetValue(Block.AccountAddress, QuotaUnused) then
  begin
    try
      Amount := FChain.GetStakeBeneficialAmount(Block.AccountAddress);
      QuotaUnused := GetSnapshotCurrentQuota(FChain, Block.AccountAddress, Amount, SbHeight);
      QuotaUnusedCache.Add(Block.AccountAddress, QuotaUnused);
    except
      on E: Exception do
        raise E;
    end;
  end;

  if QuotaUsedCache.ContainsKey(Block.AccountAddress) then
    QuotaUsedCache[Block.AccountAddress] := QuotaUsedCache[Block.AccountAddress] + Block.Quota
  else
    QuotaUsedCache.Add(Block.AccountAddress, Block.Quota);

  if QuotaUsedCache[Block.AccountAddress] > QuotaUnused then
    Exit(False);

  Result := True;
end;

function TChainUnconfirmed.ComputeDependencies(const AccountBlocks: TArray<TAccountBlock>): TArray<TAccountBlock>;
var
  NewAccountBlocks: TArray<TAccountBlock>;
  FirstAccountBlock: TAccountBlock;
  AddrSet: TDictionary<TAddress, Boolean>;
  HashSet: TDictionary<THash, Boolean>;
  I: Integer;
  AccountBlock: TAccountBlock;
begin
  SetLength(NewAccountBlocks, 0);
  if Length(AccountBlocks) = 0 then
    Exit(NewAccountBlocks);

  NewAccountBlocks := Concat(NewAccountBlocks, [AccountBlocks[0]]);
  FirstAccountBlock := AccountBlocks[0];

  AddrSet := TDictionary<TAddress, Boolean>.Create;
  AddrSet.Add(FirstAccountBlock.AccountAddress, True);

  HashSet := TDictionary<THash, Boolean>.Create;
  HashSet.Add(FirstAccountBlock.Hash, True);
  for var SendBlock in FirstAccountBlock.SendBlockList do
    HashSet.Add(SendBlock.Hash, True);

  for I := 1 to High(AccountBlocks) do
  begin
    AccountBlock := AccountBlocks[I];
    if AddrSet.ContainsKey(AccountBlock.AccountAddress) then
    begin
      NewAccountBlocks := Concat(NewAccountBlocks, [AccountBlock]);
      if AccountBlock.IsSendBlock then
        HashSet.Add(AccountBlock.Hash, True);
      for var SendBlock in AccountBlock.SendBlockList do
        HashSet.Add(SendBlock.Hash, True);
    end
    else if AccountBlock.IsReceiveBlock then
    begin
      if HashSet.ContainsKey(AccountBlock.FromBlockHash) then
      begin
        NewAccountBlocks := Concat(NewAccountBlocks, [AccountBlock]);
        AddrSet.Add(AccountBlock.AccountAddress, True);
        for var SendBlock in AccountBlock.SendBlockList do
          HashSet.Add(SendBlock.Hash, True);
      end;
    end;
  end;

  Result := NewAccountBlocks;
end;

function TChainUnconfirmed.FilterConsensusFailed(const Blocks: TArray<TAccountBlock>): TArray<TAccountBlock>;
var
  ContractMetaCache: TDictionary<TAddress, TContractMeta>;
  NeedVerifyBlocks: TDictionary<TGid, TArray<TAccountBlock>>;
  Block: TAccountBlock;
  Addr: TAddress;
  Meta: TContractMeta;
  Gid: TGid;
  BlockArray: TArray<TAccountBlock>;
begin
  ContractMetaCache := TDictionary<TAddress, TContractMeta>.Create;
  NeedVerifyBlocks := TDictionary<TGid, TArray<TAccountBlock>>.Create;

  for Block in Blocks do
  begin
    Addr := Block.AccountAddress;
    if not IsContractAddr(Addr) then
      Continue;

    if not ContractMetaCache.TryGetValue(Addr, Meta) then
    begin
      try
        Meta := FChain.GetContractMeta(Addr);
        if Meta = nil then
          raise Exception.Create(Format('%s, meta is nil', [Addr.ToString]));
        ContractMetaCache.Add(Addr, Meta);
      except
        on E: Exception do
          raise E;
      end;
    end;

    Gid := Meta.Gid;
    if NeedVerifyBlocks.TryGetValue(Gid, BlockArray) then
      NeedVerifyBlocks[Gid] := Concat(BlockArray, [Block])
    else
      NeedVerifyBlocks.Add(Gid, [Block]);
  end;

  Result := FChain.Verifier.VerifyABsProducer(NeedVerifyBlocks);
end;

end.