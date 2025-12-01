unit Ledger.Pool.Tools.Fetcher;

interface

uses
  System.SysUtils,
  Common.Types,
  Interfaces.Core,
  net.interface;

type
  ICommonSyncer = interface
    ['{F2B2B8B8-8B4B-4B4B-8B4B-4B4B4B4B4B4B}']
    procedure Fetch(hashHeight: IHashHeight; prevCnt: TUInt64);
  end;

  TAccountSyncer = class(TInterfacedObject, ICommonSyncer)
  private
    FAddress: TAddress;
    FFetcher: ISyncer;
    FLog: ILogger;
  public
    constructor Create(AAddress: TAddress; AFetcher: ISyncer; ALog: ILogger);
    procedure BroadcastBlock(block: IAccountBlock);
    procedure BroadcastBlocks(blocks: TArray<IAccountBlock>);
    procedure BroadcastReceivedBlocks(received: IVmAccountBlock; sendBlocks: TArray<IVmAccountBlock>);
    procedure Fetch(hashHeight: IHashHeight; prevCnt: TUInt64);
    procedure FetchBySnapshot(hashHeight: IHashHeight; account: TAddress; prevCnt: TUInt64; sHeight: TUInt64; sHash: THash);
    procedure FetchByHash(hash: THash; prevCnt: TUInt64);
  end;

  TSnapshotSyncer = class(TInterfacedObject, ICommonSyncer)
  private
    FFetcher: ISyncer;
    FLog: ILogger;
  public
    constructor Create(AFetcher: ISyncer; ALog: ILogger);
    procedure BroadcastBlock(block: ISnapshotBlock);
    procedure Fetch(hashHeight: IHashHeight; prevCnt: TUInt64);
    procedure FetchByHash(hash: THash; prevCnt: TUInt64);
  end;

implementation

{ TAccountSyncer }

constructor TAccountSyncer.Create(AAddress: TAddress; AFetcher: ISyncer; ALog: ILogger);
begin
  inherited Create;
  FAddress := AAddress;
  FFetcher := AFetcher;
  FLog := ALog;
end;

procedure TAccountSyncer.BroadcastBlock(block: IAccountBlock);
begin
  FFetcher.BroadcastAccountBlock(block);
end;

procedure TAccountSyncer.BroadcastBlocks(blocks: TArray<IAccountBlock>);
begin
  FFetcher.BroadcastAccountBlocks(blocks);
end;

procedure TAccountSyncer.BroadcastReceivedBlocks(received: IVmAccountBlock; sendBlocks: TArray<IVmAccountBlock>);
var
  vBlocks: TArray<IAccountBlock>;
  vB: IVmAccountBlock;
begin
  SetLength(vBlocks, 1 + Length(sendBlocks));
  vBlocks[0] := received.AccountBlock;
  for vB in sendBlocks do
    vBlocks[Succ(High(vBlocks))] := vB.AccountBlock;
  FFetcher.BroadcastAccountBlocks(vBlocks);
end;

procedure TAccountSyncer.Fetch(hashHeight: IHashHeight; prevCnt: TUInt64);
begin
  if hashHeight.Height > 0 then
  begin
    if prevCnt > 100 then
      prevCnt := 100;
    FLog.Debug('fetch account block', ['height', hashHeight.Height, 'hash', hashHeight.Hash.ToString, 'prevCnt', prevCnt]);
    FFetcher.FetchAccountBlocks(hashHeight.Hash, prevCnt, @FAddress);
  end;
end;

procedure TAccountSyncer.FetchBySnapshot(hashHeight: IHashHeight; account: TAddress; prevCnt: TUInt64; sHeight: TUInt64; sHash: THash);
begin
  if hashHeight.Height > 0 then
  begin
    FLog.Debug('fetch account block', ['height', hashHeight.Height, 'address', account.ToString, 'hash', hashHeight.Hash.ToString, 'prevCnt', prevCnt, 'sHeight', sHeight, 'sHash', sHash.ToString]);
    FFetcher.FetchAccountBlocks(hashHeight.Hash, prevCnt, @FAddress);
  end;
end;

procedure TAccountSyncer.FetchByHash(hash: THash; prevCnt: TUInt64);
begin
  FFetcher.FetchAccountBlocks(hash, prevCnt, @FAddress);
end;

{ TSnapshotSyncer }

constructor TSnapshotSyncer.Create(AFetcher: ISyncer; ALog: ILogger);
begin
  inherited Create;
  FFetcher := AFetcher;
  FLog := ALog;
end;

procedure TSnapshotSyncer.BroadcastBlock(block: ISnapshotBlock);
begin
  FFetcher.BroadcastSnapshotBlock(block);
end;

procedure TSnapshotSyncer.Fetch(hashHeight: IHashHeight; prevCnt: TUInt64);
begin
  if hashHeight.Height > 0 then
  begin
    if prevCnt > 100 then
      prevCnt := 100;
    FLog.Debug('fetch snapshot block', ['height', hashHeight.Height, 'hash', hashHeight.Hash.ToString, 'prevCnt', prevCnt]);
    FFetcher.FetchSnapshotBlocks(hashHeight.Hash, prevCnt);
  end;
end;

procedure TSnapshotSyncer.FetchByHash(hash: THash; prevCnt: TUInt64);
begin
  FFetcher.FetchSnapshotBlocks(hash, prevCnt);
end;

end.
