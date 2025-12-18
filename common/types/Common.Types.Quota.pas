unit Common.Types.Quota;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  System.SysUtils;

type
  TQuotaInfo = record
    mBlockCount: UInt64;
    mQuotaTotal: UInt64;
    mQuotaUsedTotal: UInt64;
  end;

  TQuota = record
    mCurrent: UInt64;
    mStakeQuotaPerSnapshotBlock: UInt64;
    mAvg: UInt64;
    mSnapshotCurrent: UInt64;
    mBlocked: Boolean;
    mBlockReleaseHeight: UInt64;
  end;

  TQuotaHelper = record helper for TQuota
  public
    function GetStakeQuotaPerSnapshotBlock: UInt64;
    function GetCurrent: UInt64;
    function GetSnapshotCurrent: UInt64;
    function GetAvg: UInt64;
    function GetBlocked: Boolean;
    function GetBlockReleaseHeight: UInt64;
  end;

function NewQuota(
  const ParaStakeQuota: UInt64;
  const ParaCurrent: UInt64;
  const ParaAvg: UInt64;
  const ParaSnapshotCurrent: UInt64;
  const ParaBlocked: Boolean;
  const ParaBlockReleaseHeight: UInt64
): TQuota;

implementation

function NewQuota(
  const ParaStakeQuota: UInt64;
  const ParaCurrent: UInt64;
  const ParaAvg: UInt64;
  const ParaSnapshotCurrent: UInt64;
  const ParaBlocked: Boolean;
  const ParaBlockReleaseHeight: UInt64
): TQuota;
begin
  Result.mCurrent := ParaCurrent;
  Result.mStakeQuotaPerSnapshotBlock := ParaStakeQuota;
  Result.mAvg := ParaAvg;
  Result.mSnapshotCurrent := ParaSnapshotCurrent;
  Result.mBlocked := ParaBlocked;
  Result.mBlockReleaseHeight := ParaBlockReleaseHeight;
end;

{ TQuotaHelper }

function TQuotaHelper.GetStakeQuotaPerSnapshotBlock: UInt64;
begin
  Result := Self.mStakeQuotaPerSnapshotBlock;
end;

function TQuotaHelper.GetCurrent: UInt64;
begin
  Result := Self.mCurrent;
end;

function TQuotaHelper.GetSnapshotCurrent: UInt64;
begin
  Result := Self.mSnapshotCurrent;
end;

function TQuotaHelper.GetAvg: UInt64;
begin
  Result := Self.mAvg;
end;

function TQuotaHelper.GetBlocked: Boolean;
begin
  Result := Self.mBlocked;
end;

function TQuotaHelper.GetBlockReleaseHeight: UInt64;
begin
  Result := Self.mBlockReleaseHeight;
end;

end.
