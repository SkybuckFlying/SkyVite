unit Net.Broadcaster.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  Common.Types,
  Interfaces.Core,
  Net.Broadcaster,
  Tools.Circle,
  Net.VNode;

type
  [TestFixture]
  TBroadcasterTest = class(TObject)
  public
    [Test]
    procedure TestBroadcaster_Statistic;
    [Test]
    procedure TestMemStore_EnqueueAccountBlock;
    [Test]
    procedure TestMemStore_EnqueueSnapshotBlock;
    [Test]
    procedure TestCommonPeers;
    [Test]
    procedure TestRing_Get;
  end;

implementation

uses
  System.Math,
  Net.Peer,
  Net.PeerSet;

const
  records1h = 3600;
  records12h = 12 * records1h;
  records24h = 24 * records1h;

type
  TMockAccountBlock = class(TInterfacedObject, IAccountBlock)
  private
    FHeight: UInt64;
    function GetHeight: UInt64;
    function GetHash: THash;
    function GetAccountAddress: TAddress;
  public
    constructor Create(Height: UInt64);
    property Height: UInt64 read GetHeight;
    property Hash: THash read GetHash;
    property AccountAddress: TAddress read GetAccountAddress;
  end;

  TMockSnapshotBlock = class(TInterfacedObject, ISnapshotBlock)
  private
    FHeight: UInt64;
    function GetHeight: UInt64;
    function GetHash: THash;
  public
    constructor Create(Height: UInt64);
    property Height: UInt64 read GetHeight;
    property Hash: THash read GetHash;
  end;

{ TMockAccountBlock }

constructor TMockAccountBlock.Create(Height: UInt64);
begin
  FHeight := Height;
end;

function TMockAccountBlock.GetHeight: UInt64;
begin
  Result := FHeight;
end;

function TMockAccountBlock.GetHash: THash;
begin
  Result := THash.Empty;
end;

function TMockAccountBlock.GetAccountAddress: TAddress;
begin
  Result := TAddress.Empty;
end;

{ TMockSnapshotBlock }

constructor TMockSnapshotBlock.Create(Height: UInt64);
begin
  FHeight := Height;
end;

function TMockSnapshotBlock.GetHeight: UInt64;
begin
  Result := FHeight;
end;

function TMockSnapshotBlock.GetHash: THash;
begin
  Result := THash.Empty;
end;

{ TBroadcasterTest }

procedure TBroadcasterTest.TestBroadcaster_Statistic;
var
  Broadcaster: TBroadcaster;
  Ret: TArray<Int64>;
  I: Integer;
  T0: Int64;
  T1: Double;
  Total: Integer;
  T12, T24: Double;
begin
  Broadcaster := TBroadcaster.Create(nil, nil, nil, nil, nil, nil);
  try
    Ret := Broadcaster.Statistic;
    for var V in Ret do
      Assert.AreEqual(0, V);

    // Put one element
    Broadcaster.FStatistic.Put(10);
    Ret := Broadcaster.Statistic;
    Assert.AreEqual(10, Ret[0]);

    // Put 3610 elements
    Broadcaster.FStatistic.Reset;
    T0 := 0;
    T1 := 0;
    Total := records1h + 10;
    for I := 0 to Total - 1 do
      Broadcaster.FStatistic.Put(I);
    Ret := Broadcaster.Statistic;
    for I := Total - records1h to Total - 1 do
      T1 := T1 + (I / records1h);
    T0 := Total - 1;
    Assert.AreEqual(T0, Ret[0]);
    Assert.AreEqual(Trunc(T1), Ret[1]);

    // Put 43210 elements
    Broadcaster.FStatistic.Reset;
    T0 := 0;
    T1 := 0;
    T12 := 0;
    Total := records12h + 10;
    for I := 0 to Total - 1 do
      Broadcaster.FStatistic.Put(I);
    Ret := Broadcaster.Statistic;
    for I := Total - records1h to Total - 1 do
      T1 := T1 + (I / records1h);
    for I := Total - records12h to Total - 1 do
      T12 := T12 + (I / records12h);
    T0 := Total - 1;
    Assert.AreEqual(T0, Ret[0]);
    Assert.AreEqual(Trunc(T1), Ret[1]);
    Assert.AreEqual(Trunc(T12), Ret[2]);

    // Put 86410 elements
    Broadcaster.FStatistic.Reset;
    T0 := 0;
    T1 := 0;
    T12 := 0;
    T24 := 0;
    Total := records24h + 10;
    for I := 0 to Total - 1 do
      Broadcaster.FStatistic.Put(I);
    Ret := Broadcaster.Statistic;
    for I := Total - records1h to Total - 1 do
      T1 := T1 + (I / records1h);
    for I := Total - records12h to Total - 1 do
      T12 := T12 + (I / records12h);
    for I := Total - records24h to Total - 1 do
      T24 := T24 + (I / records24h);
    T0 := Total - 1;
    Assert.AreEqual(T0, Ret[0]);
    Assert.AreEqual(Trunc(T1), Ret[1]);
    Assert.AreEqual(Trunc(T12), Ret[2]);
    Assert.AreEqual(Trunc(T24), Ret[3]);

  finally
    Broadcaster.Free;
  end;
