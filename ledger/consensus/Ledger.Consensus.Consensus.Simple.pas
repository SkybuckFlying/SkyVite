unit Ledger.Consensus.ConsensusSimple;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.DateUtils,
  Interfaces.Core,
  Common.Types,
  Ledger.Consensus.Core,
  Log15;

type
  ISimpleCs = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B44}']
    function GetInfo: IGroupInfo;
    function GenProofTime(ParaH: UInt64): TDateTime;
    function ElectionTime(ParaT: TDateTime): TTuple<IElectionResult, Exception>;
    function ElectionIndex(ParaIndex: UInt64): TTuple<IElectionResult, Exception>;
    function VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
  end;

  TSimpleCs = class(TInterfacedObject, ISimpleCs)
  private
    mGroupInfo: IGroupInfo;
    mAlgo: IAlgo;
    mLog: ILogger;
    function VerifyProducerInternal(ParaT: TDateTime; const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
  public
    constructor Create(ParaLog: ILogger);
    function GetInfo: IGroupInfo;
    function GenProofTime(ParaH: UInt64): TDateTime;
    function ElectionTime(ParaT: TDateTime): TTuple<IElectionResult, Exception>;
    function ElectionIndex(ParaIndex: UInt64): TTuple<IElectionResult, Exception>;
    function VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
  end;

function NewSimpleCs(ParaLog: ILogger): ISimpleCs;
function GenSimpleAddrs: TArray<TAddress>;
function GenSimpleInfo: IGroupInfo;

var
  simpleGenesis: TDateTime;
  simpleAddrs: TArray<TAddress>;

implementation

uses
  Common.Address;

function NewSimpleCs(ParaLog: ILogger): ISimpleCs;
begin
  Result := TSimpleCs.Create(ParaLog);
end;

// vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a hex public key:3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200
// vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25 hex public key:e0de77ffdc2719eb1d8e89139da9747bd413bfe59781c43fc078bb37d8cbd77a
function GenSimpleAddrs: TArray<TAddress>;
var
  vAddrsStr: TArray<string>;
  v: string;
  vAddr: TAddress;
begin
  SetLength(Result, 0);
  vAddrsStr := ['vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a',
    'vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25'];

  for v in vAddrsStr do
  begin
    try
      vAddr := THexToAddress(v);
      Result := Concat(Result, [vAddr]);
    except
      on E: Exception do
        raise;
    end;
  end;
end;

function GenSimpleInfo: IGroupInfo;
var
  vGroup: TConsensusGroupInfo;
begin
  vGroup.Gid := SNAPSHOT_GID;
  vGroup.NodeCount := 2;
  vGroup.Interval := 1;
  vGroup.PerCount := 3;
  vGroup.RandCount := 1;
  vGroup.RandRank := 100;
  vGroup.Repeat := 1;
  vGroup.CountingTokenId := CreateTokenTypeId;
  vGroup.RegisterConditionId := 0;
  vGroup.RegisterConditionParam := nil;
  vGroup.VoteConditionId := 0;
  vGroup.VoteConditionParam := nil;
  vGroup.Owner := Default(TAddress);
  vGroup.StakeAmount := nil;
  vGroup.ExpirationHeight := 0;

  Result := TGroupInfo.Create(simpleGenesis, vGroup);
end;

{ TSimpleCs }

constructor TSimpleCs.Create(ParaLog: ILogger);
begin
  mLog := ParaLog.New('gid', 'snapshot');
  mGroupInfo := GenSimpleInfo;
  mAlgo := TAlgo.Create(mGroupInfo);
end;

function TSimpleCs.GetInfo: IGroupInfo;
begin
  Result := mGroupInfo;
end;

function TSimpleCs.GenProofTime(ParaH: UInt64): TDateTime;
var
  vSt, vEt: TDateTime;
begin
  vSt, vEt := mGroupInfo.Index2Time(ParaH);
  Result := vEt;
end;

function TSimpleCs.ElectionTime(ParaT: TDateTime): TTuple<IElectionResult, Exception>;
var
  vIndex: UInt64;
begin
  vIndex := mGroupInfo.Time2Index(ParaT);
  Result := ElectionIndex(vIndex);
end;

function TSimpleCs.ElectionIndex(ParaIndex: UInt64): TTuple<IElectionResult, Exception>;
begin
  Result := TTuple<IElectionResult, Exception>.Create(GenElectionResult(mGroupInfo, ParaIndex, simpleAddrs), nil);
end;

function TSimpleCs.VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
var
  vElectionResult: IElectionResult;
  vErr: Exception;
begin
  TValue.Make(ElectionTime(ParaT), vElectionResult, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<Boolean, Exception>.Create(False, vErr));
  end;
  Result := TTuple<Boolean, Exception>.Create(VerifyProducerInternal(ParaT, ParaAddress, vElectionResult), nil);
end;

function TSimpleCs.VerifyProducerInternal(ParaT: TDateTime; const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
var
  vPlan: TMemberPlan;
begin
  if ParaResult = nil then
  begin
    Exit(False);
  end;
  for vPlan in ParaResult.Plans do
  begin
    if (vPlan.Member = ParaAddress) and (vPlan.STime = ParaT) then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end;

initialization
  simpleGenesis := UnixToDateTime(1553849738);
  simpleAddrs := GenSimpleAddrs;
end.
