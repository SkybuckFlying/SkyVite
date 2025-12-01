unit Common.Upgrade.HeightPoint;

interface

uses
  Common.Upgrade.Face,
  Common.Upgrade;

type
  IHeightPoint = interface
    ['{A5F5E3A3-2B1C-4D6E-8F2A-3B7C1D5A6B9E}']
    function IsVersion12Upgrade: Boolean;
    function IsDexFeeUpgrade: Boolean;
  end;

  THeightPoint = class(TInterfacedObject, IHeightPoint)
  private
    mHeight: UInt64;
  public
    constructor Create(ParaHeight: UInt64);
    function IsVersion12Upgrade: Boolean;
    function IsDexFeeUpgrade: Boolean;
  end;

  TMockHeightPoint = class(TInterfacedObject, IHeightPoint)
  private
    mBox: IUpgradeBox;
    mHeight: UInt64;
  public
    constructor Create(ParaHeight: UInt64; ParaBox: IUpgradeBox);
    function IsVersion12Upgrade: Boolean;
    function IsDexFeeUpgrade: Boolean;
  end;

function NewHeightPoint(ParaHeight: UInt64): IHeightPoint;
function NewMockPoint(ParaHeight: UInt64; ParaBox: IUpgradeBox): IHeightPoint;

implementation

{ THeightPoint }

constructor THeightPoint.Create(ParaHeight: UInt64);
begin
  inherited Create;
  mHeight := ParaHeight;
end;

function THeightPoint.IsDexFeeUpgrade: Boolean;
begin
  Result := Common.Upgrade.Face.IsDexFeeUpgrade(mHeight);
end;

function THeightPoint.IsVersion12Upgrade: Boolean;
begin
  Result := Common.Upgrade.Face.IsVersion12Upgrade(mHeight);
end;

{ TMockHeightPoint }

constructor TMockHeightPoint.Create(ParaHeight: UInt64; ParaBox: IUpgradeBox);
begin
  inherited Create;
  mHeight := ParaHeight;
  mBox := ParaBox;
end;

function TMockHeightPoint.IsDexFeeUpgrade: Boolean;
begin
  Result := mBox.IsActive(3, mHeight);
end;

function TMockHeightPoint.IsVersion12Upgrade: Boolean;
begin
  Result := mBox.IsActive(12, mHeight);
end;

function NewHeightPoint(ParaHeight: UInt64): IHeightPoint;
begin
  Result := THeightPoint.Create(ParaHeight);
end;

function NewMockPoint(ParaHeight: UInt64; ParaBox: IUpgradeBox): IHeightPoint;
begin
  Result := TMockHeightPoint.Create(ParaHeight, ParaBox);
end;

end.
