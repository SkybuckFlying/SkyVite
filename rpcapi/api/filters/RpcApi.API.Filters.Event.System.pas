unit RpcApi.Api.Filters.EventSystem;

interface

uses
  RpcApi.API.Filters.Chain.Subscribe,
  RpcApi.Api.Filters.ChainSubscribe GoToDelphi.Helpers.TChannel,
  RpcApi.API.Filters.Subscribe,
  System.SysUtils System.Classes System.Generics.Collections System.Threading,
  Vite Common.Types Interfaces.Core Log15 Rpc RpcApi.Api;

type
  TFilterType = (
    LogsSubscription,
    LogsSubscriptionV2,
    AccountBlocksSubscription,
    AccountBlocksWithHeightSubscription,
    AccountBlocksWithHeightSubscriptionV2,
    OnroadBlocksSubscription,
    OnroadBlocksSubscriptionV2,
    SnapshotBlocksSubscription,
    SnapshotBlocksSubscriptionV2
  );

  TSnapshotBlock = class
  public
    Hash: THash;
    Height: UInt64;
    HeightStr: string;
    Removed: Boolean;
  end;

  TAccountBlock = class
  public
    Hash: THash;
    Removed: Boolean;
  end;

  TAccountBlockWithHeight = class
  public
    Height: UInt64;
    HeightStr: string;
    Hash: THash;
    Removed: Boolean;
  end;

  TLogs = class
  public
    Log: IVmLog;
    AccountBlockHash: THash;
    AccountBlockHeight: string;
    Address: TAddress;
    Removed: Boolean;
  end;

  TOnroadMsg = class
  public
    Hash: THash;
    Closed: Boolean;
    Removed: Boolean;
  end;

  TSubscription = class
  private
    FId: TRpcId;
    FType: TFilterType;
    FCreateTime: TDateTime;
    FInstalled: TEvent;
    FErr: TChannel<Exception>;
    FParam: TFilterParam;
    FAddr: TAddress;
    FSnapshotBlockCh: TChannel<TArray<TSnapshotBlock>>;
    FAccountBlockCh: TChannel<TArray<TAccountBlock>>;
    FAccountBlockWithHeightCh: TChannel<TArray<TAccountBlockWithHeight>>;
    FLogsCh: TChannel<TArray<TLogs>>;
    FOnroadMsgCh: TChannel<TArray<TOnroadMsg>>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TEventSystem = class
  private
    FVite: TVite;
    FChain: TChainSubscribe;
    FInstall: TChannel<TSubscription>;
    FUninstall: TChannel<TSubscription>;
    FAcCh: TChannel<TArray<TAccountChainEvent>>;
    FAcDelCh: TChannel<TArray<TAccountChainEvent>>;
    FSbCh: TChannel<TArray<TSnapshotChainEvent>>;
    FSbDelCh: TChannel<TArray<TSnapshotChainEvent>>;
    FStop: TEvent;
    FLog: ILogger;
    FThread: TThread;
    procedure EventLoop;
    procedure HandleSbEvent(const Filters: TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>; const SbEvent: TArray<TSnapshotChainEvent>; Removed: Boolean);
    procedure HandleAcEvent(const Filters: TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>; const AcEvent: TArray<TAccountChainEvent>; Removed: Boolean);
    function AppendOnroadMsg(const OnroadMsgs: TDictionary<TAddress, TArray<TOnroadMsg>>; const ToAddr: TAddress; const Hash: THash; Closed, Removed: Boolean): TDictionary<TAddress, TArray<TOnroadMsg>>;
    function FilterLogs(const E: TAccountChainEvent; const Filter: TFilterParam; Removed: Boolean): TArray<TLogs>;
  public
    constructor Create(V: TVite);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Subscribe(S: TSubscription): TRpcSubscription;
    function SubscribeAccountBlocks(Ch: TChannel<TArray<TAccountBlock>>): TRpcSubscription;
    function SubscribeAccountBlocksByAddr(Addr: TAddress; Ch: TChannel<TArray<TAccountBlockWithHeight>>; Ft: TFilterType): TRpcSubscription;
    function SubscribeOnroadBlocksByAddr(Addr: TAddress; Ch: TChannel<TArray<TOnroadMsg>>; Ft: TFilterType): TRpcSubscription;
    function SubscribeSnapshotBlocks(Ch: TChannel<TArray<TSnapshotBlock>>; Ft: TFilterType): TRpcSubscription;
    function SubscribeLogs(P: TFilterParam; Ch: TChannel<TArray<TLogs>>; Ft: TFilterType): TRpcSubscription;
  end;

  TRpcSubscription = class
  private
    FId: TRpcId;
    FSub: TSubscription;
    FUnSubscribed: Boolean;
    FEs: TEventSystem;
  public
    constructor Create(Id: TRpcId; Sub: TSubscription; Es: TEventSystem);
    function Err: TChannel<Exception>;
    procedure Unsubscribe;
  end;

