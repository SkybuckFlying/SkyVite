unit unit_vite;

interface

uses
  SysUtils, Classes, StrUtils, Generics.Collections,
  ConfigUnit, WalletUnit, VerifierUnit, ChainUnit, ProducerUnit, NetUnit, PoolUnit, ConsensusUnit, OnRoadUnit, VMUnit, Log15Unit;

type
  TVite = class
  private
    FConfig: TConfig;
    FWalletManager: TWalletManager;
    FVerifier: TVerifier;
    FChain: TChain;
    FProducer: TProducer;
    FNet: TNet;
    FPool: TBlockPool;
    FConsensus: TConsensus;
    FOnRoad: TOnRoadManager;
  public
    constructor Create(cfg: TConfig; walletManager: TWalletManager);
    function Init: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    function Chain: TChain;
    function Net: TNet;
    function WalletManager: TWalletManager;
    function Producer: TProducer;
    function Pool: TBlockPool;
    function Consensus: TConsensus;
    function OnRoad: TOnRoadManager;
    function Config: TConfig;
    function Verifier: TVerifier;
  end;

  function ParseCoinbase(coinbaseCfg: string): TAddress;

implementation

constructor TVite.Create(cfg: TConfig; walletManager: TWalletManager);
begin
  // Initialization logic here
end;

function TVite.Init: Boolean;
begin
  // Initialization logic here
end;

function TVite.Start: Boolean;
begin
  // Start logic here
end;

function TVite.Stop: Boolean;
begin
  // Stop logic here
end;

function TVite.Chain: TChain;
begin
  Result := FChain;
end;

function TVite.Net: TNet;
begin
  Result := FNet;
end;

function TVite.WalletManager: TWalletManager;
begin
  Result := FWalletManager;
end;

function TVite.Producer: TProducer;
begin
  Result := FProducer;
end;

function TVite.Pool: TBlockPool;
begin
  Result := FPool;
end;

function TVite.Consensus: TConsensus;
begin
  Result := FConsensus;
end;

function TVite.OnRoad: TOnRoadManager;
begin
  Result := FOnRoad;
end;

function TVite.Config: TConfig;
begin
  Result := FConfig;
end;

function TVite.Verifier: TVerifier;
begin
  Result := FVerifier;
end;

function ParseCoinbase(coinbaseCfg: string): TAddress;
var
  splits: TArray<string>;
  i: Integer;
  addr: TAddress;
begin
  splits := SplitString(coinbaseCfg, ':');
  if Length(splits) <> 2 then
    raise Exception.Create('len is not equals 2.');
  i := StrToInt(splits[0]);
  addr := HexToAddress(splits[1]);
  Result := addr;
end;

end.



