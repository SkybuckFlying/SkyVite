unit net.fetcher;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  common.types, interfaces.core, net.interface, Log15;

var
  ErrNoSuitablePeer: Exception;
  ErrFetchTimeout: Exception;
  ErrNoResource: Exception;

type
  TGid = class
  private
    FIndex: Cardinal;
  public
    function MsgID: TMsgId;
  end;

  IMsgIder = interface
    ['{YOUR_GUID_HERE}']
    function MsgID: TMsgId;
  end;

  TPeerFetchResult = class
  public
    Status: TReqState;
    T: Int64;
  end;

  TRecord = class
  public
    Id: TMsgId;
    Hash: THash;
    AddAt: Int64;
    T: Int64;
    Mark: Integer;
    St: TReqState;
    Targets: TDictionary<TPeerId, TPeerFetchResult>;
    Callback: TProc<TMsg, Exception>;
    procedure Inc;
    procedure Refresh;
    procedure Reset;
    procedure Done(Peer: IPeer; Msg: TMsg; Err: Exception);
  end;

  IFetcher = interface(IHandler)
    ['{YOUR_GUID_HERE}']
    procedure Start;
    procedure Stop;
    procedure SubSyncState(St: ISyncState);
    procedure SetSBP(Value: Boolean);
    procedure FetchSnapshotBlocks(Hash: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
    procedure FetchSnapshotBlock(Hash: THash; Peer: IPeer; Callback: TProc<TMsg, Exception>);
  end;

  TFetcher = class(TInterfacedObject, IFetcher)
  private
    FIdGen: IMsgIder;
    FRecordsById: TDictionary<TMsgId, TRecord>;
    FRecordsByHash: TDictionary<THash, TRecord>;
    FMu: TCriticalSection;
    FPool: TObjectPool<TRecord>;
    FPeerFetchResultPool: TObjectPool<TPeerFetchResult>;
    FPeers: IPeerSet;
    FSt: ISyncState;
    FReceiver: IBlockReceiver;
    FLog: ILogger;
    FBlackBlocks: TDictionary<THash, Boolean>;
    FSbp: Boolean;
    FTerm: TEvent;
    procedure Clean(T: Int64);
    function Hold(Hash: THash; out R: TRecord): Boolean;
    function Add(Hash: THash): TRecord;
    procedure Pending(Id: TMsgId; Peer: IPeer);
    procedure Done(Id: TMsgId; Peer: IPeer; Msg: TMsg; Err: Exception);
    function PickTargets(R: TRecord; Height: UInt64; Peers: IPeerSet): TArray<IPeer>;
    procedure CleanLoop;
  public
    constructor Create(Peers: IPeerSet; Receiver: IBlockReceiver; BlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure SubSyncState(St: ISyncState);
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
    procedure SetSBP(Value: Boolean);
    procedure FetchSnapshotBlocks(Hash: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
    procedure FetchSnapshotBlock(Hash: THash; Peer: IPeer; Callback: TProc<TMsg, Exception>);
  end;

function NewFetcher(Peers: IPeerSet; Receiver: IBlockReceiver; BlackBlocks: TDictionary<THash, Boolean>): IFetcher;

implementation

uses
  System.Threading, System.DateUtils;

{ TGid }

function TGid.MsgID: TMsgId;
begin
  Result := TInterlocked.Increment(FIndex);
end;

{ TRecord }

procedure TRecord.Inc;
begin
  Inc(Mark);
end;

procedure TRecord.Refresh;
begin
  St := reqPending;
  Mark := 0;
  AddAt := Now.ToUnix;
end;

procedure TRecord.Reset;
begin
  Mark := 0;
  Targets.Clear;
  Callback := nil;
end;

procedure TRecord.Done(Peer: IPeer; Msg: TMsg; Err: Exception);
var
  Now: Int64;
  Result: TPeerFetchResult;
  Rest: Integer;
  Ret: TPeerFetchResult;
begin
  Now := Now.ToUnix;
  if Peer <> nil then
  begin
    if Targets.TryGetValue(Peer.Id, Result) then
    begin
      if Err <> nil then
      begin
        Result.Status := reqError;
        Result.T := Now;
      end
      else
      begin
        Result.Status := reqDone;
        Result.T := Now;
      end;
    end;
  end;

  if St <> reqPending then
    Exit;

  if Err = nil then
  begin
    St := reqDone;
    T := Now;
    if Assigned(Callback) then
    begin
      TTask.Run(procedure
      begin
        Callback(Msg, nil);
      end);
    end;
  end
  else
  begin
    Rest := 0;
    for Ret in Targets.Values do
      if Ret.Status <> reqError then
        Inc(Rest);

    if Rest = 0 then
    begin
      St := reqError;
      T := Now;
      if Assigned(Callback) then
      begin
        TTask.Run(procedure
        begin
          Callback(Msg, Err);
        end);
      end;
    end;
  end;
end;

{ TFetcher }

constructor TFetcher.Create(Peers: IPeerSet; Receiver: IBlockReceiver; BlackBlocks: TDictionary<THash, Boolean>);
begin
  FIdGen := TGid.Create;
  FRecordsById := TDictionary<TMsgId, TRecord>.Create;
  FRecordsByHash := TDictionary<THash, TRecord>.Create;
  FMu := TCriticalSection.Create;
  FPool := TObjectPool<TRecord>.Create;
  FPeerFetchResultPool := TObjectPool<TPeerFetchResult>.Create;
  FPeers := Peers;
  FReceiver := Receiver;
  if BlackBlocks = nil then
    FBlackBlocks := TDictionary<THash, Boolean>.Create
  else
    FBlackBlocks := BlackBlocks;
  FLog := Log15.New(['module', 'fetcher']);
end;

destructor TFetcher.Destroy;
begin
  FMu.Free;
  FPool.Free;
  FPeerFetchResultPool.Free;
  FBlackBlocks.Free;
  inherited;
end;

procedure TFetcher.Start;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  TTask.Run(procedure begin CleanLoop; end);
end;

procedure TFetcher.Stop;
begin
  if FTerm = nil then
    Exit;
  FTerm.SetEvent;
end;

procedure TFetcher.CleanLoop;
begin
  while not FTerm.WaitFor(4000) do
    Clean(Now.ToUnix);
end;

procedure TFetcher.Clean(T: Int64);
var
  R: TRecord;
  Ret: TPeerFetchResult;
  ToRemove: TList<TMsgId>;
begin
  ToRemove := TList<TMsgId>.Create;
  try
    FMu.Acquire;
    try
      for R in FRecordsById.Values do
      begin
        if (T - R.AddAt) > 30 then
        begin
          ToRemove.Add(R.Id);
          R.Done(nil, Default(TMsg), ErrFetchTimeout);
          for Ret in R.Targets.Values do
            FPeerFetchResultPool.Return(Ret);
          R.Reset;
          FPool.Return(R);
        end;
      end;

      for var Id in ToRemove do
      begin
        if FRecordsById.TryGetValue(Id, R) then
        begin
          FRecordsByHash.Remove(R.Hash);
          FRecordsById.Remove(Id);
        end;
      end;
    finally
      FMu.Release;
    end;
  finally
    ToRemove.Free;
  end;
end;

function TFetcher.Hold(Hash: THash; out R: TRecord): Boolean;
var
  Now: Int64;
begin
  FMu.Acquire;
  try
    Now := Now.ToUnix;
    if FRecordsByHash.TryGetValue(Hash, R) then
    begin
      if R.St = reqError then
      begin
        R.Refresh;
        Result := False;
      end
      else if R.St = reqDone then
      begin
        if (R.Mark >= 3) and ((Now - R.T) >= 4) then
        begin
          R.Refresh;
          Result := False;
        end
        else
        begin
          R.Inc;
          Result := True;
        end;
      end
      else // reqPending
      begin
        if (R.Mark >= 6) and ((Now - R.AddAt) >= 8) then
        begin
          R.Refresh;
          Result := False;
        end
        else
        begin
          R.Inc;
          Result := True;
        end;
      end;
    end
    else
    begin
      R := FPool.Acquire;
      R.St := reqPending;
      R.AddAt := Now;
      R.Id := FIdGen.MsgID;
      R.Hash := Hash;
      R.Targets.Clear;
      FRecordsByHash.Add(Hash, R);
      FRecordsById.Add(R.Id, R);
      Result := False;
    end;
  finally
    FMu.Release;
  end;
end;

function TFetcher.Add(Hash: THash): TRecord;
begin
  Result := FPool.Acquire;
  Result.St := reqPending;
  Result.AddAt := Now.ToUnix;
  Result.Targets.Clear;
  Result.Id := FIdGen.MsgID;
  FMu.Acquire;
  try
    FRecordsById.Add(Result.Id, Result);
  finally
    FMu.Release;
  end;
end;

procedure TFetcher.Pending(Id: TMsgId; Peer: IPeer);
var
  R: TRecord;
  Result: TPeerFetchResult;
begin
  FMu.Acquire;
  try
    if FRecordsById.TryGetValue(Id, R) and (Peer <> nil) then
    begin
      Result := R.Targets[Peer.Id];
      Result.Status := reqPending;
      Result.T := Now.ToUnix;
    end;
  finally
    FMu.Release;
  end;
end;

procedure TFetcher.Done(Id: TMsgId; Peer: IPeer; Msg: TMsg; Err: Exception);
var
  R: TRecord;
begin
  FMu.Acquire;
  try
    if FRecordsById.TryGetValue(Id, R) then
    begin
      R.Done(Peer, Msg, Err);
      if Err <> nil then
        FLog.Warn(Format('failed to fetch %s to %s: %v', [R.Hash.ToString, Peer.ToString, Err.Message]));
    end;
  finally
    FMu.Release;
  end;
end;

function TFetcher.PickTargets(R: TRecord; Height: UInt64; Peers: IPeerSet): TArray<IPeer>;
var
  Ps: TArray<IPeer>;
  Now: Int64;
  Hole: Boolean;
  I, J: Integer;
  P: IPeer;
  FetchResult: TPeerFetchResult;
begin
  if Height > 10 then
    Dec(Height, 10);
  Ps := Peers.PickReliable(Height);
  if Length(Ps) = 0 then
    Exit(nil);

  Now := Now.ToUnix;
  FMu.Acquire;
  try
    Hole := False;
    for I := 0 to Length(Ps) - 1 do
    begin
      P := Ps[I];
      if R.Targets.TryGetValue(P.Id, FetchResult) then
      begin
        if FetchResult.Status = reqDone then
          Continue;
        if (FetchResult.Status = reqWaiting) or (FetchResult.Status = reqPending) or ((FetchResult.Status = reqError) and (Now - FetchResult.T < 10)) then
        begin
          Hole := True;
          Ps[I] := nil;
        end;
      end;
    end;

    if Hole then
    begin
      J := 0;
      for P in Ps do
      begin
        if P <> nil then
        begin
          if J < I then
            Ps[J] := P;
          Inc(J);
        end;
      end;
      SetLength(Ps, J);
    end;

    if Length(Ps) > 3 then
      SetLength(Ps, 3);

    for P in Ps do
    begin
      FetchResult := FPeerFetchResultPool.Acquire;
      FetchResult.Status := reqWaiting;
      FetchResult.T := Now;
      R.Targets.Add(P.Id, FetchResult);
    end;
    Result := Ps;
  finally
    FMu.Release;
  end;
end;

procedure TFetcher.SubSyncState(St: ISyncState);
begin
  FSt := St;
end;

function TFetcher.Name: string;
begin
  Result := 'fetcher';
end;

function TFetcher.Codes: TArray<TCode>;
begin
  Result := [CodeSnapshotBlocks, CodeAccountBlocks, CodeException];
end;

function TFetcher.Handle(Msg: TMsg): Exception;
var
  Bs: TSnapshotBlocks;
  Block: ISnapshotBlock;
  Abs: TAccountBlocks;
  AccBlock: IAccountBlock;
begin
  Result := nil;
  case Msg.Code of
    CodeSnapshotBlocks:
      begin
        Bs := TSnapshotBlocks.Create;
        try
          Bs.Deserialize(Msg.Payload);
          for Block in Bs.Blocks do
          begin
            Result := FReceiver.ReceiveSnapshotBlock(Block, RemoteFetch);
            if Result <> nil then
              Exit;
          end;
          if Length(Bs.Blocks) > 0 then
          begin
            Done(Msg.Id, Msg.Sender, Msg, nil);
            FLog.Info(Format('receive snapshotblocks %s/%d from %s', [Bs.Blocks[High(Bs.Blocks)].Hash.ToString, Length(Bs.Blocks), Msg.Sender.ToString]));
          end;
        finally
          Bs.Free;
        end;
      end;
    CodeAccountBlocks:
      begin
        Abs := TAccountBlocks.Create;
        try
          Abs.Deserialize(Msg.Payload);
          for AccBlock in Abs.Blocks do
          begin
            Result := FReceiver.ReceiveAccountBlock(AccBlock, RemoteFetch);
            if Result <> nil then
              Exit;
          end;
          if Length(Abs.Blocks) > 0 then
          begin
            Done(Msg.Id, Msg.Sender, Msg, nil);
            FLog.Info(Format('receive accountblocks %s/%d from %s', [Abs.Blocks[High(Abs.Blocks)].Hash.ToString, Length(Abs.Blocks), Msg.Sender.ToString]));
          end;
        finally
          Abs.Free;
        end;
      end;
    CodeException:
      Done(Msg.Id, Msg.Sender, Msg, ErrNoResource);
  end;
end;

procedure TFetcher.SetSBP(Value: Boolean);
begin
  FSbp := Value;
end;

procedure TFetcher.FetchSnapshotBlocks(Hash: THash; Count: UInt64);
var
  R: TRecord;
  Hold: Boolean;
  Ps: TArray<IPeer>;
  P: IPeer;
  M: TGetSnapshotBlocks;
  Err: Exception;
begin
  if FBlackBlocks.ContainsKey(Hash) then
    Exit;
  if not FSt.SyncExited then
  begin
    FLog.Info(Format('in syncing flow, cannot fetch %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  Hold := Self.Hold(Hash, R);
  if Hold then
  begin
    FLog.Info(Format('fetch suppressed GetSnapshotBlocks %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  Ps := PickTargets(R, 0, FPeers);
  if Length(Ps) = 0 then
  begin
    FLog.Warn(Format('no suit peers for %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  for P in Ps do
  begin
    if P <> nil then
    begin
      M := TGetSnapshotBlocks.Create;
      try
        M.From.Hash := Hash;
        M.Count := Count;
        M.Forward := False;
        Err := P.Send(CodeGetSnapshotBlocks, R.Id, M);
        if Err <> nil then
        begin
          FLog.Error(Format('failed to send GetSnapshotBlocks %s/%d to %s: %v', [Hash.ToString, Count, P.ToString, Err.Message]));
          Done(R.Id, P, Default(TMsg), Err);
        end
        else
        begin
          FLog.Info(Format('send GetSnapshotBlocks %s/%d to %s', [Hash.ToString, Count, P.ToString]));
          Pending(R.Id, P);
        end;
      finally
        M.Free;
      end;
    end;
  end;
end;

procedure TFetcher.FetchSnapshotBlocksWithHeight(Hash: THash; Height, Count: UInt64);
var
  R: TRecord;
  Hold: Boolean;
  Ps: TArray<IPeer>;
  P: IPeer;
  M: TGetSnapshotBlocks;
  Err: Exception;
begin
  if FBlackBlocks.ContainsKey(Hash) then
    Exit;
  if not FSt.SyncExited then
  begin
    FLog.Info(Format('in syncing flow, cannot fetch %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  Hold := Self.Hold(Hash, R);
  if Hold then
  begin
    FLog.Info(Format('fetch suppressed GetSnapshotBlocks %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  Ps := PickTargets(R, Height, FPeers);
  if Length(Ps) = 0 then
  begin
    FLog.Warn(Format('no suit peers for %s/%d', [Hash.ToString, Count]));
    Exit;
  end;

  for P in Ps do
  begin
    if P <> nil then
    begin
      M := TGetSnapshotBlocks.Create;
      try
        M.From.Hash := Hash;
        M.Count := Count;
        M.Forward := False;
        Err := P.Send(CodeGetSnapshotBlocks, R.Id, M);
        if Err <> nil then
        begin
          FLog.Error(Format('failed to send GetSnapshotBlocks %s/%d to %s: %v', [Hash.ToString, Count, P.ToString, Err.Message]));
          Done(R.Id, P, Default(TMsg), Err);
        end
        else
        begin
          FLog.Info(Format('send GetSnapshotBlocks %s/%d to %s', [Hash.ToString, Count, P.ToString]));
          Pending(R.Id, P);
        end;
      finally
        M.Free;
      end;
    end;
  end;
end;

procedure TFetcher.FetchAccountBlocks(Start: THash; Count: UInt64; Address: PAddress);
var
  R: TRecord;
  Hold: Boolean;
  Ps: TArray<IPeer>;
  P: IPeer;
  Addr: TAddress;
  M: TGetAccountBlocks;
  Err: Exception;
begin
  if FBlackBlocks.ContainsKey(Start) then
    Exit;
  if not FSt.SyncExited then
  begin
    FLog.Info(Format('in syncing flow, cannot fetch %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  Hold := Self.Hold(Start, R);
  if Hold then
  begin
    FLog.Info(Format('fetch suppressed GetAccountBlocks %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  Ps := PickTargets(R, 0, FPeers);
  if Length(Ps) = 0 then
  begin
    FLog.Warn(Format('no suit peers for %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  for P in Ps do
  begin
    if P <> nil then
    begin
      if Address <> nil then
        Addr := Address^
      else
        Addr := Default(TAddress);
      M := TGetAccountBlocks.Create;
      try
        M.Address := Addr;
        M.From.Hash := Start;
        M.Count := Count;
        M.Forward := False;
        Err := P.Send(CodeGetAccountBlocks, R.Id, M);
        if Err <> nil then
        begin
          FLog.Error(Format('failed to send GetAccountBlocks %s/%d to %s: %v', [Start.ToString, Count, P.ToString, Err.Message]));
          Done(R.Id, P, Default(TMsg), Err);
        end
        else
        begin
          FLog.Info(Format('send GetAccountBlocks %s/%d to %s', [Start.ToString, Count, P.ToString]));
          Pending(R.Id, P);
        end;
      finally
        M.Free;
      end;
    end;
  end;
end;

procedure TFetcher.FetchAccountBlocksWithHeight(Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
var
  R: TRecord;
  Hold: Boolean;
  Ps: TArray<IPeer>;
  P: IPeer;
  Addr: TAddress;
  M: TGetAccountBlocks;
  Err: Exception;
begin
  if FBlackBlocks.ContainsKey(Start) then
    Exit;
  if not FSt.SyncExited then
  begin
    FLog.Info(Format('in syncing flow, cannot fetch %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  Hold := Self.Hold(Start, R);
  if Hold then
  begin
    FLog.Info(Format('fetch suppressed GetAccountBlocks %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  Ps := PickTargets(R, SHeight, FPeers);
  if Length(Ps) = 0 then
  begin
    FLog.Warn(Format('no suit peers for %s/%d', [Start.ToString, Count]));
    Exit;
  end;

  for P in Ps do
  begin
    if P <> nil then
    begin
      if Address <> nil then
        Addr := Address^
      else
        Addr := Default(TAddress);
      M := TGetAccountBlocks.Create;
      try
        M.Address := Addr;
        M.From.Hash := Start;
        M.Count := Count;
        M.Forward := False;
        Err := P.Send(CodeGetAccountBlocks, R.Id, M);
        if Err <> nil then
        begin
          FLog.Error(Format('failed to send GetAccountBlocks %s/%d to %s: %v', [Start.ToString, Count, P.ToString, Err.Message]));
          Done(R.Id, P, Default(TMsg), Err);
        end
        else
        begin
          FLog.Info(Format('send GetAccountBlocks %s/%d to %s', [Start.ToString, Count, P.ToString]));
          Pending(R.Id, P);
        end;
      finally
        M.Free;
      end;
    end;
  end;
end;

procedure TFetcher.FetchSnapshotBlock(Hash: THash; Peer: IPeer; Callback: TProc<TMsg, Exception>);
var
  M: TGetSnapshotBlocks;
  R: TRecord;
  Err: Exception;
begin
  M := TGetSnapshotBlocks.Create;
  try
    M.From.Hash := Hash;
    M.Count := 1;
    M.Forward := False;
    R := Add(Hash);
    R.Callback := Callback;
    Err := Peer.Send(CodeGetSnapshotBlocks, R.Id, M);
    if Err <> nil then
    begin
      FLog.Warn(Format('failed to query reliable %s to %s', [Hash.ToString, Peer.ToString]));
      Done(R.Id, Peer, Default(TMsg), Err);
    end
    else
      FLog.Info(Format('query reliable %s to %s', [Hash.ToString, Peer.ToString]));
  finally
    M.Free;
  end;
end;

function NewFetcher(Peers: IPeerSet; Receiver: IBlockReceiver; BlackBlocks: TDictionary<THash, Boolean>): IFetcher;
begin
  Result := TFetcher.Create(Peers, Receiver, BlackBlocks);
end;

initialization
  ErrNoSuitablePeer := Exception.Create('no suitable peer');
  ErrFetchTimeout := Exception.Create('timeout');
  ErrNoResource := Exception.Create('no resource');
end.
