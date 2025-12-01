unit Ledger.Pipeline.Pipeline.Blocks;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  Common.Types,
  Vite.Interfaces.Core,
  Ledger.Chain.Block,
  Net.Interface,
  Ledger.Pipeline.Blocks,
  GoToDelphi.Helpers.TChannel;

type
  TBlocksPipeline = class(TInterfacedObject, IChunkReader)
  private
    FFromDir: string;
    FFromBlocks: TBlocks;
    FChunkCh: TChannel<ISnapshotChunk>;
    FCurChunk: IChunk;
    function ReadChunk: IChunk;
  public
    constructor Create(ParaFromDir: string; ParaFileSize: Int64);
    procedure Run(ParaHeight: UInt64);
    destructor Destroy; override;
    function Peek: IChunk;
    procedure Pop(ParaHash: THash);
  end;

function NewBlocksPipeline(ParaFromDir: string; ParaHeight: UInt64): TBlocksPipeline;

implementation

uses
  Log15;

var
  GLog: ILog;

{ TBlocksPipeline }

constructor TBlocksPipeline.Create(ParaFromDir: string; ParaFileSize: Int64);
begin
  inherited Create;
  FFromDir := ParaFromDir;
  FFromBlocks := TBlocks.Create(ParaFromDir, ParaFileSize);
end;

procedure TBlocksPipeline.Run(ParaHeight: UInt64);
var
  vH: UInt64;
  vLocation: TLocation;
begin
  FChunkCh := TChannel<ISnapshotChunk>.Create(1000);

  vH := ParaHeight;
  if vH > 100 then
    vH := vH - 100;

  try
    vLocation := FFromBlocks.Location(vH);
  except
    on E: Exception do
    begin
      GLog.Error('new blocks pipeline fail. read location fail', 'err', E.Message);
      raise;
    end;
  end;

  TTask.Run(procedure
  var
    vChunk: ISnapshotChunk;
    vNext: TLocation;
  begin
    try
      while True do
      begin
        try
          FFromBlocks.FBlockDb.ReadChunk(vLocation, vChunk, vNext);
          GLog.Debug(Format('pipeline chunk to %d', [vChunk.SnapshotBlock.Height]));
          FChunkCh.Send(vChunk);
          vLocation := vNext;
        except
          on E: Exception do
          begin
            GLog.Error('read chunk fail.', 'err', E.Message, 'location', vLocation.ToString, 'height', vH);
            Exit;
          end;
        end;
      end;
    finally
      FChunkCh.Close;
    end;
  end);
end;

destructor TBlocksPipeline.Destroy;
begin
  FFromBlocks.Free;
  FChunkCh.Free;
  inherited;
end;

function TBlocksPipeline.Peek: IChunk;
var
  vChunk: IChunk;
begin
  if FCurChunk <> nil then
    Result := FCurChunk
  else
  begin
    vChunk := ReadChunk;
    FCurChunk := vChunk;
    Result := vChunk;
  end;
end;

function TBlocksPipeline.ReadChunk: IChunk;
var
  vI: Integer;
  vChunks: TArray<ISnapshotChunk>;
  vChunk: ISnapshotChunk;
  vOk: Boolean;
begin
  vI := 0;
  SetLength(vChunks, 0);
  while True do
  begin
    Inc(vI);
    if vI > 1000 then
    begin
      Result := TChunk.Create(vChunks, ltLocal);
      Exit;
    end;

    if FChunkCh.TryReceive(vChunk, vOk) then
    begin
      if vOk then
      begin
        SetLength(vChunks, Length(vChunks) + 1);
        vChunks[High(vChunks)] := vChunk;
      end
      else
      begin
        Result := TChunk.Create(vChunks, ltLocal);
        Exit;
      end;
    end
    else
    begin
      Result := TChunk.Create(vChunks, ltLocal);
      Exit;
    end;
  end;
end;

procedure TBlocksPipeline.Pop(ParaHash: THash);
begin
  if (FCurChunk <> nil) and (FCurChunk.GetSnapshotRange[1].Hash.IsEqual(ParaHash)) then
    FCurChunk := nil;
end;

function NewBlocksPipeline(ParaFromDir: string; ParaHeight: UInt64): TBlocksPipeline;
var
  vP: TBlocksPipeline;
begin
  vP := TBlocksPipeline.Create(ParaFromDir, TBlockDB.FixFileSize);
  try
    vP.Run(ParaHeight);
    Result := vP;
  except
    on E: Exception do
    begin
      GLog.Error('new blocks pipeline fail.', 'err', E.Message);
      vP.Free;
      raise;
    end;
  end;
end;

initialization
  GLog := TLog15.New('module', 'ledger/pipeline');

end.