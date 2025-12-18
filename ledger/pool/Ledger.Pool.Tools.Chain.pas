unit Ledger.Pool.Tools.Chain;

interface

uses
  Common,
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  System.SysUtils System.Generics.Collections;

type
  IChainDb = interface
    ['{F1B2B8B8-8B4B-4B4B-8B4B-4B4B4B4B4B4B}']
    // Event Manager
    procedure Register(listener: IEventListener);
    procedure UnRegister(listener: IEventListener);
    function InsertAccountBlock(vmAccountBlocks: IVmAccountBlock): Exception;
    function GetLatestAccountBlock(addr: TAddress): IAccountBlock;
    function GetAccountBlockByHeight(addr: TAddress; height: TUInt64): IAccountBlock;
    function GetAccountBlockHashByHeight(addr: TAddress; height: TUInt64): ^THash;
    function GetAllUnconfirmedBlocks: TArray<IAccountBlock>;
    function GetSnapshotHeaderByHeight(height: TUInt64): ISnapshotBlock;
    function GetSnapshotBlockByHeight(height: TUInt64): ISnapshotBlock;
    function GetSnapshotBlockByHash(hash: THash): ISnapshotBlock;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSnapshotHeaderByHash(hash: THash): ISnapshotBlock;
    function GetSnapshotHashByHeight(height: TUInt64): ^THash;
    function InsertSnapshotBlock(snapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;
    function DeleteSnapshotBlocksToHeight(toHeight: TUInt64): TArray<ISnapshotChunk>;
    function DeleteAccountBlocksToHeight(addr: TAddress; toHeight: TUInt64): TArray<IAccountBlock>;
    function GetAccountBlockByHash(blockHash: THash): IAccountBlock;
    function IsGenesisSnapshotBlock(hash: THash): Boolean;
    function IsGenesisAccountBlock(block: THash): Boolean;
    function GetQuotaUnused(address: TAddress): TUInt64;
    function GetConfirmedTimes(blockHash: THash): TUInt64;
    function GetContractMeta(contractAddress: TAddress): IContractMeta;
    function GetSnapshotHeaderBeforeTime(timestamp: TDateTime): ISnapshotBlock;
    procedure SetCacheLevelForConsensus(level: Cardinal);
  end;

  TAccountCh = class(TInterfacedObject, IChainRw)
  private
    FAddress: TAddress;
    FRw: IChainDb;
    FVersion: TVersion;
    FLog: ILogger;
  public
    constructor Create(AAddress: TAddress; ARw: IChainDb; AVersion: TVersion; ALog: ILogger);
    function InsertBlock(block: ICommonBlock): Exception;
    function InsertBlocks(blocks: TArray<ICommonBlock>): Exception;
    function Head: ICommonBlock;
    function GetBlock(height: TUInt64): ICommonBlock;
    function GetHash(height: TUInt64): ^THash;
    function DelToHeight(height: TUInt64; out ASnapshots: TArray<ICommonBlock>; out AAccounts: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetQuotaUnused: TUInt64;
    function GetConfirmedTimes(abHash: THash): TUInt64;
    function NeedSnapshot(addr: TAddress): Byte;
  end;

  TSnapshotCh = class(TInterfacedObject, IChainRw)
  private
    FBc: IChainDb;
    FVersion: TVersion;
    FLog: ILogger;
  public
    constructor Create(ABc: IChainDb; AVersion: TVersion; ALog: ILogger);
    function GetBlock(height: TUInt64): ICommonBlock;
    function GetHash(height: TUInt64): ^THash;
    function Head: ICommonBlock;
    function HeadSnapshot: ISnapshotBlock;
    function GetSnapshotBlockByHash(hash: THash): ISnapshotBlock;
    function DelToHeight(height: TUInt64; out ASnapshots: TArray<ICommonBlock>; out AAccounts: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
    function InsertBlock(block: ICommonBlock): Exception;
    function InsertSnapshotBlock(b: TSnapshotPoolBlock; out AAccountBlocks: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
    function InsertBlocks(bs: TArray<ICommonBlock>): Exception;
  end;

implementation

{ TAccountCh }

constructor TAccountCh.Create(AAddress: TAddress; ARw: IChainDb; AVersion: TVersion; ALog: ILogger);
begin
  inherited Create;
  FAddress := AAddress;
  FRw := ARw;
  FVersion := AVersion;
  FLog := ALog;
end;

function TAccountCh.InsertBlock(block: ICommonBlock): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.InsertBlocks(blocks: TArray<ICommonBlock>): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.Head: ICommonBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.GetBlock(height: TUInt64): ICommonBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.GetHash(height: TUInt64): ^THash;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.DelToHeight(height: TUInt64; out ASnapshots: TArray<ICommonBlock>; out AAccounts: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TAccountCh.GetLatestSnapshotBlock: ISnapshotBlock;
begin
  Result := FRw.GetLatestSnapshotBlock;
end;

function TAccountCh.GetQuotaUnused: TUInt64;
begin
  Result := FRw.GetQuotaUnused(FAddress);
end;

function TAccountCh.GetConfirmedTimes(abHash: THash): TUInt64;
begin
  Result := FRw.GetConfirmedTimes(abHash);
end;

function TAccountCh.NeedSnapshot(addr: TAddress): Byte;
var
  vMeta: IContractMeta;
begin
  vMeta := FRw.GetContractMeta(addr);
  if vMeta <> nil then
    Result := vMeta.SendConfirmedTimes
  else
    Result := 0;
end;

{ TSnapshotCh }

constructor TSnapshotCh.Create(ABc: IChainDb; AVersion: TVersion; ALog: ILogger);
begin
  inherited Create;
  FBc := ABc;
  FVersion := AVersion;
  FLog := ALog;
end;

function TSnapshotCh.GetBlock(height: TUInt64): ICommonBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotCh.GetHash(height: TUInt64): ^THash;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotCh.Head: ICommonBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotCh.HeadSnapshot: ISnapshotBlock;
begin
  Result := FBc.GetLatestSnapshotBlock;
end;

function TSnapshotCh.GetSnapshotBlockByHash(hash: THash): ISnapshotBlock;
begin
  Result := FBc.GetSnapshotBlockByHash(hash);
end;

function TSnapshotCh.DelToHeight(height: TUInt64; out ASnapshots: TArray<ICommonBlock>; out AAccounts: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotCh.InsertBlock(block: ICommonBlock): Exception;
begin
  raise Exception.Create('Not implemented');
end;

function TSnapshotCh.InsertSnapshotBlock(b: TSnapshotPoolBlock; out AAccountBlocks: TDictionary<TAddress, TArray<ICommonBlock>>): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotCh.InsertBlocks(bs: TArray<ICommonBlock>): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

end.
