unit Ledger.Chain.Utils.Keys;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Types;

type
  TStorageRealKey = record
  private
    mLen: byte;
    mReal: TBytes;
    mCap: integer;
  public
    function Construct(real: TBytes): TStorageRealKey;
    function ConstructFix(all: TBytes): TStorageRealKey;
    function Extra: TBytes;
    function GetLen: byte;
    function ToString: string;
  end;

  IDBKey = interface
    ['{B0422329-3E2D-4A7B-A14F-433495A5B746}']
    function Bytes: TBytes;
    function ToString: string;
  end;

  IDBKeyAddressRefill = interface
    ['{A5A9A86A-287A-4E6D-861E-5A692B4DA20D}']
    procedure AddressRefill(addr: TAddress);
  end;

  IDBKeyHashRefill = interface
    ['{E4B3C2D1-8B7A-4E6F-8F3C-3D1B7A6D2C1B}']
    procedure HashRefill(hash: THash);
  end;

  IDBKeyHeightRefill = interface
    ['{F3C2D1B7-A6D2-4E6F-8F3C-3D1B7A6D2C1B}']
    procedure HeightRefill(height: uint64);
  end;

  IDBKeyRealKeyRefill = interface
    ['{D1B7A6D2-C1B7-4E6F-8F3C-3D1B7A6D2C1B}']
    procedure KeyRefill(real: TStorageRealKey);
  end;

  IDBKeyTokenIdRefill = interface
    ['{B7A6D2C1-B7A6-4E6F-8F3C-3D1B7A6D2C1B}']
    procedure TokenIdRefill(tokenId: TTokenTypeId);
  end;

  IDBKeyStorage = interface(IDBKey, IDBKeyAddressRefill, IDBKeyRealKeyRefill)
    ['{A6D2C1B7-A6D2-4E6F-8F3C-3D1B7A6D2C1B}']
  end;

  IDBKeyBalance = interface(IDBKey, IDBKeyAddressRefill, IDBKeyTokenIdRefill)
    ['{D2C1B7A6-D2C1-4E6F-8F3C-3D1B7A6D2C1B}']
  end;

implementation

uses
  System.Types,
  System.Character,
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


{ TStorageRealKey }

function TStorageRealKey.Construct(real: TBytes): TStorageRealKey;
begin
  if Length(real) > THash.Size then
    raise EArgumentException.Create('error key len');
  Result.mLen := byte(Length(real));
  SetLength(Result.mReal, Result.mLen);
  if Result.mLen > 0 then
    Move(real[0], Result.mReal[0], Result.mLen);
  Result.mCap := THash.Size;
end;

function TStorageRealKey.ConstructFix(all: TBytes): TStorageRealKey;
begin
  if Length(all) <> (THash.Size + 1) then
    raise EArgumentException.Create('error key len');
  Result.mLen := all[Length(all) - 1];
  SetLength(Result.mReal, Result.mLen);
  if Result.mLen > 0 then
    Move(all[0], Result.mReal[0], Result.mLen);
  Result.mCap := THash.Size;
end;

function TStorageRealKey.Extra: TBytes;
begin
  Result := Self.mReal;
end;

function TStorageRealKey.GetLen: byte;
begin
  Result := Self.mLen;
end;

function TStorageRealKey.ToString: string;
begin
  Result := TEncoding.UTF8.GetString(Self.mReal);
end;

end.
