unit Ledger.Onroad.Pool.Storage;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  GoToDelphi.Helpers.LevelDB,
  Common.Types,
  Ledger.Chain.Utils,
  Ledger.Onroad.Pool.Types;

type
  TOnroadTx = record
    mFromAddr: TAddress;
    mToAddr: TAddress;
    mFromHeight: UInt64;
    mFromHash: THash;
    mFromIndex: PUInt32;
    function ToString: string;
    function ToOnroadHeightKey: TOnRoadHeightKey;
    function ToOnroadHeightValue: TBytes;
  end;

  IOnRoadDB = interface
    ['{C4D7E3B2-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    procedure InsertOnroad(ParaTx: TOnroadTx);
    procedure DeleteOnroad(ParaTx: TOnroadTx);
  end;

  IOnroadStorage = interface
    ['{D3E6F2A1-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    procedure InsertOnRoadTx(ParaTx: TOnroadTx);
    procedure DeleteOnRoadTx(ParaTx: TOnroadTx);
    function UpdateFromIndex(ParaTx: TOnroadTx): Boolean;
    function GetAllFirstOnroadTx(ParaAddr: TAddress): TDictionary<TAddress, TArray<TOnroadTx>>;
    function GetFirstOnroadTx(ParaAddr, ParaCaller: TAddress): TArray<TOnroadTx>;
    function GetOnRoadCount(ParaAddr: TAddress): Integer;
  end;

  TOnroadStorage = class(TInterfacedObject, IOnroadStorage)
  private
    FDb: TLevelDB;
    FMu: TCriticalSection;
    FCallers: TDictionary<TAddress, Integer>;
    procedure AddCaller(ParaCaller: TAddress);
    procedure RemoveCaller(ParaCaller: TAddress);
    function GetFirstOnroadTxInternal(ParaAddr, ParaCaller: TAddress): TArray<TOnroadTx>;
  public
    constructor Create(ParaDb: TLevelDB);
    destructor Destroy; override;
    procedure InsertOnRoadTx(ParaTx: TOnroadTx);
    procedure DeleteOnRoadTx(ParaTx: TOnroadTx);
    function UpdateFromIndex(ParaTx: TOnroadTx): Boolean;
    function GetAllFirstOnroadTx(ParaAddr: TAddress): TDictionary<TAddress, TArray<TOnroadTx>>;
    function GetFirstOnroadTx(ParaAddr, ParaCaller: TAddress): TArray<TOnroadTx>;
    function GetOnRoadCount(ParaAddr: TAddress): Integer;
  end;

function NewOnroadTxFromBytes(ParaKey, ParaValue: TBytes): TOnroadTx;
function NewOnroadTxFromOrHashHeight(ParaFromAddr, ParaToAddress: TAddress; ParaOr: TOrHashHeight): TOnroadTx;

implementation

uses
  System.NetEncoding,
  GoToDelphi.Helpers.BigEndian;

function TOnroadTx.ToString: string;
var
  vIi: Int64;
begin
  vIi := -1;
  if mFromIndex <> nil then
    vIi := mFromIndex^;
  Result := Format('fromAddr=%s,toAddr=%s,fromHeight=%d,fromHash=%s,fromIndex=%d',
    [mFromAddr.ToString, mToAddr.ToString, mFromHeight, mFromHash.ToString, vIi]);
end;

function TOnroadTx.ToOnroadHeightKey: TOnRoadHeightKey;
begin
  Result := TOnRoadHeightKey.CreateOnRoadAddressHeightKey(mToAddr, mFromAddr, mFromHeight, mFromHash);
end;

function TOnroadTx.ToOnroadHeightValue: TBytes;
begin
  if mFromIndex = nil then
    Result := []
  else
  begin
    SetLength(Result, 4);
    TBigEndian.PutUint32(Result, mFromIndex^);
  end;
end;

{ TOnroadStorage }

constructor TOnroadStorage.Create(ParaDb: TLevelDB);
begin
  inherited Create;
  FDb := ParaDb;
  InitializeCriticalSection(FMu);
  FCallers := TDictionary<TAddress, Integer>.Create;
end;

destructor TOnroadStorage.Destroy;
begin
  DeleteCriticalSection(FMu);
  FCallers.Free;
  inherited;
end;

procedure TOnroadStorage.AddCaller(ParaCaller: TAddress);
begin
  FCallers.AddOrSetValue(ParaCaller, 0);
end;

procedure TOnroadStorage.RemoveCaller(ParaCaller: TAddress);
begin
  FCallers.Remove(ParaCaller);
end;

procedure TOnroadStorage.InsertOnRoadTx(ParaTx: TOnroadTx);
var
  vKey, vValue: TBytes;
begin
  EnterCriticalSection(FMu);
  try
    AddCaller(ParaTx.mFromAddr);
    vKey := ParaTx.ToOnroadHeightKey.Bytes;
    vValue := ParaTx.ToOnroadHeightValue;
    FDb.Put(vKey, vValue);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

procedure TOnroadStorage.DeleteOnRoadTx(ParaTx: TOnroadTx);
var
  vKey: TBytes;
  vTxs: TArray<TOnroadTx>;
begin
  EnterCriticalSection(FMu);
  try
    vKey := ParaTx.ToOnroadHeightKey.Bytes;
    FDb.Delete(vKey);
    vTxs := GetFirstOnroadTxInternal(ParaTx.mToAddr, ParaTx.mFromAddr);
    if Length(vTxs) = 0 then
      RemoveCaller(ParaTx.mFromAddr);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TOnroadStorage.UpdateFromIndex(ParaTx: TOnroadTx): Boolean;
var
  vKey, vValue: TBytes;
  vExist: Boolean;
begin
  EnterCriticalSection(FMu);
  try
    vKey := ParaTx.ToOnroadHeightKey.Bytes;
    vExist := FDb.Has(vKey);
    if not vExist then
    begin
      Result := False;
      Exit;
    end;
    vValue := ParaTx.ToOnroadHeightValue;
    FDb.Put(vKey, vValue);
    Result := True;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TOnroadStorage.GetAllFirstOnroadTx(ParaAddr: TAddress): TDictionary<TAddress, TArray<TOnroadTx>>;
var
  vCaller: TAddress;
  vTxs: TArray<TOnroadTx>;
begin
  Result := TDictionary<TAddress, TArray<TOnroadTx>>.Create;
  EnterCriticalSection(FMu);
  try
    for vCaller in FCallers.Keys do
    begin
      vTxs := GetFirstOnroadTxInternal(ParaAddr, vCaller);
      if Length(vTxs) > 0 then
        Result.Add(vCaller, vTxs);
    end;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TOnroadStorage.GetFirstOnroadTxInternal(ParaAddr, ParaCaller: TAddress): TArray<TOnroadTx>;
var
  vKey: TOnRoadHeightKey;
  vIter: TIterator;
  vResult: TArray<TOnroadTx>;
  vInitHeight: UInt64;
  vK, vV: TBytes;
  vTx: TOnroadTx;
begin
  vKey := Default(TOnRoadHeightKey);
  vIter := FDb.NewIterator(TBytesPrefix.Create(vKey.IteratorPrefix(ParaAddr, ParaCaller)));
  try
    vResult := [];
    vInitHeight := 0;
    while vIter.Next do
    begin
      vK := vIter.Key;
      vV := vIter.Value;
      vTx := NewOnroadTxFromBytes(vK, vV);
      if vInitHeight = 0 then
        vInitHeight := vTx.mFromHeight;
      if vTx.mFromHeight <> vInitHeight then
        Break;
      SetLength(vResult, Length(vResult) + 1);
      vResult[High(vResult)] := vTx;
    end;
  finally
    vIter.Free;
  end;
  Result := vResult;
end;

function TOnroadStorage.GetFirstOnroadTx(ParaAddr, ParaCaller: TAddress): TArray<TOnroadTx>;
begin
  EnterCriticalSection(FMu);
  try
    Result := GetFirstOnroadTxInternal(ParaAddr, ParaCaller);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TOnroadStorage.GetOnRoadCount(ParaAddr: TAddress): Integer;
var
  vCount: Integer;
  vCaller: TAddress;
  vKey: TOnRoadHeightKey;
  vIter: TIterator;
begin
  vCount := 0;
  EnterCriticalSection(FMu);
  try
    for vCaller in FCallers.Keys do
    begin
      vKey := Default(TOnRoadHeightKey);
      vIter := FDb.NewIterator(TBytesPrefix.Create(vKey.IteratorPrefix(ParaAddr, vCaller)));
      try
        while vIter.Next do
          Inc(vCount);
      finally
        vIter.Free;
      end;
    end;
  finally
    LeaveCriticalSection(FMu);
  end;
  Result := vCount;
end;

function NewOnroadTxFromBytes(ParaKey, ParaValue: TBytes): TOnroadTx;
var
  vToAddress, vFromAddress: TAddress;
  vHeight: UInt64;
  vHash: THash;
  vFromIndex: UInt32;
begin
  vToAddress := TAddress.FromBytes(Copy(ParaKey, 2, TAddress.Size));
  vFromAddress := TAddress.FromBytes(Copy(ParaKey, 2 + TAddress.Size, TAddress.Size));
  vHeight := TBigEndian.ToUint64(Copy(ParaKey, 2 + TAddress.Size * 2, 8));
  vHash := THash.FromBytes(Copy(ParaKey, 2 + TAddress.Size * 2 + 8, THash.Size));
  Result.mFromAddr := vFromAddress;
  Result.mToAddr := vToAddress;
  Result.mFromHeight := vHeight;
  Result.mFromHash := vHash;
  if Length(ParaValue) = 4 then
  begin
    vFromIndex := TBigEndian.ToUint32(ParaValue);
    Result.mFromIndex := @vFromIndex;
  end
  else
    Result.mFromIndex := nil;
end;

function NewOnroadTxFromOrHashHeight(ParaFromAddr, ParaToAddress: TAddress; ParaOr: TOrHashHeight): TOnroadTx;
begin
  Result.mFromAddr := ParaFromAddr;
  Result.mToAddr := ParaToAddress;
  Result.mFromHeight := ParaOr.mHeight;
  Result.mFromHash := ParaOr.mHash;
  Result.mFromIndex := ParaOr.mSubIndex;
end;

end.