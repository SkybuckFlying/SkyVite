unit net.broadcaster;

interface

uses
  common.types interfaces.core net.interface common.bloom tools.circle,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  System.SysUtils System.Classes System.Generics.Collections;

type
  IBlockStore = interface
    ['{YOUR_GUID_HERE}']
    procedure EnqueueAccountBlock(Block: IAccountBlock);
    function DequeueAccountBlock: IAccountBlock;
    procedure EnqueueSnapshotBlock(Block: ISnapshotBlock);
    function DequeueSnapshotBlock: ISnapshotBlock;
  end;

  TMemBlockStore = class(TInterfacedObject, IBlockStore)
  private
    FRW: TMultiReadSingleWrite;
    FAIndex: Integer;
    FABlocks: TArray<IAccountBlock>;
    FSIndex: Integer;
    FSBlocks: TArray<ISnapshotBlock>;
  public
    constructor Create(Max: Integer);
    procedure EnqueueAccountBlock(Block: IAccountBlock);
    function DequeueAccountBlock: IAccountBlock;
    procedure EnqueueSnapshotBlock(Block: ISnapshotBlock);
    function DequeueSnapshotBlock: ISnapshotBlock;
  end;

  IForwardStrategy = interface
    ['{YOUR_GUID_HERE}']
    function ChoosePeers(Sender: IPeer): TArray<IPeer>;
  end;

  TFullForwardStrategy = class(TInterfacedObject, IForwardStrategy)
  private
    FPs: IPeerSet;
  public
    constructor Create(Ps: IPeerSet);
    function ChoosePeers(Sender: IPeer): TArray<IPeer>;
  end;

  TCrossForwardStrategy = class(TInterfacedObject, IForwardStrategy)
  private
    FPs: IPeerSet;
    FCommonMax: Integer;
    FCommonRatio: Integer;
  public
    constructor Create(Ps: IPeerSet; CommonMax, CommonRatio: Integer);
    function ChoosePeers(Sender: IPeer): TArray<IPeer>;
  end;

  TPickItem = class
  private
    FTotal: Integer;
    FPicked: Integer;
    FFailed: Integer;
    FCreateAt: Int64;
    FResetting: Integer;
    FLife: Int64;
  public
    procedure Inc;
    procedure Fail;
    procedure Pick;
    procedure Reset(Now: Int64);
    function Expired(Now: Int64): Boolean;
  end;

  TRingStatic = class
  private
    FRW: TMultiReadSingleWrite;
    FItems: TArray<TPickItem>;
    FIndex: Integer;
    FSize: Integer;
    FD: Int64;
  public
    constructor Create(Size: Integer; D: Int64);
    destructor Destroy; override;
    function Get: TPickItem;
    function FailedRatio: Single;
  end;

  IBroadChainReader = interface
    ['{YOUR_GUID_HERE}']
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetConfirmedTimes(BlockHash: THash): UInt64;
  end;

  TBroadcaster = class(TInterfacedObject, IHandler)
  private
    FPeers: IPeerSet;
    FStrategy: IForwardStrategy;
    FSt: ISyncState;
    FVerifier: IVerifier;
    FFeed: IBlockNotifier;
    FFilter: TFilter;
    FRings: TRingStatic;
    FStore: IBlockStore;
    FMu: TCriticalSection;
    FStatistic: TCircleList;
    FChain: IBroadChainReader;
    FLog: ILogger;
  public
    constructor Create(Peers: IPeerSet; Verifier: IVerifier; Feed: IBlockNotifier;
      Store: IBlockStore; Strategy: IForwardStrategy; Chain: IBroadChainReader);
    destructor Destroy; override;
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
    function Statistic: TArray<Int64>;
    procedure SubSyncState(St: ISyncState);
    procedure BroadcastSnapshotBlock(Block: ISnapshotBlock);
    procedure BroadcastSnapshotBlocks(Blocks: TArray<ISnapshotBlock>);
    procedure BroadcastAccountBlock(Block: IAccountBlock);
    procedure BroadcastAccountBlocks(Blocks: TArray<IAccountBlock>);
    procedure ForwardSnapshotBlock(Msg: TNewSnapshotBlock; Sender: IPeer);
    procedure ForwardAccountBlock(Msg: TNewAccountBlock; Sender: IPeer);
    function Status: TBroadcastStatus;
  end;

  TBroadcastStatus = record
    CheckFailedRatio: Single;
    Latency: TArray<Int64>;
  end;

