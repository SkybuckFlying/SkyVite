unit VM.Contracts.Dex.Leveldb.Book;

interface

uses
  GoVite.Interfaces VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

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