var
  Es: TEventSystem;

const
  AcChanSize = 100;
  AcDelChanSize = 10;
  SbChanSize = 10;
  SbDelChanSize = 10;
  InstallSize = 10;
  UninstallSize = 10;

implementation

{ TSubscription }

constructor TSubscription.Create;
begin
  FInstalled := TEvent.Create(nil, True, False, '');
  FErr := TChannel<Exception>.Create;
  FSnapshotBlockCh := TChannel<TArray<TSnapshotBlock>>.Create;
  FAccountBlockCh := TChannel<TArray<TAccountBlock>>.Create;
  FAccountBlockWithHeightCh := TChannel<TArray<TAccountBlockWithHeight>>.Create;
  FLogsCh := TChannel<TArray<TLogs>>.Create;
  FOnroadMsgCh := TChannel<TArray<TOnroadMsg>>.Create;
end;

destructor TSubscription.Destroy;
begin
  FInstalled.Free;
  FErr.Free;
  FSnapshotBlockCh.Free;
  FAccountBlockCh.Free;
  FAccountBlockWithHeightCh.Free;
  FLogsCh.Free;
  FOnroadMsgCh.Free;
  inherited;
end;

{ TEventSystem }

constructor TEventSystem.Create(V: TVite);
begin
  FVite := V;
  FAcCh := TChannel<TArray<TAccountChainEvent>>.Create(AcChanSize);
  FAcDelCh := TChannel<TArray<TAccountChainEvent>>.Create(AcDelChanSize);
  FSbCh := TChannel<TArray<TSnapshotChainEvent>>.Create(SbChanSize);
  FSbDelCh := TChannel<TArray<TSnapshotChainEvent>>.Create(SbDelChanSize);
  FInstall := TChannel<TSubscription>.Create(InstallSize);
  FUninstall := TChannel<TSubscription>.Create(UninstallSize);
  FStop := TEvent.Create(nil, True, False, '');
  FLog := TLog15.New('module', 'rpc_api/event_system');
end;

destructor TEventSystem.Destroy;
begin
  Stop;
  FChain.Free;
  FAcCh.Free;
  FAcDelCh.Free;
  FSbCh.Free;
  FSbDelCh.Free;
  FInstall.Free;
  FUninstall.Free;
  FStop.Free;
  if Assigned(FThread) then
    FThread.Free;
  inherited;
end;

procedure TEventSystem.Start;
begin
  FChain := TChainSubscribe.Create(FVite, Self);
  FThread := TThread.CreateAnonymousThread(EventLoop);
  FThread.Start;
end;

procedure TEventSystem.Stop;
begin
  FStop.SetEvent;
  FChain.Stop;
  if Assigned(FThread) then
    FThread.WaitFor;
end;

procedure TEventSystem.EventLoop;
var
  Index: TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>;
  I: TFilterType;
  AcEvent, AcDelEvent: TArray<TAccountChainEvent>;
  SbEvent, SbDelEvent: TArray<TSnapshotChainEvent>;
  Subscription: TSubscription;
  Subscriptions: TDictionary<TRpcId, TSubscription>;
  Sel: Integer;
begin
  FLog.Info('start event loop');
  Index := TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>.Create;
  for I := Low(TFilterType) to High(TFilterType) do
    Index.Add(I, TDictionary<TRpcId, TSubscription>.Create);

  while not FStop.WaitFor(0) do
  begin
    Sel := TChannel.Select([FAcCh, FAcDelCh, FSbCh, FSbDelCh, FInstall, FUninstall]);
    case Sel of
      0: if FAcCh.TryReceive(AcEvent) then HandleAcEvent(Index, AcEvent, False);
      1: if FAcDelCh.TryReceive(AcDelEvent) then HandleAcEvent(Index, AcDelEvent, True);
      2: if FSbCh.TryReceive(SbEvent) then HandleSbEvent(Index, SbEvent, False);
      3: if FSbDelCh.TryReceive(SbDelEvent) then HandleSbEvent(Index, SbDelEvent, True);
      4: if FInstall.TryReceive(Subscription) then
         begin
           FLog.Info('install ', ['id', Subscription.FId]);
           Index[Subscription.FType].Add(Subscription.FId, Subscription);
           Subscription.FInstalled.SetEvent;
         end;
      5: if FUninstall.TryReceive(Subscription) then
         begin
           FLog.Info('uninstall ', ['id', Subscription.FId]);
           Index[Subscription.FType].Remove(Subscription.FId);
           Subscription.FErr.CompleteAdding;
         end;
    end;
  end;

  for Subscriptions in Index.Values do
  begin
    for Subscription in Subscriptions.Values do
      Subscription.FErr.CompleteAdding;
  end;
  Index.Free;
  FLog.Info('stop event loop');
