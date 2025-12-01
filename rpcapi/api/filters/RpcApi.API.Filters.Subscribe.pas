unit RpcApi.Api.Filters.Subscribe;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading,
  System.JSON,
  Vite, Common.Types, Interfaces.Core, Log15, Rpc, RpcApi.Api,
  RpcApi.Api.Filters.EventSystem, GoToDelphi.Helpers.TChannel;

type
  TOneTimeTimer = class
  private
    FEvent: TEvent;
    FInterval: Cardinal;
    FThread: TThread;
    procedure Execute;
  public
    constructor Create(Interval: Cardinal);
    destructor Destroy; override;
    procedure Reset(Interval: Cardinal);
    function Stop: Boolean;
    function Wait: TWaitResult;
  end;

  TFilter = class
  private
    FType: TFilterType;
    FDeadline: TOneTimeTimer;
    FParam: TFilterParam;
    FSubscription: TRpcSubscription;
    FBlocks: TArray<TAccountBlock>;
    FBlocksWithHeight: TArray<TAccountBlockWithHeight>;
    FLogs: TArray<TLogs>;
    FSnapshotBlocks: TArray<TSnapshotBlock>;
    FOnroadMsgs: TArray<TOnroadMsg>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TRpcFilterParam = class
  private
    FAddrRange: TDictionary<string, TRange>;
    FTopics: TArray<TArray<THash>>;
    FPageIndex: UInt64;
    FPageSize: UInt64;
  public
    property AddrRange: TDictionary<string, TRange> read FAddrRange write FAddrRange;
    property Topics: TArray<TArray<THash>> read FTopics write FTopics;
    property PageIndex: UInt64 read FPageIndex write FPageIndex;
    property PageSize: UInt64 read FPageSize write FPageSize;
  end;

  TAccountBlocksMsg = class
  public
    Result: TArray<TAccountBlock>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TAccountBlock>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TAccountBlocksWithHeightMsg = class
  public
    Result: TArray<TAccountBlockWithHeight>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TAccountBlockWithHeight>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TAccountBlocksWithHeightMsgV2 = class
  public
    Result: TArray<TAccountBlockWithHeightV2>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TAccountBlockWithHeightV2>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TLogsMsg = class
  public
    Result: TArray<TLogs>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TLogs>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TLogsMsgV2 = class
  public
    Result: TArray<TLogsV2>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TLogsV2>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TOnroadBlocksMsg = class
  public
    Result: TArray<TOnroadMsg>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TOnroadMsg>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TOnroadBlocksMsgV2 = class
  public
    Result: TArray<TOnroadMsgV2>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TOnroadMsgV2>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TSnapshotBlocksMsg = class
  public
    Result: TArray<TSnapshotBlock>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TSnapshotBlock>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TSnapshotBlocksMsgV2 = class
  public
    Result: TArray<TSnapshotBlockV2>;
    Subscription: TRpcId;
    constructor Create(AResult: TArray<TSnapshotBlockV2>; ASubscription: TRpcId);
    function ToJSON: TJSONObject;
  end;

  TSubscribeApi = class
  private
    FVite: TVite;
    FLog: ILogger;
    FFilterMap: TDictionary<TRpcId, TFilter>;
    FFilterMapMu: TMutex;
    FEventSystem: TEventSystem;
    FTimeoutThread: TThread;
    procedure TimeoutLoop;
    function CreateSnapshotBlockFilter(Ft: TFilterType): TRpcId;
    function CreateAccountBlockFilter: TRpcId;
    function CreateAccountBlockFilterByAddress(Addr: TAddress; Ft: TFilterType): TRpcId;
    function CreateUnreceivedBlockFilterByAddress(Addr: TAddress; Ft: TFilterType): TRpcId;
    function CreateVmLogFilter(RangeMap: TDictionary<string, TRange>; Topics: TArray<TArray<THash>>; Ft: TFilterType): TRpcId;
    function GetChangesByFilterIdImpl(Id: TRpcId): TObject;
    function CreateSnapshotBlockSubscription(Ctx: IContext; Ft: TFilterType): TRpcSubscription;
    function CreateAccountBlockSubscription(Ctx: IContext): TRpcSubscription;
    function CreateAccountBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress; Ft: TFilterType): TRpcSubscription;
    function CreateUnreceivedBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress; Ft: TFilterType): TRpcSubscription;
    function CreateVmLogSubscription(Ctx: IContext; RangeMap: TDictionary<string, TRange>; Topics: TArray<TArray<THash>>; Ft: TFilterType): TRpcSubscription;
  public
    constructor Create(AVite: TVite);
    destructor Destroy; override;
    function NewSnapshotBlocksFilter: TRpcId;
    function CreateSnapshotBlockFilter: TRpcId;
    function NewSnapshotBlockFilter: TRpcId;
    function NewAccountBlocksFilter: TRpcId;
    function CreateAccountBlockFilter: TRpcId;
    function NewAccountBlockFilter: TRpcId;
    function NewAccountBlocksByAddrFilter(Addr: TAddress): TRpcId;
    function CreateAccountBlockFilterByAddress(Addr: TAddress): TRpcId;
    function NewAccountBlockByAddressFilter(Addr: TAddress): TRpcId;
    function NewOnroadBlocksByAddrFilter(Addr: TAddress): TRpcId;
    function CreateUnreceivedBlockFilterByAddress(Addr: TAddress): TRpcId;
    function NewUnreceivedBlockByAddressFilter(Addr: TAddress): TRpcId;
    function NewLogsFilter(Param: TRpcFilterParam): TRpcId;
    function CreateVmLogFilter(Param: TVmLogFilterParam): TRpcId;
    function NewVmLogFilter(Param: TVmLogFilterParam): TRpcId;
    function UninstallFilter(Id: TRpcId): Boolean;
    function GetFilterChanges(Id: TRpcId): TObject;
    function GetChangesByFilterId(Id: TRpcId): TObject;
    function NewSnapshotBlocks(Ctx: IContext): TRpcSubscription;
    function CreateSnapshotBlockSubscription(Ctx: IContext): TRpcSubscription;
    function NewSnapshotBlock(Ctx: IContext): TRpcSubscription;
    function NewAccountBlocks(Ctx: IContext): TRpcSubscription;
    function CreateAccountBlockSubscription(Ctx: IContext): TRpcSubscription;
    function NewAccountBlock(Ctx: IContext): TRpcSubscription;
    function NewAccountBlocksByAddr(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function CreateAccountBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function NewAccountBlockByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function NewOnroadBlocksByAddr(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function CreateUnreceivedBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function NewUnreceivedBlockByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
    function NewLogs(Ctx: IContext; Param: TRpcFilterParam): TRpcSubscription;
    function CreateVmlogSubscription(Ctx: IContext; Param: TVmLogFilterParam): TRpcSubscription;
    function NewVmLog(Ctx: IContext; Param: TVmLogFilterParam): TRpcSubscription;
    function GetLogs(Param: TRpcFilterParam): TArray<TLogs>;
  end;

var
  Deadline: TTimeSpan = 5 * 60 * 1000; // 5 minutes

implementation

{ TOneTimeTimer }

constructor TOneTimeTimer.Create(Interval: Cardinal);
begin
  FEvent := TEvent.Create(nil, True, False, '');
  FInterval := Interval;
  FThread := TThread.CreateAnonymousThread(Execute);
  FThread.Start;
end;

destructor TOneTimeTimer.Destroy;
begin
  FThread.Terminate;
  FThread.WaitFor;
  FEvent.Free;
  FThread.Free;
  inherited;
end;

procedure TOneTimeTimer.Execute;
begin
  while not TThread.CheckTerminated do
  begin
    if FEvent.WaitFor(FInterval) = TWaitResult.wrSignaled then
      Break;
  end;
end;

procedure TOneTimeTimer.Reset(Interval: Cardinal);
begin
  FInterval := Interval;
  FEvent.ResetEvent;
end;

function TOneTimeTimer.Stop: Boolean;
begin
  Result := FEvent.SetEvent = TWaitResult.wrSignaled;
end;

function TOneTimeTimer.Wait: TWaitResult;
begin
  Result := FEvent.WaitFor(0);
end;

{ TFilter }

constructor TFilter.Create;
begin
  FDeadline := TOneTimeTimer.Create(Deadline);
end;

destructor TFilter.Destroy;
begin
  FDeadline.Free;
  inherited;
end;

{ TSubscribeApi }

constructor TSubscribeApi.Create(AVite: TVite);
begin
  if Es = nil then
    raise Exception.Create('Set "SubscribeEnabled" to "true" in node_config.json');
  FVite := AVite;
  FLog := TLog15.New('module', 'rpc_api/subscribe_api');
  FFilterMap := TDictionary<TRpcId, TFilter>.Create;
  FFilterMapMu := TMutex.Create;
  FEventSystem := Es;
  FTimeoutThread := TThread.CreateAnonymousThread(TimeoutLoop);
  FTimeoutThread.Start;
end;

destructor TSubscribeApi.Destroy;
begin
  FTimeoutThread.Terminate;
  FTimeoutThread.WaitFor;
  FFilterMap.Free;
  FFilterMapMu.Free;
  FTimeoutThread.Free;
  inherited;
end;

procedure TSubscribeApi.TimeoutLoop;
var
  Id: TRpcId;
  F: TFilter;
begin
  FLog.Info('start timeout loop');
  while not TThread.CheckTerminated do
  begin
    TThread.Sleep(5 * 60 * 1000);
    FFilterMapMu.Acquire;
    try
      for Id in FFilterMap.Keys do
      begin
        F := FFilterMap[Id];
        if F.FDeadline.Wait = TWaitResult.wrSignaled then
        begin
          F.FSubscription.Unsubscribe;
          FFilterMap.Remove(Id);
        end;
      end;
    finally
      FFilterMapMu.Release;
    end;
  end;
end;

function TSubscribeApi.NewSnapshotBlocksFilter: TRpcId;
begin
  Result := CreateSnapshotBlockFilter(SnapshotBlocksSubscription);
end;

function TSubscribeApi.CreateSnapshotBlockFilter: TRpcId;
begin
  Result := CreateSnapshotBlockFilter(SnapshotBlocksSubscriptionV2);
end;

function TSubscribeApi.NewSnapshotBlockFilter: TRpcId;
begin
  Result := CreateSnapshotBlockFilter(SnapshotBlocksSubscriptionV2);
end;

function TSubscribeApi.CreateSnapshotBlockFilter(Ft: TFilterType): TRpcId;
var
  SbCh: TChannel<TArray<TSnapshotBlock>>;
  SbSub: TRpcSubscription;
  F: TFilter;
  Thread: TThread;
begin
  FLog.Info('createSnapshotBlockFilter');
  SbCh := TChannel<TArray<TSnapshotBlock>>.Create;
  SbSub := FEventSystem.SubscribeSnapshotBlocks(SbCh, Ft);

  FFilterMapMu.Acquire;
  try
    F := TFilter.Create;
    F.FType := SbSub.FSub.FType;
    F.FSubscription := SbSub;
    FFilterMap.Add(SbSub.Id, F);
  finally
    FFilterMapMu.Release;
  end;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      Sb: TArray<TSnapshotBlock>;
    begin
      while True do
      begin
        if SbCh.TryReceive(Sb) then
        begin
          FFilterMapMu.Acquire;
          try
            if FFilterMap.ContainsKey(SbSub.Id) then
              FFilterMap[SbSub.Id].FSnapshotBlocks := Concat(FFilterMap[SbSub.Id].FSnapshotBlocks, Sb);
          finally
            FFilterMapMu.Release;
          end;
        end
        else if SbSub.Err.IsCompleted then
        begin
          FFilterMapMu.Acquire;
          try
            FFilterMap.Remove(SbSub.Id);
          finally
            FFilterMapMu.Release;
          end;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := SbSub.Id;
end;

function TSubscribeApi.NewAccountBlocksFilter: TRpcId;
begin
  Result := CreateAccountBlockFilter;
end;

function TSubscribeApi.CreateAccountBlockFilter: TRpcId;
begin
  Result := CreateAccountBlockFilter;
end;

function TSubscribeApi.NewAccountBlockFilter: TRpcId;
begin
  Result := CreateAccountBlockFilter;
end;

function TSubscribeApi.CreateAccountBlockFilter: TRpcId;
var
  AcCh: TChannel<TArray<TAccountBlock>>;
  AcSub: TRpcSubscription;
  F: TFilter;
  Thread: TThread;
begin
  FLog.Info('createAccountBlockFilter');
  AcCh := TChannel<TArray<TAccountBlock>>.Create;
  AcSub := FEventSystem.SubscribeAccountBlocks(AcCh);

  FFilterMapMu.Acquire;
  try
    F := TFilter.Create;
    F.FType := AcSub.FSub.FType;
    F.FSubscription := AcSub;
    FFilterMap.Add(AcSub.Id, F);
  finally
    FFilterMapMu.Release;
  end;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      Ac: TArray<TAccountBlock>;
    begin
      while True do
      begin
        if AcCh.TryReceive(Ac) then
        begin
          FFilterMapMu.Acquire;
          try
            if FFilterMap.ContainsKey(AcSub.Id) then
              FFilterMap[AcSub.Id].FBlocks := Concat(FFilterMap[AcSub.Id].FBlocks, Ac);
          finally
            FFilterMapMu.Release;
          end;
        end
        else if AcSub.Err.IsCompleted then
        begin
          FFilterMapMu.Acquire;
          try
            FFilterMap.Remove(AcSub.Id);
          finally
            FFilterMapMu.Release;
          end;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := AcSub.Id;
end;

function TSubscribeApi.NewAccountBlocksByAddrFilter(Addr: TAddress): TRpcId;
begin
  Result := CreateAccountBlockFilterByAddress(Addr, AccountBlocksWithHeightSubscription);
end;

function TSubscribeApi.CreateAccountBlockFilterByAddress(Addr: TAddress): TRpcId;
begin
  Result := CreateAccountBlockFilterByAddress(Addr, AccountBlocksWithHeightSubscriptionV2);
end;

function TSubscribeApi.NewAccountBlockByAddressFilter(Addr: TAddress): TRpcId;
begin
  Result := CreateAccountBlockFilterByAddress(Addr, AccountBlocksWithHeightSubscriptionV2);
end;

function TSubscribeApi.CreateAccountBlockFilterByAddress(Addr: TAddress; Ft: TFilterType): TRpcId;
var
  AcCh: TChannel<TArray<TAccountBlockWithHeight>>;
  AcSub: TRpcSubscription;
  F: TFilter;
  Thread: TThread;
begin
  FLog.Info('createAccountBlockFilterByAddress');
  AcCh := TChannel<TArray<TAccountBlockWithHeight>>.Create;
  AcSub := FEventSystem.SubscribeAccountBlocksByAddr(Addr, AcCh, Ft);

  FFilterMapMu.Acquire;
  try
    F := TFilter.Create;
    F.FType := AcSub.FSub.FType;
    F.FSubscription := AcSub;
    FFilterMap.Add(AcSub.Id, F);
  finally
    FFilterMapMu.Release;
  end;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      Ac: TArray<TAccountBlockWithHeight>;
    begin
      while True do
      begin
        if AcCh.TryReceive(Ac) then
        begin
          FFilterMapMu.Acquire;
          try
            if FFilterMap.ContainsKey(AcSub.Id) then
              FFilterMap[AcSub.Id].FBlocksWithHeight := Concat(FFilterMap[AcSub.Id].FBlocksWithHeight, Ac);
          finally
            FFilterMapMu.Release;
          end;
        end
        else if AcSub.Err.IsCompleted then
        begin
          FFilterMapMu.Acquire;
          try
            FFilterMap.Remove(AcSub.Id);
          finally
            FFilterMapMu.Release;
          end;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := AcSub.Id;
end;

function TSubscribeApi.NewOnroadBlocksByAddrFilter(Addr: TAddress): TRpcId;
begin
  Result := CreateUnreceivedBlockFilterByAddress(Addr, OnroadBlocksSubscription);
end;

function TSubscribeApi.CreateUnreceivedBlockFilterByAddress(Addr: TAddress): TRpcId;
begin
  Result := CreateUnreceivedBlockFilterByAddress(Addr, OnroadBlocksSubscriptionV2);
end;

function TSubscribeApi.NewUnreceivedBlockByAddressFilter(Addr: TAddress): TRpcId;
begin
  Result := CreateUnreceivedBlockFilterByAddress(Addr, OnroadBlocksSubscriptionV2);
end;

function TSubscribeApi.CreateUnreceivedBlockFilterByAddress(Addr: TAddress; Ft: TFilterType): TRpcId;
var
  AcCh: TChannel<TArray<TOnroadMsg>>;
  AcSub: TRpcSubscription;
  F: TFilter;
  Thread: TThread;
begin
  FLog.Info('createUnreceivedBlockFilterByAddress');
  AcCh := TChannel<TArray<TOnroadMsg>>.Create;
  AcSub := FEventSystem.SubscribeOnroadBlocksByAddr(Addr, AcCh, Ft);

  FFilterMapMu.Acquire;
  try
    F := TFilter.Create;
    F.FType := AcSub.FSub.FType;
    F.FSubscription := AcSub;
    FFilterMap.Add(AcSub.Id, F);
  finally
    FFilterMapMu.Release;
  end;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      Ac: TArray<TOnroadMsg>;
    begin
      while True do
      begin
        if AcCh.TryReceive(Ac) then
        begin
          FFilterMapMu.Acquire;
          try
            if FFilterMap.ContainsKey(AcSub.Id) then
              FFilterMap[AcSub.Id].FOnroadMsgs := Concat(FFilterMap[AcSub.Id].FOnroadMsgs, Ac);
          finally
            FFilterMapMu.Release;
          end;
        end
        else if AcSub.Err.IsCompleted then
        begin
          FFilterMapMu.Acquire;
          try
            FFilterMap.Remove(AcSub.Id);
          finally
            FFilterMapMu.Release;
          end;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := AcSub.Id;
end;

function TSubscribeApi.NewLogsFilter(Param: TRpcFilterParam): TRpcId;
begin
  Result := CreateVmLogFilter(Param.AddrRange, Param.Topics, LogsSubscription);
end;

function TSubscribeApi.CreateVmLogFilter(Param: TVmLogFilterParam): TRpcId;
begin
  Result := CreateVmLogFilter(Param.AddrRange, Param.Topics, LogsSubscriptionV2);
end;

function TSubscribeApi.NewVmLogFilter(Param: TVmLogFilterParam): TRpcId;
begin
  Result := CreateVmLogFilter(Param.AddrRange, Param.Topics, LogsSubscriptionV2);
end;

function TSubscribeApi.CreateVmLogFilter(RangeMap: TDictionary<string, TRange>; Topics: TArray<TArray<THash>>; Ft: TFilterType): TRpcId;
var
  P: TFilterParam;
  LogsCh: TChannel<TArray<TLogs>>;
  LogsSub: TRpcSubscription;
  F: TFilter;
  Thread: TThread;
begin
  FLog.Info('createVmLogFilter');
  P := ToFilterParam(RangeMap, Topics);
  LogsCh := TChannel<TArray<TLogs>>.Create;
  LogsSub := FEventSystem.SubscribeLogs(P, LogsCh, Ft);

  FFilterMapMu.Acquire;
  try
    F := TFilter.Create;
    F.FType := LogsSub.FSub.FType;
    F.FSubscription := LogsSub;
    FFilterMap.Add(LogsSub.Id, F);
  finally
    FFilterMapMu.Release;
  end;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      L: TArray<TLogs>;
    begin
      while True do
      begin
        if LogsCh.TryReceive(L) then
        begin
          FFilterMapMu.Acquire;
          try
            if FFilterMap.ContainsKey(LogsSub.Id) then
              FFilterMap[LogsSub.Id].FLogs := Concat(FFilterMap[LogsSub.Id].FLogs, L);
          finally
            FFilterMapMu.Release;
          end;
        end
        else if LogsSub.Err.IsCompleted then
        begin
          FFilterMapMu.Acquire;
          try
            FFilterMap.Remove(LogsSub.Id);
          finally
            FFilterMapMu.Release;
          end;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := LogsSub.Id;
end;

function TSubscribeApi.UninstallFilter(Id: TRpcId): Boolean;
var
  F: TFilter;
begin
  FLog.Info('UninstallFilter');
  FFilterMapMu.Acquire;
  try
    Result := FFilterMap.TryGetValue(Id, F);
    if Result then
      FFilterMap.Remove(Id);
  finally
    FFilterMapMu.Release;
  end;
  if Result then
    F.FSubscription.Unsubscribe;
end;

function TSubscribeApi.GetFilterChanges(Id: TRpcId): TObject;
begin
  Result := GetChangesByFilterIdImpl(Id);
end;

function TSubscribeApi.GetChangesByFilterId(Id: TRpcId): TObject;
begin
  Result := GetChangesByFilterIdImpl(Id);
end;

function TSubscribeApi.GetChangesByFilterIdImpl(Id: TRpcId): TObject;
var
  F: TFilter;
  Blocks: TArray<TAccountBlock>;
  BlocksWithHeight: TArray<TAccountBlockWithHeight>;
  ResultV2: TArray<TAccountBlockWithHeightV2>;
  I: Integer;
  B: TAccountBlockWithHeight;
  OnroadMsgs: TArray<TOnroadMsg>;
  ResultOMV2: TArray<TOnroadMsgV2>;
  O: TOnroadMsg;
  Logs: TArray<TLogs>;
  ResultLV2: TArray<TLogsV2>;
  L: TLogs;
  SnapshotBlocks: TArray<TSnapshotBlock>;
  ResultSBV2: TArray<TSnapshotBlockV2>;
  SB: TSnapshotBlock;
begin
  FLog.Info('getChangesByFilterId', ['id', Id]);
  FFilterMapMu.Acquire;
  try
    if FFilterMap.TryGetValue(Id, F) then
    begin
      if not F.FDeadline.Stop then
        F.FDeadline.Wait;
      F.FDeadline.Reset(Deadline);

      case F.FType of
        AccountBlocksSubscription:
        begin
          Blocks := F.FBlocks;
          F.FBlocks := nil;
          Result := TAccountBlocksMsg.Create(Blocks, Id);
        end;
        AccountBlocksWithHeightSubscription:
        begin
          BlocksWithHeight := F.FBlocksWithHeight;
          F.FBlocksWithHeight := nil;
          Result := TAccountBlocksWithHeightMsg.Create(BlocksWithHeight, Id);
        end;
        AccountBlocksWithHeightSubscriptionV2:
        begin
          BlocksWithHeight := F.FBlocksWithHeight;
          F.FBlocksWithHeight := nil;
          SetLength(ResultV2, Length(BlocksWithHeight));
          for I := 0 to High(BlocksWithHeight) do
          begin
            B := BlocksWithHeight[I];
            ResultV2[I] := TAccountBlockWithHeightV2.Create(B.Hash, B.HeightStr, B.Removed);
          end;
          Result := TAccountBlocksWithHeightMsgV2.Create(ResultV2, Id);
        end;
        OnroadBlocksSubscription:
        begin
          OnroadMsgs := F.FOnroadMsgs;
          F.FOnroadMsgs := nil;
          Result := TOnroadBlocksMsg.Create(OnroadMsgs, Id);
        end;
        OnroadBlocksSubscriptionV2:
        begin
          OnroadMsgs := F.FOnroadMsgs;
          F.FOnroadMsgs := nil;
          SetLength(ResultOMV2, Length(OnroadMsgs));
          for I := 0 to High(OnroadMsgs) do
          begin
            O := OnroadMsgs[I];
            ResultOMV2[I] := TOnroadMsgV2.Create(O.Hash, O.Closed, O.Removed);
          end;
          Result := TOnroadBlocksMsgV2.Create(ResultOMV2, Id);
        end;
        LogsSubscription:
        begin
          Logs := F.FLogs;
          F.FLogs := nil;
          Result := TLogsMsg.Create(Logs, Id);
        end;
        LogsSubscriptionV2:
        begin
          Logs := F.FLogs;
          F.FLogs := nil;
          SetLength(ResultLV2, Length(Logs));
          for I := 0 to High(Logs) do
          begin
            L := Logs[I];
            ResultLV2[I] := TLogsV2.Create(L.Log, L.AccountBlockHash, L.AccountHeight, L.Addr, L.Removed);
          end;
          Result := TLogsMsgV2.Create(ResultLV2, Id);
        end;
        SnapshotBlocksSubscription:
        begin
          SnapshotBlocks := F.FSnapshotBlocks;
          F.FSnapshotBlocks := nil;
          Result := TSnapshotBlocksMsg.Create(SnapshotBlocks, Id);
        end;
        SnapshotBlocksSubscriptionV2:
        begin
          SnapshotBlocks := F.FSnapshotBlocks;
          F.FSnapshotBlocks := nil;
          SetLength(ResultSBV2, Length(SnapshotBlocks));
          for I := 0 to High(SnapshotBlocks) do
          begin
            SB := SnapshotBlocks[I];
            ResultSBV2[I] := TSnapshotBlockV2.Create(SB.Hash, SB.HeightStr, SB.Removed);
          end;
          Result := TSnapshotBlocksMsgV2.Create(ResultSBV2, Id);
        end;
      else
        Result := nil;
      end;
    end
    else
      raise Exception.Create('filter not found');
  finally
    FFilterMapMu.Release;
  end;
end;

function TSubscribeApi.NewSnapshotBlocks(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateSnapshotBlockSubscription(Ctx, SnapshotBlocksSubscription);
end;

function TSubscribeApi.CreateSnapshotBlockSubscription(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateSnapshotBlockSubscription(Ctx, SnapshotBlocksSubscriptionV2);
end;

function TSubscribeApi.NewSnapshotBlock(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateSnapshotBlockSubscription(Ctx, SnapshotBlocksSubscriptionV2);
end;

function TSubscribeApi.CreateSnapshotBlockSubscription(Ctx: IContext; Ft: TFilterType): TRpcSubscription;
var
  Notifier: TRpcNotifier;
  RpcSub: TRpcSubscription;
  SnapshotBlockHashChan: TChannel<TArray<TSnapshotBlock>>;
  SbSub: TRpcSubscription;
  Thread: TThread;
begin
  FLog.Info('createSnapshotBlockSubscription');
  Notifier := NotifierFromContext(Ctx);
  if Notifier = nil then
    raise Exception.Create(ErrNotificationsUnsupported);
  RpcSub := Notifier.CreateSubscription;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      H: TArray<TSnapshotBlock>;
      ResultV2: TArray<TSnapshotBlockV2>;
      I: Integer;
      B: TSnapshotBlock;
    begin
      SnapshotBlockHashChan := TChannel<TArray<TSnapshotBlock>>.Create(128);
      SbSub := FEventSystem.SubscribeSnapshotBlocks(SnapshotBlockHashChan, Ft);
      while True do
      begin
        if SnapshotBlockHashChan.TryReceive(H) then
        begin
          if Ft = SnapshotBlocksSubscriptionV2 then
          begin
            SetLength(ResultV2, Length(H));
            for I := 0 to High(H) do
            begin
              B := H[I];
              ResultV2[I] := TSnapshotBlockV2.Create(B.Hash, B.HeightStr, B.Removed);
            end;
            Notifier.Notify(RpcSub.Id, ResultV2);
          end
          else
            Notifier.Notify(RpcSub.Id, H);
        end
        else if RpcSub.Err.IsCompleted then
        begin
          SbSub.Unsubscribe;
          Exit;
        end
        else if Notifier.Closed then
        begin
          SbSub.Unsubscribe;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := RpcSub;
end;

function TSubscribeApi.NewAccountBlocks(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscription(Ctx);
end;

function TSubscribeApi.CreateAccountBlockSubscription(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscription(Ctx);
end;

function TSubscribeApi.NewAccountBlock(Ctx: IContext): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscription(Ctx);
end;

function TSubscribeApi.CreateAccountBlockSubscription(Ctx: IContext): TRpcSubscription;
var
  Notifier: TRpcNotifier;
  RpcSub: TRpcSubscription;
  AccountBlockHashCh: TChannel<TArray<TAccountBlock>>;
  AcSub: TRpcSubscription;
  Thread: TThread;
begin
  FLog.Info('createAccountBlockSubscription');
  Notifier := NotifierFromContext(Ctx);
  if Notifier = nil then
    raise Exception.Create(ErrNotificationsUnsupported);
  RpcSub := Notifier.CreateSubscription;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      H: TArray<TAccountBlock>;
    begin
      AccountBlockHashCh := TChannel<TArray<TAccountBlock>>.Create(128);
      AcSub := FEventSystem.SubscribeAccountBlocks(AccountBlockHashCh);
      while True do
      begin
        if AccountBlockHashCh.TryReceive(H) then
          Notifier.Notify(RpcSub.Id, H)
        else if RpcSub.Err.IsCompleted then
        begin
          AcSub.Unsubscribe;
          Exit;
        end
        else if Notifier.Closed then
        begin
          AcSub.Unsubscribe;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := RpcSub;
end;

function TSubscribeApi.NewAccountBlocksByAddr(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscriptionByAddress(Ctx, Addr, AccountBlocksWithHeightSubscription);
end;

function TSubscribeApi.CreateAccountBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscriptionByAddress(Ctx, Addr, AccountBlocksWithHeightSubscriptionV2);
end;

function TSubscribeApi.NewAccountBlockByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateAccountBlockSubscriptionByAddress(Ctx, Addr, AccountBlocksWithHeightSubscriptionV2);
end;

function TSubscribeApi.CreateAccountBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress; Ft: TFilterType): TRpcSubscription;
var
  Notifier: TRpcNotifier;
  RpcSub: TRpcSubscription;
  AccountBlockCh: TChannel<TArray<TAccountBlockWithHeight>>;
  AcSub: TRpcSubscription;
  Thread: TThread;
begin
  FLog.Info('createAccountBlockSubscriptionByAddress');
  Notifier := NotifierFromContext(Ctx);
  if Notifier = nil then
    raise Exception.Create(ErrNotificationsUnsupported);
  RpcSub := Notifier.CreateSubscription;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      H: TArray<TAccountBlockWithHeight>;
      ResultV2: TArray<TAccountBlockWithHeightV2>;
      I: Integer;
      B: TAccountBlockWithHeight;
    begin
      AccountBlockCh := TChannel<TArray<TAccountBlockWithHeight>>.Create(128);
      AcSub := FEventSystem.SubscribeAccountBlocksByAddr(Addr, AccountBlockCh, Ft);
      while True do
      begin
        if AccountBlockCh.TryReceive(H) then
        begin
          if Ft = AccountBlocksWithHeightSubscriptionV2 then
          begin
            SetLength(ResultV2, Length(H));
            for I := 0 to High(H) do
            begin
              B := H[I];
              ResultV2[I] := TAccountBlockWithHeightV2.Create(B.Hash, B.HeightStr, B.Removed);
            end;
            Notifier.Notify(RpcSub.Id, ResultV2);
          end
          else
            Notifier.Notify(RpcSub.Id, H);
        end
        else if RpcSub.Err.IsCompleted then
        begin
          AcSub.Unsubscribe;
          Exit;
        end
        else if Notifier.Closed then
        begin
          AcSub.Unsubscribe;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := RpcSub;
end;

function TSubscribeApi.NewOnroadBlocksByAddr(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateUnreceivedBlockSubscriptionByAddress(Ctx, Addr, OnroadBlocksSubscription);
end;

function TSubscribeApi.CreateUnreceivedBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateUnreceivedBlockSubscriptionByAddress(Ctx, Addr, OnroadBlocksSubscriptionV2);
end;

function TSubscribeApi.NewUnreceivedBlockByAddress(Ctx: IContext; Addr: TAddress): TRpcSubscription;
begin
  Result := CreateUnreceivedBlockSubscriptionByAddress(Ctx, Addr, OnroadBlocksSubscriptionV2);
end;

function TSubscribeApi.CreateUnreceivedBlockSubscriptionByAddress(Ctx: IContext; Addr: TAddress; Ft: TFilterType): TRpcSubscription;
var
  Notifier: TRpcNotifier;
  RpcSub: TRpcSubscription;
  AccountBlockHashCh: TChannel<TArray<TOnroadMsg>>;
  AcSub: TRpcSubscription;
  Thread: TThread;
begin
  FLog.Info('createUnreceivedBlockSubscriptionByAddress');
  Notifier := NotifierFromContext(Ctx);
  if Notifier = nil then
    raise Exception.Create(ErrNotificationsUnsupported);
  RpcSub := Notifier.CreateSubscription;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      H: TArray<TOnroadMsg>;
      ResultV2: TArray<TOnroadMsgV2>;
      I: Integer;
      O: TOnroadMsg;
    begin
      AccountBlockHashCh := TChannel<TArray<TOnroadMsg>>.Create(128);
      AcSub := FEventSystem.SubscribeOnroadBlocksByAddr(Addr, AccountBlockHashCh, Ft);
      while True do
      begin
        if AccountBlockHashCh.TryReceive(H) then
        begin
          if Ft = OnroadBlocksSubscriptionV2 then
          begin
            SetLength(ResultV2, Length(H));
            for I := 0 to High(H) do
            begin
              O := H[I];
              ResultV2[I] := TOnroadMsgV2.Create(O.Hash, O.Closed, O.Removed);
            end;
            Notifier.Notify(RpcSub.Id, ResultV2);
          end
          else
            Notifier.Notify(RpcSub.Id, H);
        end
        else if RpcSub.Err.IsCompleted then
        begin
          AcSub.Unsubscribe;
          Exit;
        end
        else if Notifier.Closed then
        begin
          AcSub.Unsubscribe;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := RpcSub;
end;

function TSubscribeApi.NewLogs(Ctx: IContext; Param: TRpcFilterParam): TRpcSubscription;
begin
  Result := CreateVmLogSubscription(Ctx, Param.AddrRange, Param.Topics, LogsSubscription);
end;

function TSubscribeApi.CreateVmlogSubscription(Ctx: IContext; Param: TVmLogFilterParam): TRpcSubscription;
begin
  Result := CreateVmLogSubscription(Ctx, Param.AddrRange, Param.Topics, LogsSubscriptionV2);
end;

function TSubscribeApi.NewVmLog(Ctx: IContext; Param: TVmLogFilterParam): TRpcSubscription;
begin
  Result := CreateVmLogSubscription(Ctx, Param.AddrRange, Param.Topics, LogsSubscriptionV2);
end;

function TSubscribeApi.CreateVmLogSubscription(Ctx: IContext; RangeMap: TDictionary<string, TRange>; Topics: TArray<TArray<THash>>; Ft: TFilterType): TRpcSubscription;
var
  P: TFilterParam;
  Notifier: TRpcNotifier;
  RpcSub: TRpcSubscription;
  LogsMsg: TChannel<TArray<TLogs>>;
  Sub: TRpcSubscription;
  Thread: TThread;
begin
  FLog.Info('createVmLogSubscription');
  P := ToFilterParam(RangeMap, Topics);
  Notifier := NotifierFromContext(Ctx);
  if Notifier = nil then
    raise Exception.Create(ErrNotificationsUnsupported);
  RpcSub := Notifier.CreateSubscription;

  Thread := TThread.CreateAnonymousThread(
    procedure
    var
      Msg: TArray<TLogs>;
      ResultV2: TArray<TLogsV2>;
      I: Integer;
      L: TLogs;
    begin
      LogsMsg := TChannel<TArray<TLogs>>.Create(128);
      Sub := FEventSystem.SubscribeLogs(P, LogsMsg, Ft);
      while True do
      begin
        if LogsMsg.TryReceive(Msg) then
        begin
          if Ft = LogsSubscriptionV2 then
          begin
            SetLength(ResultV2, Length(Msg));
            for I := 0 to High(Msg) do
            begin
              L := Msg[I];
              ResultV2[I] := TLogsV2.Create(L.Log, L.AccountBlockHash, L.AccountHeight, L.Addr, L.Removed);
            end;
            Notifier.Notify(RpcSub.Id, ResultV2);
          end
          else
            Notifier.Notify(RpcSub.Id, Msg);
        end
        else if RpcSub.Err.IsCompleted then
        begin
          Sub.Unsubscribe;
          Exit;
        end
        else if Notifier.Closed then
        begin
          Sub.Unsubscribe;
          Exit;
        end;
      end;
    end
  );
  Thread.Start;
  Result := RpcSub;
end;

function TSubscribeApi.GetLogs(Param: TRpcFilterParam): TArray<TLogs>;
var
  Logs: TArray<TLogResult>;
  ResultList: TArray<TLogs>;
  I: Integer;
  L: TLogResult;
begin
  Logs := GetLogs(FVite.Chain, Param.AddrRange, Param.Topics, Param.PageIndex, Param.PageSize);
  SetLength(ResultList, Length(Logs));
  for I := 0 to High(Logs) do
  begin
    L := Logs[I];
    ResultList[I] := TLogs.Create(L.Log, L.AccountBlockHash, L.AccountHeight, L.Addr, False);
  end;
  Result := ResultList;
end;

end.