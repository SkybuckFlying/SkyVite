unit Vendor.Golang.Org.X.Crypto.Sha3.XorGeneric;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Crypto.Sha3.Sha3;

procedure XorInGeneric(D: TState; const Buf: TBytes);
procedure CopyOutGeneric(D: TState; var B: TBytes);

implementation

procedure XorInGeneric(D: TState; const Buf: TBytes);
begin
  // Implementation of XORing buffer into state
end;

procedure CopyOutGeneric(D: TState; var B: TBytes);
begin
  // Implementation of copying state to buffer
end;

end.
