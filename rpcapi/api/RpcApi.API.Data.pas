unit RpcApi.Api.Data;

interface

uses
  Common.Types,
  Ledger.Chain,
  Log15,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Debug,
  RpcApi.Api.Dex,
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
  Vite;

type
  TGetPledgeListByPageResult = record
    mPledgeInfoList: TArray<TStakeInfo>;
    mLastKey: string;
  end;

  TDataApi = class
  private
    mChain: IChain;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function GetPledgeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaCount: UInt64): TGetPledgeListByPageResult;
    function GetDexUserFundsByPage(const ParaSnapshotHash: THash; const ParaLastAddress: string; ParaCount: Integer): TFunds;
    function GetDexPledgeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaCount: Integer): TGetPledgeListByPageResult;
  end;

implementation

uses
  System.NetEncoding,
  Vm.Contracts.Dex,
  Common.BigInt;

{ TDataApi }

constructor TDataApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mChain := ParaVite.Chain;
  mLog := TLog.New('module', 'rpc_api/data_api');
end;

function TDataApi.GetString: string;
begin
  Result := 'DataApi';
end;

function TDataApi.GetPledgeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaCount: UInt64): TGetPledgeListByPageResult;
var
  vLastKeyBytes: TBytes;
  vList: TArray<TStakeInfo>;
begin
  vLastKeyBytes := TNetEncoding.Base16.Decode(ParaLastKey);
  mChain.GetStakeListByPage(ParaSnapshotHash, vLastKeyBytes, ParaCount, vList, vLastKeyBytes);
  Result.mPledgeInfoList := vList;
  Result.mLastKey := TNetEncoding.Base16.Encode(vLastKeyBytes);
end;

function TDataApi.GetDexUserFundsByPage(const ParaSnapshotHash: THash; const ParaLastAddress: string; ParaCount: Integer): TFunds;
var
  vLastAddr: TAddress;
  vFunds: TArray<TFund>;
  vFund: TFund;
  vSimpleFund: TSimpleFund;
  vAcc: TAccountInfo;
  vSimpleAcc: TSimpleAccountInfo;
  vToken: TTokenTypeId;
  vIndex: Integer;
begin
  if ParaCount <= 0 then
  begin
    raise Exception.Create('Invalid input param');
  end;
  if ParaLastAddress <> '' then
  begin
    vLastAddr := TAddress.FromHex(ParaLastAddress);
  end
  else
  begin
    vLastAddr := TAddress.Zero;
  end;
  vFunds := mChain.GetDexFundsByPage(ParaSnapshotHash, vLastAddr, ParaCount);
  SetLength(Result.mFunds, Length(vFunds));
  vIndex := 0;
  for vFund in vFunds do
  begin
    vSimpleFund.mAddress := TAddress.FromBytes(vFund.Address).ToString;
    SetLength(vSimpleFund.mAccounts, Length(vFund.Accounts));
    for vAcc in vFund.Accounts do
    begin
      vToken := TTokenTypeId.FromBytes(vAcc.Token);
      vSimpleAcc.mToken := vToken.ToString;
      if Length(vAcc.Available) > 0 then
      begin
        vSimpleAcc.mAvailable := TAmount.BytesToString(vAcc.Available);
      end;
      if Length(vAcc.Locked) > 0 then
      begin
        vSimpleAcc.mLocked := TAmount.BytesToString(vAcc.Locked);
      end;
      vSimpleFund.mAccounts[vIndex] := vSimpleAcc;
      Inc(vIndex);
    end;
    Result.mFunds[vIndex] := vSimpleFund;
    Inc(vIndex);
  end;
end;

function TDataApi.GetDexPledgeListByPage(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaCount: Integer): TGetPledgeListByPageResult;
var
  vLastKeyBytes: TBytes;
  vList: TArray<TDexStakeInfo>;
  vPList: TArray<TStakeInfo>;
  vIndex: Integer;
  vInfo: TDexStakeInfo;
  vPInfo: TStakeInfo;
begin
  vLastKeyBytes := TNetEncoding.Base16.Decode(ParaLastKey);
  mChain.GetDexStakeListByPage(ParaSnapshotHash, vLastKeyBytes, ParaCount, vList, vLastKeyBytes);
  SetLength(vPList, Length(vList));
  if Length(vList) > 0 then
  begin
    vIndex := 0;
    for vInfo in vList do
    begin
      vPInfo.mAmount := TBigInteger.Create(vInfo.Amount);
      vPInfo.mBeneficiary := TAddress.DexFund;
      vPInfo.mIsDelegated := True;
      vPInfo.mDelegateAddress := TAddress.DexFund;
      vPInfo.mBid := Byte(vInfo.StakeType);
      vPInfo.mStakeAddress := TAddress.FromBytes(vInfo.Address);
      vPList[vIndex] := vPInfo;
      Inc(vIndex);
    end;
  end;
  Result.mPledgeInfoList := vPList;
  Result.mLastKey := TNetEncoding.Base16.Encode(vLastKeyBytes);
end;

end.
