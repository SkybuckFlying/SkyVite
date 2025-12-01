unit RpcApi.Api.Dex.Util;

interface

uses
  System.SysUtils, System.Classes, BigNumbers,
  Vite, Common.Types, Interfaces, Vm.Contracts.Dex, Vm.Util,
  RpcApi.Api.Dex.RpcConverter;

function GetConsensusReader(AVite: TVite): TVMConsensusReader;
function AmountBytesToString(Amt: TBytes): string;
function TokenBytesToString(Token: TBytes): string;
function InnerGetOrderById(Db: IVmDb; OrderId: TBytes): TRpcOrder;

implementation

{ Util functions }

function GetConsensusReader(AVite: TVite): TVMConsensusReader;
begin
  Result := TVMConsensusReader.Create(AVite.Consensus.SBPReader);
end;

function AmountBytesToString(Amt: TBytes): string;
var
  BigInt: TBigInteger;
begin
  BigInt := TBigInteger.Create(Amt);
  try
    Result := BigInt.ToString;
  finally
    BigInt.Free;
  end;
end;

function TokenBytesToString(Token: TBytes): string;
var
  Tk: TTokenTypeId;
begin
  Tk := TTokenTypeId.FromBytes(Token);
  Result := Tk.ToString;
end;

function InnerGetOrderById(Db: IVmDb; OrderId: TBytes): TRpcOrder;
var
  Matcher: TRawMatcher;
  Order: TDexOrder;
begin
  Matcher := TRawMatcher.Create(Db);
  try
    Order := Matcher.GetOrderById(OrderId);
    Result := OrderToRpc(Order);
  finally
    Matcher.Free;
  end;
end;

end.
