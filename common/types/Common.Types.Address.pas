// Copyright 2018 The Vite Authors
// This file is part of the go-vite library.
//
// The go-vite library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-vite library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.

unit Common.Types.Address;

interface

uses
  Common.Bytes,
  Common.HexUtil,
  Common.Types.Address.Test,
  Common.Types.Block.Source,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  Crypto.Ed25519,
  Crypto.Hash,
  System.Math.BigInts,
  System.SysUtils;

const
  ConstAddressPrefix = 'vite_';
  ConstAddressSize = 21;
  ConstAddressCoreSize = 20;
  ConstAddressChecksumSize = 5;
  ConstAddressPrefixLen = Length(ConstAddressPrefix);
  ConstHexAddrCoreLen = 2 * ConstAddressCoreSize;
  ConstHexAddrChecksumLen = 2 * ConstAddressChecksumSize;
  ConstHexAddressLength = ConstAddressPrefixLen + ConstHexAddrCoreLen + ConstHexAddrChecksumLen;

  ConstUserAddrByte = $00;
  ConstContractAddrByte = $01;

type
  TAddressCore = array[0..ConstAddressCoreSize - 1] of Byte;
  TAddressChecksum = array[0..ConstAddressChecksumSize - 1] of Byte;
  TAddress = array[0..ConstAddressSize - 1] of Byte;

  TAddressRec = record
    Address: TAddress;
    PrivateKey: TEd25519PrivateKey;
  end;

  EJsonError = class(Exception);

  TAddressHelper = record helper for TAddress
    function ToHex: string;
    function ToString: string;
    function IsZero: Boolean;
    function ToBytes: TBytes;
    procedure SetBytes(const ParaB: TBytes);
    function Compare(const ParaB: TAddress): Integer;
    procedure UnmarshalJSON(const ParaInput: TBytes);
    function MarshalText: TBytes;
    procedure UnmarshalText(const ParaInput: TBytes);
  end;

var
  AddressQuota, AddressGovernance, AddressAsset, AddressDexFund, AddressDexTrade: TAddress;
  BuiltinContracts, BuiltinContractsWithoutQuota, BuiltinContractsWithSendConfirm: TArray<TAddress>;
  ZERO_ADDRESS: TAddress;
  ErrJsonNotString: EJsonError;

function BytesToAddress(const ParaB: TBytes): TAddress;
function BigToAddress(const ParaB: TBigInteger): TAddress;
function HexToAddress(const ParaHexStr: string): TAddress;
function HexToAddressPanic(const ParaHexStr: string): TAddress;
function IsValidHexAddress(const ParaHexStr: string): Boolean;
function ValidHexAddress(const ParaHexStr: string): TAddress;
function PubkeyToAddress(const ParaPubkey: TEd25519PublicKey): TAddress;
function PrikeyToAddress(const ParaKey: TEd25519PrivateKey): TAddress;
function CreateAddress: TAddressRec;
function CreateContractAddress(const ParaData: array of TBytes): TAddress;
function GenContractAddress(const ParaData: TBytes): TAddress;
function GenUserAddress(const ParaData: TBytes): TAddress;
function CreateAddressWithDeterministic(const ParaD: TBytes32): TAddressRec;

function IsContractAddr(const ParaAddr: TAddress): Boolean;
function IsBuiltinContractAddr(const ParaAddr: TAddress): Boolean;
function IsBuiltinContractAddrInUse(const ParaAddr: TAddress): Boolean;
function IsBuiltinContractAddrInUseWithoutQuota(const ParaAddr: TAddress): Boolean;
function IsBuiltinContractAddrInUseWithSendConfirm(const ParaAddr: TAddress): Boolean;

implementation

uses
  System.StrUtils,
  System.JSON,
  Common.Helper,
  Common.Math.Big;

function getAddrCoreFromHex(const ParaHexStr: string): TAddressCore;
var
  vBytes: TBytes;
begin
  try
    vBytes := THexUtil.Decode(ParaHexStr.Substring(ConstAddressPrefixLen, ConstHexAddrCoreLen));
    if Length(vBytes) <> ConstAddressCoreSize then
    begin
      raise Exception.Create('Invalid core address length');
    end;
    Move(vBytes[0], Result, ConstAddressCoreSize);
  except
    on E: Exception do
      raise Exception.Create('Failed to decode core address from hex: ' + E.Message);
  end;
end;

function getAddressChecksumFromHex(const ParaHexStr: string): TAddressChecksum;
var
  vBytes: TBytes;
begin
  try
    vBytes := THexUtil.Decode(ParaHexStr.Substring(ConstAddressPrefixLen + ConstHexAddrCoreLen));
    if Length(vBytes) <> ConstAddressChecksumSize then
    begin
      raise Exception.Create('Invalid checksum length');
    end;
    Move(vBytes[0], Result, ConstAddressChecksumSize);
  except
    on E: Exception do
      raise Exception.Create('Failed to decode checksum from hex: ' + E.Message);
  end;
