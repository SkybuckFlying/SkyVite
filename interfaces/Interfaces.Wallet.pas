unit Interfaces.Wallet;

interface

uses
  SysUtils, Classes,
  Common.Types,
  Crypto.Ed25519;

type
  TSignFunc = reference to function(ParaMsg: TBytes; out ParaSignedData: TBytes; out ParaPub: TPublicKey; out ParaError: Exception): Boolean;
  TVerifyFunc = reference to function(ParaPub: TPublicKey; ParaMessage, ParaSigndata: TBytes): Exception;

  IAccount = interface(IInterface)
    ['{E2F7F7F7-7F7F-7F7F-C7F7-7F7F7F7F7F7F}']
    function Address: TAddress;
    function Sign(ParaMsg: TBytes; out ParaSignData: TBytes; out ParaPub: TPublicKey; out ParaError: Exception): Boolean;
    function Verify(ParaPub: TPublicKey; ParaMessage, ParaSigndata: TBytes): Exception;
  end;

implementation

end.
