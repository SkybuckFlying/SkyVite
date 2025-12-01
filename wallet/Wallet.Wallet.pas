unit Wallet.Wallet;

interface

uses
  SysUtils,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Types,
  Vite.Crypto,
  Wallet.HD_BIP.Derivation;

type
  TWallet = class
  public
    class procedure RandomMnemonic24(out ParaAddr: TAddress; out ParaPriv: TEd25519PrivateKey; out ParaMnemonic: string); static;
    class procedure RandomMnemonic12(out ParaAddr: TAddress; out ParaPriv: TEd25519PrivateKey; out ParaMnemonic: string); static;
  end;

implementation

uses
  BIP39,
  Wallet.HD_BIP.Derivation;

class procedure TWallet.RandomMnemonic24(out ParaAddr: TAddress; out ParaPriv: TEd25519PrivateKey; out ParaMnemonic: string);
var
  vEntropy: TBytes;
begin
  vEntropy := TBIP39.NewEntropy(256);
  ParaMnemonic := TBIP39.NewMnemonic(vEntropy);
  TWallet.NewMnemonic(vEntropy, ParaAddr, ParaPriv, ParaMnemonic);
end;

class procedure TWallet.RandomMnemonic12(out ParaAddr: TAddress; out ParaPriv: TEd25519PrivateKey; out ParaMnemonic: string);
var
  vEntropy: TBytes;
begin
  vEntropy := TBIP39.NewEntropy(128);
  ParaMnemonic := TBIP39.NewMnemonic(vEntropy);
  TWallet.NewMnemonic(vEntropy, ParaAddr, ParaPriv, ParaMnemonic);
end;

class procedure TWallet.NewMnemonic(const ParaEntropy: TBytes; out ParaAddr: TAddress; out ParaPriv: TEd25519PrivateKey; out ParaMnemonic: string);
var
  vSeed: TBytes;
  vKey: TDerivationKey;
begin
  ParaMnemonic := TBIP39.NewMnemonic(ParaEntropy);
  vSeed := TBIP39.NewSeed(ParaMnemonic, '');
  vKey := TDerivation.DeriveWithIndex(0, vSeed);
  ParaAddr := vKey.Address;
  ParaPriv := vKey.PrivateKey;
end;

end.
