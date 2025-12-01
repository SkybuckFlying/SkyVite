unit RpcApi.Api.LedgerDebug;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.Types, Ledger.Chain, Ledger.OnRoad, Log15;

type
  TUnreceivedDebugApi = class
  private
    FManager: TOnRoadManager;
    FChain: IChain;
  public
    constructor Create(AVite: TVite);
    function GetContractUnreceivedTransactionCount(const Addr: TAddress; Gid: PGid): UInt64;
    function GetContractUnreceivedFrontBlocks(const Addr: TAddress; Gid: PGid): TArray<TAccountBlock>;
  end;

  TLedgerDebugApi = class
  private
    FUnreceived: TUnreceivedDebugApi;
  public
    constructor Create(AVite: TVite);
    function GetString: string;
    property Unreceived: TUnreceivedDebugApi read FUnreceived;
  end;

implementation

{ TUnreceivedDebugApi }

constructor TUnreceivedDebugApi.Create(AVite: TVite);
begin
  FManager := AVite.OnRoad;
  FChain := AVite.Chain;
end;

function TUnreceivedDebugApi.GetContractUnreceivedTransactionCount(const Addr: TAddress; Gid: PGid): UInt64;
var
  G: TGid;
  Num: UInt64;
begin
  if not Addr.IsContractAddr then
    raise Exception.Create('Address must be the type of Contract.');

  if Gid = nil then
    G := TTypes.DELEGATE_GID
  else
    G := Gid^;

  Num := FManager.GetOnRoadTotalNumByAddr(G, Addr);
  TLog.Info('GetContractUnreceivedTransactionCount', ['gid', G, 'addr', Addr, 'num', Num]);
  Result := Num;
end;

function TUnreceivedDebugApi.GetContractUnreceivedFrontBlocks(const Addr: TAddress; Gid: PGid): TArray<TAccountBlock>;
var
  G: TGid;
  BlockList: TArray<PAccountBlock>;
  RpcBlockList: TArray<TAccountBlock>;
  Sum: Integer;
  V: PAccountBlock;
  AccountBlock: TAccountBlock;
begin
  if not Addr.IsContractAddr then
    raise Exception.Create('Address must be the type of Contract.');

  if Gid = nil then
    G := TTypes.DELEGATE_GID
  else
    G := Gid^;

  BlockList := FManager.GetAllCallersFrontOnRoad(G, Addr);
  TLog.Info('GetContractUnreceivedFrontBlocks', ['gid', G, 'addr', Addr, 'len', Length(BlockList)]);
  SetLength(RpcBlockList, Length(BlockList));
  Sum := 0;
  for V in BlockList do
  begin
    if V <> nil then
    begin
      AccountBlock := LedgerToRpcBlock(FChain, V);
      RpcBlockList[Sum] := AccountBlock;
      Inc(Sum);
    end;
  end;
  Result := Copy(RpcBlockList, 0, Sum);
end;

{ TLedgerDebugApi }

constructor TLedgerDebugApi.Create(AVite: TVite);
begin
  FUnreceived := TUnreceivedDebugApi.Create(AVite);
end;

function TLedgerDebugApi.GetString: string;
begin
  Result := 'LedgerDebugApi';
end;

end.
