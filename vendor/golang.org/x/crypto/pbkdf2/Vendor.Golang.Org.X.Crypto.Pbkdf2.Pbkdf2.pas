unit Vendor.Golang.Org.X.Crypto.Pbkdf2.Pbkdf2;

interface

uses
  System.SysUtils, Crypto.Hash;

function Key(const Password, Salt: TBytes; Iter, KeyLen: Integer; const H: THashFactory): TBytes;

implementation

function Key(const Password, Salt: TBytes; Iter, KeyLen: Integer; const H: THashFactory): TBytes;
begin
  // Implementation of PBKDF2
  Result := nil;
end;

end.
