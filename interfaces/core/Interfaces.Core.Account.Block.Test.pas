unit Interfaces.Core.AccountBlock.Test;

interface

uses
  Common.Types,
  Crypto,
  Crypto.Ed25519,
  DUnitX.TestFramework,
  GoToDelphi.Helpers.BigInt,
  Interfaces.Core.Account,
  Interfaces.Core.Account.Block,
  Interfaces.Core.AccountBlock,
  Interfaces.Core.Contract.Meta,
  Interfaces.Core.Contract.Meta.Test,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Hash.Height.Test,
  Interfaces.Core.Info,
  Interfaces.Core.Serializable,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Core.Snapshot.Block.Test,
  Interfaces.Core.Snapshot.Chunk,
  Interfaces.Core.Token,
  Interfaces.Core.VM.Log.List,
  Interfaces.Core.VM.Log.List.Test,
  Math.BigInt;

type
  [TestFixture]
  TAccountBlockTests = class
  private
    function CreateBlock: TAccountBlock;
  public
    [Test]
    procedure TestComputeHash;
  end;

implementation

uses
  Common.Json;

function TAccountBlockTests.CreateBlock: TAccountBlock;
var
  vAccountAddress1, vAccountAddress2: TAddress;
  vPrivateKey: TPrivateKey;
  vPublicKey: TPublicKey;
  vHash, vPrevHash, vFromBlockHash, vLogHash: THash;
  vSignature: TBytes;
  vError: Exception;
begin
  vError := TEd25519.CreateKeyPair(vPublicKey, vPrivateKey);
  if vError <> nil then
    raise vError;
  vAccountAddress1 := TAddress.FromPublicKey(vPublicKey, vError);
  if vError <> nil then
    raise vError;
  vError := TEd25519.CreateKeyPair(vPublicKey, vPrivateKey);
  if vError <> nil then
    raise vError;
  vAccountAddress2 := TAddress.FromPublicKey(vPublicKey, vError);
  if vError <> nil then
    raise vError;

  vHash := THash.Hash256(TEncoding.UTF8.GetBytes('This is hash'), vError);
  vPrevHash := THash.Hash256(TEncoding.UTF8.GetBytes('This is prevHash'), vError);
  vFromBlockHash := THash.Hash256(TEncoding.UTF8.GetBytes('This is fromBlockHash'), vError);
  vLogHash := THash.Hash256(TEncoding.UTF8.GetBytes('This is logHash'), vError);

  vSignature := TEd25519.Sign(vPrivateKey, vHash.Bytes, vError);

  Result.BlockType := BlockTypeSendCall;
  Result.Hash := vHash;
  Result.PrevHash := vPrevHash;
  Result.Height := 123;
  Result.AccountAddress := vAccountAddress1;
  Result.PublicKey := vPrivateKey.PublicKey;
  Result.ToAddress := vAccountAddress2;
  Result.Amount := TBigInt.Create(1000);
  Result.TokenId := ViteTokenId;
  Result.FromBlockHash := vFromBlockHash;
  Result.Data := TEncoding.UTF8.GetBytes('cbcd' + 'ecbc' + 'de' + 'cbcd' + 'ecbc' + 'de' + 'cbcd' + 'ecbc' + 'de' + 'cbcd' + 'ecbc' + 'de');
  Result.Quota := 1;
  Result.Fee := TBigInt.Create(10);
  New(Result.LogHash);
  Result.LogHash^ := vLogHash;
  New(Result.Difficulty);
  Result.Difficulty.SetText('10');
  Result.Nonce := TEncoding.UTF8.GetBytes('test nonce test nonce');
  Result.Signature := vSignature;
end;

procedure TAccountBlockTests.TestComputeHash;
var
  vBlock: TAccountBlock;
  vPrevHash, vFromBlockHash: THash;
  vAddr1, vAddr2: TAddress;
  vPublicKey: TPublicKey;
  vError: Exception;
begin
  vPrevHash := THash.FromHexString('0000000000000000000000000000000000000000000000000000000000000000', vError);
  Assert.IsNull(vError);
  vFromBlockHash := THash.FromHexString('4b4d6cf7d2f0f6ef25f8b63c1e8d58cecbf29bd3b5fb484a9b53060ecea19f34', vError);
  Assert.IsNull(vError);
  vAddr1 := TAddress.FromHexString('vite_afc922b148b3b792ecff2e79fa17255c22f15d43a77dd79f15', vError);
  Assert.IsNull(vError);
  vAddr2 := TAddress.FromHexString('vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a', vError);
  Assert.IsNull(vError);

  SetLength(vPublicKey, 32);
  vPublicKey[0] := 146;
  vPublicKey[1] := 4;
  vPublicKey[2] := 102;
  vPublicKey[3] := 210;
  vPublicKey[4] := 240;
  vPublicKey[5] := 121;
  vPublicKey[6] := 18;
  vPublicKey[7] := 183;
  vPublicKey[8] := 101;
  vPublicKey[9] := 145;
  vPublicKey[10] := 74;
  vPublicKey[11] := 10;
  vPublicKey[12] := 42;
  vPublicKey[13] := 214;
  vPublicKey[14] := 120;
  vPublicKey[15] := 193;
  vPublicKey[16] := 131;
  vPublicKey[17] := 136;
  vPublicKey[18] := 161;
  vPublicKey[19] := 22;
  vPublicKey[20] := 13;
  vPublicKey[21] := 13;
  vPublicKey[22] := 167;
  vPublicKey[23] := 76;
  vPublicKey[24] := 142;
  vPublicKey[25] := 211;
  vPublicKey[26] := 246;
  vPublicKey[27] := 186;
  vPublicKey[28] := 111;
  vPublicKey[29] := 200;
  vPublicKey[30] := 217;
  vPublicKey[31] := 69;

  vBlock.BlockType := BlockTypeReceive;
  vBlock.PrevHash := vPrevHash;
  vBlock.Height := 1;
  vBlock.AccountAddress := vAddr1;
  vBlock.PublicKey := vPublicKey;
  vBlock.ToAddress := vAddr2;
  vBlock.FromBlockHash := vFromBlockHash;
  vBlock.Data := [17, 169, 223, 165, 21, 64, 107, 179, 146, 29, 137, 253, 49, 37, 204, 154, 39, 0, 57, 101, 67, 106, 129, 234, 203, 245, 74, 25, 44, 21, 168, 186, 0];

  Assert.AreEqual('57410f8496598113220fd7f8780cedec5f23f13bbe0d4852e1c0e782092b3a46', vBlock.ComputeHash.ToString);
end;

end.
