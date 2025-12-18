unit RpcApi.Api.Vote;

interface

uses
  Common.BigInt,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
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
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.SysUtils System.Classes System.JSON,
  Vite Common.Types Interfaces.Core Ledger.Chain Ledger.Consensus Log15 Vm.Contracts.Abi;

type
  TVoteInfo = class
  private
    FNodeName: string;
    FNodeStatus: Byte;
    FBalance: string;
  public
    property NodeName: string read FNodeName write FNodeName;
    property NodeStatus: Byte read FNodeStatus write FNodeStatus;
    property Balance: string read FBalance write FBalance;
    function ToJSON: TJSONObject;
  end;

  TVoteApi = class
  private
    FChain: IChain;
    FCs: IConsensus;
    FLog: ILogger;
    function GetVoteData(Gid: TGid; const Name: string): TBytes;
    function GetCancelVoteData(Gid: TGid): TBytes;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    function GetVoteInfo(Gid: TGid; Addr: TAddress): TVoteInfo;
    function GetVoteDetails(Index: PUInt64): TArray<IVoteDetails>;
  end;

const
  NodeStatusActive = 1;
  NodeStatusInActive = 2;

implementation

uses
  Common.Db, Vm.Db;

{ TVoteInfo }

function TVoteInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('nodeName', FNodeName);
  Result.AddPair('nodeStatus', TJSONNumber.Create(FNodeStatus));
  Result.AddPair('balance', FBalance);
end;

{ TVoteApi }

constructor TVoteApi.Create(AVite: TVite);
begin
  FChain := AVite.Chain;
  FCs := AVite.Consensus;
  FLog := TLog15.New('module', 'rpc_api/vote_api');
end;

function TVoteApi.GetString: string;
begin
  Result := 'VoteApi';
end;

function TVoteApi.GetVoteData(Gid: TGid; const Name: string): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbiGovernance.MethodNameVote, Gid, Name);
end;

function TVoteApi.GetCancelVoteData(Gid: TGid): TBytes;
begin
  Result := TAbiGovernance.PackMethod(TAbiGovernance.MethodNameCancelVote, Gid);
end;

function TVoteApi.GetVoteInfo(Gid: TGid; Addr: TAddress): TVoteInfo;
var
  Db: IVmDb;
  VoteInfo: TAbiVoteInfo;
  Balance: TBigInt;
  IsActive: Boolean;
begin
  Db := GetVmDb(FChain, AddressGovernance);
  VoteInfo := TAbi.GetVote(Db, Gid, Addr);
  if VoteInfo <> nil then
  begin
    Balance := FChain.GetBalance(Addr, ViteTokenId);
    IsActive := TAbi.IsActiveRegistration(Db, VoteInfo.SbpName, Gid);
    Result := TVoteInfo.Create;
    Result.NodeName := VoteInfo.SbpName;
    if IsActive then
      Result.NodeStatus := NodeStatusActive
    else
      Result.NodeStatus := NodeStatusInActive;
    Result.Balance := BigIntToString(Balance);
  end
  else
    Result := nil;
end;

function TVoteApi.GetVoteDetails(Index: PUInt64): TArray<IVoteDetails>;
var
  T: TDateTime;
  Details: TArray<IVoteDetails>;
  Err: Pointer;
  eTime: TDateTime;
begin
  T := Now;
  if Index <> nil then
  begin
    eTime := FCs.SBPReader.GetDayTimeIndex.Index2Time(Index^);
    T := eTime;
  end;
  FCs.API.ReadVoteMap(T, Details, Err);
  if Err <> nil then
    raise Exception(Err);
  Result := Details;
end;

end.
