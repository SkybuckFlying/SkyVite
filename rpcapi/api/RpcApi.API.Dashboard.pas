unit RpcApi.Api.Dashboard;

interface

uses
  Common.HexUtil,
  Common.Types,
  Crypto.Ed25519,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Version,
  Vite;

type
  TOsInfo = record
    mReqId: string;
    mOs: string;
    mPlatform: string;
    mPlatformFamily: string;
    mPlatformVersion: string;
    mKernelVersion: string;
    mMemTotal: UInt64;
    mMemFree: UInt64;
    mCpuNum: Integer;
    mGoroutineCount: Integer;
    mErr: string;
  end;

  TProcessInfo = record
    mReqId: string;
    mBuildVersion: string;
    mCommitVersion: string;
    mNodeName: string;
    mRewardAddress: TAddress;
    mPid: Cardinal;
  end;

  THashHeightTime = record
    mHash: string;
    mHeight: UInt64;
    mTime: Int64;
  end;

  TRuntimeInfo = record
    mReqId: string;
    mPeersNum: Integer;
    mSnapshotPendingNum: Integer;
    mAccountPendingNum: string;
    mLatestSnapshot: THashHeightTime;
    mUpdateTime: Int64;
    mDelayTime: Int64;
    mProducer: string;
    mSignData: string;
  end;

  TDashboardApi = class
  private
    mVite: TVite;
  public
    constructor Create(ParaVite: TVite);
    function OsInfo(const ParaId: PString): TOsInfo;
    function ProcessInfo(const ParaId: PString): TProcessInfo;
    function RuntimeInfo(const ParaId: PString): TRuntimeInfo;
    function NetId: Cardinal;
  end;

implementation

uses
  System.Diagnostics,
  System.Environment,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  Posix.Sysinfo,
  {$ENDIF}
  System.Threading;

{ TDashboardApi }

constructor TDashboardApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
end;

function TDashboardApi.OsInfo(const ParaId: PString): TOsInfo;
begin
  if ParaId <> nil then
  begin
    Result.mReqId := ParaId^;
  end;

  Result.mOs := TSysInfo.GetOSName;
  Result.mPlatform := TSysInfo.GetDistributionName;
  Result.mPlatformFamily := ''; // Not directly available
  Result.mPlatformVersion := TSysInfo.GetVersionString;
  Result.mKernelVersion := TSysInfo.GetKernelVersion;

  Result.mMemTotal := TSysInfo.GetTotalMemory;
  Result.mMemFree := TSysInfo.GetFreeMemory;

  Result.mCpuNum := TCPU.GetNumProcessors;
  Result.mGoroutineCount := TTask.GetTaskCount;
end;

function TDashboardApi.ProcessInfo(const ParaId: PString): TProcessInfo;
begin
  if ParaId <> nil then
  begin
    Result.mReqId := ParaId^;
  end;
  Result.mBuildVersion := VITE_BUILD_VERSION;
  Result.mCommitVersion := VITE_COMMIT_VERSION;
  if mVite.Config.NodeReward <> nil then
  begin
    Result.mNodeName := mVite.Config.NodeReward.Name;
    Result.mRewardAddress := mVite.Config.RewardAddr;
  end;
  Result.mPid := TProcess.Current.ProcessId;
end;

function TDashboardApi.RuntimeInfo(const ParaId: PString): TRuntimeInfo;
var
  vHead: ISnapshotBlock;
  vSign: TBytes;
begin
  if ParaId <> nil then
  begin
    Result.mReqId := ParaId^;
  end;
  Result.mPeersNum := mVite.Net.Info.Peers.Count;
  Result.mSnapshotPendingNum := mVite.Pool.SnapshotPendingNum;
  Result.mAccountPendingNum := mVite.Pool.AccountPendingNum.ToString;
  vHead := mVite.Chain.GetLatestSnapshotBlock;
  Result.mLatestSnapshot.mHash := vHead.Hash.ToString;
  Result.mLatestSnapshot.mHeight := vHead.Height;
  Result.mLatestSnapshot.mTime := vHead.Timestamp.AsInt64 * 1000;
  Result.mUpdateTime := TTimeZone.Local.ToUniversalTime(Now).AsInt64 * 1000;
  Result.mDelayTime := mVite.Net.Info.Latency;
  if mVite.Producer <> nil then
  begin
    Result.mProducer := mVite.Producer.GetCoinBase.ToString;
  end;
  vSign := TEd25519.Sign(mVite.Net.PeerKey, vHead.Hash.Bytes);
  Result.mSignData := THexUtil.Encode(vSign);
end;

function TDashboardApi.NetId: Cardinal;
begin
  Result := mVite.Config.NetId;
end;

end.