end;

function isString(const ParaInput: TBytes): Boolean;
begin
  Result := (Length(ParaInput) >= 2) and (ParaInput[0] = Ord('"')) and (ParaInput[High(ParaInput)] = Ord('"'));
end;

{ TAddressHelper }

function TAddressHelper.ToHex: string;
var
  vCoreAddr: TAddressCore;
  vByte: Byte;
  vHash: TBytes;
begin
  Move(Self[0], vCoreAddr[0], ConstAddressCoreSize);
  vByte := Self[ConstAddressCoreSize];

  if vByte = ConstUserAddrByte then
  begin
    Result := ConstAddressPrefix + THexUtil.Encode(vCoreAddr) + THexUtil.Encode(THash.Hash(ConstAddressChecksumSize, vCoreAddr));
  end
  else if vByte = ConstContractAddrByte then
  begin
    vHash := THash.Hash(ConstAddressChecksumSize, vCoreAddr);
    Result := ConstAddressPrefix + THexUtil.Encode(vCoreAddr) + THexUtil.Encode(THelper.LDI(vHash));
  end
  else
  begin
    Result := Format('error address[%d]', [vByte]);
  end;
end;

function TAddressHelper.ToString: string;
begin
  Result := Self.ToHex;
end;

function TAddressHelper.IsZero: Boolean;
begin
  Result := BytesEqual(Self.ToBytes, ZERO_ADDRESS.ToBytes);
end;

function TAddressHelper.ToBytes: TBytes;
begin
  SetLength(Result, ConstAddressSize);
  Move(Self[0], Result[0], ConstAddressSize);
end;

procedure TAddressHelper.SetBytes(const ParaB: TBytes);
begin
  if Length(ParaB) <> ConstAddressSize then
  begin
    raise Exception.CreateFmt('error address size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Self[0], ConstAddressSize);
end;

function TAddressHelper.Compare(const ParaB: TAddress): Integer;
begin
  Result := CompareMem(@Self, @ParaB, ConstAddressSize);
end;

procedure TAddressHelper.UnmarshalJSON(const ParaInput: TBytes);
var
  vTrimmedInput: TBytes;
  vAddrStr: string;
begin
  if not isString(ParaInput) then
  begin
    raise EJsonError.Create(ErrJsonNotString.Message);
  end;

  try
    SetLength(vTrimmedInput, Length(ParaInput) - 2);
    Move(ParaInput[1], vTrimmedInput[0], Length(vTrimmedInput));
    vAddrStr := TEncoding.UTF8.GetString(vTrimmedInput);
    Self := ValidHexAddress(vAddrStr);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to unmarshal address from JSON: ' + E.Message);
    end;
  end;
end;

function TAddressHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Self.ToString);
end;

procedure TAddressHelper.UnmarshalText(const ParaInput: TBytes);
begin
  Self.UnmarshalJSON(ParaInput);
end;

{ Standalone Functions }

function BytesToAddress(const ParaB: TBytes): TAddress;
begin
  if Length(ParaB) <> ConstAddressSize then
  begin
    raise Exception.CreateFmt('error address size %d', [Length(ParaB)]);
  end;
  Move(ParaB[0], Result[0], ConstAddressSize);
end;

function BigToAddress(const ParaB: TBigInteger): TAddress;
var
  vBytes: TBytes;
begin
  vBytes := TBigMath.PaddedBigBytes(ParaB, ConstAddressSize);
  Result := BytesToAddress(vBytes);
end;

function HexToAddress(const ParaHexStr: string): TAddress;
begin
  Result := ValidHexAddress(ParaHexStr);
end;

function HexToAddressPanic(const ParaHexStr: string): TAddress;
begin
  try
    Result := HexToAddress(ParaHexStr);
  except
    on E: Exception do
    begin
      raise; // Re-raise the exception to mimic panic
    end;
  end;
end;

function IsValidHexAddress(const ParaHexStr: string): Boolean;
begin
  try
    ValidHexAddress(ParaHexStr);
    Result := True;
  except
    Result := False;
  end;
end;

function ValidHexAddress(const ParaHexStr: string): TAddress;
var
  vAddrCore: TAddressCore;
  vAddressChecksum: TAddressChecksum;
  vChecksum: TBytes;
begin
  if (Length(ParaHexStr) <> ConstHexAddressLength) or not System.StrUtils.StartsWith(ParaHexStr, ConstAddressPrefix) then
  begin
    raise Exception.Create('error hex address or prefix');
  end;

  vAddrCore := getAddrCoreFromHex(ParaHexStr);
  vAddressChecksum := getAddressChecksumFromHex(ParaHexStr);

  vChecksum := THash.Hash(ConstAddressChecksumSize, vAddrCore);

  if BytesEqual(vChecksum, vAddressChecksum) then
  begin
    Result := GenUserAddress(vAddrCore);
  end
  else if BytesEqual(vChecksum, THelper.LDI(vAddressChecksum)) then
  begin
    Result := GenContractAddress(vAddrCore);
  end
  else
  begin
    raise Exception.CreateFmt('error address[%s] checksum', [ParaHexStr]);
  end;
