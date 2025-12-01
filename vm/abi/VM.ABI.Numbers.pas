unit VM.Abi.Numbers;

interface

uses
  System.SysUtils,
  GoToDelphi.Helpers.BigInt,
  Common.Helper.Common,
  Common.Helper.Math.Big,
  Common.Types.Address,
  Common.Types.Gid,
  Common.Types.TokenTypeId;

function U256(const ParaN: TBigInt): TBytes;

implementation

uses
  System.TypInfo;

var
  BigT: PTypeInfo;
  DerefBigT: PTypeInfo;
  Uint8T: PTypeInfo;
  Uint16T: PTypeInfo;
  Uint32T: PTypeInfo;
  Uint64T: PTypeInfo;
  Int8T: PTypeInfo;
  Int16T: PTypeInfo;
  Int32T: PTypeInfo;
  Int64T: PTypeInfo;
  AddressT: PTypeInfo;
  GidT: PTypeInfo;
  TokenIdT: PTypeInfo;

function U256(const ParaN: TBigInt): TBytes;
begin
  Result := TBigHelper.PaddedBigBytes(TBigHelper.U256(ParaN), WordSize);
end;

initialization
  BigT := TypeInfo(TBigInt);
  DerefBigT := TypeInfo(TBigInt);
  Uint8T := TypeInfo(Byte);
  Uint16T := TypeInfo(Word);
  Uint32T := TypeInfo(LongWord);
  Uint64T := TypeInfo(UInt64);
  Int8T := TypeInfo(ShortInt);
  Int16T := TypeInfo(SmallInt);
  Int32T := TypeInfo(Integer);
  Int64T := TypeInfo(Int64);
  AddressT := TypeInfo(TAddress);
  GidT := TypeInfo(TGid);
  TokenIdT := TypeInfo(TTokenTypeId);
end.