function NewMemBlockStore(Max: Integer): IBlockStore;
function CreateForwardStrategy(Strategy: string; Ps: IPeerSet): IForwardStrategy;
function NewBroadcaster(Peers: IPeerSet; Verifier: IVerifier; Feed: IBlockNotifier;
  Store: IBlockStore; Strategy: IForwardStrategy; Chain: IBroadChainReader): TBroadcaster;

implementation

uses
  System.Math, Log15;

{ TMemBlockStore }

constructor TMemBlockStore.Create(Max: Integer);
begin
  FRW.Create;
  SetLength(FABlocks, 0, Max);
  SetLength(FSBlocks, 0, Max);
end;

procedure TMemBlockStore.EnqueueAccountBlock(Block: IAccountBlock);
begin
  FRW.BeginWrite;
  try
    if Length(FABlocks) < Cap(FABlocks) then
      FABlocks := FABlocks + [Block];
  finally
    FRW.EndWrite;
  end;
end;

function TMemBlockStore.DequeueAccountBlock: IAccountBlock;
begin
  FRW.BeginWrite;
  try
    if FAIndex > Length(FABlocks) - 1 then
    begin
      SetLength(FABlocks, 0);
      Exit(nil);
    end;
    Result := FABlocks[FAIndex];
    Inc(FAIndex);
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemBlockStore.EnqueueSnapshotBlock(Block: ISnapshotBlock);
begin
  FRW.BeginWrite;
  try
    if Length(FSBlocks) < Cap(FSBlocks) then
      FSBlocks := FSBlocks + [Block];
  finally
    FRW.EndWrite;
  end;
end;

function TMemBlockStore.DequeueSnapshotBlock: ISnapshotBlock;
begin
  FRW.BeginWrite;
  try
    if FSIndex > Length(FSBlocks) - 1 then
    begin
      SetLength(FSBlocks, 0);
      Exit(nil);
    end;
    Result := FSBlocks[FSIndex];
    Inc(FSIndex);
  finally
    FRW.EndWrite;
  end;
end;

function NewMemBlockStore(Max: Integer): IBlockStore;
begin
  Result := TMemBlockStore.Create(Max);
end;

{ TFullForwardStrategy }

constructor TFullForwardStrategy.Create(Ps: IPeerSet);
begin
  FPs := Ps;
end;

function TFullForwardStrategy.ChoosePeers(Sender: IPeer): TArray<IPeer>;
var
  OurPeers: TArray<IPeer>;
  P: IPeer;
begin
  OurPeers := FPs.Peers;
  SetLength(Result, 0);
  for P in OurPeers do
    if P.Id <> Sender.Id then
      Result := Result + [P];
end;

{ TCrossForwardStrategy }

constructor TCrossForwardStrategy.Create(Ps: IPeerSet; CommonMax, CommonRatio: Integer);
begin
  FPs := Ps;
  FCommonMax := CommonMax;
  if CommonRatio < 0 then
    FCommonRatio := 0
  else if CommonRatio > 100 then
    FCommonRatio := 100
  else
    FCommonRatio := CommonRatio;
end;

function TCrossForwardStrategy.ChoosePeers(Sender: IPeer): TArray<IPeer>;
var
  PpMap: TDictionary<TPeerId, Boolean>;
  OurPeers: TArray<IPeer>;
  Common, EnoughIndex, I, J, OverPeerNum, Max: Integer;
  P: IPeer;
begin
  PpMap := Sender.Peers;
  OurPeers := FPs.Peers;

  if PpMap.Count = 0 then
  begin
    J := 0;
    for I := 0 to Length(OurPeers) - 1 do
    begin
      if OurPeers[I].Id <> Sender.Id then
      begin
        if J < I then
          OurPeers[J] := OurPeers[I];
        Inc(J);
      end;
    end;
    SetLength(OurPeers, J);
    Result := OurPeers;
    Exit;
  end;

  Common := 0;
  EnoughIndex := -1;
  for I := 0 to Length(OurPeers) - 1 do
  begin
    P := OurPeers[I];
    if P.Id = Sender.Id then
    begin
      OurPeers[I] := nil;
      Continue;
    end;

    if PpMap.ContainsKey(P.Id) then
    begin
      Inc(Common);
      if Common <= FCommonMax then
        EnoughIndex := I;
    end;
  end;

  if FCommonMax > Common then
    FCommonMax := Common;

  Max := Common * FCommonRatio div 100;
  if Max = 0 then
    Max := 1;

  if Max < FCommonMax then
  begin
    OverPeerNum := FCommonMax - Max;
    J := 0;
    for I := 0 to EnoughIndex do
    begin
      P := OurPeers[I];
      if (P <> nil) and PpMap.ContainsKey(P.Id) then
      begin
        OurPeers[I] := nil;
        Inc(J);
        if J = OverPeerNum then
          Break;
      end;
    end;
  end;

  J := 0;
  for I := 0 to Length(OurPeers) - 1 do
  begin
    if OurPeers[I] <> nil then
    begin
      if J < I then
        OurPeers[J] := OurPeers[I];
      Inc(J);
    end;
  end;
  SetLength(OurPeers, J);
  Result := OurPeers;
