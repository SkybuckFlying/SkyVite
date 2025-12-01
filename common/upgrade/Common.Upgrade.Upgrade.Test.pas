unit Common.Upgrade.Test;

interface

uses
  DUnitX.TestFramework,
  Common.Upgrade,
  Common.Upgrade.Face,
  System.SysUtils,
  System.Generics.Collections;

type
  [TestFixture]
  TTestUpgrade = class
  private
    procedure TestUpgradePoint(const AIsUpgrade: TFunc<UInt64, Boolean>; const ASHeight: UInt64);
    procedure TestEmptyUpgradePoint(const AIsUpgrade: TFunc<UInt64, Boolean>; const ASHeight: UInt64);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMainnetUpgradeBox;
    [Test]
    procedure TestLatestUpgradeBox;
    [Test]
    procedure TestCustomUpgradeBox;
    [Test]
    procedure TestEmptyUpgradeBox;
    [Test]
    procedure TestUpgrade;
  end;

implementation

uses
  Common.Json;

procedure TTestUpgrade.TestUpgradePoint(const AIsUpgrade: TFunc<UInt64, Boolean>; const ASHeight: UInt64);
begin
  Assert.IsFalse(AIsUpgrade(ASHeight - 1), 'Height: ' + ASHeight.ToString);
  Assert.IsTrue(AIsUpgrade(ASHeight), 'Height: ' + ASHeight.ToString);
  Assert.IsTrue(AIsUpgrade(ASHeight + 1), 'Height: ' + ASHeight.ToString);
end;

procedure TTestUpgrade.TestEmptyUpgradePoint(const AIsUpgrade: TFunc<UInt64, Boolean>; const ASHeight: UInt64);
begin
  Assert.IsFalse(AIsUpgrade(ASHeight - 1), 'Height: ' + ASHeight.ToString);
  Assert.IsFalse(AIsUpgrade(ASHeight), 'Height: ' + ASHeight.ToString);
  Assert.IsFalse(AIsUpgrade(ASHeight + 1), 'Height: ' + ASHeight.ToString);
end;

procedure TTestUpgrade.Setup;
begin
  CleanupUpgradeBox;
end;

procedure TTestUpgrade.TearDown;
begin
  CleanupUpgradeBox;
end;

procedure TTestUpgrade.TestMainnetUpgradeBox;
type
  TUPoint = record
    Func: TFunc<UInt64, Boolean>;
    SHeight: UInt64;
  end;
var
  vCases: TArray<TUPoint>;
  vEle: TUPoint;
begin
  InitUpgradeBox(NewMainnetUpgradeBox);

  vCases := [
    (Func: IsSeedUpgrade; SHeight: 3488471),
    (Func: IsDexUpgrade; SHeight: 5442723),
    (Func: IsDexFeeUpgrade; SHeight: 8013367),
    (Func: IsStemUpgrade; SHeight: 8403110),
    (Func: IsLeafUpgrade; SHeight: 9413600),
    (Func: IsEarthUpgrade; SHeight: 16634530),
    (Func: IsDexMiningUpgrade; SHeight: 17142720),
    (Func: IsDexRobotUpgrade; SHeight: 31305900),
    (Func: IsDexStableMarketUpgrade; SHeight: 39694000),
    (Func: IsVersion10Upgrade; SHeight: 77106666),
    (Func: IsVersion11Upgrade; SHeight: 101320000),
    (Func: IsVersion12Upgrade; SHeight: 116480000),
    (Func: IsVersion13Upgrade; SHeight: 166869900),
    (Func: IsVersionXUpgrade; SHeight: ConstEndlessHeight)
  ];

  for vEle in vCases do
  begin
    TestUpgradePoint(vEle.Func, vEle.SHeight);
  end;
  Assert.AreEqual<Cardinal>(13, GetLatestPoint.Version);
end;

procedure TTestUpgrade.TestLatestUpgradeBox;
type
  TUPoint = record
    Func: TFunc<UInt64, Boolean>;
    SHeight: UInt64;
  end;
var
  vCases: TArray<TUPoint>;
  vEle: TUPoint;
