unit Common.Upgrade.Face;

interface

uses
  Common.Upgrade,
  Common.Upgrade.Height.Point,
  Common.Upgrade.Upgrade,
  Common.Upgrade.Upgrade.Init,
  Common.Upgrade.Upgrade.Test,
  Log15,
  System.Generics.Collections,
  System.SysUtils;

var
  gUpgrade: IUpgradeBox;

const
  ConstEndlessHeight = 1000000000;

procedure AssertUpgradeNotNil;
procedure CleanupUpgradeBox;
procedure InitUpgradeBox(ParaBox: IUpgradeBox);
procedure AddUpgradePoint(ParaVersion: Cardinal; ParaHeight: UInt64);
function IsUpgradePoint(ParaSHeight: UInt64): Boolean;
function GetCurPoint(ParaSHeight: UInt64): TUpgradePoint;
function GetLatestPoint: TUpgradePoint;
function GetActivePoints(ParaSHeight: UInt64): TArray<TUpgradePoint>;
function GetAllPoints: TArray<TUpgradePoint>;
function IsSeedUpgrade(ParaSHeight: UInt64): Boolean;
function IsDexUpgrade(ParaSHeight: UInt64): Boolean;
function IsDexFeeUpgrade(ParaSHeight: UInt64): Boolean;
function IsStemUpgrade(ParaSHeight: UInt64): Boolean;
function IsLeafUpgrade(ParaSHeight: UInt64): Boolean;
function GetLeafUpgradePoint: TUpgradePoint;
function IsEarthUpgrade(ParaSHeight: UInt64): Boolean;
function IsDexMiningUpgrade(ParaSHeight: UInt64): Boolean;
function IsDexRobotUpgrade(ParaSHeight: UInt64): Boolean;
function IsDexStableMarketUpgrade(ParaSHeight: UInt64): Boolean;
function IsVersion10Upgrade(ParaSHeight: UInt64): Boolean;
function IsVersion11Upgrade(ParaSHeight: UInt64): Boolean;
function IsVersion12Upgrade(ParaSHeight: UInt64): Boolean;
function IsVersion13Upgrade(ParaSHeight: UInt64): Boolean;
function IsVersionXUpgrade(ParaSHeight: UInt64): Boolean;

implementation

uses
  Common.Json;

var
  log: TLog15;

procedure AssertUpgradeNotNil;
begin
  if not Assigned(gUpgrade) then
  begin
    raise Exception.Create('upgrade is nil');
  end;
end;

procedure CleanupUpgradeBox;
begin
  log.Info('clean up upgrade box');
  gUpgrade := nil;
end;

procedure InitUpgradeBox(ParaBox: IUpgradeBox);
var
  vPoints: TArray<TUpgradePoint>;
begin
  if Assigned(gUpgrade) then
  begin
    raise Exception.Create('init upgrade twice');
  end;
  vPoints := ParaBox.UpgradePoints;
  log.Info(Format('init upgrade: %s', [TJson.ToJson(vPoints)]));
  gUpgrade := NewUpgradeBox(vPoints);
end;

procedure AddUpgradePoint(ParaVersion: Cardinal; ParaHeight: UInt64);
begin
  gUpgrade := gUpgrade.AddPoint(ParaVersion, ParaHeight);
end;

function IsUpgradePoint(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsPoint(ParaSHeight);
end;

function GetCurPoint(ParaSHeight: UInt64): TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.CurrentPoint(ParaSHeight);
end;

function GetLatestPoint: TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.LatestPoint;
end;

function GetActivePoints(ParaSHeight: UInt64): TArray<TUpgradePoint>;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.ActivePoints(ParaSHeight);
end;

function GetAllPoints: TArray<TUpgradePoint>;
begin
  Result := gUpgrade.UpgradePoints;
end;

function IsSeedUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(1, ParaSHeight);
end;

function IsDexUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(2, ParaSHeight);
end;

function IsDexFeeUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(3, ParaSHeight);
end;

function IsStemUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(4, ParaSHeight);
end;

function IsLeafUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(5, ParaSHeight);
end;

function GetLeafUpgradePoint: TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.GetUpgradePoint(5);
end;

function IsEarthUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(6, ParaSHeight);
end;

function IsDexMiningUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(7, ParaSHeight);
end;

function IsDexRobotUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(8, ParaSHeight);
end;

function IsDexStableMarketUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(9, ParaSHeight);
end;

function IsVersion10Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(10, ParaSHeight);
end;

function IsVersion11Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(11, ParaSHeight);
end;

function IsVersion12Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(12, ParaSHeight);
end;

function IsVersion13Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(13, ParaSHeight);
end;

function IsVersionXUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := gUpgrade.IsActive(14, ParaSHeight);
end;

initialization
  log := TLog15.New('module', 'upgrade');
end.
