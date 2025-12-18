unit Ledger.Chain.Sync.Cache.Sync.Cache;

interface

uses
  Interfaces Common.DB.XLevelDB Log15 Interfaces.Core,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TCacheItem = class; // Forward declaration

  ISyncCache = interface
    ['{C5B6F5A3-9E3B-4B7E-8D2F-2A0B7A54C9A8}']
    function NewReader(const aSegment: ISegment): IChunkReader;
    function NewWriter(const aSegment: ISegment; aSize: Int64): TStream;
    procedure Delete(const aSeg: ISegment);
    function Chunks: ISegmentList;
    procedure Close;
  end;

  TSyncCache = class(TInterfacedObject, ISyncCache)
  private
    FDirName: string;
    FIndexDB: IDB;
    FCaches: TObjectList<TCacheItem>;
    FMu: TCriticalSection;
    FLog: ILogger;

    procedure Open;
    procedure LoadCaches;
    procedure ReadIndex;
    function CheckOverlap(const aSegment: ISegment; out AIndex: Integer): Boolean;
    function FindSeg(const aSeg: ISegment): TCacheItem;
    procedure DeleteItem(const aToDelete: TCacheItem);
    procedure CleanItem(const aItem: TCacheItem);
    procedure CreateNewFile(const aItem: TCacheItem; out AFile: TFileStream);
    function ToCacheFileName(const aSegment: ISegment): string;
    class function ToFilename(const aPrefix: string; const aSegment: ISegment): string;
  public
    constructor Create(const aDirName: string);
    destructor Destroy; override;

    function NewReader(const aSegment: ISegment): IChunkReader;
    function NewWriter(const aSegment: ISegment; aSize: Int64): TStream;
    procedure Delete(const aSeg: ISegment);
    function Chunks: ISegmentList;
    procedure Close;
    procedure UpdateIndex(const aItem: TCacheItem);
  end;

implementation

uses
  System.IOUtils, System.StrUtils, System.Generics.Defaults,
  Ledger.Chain.Sync.Cache.Cache.Item, Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Writer;

const
  FilePrefix = 'f_';
  IndexDBName = 'db';

{ TSyncCache }

constructor TSyncCache.Create(const aDirName: string);
begin
  inherited Create;
  FLog := TLog15.New('module', 'sync_cache');
  FDirName := aDirName;
  FMu := TCriticalSection.Create;
  FCaches := TObjectList<TCacheItem>.Create;
  FCaches.OwnsObjects := True;

  try
    LoadCaches;
  except
    on E: Exception do
    begin
      Free;
      raise Exception.CreateFmt('Failed to load caches: %s', [E.Message]);
    end;
  end;
end;

destructor TSyncCache.Destroy;
begin
  Close;
  FMu.Free;
  FCaches.Free;
  inherited;
end;

procedure TSyncCache.Close;
begin
  if Assigned(FIndexDB) then
  begin
    FIndexDB.Close;
    FIndexDB := nil;
  end;
end;

procedure TSyncCache.Open;
begin
  if not TDirectory.Exists(FDirName) then
  begin
    try
      TDirectory.CreateDirectory(FDirName);
    except
      on E: Exception do
        raise Exception.CreateFmt('Failed to create cache dir %s: %s', [FDirName, E.Message]);
    end;
  end
  else
  begin
    // Additional logic from Go source to handle non-dir paths can be added if necessary
  end;
end;

procedure TSyncCache.LoadCaches;
var
  vKeepFiles: TDictionary<string, Boolean>;
  I: Integer;
  vItem: TCacheItem;
  vFiles: TArray<string>;
  vFile: string;
begin
  Open;
  ReadIndex;

  vKeepFiles := TDictionary<string, Boolean>.Create;
  defer vKeepFiles.Free;

  // Iterate backwards to safely remove items
  for I := FCaches.Count - 1 downto 0 do
  begin
    vItem := FCaches[I];
    if (not TFile.Exists(vItem.filename)) or (not vItem.done) then
    begin
      FLog.Warn(Format('Failed to read cache file %s info.', [vItem.filename]));
      CleanItem(vItem); // CleanItem also handles DB deletion
      FCaches.Delete(I); // This frees the item due to TObjectList ownership
    end
    else
    begin
      vKeepFiles.AddOrSetValue(vItem.filename, True);
    end;
  end;

  // Remove useless files
  vFiles := TDirectory.GetFiles(FDirName);
  for vFile in vFiles do
  begin
    if not vKeepFiles.ContainsKey(TPath.GetFileName(vFile)) then
    begin
      TFile.Delete(vFile);
    end;
  end;
end;

procedure TSyncCache.ReadIndex;
var
  vIndexPath: string;
  vIterator: IIterator;
  vItem: TCacheItem;
begin
  vIndexPath := TPath.Combine(FDirName, IndexDBName);
  if (not TDirectory.Exists(vIndexPath)) then
  begin
    TDirectory.Delete(FDirName, True);
    Open;
  end;

  FIndexDB := TLevelDB.OpenFile(vIndexPath);

  vIterator := FIndexDB.NewIterator(TBytes.Create($01)); // Assuming dbItemPrefix is 1
  defer vIterator.Release;

  while vIterator.Next do
  begin
    vItem := TCacheItem.Create;
    try
      vItem.DeSerialize(vIterator.Value);
      FCaches.Add(vItem);
    except
      FIndexDB.Delete(vIterator.Key);
      vItem.Free;
    end;
  end;

  FCaches.Sort(TComparer<TCacheItem>.Default);
end;

procedure TSyncCache.UpdateIndex(const aItem: TCacheItem);
var
  vData: TBytes;
