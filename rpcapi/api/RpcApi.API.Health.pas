unit RpcApi.Api.Health;

interface

uses
  System.SysUtils,
  Vite;

const
  ConstInvalidSnapshotMinutes = 3;

type
  THealth = class
  private
    mVite: TVite;
  public
    constructor Create(ParaVite: TVite);
    procedure Health;
  end;

implementation

uses
  System.DateUtils;

{ THealth }

constructor THealth.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
end;

procedure THealth.Health;
var
  vSb: PSnapshotBlock;
  vNowTime: TDateTime;
begin
  vSb := mVite.Chain.GetLatestSnapshotBlock;
  if vSb = nil then
  begin
    raise Exception.Create('check node height failed, sb nil');
  end;
  vNowTime := Now;
  if vNowTime > IncMinute(TDateTime(vSb.Timestamp), ConstInvalidSnapshotMinutes) then
  begin
    raise Exception.Create('check node height failed, height invalid');
  end;
end;

end.