end;

procedure TEventSystem.HandleSbEvent(const Filters: TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>; const SbEvent: TArray<TSnapshotChainEvent>; Removed: Boolean);
var
  Blocks: TArray<TSnapshotBlock>;
  I: Integer;
  E: TSnapshotChainEvent;
  F: TSubscription;
begin
  if Length(SbEvent) = 0 then
    Exit;
  SetLength(Blocks, Length(SbEvent));
  for I := 0 to High(SbEvent) do
  begin
    E := SbEvent[I];
    Blocks[I] := TSnapshotBlock.Create;
    Blocks[I].Hash := E.Hash;
    Blocks[I].Height := E.Height;
    Blocks[I].HeightStr := Uint64ToString(E.Height);
    Blocks[I].Removed := Removed;
  end;
  for F in Filters[SnapshotBlocksSubscription].Values do
    F.FSnapshotBlockCh.Add(Blocks);
  for F in Filters[SnapshotBlocksSubscriptionV2].Values do
    F.FSnapshotBlockCh.Add(Blocks);
end;

procedure TEventSystem.HandleAcEvent(const Filters: TDictionary<TFilterType, TDictionary<TRpcId, TSubscription>>; const AcEvent: TArray<TAccountChainEvent>; Removed: Boolean);
var
  Msgs: TArray<TAccountBlock>;
  HeightMsgs: TDictionary<TAddress, TArray<TAccountBlockWithHeight>>;
  OnroadMsgs: TDictionary<TAddress, TArray<TOnroadMsg>>;
  DeletedSendBlockHash: TDictionary<THash, TAddress>;
  I: Integer;
  E: TAccountChainEvent;
  SendBlock: TSendBlock;
  F: TSubscription;
  HashHeightMsgs: TArray<TAccountBlockWithHeight>;
  OnroadMsgsForAddr: TArray<TOnroadMsg>;
  Logs: TArray<TLogs>;
  MatchedLogs: TArray<TLogs>;
  DeletedSendHash: THash;
  ToAddr: TAddress;
