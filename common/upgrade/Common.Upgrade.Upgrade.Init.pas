unit Common.Upgrade.Init;

interface

uses
  Common.Upgrade Common.Upgrade.Face System.Generics.Collections,
  Common.Upgrade.Face,
  Common.Upgrade.Height.Point,
  Common.Upgrade.Upgrade,
  Common.Upgrade.Upgrade.Test;

function NewLatestUpgradeBox: IUpgradeBox;
function NewMainnetUpgradeBox: IUpgradeBox;
function NewCustomUpgradeBox(ParaPoints: TDictionary<string, TUpgradePoint>): IUpgradeBox;
function NewEmptyUpgradeBox: IUpgradeBox;

implementation

function NewLatestUpgradeBox: IUpgradeBox;
begin
  Result := TUpgradeBox.Create([
    TUpgradePoint.Create(1, 1),
    TUpgradePoint.Create(2, 1),
    TUpgradePoint.Create(3, 1),
    TUpgradePoint.Create(4, 1),
    TUpgradePoint.Create(5, 1),
    TUpgradePoint.Create(6, 1),
    TUpgradePoint.Create(7, 1),
    TUpgradePoint.Create(8, 1),
    TUpgradePoint.Create(9, 1),
    TUpgradePoint.Create(10, 1),
    TUpgradePoint.Create(11, 1),
    TUpgradePoint.Create(12, 1),
    TUpgradePoint.Create(13, 1),
    TUpgradePoint.Create(14, 1)
  ]);
end;

function NewMainnetUpgradeBox: IUpgradeBox;
begin
  Result := TUpgradeBox.Create([
    TUpgradePoint.Create(1, 3488471, 'SeedFork'),
    TUpgradePoint.Create(2, 5442723, 'DexFork'),
    TUpgradePoint.Create(3, 8013367, 'DexFeeFork'),
    TUpgradePoint.Create(4, 8403110, 'StemFork'),
    TUpgradePoint.Create(5, 9413600, 'LeafFork'),
    TUpgradePoint.Create(6, 16634530, 'EarthFork'),
    TUpgradePoint.Create(7, 17142720, 'DexMiningFork'),
    TUpgradePoint.Create(8, 31305900, 'DexRobotFork'),
    TUpgradePoint.Create(9, 39694000, 'DexStableMarketFork'),
    TUpgradePoint.Create(10, 77106666, 'Version10'),
    TUpgradePoint.Create(11, 101320000, 'Version11'),
    TUpgradePoint.Create(12, 116480000, 'Version12'),
    TUpgradePoint.Create(13, 166869900, 'Version13'),
    TUpgradePoint.Create(14, EndlessHeight, 'VersionX')
  ]);
end;

function NewCustomUpgradeBox(ParaPoints: TDictionary<string, TUpgradePoint>): IUpgradeBox;
var
  Points: TArray<TUpgradePoint>;
  Pair: TPair<string, TUpgradePoint>;
  Point: TUpgradePoint;
begin
  SetLength(Points, ParaPoints.Count);
  var i := 0;
  for Pair in ParaPoints do
  begin
    Point := Pair.Value;
    if Point.Name = '' then
      Point.Name := Pair.Key;
    Points[i] := Point;
    Inc(i);
  end;
  Result := TUpgradeBox.Create(Points);
end;

function NewEmptyUpgradeBox: IUpgradeBox;
begin
  Result := TUpgradeBox.Create([]);
end;

end.
