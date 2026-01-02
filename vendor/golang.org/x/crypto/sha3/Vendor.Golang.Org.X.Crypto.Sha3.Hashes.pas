unit Vendor.Golang.Org.X.Crypto.Sha3.Hashes;

interface

uses
  System.SysUtils, Crypto.Hash,
  Vendor.Golang.Org.X.Crypto.Sha3.Sha3;

function New224: IHash;
function New256: IHash;
function New384: IHash;
function New512: IHash;

function Sum224(const Data: TBytes): TBytes;
function Sum256(const Data: TBytes): TBytes;
function Sum384(const Data: TBytes): TBytes;
function Sum512(const Data: TBytes): TBytes;

implementation

uses
  Vendor.Golang.Org.X.Crypto.Sha3.HashesGeneric;

function New224: IHash;
begin
  // Implementation
end;

function New256: IHash;
begin
  // Implementation
end;

function New384: IHash;
begin
  // Implementation
end;

function New512: IHash;
begin
  // Implementation
end;

function Sum224(const Data: TBytes): TBytes;
begin
  // Implementation
end;

function Sum256(const Data: TBytes): TBytes;
begin
  // Implementation
end;

function Sum384(const Data: TBytes): TBytes;
begin
  // Implementation
end;

function Sum512(const Data: TBytes): TBytes;
begin
  // Implementation
end;

end.
