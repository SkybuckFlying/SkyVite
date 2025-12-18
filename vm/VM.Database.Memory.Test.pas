unit VM.Database.Memory.Test;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Interfaces, GoVite.Ledger;

type
  TMemoryDatabase = class(TInterfacedObject, IVMDatabase)
  private
    FAddr: TAddress;
    FStorage: TDictionary<string, TBytes>;
    FOriginalStorage: TDictionary<string, TBytes>;
    FLogList: TList<TVmLog>;
    FSb: TSnapshotBlock;

    function GetBalanceKey(const ATokenID: TTokenId): string;
    function GetCodeKey(const AAddr: TAddress): string;
  public
    constructor Create(const AAddr: TAddress; ASb: TSnapshotBlock);
    destructor Destroy; override;

    // IVMDatabase implementation
    function GetBalance(const ATokenID: TTokenId): TBigInteger;
    procedure SetBalance(const ATokenID: TTokenId; AAmount: TBigInteger);
    function GetSnapshotBlockByHeight(AHeight: UInt64): TSnapshotBlock;
    procedure Reset;
    procedure Finish;
    procedure SetContractCode(ACode: TBytes);
    function GetContractCode: TBytes;
    function GetContractCodeBySnapshotBlock(const AAddr: TAddress; ASnapshotBlock: TSnapshotBlock): TBytes;
    function GetOriginalValue(AKey: TBytes): TBytes;
    function GetValue(AKey: TBytes): TBytes;
    procedure SetValue(AKey, AValue: TBytes);
    function PrintStorage: string;
    function GetReceiptHash: THash;
    procedure AddLog(ALog: TVmLog);
    function GetLogListHash: THash;
    function GetLogList: TVmLogList;
    function GetHistoryLogList(const ALogHash: THash): TVmLogList;
    function NewStorageIterator(APrefix: TBytes): IStorageIterator;
    function Address: TAddress;
    function LatestSnapshotBlock: TSnapshotBlock;
    function PrevAccountBlock: TAccountBlock;
    function GetGenesisSnapshotBlock: TSnapshotBlock;
    function GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
    function GetUnsavedBalanceMap: TDictionary<TTokenId, TBigInteger>;
    function GetUnsavedContractMeta: TDictionary<TAddress, TContractMeta>;
    function GetUnsavedContractCode: TBytes;
    function GetCallDepth(const AHash: THash): Word;
    procedure SetCallDepth(ADepth: Word);
    function GetUnsavedCallDepth: Word;
    procedure DeleteValue(AKey: TBytes);
  end;

implementation

uses
  System.StrUtils, GoVite.Crypto, GoVite.Encoding;

const
  BALANCE_KEY = '$BALANCE';
  CODE_KEY = '$CODE';

{ TMemoryDatabase }

constructor TMemoryDatabase.Create(const AAddr: TAddress; ASb: TSnapshotBlock);
begin
  FAddr := AAddr;
  FSb := ASb;
  FStorage := TDictionary<string, TBytes>.Create;
  FOriginalStorage := TDictionary<string, TBytes>.Create;
  FLogList := TList<TVmLog>.Create;
end;

destructor TMemoryDatabase.Destroy;
begin
  FStorage.Free;
  FOriginalStorage.Free;
  FLogList.Free;
  inherited;
end;

function TMemoryDatabase.GetBalanceKey(const ATokenID: TTokenId): string;
begin
  Result := BALANCE_KEY + ATokenID.ToString;
end;

function TMemoryDatabase.GetCodeKey(const AAddr: TAddress): string;
begin
  Result := CODE_KEY + AAddr.ToString;
end;

function TMemoryDatabase.GetBalance(const ATokenID: TTokenId): TBigInteger;
var
  LBalanceBytes: TBytes;
begin
  if FStorage.TryGetValue(GetBalanceKey(ATokenID), LBalanceBytes) then
    Result := TBigInteger.FromBytes(LBalanceBytes)
  else
    Result := TBigInteger.Zero;
end;

procedure TMemoryDatabase.SetBalance(const ATokenID: TTokenId; AAmount: TBigInteger);
begin
  if AAmount = nil then
    FStorage.Remove(GetBalanceKey(ATokenID))
  else
    FStorage.AddOrSetValue(GetBalanceKey(ATokenID), AAmount.ToBytes);
end;

