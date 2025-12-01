unit RpcApi.Api.Utils;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Common, Common.Types, Common.BigInt, Ledger.Chain, Vm.Db, Vm.Abi,
  System.JSON;

var
  Log: ILogger;
  TestApiHexPrivKey: string;
  TestApiTti: string;
  ConvertError: Exception;
  TestApiTestTokenLru: TDictionary<string, string>;
  TestTokenLruLimitSize: Integer;
  DataDir: string;
  NetId: Cardinal;
  DexTxAvailable: Boolean;

procedure InitConfig(Id: Cardinal; ADexAvailable: PBoolean);
procedure InitLog(Dir, Lvl: string);
procedure InitTestAPIParams(Priv, Tti: string);
function StringToBigInt(const Str: string): TBigInteger;
function BigIntToString(const Big: TBigInteger): string;
function Uint64ToString(U: UInt64): string;
function StringToUint64(const S: string): UInt64;
function Float64ToString(F: Double; Prec: Integer): string;
function StringToFloat64(const S: string): Double;
function GetWithdrawTime(SnapshotTime: TDateTime; SnapshotHeight, ExpirationHeight: UInt64): Int64;
procedure GetRange(Index, Count, ListLen: Integer; out Start, &End: Integer);
function GetPrevBlockHash(C: IChain; Addr: TAddress): PHash;
function GetVmDb(C: IChain; Addr: TAddress): IVmDb;
function CheckTxToAddressAvailable(Address: TAddress): Boolean;
function CheckSnapshotValid(LatestSb: PSnapshotBlock): Boolean;
function CheckTokenIdValid(AChain: IChain; TokenId: PTokenTypeId): Boolean;
function Convert(Params: TArray<string>; Arguments: TAbiArguments): TArray<TValue>;
function ConvertOne(Param: string; T: TAbiType): TValue;
function ConvertToArray(Param: string; T: TAbiType): TValue;
function ConvertToBoolArray(Param: string): TValue;
function ConvertToIntArray(Param: string; T: TAbiType): TValue;
function ConvertToUintArray(Param: string; T: TAbiType): TValue;
function ConvertToAddressArray(Param: string): TValue;
function ConvertToTokenIdArray(Param: string): TValue;
function ConvertToGidArray(Param: string): TValue;
function ConvertToStringArray(Param: string): TValue;
function ConvertToBool(Param: string): TValue;
function ConvertToInt(Param: string; Size: Integer): TValue;
function ConvertToUint(Param: string; Size: Integer): TValue;
function ConvertToBytes(Param: string; Size: Integer): TValue;
function ConvertToFixedBytes(Param: string; Size: Integer): TValue;
function ConvertToDynamicBytes(Param: string): TValue;

implementation

uses System.DateUtils, System.StrUtils, System.NetEncoding;

procedure InitConfig(Id: Cardinal; ADexAvailable: PBoolean);
begin
  NetId := Id;
  if (ADexAvailable <> nil) and (ADexAvailable^) then
    DexTxAvailable := ADexAvailable^;
end;

procedure InitLog(Dir, Lvl: string);
begin
  Log.SetHandler(TLogHandler.Create(Dir, 'rpclog', 'rpc.log', Lvl));
end;

procedure InitTestAPIParams(Priv, Tti: string);
begin
  TestApiHexPrivKey := Priv;
  TestApiTti := Tti;
end;

function StringToBigInt(const Str: string): TBigInteger;
begin
  Result := TBigInteger.Create;
  if not Result.SetString(Str, 10) then
    raise ConvertError;
end;

function BigIntToString(const Big: TBigInteger): string;
begin
  if Big = nil then
    Result := ''
  else
    Result := Big.ToString;
end;

function Uint64ToString(U: UInt64): string;
begin
  Result := IntToStr(U);
end;

function StringToUint64(const S: string): UInt64;
begin
  Result := StrToInt(S);
end;

function Float64ToString(F: Double; Prec: Integer): string;
begin
  Result := FloatToStrF(F, ffFixed, 18, Prec);
end;

function StringToFloat64(const S: string): Double;
begin
  Result := StrToFloat(S);
end;

function GetWithdrawTime(SnapshotTime: TDateTime; SnapshotHeight, ExpirationHeight: UInt64): Int64;
const
  SecondBetweenSnapshotBlocks = 1;
begin
  Result := Round(SnapshotTime) + (ExpirationHeight - SnapshotHeight) * SecondBetweenSnapshotBlocks;
end;

procedure GetRange(Index, Count, ListLen: Integer; out Start, &End: Integer);
begin
  Start := Index * Count;
  if Start >= ListLen then
  begin
    Start := ListLen;
    &End := ListLen;
    Exit;
  end;
  &End := Start + Count;
  if &End >= ListLen then
    &End := ListLen;
end;

function GetPrevBlockHash(C: IChain; Addr: TAddress): PHash;
var
  B: PAccountBlock;
