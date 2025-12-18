unit Vm.MockDb;

interface

uses
  System.DateUtils System.NetEncoding,
  System.SysUtils System.Classes System.Generics.Collections System.Math.BigInteger,
  Vite.Common.Types Vite.Interfaces.Core Vite.Interfaces.Chain Vite.Interfaces.VmDb,
  Vite.Crypto,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TMockIteratorItem = record
    Key: TBytes;
    Value: TBytes;
  end;

  TMockIterator = class(TInterfacedObject, IStorageIterator)
  private
    FIndex: Integer;
    FItems: TArray<TMockIteratorItem>;
  public
    constructor Create(const Items: TArray<TMockIteratorItem>);
    function Next: Boolean;
    function Prev: Boolean;
    function Last: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function Error: Exception;
    procedure Release;
    function Seek(key: TBytes): Boolean;
  end;

  TMockDB = class(TInterfacedObject, IVmDb)
  private
    FCurrentAddr: TAddress;
    FLatestSnapshotBlock: ISnapshotBlock;
    FForkSnapshotBlockMap: TDictionary<UInt64, ISnapshotBlock>;
    FPrevAccountBlock: IAccountBlock;
    FQuotaInfo: TArray<TQuotaInfo>;
    FPledgeBeneficialAmount: TBigInteger;
    FBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
    FBalanceMapOrigin: TDictionary<TTokenTypeId, TBigInteger>;
    FStorageMap: TDictionary<string, string>;
    FStorageMapOrigin: TDictionary<string, string>;
    FContractMetaMap: TDictionary<TAddress, IContractMeta>;
    FContractMetaMapOrigin: TDictionary<TAddress, IContractMeta>;
    FLogList: TList<IVmLog>;
    FCode: TBytes;
    FGenesisBlock: ISnapshotBlock;
    function BytesToString(V: TBytes): string;
    function StringToBytes(V: string): TBytes;
    function HexToBigInteger(const Hex: string; out Value: TBigInteger): Boolean;
    function BytesStartsWith(const A, B: TBytes): Boolean;
    function GetContractMetaMap: TDictionary<TAddress, IContractMeta>;
    function GetStorageMap: TDictionary<string, string>;
  public
    constructor Create(
      Addr: TAddress;
      LatestSnapshotBlock: ISnapshotBlock;
      PrevAccountBlock: IAccountBlock;
      QuotaInfo: TArray<TQuotaInfo>;
      PledgeBeneficialAmount: TBigInteger;
      BalanceMap: TDictionary<TTokenTypeId, string>;
      Storage: TDictionary<string, string>;
      ContractMetaMap: TDictionary<TAddress, IContractMeta>;
      Code: TBytes;
      GenesisTimestamp: Int64;
      SnapshotBlockMap: TDictionary<UInt64, ISnapshotBlock>
    );
    destructor Destroy; override;

    // IVmDb
    function CanWrite: Boolean;
    function Address: TAddress;
    function LatestSnapshotBlock: ISnapshotBlock;
    function PrevAccountBlock: IAccountBlock;
    function GetLatestAccountBlock(addr: TAddress): IAccountBlock;
    function GetCallDepth(sendBlockHash: THash): UInt16;
    function GetQuotaUsedList(addr: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;
    function GetReceiptHash: THash;
    procedure Reset;
    procedure Finish;
    function GetValue(key: TBytes): TBytes;
    function GetOriginalValue(key: TBytes): TBytes;
    procedure SetValue(key, value: TBytes);
    function NewStorageIterator(prefix: TBytes): IStorageIterator;
    function GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
    function GetBalance(tokenTypeId: TTokenTypeId): TBigInteger;
    procedure SetBalance(tokenTypeId: TTokenTypeId; amount: TBigInteger);
    function GetBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
    function GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
    procedure AddLog(log: IVmLog);
    function GetLogList: IVmLogList;
    function GetHistoryLogList(logHash: THash): IVmLogList;
    function GetLogListHash: THash;
    function GetUnconfirmedBlocks(address: TAddress): TArray<IAccountBlock>;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetConfirmSnapshotHeader(blockHash: THash): ISnapshotBlock;
    function GetConfirmedTimes(blockHash: THash): UInt64;
    function GetSnapshotBlockByHeight(height: UInt64): ISnapshotBlock;
    procedure SetContractMeta(toAddr: TAddress; meta: IContractMeta);
    function GetContractMeta: IContractMeta;
    function GetContractMetaInSnapshot(contractAddress: TAddress; snapshotBlock: ISnapshotBlock): IContractMeta;
    procedure SetContractCode(code: TBytes);
    function GetContractCode: TBytes;
    function GetContractCodeBySnapshotBlock(addr: TAddress; snapshotBlock: ISnapshotBlock): TBytes;
    function GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
    function GetUnsavedContractCode: TBytes;
    function GetStakeBeneficialAmount(addr: TAddress): TBigInteger;
    function DebugGetStorage: TDictionary<string, TBytes>;
  end;

implementation

uses System.Generics.Defaults;

{ TMockIterator }

constructor TMockIterator.Create(const Items: TArray<TMockIteratorItem>);
begin
  inherited Create;
  FIndex := -1;
  FItems := Items;
end;

function TMockIterator.Next: Boolean;
begin
  if FIndex < Length(FItems) - 1 then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

function TMockIterator.Prev: Boolean;
begin
  Result := FIndex <= 0;
end;

function TMockIterator.Last: Boolean;
begin
  Result := FIndex = Length(FItems) - 1;
end;

function TMockIterator.Key: TBytes;
begin
  Result := FItems[FIndex].Key;
end;

function TMockIterator.Value: TBytes;
begin
  Result := FItems[FIndex].Value;
end;

function TMockIterator.Error: Exception;
begin
  Result := nil;
end;

procedure TMockIterator.Release;
begin
end;

function TMockIterator.Seek(key: TBytes): Boolean;
var
  i: Integer;
begin
  for i := 0 to Length(FItems) - 1 do
  begin
    if TBytes.Compare(FItems[i].Key, key) = 0 then
    begin
      FIndex := i;
      Exit(True);
    end;
  end;
  Result := False;
end;

{ TMockDB }

constructor TMockDB.Create(
  Addr: TAddress;
  LatestSnapshotBlock: ISnapshotBlock;
  PrevAccountBlock: IAccountBlock;
  QuotaInfo: TArray<TQuotaInfo>;
  PledgeBeneficialAmount: TBigInteger;
  BalanceMap: TDictionary<TTokenTypeId, string>;
  Storage: TDictionary<string, string>;
  ContractMetaMap: TDictionary<TAddress, IContractMeta>;
  Code: TBytes;
  GenesisTimestamp: Int64;
  SnapshotBlockMap: TDictionary<UInt64, ISnapshotBlock>);
var
  Pair: TPair<TTokenTypeId, string>;
  BigAmount: TBigInteger;
  Key: string;
  AddrKey: TAddress;
  GenesisTime: TDateTime;
begin
  inherited Create;
  FCurrentAddr := Addr;
  FLatestSnapshotBlock := LatestSnapshotBlock;
  FPrevAccountBlock := PrevAccountBlock;
  FQuotaInfo := QuotaInfo;
  FPledgeBeneficialAmount := PledgeBeneficialAmount;
  FCode := Code;
  FForkSnapshotBlockMap := SnapshotBlockMap;

  FLogList := TList<IVmLog>.Create;
  FBalanceMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  FStorageMap := TDictionary<string, string>.Create;
  FContractMetaMap := TDictionary<TAddress, IContractMeta>.Create;

  FBalanceMapOrigin := TDictionary<TTokenTypeId, TBigInteger>.Create;
  if BalanceMap <> nil then
  begin
    for Pair in BalanceMap do
    begin
      if not HexToBigInteger(Pair.Value, BigAmount) then
        raise Exception.Create('invalid balance amount ' + Pair.Value);
      FBalanceMapOrigin.Add(Pair.Key, BigAmount);
    end;
  end;

  FStorageMapOrigin := TDictionary<string, string>.Create(Storage);
  FContractMetaMapOrigin := TDictionary<TAddress, IContractMeta>.Create(ContractMetaMap);

  GenesisTime := UnixToDateTime(GenesisTimestamp);
  FGenesisBlock := TSnapshotBlock.Create;
  FGenesisBlock.Height := 1;
  FGenesisBlock.Timestamp := GenesisTime;
end;

destructor TMockDB.Destroy;
begin
  FLogList.Free;
  FBalanceMap.Free;
  FStorageMap.Free;
  FContractMetaMap.Free;
  FBalanceMapOrigin.Free;
  FStorageMapOrigin.Free;
  FContractMetaMapOrigin.Free;
  inherited;
end;

function TMockDB.BytesToString(V: TBytes): string;
begin
  Result := TNetEncoding.Base16.Encode(V);
end;

function TMockDB.StringToBytes(V: string): TBytes;
begin
  Result := TNetEncoding.Base16.Decode(V);
end;

function TMockDB.HexToBigInteger(const Hex: string; out Value: TBigInteger): Boolean;
var
  Bytes: TBytes;
  TempHex: string;
begin
  TempHex := Hex;
  if System.SysUtils.StartsText('0x', TempHex) then
    Delete(TempHex, 1, 2);
  try
    Bytes := TNetEncoding.Base16.Decode(TempHex);
    Value := TBigInteger.FromBytes(Bytes);
    Result := True;
  except
    Result := False;
  end;
end;

function TMockDB.BytesStartsWith(const A, B: TBytes): Boolean;
var
  i: Integer;
begin
  if Length(A) > Length(B) then
    Exit(False);
  for i := 0 to Length(A) - 1 do
    if A[i] <> B[i] then
      Exit(False);
  Result := True;
end;

function TMockDB.CanWrite: Boolean;
begin
  Result := False;
end;

function TMockDB.Address: TAddress;
begin
  Result := FCurrentAddr;
end;

function TMockDB.LatestSnapshotBlock: ISnapshotBlock;
begin
  if FLatestSnapshotBlock = nil then
    raise Exception.Create('latest snapshot block not exist');
  Result := FLatestSnapshotBlock;
end;

function TMockDB.PrevAccountBlock: IAccountBlock;
begin
  Result := FPrevAccountBlock;
end;

function TMockDB.GetLatestAccountBlock(addr: TAddress): IAccountBlock;
begin
  if not addr.Equals(FCurrentAddr) then
    raise Exception.Create('current account address not match');
  Result := FPrevAccountBlock;
end;

function TMockDB.GetCallDepth(sendBlockHash: THash): UInt16;
begin
  Result := 0;
end;

function TMockDB.GetQuotaUsedList(addr: TAddress): TArray<TQuotaInfo>;
begin
  if not addr.Equals(FCurrentAddr) then
    Result := nil
  else
    Result := FQuotaInfo;
end;

function TMockDB.GetGlobalQuota: TQuotaInfo;
begin
  Result := TQuotaInfo.Create(0,0,0);
end;

type
  TMockDBStorageKv = record
    K, V: string;
  end;

function TMockDB.GetReceiptHash: THash;
var
  List: TList<TMockDBStorageKv>;
  Pair: TPair<string, string>;
  Source: TBytes;
  Item: TMockDBStorageKv;
  I: Integer;
begin
  List := TList<TMockDBStorageKv>.Create;
  try
    for Pair in FStorageMap do
    begin
      List.Add(TMockDBStorageKv.Create(Pair.Key, Pair.Value));
    end;

    List.Sort(TComparer<TMockDBStorageKv>.Construct(
      function(const Left, Right: TMockDBStorageKv): Integer
      begin
        Result := CompareStr(Left.K, Right.K);
      end
    ));

    SetLength(Source, 0);
    for Item in List do
    begin
      Source := Concat(Source, StringToBytes(Item.K), StringToBytes(Item.V));
    end;

    if Length(Source) = 0 then
      Result := THash.Empty
    else
      Result := TCrypto.Hash256(Source);
  finally
    List.Free;
  end;
end;

procedure TMockDB.Reset;
begin
  FBalanceMap.Clear;
  FStorageMap.Clear;
  FContractMetaMap.Clear;
  FLogList.Clear;
end;

procedure TMockDB.Finish;
begin
end;

function TMockDB.GetValue(key: TBytes): TBytes;
var
  keyStr: string;
  valStr: string;
begin
  keyStr := BytesToString(key);
  if FStorageMap.TryGetValue(keyStr, valStr) then
    Exit(StringToBytes(valStr));
  if FStorageMapOrigin.TryGetValue(keyStr, valStr) then
    Exit(StringToBytes(valStr));
  Result := nil;
end;

function TMockDB.GetOriginalValue(key: TBytes): TBytes;
var
  valStr: string;
begin
  if FStorageMapOrigin.TryGetValue(BytesToString(key), valStr) then
    Result := StringToBytes(valStr)
  else
    Result := nil;
end;

procedure TMockDB.SetValue(key, value: TBytes);
begin
  FStorageMap.AddOrSetValue(BytesToString(key), BytesToString(value));
end;

function TMockDB.NewStorageIterator(prefix: TBytes): IStorageIterator;
var
  Items: TList<TMockIteratorItem>;
  Pair: TPair<string, string>;
  KeyBytes: TBytes;
begin
  Items := TList<TMockIteratorItem>.Create;
  try
    for Pair in FStorageMap do
    begin
      if Length(Pair.Value) = 0 then Continue;
      KeyBytes := StringToBytes(Pair.Key);
      if (Length(prefix) = 0) or BytesStartsWith(prefix, KeyBytes) then
        Items.Add(TMockIteratorItem(Key: KeyBytes, Value: StringToBytes(Pair.Value)));
    end;

    for Pair in FStorageMapOrigin do
    begin
      if FStorageMap.ContainsKey(Pair.Key) then Continue;
      KeyBytes := StringToBytes(Pair.Key);
      if (Length(prefix) = 0) or BytesStartsWith(prefix, KeyBytes) then
        Items.Add(TMockIteratorItem(Key: KeyBytes, Value: StringToBytes(Pair.Value)));
    end;

    Items.Sort(TComparer<TMockIteratorItem>.Construct(
      function(const Left, Right: TMockIteratorItem): Integer
      begin
        Result := TBytes.Compare(Left.Key, Right.Key);
      end
    ));

    Result := TMockIterator.Create(Items.ToArray);
  finally
    Items.Free;
  end;
end;

function TMockDB.GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
begin
  Result := nil;
end;

function TMockDB.GetBalance(tokenTypeId: TTokenTypeId): TBigInteger;
var
  balance: TBigInteger;
begin
  if FBalanceMap.TryGetValue(tokenTypeId, balance) then
    Exit(balance);
  if FBalanceMapOrigin.TryGetValue(tokenTypeId, balance) then
    Exit(balance);
  Result := TBigInteger.Zero;
end;

procedure TMockDB.SetBalance(tokenTypeId: TTokenTypeId; amount: TBigInteger);
begin
  FBalanceMap.AddOrSetValue(tokenTypeId, amount);
end;

function TMockDB.GetBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
var
  balanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  Pair: TPair<TTokenTypeId, TBigInteger>;
begin
  balanceMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  for Pair in FBalanceMap do
    balanceMap.Add(Pair.Key, Pair.Value);
  for Pair in FBalanceMapOrigin do
    if not balanceMap.ContainsKey(Pair.Key) then
      balanceMap.Add(Pair.Key, Pair.Value);
  Result := balanceMap;
end;

function TMockDB.GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
begin
  Result := nil;
end;

procedure TMockDB.AddLog(log: IVmLog);
begin
  FLogList.Add(log);
end;

function TMockDB.GetLogList: IVmLogList;
begin
  Result := TLogList.Create(FLogList);
end;

function TMockDB.GetHistoryLogList(logHash: THash): IVmLogList;
begin
  Result := nil;
end;

function TMockDB.GetLogListHash: THash;
var
  Source: TBytes;
  log: IVmLog;
  topic: THash;
begin
  if FLogList.Count = 0 then
    Exit(nil);

  SetLength(Source, 0);
  for log in FLogList do
  begin
    for topic in log.Topics do
      Source := Concat(Source, topic.Bytes);
    Source := Concat(Source, log.Data);
  end;
  Result := TCrypto.Hash256(Source);
end;

function TMockDB.GetUnconfirmedBlocks(address: TAddress): TArray<IAccountBlock>;
begin
  Result := nil;
end;

function TMockDB.GetGenesisSnapshotBlock: ISnapshotBlock;
begin
  Result := FGenesisBlock;
end;

function TMockDB.GetSnapshotBlockByHeight(height: UInt64): ISnapshotBlock;
begin
  FForkSnapshotBlockMap.TryGetValue(height, Result);
end;

function TMockDB.GetConfirmSnapshotHeader(blockHash: THash): ISnapshotBlock;
begin
  Result := nil;
end;

function TMockDB.GetConfirmedTimes(blockHash: THash): UInt64;
begin
  Result := 0;
end;

procedure TMockDB.SetContractMeta(toAddr: TAddress; meta: IContractMeta);
begin
  FContractMetaMap.AddOrSetValue(toAddr, meta);
end;

function TMockDB.GetContractMeta: IContractMeta;
var
  meta: IContractMeta;
begin
  meta := TBuiltinContractMeta.GetBuiltinContractMeta(FCurrentAddr);
  if meta <> nil then
    Exit(meta);
  if FContractMetaMap.TryGetValue(FCurrentAddr, meta) then
    Exit(meta);
  if FContractMetaMapOrigin.TryGetValue(FCurrentAddr, meta) then
    Exit(meta);
  Result := nil;
end;

function TMockDB.GetContractMetaInSnapshot(contractAddress: TAddress; snapshotBlock: ISnapshotBlock): IContractMeta;
var
  meta: IContractMeta;
begin
  meta := TBuiltinContractMeta.GetBuiltinContractMeta(contractAddress);
  if meta <> nil then
    Exit(meta);
  if FContractMetaMap.TryGetValue(contractAddress, meta) then
    Exit(meta);
  if FContractMetaMapOrigin.TryGetValue(contractAddress, meta) then
    Exit(meta);
  Result := nil;
end;

function TMockDB.GetContractMetaMap: TDictionary<TAddress, IContractMeta>;
var
  metaMap: TDictionary<TAddress, IContractMeta>;
  Pair: TPair<TAddress, IContractMeta>;
begin
  metaMap := TDictionary<TAddress, IContractMeta>.Create;
  for Pair in FContractMetaMap do
    metaMap.Add(Pair.Key, Pair.Value);
  for Pair in FContractMetaMapOrigin do
    if not metaMap.ContainsKey(Pair.Key) then
      metaMap.Add(Pair.Key, Pair.Value);
  Result := metaMap;
end;

function TMockDB.GetStorageMap: TDictionary<string, string>;
var
  storageMap: TDictionary<string, string>;
  Pair: TPair<string, string>;
begin
  storageMap := TDictionary<string, string>.Create;
  for Pair in FStorageMap do
    storageMap.Add(Pair.Key, Pair.Value);
  for Pair in FStorageMapOrigin do
    if not storageMap.ContainsKey(Pair.Key) then
      storageMap.Add(Pair.Key, Pair.Value);
  Result := storageMap;
end;

procedure TMockDB.SetContractCode(code: TBytes);
begin
  FCode := code;
end;

function TMockDB.GetContractCode: TBytes;
begin
  Result := FCode;
end;

function TMockDB.GetContractCodeBySnapshotBlock(addr: TAddress; snapshotBlock: ISnapshotBlock): TBytes;
begin
  Result := nil;
end;

function TMockDB.GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
begin
  Result := nil;
end;

function TMockDB.GetUnsavedContractCode: TBytes;
begin
  Result := nil;
end;

function TMockDB.GetStakeBeneficialAmount(addr: TAddress): TBigInteger;
begin
  if not addr.Equals(FCurrentAddr) then
    raise Exception.Create('current account address not match');
  Result := FPledgeBeneficialAmount;
end;

function TMockDB.DebugGetStorage: TDictionary<string, TBytes>;
begin
  Result := nil;
end;

end.
