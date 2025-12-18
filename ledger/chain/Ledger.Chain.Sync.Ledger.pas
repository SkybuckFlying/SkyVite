unit V2.Ledger.Chain.SyncLedger;

interface

uses
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.Classes,
  System.SysUtils,
  V2.Common.Types,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Ledger.Chain.Chain,
  V2.Ledger.Chain.FileManager,
  V2.Ledger.Chain.SyncCache;

type
  TChainSyncLedgerHelper = class helper for TChain
  public
    function GetLedgerReaderByHeight(AStartHeight, AEndHeight: TUInt64): ILedgerReader;
    function GetSyncCache: ISyncCache;
  end;

  TLedgerReader = class(TInterfacedObject, ILedgerReader)
  private
    FChain: TChain;
    FFrom: TUInt64;
    FTo: TUInt64;
    FChunkPrevHash: THash;
    FChunkHash: THash;
    FFromLocation: ILocation;
    FToLocation: ILocation;
    FCurrentLocation: ILocation;
  public
    constructor Create(AChain: TChain; AFrom, ATo: TUInt64);
    function Seg: ISegment;
    function Size: Integer;
    function Read(P: TBytes): Integer;
    procedure Close;
  end;

implementation

{ TChainSyncLedgerHelper }

function TChainSyncLedgerHelper.GetLedgerReaderByHeight(AStartHeight, AEndHeight: TUInt64): ILedgerReader;
var
  LLatestSnapshotBlock: ISnapshotBlock;
begin
  if AStartHeight < 2 then
    raise Exception.Create(Format('startHeight is %d', [AStartHeight]));
  if AStartHeight > AEndHeight then
    raise Exception.Create(Format('startHeight > endHeight, startHeight is %d, endHeight is %d', [AStartHeight, AEndHeight]));
  LLatestSnapshotBlock := Self.GetLatestSnapshotBlock;
  if AEndHeight > LLatestSnapshotBlock.Height then
    raise Exception.Create(Format('endHeight is too big, endHeight is %d, latest snapshot height is %d', [AEndHeight, LLatestSnapshotBlock.Height]));
  Result := TLedgerReader.Create(Self, AStartHeight, AEndHeight);
end;

function TChainSyncLedgerHelper.GetSyncCache: ISyncCache;
begin
  Result := Self.FSyncCache;
end;

{ TLedgerReader }

constructor TLedgerReader.Create(AChain: TChain; AFrom, ATo: TUInt64);
var
  LTmpFromLocation, LTmpToLocation: ILocation;
  LFromPrevSnapshotBlock, LToSnapshotBlock: ISnapshotBlock;
begin
  FChain := AChain;
  FFrom := AFrom;
  FTo := ATo;

  try
    LTmpFromLocation := FChain.FIndexDB.GetSnapshotBlockLocation(AFrom - 1);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if LTmpFromLocation = nil then
    raise Exception.Create(Format('from location %d is not existed', [AFrom - 1]));

  try
    FFromLocation := FChain.FBlockDB.GetNextLocation(LTmpFromLocation);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if FFromLocation = nil then
    raise Exception.Create(Format('block %d is not existed', [AFrom]));

  try
    LTmpToLocation := FChain.FIndexDB.GetSnapshotBlockLocation(ATo);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if LTmpToLocation = nil then
    raise Exception.Create(Format('block %d is not existed', [ATo]));

  try
    FToLocation := FChain.FBlockDB.GetNextLocation(LTmpToLocation);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if FToLocation = nil then
    raise Exception.Create(Format('next location %s is not existed', [FToLocation.ToString]));

  try
    LFromPrevSnapshotBlock := FChain.GetSnapshotHeaderByHeight(AFrom - 1);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if LFromPrevSnapshotBlock = nil then
    raise Exception.Create(Format('fromPrevSnapshotBlock is nil, from is %d', [AFrom]));

  try
    LToSnapshotBlock := FChain.GetSnapshotHeaderByHeight(ATo);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
  if LToSnapshotBlock = nil then
    raise Exception.Create(Format('toSnapshotBlock is nil, to is %d', [ATo]));

  FChunkPrevHash := LFromPrevSnapshotBlock.Hash;
  FChunkHash := LToSnapshotBlock.Hash;
  FCurrentLocation := FFromLocation;
end;

function TLedgerReader.Seg: ISegment;
begin
  Result := TSegment.Create(FFrom, FTo, FChunkPrevHash, FChunkHash);
end;

function TLedgerReader.Size: Integer;
begin
  Result := FFromLocation.Distance(FChain.FBlockDB.FileSize, FToLocation);
end;

function TLedgerReader.Read(P: TBytes): Integer;
var
  LReadN: Integer;
  LIsEnd: Boolean;
  LN: Integer;
begin
  LReadN := FCurrentLocation.Distance(FChain.FBlockDB.FileSize, FToLocation);
  LIsEnd := False;
  if LReadN <= Length(P) then
    LIsEnd := True
  else
    LReadN := Length(P);

  try
    FCurrentLocation := FChain.FBlockDB.ReadRaw(FCurrentLocation, P, LReadN, LN);
  except
    on E: Exception do
      raise E;
  end;

  if LIsEnd then
    raise EReadError.Create('EOF');

  Result := LN;
end;

procedure TLedgerReader.Close;
begin
  FCurrentLocation := FToLocation;
end;

end.
