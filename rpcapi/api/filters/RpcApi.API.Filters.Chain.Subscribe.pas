unit RpcApi.Api.Filters.ChainSubscribe;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.Types, Interfaces, Interfaces.Core,
  RpcApi.Api.Filters.EventSystem, GoToDelphi.Helpers.TChannel;

type
  TSendBlock = class
  private
    FHash: THash;
    FToAddr: TAddress;
  public
    property Hash: THash read FHash write FHash;
    property ToAddr: TAddress read FToAddr write FToAddr;
  end;

  TAccountChainEvent = class
  private
    FBlockType: Byte;
    FFromBlockHash: THash;
    FHash: THash;
    FHeight: UInt64;
    FAddr: TAddress;
    FToAddr: TAddress;
    FLogs: TArray<IVmLog>;
    FSendBlockList: TArray<TSendBlock>;
  public
    constructor Create(const Block: IAccountBlock; const Logs: TArray<IVmLog>);
    property BlockType: Byte read FBlockType write FBlockType;
    property FromBlockHash: THash read FFromBlockHash write FFromBlockHash;
    property Hash: THash read FHash write FHash;
    property Height: UInt64 read FHeight write FHeight;
    property Addr: TAddress read FAddr write FAddr;
    property ToAddr: TAddress read FToAddr write FToAddr;
    property Logs: TArray<IVmLog> read FLogs write FLogs;
    property SendBlockList: TArray<TSendBlock> read FSendBlockList write FSendBlockList;
  end;

  TSnapshotChainEvent = class
  private
    FHash: THash;
    FHeight: UInt64;
  public
    property Hash: THash read FHash write FHash;
    property Height: UInt64 read FHeight write FHeight;
  end;

  TChainSubscribe = class(TInterfacedObject, IChainObserver)
  private
    FVite: TVite;
    FEs: TEventSystem;
    FListenIdList: TArray<UInt64>;
    FPreDeleteAccountBlocks: TArray<TAccountChainEvent>;
    function PrepareInsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>): Exception;
    function InsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>): Exception;
    function PrepareInsertSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
    function InsertSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
    function PrepareDeleteAccountBlocks(const Blocks: TArray<IAccountBlock>): Exception;
    function DeleteAccountBlocks(const Blocks: TArray<IAccountBlock>): Exception;
    function PrepareDeleteSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
    function DeleteSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
  public
    constructor Create(V: TVite; E: TEventSystem);
    destructor Destroy; override;
    procedure Stop;
  end;

implementation

{ TAccountChainEvent }

constructor TAccountChainEvent.Create(const Block: IAccountBlock; const Logs: TArray<IVmLog>);
var
  I: Integer;
  S: ISendBlock;
begin
  FBlockType := Block.BlockType;
  FFromBlockHash := Block.FromBlockHash;
  FHash := Block.Hash;
  FHeight := Block.Height;
  FAddr := Block.AccountAddress;
  FToAddr := Block.ToAddress;
  FLogs := Logs;
  if Length(Block.SendBlockList) > 0 then
  begin
    SetLength(FSendBlockList, Length(Block.SendBlockList));
    for I := 0 to High(Block.SendBlockList) do
    begin
      S := Block.SendBlockList[I];
      FSendBlockList[I] := TSendBlock.Create;
      FSendBlockList[I].Hash := S.Hash;
      FSendBlockList[I].ToAddr := S.ToAddress;
    end;
  end;
end;

{ TChainSubscribe }

constructor TChainSubscribe.Create(V: TVite; E: TEventSystem);
begin
  FVite := V;
  FEs := E;
  FVite.Chain.Register(Self);
end;

destructor TChainSubscribe.Destroy;
begin
  Stop;
  inherited;
end;

procedure TChainSubscribe.Stop;
begin
  FVite.Chain.UnRegister(Self);
end;

function TChainSubscribe.PrepareInsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>): Exception;
begin
  Result := nil;
end;

function TChainSubscribe.InsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>): Exception;
var
  AcEvents: TArray<TAccountChainEvent>;
  I: Integer;
  B: IVmAccountBlock;
begin
  SetLength(AcEvents, Length(Blocks));
  for I := 0 to High(Blocks) do
  begin
    B := Blocks[I];
    AcEvents[I] := TAccountChainEvent.Create(B.AccountBlock, B.VmDb.GetLogList);
  end;
  FEs.AcCh.Add(AcEvents);
  Result := nil;
end;

function TChainSubscribe.PrepareInsertSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
begin
  Result := nil;
end;