begin
  InitUpgradeBox(NewLatestUpgradeBox);

  vCases := [
    (Func: IsSeedUpgrade; SHeight: 1),
    (Func: IsDexUpgrade; SHeight: 1),
    (Func: IsDexFeeUpgrade; SHeight: 1),
    (Func: IsStemUpgrade; SHeight: 1),
    (Func: IsLeafUpgrade; SHeight: 1),
    (Func: IsEarthUpgrade; SHeight: 1),
    (Func: IsDexMiningUpgrade; SHeight: 1),
    (Func: IsDexRobotUpgrade; SHeight: 1),
    (Func: IsDexStableMarketUpgrade; SHeight: 1),
    (Func: IsVersion10Upgrade; SHeight: 1),
    (Func: IsVersion11Upgrade; SHeight: 1),
    (Func: IsVersion12Upgrade; SHeight: 1),
    (Func: IsVersion13Upgrade; SHeight: 1),
    (Func: IsVersionXUpgrade; SHeight: 1)
  ];

  for vEle in vCases do
  begin
    TestUpgradePoint(vEle.Func, vEle.SHeight);
  end;
end;

procedure TTestUpgrade.TestCustomUpgradeBox;
type
  TUPoint = record
    Func: TFunc<UInt64, Boolean>;
    SHeight: UInt64;
  end;
var
  vRaw: string;
  vM: TDictionary<string, TUpgradePoint>;
  vCases: TArray<TUPoint>;
  vEle: TUPoint;
begin
  vRaw := '{' +
    '"SeedFork":{"Height":1,"Version":1},' +
    '"DexFork":{"Height":2,"Version":2},' +
    '"DexFeeFork":{"Height":3,"Version":3},' +
    '"StemFork":{"Height":4,"Version":4},' +
    '"LeafFork":{"Height":5,"Version":5},' +
    '"EarthFork":{"Height":6,"Version":6},' +
    '"DexMiningFork":{"Height":7,"Version":7},' +
    '"DexRobotFork":{"Height":8,"Version":8},' +
    '"DexStableMarketFork":{"Height":9,"Version":9}' +
  '}';

  vM := TJson.JsonToDictionary<string, TUpgradePoint>(vRaw);

  InitUpgradeBox(NewCustomUpgradeBox(vM));

  vCases := [
    (Func: IsSeedUpgrade; SHeight: 1),
    (Func: IsDexUpgrade; SHeight: 2),
    (Func: IsDexFeeUpgrade; SHeight: 3),
    (Func: IsStemUpgrade; SHeight: 4),
    (Func: IsLeafUpgrade; SHeight: 5),
    (Func: IsEarthUpgrade; SHeight: 6),
    (Func: IsDexMiningUpgrade; SHeight: 7),
    (Func: IsDexRobotUpgrade; SHeight: 8),
    (Func: IsDexStableMarketUpgrade; SHeight: 9)
  ];

  for vEle in vCases do
  begin
    TestUpgradePoint(vEle.Func, vEle.SHeight);
  end;
end;

procedure TTestUpgrade.TestEmptyUpgradeBox;
type
  TUPoint = record
    Func: TFunc<UInt64, Boolean>;
    SHeight: UInt64;
  end;
var
  vCases: TArray<TUPoint>;
  vEle: TUPoint;
begin
  Assert.WillRaise(procedure
  begin
    NewEmptyUpgradeBox.AddPoint(1, 20).AddPoint(3, 90);
  end, EAbort, 'last upgrade version is missing');

  InitUpgradeBox(NewEmptyUpgradeBox.AddPoint(1, 20).AddPoint(2, 90));

  vCases := [
    (Func: IsSeedUpgrade; SHeight: 20),
    (Func: IsDexUpgrade; SHeight: 90)
  ];
  for vEle in vCases do
  begin
    TestUpgradePoint(vEle.Func, vEle.SHeight);
  end;

  vCases := [
    (Func: IsStemUpgrade; SHeight: 20),
    (Func: IsEarthUpgrade; SHeight: 90)
  ];
  for vEle in vCases do
  begin
    TestEmptyUpgradePoint(vEle.Func, vEle.SHeight);
  end;
end;

procedure TTestUpgrade.TestUpgrade;
var
  vCur: TUpgradePoint;
  vActivePoints: TArray<TUpgradePoint>;
begin
  InitUpgradeBox(NewEmptyUpgradeBox.AddPoint(1, 10).AddPoint(2, 20).AddPoint(3, 30));

  vCur := GetCurPoint(15);
  Assert.AreEqual<UInt64>(10, vCur.Height);
  Assert.AreEqual<Cardinal>(1, vCur.Version);

  vCur := GetCurPoint(2);
  Assert.IsNull(vCur);

  vActivePoints := GetActivePoints(25);

  Assert.AreEqual(2, Length(vActivePoints));
  Assert.AreEqual<Cardinal>(1, vActivePoints[0].Version);
  Assert.AreEqual<Cardinal>(2, vActivePoints[1].Version);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUpgrade);
end.