end;

function CreateForwardStrategy(Strategy: string; Ps: IPeerSet): IForwardStrategy;
begin
  if Strategy = 'full' then
    Result := TFullForwardStrategy.Create(Ps)
  else
    Result := TCrossForwardStrategy.Create(Ps, 3, 10);
end;

{ TPickItem }

procedure TPickItem.Inc;
begin
  TInterlocked.Increment(FTotal);
end;

procedure TPickItem.Fail;
begin
  TInterlocked.Increment(FFailed);
end;

procedure TPickItem.Pick;
begin
  TInterlocked.Increment(FPicked);
end;

procedure TPickItem.Reset(Now: Int64);
begin
  if not Expired(Now) then
    Exit;

  if TInterlocked.CompareExchange(FResetting, 1, 0) = 0 then
  begin
    FCreateAt := Now;
    FTotal := 0;
    FFailed := 0;
    FPicked := 0;
    TInterlocked.Exchange(FResetting, 0);
  end;
end;

function TPickItem.Expired(Now: Int64): Boolean;
begin
  Result := FCreateAt + FLife < Now;
end;

{ TRingStatic }

constructor TRingStatic.Create(Size: Integer; D: Int64);
var
  I: Integer;
  Now: Int64;
begin
  FRW.Create;
  SetLength(FItems, Size);
  FIndex := 0;
  FSize := Size;
  FD := D;
  Now := TDateTime.Now.ToUniversalTime.ToBinary;
  for I := 0 to Size - 1 do
  begin
    FItems[I] := TPickItem.Create;
    FItems[I].FCreateAt := Now;
    FItems[I].FLife := D;
  end;
end;

destructor TRingStatic.Destroy;
var
  Item: TPickItem;
begin
  for Item in FItems do
    Item.Free;
  FRW.Free;
  inherited;
end;

function TRingStatic.Get: TPickItem;
var
  Now: Int64;
  Index: Integer;
  Item: TPickItem;
begin
  Now := TDateTime.Now.ToUniversalTime.Ticks;
  Index := TInterlocked.Read(FIndex);
  Item := FItems[Index];
  if Item.Expired(Now) then
  begin
    Index := (Index + 1) and (FSize - 1);
    TInterlocked.Exchange(FIndex, Index);
    Item := FItems[Index];
    Item.Reset(Now);
  end;
  Result := Item;
end;

function TRingStatic.FailedRatio: Single;
var
  Failed, Pick: Integer;
  Item: TPickItem;
begin
  Failed := 0;
  Pick := 0;
  for Item in FItems do
  begin
    Failed := Failed + Item.FFailed;
    Pick := Pick + Item.FPicked;
  end;
  if Pick = 0 then
    Pick := 1;
  Result := Failed / Pick;
end;

{ TBroadcaster }

constructor TBroadcaster.Create(Peers: IPeerSet; Verifier: IVerifier; Feed: IBlockNotifier;
  Store: IBlockStore; Strategy: IForwardStrategy; Chain: IBroadChainReader);
begin
  FPeers := Peers;
  FVerifier := Verifier;
  FFeed := Feed;
  FStore := Store;
  FFilter := TFilter.Create(100000, 0.0001);
  FStrategy := Strategy;
  FChain := Chain;
  FRings := TRingStatic.Create(8, 2);
  FMu := TCriticalSection.Create;
  FStatistic := TCircleList.Create(24 * 3600);
  FLog := Log15.New(['module', 'broadcaster']);
end;

destructor TBroadcaster.Destroy;
begin
  FFilter.Free;
  FRings.Free;
  FMu.Free;
  FStatistic.Free;
  inherited;
end;

function TBroadcaster.Name: string;
begin
  Result := 'broadcaster';
end;

function TBroadcaster.Codes: TArray<TCode>;
begin
  Result := [CodeNewAccountBlock, CodeNewSnapshotBlock];
