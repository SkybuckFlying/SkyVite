unit Ledger.Chain.Utils.Keys_State_Db;

interface

uses
  Common.Bytes,
  Common.Types,
  Ledger.Chain.Utils.Conversion,
  Ledger.Chain.Utils.Generate.Key,
  Ledger.Chain.Utils.Generate.Key.Test,
  Ledger.Chain.Utils.Key.Prefix,
  Ledger.Chain.Utils.Keys,
  Ledger.Chain.Utils.Keys.Index.DB,
  Ledger.Chain.Utils.Keys.State.Redo.DB,
  System.SysUtils;

type
  TStorageKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + THash.Size + 1;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    procedure KeyRefill(real: TStorageRealKey);
    procedure StorageKeyRefill(bytes: TBytes);
    procedure KeyLenRefill(len: integer);
    class function New: TStorageKey;
  end;

  TStorageHistoryKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + THash.Size + 1 + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    class function Construct(bytes: TBytes): TStorageHistoryKey;
    procedure AddressRefill(addr: TAddress);
    procedure KeyRefill(real: TStorageRealKey);
    procedure HeightRefill(height: uint64);
    function ExtraKeyAndLen: TBytes;
    function ExtraAddress: TAddress;
    function ExtraHeight: uint64;
    class function New: TStorageHistoryKey;
  end;

  TBalanceKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + TTokenTypeId.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    procedure TokenIdRefill(tokenId: TTokenTypeId);
    class function New: TBalanceKey;
  end;

  TBalanceHistoryKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + TTokenTypeId.Size + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    class function Construct(bytes: TBytes): TBalanceHistoryKey;
    procedure AddressRefill(addr: TAddress);
    procedure TokenIdRefill(tokenId: TTokenTypeId);
    procedure HeightRefill(height: uint64);
    function EqualAddressAndTokenId(addr: TAddress; tokenId: TTokenTypeId): boolean;
    function ExtraTokenId: TTokenTypeId;
    function ExtraHeight: uint64;
    class function New: TBalanceHistoryKey;
  end;

  TCodeKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    class function New: TCodeKey;
  end;

  TContractMetaKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    class function New: TContractMetaKey;
  end;

  TGidContractKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TGid.Size + TAddress.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure GidRefill(gid: TGid);
    procedure AddressRefill(addr: TAddress);
    class function New: TGidContractKey;
  end;

  TVmLogListKey = record
  private
    FBytes: TBytes;
    const Size = 1 + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HashRefill(hash: THash);
    class function New: TVmLogListKey;
  end;

  TCallDepthKey = record
  private
    FBytes: TBytes;
    const Size = 1 + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HashRefill(hash: THash);
    class function New: TCallDepthKey;
  end;

implementation

uses
  System.Types,
  System.NetEncoding,
  System.SysConst,
  System.RTLConsts,
  System.ConvUtils,
  System.VarUtils,
  System.Variants,
  System.Math,
  System.SyncObjs,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Ansistrings,
  System.Encoding,
  GoToDelphi.Helpers.BigInt;

procedure Uint64Put(var bytes: TBytes; height: uint64);
var
  LBytes: TBytes;
begin
  LBytes := TBitConverter.GetBytes(height);
  if TBitConverter.IsLittleEndian then
    TArray.Reverse<byte>(LBytes);
  Move(LBytes[0], bytes[0], 8);
end;

function BytesToUint64(bytes: TBytes): uint64;
var
  LBytes: TBytes;
begin
  LBytes := bytes;
  if TBitConverter.IsLittleEndian then
    TArray.Reverse<byte>(LBytes);
  Result := TBitConverter.ToUInt64(LBytes, 0);
end;

{ TStorageKey }

class function TStorageKey.New: TStorageKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TStorageKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TStorageKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TStorageKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TStorageKey.KeyRefill(real: TStorageRealKey);
var
  PaddedBytes: TBytes;
begin
  PaddedBytes := RightPadBytes(real.Extra, THash.Size);
  Move(PaddedBytes[0], Self.FBytes[1 + TAddress.Size], THash.Size);
  Self.FBytes[1 + TAddress.Size + THash.Size] := real.GetLen;
end;

procedure TStorageKey.StorageKeyRefill(bytes: TBytes);
var
  PaddedBytes: TBytes;
begin
  PaddedBytes := RightPadBytes(bytes, THash.Size);
  Move(PaddedBytes[0], Self.FBytes[1 + TAddress.Size], THash.Size);
end;

procedure TStorageKey.KeyLenRefill(len: integer);
begin
  Self.FBytes[1 + TAddress.Size + THash.Size] := byte(len);
