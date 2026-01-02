unit Vendor.Golang.Org.X.Crypto.Blake2b.Blake2b;

interface

uses
  System.SysUtils, System.Classes, Crypto.Hash;

const
  // The blocksize of BLAKE2b in bytes.
  BlockSize = 128;
  // The hash size of BLAKE2b-512 in bytes.
  Size = 64;
  // The hash size of BLAKE2b-384 in bytes.
  Size384 = 48;
  // The hash size of BLAKE2b-256 in bytes.
  Size256 = 32;

type
  TDigest = class
  private
    FH: array [0 .. 7] of UInt64;
    FC: array [0 .. 1] of UInt64;
    FSize: Integer;
    FBlock: array [0 .. BlockSize - 1] of Byte;
    FOffset: Integer;
    FKey: array [0 .. BlockSize - 1] of Byte;
    FKeyLen: Integer;

    procedure Finalize(out Hash: TBytes);
  public
    constructor Create(HashSize: Integer; const Key: TBytes);
    procedure Reset;
    procedure Write(const P: TBytes);
    function Sum(const Initial: TBytes): TBytes;
    property DigestSize: Integer read FSize;
  end;

function Sum512(const Data: TBytes): TBytes;
function Sum384(const Data: TBytes): TBytes;
function Sum256(const Data: TBytes): TBytes;

implementation

uses
  Vendor.Golang.Org.X.Crypto.Blake2b.Blake2bGeneric;

var
  IV: array [0 .. 7] of UInt64 = (
    $6A09E667F3BCC908, $BB67AE8584CAA73B, $3C6EF372FE94F82B, $A54FF53A5F1D36F1,
    $510E527FADE682D1, $9B05688C2B3E6C1F, $1F83D9ABFB41BD6B, $5BE0CD19137E2179
  );

{ TDigest }

constructor TDigest.Create(HashSize: Integer; const Key: TBytes);
begin
  if (HashSize < 1) or (HashSize > Size) then
    raise Exception.Create('blake2b: invalid hash size');
  if Length(Key) > Size then
    raise Exception.Create('blake2b: invalid key size');

  FSize := HashSize;
  FKeyLen := Length(Key);
  if FKeyLen > 0 then
    Move(Key[0], FKey[0], FKeyLen);
  Reset;
end;

procedure TDigest.Reset;
begin
  Move(IV[0], FH[0], SizeOf(FH));
  FH[0] := FH[0] xor (UInt64(FSize) or (UInt64(FKeyLen) shl 8) or (1 shl 16) or (1 shl 24));
  FOffset := 0;
  FC[0] := 0;
  FC[1] := 0;
  if FKeyLen > 0 then
  begin
    Move(FKey[0], FBlock[0], BlockSize);
    FOffset := BlockSize;
  end;
end;

procedure TDigest.Write(const P: TBytes);
begin
  // Implementation of hash update
end;

procedure TDigest.Finalize(out Hash: TBytes);
begin
  SetLength(Hash, Size);
  // Implementation of final block hashing
end;

function TDigest.Sum(const Initial: TBytes): TBytes;
var
  Hash: TBytes;
begin
  Finalize(Hash);
  Result := Initial + Copy(Hash, 0, FSize);
end;

function Sum512(const Data: TBytes): TBytes;
var
  D: TDigest;
begin
  D := TDigest.Create(Size, nil);
  try
    D.Write(Data);
    Result := D.Sum(nil);
  finally
    D.Free;
  end;
end;

function Sum384(const Data: TBytes): TBytes;
var
  D: TDigest;
begin
  D := TDigest.Create(Size384, nil);
  try
    D.Write(Data);
    Result := D.Sum(nil);
  finally
    D.Free;
  end;
end;

function Sum256(const Data: TBytes): TBytes;
var
  D: TDigest;
begin
  D := TDigest.Create(Size256, nil);
  try
    D.Write(Data);
    Result := D.Sum(nil);
  finally
    D.Free;
  end;
end;

end.