end;

function TBroadcaster.Handle(Msg: TMsg): Exception;
var
  Nb: TNewSnapshotBlock;
  Block: ISnapshotBlock;
  Hash: THash;
  PickItem: TPickItem;
  CheckFailedRatio: Single;
  ShouldCheck: Boolean;
  ConfirmTimes: UInt64;
  Nab: TNewAccountBlock;
  AccBlock: IAccountBlock;
begin
  Result := nil;
  case Msg.Code of
    CodeNewSnapshotBlock:
      begin
        Nb := TNewSnapshotBlock.Create;
        try
          Nb.Deserialize(Msg.Payload);
          Msg.Recycle;
          if Nb.Block = nil then
            Exit(Exception.Create('propagation missing block'));
          Block := Nb.Block;
          if Block.Height + 100 < FChain.GetLatestSnapshotBlock.Height then
          begin
            FLog.Warn(Format('receive new snapshotblock %s/%d from %s: too old', [Block.Hash.ToString, Block.Height, Msg.Sender.ToString]));
            Exit;
          end;
          FLog.Info(Format('receive new snapshotblock %s/%d from %s', [Block.Hash.ToString, Block.Height, Msg.Sender.ToString]));
          if FFilter.Test(Block.Hash.Bytes) then
            Exit;
          Hash := Block.ComputeHash;
          if FFilter.TestAndAdd(Hash.Bytes) then
            Exit;
          Result := FVerifier.VerifyNetSnapshotBlock(Block);
          if Result <> nil then
          begin
            FLog.Error(Format('verify new snapshotblock %s/%d from %s error: %s', [Hash.ToString, Block.Height, Msg.Sender.ToString, Result.Message]));
            Exit;
          end;
          if Nb.TTL > 0 then
          begin
            Dec(Nb.TTL);
            ForwardSnapshotBlock(Nb, Msg.Sender);
          end;
          if FSt.SyncExited then
            FFeed.NotifySnapshotBlock(Block, bsRemoteBroadcast)
          else
          begin
            FStore.EnqueueSnapshotBlock(Block);
            FLog.Info(Format('syncing, don`t give %s/%d to pool', [Hash.ToString, Block.Height]));
          end;
        finally
          Nb.Free;
        end;
      end;
    CodeNewAccountBlock:
      begin
        Nab := TNewAccountBlock.Create;
        try
          Nab.Deserialize(Msg.Payload);
          Msg.Recycle;
          if Nab.Block = nil then
            Exit(Exception.Create('propagation missing block'));
          AccBlock := Nab.Block;
          FLog.Info(Format('receive new accountblock %s from %s', [AccBlock.Hash.ToString, Msg.Sender.ToString]));
          if FFilter.Test(AccBlock.Hash.Bytes) then
            Exit;
          Hash := AccBlock.ComputeHash;
          if FFilter.TestAndAdd(Hash.Bytes) then
            Exit;
          PickItem := FRings.Get;
          PickItem.Inc;
          CheckFailedRatio := FRings.FailedRatio;
          ShouldCheck := False;
          if CheckFailedRatio > 0.3 then
            ShouldCheck := True
          else if Random(10) < 3 then
            ShouldCheck := True;
          if ShouldCheck then
          begin
            PickItem.Pick;
            ConfirmTimes := FChain.GetConfirmedTimes(Hash);
            if ConfirmTimes > 100 then
            begin
              PickItem.Fail;
              FLog.Warn(Format('receive new accountblock %s from %s: confirmed times %d too old', [AccBlock.Hash.ToString, Msg.Sender.ToString, ConfirmTimes]));
              Exit;
            end;
          end;
          Result := FVerifier.VerifyNetAccountBlock(AccBlock);
          if Result <> nil then
          begin
            FLog.Error(Format('verify new accountblock %s from %s error: %s', [Hash.ToString, Msg.Sender.ToString, Result.Message]));
            Exit;
          end;
          if Nab.TTL > 0 then
          begin
            Dec(Nab.TTL);
            ForwardAccountBlock(Nab, Msg.Sender);
          end;
          if FSt.SyncExited then
            FFeed.NotifyAccountBlock(AccBlock, bsRemoteBroadcast)
          else
          begin
            FStore.EnqueueAccountBlock(AccBlock);
            FLog.Info(Format('syncing, don`t give %s/%d to pool', [Hash.ToString, AccBlock.Height]));
          end;
        finally
          Nab.Free;
        end;
      end;
  end;
