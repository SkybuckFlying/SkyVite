unit Common.Upgrade;

interface

uses
  Common.Upgrade.Face,
  Common.Upgrade.Height.Point,
  Common.Upgrade.Upgrade.Init,
  Common.Upgrade.Upgrade.Test,
  System.SysUtils System.Classes System.Generics.Collections Common.Upgrade.Face Common.Log;

const
  EndlessHeight = 1000000000;

type
  TUpgradePoint = record
    Version: UInt32;
    Height: UInt64;
    Name: string;
  end;

  TUpgradeBox = class(TInterfacedObject, IUpgradeBox)
  private
    FPointMap: TDictionary<UInt32, TUpgradePoint>;
    FHeightMap: TDictionary<UInt64, Boolean>;
    FSortedPoints: TList<TUpgradePoint>;
    procedure CheckBox;
    procedure InitFromArray(ParaPoints: TArray<TUpgradePoint>);
    function SortPoints(ParaPointMap: TDictionary<UInt32, TUpgradePoint>): TList<TUpgradePoint>;
  public
    constructor Create(ParaPoints: TArray<TUpgradePoint>);
    destructor Destroy; override;
    procedure AddPoint(ParaVersion: UInt32; ParaHeight: UInt64);
    function GetLatestPoint: TUpgradePoint;
    function GetCurrentPoint(ParaHeight: UInt64): TUpgradePoint;
    function GetActivePoints(ParaHeight: UInt64): TArray<TUpgradePoint>;
    function GetUpgradePoint(ParaVersion: UInt32): TUpgradePoint;
    function IsActive(ParaVersion: UInt32; ParaHeight: UInt64): Boolean;
    function IsPoint(ParaHeight: UInt64): Boolean;
    function GetUpgradePoints: TArray<TUpgradePoint>;
  end;

  THeightPoint = class(TInterfacedObject, IHeightPoint)
  private
    FHeight: UInt64;
  public
    constructor Create(ParaHeight: UInt64);
    function IsVersion12Upgrade: Boolean;
    function IsDexFeeUpgrade: Boolean;
  end;

  TMockHeightPoint = class(TInterfacedObject, IHeightPoint)
  private
    FBox: IUpgradeBox;
    FHeight: UInt64;
  public
    constructor Create(ParaBox: IUpgradeBox; ParaHeight: UInt64);
    function IsVersion12Upgrade: Boolean;
    function IsDexFeeUpgrade: Boolean;
  end;

var
  Upgrade: IUpgradeBox;
  Log: TLogger;

procedure CleanupUpgradeBox;
procedure InitUpgradeBox(ParaBox: IUpgradeBox);
procedure AddUpgradePoint(ParaVersion: UInt32; ParaHeight: UInt64);
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
  System.JSON;

procedure AssertUpgradeNotNil;
begin
  if Upgrade = nil then
    raise Exception.Create('upgrade is nil');
end;

procedure CleanupUpgradeBox;
begin
  Log.Info('clean up upgrade box');
  Upgrade := nil;
end;

procedure InitUpgradeBox(ParaBox: IUpgradeBox);
var
  Points: TArray<TUpgradePoint>;
  PointsJson: string;
begin
  if Upgrade <> nil then
    raise Exception.Create('init upgrade twice');

  Points := ParaBox.GetUpgradePoints;
  PointsJson := TJson.Format(TJson.Serialize<TArray<TUpgradePoint>>(Points));
  Log.Info(Format('init upgrade: %s', [PointsJson]));
  Upgrade := TUpgradeBox.Create(Points);
end;

procedure AddUpgradePoint(ParaVersion: UInt32; ParaHeight: UInt64);
begin
  Upgrade.AddPoint(ParaVersion, ParaHeight);
end;