begin
  B := C.GetLatestAccountBlock(Addr);
  if B <> nil then
    Result := @B.Hash
  else
    Result := @THash.Zero;
end;

function GetVmDb(C: IChain; Addr: TAddress): IVmDb;
var
  PrevHash: PHash;
begin
  PrevHash := GetPrevBlockHash(C, Addr)^;
  Result := TVmDb.Create(C, @Addr, @C.GetLatestSnapshotBlock.Hash, @PrevHash);
end;

function CheckTxToAddressAvailable(Address: TAddress): Boolean;
begin
  if not DexTxAvailable then
    Result := (Address <> TAddress.DexTrade) and (Address <> TAddress.DexFund)
  else
    Result := True;
end;

function CheckSnapshotValid(LatestSb: PSnapshotBlock): Boolean;
var
  NowTime: TDateTime;
begin
  NowTime := Now;
  if (NowTime < IncMinute(LatestSb.Timestamp, -10)) or (NowTime > IncMinute(LatestSb.Timestamp, 10)) then
    raise Exception.Create('IllegalNodeTime');
  Result := True;
end;

function CheckTokenIdValid(AChain: IChain; TokenId: PTokenTypeId): Boolean;
var
  TkInfo: PTokenInfo;
begin
  if (TokenId <> nil) and (TokenId^ <> TTypes.ZERO_TOKENID) then
  begin
    TkInfo := AChain.GetTokenInfoById(TokenId^);
    if TkInfo = nil then
      raise Exception.Create('tokenId doesn''t exist');
  end;
  Result := True;
end;

function Convert(Params: TArray<string>; Arguments: TAbiArguments): TArray<TValue>;
var
  ResultList: TArray<TValue>;
  I: Integer;
  Argument: TAbiArgument;
  Res: TValue;
begin
  if Length(Params) <> Length(Arguments) then
    raise Exception.Create('argument size not match');
  SetLength(ResultList, Length(Params));
  for I := 0 to High(Arguments) do
  begin
    Argument := Arguments[I];
    Res := ConvertOne(Params[I], Argument.Type);
    ResultList[I] := Res;
  end;
  Result := ResultList;
end;

function ConvertOne(Param: string; T: TAbiType): TValue;
var
  TypeString: string;
begin
  TypeString := T.ToString;
  if Pos('[', TypeString) > 0 then
    Result := ConvertToArray(Param, T)
  else if TypeString = 'bool' then
    Result := ConvertToBool(Param)
  else if StartsText('int', TypeString) then
    Result := ConvertToInt(Param, T.Size)
  else if StartsText('uint', TypeString) then
    Result := ConvertToUint(Param, T.Size)
  else if TypeString = 'address' then
    Result := TValue.From<TAddress>(TAddress.FromHex(Param))
  else if TypeString = 'tokenId' then
    Result := TValue.From<TTokenTypeId>(TTokenTypeId.FromHex(Param))
  else if TypeString = 'gid' then
    Result := TValue.From<TGid>(TGid.FromHex(Param))
  else if TypeString = 'string' then
    Result := Param
  else if TypeString = 'bytes' then
    Result := ConvertToDynamicBytes(Param)
  else if StartsText('bytes', TypeString) then
    Result := ConvertToFixedBytes(Param, T.Size)
  else
    raise Exception.Create('unknown type ' + TypeString);
end;

function ConvertToArray(Param: string; T: TAbiType): TValue;
var
  TypeString: string;
begin
  if T.Elem.Elem <> nil then
    raise Exception.Create(T.ToString + ' type not supported');
  TypeString := T.Elem.ToString;
  if TypeString = 'bool' then
    Result := ConvertToBoolArray(Param)
  else if StartsText('int', TypeString) then
    Result := ConvertToIntArray(Param, T.Elem^)
  else if StartsText('uint', TypeString) then
    Result := ConvertToUintArray(Param, T.Elem^)
  else if TypeString = 'address' then
    Result := ConvertToAddressArray(Param)
  else if TypeString = 'tokenId' then
    Result := ConvertToTokenIdArray(Param)
  else if TypeString = 'gid' then
    Result := ConvertToGidArray(Param)
  else if TypeString = 'string' then
    Result := ConvertToStringArray(Param)
  else
    raise Exception.Create(TypeString + ' array type not supported');
end;

function ConvertToBoolArray(Param: string): TValue;
var
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  I: Integer;
  ResultList: TArray<Boolean>;
begin
  JsonValue := TJSONObject.ParseJSONValue(Param);
  try
    JsonArray := JsonValue as TJSONArray;
    SetLength(ResultList, JsonArray.Count);
    for I := 0 to JsonArray.Count - 1 do
      ResultList[I] := (JsonArray.Items[I] as TJSONBool).AsBoolean;
    Result := TValue.From<TArray<Boolean>>(ResultList);
  finally
    JsonValue.Free;
  end;
end;

