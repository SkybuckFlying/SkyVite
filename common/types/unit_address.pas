unit unit_address;

interface

uses
  SysUtils,
  Classes,
  Crypto,
  Math,
  StrUtils,
  Generics.Collections;

const
  AddressPrefix = 'vite_';
  AddressSize = 21;
  AddressCoreSize = 20;
  addressChecksumSize = 5;
  addressPrefixLen = Length(AddressPrefix);
  hexAddrCoreLen = 2 * AddressCoreSize;
  hexAddrChecksumLen = 2 * addressChecksumSize;
  hexAddressLength = addressPrefixLen + hexAddrCoreLen + hexAddrChecksumLen;

const
  UserAddrByte = Byte(0);
  ContractAddrByte = Byte(1);

var
  AddressQuota, AddressGovernance, AddressAsset, AddressDexFund, AddressDexTrade: TBytes;
  BuiltinContracts, BuiltinContractsWithoutQuota, BuiltinContractsWithSendConfirm: TList<TBytes>;

type
  TAddress = array [0..AddressSize - 1] of Byte;

const
  ZERO_ADDRESS: TAddress = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );

function BytesToAddress(const b: TBytes): TAddress;
function BigToAddress(const b: TBigInteger): TAddress;
function HexToAddress(const hexStr: string): TAddress;
function HexToAddressPanic(const hexstr: string): TAddress;
function IsValidHexAddress(const hexStr: string): Boolean;
function ValidHexAddress(const hexStr: string): TAddress;
function PubkeyToAddress(const pubkey: TBytes): TAddress;
function PrikeyToAddress(const key: TEd25519PrivateKey): TAddress;
function CreateAddress: TAddress;
function CreateContractAddress(const data: TArray<TBytes>): TAddress;
function GenContractAddress(const data: TBytes): TAddress;
function GenUserAddress(const data: TBytes): TAddress;
function CreateAddressWithDeterministic(const d: TBytes): TAddress;
function IsContractAddr(const addr: TAddress): Boolean;
function IsBuiltinContractAddr(const addr: TAddress): Boolean;
function IsBuiltinContractAddrInUse(const addr: TAddress): Boolean;
function IsBuiltinContractAddrInUseWithoutQuota(const addr: TAddress): Boolean;
function IsBuiltinContractAddrInUseWithSendConfirm(const addr: TAddress): Boolean;

implementation

uses
  Vcrypto;

function BytesToAddress(const b: TBytes): TAddress;
var
  a: TAddress;
  i: Integer;
begin
  if Length(b) <> AddressSize then
    raise Exception.Create('Error address size');

  for i := 0 to AddressSize - 1 do
    a[i] := b[i];

  Result := a;
end;

function BigToAddress(const b: TBigInteger): TAddress;
begin
  Result := BytesToAddress(LeftPadBytes(b.ToBytes, AddressSize));
end;

function HexToAddress(const hexStr: string): TAddress;
begin
  Result := ValidHexAddress(hexStr);
end;

function HexToAddressPanic(const hexstr: string): TAddress;
var
  h: TAddress;
  err: Exception;
begin
  try
    h := HexToAddress(hexstr);
  except
    on E: Exception do
    begin
      err := E;
      raise err;
    end;
  end;
  Result := h;
end;

function IsValidHexAddress(const hexStr: string): Boolean;
var
  addr: TAddress;
  err: Exception;
begin
  try
    addr := ValidHexAddress(hexStr);
    Result := True;
  except
    on E: Exception do
    begin
      err := E;
      Result := False;
    end;
  end;
end;

function ValidHexAddress(const hexStr: string): TAddress;
var
  addrCore: TBytes;
  addressChecksum: TBytes;
  checksum: TBytes;
  err: Exception;
begin
  if (Length(hexStr) <> hexAddressLength) or (not StartsWith(hexStr, AddressPrefix)) then
    raise Exception.Create('Error hex address or prefix');

  try
    addrCore := getAddrCoreFromHex(hexStr);
    addressChecksum := getAddressChecksumFromHex(hexStr);
  except
    on E: Exception do
    begin
      err := E;
      raise err;
    end;
  end;

  checksum := Vcrypto.Hash(addressChecksumSize, addrCore);

  if CompareMem(@checksum[0], @addressChecksum[0], addressChecksumSize) then
    Result := GenUserAddress(addrCore)
  else if CompareMem(@checksum[0], @LDI(addressChecksum)[0], addressChecksumSize) then
    Result := GenContractAddress(addrCore)
  else
    raise Exception.CreateFmt('Error address[%s] checksum', [hexStr]);
end;

function PubkeyToAddress(const pubkey: TBytes): TAddress;
var
  hash: TBytes;
  addr: TAddress;
  err: Exception;
