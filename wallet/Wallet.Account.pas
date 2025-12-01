unit Wallet.Account;

interface

uses
  SysUtils,
  GoToDelphi.Helpers.TBytes,
  Vite.Crypto,
  Vite.Common.Errors,
  Vite.Common.Types,
  Vite.Interfaces,
  Wallet.HD_BIP.Derivation;

type
  TAccount = class(TInterfacedObject, IAccount)
  private
    mAddress: TAddress;
    mPriv: TEd25519PrivateKey;
  public
    constructor Create(const ParaAddress: TAddress; const ParaKey: TDerivationKey);
    class function NewAccountFromHexKey(const ParaHexPriv: string): IAccount; static;
    class function RandomAccount: IAccount; static;
    function Address: TAddress;
    function Sign(const ParaMsg: TBytes; out ParaPub: TEd25519PublicKey): TBytes;
    function Verify(const ParaPub: TEd25519PublicKey; const ParaMessage, ParaSignData: TBytes): Boolean;
    function PrivateKey: TEd25519PrivateKey;
  end;

implementation

uses
  Vite.Crypto.Ed25519,
  Wallet.Wallet;

constructor TAccount.Create(const ParaAddress: TAddress; const ParaKey: TDerivationKey);
var
  vTarget: TAddress;
  vPrivKey: TEd25519PrivateKey;
begin
  vPrivKey := ParaKey.PrivateKey;
  vTarget := TViteTypes.PrikeyToAddress(vPrivKey);
  if not vTarget.Equals(ParaAddress) then
  begin
    raise ENotFound.Create('NotFound');
  end;
  mAddress := ParaAddress;
  mPriv := vPrivKey;
end;

function TAccount.Address: TAddress;
begin
  Result := mAddress;
end;

class function TAccount.NewAccountFromHexKey(const ParaHexPriv: string): IAccount;
var
  vKey: TEd25519PrivateKey;
  vAddress: TAddress;
  vDerivationKey: TDerivationKey;
begin
  vKey := TEd25519.HexToPrivateKey(ParaHexPriv);
  vAddress := TViteTypes.PrikeyToAddress(vKey);
  vDerivationKey := TDerivationKey.Create(vKey);
  Result := TAccount.Create(vAddress, vDerivationKey);
end;

function TAccount.PrivateKey: TEd25519PrivateKey;
begin
  Result := mPriv;
end;

class function TAccount.RandomAccount: IAccount;
var
  vAddr: TAddress;
  vPriv: TEd25519PrivateKey;
  vMnemonic: string;
  vDerivationKey: TDerivationKey;
begin
  TWallet.RandomMnemonic24(vAddr, vPriv, vMnemonic);
  vDerivationKey := TDerivationKey.Create(vPriv);
  Result := TAccount.Create(vAddr, vDerivationKey);
end;

function TAccount.Sign(const ParaMsg: TBytes; out ParaPub: TEd25519PublicKey): TBytes;
begin
  Result := TEd25519.Sign(mPriv, ParaMsg);
  ParaPub := mPriv.PubByte;
end;

function TAccount.Verify(const ParaPub: TEd25519PublicKey; const ParaMessage, ParaSignData: TBytes): Boolean;
begin
  Result := TEd25519.VerifySig(ParaPub, ParaMessage, ParaSignData);
end;

end.
