unit net.msghandler;

interface

uses
  common.types common.vitepb interfaces interfaces.core,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  net.interface net.message Log15 tools.list,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
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
  System.SysUtils System.Classes System.Generics.Collections System.SyncObjs;

type
  IMsgHandler = interface
    ['{YOUR_GUID_HERE}']
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

  TMsgHandlers = class(TInterfacedObject, IMsgHandler)
  private
    FName: string;
    FHandlers: TDictionary<TCode, IMsgHandler>;
  public
    constructor Create(Name: string);
    destructor Destroy; override;
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
    function Register(H: IMsgHandler): Exception;
    function Unregister(H: IMsgHandler): Exception;
  end;

  TQueryHandler = class(TInterfacedObject, IMsgHandler)
  private
    FMsgHandlers: TMsgHandlers;
    FLock: TCriticalSection;
    FQueue: TList;
    FTerm: TEvent;
    FWg: TCountdownEvent;
    FLog: ILogger;
    procedure Loop;
  public
    constructor Create(Chain: IChain);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

  TCheckHandler = class(TInterfacedObject, IMsgHandler)
  private
    FChain: IChain;
    FLog: ILogger;
    function HandleGetHashHeightList(Get: TGetHashHeightList; out Code: TCode; out Payload: ISerializable): Exception;
  public
    constructor Create(Chain: IChain);
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

  TGetSnapshotBlocksHandler = class(TInterfacedObject, IMsgHandler)
  private
    FChain: ISnapshotBlockReader;
  public
    constructor Create(Chain: ISnapshotBlockReader);
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

  TGetAccountBlocksHandler = class(TInterfacedObject, IMsgHandler)
  private
    FChain: IAccountBlockReader;
  public
    constructor Create(Chain: IAccountBlockReader);
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

  TStateHandler = class(TInterfacedObject, IMsgHandler)
  private
    FMaxNeighbors: Integer;
    FPeers: IPeerSet;
  public
    constructor Create(MaxNeighbors: Integer; Peers: IPeerSet);
    function Name: string;
    function Codes: TArray<TCode>;
    function Handle(Msg: TMsg): Exception;
  end;

function NewQueryHandler(Chain: IChain): TQueryHandler;
function SplitChunk(From, To, Size: UInt64): TArray<TArray<UInt64>>;

implementation

uses
  System.Threading, System.DateUtils;

{ TMsgHandlers }

constructor TMsgHandlers.Create(Name: string);
begin
  FName := Name;
  FHandlers := TDictionary<TCode, IMsgHandler>.Create;
end;

destructor TMsgHandlers.Destroy;
begin
  FHandlers.Free;
  inherited;
end;

function TMsgHandlers.Name: string;
begin
  Result := FName;
end;

function TMsgHandlers.Codes: TArray<TCode>;
var
  C: TCode;
begin
  SetLength(Result, FHandlers.Count);
  var I := 0;
  for C in FHandlers.Keys do
  begin
    Result[I] := C;
    Inc(I);
  end;
end;

function TMsgHandlers.Handle(Msg: TMsg): Exception;
var
  Handler: IMsgHandler;
begin
  Result := nil;
  if FHandlers.TryGetValue(Msg.Code, Handler) then
    Result := Handler.Handle(Msg);
end;

function TMsgHandlers.Register(H: IMsgHandler): Exception;
var
  C: TCode;
begin
  Result := nil;
  for C in H.Codes do
  begin
    if FHandlers.ContainsKey(C) then
      Exit(Exception.Create(Format('handler for code %d has existed', [C])));
    FHandlers.Add(C, H);
  end;
end;

function TMsgHandlers.Unregister(H: IMsgHandler): Exception;
var
  Codes: TArray<TCode>;
  C: TCode;
begin
  Result := nil;
  SetLength(Codes, 0);
  for C in H.Codes do
  begin
    if FHandlers.ContainsKey(C) then
      FHandlers.Remove(C)
    else
      Codes := Codes + [C];
  end;
  if Length(Codes) > 0 then
    Result := Exception.Create(Format('handler for codes %v not exist', [Codes]));
end;

{ TQueryHandler }

constructor TQueryHandler.Create(Chain: IChain);
var
  Err: Exception;
