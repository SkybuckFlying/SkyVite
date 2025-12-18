unit Ledger.Chain.State.RoundCache.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Interfaces.Core,
  Ledger.Chain.State,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  Ledger.Consensus.Core,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  [TestFixture]
  TRoundCacheTest = class(TObject)
  public
    [Test]
    procedure TestRoundCache;
  end;

implementation

uses
  System.Math,
  System.DateUtils,
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.MemDB,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.Util,
  Ledger.Chain.Utils;

type
  TMockSnapshot = class
  public
    SnapshotHeader: ISnapshotBlock;
    Data: TMemDB;
    Log: TSnapshotLog;
  end;

  TMockData = class
  public
    AddrList: TArray<TAddress>;
    Snapshots: TArray<TMockSnapshot>;
    procedure Add(appendAddrList: TArray<TAddress>; snapshotCount: Integer);
    procedure Delete(snapshotCount: Integer);
  end;

  TMockChain = class(TInterfacedObject, IChain)
    // Implement IChain methods for testing
  end;

  TMockStateDB = class(TInterfacedObject, IStateDB)
    // Implement IStateDB methods for testing
  end;

{ TMockData }

procedure TMockData.Add(appendAddrList: TArray<TAddress>; snapshotCount: Integer);
var
  startH: TUInt64;
  snapshotData: TMemDB;
  lastSnapshot: TMockSnapshot;
  h: TUInt64;
  currentTime: TDateTime;
  newSnapshotData: TMemDB;
  log: TSnapshotLog;
  snapshotHeader: ISnapshotBlock;
  newMockSnapshot: TMockSnapshot;
begin
  Self.AddrList := Concat(Self.AddrList, appendAddrList);

  startH := 1;
  snapshotData := TMemDB.Create(TComparerDefault.Create, 0);

  if Length(Self.Snapshots) > 0 then
  begin
    lastSnapshot := Self.Snapshots[High(Self.Snapshots)];
    startH := lastSnapshot.SnapshotHeader.Height + 1;
    snapshotData := lastSnapshot.Data;
  end;

  for h := startH to TUInt64(snapshotCount) + startH - 1 do
  begin
    currentTime := IncSecond(GenesisTime, h - 1);

    // snapshot log
    newSnapshotData := snapshotData.Copy;
    log := MockSnapshotState(newSnapshotData, appendAddrList, Random(5) + 1, Random(5) + 1);

    snapshotHeader := TSnapshotBlock.Create;
    snapshotHeader.Height := h;
    snapshotHeader.Timestamp := currentTime;
    snapshotHeader.Hash := snapshotHeader.ComputeHash;

    newMockSnapshot := TMockSnapshot.Create;
    newMockSnapshot.SnapshotHeader := snapshotHeader;
    newMockSnapshot.Data := newSnapshotData;
    newMockSnapshot.Log := log;

    Self.Snapshots := Concat(Self.Snapshots, [newMockSnapshot]);
    snapshotData := newSnapshotData;
  end;
end;

procedure TMockData.Delete(snapshotCount: Integer);
var
  lowIndex: Integer;
begin
  lowIndex := 1;
  if Length(Self.Snapshots) > snapshotCount then
    lowIndex := Length(Self.Snapshots) - snapshotCount;

  System.Delete(Self.Snapshots, 0, lowIndex);
end;

{ TRoundCacheTest }

procedure TRoundCacheTest.TestRoundCache;
begin
  Assert.Ignore('Test not implemented');
end;

initialization
  RegisterTest(TRoundCacheTest.Suite);
end.
