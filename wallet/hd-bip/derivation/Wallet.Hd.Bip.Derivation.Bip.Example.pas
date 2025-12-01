unit Wallet.Hd_Bip.Derivation.Bip_Example;

interface

uses
  SysUtils, Classes, bip39;

procedure RandomMnemonic12(const ParaPassphrase: string);
procedure RandomMnemonic24(const ParaPassphrase: string);
procedure Menmonic(const ParaEntropy: TBytes; const ParaPassphrase: string);

implementation

uses
  System.SysConst, System.Character, GoToDelphi.Helpers.TChannel,
  common.log, common.hexutil, wallet.hd_bip.derivation;

procedure RandomMnemonic12(const ParaPassphrase: string);
var
  vEntropy: TBytes;
  vErr: Except;
begin
  Writeln('RandomMnemonic12:');
  vEntropy := TBip39.NewEntropy(128, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Menmonic(vEntropy, ParaPassphrase);
end;

procedure RandomMnemonic24(const ParaPassphrase: string);
var
  vEntropy: TBytes;
  vErr: Except;
begin
  Writeln('RandomMnemonic24:');
  vEntropy := TBip39.NewEntropy(256, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Menmonic(vEntropy, ParaPassphrase);
end;

procedure Menmonic(const ParaEntropy: TBytes; const ParaPassphrase: string);
var
  vMnemonic: string;
  vSeed: TBytes;
  vKey: TDerivationKey;
  vErr: Except;
  vIndex: integer;
  vPath: string;
  vK: TDerivationKey;
  vSeedHex, vAddress: string;
begin
  vMnemonic := TBip39.NewMnemonic(ParaEntropy, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Writeln(vMnemonic);

  Writeln('entropy');
  Writeln(THexUtil.BytesToHex(ParaEntropy));

  if ParaPassphrase <> '' then
  begin
    Writeln('passphrase:');
    Writeln(ParaPassphrase);
  end;
  vSeed := TBip39.NewSeed(vMnemonic, ParaPassphrase);
  Writeln('Seed hex:');
  Writeln(THexUtil.BytesToHex(vSeed));

  vKey := TDerivation.NewMasterKey(vSeed, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  Writeln('primary key hex:');
  Writeln(THexUtil.BytesToHex(vKey.Key));

  Writeln('Accounts:');
  for vIndex := 0 to 9 do
  begin
    vPath := Format(ViteAccountPathFormat, [vIndex]);
    vK := TDerivation.DeriveForPath(vPath, vSeed, vErr);
    if vErr <> nil then
    begin
      raise vErr;
    end;
    vErr := vK.StringPair(vSeedHex, vAddress);
    if vErr <> nil then
    begin
      raise vErr;
    end;
    Writeln(vPath, ' ', vSeedHex, ' ' + vAddress);
  end;
end;

end.