begin
  FMsgHandlers := TMsgHandlers.Create('query');
  FQueue := TList.Create;
  FLock := TCriticalSection.Create;
  FLog := Log15.New(['module', 'query']);
  Err := FMsgHandlers.Register(TGetSnapshotBlocksHandler.Create(Chain));
  if Err <> nil then
    raise Err;
  Err := FMsgHandlers.Register(TGetAccountBlocksHandler.Create(Chain));
  if Err <> nil then
    raise Err;
  Err := FMsgHandlers.Register(TCheckHandler.Create(Chain));
  if Err <> nil then
    raise Err;
end;

destructor TQueryHandler.Destroy;
begin
  FMsgHandlers.Free;
  FQueue.Free;
  FLock.Free;
  inherited;
end;

procedure TQueryHandler.Start;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  FWg := TCountdownEvent.Create(1);
  TTask.Run(procedure begin Loop; end);
end;

procedure TQueryHandler.Stop;
begin
  if FTerm = nil then
    Exit;
  FTerm.SetEvent;
  FWg.Wait;
end;

function TQueryHandler.Name: string;
begin
  Result := FMsgHandlers.Name;
end;

function TQueryHandler.Codes: TArray<TCode>;
begin
  Result := FMsgHandlers.Codes;
end;

function TQueryHandler.Handle(Msg: TMsg): Exception;
begin
  Result := nil;
  FLock.Acquire;
  try
    FQueue.Add(Msg);
  finally
    FLock.Release;
  end;
end;

procedure TQueryHandler.Loop;
const
  Batch = 10;
var
  Tasks: TArray<TMsg>;
  Index: Integer;
  Ele: TObject;
  Now: Int64;
  Msg: TMsg;
  Err: Exception;
begin
  SetLength(Tasks, Batch);
  while not FTerm.IsSet do
  begin
    FLock.Acquire;
    Index := 0;
    while FQueue.Count > 0 do
    begin
      Tasks[Index] := TMsg(FQueue.First);
      FQueue.Delete(0);
      Inc(Index);
      if Index >= Batch then
        Break;
    end;
    FLock.Release;

    if Index = 0 then
      TThread.Sleep(10)
    else
    begin
      Now := Now.ToUnix;
      for Msg in Tasks do
      begin
        if Index = 0 then
          Break;
        Dec(Index);
        if Now - Msg.ReceivedAt > 20 then
        begin
          FLog.Warn(Format('fetch message from %s is expired', [Msg.Sender.ToString]));
          Continue;
        end;
        Err := FMsgHandlers.Handle(Msg);
        if Err <> nil then
          Msg.Sender.Catch(Err);
      end;
    end;
  end;
  FWg.Signal;
end;

{ TCheckHandler }

constructor TCheckHandler.Create(Chain: IChain);
begin
  FChain := Chain;
  FLog := Log15.New(['module', 'checkHandler']);
end;

function TCheckHandler.Name: string;
begin
  Result := 'Check';
end;

function TCheckHandler.Codes: TArray<TCode>;
begin
  Result := [CodeGetHashList];
end;

function TCheckHandler.HandleGetHashHeightList(Get: TGetHashHeightList; out Code: TCode; out Payload: ISerializable): Exception;
var
  Block: ISnapshotBlock;
  Err: Exception;
  Hh: THashHeight;
  Step, Start, To: UInt64;
  Points: TArray<THashHeightPoint>;
  Point: THashHeightPoint;
  Reader: ILedgerReader;
  I: Integer;
