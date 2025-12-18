unit VM.Contracts.Dex.Leveldb.Book;

interface

uses
  GoVite.Interfaces, VM.Contracts.Dex.Order;

type
  TLevelDbBook = class
  private
    FDb: IVmDb;
    FMarketId: Int32;
    FSide: Boolean;
    FIterator: IStorageIterator;
    function GetBookPrefix: TBytes;
  public
    constructor Create(const ADB: IVmDb; AMarketId: Int32; ASide: Boolean);
    destructor Destroy; override;
    function NextOrder(out AOrder: TOrder): Boolean;
    procedure Release;
  end;

implementation

uses
  System.SysUtils, VM.Contracts.Dex.Utils;

constructor TLevelDbBook.Create(const ADB: IVmDb; AMarketId: Int32; ASide: Boolean);
begin
  inherited Create;
  FDb := ADB;
  FMarketId := AMarketId;
  FSide := ASide;
  FIterator := FDb.NewStorageIterator(GetBookPrefix);
end;

destructor TLevelDbBook.Destroy;
begin
  Release;
  inherited Destroy;
end;

function TLevelDbBook.NextOrder(out AOrder: TOrder): Boolean;
var
  LOrderId, LOrderData: TBytes;
begin
  Result := FIterator.Next;
  if not Result then
  begin
    if FIterator.GetError <> nil then
      raise FIterator.GetError;
    Exit;
  end;

  LOrderId := FIterator.Key;
  LOrderData := FIterator.Value;

  if (Length(LOrderId) <> OrderIdBytesLength) or (Length(LOrderData) = 0) then
    raise Exception.Create(IterateVmDbFailedErr);

  AOrder := TOrder.Create;
  AOrder.DeSerializeCompact(LOrderData, LOrderId);
end;

procedure TLevelDbBook.Release;
begin
  if Assigned(FIterator) then
  begin
    FIterator.Release;
    FIterator := nil;
  end;
end;

function TLevelDbBook.GetBookPrefix: TBytes;
var
  LMarketIdBytes: TBytes;
begin
  LMarketIdBytes := Copy(Uint32ToBytes(FMarketId), 2, 3);
  if FSide then
    Result := Concat(LMarketIdBytes, [1])
  else
    Result := Concat(LMarketIdBytes, [0]);
end;

end.
