unit Crypto.Ed25519.Ed25519;

interface

uses
  Crypto.Crypto,
  Crypto.Crypto.Test,
  Crypto.Ed25519.Ed25519,
  Crypto.Ed25519.Ed25519.Test,
  Crypto.Ed25519.Internal.Edwards25519,
  Crypto.Ed25519.Internal.Edwards25519.Const,
  Crypto.Ed25519.Internal.Edwards25519.Edwards25519,
  Crypto.Hash,
  Crypto.Hast.Test,
  DECHash,
  DECKeys,
  System.Classes,
  System.SysUtils;

const
  PublicKeySize = 32;
  PrivateKeySize = 64;
  SignatureSize = 64;
  X25519SkSize = 32;
  dummyMessage = 'vite is best';

type
  TPublicKey = TBytes;
  TPrivateKey = TBytes;

  TEd25519 = class
  public
    class function GenerateKey(const ParaReader: TStream): TPrivateKey;
    class function GenerateKeyFromD(const ParaD: TBytes): TPrivateKey;
    class function Sign(const ParaPrivateKey: TPrivateKey; const ParaMessage: TBytes): TBytes;
    class function Verify(const ParaPublicKey: TPublicKey; const ParaMessage, ParaSignature: TBytes): Boolean;
    class function VerifySig(const ParaPublicKey: TPublicKey; const ParaMessage, ParaSignature: TBytes): Boolean;
    class function ToX25519Pk(const ParaPublicKey: TPublicKey): TBytes;
    class function ToX25519Sk(const ParaPrivateKey: TPrivateKey): TBytes;
    class function IsValidPrivateKey(const ParaPrivateKey: TPrivateKey): Boolean;
    class function HexToPublicKey(const ParaHexStr: string): TPublicKey;
    class function HexToPrivateKey(const ParaHexStr: string): TPrivateKey;
  end;

implementation

{ TEd25519 }

class function TEd25519.GenerateKey(const ParaReader: TStream): TPrivateKey;
var
  vRandD: TBytes;
begin
  SetLength(vRandD, 32);
  ParaReader.Read(vRandD, 32);
  Result := GenerateKeyFromD(vRandD);
end;

class function TEd25519.GenerateKeyFromD(const ParaD: TBytes): TPrivateKey;
var
  vPrivateKey: TPrivateKey;
  vPublicKey: TPublicKey;
  vDigest: TBytes;
  vA: TExtendedGroupElement;
  vhBytes: TBytes;
  vPublicKeyBytes: TBytes;
  vHasher: THash_Blake2b_512;
begin
  SetLength(vPrivateKey, PrivateKeySize);
  System.Move(ParaD[0], vPrivateKey[0], 32);

  SetLength(vPublicKey, PublicKeySize);

  vHasher := THash_Blake2b_512.Create;
  try
    vHasher.Update(Copy(vPrivateKey, 0, 32));
    vDigest := vHasher.Final;
  finally
    vHasher.Free;
  end;

  vDigest[0] := vDigest[0] and 248;
  vDigest[31] := vDigest[31] and 127;
  vDigest[31] := vDigest[31] or 64;

  SetLength(vhBytes, 32);
  System.Move(vDigest[0], vhBytes[0], 32);
  GeScalarMultBase(vA, vhBytes);

  SetLength(vPublicKeyBytes, 32);
  //vA.ToBytes(vPublicKeyBytes); // TODO: Implement ToBytes in TExtendedGroupElement

  System.Move(vPublicKeyBytes[0], vPrivateKey[32], 32);
  System.Move(vPublicKeyBytes[0], vPublicKey[0], 32);

  Result := vPrivateKey;
end;

class function TEd25519.Sign(const ParaPrivateKey: TPrivateKey; const ParaMessage: TBytes): TBytes;
begin
  // TODO: Implement this function
  Result := [];
end;

class function TEd25519.Verify(const ParaPublicKey: TPublicKey; const ParaMessage, ParaSignature: TBytes): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

class function TEd25519.VerifySig(const ParaPublicKey: TPublicKey; const ParaMessage, ParaSignature: TBytes): Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

class function TEd25519.ToX25519Pk(const ParaPublicKey: TPublicKey): TBytes;
begin
  // TODO: Implement this function
  Result := [];
end;

class function TEd25519.ToX25519Sk(const ParaPrivateKey: TPrivateKey): TBytes;
var
  vDigest: TBytes;
  vHasher: THash_Blake2b_512;
begin
  vHasher := THash_Blake2b_512.Create;
  try
    vHasher.Update(Copy(ParaPrivateKey, 0, 32));
    vDigest := vHasher.Final;
  finally
    vHasher.Free;
  end;

  vDigest[0] := vDigest[0] and 248;
  vDigest[31] := vDigest[31] and 127;
  vDigest[31] := vDigest[31] or 64;

  Result := Copy(vDigest, 0, 32);
end;

class function TEd25519.IsValidPrivateKey(const ParaPrivateKey: TPrivateKey): Boolean;
begin
  if Length(ParaPrivateKey) <> PrivateKeySize then
  begin
    Result := False;
    Exit;
  end;

  // TODO: Implement this function
  Result := False;
end;

class function TEd25519.HexToPublicKey(const ParaHexStr: string): TPublicKey;
begin
  Result := TBytes.FromHexString(ParaHexStr);
end;

class function TEd25519.HexToPrivateKey(const ParaHexStr: string): TPrivateKey;
begin
  Result := TBytes.FromHexString(ParaHexStr);
end;

end.
