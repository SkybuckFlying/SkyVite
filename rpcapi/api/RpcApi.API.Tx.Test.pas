unit RpcApi.API.Tx.Test;

interface

procedure RunTxTest;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.Math.Vectors,
  System.BigInt,
  GoVite.Types,      // Assumed unit for Address, Hash, Tti, etc.
  GoVite.Crypto,     // Assumed unit for Ed25519, VerifySig
  GoVite.Pow,        // Assumed unit for PoW functions
  GoVite.Encoding,   // Assumed unit for Base64 encoding
  DUnitX.TestFramework;

type
  TAccountBlock = class
  public
    BlockType: Byte;
    PrevHash: THash;
    Height: UInt64;
    AccountAddress: TAddress;
    PublicKey: TBytes;
    ToAddress: TAddress;
    Amount: TBigInteger;
    TokenId: TTokenId;
    Difficulty: TBigInteger;
    Nonce: TBytes;
    function ComputeHash: THash;
  end;

function TAccountBlock.ComputeHash: THash;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    LStream.WriteByte(BlockType);
    LStream.Write(PrevHash.Bytes, Length(PrevHash.Bytes));
    LStream.Write(AccountAddress.Bytes, Length(AccountAddress.Bytes));
    // Simplified hashing logic. A real implementation would be more complex and match Go's RLP encoding.
    Result := THash.FromBytes(TCrypto.Blake2b(LStream.Bytes));
  finally
    LStream.Free;
  end;
end;


procedure TestPubKeyToAddress;
var
  PublicKey: TBytes;
  Addr: TAddress;
begin
  PublicKey := TBase64.Decode(''); // Empty public key example
  Addr := TAddress.PubkeyToAddress(PublicKey);
  // In a real test, you'd assert against a known address.
  // Writeln('PublicKey to addr ', Addr.ToString);
end;

procedure TestTx_SendRawTx_VerifyHashAndSig;
var
  ZeroAddr: TAddress;
  ZeroTkId: TTokenId;
  TokenId: TTokenId;
  PrevHash, PowDataHash, HashData: THash;
  Addr, Address: TAddress;
  Difficulty, Amount: TBigInteger;
  Nonce, PubKey, SignData: TBytes;
  PrivKey: TPrivateKey;
  Block: TAccountBlock;
  IsVerified: Boolean;
  SignBase64, PubKeyBase64: string;
begin
  ZeroAddr := TAddress.FromBytes(TAddress.ZERO_ADDRESS.Bytes);
  ZeroTkId := TTokenId.FromBytes(TTokenId.ZERO_TOKENID.Bytes);
  TokenId := TTokenId.FromHexString('tti_5649544520544f4b454e6e40');
  PrevHash := THash.FromHexString('0000000000000000000000000000000000000000000000000000000000000000');
  Addr := TAddress.FromHexString('vite_6c1032417f80329f3abe0a024fa3a7aa0e952b0fded2262f6f');

  Difficulty := TBigInteger.Parse('65535');
  PowDataHash := THash.DataHash(Addr.Bytes + PrevHash.Bytes);
  Nonce := TBase64.Decode('dfBL1GFpMNA=');

  PrivKey := TEd25519.HexToPrivateKey('44e9768b7d8320a282e75337df8fc1f12a4f000b9f9906ddb886c6823bb599addfda7318e7824d25aae3c749c1cbd4e72ce9401653c66479554a05a2e3cb4f88');
  PubKey := PrivKey.PublicKey;
  Address := TAddress.PubkeyToAddress(PubKey);
  Assert.AreEqual(Addr.ToString, Address.ToString, 'PublicKey does not match address');

  Amount := 10000;

  Block := TAccountBlock.Create;
  try
    Block.BlockType := 2;
    Block.PrevHash := PrevHash;
    Block.Height := 2;
    Block.AccountAddress := Addr;
    Block.PublicKey := PubKey;
    Block.ToAddress := Addr;
    Block.Amount := Amount;
    Block.TokenId := TokenId;
    Block.Difficulty := Difficulty;
    Block.Nonce := Nonce;

    HashData := Block.ComputeHash;
    Assert.IsFalse(HashData.IsZero, 'ComputeHash failed');

    SignData := TEd25519.Sign(PrivKey, HashData.Bytes);
    SignBase64 := TBase64.Encode(SignData);
    PubKeyBase64 := TBase64.Encode(PubKey);

    // For debugging/comparison with Go test output
    // Writeln('sig=', SignBase64);
    // Writeln('pub=', PubKeyBase64);
    // Writeln('hash=', HashData.ToString);

    IsVerified := TCrypto.VerifySig(PubKey, HashData.Bytes, SignData);
    Assert.IsTrue(IsVerified, 'Signature verification failed');

  finally
    Block.Free;
  end;
end;

procedure TestPow;
var
  Address: TAddress;
  Hash, DataHash: THash;
  Difficulty: TBigInteger;
  Nonce: TBytes;
  Stopwatch: TStopwatch;
  Step, I: UInt64;
  Check: Boolean;
begin
  Address := TAddress.FromHexString('vite_f1a9bed77ce7caf9774d0bb82b98e0946570b3531f8f554a00');
  Hash := THash.FromHexString('92a44a90ca60b4bdf4dbdcff5f3452df892271c217e492910013f5c6be6e22ec');

  Stopwatch := TStopwatch.StartNew;
  DataHash := THash.DataHash(Address.Bytes + Hash.Bytes);
  Difficulty := TBigInteger.Parse('12108863');
  Step := 1000000;
  I := 0;

  while True do
  begin
    Nonce := TPoW.MapPowNonce2(Difficulty, DataHash, Step);
    if Length(Nonce) > 0 then
    begin
      Check := TPoW.CheckPowNonce(Difficulty, Nonce, DataHash.Bytes);
      // Log results for comparison
      // TestContext.WriteLine(Format('Nonce: %s, Time: %s, Check: %s', [TBase64.Encode(Nonce), Stopwatch.Elapsed.ToString, Check.ToString]));
      Assert.IsTrue(Check);
      break;
    end;
    I := I + Step;
    if I > 10 * Step then // Timeout to prevent infinite loop
    begin
      Assert.Fail('PoW calculation timed out');
      break;
    end;
  end;
end;


procedure RunTxTest;
begin
  TestPubKeyToAddress;
  TestTx_SendRawTx_VerifyHashAndSig;
  TestPow;
end;

end.
