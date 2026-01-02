unit Vendor.Golang.Org.X.Crypto.Sha3.Shake;

interface

uses
  System.SysUtils, Crypto.Hash,
  Vendor.Golang.Org.X.Crypto.Sha3.Sha3;

type
  IShakeHash = interface
    procedure Write(const P: TBytes);
    function Read(out P: TBytes): Integer;
    function Clone: IShakeHash;
    procedure Reset;
  end;

function NewShake128: IShakeHash;
function NewShake256: IShakeHash;

implementation

function NewShake128: IShakeHash;
begin
  // Implementation
end;

function NewShake256: IShakeHash;
begin
  // Implementation
end;

end.