function IsUpgradePoint(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsPoint(ParaSHeight);
end;

function GetCurPoint(ParaSHeight: UInt64): TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.GetCurrentPoint(ParaSHeight);
end;

function GetLatestPoint: TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.GetLatestPoint;
end;

function GetActivePoints(ParaSHeight: UInt64): TArray<TUpgradePoint>;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.GetActivePoints(ParaSHeight);
end;

function GetAllPoints: TArray<TUpgradePoint>;
begin
  Result := Upgrade.GetUpgradePoints;
end;

function IsSeedUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(1, ParaSHeight);
end;

function IsDexUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(2, ParaSHeight);
end;

function IsDexFeeUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(3, ParaSHeight);
end;

function IsStemUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(4, ParaSHeight);
end;

function IsLeafUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(5, ParaSHeight);
end;

function GetLeafUpgradePoint: TUpgradePoint;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.GetUpgradePoint(5);
end;

function IsEarthUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(6, ParaSHeight);
end;

function IsDexMiningUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(7, ParaSHeight);
end;

function IsDexRobotUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(8, ParaSHeight);
end;

function IsDexStableMarketUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(9, ParaSHeight);
end;

function IsVersion10Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(10, ParaSHeight);
end;

function IsVersion11Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(11, ParaSHeight);
end;

function IsVersion12Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(12, ParaSHeight);
end;

function IsVersion13Upgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(13, ParaSHeight);
end;

function IsVersionXUpgrade(ParaSHeight: UInt64): Boolean;
begin
  AssertUpgradeNotNil;
  Result := Upgrade.IsActive(14, ParaSHeight);
end;

{ TUpgradeBox }

procedure TUpgradeBox.CheckBox;
var
  LastHeight: UInt64;
  Index: Integer;
  Ele: TUpgradePoint;
begin
  LastHeight := 0;
  for Index := 0 to FSortedPoints.Count - 1 do
  begin
    Ele := FSortedPoints[Index];
    if Index <> Integer(Ele.Version) - 1 then
      raise Exception.Create('error version in upgrade box');
    if Ele.Height < LastHeight then
      raise Exception.Create('error height in upgrade box');
    LastHeight := Ele.Height;
  end;
end;

procedure TUpgradeBox.InitFromArray(ParaPoints: TArray<TUpgradePoint>);
var
  Value: TUpgradePoint;
begin
  FPointMap := TDictionary<UInt32, TUpgradePoint>.Create;
  FHeightMap := TDictionary<UInt64, Boolean>.Create;
  FSortedPoints := TList<TUpgradePoint>.Create;

  for Value in ParaPoints do
  begin
    if Value.Name = '' then
      Value.Name := IntToStr(Value.Version);
    FPointMap.Add(Value.Version, Value);
    FHeightMap.Add(Value.Height, True);
  end;
  FSortedPoints := SortPoints(FPointMap);
end;

function TUpgradeBox.SortPoints(ParaPointMap: TDictionary<UInt32, TUpgradePoint>): TList<TUpgradePoint>;
var
  ResultList: TList<TUpgradePoint>;
  Value: TUpgradePoint;
begin
  ResultList := TList<TUpgradePoint>.Create;
  for Value in ParaPointMap.Values do
    ResultList.Add(Value);
  ResultList.Sort(TComparer<TUpgradePoint>.Construct(function(const L, R: TUpgradePoint): Integer
  begin
    if L.Version < R.Version then
      Result := -1
    else if L.Version > R.Version then
      Result := 1
    else
      Result := 0;
  end));
  Result := ResultList;
end;

constructor TUpgradeBox.Create(ParaPoints: TArray<TUpgradePoint>);
begin
  inherited Create;
  InitFromArray(ParaPoints);
  CheckBox;
end;

destructor TUpgradeBox.Destroy;
begin
  FPointMap.Free;
  FHeightMap.Free;
  FSortedPoints.Free;
  inherited;
end;

procedure TUpgradeBox.AddPoint(ParaVersion: UInt32; ParaHeight: UInt64);
var
  Point: TUpgradePoint;
begin
  if (FPointMap.Count > 0) and (not FPointMap.ContainsKey(ParaVersion - 1)) then
    raise Exception.Create('last upgrade version is missing');

  Point.Version := ParaVersion;
  Point.Height := ParaHeight;
  FPointMap.Add(ParaVersion, Point);
  FHeightMap.Add(ParaHeight, True);
  FSortedPoints := SortPoints(FPointMap);
end;

function TUpgradeBox.GetLatestPoint: TUpgradePoint;
var
  ResultPoint: TUpgradePoint;
  V: TUpgradePoint;
begin
  FillChar(ResultPoint, SizeOf(TUpgradePoint), 0);
  for V in FSortedPoints do
  begin
    if V.Height < EndlessHeight then
      ResultPoint := V
    else
      Break;
  end;
  Result := ResultPoint;
end;

function TUpgradeBox.GetCurrentPoint(ParaHeight: UInt64): TUpgradePoint;
var
  ResultPoint: TUpgradePoint;
  V: TUpgradePoint;
begin
  FillChar(ResultPoint, SizeOf(TUpgradePoint), 0);
  for V in FSortedPoints do
  begin
    if V.Height <= ParaHeight then
      ResultPoint := V
    else
      Break;
  end;
  Result := ResultPoint;
end;

function TUpgradeBox.GetActivePoints(ParaHeight: UInt64): TArray<TUpgradePoint>;
var
  ResultList: TList<TUpgradePoint>;
  V: TUpgradePoint;
begin
  ResultList := TList<TUpgradePoint>.Create;
  for V in FSortedPoints do
  begin
    if V.Height <= ParaHeight then
      ResultList.Add(V);
  end;
  Result := ResultList.ToArray;
  ResultList.Free;
end;

function TUpgradeBox.GetUpgradePoint(ParaVersion: UInt32): TUpgradePoint;
begin
  if FPointMap.ContainsKey(ParaVersion) then
    Result := FPointMap[ParaVersion]
  else
    FillChar(Result, SizeOf(TUpgradePoint), 0);
end;

function TUpgradeBox.IsActive(ParaVersion: UInt32; ParaHeight: UInt64): Boolean;
var
  Point: TUpgradePoint;
begin
  if FPointMap.TryGetValue(ParaVersion, Point) then
    Result := ParaHeight >= Point.Height
  else
    Result := False;
end;

function TUpgradeBox.IsPoint(ParaHeight: UInt64): Boolean;
begin
  Result := FHeightMap.ContainsKey(ParaHeight);
end;

function TUpgradeBox.GetUpgradePoints: TArray<TUpgradePoint>;
begin
  Result := FSortedPoints.ToArray;
end;

{ THeightPoint }

constructor THeightPoint.Create(ParaHeight: UInt64);
begin
  inherited Create;
  FHeight := ParaHeight;
end;

function THeightPoint.IsVersion12Upgrade: Boolean;
begin
  Result := IsVersion12Upgrade(FHeight);
end;

function THeightPoint.IsDexFeeUpgrade: Boolean;
begin
  Result := IsDexFeeUpgrade(FHeight);
end;

{ TMockHeightPoint }

constructor TMockHeightPoint.Create(ParaBox: IUpgradeBox; ParaHeight: UInt64);
begin
  inherited Create;
  FBox := ParaBox;
  FHeight := ParaHeight;
end;

function TMockHeightPoint.IsVersion12Upgrade: Boolean;
begin
  Result := FBox.IsActive(12, FHeight);
end;

function TMockHeightPoint.IsDexFeeUpgrade: Boolean;
begin
  Result := FBox.IsActive(3, FHeight);
end;

initialization
  Log := TLogger.New('module', 'upgrade');
end.
