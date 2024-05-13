unit unit_ed25519;

{

This is an implementation of the Ed25519 digital signature scheme in Go. The code includes functions for generating and verifying signatures.

Here's a breakdown of the code:

1. `GenerateKeyPair()`: This function generates a random private key and derives the corresponding public key.
2. `Sign()`: This function takes a message, a private key, and returns a signature.
3. `VerifySig()`: This function verifies whether a given signature is valid for a specific message using a public key.

The Ed25519 algorithm uses a combination of cryptographic hash functions (BLAKE2b) and elliptic curve arithmetic to generate the signatures. The code includes implementations of these components:

* `edwards25519` package: This package provides functions for performing elliptic curve operations, such as scalar multiplication and projective coordinates.
* `blake2b`: This package provides a Go implementation of the BLAKE2b cryptographic hash function.

The signing process involves the following steps:

1. Hash the message using BLAKE2b to produce a digest.
2. Derive a reduced digest by applying the Ed25519 scalar multiplication algorithm.
3. Use the private key to compute a signature, which consists of two parts: `R` and `s`. `R` is computed as the result of multiplying the public key with the reduced digest, while `s` is computed using the private key and the message digest.

The verification process involves the following steps:

1. Hash the message using BLAKE2b to produce a digest.
2. Derive a reduced digest by applying the Ed25519 scalar multiplication algorithm.
3. Verify that the signature matches the expected result by comparing it with the computed value of `R`.

Overall, this implementation provides a secure and efficient way to generate and verify digital signatures using the Ed25519 algorithm in Go.

}

interface

const
  PublicKeySize = 32;
  PrivateKeySize = 64;
  SignatureSize = 64;
  X25519SkSize = 32;
  DummyMessage = 'vite is best';

type
  PublicKey = array[0..PublicKeySize - 1] of Byte;
  PrivateKey = array[0..PrivateKeySize - 1] of Byte;

function GenerateKey(rand: TStream): (publicKey: PublicKey; privateKey: PrivateKey; err: Boolean);
function GenerateKeyFromD(d: array[0..31] of Byte): (publicKey: PublicKey; privateKey: PrivateKey; err: Boolean);
function Sign(privateKey: PrivateKey; message: array of Byte): array of Byte;
function Verify(publicKey: PublicKey; message, sig: array of Byte): Boolean;
function VerifySig(publicKey: PublicKey; message, sig: array of Byte): Boolean;

implementation

uses
  SysUtils,
  Blake2b,
  Edwards25519;

function (priv: PrivateKey).Public: PublicKey;
begin
  Result := Copy(priv, 32, PublicKeySize);
end;

function (priv: PrivateKey).ToX25519Sk: array[0..X25519SkSize - 1] of Byte;
var
  digest: THashDigest;
begin
  digest := Blake2b.Blake2bSumBuffer(Copy(priv, 0, 32));
  digest[0] := digest[0] and $F8;
  digest[31] := digest[31] and $7F;
  digest[31] := digest[31] or $40;
  Move(digest[0], Result[0], X25519SkSize);
end;

function (priv: PrivateKey).Hex: string;
begin
  Result := BytesToHex(priv);
end;

function (pub: PublicKey).Hex: string;
begin
  Result := BytesToHex(pub);
end;

function (pub: PublicKey).ToX25519Pk: array[0..31] of Byte;
var
  A: TExtendedGroupElement;
  x, one_minus_y: TFieldElement;
  p32: array[0..31] of Byte;
  s: array[0..31] of Byte;
begin
  Move(pub[0], p32[0], 32);
  A.FromBytes(@p32);

  FeOne(one_minus_y);
  FeSub(one_minus_y, one_minus_y, A.Y);
  FeOne(x);
  FeAdd(x, x, A.Y);
  FeInvert(one_minus_y, one_minus_y);
  FeMul(x, x, one_minus_y);

  FeToBytes(@s, x);
  Move(s[0], Result[0], 32);
end;

function HexToPublicKey(hexstr: string): (pub: PublicKey; err: Boolean);
var
  b: TBytes;
begin
  b := HexToBin(hexstr);
  if Length(b) <> PublicKeySize then
  begin
    err := True;
    Exit;
  end;
  Move(b[0], Result[0], PublicKeySize);
  err := False;
end;

function HexToPrivateKey(hexstr: string): (priv: PrivateKey; err: Boolean);
var
  b: TBytes;
begin
  b := HexToBin(hexstr);
  if Length(b) <> PrivateKeySize then
  begin
    err := True;
    Exit;
  end;
  Move(b[0], Result[0], PrivateKeySize);
  err := False;
end;

function IsValidPrivateKey(priv: PrivateKey): Boolean;
var
  pub: PublicKey;
  msg, sig: TBytes;
begin
  if Length(priv) <> PrivateKeySize then
    Exit(False);

  pub := priv.Public;
  msg := BytesOf(DummyMessage);
  sig := Sign(priv, msg);
  Result := Verify(pub, msg, sig);
end;

procedure (priv: PrivateKey).Clear;
var
  i: Integer;
begin
  for i := 0 to Length(priv) - 1 do
    priv[i] := 0;
end;

function (priv: PrivateKey).Sign(rand: TStream; message: array of Byte; opts: TSignerOpts): (signature: array of Byte; err: Boolean);
begin
  if opts.HashFunc <> 0 then
  begin
    err := True;
    Exit('ed25519: cannot sign hashed message');
  end;

  Result.signature := Sign(priv, message);
  err := False;
end;

function GenerateKey(rand: TStream): (publicKey: PublicKey; privateKey: PrivateKey; err: Boolean);
var
  randD: array[0..31] of Byte;