begin
  if Length(AcEvent) = 0 then
    Exit;
  SetLength(Msgs, Length(AcEvent));
  HeightMsgs := TDictionary<TAddress, TArray<TAccountBlockWithHeight>>.Create;
  OnroadMsgs := TDictionary<TAddress, TArray<TOnroadMsg>>.Create;
  DeletedSendBlockHash := TDictionary<THash, TAddress>.Create;
  for I := 0 to High(AcEvent) do
  begin
    E := AcEvent[I];
    Msgs[I] := TAccountBlock.Create;
    Msgs[I].Hash := E.Hash;
    Msgs[I].Removed := Removed;
    if not HeightMsgs.ContainsKey(E.Addr) then
      HeightMsgs.Add(E.Addr, TArray<TAccountBlockWithHeight>.Create);
    HeightMsgs[E.Addr] := Concat(HeightMsgs[E.Addr], [TAccountBlockWithHeight.Create(E.Height, Uint64ToString(E.Height), E.Hash, Removed)]);

    if Removed then
    begin
      if IsSendBlock(E.BlockType) then
        DeletedSendBlockHash.Add(E.Hash, E.ToAddr)
      else if Length(E.SendBlockList) > 0 then
      begin
        for SendBlock in E.SendBlockList do
          DeletedSendBlockHash.Add(SendBlock.Hash, SendBlock.ToAddr);
      end;
    end
    else
    begin
      if IsSendBlock(E.BlockType) then
        OnroadMsgs := AppendOnroadMsg(OnroadMsgs, E.ToAddr, E.Hash, False, Removed)
      else
      begin
        OnroadMsgs := AppendOnroadMsg(OnroadMsgs, E.Addr, E.FromBlockHash, True, Removed);
        if Length(E.SendBlockList) > 0 then
        begin
          for SendBlock in E.SendBlockList do
            OnroadMsgs := AppendOnroadMsg(OnroadMsgs, SendBlock.ToAddr, SendBlock.Hash, False, Removed);
        end;
      end;
    end;
  end;
  if Removed then
  begin
    for E in AcEvent do
    begin
      if IsReceiveBlock(E.BlockType) then
      begin
        if not DeletedSendBlockHash.ContainsKey(E.FromBlockHash) then
          OnroadMsgs := AppendOnroadMsg(OnroadMsgs, E.Addr, E.FromBlockHash, False, False)
        else
          DeletedSendBlockHash.Remove(E.FromBlockHash);
      end;
    end;
  end;
  for DeletedSendHash in DeletedSendBlockHash.Keys do
  begin
    ToAddr := DeletedSendBlockHash[DeletedSendHash];
    OnroadMsgs := AppendOnroadMsg(OnroadMsgs, ToAddr, DeletedSendHash, False, True);
  end;
  // handle account blocks
  for F in Filters[AccountBlocksSubscription].Values do
    F.FAccountBlockCh.Add(Msgs);
  // handle accountBlocksWithHeight
  for F in Filters[AccountBlocksWithHeightSubscription].Values do
  begin
    if HeightMsgs.TryGetValue(F.FAddr, HashHeightMsgs) then
      F.FAccountBlockWithHeightCh.Add(HashHeightMsgs);
  end;
  for F in Filters[AccountBlocksWithHeightSubscriptionV2].Values do
  begin
    if HeightMsgs.TryGetValue(F.FAddr, HashHeightMsgs) then
      F.FAccountBlockWithHeightCh.Add(HashHeightMsgs);
  end;
  // handle onroad blocks
  for F in Filters[OnroadBlocksSubscription].Values do
  begin
    if OnroadMsgs.TryGetValue(F.FAddr, OnroadMsgsForAddr) then
      F.FOnroadMsgCh.Add(OnroadMsgsForAddr);
  end;
  for F in Filters[OnroadBlocksSubscriptionV2].Values do
  begin
    if OnroadMsgs.TryGetValue(F.FAddr, OnroadMsgsForAddr) then
      F.FOnroadMsgCh.Add(OnroadMsgsForAddr);
  end;
  // handle logs
  for F in Filters[LogsSubscription].Values do
  begin
    Logs := TArray<TLogs>.Create;
    for E in AcEvent do
    begin
      MatchedLogs := FilterLogs(E, F.FParam, Removed);
      if Length(MatchedLogs) > 0 then
        Logs := Concat(Logs, MatchedLogs);
    end;
    if Length(Logs) > 0 then
      F.FLogsCh.Add(Logs);
  end;
  for F in Filters[LogsSubscriptionV2].Values do
  begin
    Logs := TArray<TLogs>.Create;
    for E in AcEvent do
    begin
      MatchedLogs := FilterLogs(E, F.FParam, Removed);
      if Length(MatchedLogs) > 0 then
        Logs := Concat(Logs, MatchedLogs);
    end;
    if Length(Logs) > 0 then
      F.FLogsCh.Add(Logs);
  end;
end;

function TEventSystem.AppendOnroadMsg(const OnroadMsgs: TDictionary<TAddress, TArray<TOnroadMsg>>; const ToAddr: TAddress; const Hash: THash; Closed, Removed: Boolean): TDictionary<TAddress, TArray<TOnroadMsg>>;
begin
  if not OnroadMsgs.ContainsKey(ToAddr) then
    OnroadMsgs.Add(ToAddr, TArray<TOnroadMsg>.Create);
  OnroadMsgs[ToAddr] := Concat(OnroadMsgs[ToAddr], [TOnroadMsg.Create(Hash, Closed, Removed)]);
  Result := OnroadMsgs;
end;

function TEventSystem.FilterLogs(const E: TAccountChainEvent; const Filter: TFilterParam; Removed: Boolean): TArray<TLogs>;
var
  Logs: TArray<TLogs>;
  Hr: THeightRange;
  L: IVmLog;
