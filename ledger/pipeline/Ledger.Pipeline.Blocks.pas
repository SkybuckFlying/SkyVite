unit Ledger.Pipeline.Blocks;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.IOUtils,
  Ledger.Chain.Block,
  Ledger.Chain.FileManager,
  Log15;

type
  THeightMeta = record
    mLocation: TLocation;
    mHeight: UInt64;
  end;

  TBlocksMeta = class
  private
    FHeights: TArray<THeightMeta>;
    FDir: string;
    procedure GenerateMeta(ParaBlockDb: TBlockDB);
    procedure Load;
  public
    constructor Create(ParaDir: string);
    function Hit(ParaHeight: UInt64): TPair<THeightMeta, THeightMeta>;
  end;

  TBlocks = class
  private
    FBlockDb: TBlockDB;
    FMeta: TBlocksMeta;
    FDir: string;
  public
    constructor Create(ParaDir: string; ParaFilesize: Int64);
    destructor Destroy; override;
    function Location(ParaHeight: UInt64): TLocation;
  end;

implementation

uses
  System.StrUtils;

{ TBlocksMeta }

constructor TBlocksMeta.Create(ParaDir: string);
begin
  inherited Create;
  FDir := ParaDir;
end;

procedure TBlocksMeta.Load;
var
  vJsonFile: TStringStream;
  vByteValue: TBytes;
  vHeights: TArray<THeightMeta>;
begin
  vJsonFile := TStringStream.Create;
  try
    vJsonFile.LoadFromFile(TPath.Combine(FDir, 'meta'));
    vByteValue := TEncoding.UTF8.GetBytes(vJsonFile.DataString);
    vHeights := TJson.JsonToObject<TArray<THeightMeta>>(vByteValue);
    FHeights := vHeights;
  finally
    vJsonFile.Free;
  end;
end;

procedure TBlocksMeta.GenerateMeta(ParaBlockDb: TBlockDB);
var
  vI, vStep: UInt64;
  vHeights: TArray<THeightMeta>;
  vCurrent: TLocation;
  vSBlock: ISnapshotBlock;
  vAccBlocks: TArray<IAccountBlock>;
  vLocation: TLocation;
  vByt: TBytes;
  vLog: ILog;
begin
  vLog := TLog15.New();
  vI := 0;
  vStep := 1000;
  vCurrent := TLocation.Create(1, 0);
  vLog.Info('rebuild the block meta info...');
  while True do
  begin
    Inc(vI);
    if vI mod vStep = 0 then
    begin
      vSBlock := nil;
      vAccBlocks := nil;
      vLocation := Default(TLocation);
      ParaBlockDb.ReadUnit(vCurrent, vSBlock, vAccBlocks, vLocation);
      if (vSBlock = nil) and (vAccBlocks = nil) then
        Break;
      if vSBlock = nil then
      begin
        vCurrent := vLocation;
        Continue;
      end;
      SetLength(vHeights, Length(vHeights) + 1);
      vHeights[High(vHeights)] := THeightMeta.Create(vLocation, vSBlock.Height + 1);
      vLog.Info(Format('rebuild height %d', [vSBlock.Height]));
      vCurrent := vLocation;
    end
    else
    begin
      try
        vLocation := ParaBlockDb.GetNextLocation(vCurrent);
        vCurrent := vLocation;
      except
        on E: Exception do
          Break;
      end;
    end;
  end;
  FHeights := vHeights;
  vByt := TJson.ObjectToJSONBytes(vHeights);
  TFile.WriteAllBytes(TPath.Combine(FDir, 'meta'), vByt);
end;

function TBlocksMeta.Hit(ParaHeight: UInt64): TPair<THeightMeta, THeightMeta>;
var
  vStart, vEnd: THeightMeta;
  vTmp: THeightMeta;
begin
  vStart := THeightMeta.Create(TLocation.Create(1, 0), 1);
  vEnd := Default(THeightMeta);
  for vTmp in FHeights do
  begin
    if vTmp.mHeight < ParaHeight then
      vStart := vTmp;
    if (vTmp.mHeight >= ParaHeight) and (vEnd.mHeight = 0) then
      vEnd := vTmp;
  end;
  Result := TPair<THeightMeta, THeightMeta>.Create(vStart, vEnd);
end;

{ TBlocks }

constructor TBlocks.Create(ParaDir: string; ParaFilesize: Int64);
var
  vLog: ILog;
begin
  inherited Create;
  vLog := TLog15.New();
  FDir := ParaDir;
  FBlockDb := TBlockDB.CreateFixedSize(FDir, ParaFilesize);
  FMeta := TBlocksMeta.Create(ParaDir);
  try
    FMeta.Load;
  except
    on E: Exception do
    begin
      try
        FMeta.GenerateMeta(FBlockDb);
      except
        on E2: Exception do
          vLog.Warn('rebuild the block meta info error', 'err', E2.Message);
      end;
    end;
  end;
end;

destructor TBlocks.Destroy;
begin
  FBlockDb.Free;
  FMeta.Free;
  inherited;
end;

function TBlocks.Location(ParaHeight: UInt64): TLocation;
var
  vStart, vEnd: THeightMeta;
  vCur: TLocation;
  vChunk: ISnapshotChunk;
  vLocation: TLocation;
begin
  vStart := FMeta.Hit(ParaHeight).Key;
  vCur := vStart.mLocation;
  while True do
  begin
    vChunk := nil;
    vLocation := Default(TLocation);
    FBlockDb.ReadChunk(vCur, vChunk, vLocation);
    if vChunk.SnapshotBlock.Height = ParaHeight then
    begin
      Result := vCur;
      Exit;
    end
    else if vChunk.SnapshotBlock.Height > ParaHeight then
      raise Exception.Create('strange error');
    vCur := vLocation;
  end;
end;

end.