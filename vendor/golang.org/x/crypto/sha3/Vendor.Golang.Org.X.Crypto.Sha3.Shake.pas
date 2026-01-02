unit Vendor.Golang.Org.X.Crypto.Sha3.Shake;

interface

uses
  System.SysUtils, System.Classes;

type
  IShakeHash = interface
    procedure Write(const B: TBytes);
    procedure Read(var B: TBytes);
    function Clone: IShakeHash;
    procedure Reset;
  end;

function NewShake128: IShakeHash;
function NewShake256: IShakeHash;

implementation

function NewShake128: IShakeHash;
begin
  // Result := TState.Create(...)
  Result := nil;
end;

function NewShake256: IShakeHash;
begin
  Result := nil;
end;

end.