function TChainSubscribe.InsertSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
var
  SbEvents: TArray<TSnapshotChainEvent>;
  Chunk: ISnapshotChunk;
  Event: TSnapshotChainEvent;
  I: Integer;
begin
  SetLength(SbEvents, Length(Chunks));
  for I := 0 to High(Chunks) do
  begin
    Chunk := Chunks[I];
    Event := TSnapshotChainEvent.Create;
    Event.Hash := Chunk.SnapshotBlock.Hash;
    Event.Height := Chunk.SnapshotBlock.Height;
    SbEvents[I] := Event;
  end;
  FEs.SbCh.Add(SbEvents);
  Result := nil;
end;

function TChainSubscribe.PrepareDeleteAccountBlocks(const Blocks: TArray<IAccountBlock>): Exception;
var
  AcEvents: TArray<TAccountChainEvent>;
  B: IAccountBlock;
  LogList: TArray<IVmLog>;
  I: Integer;
begin
  SetLength(AcEvents, Length(Blocks));
  for I := 0 to High(Blocks) do
  begin
    B := Blocks[I];
    if B.LogHash <> nil then
    begin
      try
        LogList := FVite.Chain.GetVmLogList(B.LogHash);
        AcEvents[I] := TAccountChainEvent.Create(B, LogList);
      except
        on E: Exception do
        begin
          FEs.Log.Error('get log list failed when preDeleteAccountBlocks', ['addr', B.AccountAddress.ToString, 'hash', B.Hash.ToString, 'height', B.Height, 'err', E.Message]);
          Result := E;
          Exit;
        end;
      end;
    end
    else
      AcEvents[I] := TAccountChainEvent.Create(B, nil);
  end;
  FPreDeleteAccountBlocks := Concat(FPreDeleteAccountBlocks, AcEvents) as TArray<TAccountChainEvent>;
  Result := nil;
end;

function TChainSubscribe.DeleteAccountBlocks(const Blocks: TArray<IAccountBlock>): Exception;
var
  DeletedBlocks: TArray<TAccountChainEvent>;
begin
  DeletedBlocks := FPreDeleteAccountBlocks;
  FPreDeleteAccountBlocks := nil;
  FEs.AcDelCh.Add(DeletedBlocks);
  Result := nil;
end;

function TChainSubscribe.PrepareDeleteSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
var
  AcEvents: TArray<TAccountChainEvent>;
  Chunk: ISnapshotChunk;
  B: IAccountBlock;
  LogList: TArray<IVmLog>;
  I, J: Integer;
begin
  for I := 0 to High(Chunks) do
  begin
    Chunk := Chunks[I];
    SetLength(AcEvents, Length(Chunk.AccountBlocks));
    for J := 0 to High(Chunk.AccountBlocks) do
    begin
      B := Chunk.AccountBlocks[J];
      if B.LogHash <> nil then
      begin
        try
          LogList := FVite.Chain.GetVmLogList(B.LogHash);
          AcEvents[J] := TAccountChainEvent.Create(B, LogList);
        except
          on E: Exception do
          begin
            FEs.Log.Error('get log list failed when preDeleteSnapshotBlocks', ['addr', B.AccountAddress.ToString, 'hash', B.Hash.ToString, 'height', B.Height, 'err', E.Message]);
            Result := E;
            Exit;
          end;
        end;
      end
      else
        AcEvents[J] := TAccountChainEvent.Create(B, nil);
    end;
    FPreDeleteAccountBlocks := Concat(FPreDeleteAccountBlocks, AcEvents) as TArray<TAccountChainEvent>;
  end;
  Result := nil;
end;

function TChainSubscribe.DeleteSnapshotBlocks(const Chunks: TArray<ISnapshotChunk>): Exception;
var
  SbEvents: TArray<TSnapshotChainEvent>;
  B: ISnapshotChunk;
  Event: TSnapshotChainEvent;
  DeletedBlocks: TArray<TAccountChainEvent>;
  I: Integer;
begin
  SetLength(SbEvents, Length(Chunks));
  for I := 0 to High(Chunks) do
  begin
    B := Chunks[I];
    if B.SnapshotBlock <> nil then
    begin
      Event := TSnapshotChainEvent.Create;
      Event.Hash := B.SnapshotBlock.Hash;
      Event.Height := B.SnapshotBlock.Height;
      SbEvents[I] := Event;
    end;
  end;
  FEs.SbDelCh.Add(SbEvents);

  if Length(FPreDeleteAccountBlocks) > 0 then
  begin
    DeletedBlocks := FPreDeleteAccountBlocks;
    FPreDeleteAccountBlocks := nil;
    FEs.AcDelCh.Add(DeletedBlocks);
  end;
  Result := nil;
end;

end.