end;

{ TStorageHistoryKey }

class function TStorageHistoryKey.New: TStorageHistoryKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TStorageHistoryKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TStorageHistoryKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

class function TStorageHistoryKey.Construct(bytes: TBytes): TStorageHistoryKey;
begin
  if Length(bytes) <> Size then
    Exit; // Or raise an exception
  SetLength(Result.FBytes, Size);
  Move(bytes[0], Result.FBytes[0], Size);
end;

procedure TStorageHistoryKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TStorageHistoryKey.KeyRefill(real: TStorageRealKey);
var
  PaddedBytes: TBytes;
begin
  PaddedBytes := RightPadBytes(real.Extra, THash.Size);
  Move(PaddedBytes[0], Self.FBytes[1 + TAddress.Size], THash.Size);
  Self.FBytes[1 + TAddress.Size + THash.Size] := real.GetLen;
end;

procedure TStorageHistoryKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1 + TAddress.Size + THash.Size + 1], 8);
end;

function TStorageHistoryKey.ExtraKeyAndLen: TBytes;
begin
  SetLength(Result, THash.Size + 1);
  Move(Self.FBytes[1 + TAddress.Size], Result[0], THash.Size + 1);
end;

function TStorageHistoryKey.ExtraAddress: TAddress;
begin
  Result := TAddress.FromBytes(Copy(Self.FBytes, 1, TAddress.Size));
end;

function TStorageHistoryKey.ExtraHeight: uint64;
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Move(Self.FBytes[1 + TAddress.Size + THash.Size + 1], LTempBytes[0], 8);
  Result := BytesToUint64(LTempBytes);
end;

{ TBalanceKey }

class function TBalanceKey.New: TBalanceKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TBalanceKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TBalanceKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TBalanceKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TBalanceKey.TokenIdRefill(tokenId: TTokenTypeId);
begin
  Move(tokenId.Bytes[0], Self.FBytes[1 + TAddress.Size], TTokenTypeId.Size);
end;

{ TBalanceHistoryKey }

class function TBalanceHistoryKey.New: TBalanceHistoryKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TBalanceHistoryKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TBalanceHistoryKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

class function TBalanceHistoryKey.Construct(bytes: TBytes): TBalanceHistoryKey;
begin
  if Length(bytes) <> Size then
    Exit; // Or raise an exception
  SetLength(Result.FBytes, Size);
  Move(bytes[0], Result.FBytes[0], Size);
end;

procedure TBalanceHistoryKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TBalanceHistoryKey.TokenIdRefill(tokenId: TTokenTypeId);
begin
  Move(tokenId.Bytes[0], Self.FBytes[1 + TAddress.Size], TTokenTypeId.Size);
end;

procedure TBalanceHistoryKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1 + TAddress.Size + TTokenTypeId.Size], 8);
end;

function TBalanceHistoryKey.EqualAddressAndTokenId(addr: TAddress; tokenId: TTokenTypeId): boolean;
begin
  Result := CompareMem(Self.FBytes, addr.Bytes, TAddress.Size) and CompareMem(@Self.FBytes[1 + TAddress.Size], tokenId.Bytes, TTokenTypeId.Size);
end;

function TBalanceHistoryKey.ExtraTokenId: TTokenTypeId;
begin
  Result := TTokenTypeId.FromBytes(Copy(Self.FBytes, 1 + TAddress.Size, TTokenTypeId.Size));
end;

function TBalanceHistoryKey.ExtraHeight: uint64;
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Move(Self.FBytes[1 + TAddress.Size + TTokenTypeId.Size], LTempBytes[0], 8);
  Result := BytesToUint64(LTempBytes);
end;

{ TCodeKey }

class function TCodeKey.New: TCodeKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TCodeKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TCodeKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TCodeKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

{ TContractMetaKey }

class function TContractMetaKey.New: TContractMetaKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TContractMetaKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TContractMetaKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TContractMetaKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

{ TGidContractKey }

class function TGidContractKey.New: TGidContractKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TGidContractKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TGidContractKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TGidContractKey.GidRefill(gid: TGid);
begin
  Move(gid.Bytes[0], Self.FBytes[1], TGid.Size);
end;

procedure TGidContractKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1 + TGid.Size], TAddress.Size);
end;

{ TVmLogListKey }

class function TVmLogListKey.New: TVmLogListKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TVmLogListKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TVmLogListKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TVmLogListKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1], THash.Size);
end;

{ TCallDepthKey }

class function TCallDepthKey.New: TCallDepthKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TCallDepthKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TCallDepthKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TCallDepthKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1], THash.Size);
end;

end.