function ConvertToIntArray(Param: string; T: TAbiType): TValue;
begin
  // Implementation depends on JSON library and specific integer types
end;

function ConvertToUintArray(Param: string; T: TAbiType): TValue;
begin
  // Implementation depends on JSON library and specific integer types
end;

function ConvertToAddressArray(Param: string): TValue;
var
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  I: Integer;
  ResultList: TArray<TAddress>;
begin
  JsonValue := TJSONObject.ParseJSONValue(Param);
  try
    JsonArray := JsonValue as TJSONArray;
    SetLength(ResultList, JsonArray.Count);
    for I := 0 to JsonArray.Count - 1 do
      ResultList[I] := TAddress.FromHex(JsonArray.Items[I].Value);
    Result := TValue.From<TArray<TAddress>>(ResultList);
  finally
    JsonValue.Free;
  end;
end;

function ConvertToTokenIdArray(Param: string): TValue;
var
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  I: Integer;
  ResultList: TArray<TTokenTypeId>;
begin
  JsonValue := TJSONObject.ParseJSONValue(Param);
  try
    JsonArray := JsonValue as TJSONArray;
    SetLength(ResultList, JsonArray.Count);
    for I := 0 to JsonArray.Count - 1 do
      ResultList[I] := TTokenTypeId.FromHex(JsonArray.Items[I].Value);
    Result := TValue.From<TArray<TTokenTypeId>>(ResultList);
  finally
    JsonValue.Free;
  end;
end;

function ConvertToGidArray(Param: string): TValue;
var
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  I: Integer;
  ResultList: TArray<TGid>;
begin
  JsonValue := TJSONObject.ParseJSONValue(Param);
  try
    JsonArray := JsonValue as TJSONArray;
    SetLength(ResultList, JsonArray.Count);
    for I := 0 to JsonArray.Count - 1 do
      ResultList[I] := TGid.FromHex(JsonArray.Items[I].Value);
    Result := TValue.From<TArray<TGid>>(ResultList);
  finally
    JsonValue.Free;
  end;
end;

function ConvertToStringArray(Param: string): TValue;
var
  JsonValue: TJSONValue;
  JsonArray: TJSONArray;
  I: Integer;
  ResultList: TArray<string>;
begin
  JsonValue := TJSONObject.ParseJSONValue(Param);
  try
    JsonArray := JsonValue as TJSONArray;
    SetLength(ResultList, JsonArray.Count);
    for I := 0 to JsonArray.Count - 1 do
      ResultList[I] := JsonArray.Items[I].Value;
    Result := TValue.From<TArray<string>>(ResultList);
  finally
    JsonValue.Free;
  end;
end;

function ConvertToBool(Param: string): TValue;
begin
  if SameText(Param, 'true') then
    Result := True
  else
    Result := False;
end;

function ConvertToInt(Param: string; Size: Integer): TValue;
var
  BigInt: TBigInteger;
begin
  BigInt := TBigInteger.Create;
  if not BigInt.SetString(Param, 0) or (BigInt.BitLen > Size - 1) then
    raise Exception.Create(Param + ' convert to int failed');
  case Size of
    8: Result := Int8(BigInt.ToInt64);
    16: Result := Int16(BigInt.ToInt64);
    32: Result := Int32(BigInt.ToInt64);
    64: Result := Int64(BigInt.ToInt64);
  else
    Result := TValue.From<TBigInteger>(BigInt);
  end;
end;

function ConvertToUint(Param: string; Size: Integer): TValue;
var
  BigInt: TBigInteger;
begin
  BigInt := TBigInteger.Create;
  if not BigInt.SetString(Param, 0) or (BigInt.BitLen > Size) then
    raise Exception.Create(Param + ' convert to uint failed');
  case Size of
    8: Result := UInt8(BigInt.ToUInt64);
    16: Result := UInt16(BigInt.ToUInt64);
    32: Result := UInt32(BigInt.ToUInt64);
    64: Result := UInt64(BigInt.ToUInt64);
  else
    Result := TValue.From<TBigInteger>(BigInt);
  end;
end;

function ConvertToBytes(Param: string; Size: Integer): TValue;
begin
  if Size = 0 then
    Result := ConvertToDynamicBytes(Param)
  else
    Result := ConvertToFixedBytes(Param, Size);
end;

function ConvertToFixedBytes(Param: string; Size: Integer): TValue;
begin
  if Length(Param) <> Size * 2 then
    raise Exception.Create(Param + ' is not valid bytes');
  Result := TValue.From<TBytes>(THex.Decode(Param));
end;

function ConvertToDynamicBytes(Param: string): TValue;
begin
  Result := TValue.From<TBytes>(THex.Decode(Param));
end;

initialization
  Log := TLog.New('module', 'rpc/api');
  ConvertError := Exception.Create('convert error');
  TestApiTestTokenLru := TDictionary<string, string>.Create;
  TestTokenLruLimitSize := 20;
  DexTxAvailable := False;
end.