begin
  try
    vData := aItem.Serialize;
    FIndexDB.Put(aItem.DBKey, vData);
  except
    on E: Exception do
      FLog.Warn(Format('Failed to serialize or store item: %s', [E.Message]));
  end;
end;

function TSyncCache.NewReader(const aSegment: ISegment): IChunkReader;
var
  vItem: TCacheItem;
begin
  vItem := FindSeg(aSegment);
  if Assigned(vItem) then
    Result := TReader.Create(Self, vItem) // TReader needs to be IChunkReader
  else
    raise Exception.CreateFmt('Failed to find cache: %d-%d %s-%s', [aSegment.From, aSegment.To, aSegment.PrevHash.ToString, aSegment.Hash.ToString]);
end;

function TSyncCache.NewWriter(const aSegment: ISegment; aSize: Int64): TStream;
var
  vIndex: Integer;
  vOverlapped: Boolean;
  vItem: TCacheItem;
  vFile: TFileStream;
begin
  FMu.Enter;
  try
    vOverlapped := CheckOverlap(aSegment, vIndex);
    if vOverlapped then
      raise Exception.CreateFmt('Failed to cache %d-%d: overlapped', [aSegment.From, aSegment.To]);

    vItem := TCacheItem.Create;
    vItem.Segment := aSegment;
    vItem.done := False;
    vItem.verified := False;
    vItem.size := aSize;

    FCaches.Insert(vIndex, vItem);
  finally
    FMu.Leave;
  end;

  try
    CreateNewFile(vItem, vFile);
    vItem.filename := vFile.FileName;
    Result := TWriter.Create(Self, vItem, vFile);
  except
    on E: Exception do
    begin
      DeleteItem(vItem);
      raise;
    end;
  end;
end;

function TSyncCache.CheckOverlap(const aSegment: ISegment; out AIndex: Integer): Boolean;
var
  L, H, I: Integer;
begin
  // Simplified search, Go uses sort.Search which is a binary search.
  // This linear search is simpler but less efficient for large lists.
  // For a direct equivalent, a binary search would be implemented here.
  for I := 0 to FCaches.Count - 1 do
  begin
    if (aSegment.From <= FCaches[I].To) and (aSegment.To >= FCaches[I].From) then
    begin
      Result := True;
      AIndex := -1;
      Exit;
    end;
    if aSegment.To < FCaches[I].From then
    begin
      Result := False;
      AIndex := I;
      Exit;
    end;
  end;
  Result := False;
  AIndex := FCaches.Count;
end;

procedure TSyncCache.Delete(const aSeg: ISegment);
var
  vItem: TCacheItem;
begin
  vItem := FindSeg(aSeg);
  if Assigned(vItem) then
    DeleteItem(vItem)
  else
    raise Exception.CreateFmt('Failed to find segment: %d-%d %s-%s', [aSeg.From, aSeg.To, aSeg.PrevHash.ToString, aSeg.Hash.ToString]);
end;

function TSyncCache.FindSeg(const aSeg: ISegment): TCacheItem;
var
  vItem: TCacheItem;
begin
  Result := nil;
  FMu.Enter;
  try
    for vItem in FCaches do
    begin
      if vItem.Equal(aSeg) then
      begin
        Result := vItem;
        Exit;
      end;
    end;
  finally
    FMu.Leave;
  end;
end;

procedure TSyncCache.DeleteItem(const aToDelete: TCacheItem);
var
  vIndex: Integer;
begin
  FMu.Enter;
  try
    vIndex := FCaches.IndexOf(aToDelete);
    if vIndex > -1 then
    begin
      CleanItem(aToDelete);
      FCaches.Delete(vIndex);
    end;
  finally
    FMu.Leave;
  end;
end;

procedure TSyncCache.CleanItem(const aItem: TCacheItem);
begin
  try
    FIndexDB.Delete(aItem.DBKey);
  except
    on E: Exception do
      FLog.Warn(Format('Failed to delete item %d-%d from db: %s', [aItem.From, aItem.To, E.Message]));
  end;

  if (aItem.filename <> '') and TFile.Exists(aItem.filename) then
  begin
    try
      TFile.Delete(aItem.filename);
    except
      on E: Exception do
        FLog.Warn(Format('Failed to delete item file %s: %s', [aItem.filename, E.Message]));
    end;
  end;
end;

function TSyncCache.Chunks: ISegmentList;
var
  i: Integer;
begin
  FMu.Enter;
  try
    SetLength(Result, 0);
    for i := 0 to FCaches.Count - 1 do
    begin
      if FCaches[i].done then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[high(Result)] := FCaches[i].Segment;
      end;
    end;
  finally
    FMu.Leave;
  end;
end;

procedure TSyncCache.CreateNewFile(const aItem: TCacheItem; out AFile: TFileStream);
var
  vFilename: string;
begin
  vFilename := ToCacheFileName(aItem.Segment);
  try
    AFile := TFileStream.Create(vFilename, fmCreate);
  except
    on E: Exception do
      raise Exception.CreateFmt('Failed to create cache file %s: %s', [vFilename, E.Message]);
  end;
end;

function TSyncCache.ToCacheFileName(const aSegment: ISegment): string;
begin
  Result := TPath.Combine(FDirName, ToFilename(FilePrefix, aSegment));
end;

class function TSyncCache.ToFilename(const aPrefix: string; const aSegment: ISegment): string;
begin
  Result := aPrefix +
    aSegment.From.ToString + '_' +
    aSegment.To.ToString + '_' +
    DateTimeToUnix(Now).ToString;
end;

end.
