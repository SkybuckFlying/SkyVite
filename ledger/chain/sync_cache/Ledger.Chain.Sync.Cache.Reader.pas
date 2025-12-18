unit Ledger.Chain.Sync.Cache.Reader;

interface

uses
  Interfaces.Core,
  Ledger.Chain.Block,
  Ledger.Chain.Sync.Cache,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  System.Classes,
  System.IOUtils,
  System.SysUtils;

type
  TReader = class
  private
    mCache: TSyncCache;
    mFile: TFileStream;
    mReadBuffer: TBytes;
    mDecodeBuffer: TBytes;
    mItem: TCacheItem;
    function GetVerified: Boolean;
    procedure SetVerified(const Value: Boolean);
  public
    constructor Create(const aCache: TSyncCache; const aItem: TCacheItem);
    destructor Destroy; override;
    function Read(out aAb: IAccountBlock; out aSb: ISnapshotBlock): Boolean;
    procedure Close;
    property Size: Int64 read GetSize;
    property Verified: Boolean read GetVerified write SetVerified;
  end;

implementation

uses
  Snappy,
  System.Net.Sockets;

constructor TReader.Create(const aCache: TSyncCache; const aItem: TCacheItem);
begin
  if not aItem.done then
    raise Exception.CreateFmt('Failed to open cache %d-%d %s-%s: not write done', [aItem.From, aItem.To, aItem.PrevHash, aItem.Hash]);

  mFile := TFileStream.Create(aItem.filename, fmOpenReadWrite);
  mCache := aCache;
  mItem := aItem;
  SetLength(mReadBuffer, 8 * 1024);
end;

destructor TReader.Destroy;
begin
  mFile.Free;
  inherited;
end;

function TReader.GetVerified: Boolean;
begin
  Result := mItem.verified;
end;

procedure TReader.SetVerified(const Value: Boolean);
begin
  if Verified then
    Exit;

  mItem.verified := True;
  mCache.UpdateIndex(mItem);
end;

function TReader.Size: Int64;
begin
  Result := mItem.size;
end;

function TReader.Read(out aAb: IAccountBlock; out aSb: ISnapshotBlock): Boolean;
var
  vSize: Cardinal;
  vCode: Byte;
  vDecodeLen: Integer;
  vSBuf: TBytes;
  vBuf: TBytes;
  vBytesRead: Integer;
begin
  aAb := nil;
  aSb := nil;

  SetLength(vBuf, 4);
  vBytesRead := mFile.Read(vBuf, 4);
  if vBytesRead <> 4 then
  begin
    Result := False;
    Exit;
  end;

  vSize := ntohl(PInteger(@vBuf[0])^);

  if vSize = 0 then
    raise Exception.Create('0 size');

  if Length(mReadBuffer) < Integer(vSize) then
    SetLength(mReadBuffer, vSize);

  vBytesRead := mFile.Read(mReadBuffer, vSize);
  if vBytesRead <> Integer(vSize) then
    raise Exception.Create('error size length');

  vCode := mReadBuffer[0];

  vDecodeLen := TSnappy.GetDecodedLen(mReadBuffer, 1, vSize - 1);
  if Length(mDecodeBuffer) < vDecodeLen then
    SetLength(mDecodeBuffer, vDecodeLen);

  vSBuf := TSnappy.Decode(mReadBuffer, 1, vSize - 1);

  case vCode of
    TBlockType.BlockTypeAccountBlock:
      begin
        aAb := TAccountBlock.Create;
        aAb.Deserialize(vSBuf);
      end;
    TBlockType.BlockTypeSnapshotBlock:
      begin
        aSb := TSnapshotBlock.Create;
        aSb.Deserialize(vSBuf);
      end;
  else
    Result := False;
    Exit;
  end;

  Result := True;
end;

procedure TReader.Close;
begin
  mFile.Free;
end;

end.