begin
  Result := nil;
  Block := nil;
  for Hh in Get.From do
  begin
    Block := FChain.GetSnapshotBlockByHeight(Hh.Height);
    if (Block = nil) or (not Block.Hash.IsEqual(Hh.Hash)) then
    begin
      FLog.Warn(Format('failed to find snapshotblock %s/%d', [Hh.Hash.ToString, Hh.Height]));
      Continue;
    end;
    Break;
  end;
  if Block = nil then
  begin
    Code := CodeException;
    Payload := TPeerError.Create(ExpMissing);
    Exit;
  end;
  Step := Get.Step;
  Start := (Block.Height + 1) div Step * Step;
  if Start < Block.Height + 1 then
    Start := Block.Height + 1;
  To := Get.To;
  SetLength(Points, 0);
  while Start <= To do
  begin
    Block := FChain.GetSnapshotBlockByHeight(Start);
    if Block = nil then
    begin
      FLog.Warn(Format('failed to find snapshotblock at %d', [Start]));
      Break;
    end;
    Point := THashHeightPoint.Create;
    Point.HashHeight.Height := Block.Height;
    Point.HashHeight.Hash := Block.Hash;
    Points := Points + [Point];
    if Start = To then
      Break;
    Start := (Start + Step) div Step * Step;
    if Start > To then
      Start := To;
  end;
  if Length(Points) = 0 then
  begin
    Code := CodeException;
    Payload := TPeerError.Create(ExpMissing);
    Exit;
  end;
  Start := Points[0].HashHeight.Height;
  for I := 1 to Length(Points) - 1 do
  begin
    Point := Points[I];
    Reader := FChain.GetLedgerReaderByHeight(Start, Point.HashHeight.Height);
    if Reader = nil then
      Break;
    Point.Size := Reader.Size;
    Start := Point.HashHeight.Height + 1;
  end;
  Code := CodeHashList;
  Payload := THashHeightPointList.Create;
  (Payload as THashHeightPointList).Points := Points;
end;

function TCheckHandler.Handle(Msg: TMsg): Exception;
var
  Get: TGetHashHeightList;
  Code: TCode;
  Payload: ISerializable;
begin
  Result := nil;
  Get := TGetHashHeightList.Create;
  try
    Get.Deserialize(Msg.Payload);
    Result := HandleGetHashHeightList(Get, Code, Payload);
    if Result = nil then
      Result := Msg.Sender.Send(Code, Msg.Id, Payload);
  finally
    Get.Free;
  end;
end;

{ TGetSnapshotBlocksHandler }

constructor TGetSnapshotBlocksHandler.Create(Chain: ISnapshotBlockReader);
begin
  FChain := Chain;
end;

function TGetSnapshotBlocksHandler.Name: string;
begin
  Result := 'GetSnapshotBlocks';
end;

function TGetSnapshotBlocksHandler.Codes: TArray<TCode>;
begin
  Result := [CodeGetSnapshotBlocks];
end;

function TGetSnapshotBlocksHandler.Handle(Msg: TMsg): Exception;
var
  Req: TGetSnapshotBlocks;
  Block: ISnapshotBlock;
  From, To: UInt64;
  Chunks: TArray<TArray<UInt64>>;
  C: TArray<UInt64>;
  Blocks: TArray<ISnapshotBlock>;
begin
  Result := nil;
  Req := TGetSnapshotBlocks.Create;
  try
    Req.Deserialize(Msg.Payload);
    if not Req.From.Hash.IsZero then
      Block := FChain.GetSnapshotBlockByHash(Req.From.Hash)
    else
      Block := FChain.GetSnapshotBlockByHeight(Req.From.Height);
    if Block = nil then
    begin
      Result := Msg.Sender.Send(CodeException, Msg.Id, TPeerError.Create(ExpMissing));
      Exit;
    end;
    if Req.Forward then
    begin
      From := Block.Height;
      To := From + Req.Count - 1;
    end
    else
    begin
      To := Block.Height;
      if To >= Req.Count then
        From := To - Req.Count + 1
      else
        From := 0;
    end;
    Chunks := SplitChunk(From, To, 100);
    for C in Chunks do
    begin
      Blocks := FChain.GetSnapshotBlocksByHeight(C[0], True, C[1] - C[0] + 1);
      if Length(Blocks) = 0 then
      begin
        Result := Msg.Sender.Send(CodeException, Msg.Id, TPeerError.Create(ExpMissing));
        Exit;
      end;
      Result := Msg.Sender.SendSnapshotBlocks(Blocks, Msg.Id);
      if Result <> nil then
        Exit;
    end;
  finally
    Req.Free;
  end;
end;

{ TGetAccountBlocksHandler }

constructor TGetAccountBlocksHandler.Create(Chain: IAccountBlockReader);
begin
  FChain := Chain;
end;

function TGetAccountBlocksHandler.Name: string;
begin
  Result := 'GetAccountBlocks Handler';