begin
  if Length(E.Logs) = 0 then
    Exit(nil);
  if Filter.AddrRange <> nil then
  begin
    if not Filter.AddrRange.TryGetValue(E.Addr, Hr) then
      Exit(nil)
    else if ((Hr.FromHeight > 0) and (Hr.FromHeight > E.Height)) or ((Hr.ToHeight > 0) and (Hr.ToHeight < E.Height)) then
      Exit(nil);
  end;
  for L in E.Logs do
  begin
    if FilterLog(Filter, L) then
      Logs := Concat(Logs, [TLogs.Create(L, E.Hash, Uint64ToString(E.Height), E.Addr, Removed)]);
  end;
  Result := Logs;
end;

function TEventSystem.Subscribe(S: TSubscription): TRpcSubscription;
begin
  FInstall.Add(S);
  S.FInstalled.WaitFor;
  Result := TRpcSubscription.Create(S.FId, S, Self);
end;

function TEventSystem.SubscribeAccountBlocks(Ch: TChannel<TArray<TAccountBlock>>): TRpcSubscription;
var
  Sub: TSubscription;
begin
  Sub := TSubscription.Create;
  Sub.FId := TRpc.NewID;
  Sub.FType := AccountBlocksSubscription;
  Sub.FCreateTime := Now;
  Sub.FAccountBlockCh := Ch;
  Result := Subscribe(Sub);
end;

function TEventSystem.SubscribeAccountBlocksByAddr(Addr: TAddress; Ch: TChannel<TArray<TAccountBlockWithHeight>>; Ft: TFilterType): TRpcSubscription;
var
  Sub: TSubscription;
begin
  Sub := TSubscription.Create;
  Sub.FId := TRpc.NewID;
  Sub.FType := Ft;
  Sub.FAddr := Addr;
  Sub.FCreateTime := Now;
  Sub.FAccountBlockWithHeightCh := Ch;
  Result := Subscribe(Sub);
end;

function TEventSystem.SubscribeOnroadBlocksByAddr(Addr: TAddress; Ch: TChannel<TArray<TOnroadMsg>>; Ft: TFilterType): TRpcSubscription;
var
  Sub: TSubscription;
begin
  Sub := TSubscription.Create;
  Sub.FId := TRpc.NewID;
  Sub.FType := Ft;
  Sub.FAddr := Addr;
  Sub.FCreateTime := Now;
  Sub.FOnroadMsgCh := Ch;
  Result := Subscribe(Sub);
end;

function TEventSystem.SubscribeSnapshotBlocks(Ch: TChannel<TArray<TSnapshotBlock>>; Ft: TFilterType): TRpcSubscription;
var
  Sub: TSubscription;
begin
  Sub := TSubscription.Create;
  Sub.FId := TRpc.NewID;
  Sub.FType := Ft;
  Sub.FCreateTime := Now;
  Sub.FSnapshotBlockCh := Ch;
  Result := Subscribe(Sub);
end;

function TEventSystem.SubscribeLogs(P: TFilterParam; Ch: TChannel<TArray<TLogs>>; Ft: TFilterType): TRpcSubscription;
var
  Sub: TSubscription;
begin
  Sub := TSubscription.Create;
  Sub.FId := TRpc.NewID;
  Sub.FType := Ft;
  Sub.FParam := P;
  Sub.FCreateTime := Now;
  Sub.FLogsCh := Ch;
  Result := Subscribe(Sub);
end;

{ TRpcSubscription }

constructor TRpcSubscription.Create(Id: TRpcId; Sub: TSubscription; Es: TEventSystem);
begin
  FId := Id;
  FSub := Sub;
  FEs := Es;
end;

function TRpcSubscription.Err: TChannel<Exception>;
begin
  Result := FSub.FErr;
end;

procedure TRpcSubscription.Unsubscribe;
var
  DummyAB: TArray<TAccountBlock>;
  DummyABWH: TArray<TAccountBlockWithHeight>;
  DummyL: TArray<TLogs>;
  DummySB: TArray<TSnapshotBlock>;
  DummyOM: TArray<TOnroadMsg>;
begin
  if not FUnSubscribed then
  begin
    FUnSubscribed := True;
    while True do
    begin
      if FEs.FUninstall.TryAdd(FSub) then
        Break
      else if FSub.FAccountBlockCh.TryReceive(DummyAB) then
      else if FSub.FAccountBlockWithHeightCh.TryReceive(DummyABWH) then
      else if FSub.FLogsCh.TryReceive(DummyL) then
      else if FSub.FSnapshotBlockCh.TryReceive(DummySB) then
      else if FSub.FOnroadMsgCh.TryReceive(DummyOM) then
    end;
    FSub.FErr.WaitForCompletion;
  end;
end;

end.