begin
  hash := Vcrypto.Hash(AddressCoreSize, pubkey);
  try
    addr := GenUserAddress(hash);
  except
    on E: Exception do
    begin
      err := E;
      raise err;
    end;
  end;
  Result := addr;
end;

function PrikeyToAddress(const key: TEd25519PrivateKey): TAddress;
begin
  Result := PubkeyToAddress(key.PubByte);
end;

function CreateAddress: TAddress;
var
  pub: TBytes;
  pri: TEd25519PrivateKey;
  err: Exception;
begin
  try
    Ed25519.GenerateKey(pub, pri);
  except
    on E: Exception do
    begin
      err := E;
      raise err;
    end;
  end;
  Result := PubkeyToAddress(pub);
end;

function CreateContractAddress(const data: TArray<TBytes>): TAddress;
var
  d: TBytes;
  i: Integer;
begin
  for i := Low(data) to High(data) do
    d := d + data[i];
  Result := BytesToAddress(Vcrypto.Hash(AddressCoreSize, d) + [ContractAddrByte]);
end;

function GenContractAddress(const data: TBytes): TAddress;
var
  addr: TBytes;
begin
  addr := data + [ContractAddrByte];
  Result := BytesToAddress(addr);
end;

function GenUserAddress(const data: TBytes): TAddress;
var
  addr: TBytes;
begin
  addr := data + [UserAddrByte];
  Result := BytesToAddress(addr);
end;

function CreateAddressWithDeterministic(const d: TBytes): TAddress;
var
  pub: TBytes;
  pri: TEd25519PrivateKey;
  err: Exception;
begin
  try
    Ed25519.GenerateKeyFromD(d, pub, pri);
  except
    on E: Exception do
    begin
      err := E;
      raise err;
    end;
  end;
  Result := PubkeyToAddress(pub);
end;

function IsContractAddr(const addr: TAddress): Boolean;
begin
  Result := addr[AddressSize - 1] = ContractAddrByte;
end;

function IsBuiltinContractAddr(const addr: TAddress): Boolean;
var
  addrBytes: TBytes;
  i: Integer;
begin
  addrBytes := addr;
  if IsContractAddr(addr) and AllZero(Copy(addrBytes, 0, AddressCoreSize - 1)) and
     (addrBytes[AddressCoreSize - 1] <> 0) then
    Result := True
  else
    Result := False;
end;

function IsBuiltinContractAddrInUse(const addr: TAddress): Boolean;
var
  cAddr: TBytes;
begin
  Result := False;
  for cAddr in BuiltinContracts do
    if CompareMem(@cAddr[0], @addr[0], AddressSize) then
    begin
      Result := True;
      Break;
    end;
end;

function IsBuiltinContractAddrInUseWithoutQuota(const addr: TAddress): Boolean;
var
  cAddr: TBytes;
begin
  Result := False;
  for cAddr in BuiltinContractsWithoutQuota do
    if CompareMem(@cAddr[0], @addr[0], AddressSize) then
    begin
      Result := True;
      Break;
    end;
end;

function IsBuiltinContractAddrInUseWithSendConfirm(const addr: TAddress): Boolean;
var
  cAddr: TBytes;
begin
  Result := False;
  for cAddr in BuiltinContractsWithSendConfirm do
    if CompareMem(@cAddr[0], @addr[0], AddressSize) then
    begin
      Result := True;
      Break;
    end;
end;

initialization
  AddressQuota := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, ContractAddrByte]);
  AddressGovernance := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, ContractAddrByte]);
  AddressAsset := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, ContractAddrByte]);
  AddressDexFund := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, ContractAddrByte]);
  AddressDexTrade := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, ContractAddrByte]);

  BuiltinContracts := TList<TBytes>.Create;
  BuiltinContracts.Add(AddressQuota);
  BuiltinContracts.Add(AddressGovernance);
  BuiltinContracts.Add(AddressAsset);
  BuiltinContracts.Add(AddressDexFund);
  BuiltinContracts.Add(AddressDexTrade);

  BuiltinContractsWithoutQuota := TList<TBytes>.Create;
  BuiltinContractsWithoutQuota.Add(AddressGovernance);
  BuiltinContractsWithoutQuota.Add(AddressAsset);
  BuiltinContractsWithoutQuota.Add(AddressDexTrade);

  BuiltinContractsWithSendConfirm := TList<TBytes>.Create;
  BuiltinContractsWithSendConfirm.Add(AddressQuota);
  BuiltinContractsWithSendConfirm.Add(AddressGovernance);
  BuiltinContractsWithSendConfirm.Add(AddressAsset);

end.