end;

function TGetAccountBlocksHandler.Codes: TArray<TCode>;
begin
  Result := [CodeGetAccountBlocks];
end;

function TGetAccountBlocksHandler.Handle(Msg: TMsg): Exception;
var
  Req: TGetAccountBlocks;
  Block: IAccountBlock;
  Address: TAddress;
  From, To: UInt64;
  Chunks: TArray<TArray<UInt64>>;
  C: TArray<UInt64>;
  Blocks: TArray<IAccountBlock>;
begin
  Result := nil;
  Req := TGetAccountBlocks.Create;
  try
    Req.Deserialize(Msg.Payload);
    if not Req.From.Hash.IsZero then
      Block := FChain.GetAccountBlockByHash(Req.From.Hash)
    else if Req.Address.IsZero then
      Exit(Exception.Create('missing param to GetAccountBlocks'))
    else
      Block := FChain.GetAccountBlockByHeight(Req.Address, Req.From.Height);
    if Block = nil then
    begin
      Result := Msg.Sender.Send(CodeException, Msg.Id, TPeerError.Create(ExpMissing));
      Exit;
    end;
    Address := Block.AccountAddress;
    if Req.Forward then
    begin
      From := Block.Height;
      To := From + Req.Count - 1;
    end
    else
    begin
      To := Block.Height;
      if To >= Req.Count then
        From := To - Req.Count + 1
      else
        From := 0;
    end;
    Chunks := SplitChunk(From, To, 100);
    for C in Chunks do
    begin
      Blocks := FChain.GetAccountBlocksByHeight(Address, C[1], C[1] - C[0] + 1);
      if Length(Blocks) = 0 then
      begin
        Result := Msg.Sender.Send(CodeException, Msg.Id, TPeerError.Create(ExpMissing));
        Exit;
      end;
      Result := Msg.Sender.SendAccountBlocks(Blocks, Msg.Id);
      if Result <> nil then
        Exit;
    end;
  finally
    Req.Free;
  end;
end;

{ TStateHandler }

constructor TStateHandler.Create(MaxNeighbors: Integer; Peers: IPeerSet);
begin
  FMaxNeighbors := MaxNeighbors;
  FPeers := Peers;
end;

function TStateHandler.Name: string;
begin
  Result := 'state';
end;

function TStateHandler.Codes: TArray<TCode>;
begin
  Result := [CodeHeartBeat];
end;

function TStateHandler.Handle(Msg: TMsg): Exception;
var
  Heartbeat: TState;
  Head: THash;
  Count, I: Integer;
  Pl: TArray<TPeerConn>;
  Hp: TStatePeer;
begin
  Result := nil;
  Heartbeat := TState.Create;
  try
    Heartbeat.FromBytes(Msg.Payload);
    Head := THash.FromBytes(Heartbeat.Head);
    Msg.Sender.SetState(Head, Heartbeat.Height);
    Count := Length(Heartbeat.Peers);
    if Count > FMaxNeighbors then
      Count := FMaxNeighbors;
    SetLength(Pl, Count);
    for I := 0 to Count - 1 do
    begin
      Hp := Heartbeat.Peers[I];
      Pl[I].Id := Hp.ID;
      Pl[I].Add := Hp.Status <> Disconnected;
    end;
    Msg.Sender.SetPeers(Pl, Heartbeat.Patch);
  finally
    Heartbeat.Free;
  end;
end;

function NewQueryHandler(Chain: IChain): TQueryHandler;
begin
  Result := TQueryHandler.Create(Chain);
end;

function SplitChunk(From, To, Size: UInt64): TArray<TArray<UInt64>>;
var
  Total, I: UInt64;
  CTo: UInt64;
begin
  if (From > To) or (To = 0) then
    Exit(nil);
  Total := (To - From) div Size + 1;
  SetLength(Result, Total);
  I := 0;
  while From <= To do
  begin
    CTo := From + Size - 1;
    if CTo > To then
      CTo := To;
    SetLength(Result[I], 2);
    Result[I][0] := From;
    Result[I][1] := CTo;
    From := CTo + 1;
    Inc(I);
  end;
  SetLength(Result, I);
end;

end.
