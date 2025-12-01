unit V2.Ledger.Chain.Utils.GenerateKey;

interface

uses
  System.SysUtils,
  V2.Common.Types,
  V2.Crypto;

procedure GenerateKey(out AAddr: TAddress; out APriKey: TBytes);

implementation

procedure GenerateKey(out AAddr: TAddress; out APriKey: TBytes);
var
  LPubKey: TBytes;
  LSuccess: Boolean;
begin
  LSuccess := TCrypto.GenerateKey(APriKey, LPubKey);
  if not LSuccess then
  begin
    // The original Go function returns an error. We'll raise an exception.
    raise Exception.Create('Failed to generate key pair in TCrypto.GenerateKey');
  end;
  AAddr := TCrypto.PubKeyToAddress(LPubKey);
end;

end.
