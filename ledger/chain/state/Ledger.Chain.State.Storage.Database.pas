unit Ledger.Chain.State.StorageDatabase;

interface

uses
  System.SysUtils,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.State.StateDB;

type
  IStateDB; // Forward declaration

  IStorageDatabase = interface
    ['{B5B0E6A2-6C6C-4A5A-9B8E-3A9E2B6C8B6E}']
    function GetValue(ParaKey: TBytes): TBytes;
    function NewStorageIterator(ParaPrefix: TBytes): IStorageIterator;
    function GetAddress: TAddress;
    property Address: TAddress read GetAddress;
  end;

  TStateDBStorageDatabaseHelper = class helper for TStateDB
  public
    function NewStorageDatabase(ParaSnapshotHash: THash; ParaAddr: TAddress): IStorageDatabase;
  end;

  TStorageDatabase = class(TInterfacedObject, IStorageDatabase)
  private
    mStateDb: IStateDB;
    mSnapshotHash: THash;
    mSnapshotHeight: TUInt64;
    mAddr: TAddress;
    function GetAddress: TAddress;
  public
    constructor Create(ParaStateDb: IStateDB; ParaHashHeight: THashHeight; ParaAddr: TAddress);
    function GetValue(ParaKey: TBytes): TBytes;
    function NewStorageIterator(ParaPrefix: TBytes): IStorageIterator;
  end;

implementation

uses
  Ledger.Chain.State.RoundCache;

{ TStateDBStorageDatabaseHelper }

function TStateDBStorageDatabaseHelper.NewStorageDatabase(ParaSnapshotHash: THash; ParaAddr: TAddress): IStorageDatabase;
var
  vSnapshotHeight: TUInt64;
begin
  try
    vSnapshotHeight := Self.Chain.GetSnapshotHeightByHash(ParaSnapshotHash);
    if vSnapshotHeight <= 0 then
    begin
      raise Exception.CreateFmt('snapshot hash %s is not existed', [ParaSnapshotHash.ToString]);
    end;
    Result := TStorageDatabase.Create(Self, THashHeight.Create(vSnapshotHeight, ParaSnapshotHash), ParaAddr);
  except
    on E: Exception do
      raise Exception.CreateFmt('Error in NewStorageDatabase: %s', [E.Message]);
  end;
end;

{ TStorageDatabase }

constructor TStorageDatabase.Create(ParaStateDb: IStateDB; ParaHashHeight: THashHeight; ParaAddr: TAddress);
begin
  inherited Create;
  mStateDb := ParaStateDb;
  mSnapshotHeight := ParaHashHeight.Height;
  mSnapshotHash := ParaHashHeight.Hash;
  mAddr := ParaAddr;
end;

function TStorageDatabase.GetValue(ParaKey: TBytes): TBytes;
begin
  Result := mStateDb.GetSnapshotValue(mSnapshotHeight, mAddr, ParaKey);
end;

function TStorageDatabase.NewStorageIterator(ParaPrefix: TBytes): IStorageIterator;
var
  vIter: IStorageIterator;
begin
  // if use cache
  if (mStateDb.ConsensusCacheLevel = ConsensusReadCache) and (mAddr = TAddressGovernance) then
  begin
    vIter := mStateDb.RoundCache.StorageIterator(mSnapshotHash);
    if vIter <> nil then
    begin
      Exit(vIter);
    end;
  end;
  try
    Result := mStateDb.NewSnapshotStorageIteratorByHeight(mSnapshotHeight, mAddr, ParaPrefix);
  except
    on E: Exception do
      raise Exception.CreateFmt('c.stateDB.NewSnapshotStorageIterator failed, snapshotHeight is %d, addr is %s, prefix is %s. Error: %s',
        [mSnapshotHeight, mAddr.ToString, string(ParaPrefix), E.Message]);
  end;
end;

function TStorageDatabase.GetAddress: TAddress;
begin
  Result := mAddr;
end;

end.