begin
  if rand = nil then
    rand := TRandom.Create;

  if rand.Read(randD, 32) <> 32 then
  begin
    err := True;
    Exit;
  end;

  Result := GenerateKeyFromD(randD);
  err := False;
end;

function GenerateKeyFromD(d: array[0..31] of Byte): (publicKey: PublicKey; privateKey: PrivateKey; err: Boolean);
var
  digest: THashDigest;
  A: TExtendedGroupElement;
  hBytes: array[0..31] of Byte;
  publicKeyBytes: array[0..31] of Byte;
begin
  Move(d[0], privateKey[0], 32);

  digest := Blake2b.Blake2bSumBuffer(privateKey);
  digest[0] := digest[0] and $F8;
  digest[31] := digest[31] and $7F;
  digest[31] := digest[31] or $40;
  Move(digest[0], hBytes[0], 32);

  GeScalarMultBase(A, @hBytes);
  A.ToBytes(@publicKeyBytes);

  Move(publicKeyBytes[0], privateKey[32], 32);
  Move(publicKeyBytes[0], publicKey[0], 32);
  err := False;
end;

function Sign(privateKey: PrivateKey; message: array of Byte): array of Byte;
var
  h: TBlake2bHash;
  digest1, messageDigest, hramDigest: THashDigest;
  expandedSecretKey: array[0..31] of Byte;
  messageDigestReduced, hramDigestReduced: array[0..31] of Byte;
  R: TExtendedGroupElement;
  encodedR: array[0..31] of Byte;
  s: array[0..31] of Byte;
  signature: array[0..SignatureSize - 1] of Byte;
begin
  if Length(privateKey) <> PrivateKeySize then
    raise Exception.Create('ed25519: bad private key length: ' + IntToStr(Length(privateKey)));

  h := TBlake2bHash.Create(512);
  try
    h.Update(privateKey, 32);
    h.Final(digest1);
    Move(digest1[0], expandedSecretKey[0], 32);
    expandedSecretKey[0] := expandedSecretKey[0] and $F8;
    expandedSecretKey[31] := expandedSecretKey[31] and $3F;
    expandedSecretKey[31] := expandedSecretKey[31] or $40;

    h.Init;
    h.Update(@digest1[32], 32);
    h.Update(message, Length(message));
    h.Final(messageDigest);

    ScReduce(messageDigestReduced, @messageDigest);
    GeScalarMultBase(R, @messageDigestReduced);

    R.ToBytes(@encodedR);

    h.Init;
    h.Update(encodedR, 32);
    h.Update(@privateKey[32], 32);
    h.Update(message, Length(message));
    h.Final(hramDigest);

    ScReduce(hramDigestReduced, @hramDigest);

    ScMulAdd(s, hramDigestReduced, expandedSecretKey, messageDigestReduced);

    Move(encodedR[0], signature[0], 32);
	Move(s[0], signature[32], 32);
    Result := signature;
  finally
    h.Free;
  end;
end;

function Verify(publicKey: PublicKey; message, sig: array of Byte): Boolean;
var
  h: TBlake2bHash;
  A: TExtendedGroupElement;
  publicKeyBytes: array[0..31] of Byte;
  digest: THashDigest;
  hReduced: array[0..31] of Byte;
  R: TProjectiveGroupElement;
  s: array[0..31] of Byte;
  checkR: array[0..31] of Byte;
begin
  if Length(publicKey) <> PublicKeySize then
    raise Exception.Create('ed25519: bad public key length: ' + IntToStr(Length(publicKey)));

  if (Length(sig) <> SignatureSize) or (sig[63] and $E0 <> 0) then
    Exit(False);

  Move(publicKey[0], publicKeyBytes[0], 32);
  if not A.FromBytes(@publicKeyBytes) then
    Exit(False);
  FeNeg(A.X, A.X);
  FeNeg(A.T, A.T);

  h := TBlake2bHash.Create(512);
  try
    h.Update(sig, 32);
    h.Update(publicKey, 32);
    h.Update(message, Length(message));
    h.Final(digest);

    ScReduce(hReduced, @digest);

    Move(sig[32], s[0], 32);
    if not ScMinimal(@s) then
      Exit(False);

    GeDoubleScalarMultVartime(R, hReduced, A, s);

    R.ToBytes(@checkR);
    Result := CompareMem(@sig[0], @checkR[0], 32);
  finally
    h.Free;
  end;
end;

function VerifySig(publicKey: PublicKey; message, sig: array of Byte): Boolean;
var
  h: TBlake2bHash;
  A: TExtendedGroupElement;
  publicKeyBytes: array[0..31] of Byte;
  digest: THashDigest;
  hReduced: array[0..31] of Byte;
  R: TProjectiveGroupElement;
  s: array[0..31] of Byte;
  checkR: array[0..31] of Byte;
begin
  if Length(publicKey) <> PublicKeySize then
    Exit(False);

  if (Length(sig) <> SignatureSize) or (sig[63] and $E0 <> 0) then
    Exit(False);

  Move(publicKey[0], publicKeyBytes[0], 32);
  if not A.FromBytes(@publicKeyBytes) then
    Exit(False);
  FeNeg(A.X, A.X);
  FeNeg(A.T, A.T);

  h := TBlake2bHash.Create(512);
  try
    h.Update(sig, 32);
    h.Update(publicKey, 32);
    h.Update(message, Length(message));
    h.Final(digest);

    ScReduce(hReduced, @digest);

    Move(sig[32], s[0], 32);
    if not ScMinimal(@s) then
      Exit(False);

    GeDoubleScalarMultVartime(R, hReduced, A, s);

    R.ToBytes(@checkR);
    if not CompareMem(@sig[0], @checkR[0], 32) then
      Exit(False);
    Result := True;
  finally
    h.Free;
  end;
end;

end.


