unit unit_ed25519_alternative_1;

interface

uses
  SysUtils,
  BLAKE2;

type
  TEd25519 = record
  public
	class procedure ScReduce(var output: TByteArray; input: TByteArray);
	class function GeScalarMultBase(var R: TExtendedGroupElement; k: TByteArray): Boolean;
	class function FeNeg(var X, Y: TFloatElement); overload;
	class function GeDoubleScalarMultVartime(var R: TProjectiveGroupElement; k1, k2: TByteArray; G1, G2: TExtendedGroupElement): Boolean;
  end;

implementation

type
  TExtendedGroupElement = record
    X, Y: TFloatElement;
    T: TFloatElement;
  end;

type
  TFloatElement = array[0..31] of byte;

type
  TProjectiveGroupElement = record
    X, Y, Z: TFloatElement;
  end;

var
  h: TBlake2b;
  publicKeyBytes: TArray<Byte>;
  messageDigest: TArray<Byte>;
  signature: TArray<Byte>;
  R: TExtendedGroupElement;
  s: TArray<Byte>;

function Verify(publicKey: TArray<Byte>; message, sig: TArray<Byte>): Boolean;
begin
  if Length(publicKey) <> 32 then
    raise Exception.Create('Bad public key length');

  if Length(sig) <> 64 or sig[63] and $180 <> 0 then
    Result := False;

  publicKeyBytes := publickey;
  messageDigest := TByteArray(Repeat($00, 64));
  signature := sig;

  h := TBlake2b.Create;
  try
    h.Write(signature);
    h.Write(publicKeyBytes);
    h.Write(message);
    h.Sum(messageDigest);

    R.X := TArray<Byte>(messageDigest[0..31]);
    s := TArray<Byte>(messageDigest[32..63]);

    if not (VerifySig(R, s)) then
      Result := False;

    Dispose(h);
  except
    on E: Exception do
      raise;
  end;
end;

function VerifySig(R, s: TArray<Byte>): Boolean;
var
  A: TExtendedGroupElement;
  hReduced, checkR: TArray<Byte>;
begin
  SetLength(publicKeyBytes, 32);
  Move(s, publicKeyBytes[0], Length(publicKeyBytes));
  if not (A.FromBytes(publicKeyBytes)) then
    Result := False;

  edwards25519.FeNeg(A.X, A.X);
  edwards25519.FeNeg(A.T, A.T);

  h := TBlake2b.Create;
  try
    h.Write(signature);
    h.Write(publicKeyBytes);
    h.Write(message);
    SetLength(digest, 64);
    h.Sum(digest);

    SetLength(hReduced, 32);
    edwards25519.ScReduce(hReduced, digest);

    R.X := TArray<Byte>(hReduced[0..31]);
    s := TArray<Byte>(s);

    if not (edwards25519.ScMinimal(s)) then
      Result := False;

    edwards25519.GeDoubleScalarMultVartime(R, hReduced, A, s);

    SetLength(checkR, 32);
    R.ToBytes(checkR);

    Result := CompareMem(signature[0..31], checkR) = 0;
  except
    on E: Exception do
      raise;
  end;

end.

end.
