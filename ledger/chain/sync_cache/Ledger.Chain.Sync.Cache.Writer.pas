unit Ledger.Chain.Sync.Cache.Writer;

interface

uses
  System.SysUtils,
  System.Classes,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Cache.Item;

type
  TWriter = class(TStream)
  private
    FCache: TSyncCache;
    FItem: TCacheItem;
    FFD: TFileStream;
  public
    constructor Create(const aCache: TSyncCache; const aItem: TCacheItem; aFD: TFileStream);
    destructor Destroy; override;
    function Write(const aBuffer: TBytes; aOffset, aCount: Longint): Longint; override;
    function Read(var aBuffer: TBytes; aOffset, aCount: Longint): Longint; override;
    function Seek(aOffset: Longint; aOrigin: TSeekOrigin): Longint; override;
    procedure Close;
  end;

implementation

{ TWriter }

constructor TWriter.Create(const aCache: TSyncCache; const aItem: TCacheItem; aFD: TFileStream);
begin
  FCache := aCache;
  FItem := aItem;
  FFD := aFD;
end;

destructor TWriter.Destroy;
begin
  Close;
  inherited;
end;

function TWriter.Write(const aBuffer: TBytes; aOffset, aCount: Longint): Longint;
var
  vBytesToWrite: TBytes;
begin
  SetLength(vBytesToWrite, aCount);
  System.Move(aBuffer[aOffset], vBytesToWrite[0], aCount);
  Result := FFD.Write(vBytesToWrite, aCount);
end;

function TWriter.Read(var aBuffer: TBytes; aOffset, aCount: Longint): Longint;
begin
  // TWriter is write-only stream wrapper. Read is not supported.
  raise ENotSupportedException.Create('Read not supported in TWriter');
end;

function TWriter.Seek(aOffset: Longint; aOrigin: TSeekOrigin): Longint;
begin
  Result := FFD.Seek(aOffset, aOrigin);
end;

procedure TWriter.Close;
begin
  if FFD = nil then Exit;

  try
    FFD.Free;
    FFD := nil;

    FItem.done := True;
    FCache.UpdateIndex(FItem);
  except
    on E: Exception do
    begin
      // If closing file fails, we should clean up.
      // The Go code calls deleteItem, which also removes the file.
      FCache.Delete(FItem.Segment);
      raise;
    end;
  end;
end;

end.
