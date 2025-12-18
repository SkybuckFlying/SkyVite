unit RpcApi.Api.Pow;

interface

uses
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
  System.SysUtils System.Classes System.Generics.Collections,
  Vite Common.HexUtil Common.Types Pow Pow.Remote Vm.Quota Common.BigInt;

type
  TPow = class
  private
    FVite: TVite;
    FPubKey: TBytes;
  public
    constructor Create(AVite: TVite);
    function GetPowNonce(const Difficulty: string; const Data: THash): TBytes;
    function CancelPow(const Data: THash): Boolean;
  end;

implementation

uses System.NetEncoding, System.Binary;

{ TPow }

constructor TPow.Create(AVite: TVite);
var
  P: TBytes;
  Pub: PString;
begin
  FVite := AVite;
  Pub := AVite.Config.SecretPub;
  if Pub <> nil then
    P := THex.Decode(Pub^)
  else
    P := THex.Decode('0xf4b37ea2a04d012835820fc480e0b87150f76112c87fce51412815bc90476d4e');
  FPubKey := P;
end;

function TPow.GetPowNonce(const Difficulty: string; const Data: THash): TBytes;
var
  RealDifficulty, NonceBig, Bd: TBigInteger;
  IsCongestion: Boolean;
  Work: PString;
  NonceStr: string;
  NonceUint64: UInt64;
  Nn: TBytes;
begin
  if TVMTestParamEnabled then
  begin
    Result := TPoW.GetPowNonce(nil, Data);
    Exit;
  end;

  RealDifficulty := TBigInteger.Create;
  RealDifficulty.SetString(Difficulty, 10);

  TQuota.CalcQc(FVite.Chain, FVite.Chain.GetLatestSnapshotBlock.Height, IsCongestion);
  if IsCongestion then
    raise Exception.Create(SErrPoWNotSupportedUnderCongestion);

  Work := TRemote.GenerateWork(Data.Bytes, RealDifficulty);
  if Work = nil then
    raise Exception.Create('GenerateWork failed');

  NonceStr := Work^;
  NonceBig := TBigInteger.Create;
  if not NonceBig.SetString(NonceStr, 16) then
    raise Exception.Create('wrong nonce str');

  NonceUint64 := NonceBig.ToUInt64;
  SetLength(Nn, 8);
  TBitConverter.PutBytes(Nn, 0, NonceUint64, 8);

  Bd := TBigInteger.Create;
  if not Bd.SetString(Difficulty, 10) then
    raise Exception.Create('wrong nonce difficulty');

  if not TPoW.CheckPowNonce(Bd, Nn, Data.Bytes) then
    raise Exception.Create('check nonce failed');

  Result := Nn;
end;

function TPow.CancelPow(const Data: THash): Boolean;
begin
  Result := TRemote.CancelWork(Data.Bytes);
  if not Result then
    raise Exception.Create('pow cancel failed');
end;

end.
