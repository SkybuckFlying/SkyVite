unit RpcApi.Api.Util;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite, Common.HexUtil, Common.Types, Pow, Pow.Remote, Vm.Quota, Common.BigInt,
  Crypto;

type
  TUtilApi = class
  private
    FVite: TVite;
  public
    constructor Create(AVite: TVite);
    function GetPoWNonce(const Difficulty: string; const Data: THash): TBytes;
    function GetPowNoncePrivate(const Address: TAddress; Height: UInt64; const Difficulty: string; const Data: THash; Timestamp: UInt64; const Sig: TBytes; Cnt: UInt64): TBytes;
  end;

implementation

uses System.NetEncoding, System.Binary, System.DateUtils;

{ TUtilApi }

constructor TUtilApi.Create(AVite: TVite);
begin
  FVite := AVite;
end;

function TUtilApi.GetPoWNonce(const Difficulty: string; const Data: THash): TBytes;
var
  RealDifficulty, DifficultyCap, NonceBig, Bd: TBigInteger;
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

  DifficultyCap := TBigInteger.Create(8034995932);
  DifficultyCap := DifficultyCap * TBigInteger.Create(50);
  if RealDifficulty > DifficultyCap then
    raise Exception.Create(SErrDifficultyTooLarge);

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

function TUtilApi.GetPowNoncePrivate(const Address: TAddress; Height: UInt64; const Difficulty: string; const Data: THash; Timestamp: UInt64; const Sig: TBytes; Cnt: UInt64): TBytes;
var
  S: TDateTime;
  Flag: Boolean;
  RealDifficulty: TBigInteger;
  Nonce: TBytes;
begin
  S := Now;
  try
    Flag := TCrypto.VerifySig(FVite.Config.SecretPub, TEncoding.UTF8.GetBytes(IntToStr(Timestamp)), Sig);
    if not Flag then
      raise Exception.Create('auth fail');

    RealDifficulty := TBigInteger.Create;
    RealDifficulty.SetString(Difficulty, 10);

    Nonce := TPoW.MapPowNonce2(RealDifficulty, Data, Cnt);
    Result := Nonce;
  finally
    WriteLn(Format('GetPowNoncePrivate address:%s height:%d difficulty:%s data:%s timestamp:%d sig:%s err:%s duration_ms:%d',
      [Address.ToString, Height, Difficulty, Data.ToHex, Timestamp, THex.Encode(Sig), '', Round((Now - S) * 24 * 60 * 60 * 1000)]));
  end;
end;

end.