function TMemoryDatabase.GetSnapshotBlockByHeight(AHeight: UInt64): TSnapshotBlock;
begin
  Result := nil; // Not implemented in mock
end;

procedure TMemoryDatabase.Reset;
begin
  // No-op
end;

procedure TMemoryDatabase.Finish;
begin
  // No-op
end;

procedure TMemoryDatabase.SetContractCode(ACode: TBytes);
begin
  FStorage.AddOrSetValue(GetCodeKey(FAddr), ACode);
end;

function TMemoryDatabase.GetContractCode: TBytes;
begin
  FStorage.TryGetValue(GetCodeKey(FAddr), Result);
end;

function TMemoryDatabase.GetContractCodeBySnapshotBlock(const AAddr: TAddress; ASnapshotBlock: TSnapshotBlock): TBytes;
begin
  FStorage.TryGetValue(GetCodeKey(AAddr), Result);
end;

function TMemoryDatabase.GetOriginalValue(AKey: TBytes): TBytes;
begin
  FOriginalStorage.TryGetValue(THex.Encode(AKey), Result);
end;

function TMemoryDatabase.GetValue(AKey: TBytes): TBytes;
begin
  FStorage.TryGetValue(THex.Encode(AKey), Result);
end;

procedure TMemoryDatabase.SetValue(AKey, AValue: TBytes);
begin
  if Length(AValue) = 0 then
    FStorage.Remove(THex.Encode(AKey))
  else
    FStorage.AddOrSetValue(THex.Encode(AKey), AValue);
end;

procedure TMemoryDatabase.DeleteValue(AKey: TBytes);
begin
  FStorage.Remove(THex.Encode(AKey));
end;

function TMemoryDatabase.PrintStorage: string;
var
  Pair: TPair<string, TBytes>;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  Builder.Append('[');
  for Pair in FStorage do
  begin
    Builder.Append(Pair.Key + '=>' + THex.Encode(Pair.Value) + ', ');
  end;
  Builder.Append(']');
  Result := Builder.ToString;
  Builder.Free;
end;

function TMemoryDatabase.GetReceiptHash: THash;
begin
  Result := THash.ZERO_HASH;
end;

procedure TMemoryDatabase.AddLog(ALog: TVmLog);
begin
  FLogList.Add(ALog);
end;

function TMemoryDatabase.GetLogListHash: THash;
var
  Source: TBytes;
  VmLog: TVmLog;
  Topic: THash;
begin
  if FLogList.Count = 0 then
    Exit(THash.ZERO_HASH); // Return empty hash, not nil pointer

  Source := [];
  for VmLog in FLogList do
  begin
    for Topic in VmLog.Topics do
      Source := Source + Topic.Bytes;
    Source := Source + VmLog.Data;
  end;

  Result := THash.FromBytes(TCrypto.Hash256(Source));
end;

function TMemoryDatabase.GetLogList: TVmLogList;
begin
  Result := FLogList;
end;

function TMemoryDatabase.GetHistoryLogList(const ALogHash: THash): TVmLogList;
begin
  Result := nil; // Not implemented
end;

function TMemoryDatabase.NewStorageIterator(APrefix: TBytes): IStorageIterator;
begin
  Result := nil; // Not implemented
end;

function TMemoryDatabase.Address: TAddress;
begin
  Result := FAddr;
end;

function TMemoryDatabase.LatestSnapshotBlock: TSnapshotBlock;
begin
  Result := FSb;
end;

function TMemoryDatabase.PrevAccountBlock: TAccountBlock;
begin
  Result := nil; // Not implemented
end;

function TMemoryDatabase.GetGenesisSnapshotBlock: TSnapshotBlock;
begin
  Result := LatestSnapshotBlock;
end;

function TMemoryDatabase.GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>; begin Result := nil; end;
function TMemoryDatabase.GetUnsavedBalanceMap: TDictionary<TTokenId, TBigInteger>; begin Result := nil; end;
function TMemoryDatabase.GetUnsavedContractMeta: TDictionary<TAddress, TContractMeta>; begin Result := nil; end;
function TMemoryDatabase.GetUnsavedContractCode: TBytes; begin Result := nil; end;
function TMemoryDatabase.GetCallDepth(const AHash: THash): Word; begin Result := 0; end;
procedure TMemoryDatabase.SetCallDepth(ADepth: Word); begin end;
function TMemoryDatabase.GetUnsavedCallDepth: Word; begin Result := 0; end;

end.
