unit Vendor.Golang.Org.X.Crypto.Scrypt.Scrypt;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Crypto.Pbkdf2.Pbkdf2;

function Key(const Password, Salt: TBytes; N, R, P, KeyLen: Integer): TBytes;

implementation

function Key(const Password, Salt: TBytes; N, R, P, KeyLen: Integer): TBytes;
begin
  // Implementation of scrypt
  Result := nil;
end;

end.
