unit VM.Contracts.Dex.Utils;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Interfaces;

const
  PriceBytesLength = 10;

function ComposeOrderId(const ADB: IVmDb; AMarketId: Int32; ASide: Boolean; APrice: string): TBytes;
procedure DeComposeOrderId(const AIdBytes: TBytes; out AMarketId: Int32; out ASide: Boolean; out APrice: TBytes; out ATimestamp: Int64);
function PriceToBytes(APrice: string): TBytes;
function BytesToPrice(APriceBytes: TBytes): string;
function CardinalRateToString(ARawRate: Int32): string;
function RandomBytesFromBytes(const AData, ARecursiveData: TBytes; ABegin, AEnd: Integer): TBytes;
function GetValueFromDb(const ADB: IVmDb; AKey: TBytes): TBytes;
procedure SetValueToDb(const ADB: IVmDb; AKey, AValue: TBytes);
function Uint64ToBytes(AValue: UInt64): TBytes;
function BytesToUint64(ABytes: TBytes): UInt64;
function Uint32ToBytes(AValue: UInt32): TBytes;
function BytesToUint32(ABytes: TBytes): UInt32;
procedure BitwiseNotBytes(var ABytes: TBytes);
function IsOperationValidWithMask(AOperationCode, AMask: Byte): Boolean;

type
  TAmountWithToken = record
    Token: TTokenTypeId;
    Amount: TBigInteger;
    IsTradeToken: Boolean;
  end;

function MapToAmountWithTokens(AMap: TDictionary<TTokenTypeId, TBigInteger>): TArray<TAmountWithToken>;

implementation

uses
  System.Math, System.StrUtils, VM.Contracts.Dex.Storage, VM.Contracts.Dex.Order;

function ComposeOrderId(const ADB: IVmDb; AMarketId: Int32; ASide: Boolean; APrice: string): TBytes;
var
  LPriceBytes: TBytes;
  LTimestamp: Int64;
  LSerialNo: Int32;
begin
  SetLength(Result, OrderIdBytesLength);
  CopyMemory(@Result[0], @Uint32ToBytes(AMarketId)[1], 3);
  if ASide then
    Result[3] := 1
  else
    Result[3] := 0;

  LPriceBytes := PriceToBytes(APrice);
  if not ASide then
    BitwiseNotBytes(LPriceBytes);
  CopyMemory(@Result[4], @LPriceBytes[0], 10);

  LTimestamp := GetTimestampInt64(ADB);
  CopyMemory(@Result[14], @Uint64ToBytes(LTimestamp)[3], 5);

  LSerialNo := NewAndSaveOrderSerialNo(ADB, LTimestamp);
  CopyMemory(@Result[19], @Uint32ToBytes(LSerialNo)[1], 3);
end;

// ... other implementations
procedure DeComposeOrderId(const AIdBytes: TBytes; out AMarketId: Int32; out ASide: Boolean; out APrice: TBytes; out ATimestamp: Int64);
begin
  if Length(AIdBytes) <> OrderIdBytesLength then
    raise Exception.Create('DeComposeOrderIdFailErr');
  //...
end;
//...
end.