end;

function TBroadcaster.Statistic: TArray<Int64>;
var
  T1, T12, T24: Double;
  First: Boolean;
  I: Integer;
  Records1hf, Records12hf: Double;
  Count: Int64;
  CountF: Double;
  Vf: Double;
  Key: TCircleKey;
  V: Int64;
begin
  SetLength(Result, 4);
  T1 := 0;
  T12 := 0;
  T24 := 0;
  First := True;
  I := 0;
  Records1hf := 3600;
  Records12hf := 12 * 3600;
  FMu.Acquire;
  try
    Count := FStatistic.Size;
    if Count = 0 then
      Exit;
    CountF := Count;
    FStatistic.TraverseR(
      function(const Key: TCircleKey): Boolean
      begin
        V := Key.Value;
        if First then
        begin
          Result[0] := V;
          First := False;
        end;
        Vf := V;
        if Count < 3600 then
          T1 := T1 + Vf / CountF
        else if Count < 12 * 3600 then
        begin
          T12 := T12 + Vf / CountF;
          if I < 3600 then
            T1 := T1 + Vf / Records1hf;
        end
        else
        begin
          T24 := T24 + Vf / CountF;
          if I < 3600 then
            T1 := T1 + Vf / Records1hf;
          if I < 12 * 3600 then
            T12 := T12 + Vf / Records12hf;
        end;
        Inc(I);
        Result := True;
      end);
  finally
    FMu.Release;
  end;
  Result[1] := Trunc(T1);
  Result[2] := Trunc(T12);
  Result[3] := Trunc(T24);
end;

procedure TBroadcaster.SubSyncState(St: ISyncState);
var
  Block: ISnapshotBlock;
  AccBlock: IAccountBlock;
begin
  FSt := St;
  if FSt.SyncExited then
  begin
    Block := FStore.DequeueSnapshotBlock;
    while Block <> nil do
    begin
      FFeed.NotifySnapshotBlock(Block, RemoteBroadcast);
      Block := FStore.DequeueSnapshotBlock;
    end;
    AccBlock := FStore.DequeueAccountBlock;
    while AccBlock <> nil do
    begin
      FFeed.NotifyAccountBlock(AccBlock, RemoteBroadcast);
      AccBlock := FStore.DequeueAccountBlock;
    end;
  end;
end;

procedure TBroadcaster.BroadcastSnapshotBlock(Block: ISnapshotBlock);
var
  Msg: TNewSnapshotBlock;
  Data: TBytes;
  RawMsg: TMsg;
  Ps: TArray<IPeer>;
  P: IPeer;
  Err: Exception;
begin
  if FSt.IsSyncing then
  begin
    FLog.Warn(Format('failed to broadcast snapshotblock %s/%d: syncing', [Block.Hash.ToString, Block.Height]));
    Exit;
  end;
  Msg := TNewSnapshotBlock.Create;
  try
    Msg.Block := Block;
    Msg.TTL := 32;
    Data := Msg.Serialize;
    FFilter.Add(Block.Hash.Bytes);
    RawMsg.Code := CodeNewSnapshotBlock;
    RawMsg.Id := 0;
    RawMsg.Payload := Data;
    Ps := FPeers.Peers;
    for P in Ps do
    begin
      Err := P.WriteMsg(RawMsg);
      if Err <> nil then
      begin
        P.Catch(Err);
        FLog.Error(Format('failed to broadcast snapshotblock %s/%d to %s: %v', [Block.Hash.ToString, Block.Height, P.ToString, Err.Message]));
      end
      else
        FLog.Info(Format('broadcast snapshotblock %s/%d to %s', [Block.Hash.ToString, Block.Height, P.ToString]));
    end;
  finally
    Msg.Free;
  end;
end;

procedure TBroadcaster.BroadcastSnapshotBlocks(Blocks: TArray<ISnapshotBlock>);
var
  Block: ISnapshotBlock;
begin
  for Block in Blocks do
    BroadcastSnapshotBlock(Block);
end;

procedure TBroadcaster.BroadcastAccountBlock(Block: IAccountBlock);
var
  Msg: TNewAccountBlock;
  Data: TBytes;
  RawMsg: TMsg;
  Ps: TArray<IPeer>;
  P: IPeer;
  Err: Exception;
