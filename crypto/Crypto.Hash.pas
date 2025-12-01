unit Crypto.Hash;

interface

uses
  System.SysUtils,
  DECHash;

type
  THash = class
  public
    class function Hash256(const ParaData: array of TBytes): TBytes;
    class function Keccak256(const ParaData: array of TBytes): TBytes;
    class function Hash512(const ParaData: array of TBytes): TBytes;
    class function Hash(const ParaSize: Integer; const ParaData: array of TBytes): TBytes;
  end;

implementation

{ THash }

class function THash.Hash256(const ParaData: array of TBytes): TBytes;
var
  vHasher: THash_Blake2b_256;
  vItem: TBytes;
begin
  vHasher := THash_Blake2b_256.Create;
  try
    for vItem in ParaData do
    begin
      vHasher.Update(vItem);
    end;
    Result := vHasher.Final;
  finally
    vHasher.Free;
  end;
end;

class function THash.Keccak256(const ParaData: array of TBytes): TBytes;
var
  vHasher: THash_Keccak_256;
  vItem: TBytes;
begin
  vHasher := THash_Keccak_256.Create;
  try
    for vItem in ParaData do
    begin
      vHasher.Update(vItem);
    end;
    Result := vHasher.Final;
  finally
    vHasher.Free;
  end;
end;

class function THash.Hash512(const ParaData: array of TBytes): TBytes;
var
  vHasher: THash_Blake2b_512;
  vItem: TBytes;
begin
  vHasher := THash_Blake2b_512.Create;
  try
    for vItem in ParaData do
    begin
      vHasher.Update(vItem);
    end;
    Result := vHasher.Final;
  finally
    vHasher.Free;
  end;
end;

class function THash.Hash(const ParaSize: Integer; const ParaData: array of TBytes): TBytes;
var
  vHasher: THash_Blake2b;
  vItem: TBytes;
begin
  vHasher := THash_Blake2b.Create(ParaSize);
  try
    for vItem in ParaData do
    begin
      vHasher.Update(vItem);
    end;
    Result := vHasher.Final;
  finally
    vHasher.Free;
  end;
end;

end.