end;

function PubkeyToAddress(const ParaPubkey: TEd25519PublicKey): TAddress;
var
  vHash: TBytes;
begin
  vHash := THash.Hash(ConstAddressCoreSize, ParaPubkey);
  Result := GenUserAddress(vHash);
end;

function PrikeyToAddress(const ParaKey: TEd25519PrivateKey): TAddress;
begin
  Result := PubkeyToAddress(ParaKey.PublicKey);
end;

function CreateAddress: TAddressRec;
var
  vPub: TEd25519PublicKey;
begin
  Result.PrivateKey := TEd25519.GenerateKey;
  vPub := Result.PrivateKey.PublicKey;
  Result.Address := PubkeyToAddress(vPub);
end;

function CreateContractAddress(const ParaData: array of TBytes): TAddress;
var
  vCombined, vHashed: TBytes;
  vItem: TBytes;
begin
  vCombined := [];
  for vItem in ParaData do
  begin
    vCombined := vCombined + vItem;
  end;
  vHashed := THash.Hash(ConstAddressCoreSize, vCombined);
  Result := GenContractAddress(vHashed);
end;

function GenContractAddress(const ParaData: TBytes): TAddress;
var
  vAddrBytes: TBytes;
begin
  SetLength(vAddrBytes, ConstAddressSize);
  Move(ParaData[0], vAddrBytes[0], ConstAddressCoreSize);
  vAddrBytes[ConstAddressCoreSize] := ConstContractAddrByte;
  Result := BytesToAddress(vAddrBytes);
end;

function GenUserAddress(const ParaData: TBytes): TAddress;
var
  vAddrBytes: TBytes;
begin
  SetLength(vAddrBytes, ConstAddressSize);
  Move(ParaData[0], vAddrBytes[0], ConstAddressCoreSize);
  vAddrBytes[ConstAddressCoreSize] := ConstUserAddrByte;
  Result := BytesToAddress(vAddrBytes);
end;

function CreateAddressWithDeterministic(const ParaD: TBytes32): TAddressRec;
var
  vPub: TEd25519PublicKey;
begin
  Result.PrivateKey := TEd25519.GenerateKeyFromD(ParaD);
  vPub := Result.PrivateKey.PublicKey;
  Result.Address := PubkeyToAddress(vPub);
end;

function IsContractAddr(const ParaAddr: TAddress): Boolean;
begin
  Result := ParaAddr[ConstAddressSize - 1] = ConstContractAddrByte;
end;

function IsBuiltinContractAddr(const ParaAddr: TAddress): Boolean;
var
  vAddrBytes: TBytes;
begin
  vAddrBytes := ParaAddr.ToBytes;
  Result := IsContractAddr(ParaAddr) and THelper.AllZero(Copy(vAddrBytes, 0, ConstAddressCoreSize - 1)) and (vAddrBytes[ConstAddressCoreSize - 1] <> 0);
end;

function IsBuiltinContractAddrInUse(const ParaAddr: TAddress): Boolean;
var
  vCAddr: TAddress;
begin
  Result := false;
  for vCAddr in BuiltinContracts do
  begin
    if vCAddr.Compare(ParaAddr) = 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function IsBuiltinContractAddrInUseWithoutQuota(const ParaAddr: TAddress): Boolean;
var
  vCAddr: TAddress;
begin
  Result := false;
  for vCAddr in BuiltinContractsWithoutQuota do
  begin
    if vCAddr.Compare(ParaAddr) = 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function IsBuiltinContractAddrInUseWithSendConfirm(const ParaAddr: TAddress): Boolean;
var
  vCAddr: TAddress;
begin
  Result := false;
  for vCAddr in BuiltinContractsWithSendConfirm do
  begin
    if vCAddr.Compare(ParaAddr) = 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

initialization
  AddressQuota := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, ConstContractAddrByte]);
  AddressGovernance := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, ConstContractAddrByte]);
  AddressAsset := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, ConstContractAddrByte]);
  AddressDexFund := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, ConstContractAddrByte]);
  AddressDexTrade := BytesToAddress([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, ConstContractAddrByte]);

  BuiltinContracts := [AddressQuota, AddressGovernance, AddressAsset, AddressDexFund, AddressDexTrade];
  BuiltinContractsWithoutQuota := [AddressQuota, AddressGovernance, AddressAsset, AddressDexTrade];
  BuiltinContractsWithSendConfirm := [AddressQuota, AddressGovernance, AddressAsset];

  FillChar(ZERO_ADDRESS, SizeOf(TAddress), 0);
  ErrJsonNotString := EJsonError.Create('json: not a string');
end.