begin
  if FSt.IsSyncing then
  begin
    FLog.Warn(Format('failed to broadcast accountblock %s/%d: syncing', [Block.Hash.ToString, Block.Height]));
    Exit;
  end;
  Msg := TNewAccountBlock.Create;
  try
    Msg.Block := Block;
    Msg.TTL := 32;
    Data := Msg.Serialize;
    FFilter.Add(Block.Hash.Bytes);
    RawMsg.Code := CodeNewAccountBlock;
    RawMsg.Id := 0;
    RawMsg.Payload := Data;
    Ps := FPeers.Peers;
    for P in Ps do
    begin
      Err := P.WriteMsg(RawMsg);
      if Err <> nil then
      begin
        P.Catch(Err);
        FLog.Error(Format('failed to broadcast accountblock %s to %s: %v', [Block.Hash.ToString, P.ToString, Err.Message]));
      end
      else
        FLog.Info(Format('broadcast accountblock %s to %s', [Block.Hash.ToString, P.ToString]));
    end;
  finally
    Msg.Free;
  end;
end;

procedure TBroadcaster.BroadcastAccountBlocks(Blocks: TArray<IAccountBlock>);
var
  Block: IAccountBlock;
begin
  for Block in Blocks do
    BroadcastAccountBlock(Block);
end;

procedure TBroadcaster.ForwardSnapshotBlock(Msg: TNewSnapshotBlock; Sender: IPeer);
var
  Data: TBytes;
  RawMsg: TMsg;
  Pl: TArray<IPeer>;
  P: IPeer;
  Err: Exception;
  Now: TDateTime;
  Current: UInt64;
  Delta: TTimeSpan;
begin
  Data := Msg.Serialize;
  RawMsg.Code := CodeNewSnapshotBlock;
  RawMsg.Id := 0;
  RawMsg.Payload := Data;
  Pl := FStrategy.ChoosePeers(Sender);
  for P in Pl do
  begin
    if P.KnownBlocks.TestAndAdd(Msg.Block.Hash.Bytes) then
      Continue
    else
    begin
      Err := P.WriteMsg(RawMsg);
      if Err <> nil then
      begin
        P.Catch(Err);
        FLog.Error(Format('failed to forward snapshotblock %s/%d to %s: %v', [Msg.Block.Hash.ToString, Msg.Block.Height, P.ToString, Err.Message]));
      end
      else
        FLog.Info(Format('forward snapshotblock %s/%d to %s', [Msg.Block.Hash.ToString, Msg.Block.Height, P.ToString]));
    end;
  end;
  if FChain <> nil then
  begin
    Now := TDateTime.Now;
    Current := FChain.GetLatestSnapshotBlock.Height;
    if (Msg.Block.Timestamp <> 0) and (Msg.Block.Height > Current) then
    begin
      Delta := Now - TDateTime.FromUniversalTime(Msg.Block.Timestamp);
      FMu.Acquire;
      try
        FStatistic.Put(Delta.TotalMilliseconds);
      finally
        FMu.Release;
      end;
    end;
  end;
end;

procedure TBroadcaster.ForwardAccountBlock(Msg: TNewAccountBlock; Sender: IPeer);
var
  Data: TBytes;
  RawMsg: TMsg;
  Pl: TArray<IPeer>;
  P: IPeer;
  Err: Exception;
begin
  Data := Msg.Serialize;
  RawMsg.Code := CodeNewAccountBlock;
  RawMsg.Id := 0;
  RawMsg.Payload := Data;
  Pl := FStrategy.ChoosePeers(Sender);
  for P in Pl do
  begin
    if P.KnownBlocks.TestAndAdd(Msg.Block.Hash.Bytes) then
      Continue
    else
    begin
      Err := P.WriteMsg(RawMsg);
      if Err <> nil then
      begin
        P.Catch(Err);
        FLog.Error(Format('failed to forward accountblock %s to %s: %v', [Msg.Block.Hash.ToString, P.ToString, Err.Message]));
      end
      else
        FLog.Info(Format('forward accountblock %s to %s', [Msg.Block.Hash.ToString, P.ToString]));
    end;
  end;
end;

function TBroadcaster.Status: TBroadcastStatus;
begin
  Result.CheckFailedRatio := FRings.FailedRatio;
  Result.Latency := Statistic;
end;

function NewBroadcaster(Peers: IPeerSet; Verifier: IVerifier; Feed: IBlockNotifier;
  Store: IBlockStore; Strategy: IForwardStrategy; Chain: IBroadChainReader): TBroadcaster;
begin
  Result := TBroadcaster.Create(Peers, Verifier, Feed, Store, Strategy, Chain);
end;

end.