end;

procedure TBroadcasterTest.TestMemStore_EnqueueAccountBlock;
var
  Store: IBlockStore;
  I: TUInt64;
  Block: IAccountBlock;
begin
  Store := NewMemBlockStore(1000);
  for I := 0 to 1099 do
    Store.EnqueueAccountBlock(TMockAccountBlock.Create(I));

  for I := 0 to 999 do
  begin
    Block := Store.DequeueAccountBlock;
    Assert.AreEqual(I, Block.Height);
  end;

  for I := 0 to 99 do
  begin
    Block := Store.DequeueAccountBlock;
    Assert.IsNull(Block);
  end;
end;

procedure TBroadcasterTest.TestMemStore_EnqueueSnapshotBlock;
var
  Store: IBlockStore;
  I: TUInt64;
  Block: ISnapshotBlock;
begin
  Store := NewMemBlockStore(1000);
  for I := 0 to 1099 do
    Store.EnqueueSnapshotBlock(TMockSnapshotBlock.Create(I));

  for I := 0 to 999 do
  begin
    Block := Store.DequeueSnapshotBlock;
    Assert.AreEqual(I, Block.Height);
  end;

  for I := 0 to 99 do
  begin
    Block := Store.DequeueSnapshotBlock;
    Assert.IsNull(Block);
  end;
end;

procedure TBroadcasterTest.TestCommonPeers;
const
  OurCount = 100;
  CommonCount = 10;
var
  OurPeers: TArray<IPeer>;
  PPMap: TDictionary<TPeerId, Boolean>;
  Sender: IPeer;
  I: Integer;
  PS: TArray<IPeer>;
  Strategy: IForwardStrategy;
  PeerSet: IPeerSet;
begin
  PeerSet := TPeerSet.Create;
  SetLength(OurPeers, OurCount);
  for I := 0 to OurCount - 1 do
  begin
    OurPeers[I] := TPeer.Create(nil, nil);
    OurPeers[I].Id := TPeerId.Random;
    PeerSet.Add(OurPeers[I]);
  end;

  Sender := OurPeers[0];

  // ppMap is nil
  Strategy := TCrossForwardStrategy.Create(PeerSet, 5, 100);
  PS := Strategy.ChoosePeers(Sender);
  Assert.AreEqual(OurCount - 1, Length(PS));

  // ppMap is not nil
  PPMap := TDictionary<TPeerId, Boolean>.Create;
  for I := 0 to CommonCount - 1 do
    PPMap.Add(OurPeers[50 + I].Id, True);
  Sender.SetPeers(PPMap);

  Strategy := TCrossForwardStrategy.Create(PeerSet, 5, 100);
  PS := Strategy.ChoosePeers(Sender);
  Assert.AreEqual(OurCount - 1, Length(PS));

  Strategy := TCrossForwardStrategy.Create(PeerSet, 5, 30);
  PS := Strategy.ChoosePeers(Sender);
  Assert.AreEqual(OurCount - CommonCount + (CommonCount * 30 div 100) - 1, Length(PS));

  Strategy := TCrossForwardStrategy.Create(PeerSet, 5, 0);
  PS := Strategy.ChoosePeers(Sender);
  Assert.AreEqual(OurCount - CommonCount, Length(PS));
end;

procedure TBroadcasterTest.TestRing_Get;
var
  Ring: TRingStatic;
  Tasks: TArray<ITask>;
  I: Integer;
  Locker: TCriticalSection;
begin
  Ring := TRingStatic.Create(8, 2);
  Locker := TCriticalSection.Create;
  try
    SetLength(Tasks, 100);
    for I := 0 to High(Tasks) do
    begin
      Tasks[I] := TTask.Run(procedure
      var
        Item: TPickItem;
      begin
        Locker.Acquire;
        try
          Item := Ring.Get;
          Item.Inc;
          Item.Pick;
          if Random > 0.5 then
            Item.Fail;
        finally
          Locker.Release;
        end;
      end);
    end;
    TTask.WaitForAll(Tasks);
    WriteLn(Format('Final failed ratio: %f', [Ring.FailedRatio]));
  finally
    Ring.Free;
    Locker.Free;
  end;
end;

initialization
  RegisterTestFixture(TBroadcasterTest);
end.