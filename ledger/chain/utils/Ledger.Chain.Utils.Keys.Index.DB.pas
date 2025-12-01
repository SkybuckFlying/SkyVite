unit Ledger.Chain.Utils.Keys_Index_Db;

interface

uses
  System.SysUtils,
  Common.Types,
  Ledger.Chain.Utils.Keys;

type
  TAccountBlockHashKey = record
  private
    FBytes: TBytes;
    const Size = 1 + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HashRefill(hash: THash);
    class function New: TAccountBlockHashKey;
  end;

  TAccountBlockHeightKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    procedure HeightRefill(height: uint64);
    class function New: TAccountBlockHeightKey;
  end;

  TReceiveKey = record
  private
    FBytes: TBytes;
    const Size = 1 + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HashRefill(hash: THash);
    class function New: TReceiveKey;
  end;

  TConfirmHeightKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    procedure HeightRefill(height: uint64);
    class function New: TConfirmHeightKey;
  end;

  TOnRoadKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    procedure HashRefill(hash: THash);
    class function New: TOnRoadKey;
  end;

  TOnRoadHeightKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size + TAddress.Size + 8 + THash.Size;
  public
    class function New: TOnRoadHeightKey;
    function Bytes: TBytes;
    function ToString: string;
    function IteratorPrefix(toAddress, fromAddress: TAddress): TBytes;
    procedure ToAddressRefill(addr: TAddress);
    procedure FromAddressRefill(addr: TAddress);
    procedure FromHeightRefill(height: uint64);
    procedure FromHashRefill(hash: THash);
  end;

  TSnapshotBlockHashKey = record
  private
    FBytes: TBytes;
    const Size = 1 + THash.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HashRefill(hash: THash);
    class function New: TSnapshotBlockHashKey;
  end;

  TSnapshotBlockHeightKey = record
  private
    FBytes: TBytes;
    const Size = 1 + 8; // HeightSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure HeightRefill(height: uint64);
    class function New: TSnapshotBlockHeightKey;
  end;

  TAccountAddressKey = record
  private
    FBytes: TBytes;
    const Size = 1 + TAddress.Size;
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AddressRefill(addr: TAddress);
    class function New: TAccountAddressKey;
  end;

  TAccountIdKey = record
  private
    FBytes: TBytes;
    const Size = 1 + 8; // AccountIdSize is 8
  public
    function Bytes: TBytes;
    function ToString: string;
    procedure AccountIdRefill(accountId: uint64);
    class function New: TAccountIdKey;
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

const
  OnRoadAddressHeightKeyPrefix = 1;

procedure Uint64Put(var bytes: TBytes; height: uint64);
var
  LBytes: TBytes;
begin
  LBytes := TBitConverter.GetBytes(height);
  if TBitConverter.IsLittleEndian then
    TArray.Reverse<byte>(LBytes);
  Move(LBytes[0], bytes[0], 8);
end;

{ TAccountBlockHashKey }

class function TAccountBlockHashKey.New: TAccountBlockHashKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TAccountBlockHashKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TAccountBlockHashKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TAccountBlockHashKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1], THash.Size);
end;

{ TAccountBlockHeightKey }

class function TAccountBlockHeightKey.New: TAccountBlockHeightKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TAccountBlockHeightKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TAccountBlockHeightKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TAccountBlockHeightKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TAccountBlockHeightKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1 + TAddress.Size], 8);
end;

{ TReceiveKey }

class function TReceiveKey.New: TReceiveKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TReceiveKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TReceiveKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TReceiveKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1], THash.Size);
end;

{ TConfirmHeightKey }

class function TConfirmHeightKey.New: TConfirmHeightKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TConfirmHeightKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TConfirmHeightKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TConfirmHeightKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TConfirmHeightKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1 + TAddress.Size], 8);
end;

{ TOnRoadKey }

class function TOnRoadKey.New: TOnRoadKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TOnRoadKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TOnRoadKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TOnRoadKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TOnRoadKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1 + TAddress.Size], THash.Size);
end;

{ TOnRoadHeightKey }

class function TOnRoadHeightKey.New: TOnRoadHeightKey;
begin
  SetLength(Result.FBytes, Size);
  Result.FBytes[0] := OnRoadAddressHeightKeyPrefix;
end;

function TOnRoadHeightKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TOnRoadHeightKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

function TOnRoadHeightKey.IteratorPrefix(toAddress, fromAddress: TAddress): TBytes;
begin
  Self.ToAddressRefill(toAddress);
  Self.FromAddressRefill(fromAddress);
  SetLength(Result, 1 + TAddress.Size + TAddress.Size);
  Move(Self.FBytes[0], Result[0], Length(Result));
end;

procedure TOnRoadHeightKey.ToAddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

procedure TOnRoadHeightKey.FromAddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1 + TAddress.Size], TAddress.Size);
end;

procedure TOnRoadHeightKey.FromHeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1 + TAddress.Size + TAddress.Size], 8);
end;

procedure TOnRoadHeightKey.FromHashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1 + TAddress.Size + TAddress.Size + 8], THash.Size);
end;

{ TSnapshotBlockHashKey }

class function TSnapshotBlockHashKey.New: TSnapshotBlockHashKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TSnapshotBlockHashKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TSnapshotBlockHashKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TSnapshotBlockHashKey.HashRefill(hash: THash);
begin
  Move(hash.Bytes[0], Self.FBytes[1], THash.Size);
end;

{ TSnapshotBlockHeightKey }

class function TSnapshotBlockHeightKey.New: TSnapshotBlockHeightKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TSnapshotBlockHeightKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TSnapshotBlockHeightKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TSnapshotBlockHeightKey.HeightRefill(height: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, height);
  Move(LTempBytes[0], Self.FBytes[1], 8);
end;

{ TAccountAddressKey }

class function TAccountAddressKey.New: TAccountAddressKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TAccountAddressKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TAccountAddressKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TAccountAddressKey.AddressRefill(addr: TAddress);
begin
  Move(addr.Bytes[0], Self.FBytes[1], TAddress.Size);
end;

{ TAccountIdKey }

class function TAccountIdKey.New: TAccountIdKey;
begin
  SetLength(Result.FBytes, Size);
end;

function TAccountIdKey.Bytes: TBytes;
begin
  Result := Self.FBytes;
end;

function TAccountIdKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.FBytes);
end;

procedure TAccountIdKey.AccountIdRefill(accountId: uint64);
var
  LTempBytes: TBytes;
begin
  SetLength(LTempBytes, 8);
  Uint64Put(LTempBytes, accountId);
  Move(LTempBytes[0], Self.FBytes[1], 8);
end;

end.
