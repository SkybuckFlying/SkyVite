unit Ledger.Pool.Snapshot.Pool;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Pool,
  Ledger.Pool.Tree,
  Ledger.Pool.Batch,
  Ledger.Verifier,
  Common;

type
  TSnapshotPoolBlock = class(TInterfacedObject, IItem)
  private
    FBlock: ISnapshotBlock;
    FForkBlock: TForkBlock;
    FLastCheckTime: TDateTime;
    FCheckResult: Boolean;
    FFailStat: TFailStat;
  public
    constructor Create(ABlock: ISnapshotBlock; AVersion: TVersion; ASource: TBlockSource);
    function ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
    function Owner: ^TAddress;
    function Hash: THash;
    function Height: TUInt64;
    function PrevHash: THash;
    function Ready: Boolean;
  end;

  TSnapshotPool = class(TBCPool)
  private
    FClosed: TEvent;
    FPool: TPool;
    FRw: TSnapshotCh;
    FV: TSnapshotVerifier;
    FF: TSnapshotSyncer;
    FNextFetchTime: TDateTime;
    FHashBlacklist: IBlacklist;
    FNewSnapshotBlockCond: TCondTimer;
    FIrreversible: TIrreversibleInfo;
  public
    constructor Create(AName: string; AVersion: TVersion; AV: TSnapshotVerifier; AF: TSnapshotSyncer; ARw: TSnapshotCh; AHashBlacklist: IBlacklist; ACond: TCondTimer; ALog: ILogger);
    procedure Init(ATools: ITools; APool: TPool);
    function CheckFork(out ALongestH: TUInt64; out AError: Exception): IBranch;
    function SnapshotFork(ALongest, ACurrent: IBranch): Exception;
    procedure Loop;
    function LoopCompactSnapshot: Integer;
    function SnapshotInsertItems(AP: IBatch; AItems: TArray<IItem>; AVersion: TUInt64; out AAccBlocks: TDictionary<TAddress, TArray<ICommonBlock>>; out AItem: IItem): Exception;
    function SnapshotWriteToChain(ABlock: TSnapshotPoolBlock): TDictionary<TAddress, TArray<ICommonBlock>>;
    procedure Start;
    procedure Stop;
    function AddDirectBlock(ABlock: TSnapshotPoolBlock): TDictionary<TAddress, TArray<ICommonBlock>>;
    procedure LoopFetchForSnapshot;
    function GetCurrentBlock(i: TUInt64): TSnapshotPoolBlock;
    procedure FetchAccounts(AAccounts: TDictionary<TAddress, IHashHeight>; ASHeight: TUInt64; ASHash: THash);
    function GenMaxAccounts(ATargetHeight: TUInt64): TDictionary<TAddress, IHashHeight>;
  end;

implementation

{ TSnapshotPoolBlock }

constructor TSnapshotPoolBlock.Create(ABlock: ISnapshotBlock; AVersion: TVersion; ASource: TBlockSource);
begin
  inherited Create;
  FBlock := ABlock;
  FForkBlock := NewForkBlock(AVersion, ASource);
  FFailStat := TFailStat.Create(20 * 1000);
end;

function TSnapshotPoolBlock.ReferHashes: TTuple<TArray<THash>, TArray<THash>, THash>;
var
  vAccounts: TArray<THash>;
  vSnapshot: THash;
  vKeys: TArray<THash>;
  vPair: TPair<TAddress, IHashHeight>;
begin
  SetLength(vAccounts, 0);
  for vPair in FBlock.SnapshotContent do
    vAccounts := vAccounts + [vPair.Value.Hash];

  if Height > 1 then // GenesisHeight
    vSnapshot := PrevHash;

  vKeys := vKeys + [Hash];
  Result := TTuple<TArray<THash>, TArray<THash>, THash>.Create(vKeys, vAccounts, vSnapshot);
end;

function TSnapshotPoolBlock.Owner: ^TAddress;
begin
  Result := nil;
end;

function TSnapshotPoolBlock.Hash: THash;
begin
  Result := FBlock.Hash;
end;

function TSnapshotPoolBlock.Height: TUInt64;
begin
  Result := FBlock.Height;
end;

function TSnapshotPoolBlock.PrevHash: THash;
begin
  Result := FBlock.PrevHash;
end;

function TSnapshotPoolBlock.Ready: Boolean;
begin
  Result := FBlock.Timestamp <= Now + OneSecond;
end;

{ TSnapshotPool }

constructor TSnapshotPool.Create(AName: string; AVersion: TVersion; AV: TSnapshotVerifier; AF: TSnapshotSyncer; ARw: TSnapshotCh; AHashBlacklist: IBlacklist; ACond: TCondTimer; ALog: ILogger);
begin
  inherited Create;
  Self.ID := AName;
  Self.FVersion := AVersion;
  Self.FRw := ARw;
  Self.FV := AV;
  Self.FF := AF;
  Self.FLog := ALog;
  Self.FNextFetchTime := Now;
  Self.FHashBlacklist := AHashBlacklist;
  Self.FNewSnapshotBlockCond := ACond;
end;

procedure TSnapshotPool.Init(ATools: ITools; APool: TPool);
begin
  FPool := APool;
  inherited Init(ATools);
end;

function TSnapshotPool.CheckFork(out ALongestH: TUInt64; out AError: Exception): IBranch;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotPool.SnapshotFork(ALongest, ACurrent: IBranch): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

procedure TSnapshotPool.Loop;
begin
  // Implementation to be added
end;

function TSnapshotPool.LoopCompactSnapshot: Integer;
begin
  // Implementation to be added
  Result := 0;
end;

function TSnapshotPool.SnapshotInsertItems(AP: IBatch; AItems: TArray<IItem>; AVersion: TUInt64; out AAccBlocks: TDictionary<TAddress, TArray<ICommonBlock>>; out AItem: IItem): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TSnapshotPool.SnapshotWriteToChain(ABlock: TSnapshotPoolBlock): TDictionary<TAddress, TArray<ICommonBlock>>;
begin
  // Implementation to be added
  Result := nil;
end;

procedure TSnapshotPool.Start;
begin
  FClosed := TEvent.Create(nil, True, False, '');
  FLog.Info('snapshot_pool started.');
end;

procedure TSnapshotPool.Stop;
begin
  FClosed.SetEvent;
  FLog.Info('snapshot_pool stopped.');
end;

function TSnapshotPool.AddDirectBlock(ABlock: TSnapshotPoolBlock): TDictionary<TAddress, TArray<ICommonBlock>>;
begin
  // Implementation to be added
  Result := nil;
end;

procedure TSnapshotPool.LoopFetchForSnapshot;
begin
  // Implementation to be added
end;

function TSnapshotPool.GetCurrentBlock(i: TUInt64): TSnapshotPoolBlock;
begin
  // Implementation to be added
  Result := nil;
end;

procedure TSnapshotPool.FetchAccounts(AAccounts: TDictionary<TAddress, IHashHeight>; ASHeight: TUInt64; ASHash: THash);
begin
  // Implementation to be added
end;

function TSnapshotPool.GenMaxAccounts(ATargetHeight: TUInt64): TDictionary<TAddress, IHashHeight>;
begin
  // Implementation to be added
  Result := nil;
end;

end.
