unit Ledger.Onroad.Pool.Contract.Pool;

interface

uses
  Common.Types,
  GoToDelphi.Helpers.LevelDB,
  Ledger.Onroad.Pool,
  Ledger.Onroad.Pool.Caller.Cache.Test,
  Ledger.Onroad.Pool.Error.Table,
  Ledger.Onroad.Pool.Pool,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Storage.Test,
  Ledger.Onroad.Pool.Types,
  Ledger.Onroad.Pool.Types.Test,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  Vite.Interfaces.Core;

type
  TContractOnRoadPool = class(TInterfacedObject, IOnRoadPool)
  private
    FGid: TGid;
    FCache: TDictionary<TAddress, TCallerCache>;
    FStorage: IOnroadStorage;
    FChain: IChainReader;
    FLog: ILog;
    FMutex: TCriticalSection;
    procedure LoadOnRoad;
    function LedgerBlockListToOnRoad(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>): TDictionary<TAddress, TPendingOnRoadList>;
    procedure InsertOnRoad(ParaOrAddr, ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
    procedure DeleteOnRoad(ParaOrAddr, ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
  public
    constructor Create(ParaGid: TGid; ParaChain: IChainReader; ParaDb: TLevelDB);
    destructor Destroy; override;
    function IsFrontOnRoadOfCaller(ParaOrAddr, ParaCaller: TAddress; ParaHash: THash): Boolean;
    function GetFrontOnRoadBlocksByAddr(ParaContract: TAddress): TArray<TAccountBlock>;
    function GetOnRoadTotalNumByAddr(ParaContract: TAddress): UInt64;
    procedure InsertAccountBlocks(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>);
    procedure DeleteAccountBlocks(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>);
    function Info: TDictionary<string, TObject>;
  end;

  TCallerCache = class
  private
    FStorage: IOnroadStorage;
    FAddress: TAddress;
    FMu: TCriticalSection;
    function GetFrontTxOfAllCallers: TArray<TOrHeightValue>;
    function GetFrontTxByCaller(ParaCaller: TAddress): TOrHeightValue;
    function LazyUpdateFrontTx(ParaReader: IChainReader; ParaHv: TOrHeightValue): TOrHashHeight;
  public
    constructor Create(ParaAddress: TAddress; ParaStorage: IOnroadStorage);
    destructor Destroy; override;
    procedure InitAdd(ParaFromAddr, ParaToAddr: TAddress; ParaHashHeight: THashHeight);
    function GetAndLazyUpdateFrontTxOfAllCallers(ParaReader: IChainReader): TArray<TOrHashHeight>;
    function GetAndLazyUpdateFrontTxByCaller(ParaReader: IChainReader; ParaCaller: TAddress): TOrHashHeight;
    function Len: Integer;
    procedure AddTx(ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
    procedure RmTx(ParaCaller: TAddress; ParaIsCallerContract: Boolean; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
  end;

implementation

uses
  System.StrUtils,
  Vite.Common,
  GoToDelphi.Helpers.Logging;

{ TContractOnRoadPool }

constructor TContractOnRoadPool.Create(ParaGid: TGid; ParaChain: IChainReader; ParaDb: TLevelDB);
begin
  inherited Create;
  FGid := ParaGid;
  FChain := ParaChain;
  FStorage := TOnroadStorage.Create(ParaDb);
  FCache := TDictionary<TAddress, TCallerCache>.Create;
  FLog := TLog15.New('contractOnRoadPool', ParaGid.ToString);
  InitializeCriticalSection(FMutex);
  LoadOnRoad;
end;

destructor TContractOnRoadPool.Destroy;
begin
  FCache.Free;
  FStorage := nil;
  DeleteCriticalSection(FMutex);
  inherited;
end;

procedure TContractOnRoadPool.LoadOnRoad;
var
  vToAddrStat: TDictionary<TAddress, UInt64>;
  vLastToAddr: TAddress;
  vCC: TCallerCache;
  vValue: TCallerCache;
begin
  vToAddrStat := TDictionary<TAddress, UInt64>.Create;
  try
    vLastToAddr := Default(TAddress);
    FLog.Info('start loadOnRoad from chain into onroad');
    FChain.LoadOnRoadRange(FGid,
      procedure(ParaFromAddr, ParaToAddr: TAddress; ParaHashHeight: THashHeight)
      begin
        if not FCache.TryGetValue(ParaToAddr, vValue) then
        begin
          vCC := TCallerCache.Create(ParaToAddr, FStorage);
          FCache.Add(ParaToAddr, vCC);
        end
        else
          vCC := vValue;

        if vCC = nil then
          raise Exception.CreateFmt('error load caller cache for %s', [ParaToAddr.ToString]);

        if (vToAddrStat.ContainsKey(ParaToAddr)) and (vToAddrStat[ParaToAddr] = 0) and (not vLastToAddr.IsZero) then
          FLog.Info(Format('initLoad one caller, len=%d', [vToAddrStat[vLastToAddr]]), 'contract', vLastToAddr.ToString);

        if not vToAddrStat.ContainsKey(ParaToAddr) then
            vToAddrStat.Add(ParaToAddr, 0);

        vToAddrStat[ParaToAddr] := vToAddrStat[ParaToAddr] + 1;
        vLastToAddr := ParaToAddr;
        vCC.InitAdd(ParaFromAddr, ParaToAddr, ParaHashHeight);
      end);
    if not vLastToAddr.IsZero then
      FLog.Info(Format('initLoad one caller, len=%d', [vToAddrStat[vLastToAddr]]), 'contract', vLastToAddr.ToString);
    FLog.Info('end loadOnRoad from chain into onroad');
    FLog.Info('success loadOnRoad');
  finally
    vToAddrStat.Free;
  end;
end;

function TContractOnRoadPool.IsFrontOnRoadOfCaller(ParaOrAddr, ParaCaller: TAddress; ParaHash: THash): Boolean;
var
  vCC: TCallerCache;
  vOk: Boolean;
  vOr: TOrHashHeight;
  vFrontHash: THash;
begin
  EnterCriticalSection(FMutex);
  try
    vOk := FCache.TryGetValue(ParaOrAddr, vCC);
  finally
    LeaveCriticalSection(FMutex);
  end;

  if not vOk or (vCC = nil) then
    raise ELoadCallerCacheFailed.Create;

  vOr := vCC.GetAndLazyUpdateFrontTxByCaller(FChain, ParaCaller);
  if (vOr = nil) or (not vOr.mHash.IsEqual(ParaHash)) then
  begin
    vFrontHash := Default(THash);
    if vOr <> nil then
      vFrontHash := vOr.mHash;
    FLog.Error(Format('check IsFrontOnRoadOfCaller fail target=%s front=%s', [ParaHash.ToString, vFrontHash.ToString]));
    raise ECheckIsCallerFrontOnRoadFailed.Create;
  end;
  Result := True;
end;

function TContractOnRoadPool.GetFrontOnRoadBlocksByAddr(ParaContract: TAddress): TArray<TAccountBlock>;
var
  vCC: TCallerCache;
  vOk: Boolean;
  vBlockList: TArray<TAccountBlock>;
  vOrList: TArray<TOrHashHeight>;
  vOr: TOrHashHeight;
  vB: TAccountBlock;
begin
  EnterCriticalSection(FMutex);
  try
    vOk := FCache.TryGetValue(ParaContract, vCC);
  finally
    LeaveCriticalSection(FMutex);
  end;

  if not vOk or (vCC = nil) then
  begin
    Result := nil;
    Exit;
  end;

  vBlockList := [];
  vOrList := vCC.GetAndLazyUpdateFrontTxOfAllCallers(FChain);

  for vOr in vOrList do
  begin
    vB := vOr.mCachedBlock;
    if vB = nil then
    begin
      vB := FChain.GetAccountBlockByHash(vOr.mHash);
      vOr.mCachedBlock := vB;
    end;
    if vB = nil then
      Continue;
    SetLength(vBlockList, Length(vBlockList) + 1);
    vBlockList[High(vBlockList)] := vB;
  end;
  Result := vBlockList;
end;

function TContractOnRoadPool.GetOnRoadTotalNumByAddr(ParaContract: TAddress): UInt64;
var
  vCC: TCallerCache;
  vOk: Boolean;
begin
  EnterCriticalSection(FMutex);
  try
    vOk := FCache.TryGetValue(ParaContract, vCC);
  finally
    LeaveCriticalSection(FMutex);
  end;

  if not vOk or (vCC = nil) then
  begin
    Result := 0;
    Exit;
  end;
  Result := vCC.Len;
end;

procedure TContractOnRoadPool.InsertAccountBlocks(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>);
var
  vMlog: ILog;
  vIsWrite: Boolean;
  vOnroadMap: TDictionary<TAddress, TPendingOnRoadList>;
  vPendingList: TPendingOnRoadList;
  vV: TPendingOnRoad;
  vOr: TOrHashHeight;
begin
  vMlog := FLog.New('method', 'InsertAccountBlocks', 'orAddr', ParaOrAddr.ToString, 'len', Length(ParaBlocks));
  vIsWrite := True;
  vOnroadMap := LedgerBlockListToOnRoad(ParaOrAddr, ParaBlocks);
  try
    for vPendingList in vOnroadMap.Values do
    begin
      vPendingList.Sort;
      for vV in vPendingList do
      begin
        vOr := vV.mHashHeight;
        if vV.mBlock.IsSendBlock then
        begin
          vMlog.Debug(Format('write block-s: %s -> %s %d %s isWrite=%s', [vV.mBlock.AccountAddress.ToString, vV.mBlock.ToAddress.ToString, vV.mBlock.Height, vV.mBlock.Hash.ToString, BoolToStr(vIsWrite, True)]));
          InsertOnRoad(vV.mOrAddr, vV.mCaller, vOr, vIsWrite);
        end
        else
        begin
          vMlog.Debug(Format('write block-r: %s %d %s fromHash=%s isWrite=%s', [vV.mBlock.AccountAddress.ToString, vV.mBlock.Height, vV.mBlock.Hash.ToString, vV.mBlock.FromBlockHash.ToString, BoolToStr(vIsWrite, True)]));
          DeleteOnRoad(vV.mOrAddr, vV.mCaller, vOr, vIsWrite);
        end;
      end;
    end;
  finally
    vOnroadMap.Free;
  end;
end;

procedure TContractOnRoadPool.DeleteAccountBlocks(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>);
var
  vMlog: ILog;
  vIsWrite: Boolean;
  vOnroadMap: TDictionary<TAddress, TPendingOnRoadList>;
  vPendingList: TPendingOnRoadList;
  vI: Integer;
  vV: TPendingOnRoad;
  vOr: TOrHashHeight;
begin
  vMlog := FLog.New('method', 'DeleteAccountBlocks', 'orAddr', ParaOrAddr.ToString);
  vMlog.Info(Format('deleteBlocks len %d', [Length(ParaBlocks)]));
  vIsWrite := False;
  vOnroadMap := LedgerBlockListToOnRoad(ParaOrAddr, ParaBlocks);
  try
    for vPendingList in vOnroadMap.Values do
    begin
      vPendingList.Sort;
      for vI := vPendingList.Count - 1 downto 0 do
      begin
        vV := vPendingList[vI];
        vOr := vV.mHashHeight;
        if vV.mBlock.IsSendBlock then
        begin
          vMlog.Debug(Format('delete block-s: %s -> %s %d %s isWrite=%s', [vV.mBlock.AccountAddress.ToString, vV.mBlock.ToAddress.ToString, vV.mBlock.Height, vV.mBlock.Hash.ToString, BoolToStr(vIsWrite, True)]));
          DeleteOnRoad(vV.mOrAddr, vV.mCaller, vOr, vIsWrite);
        end
        else
        begin
          vMlog.Debug(Format('delete block-r: %s %d %s fromHash=%s isWrite=%s', [vV.mBlock.AccountAddress.ToString, vV.mBlock.Height, vV.mBlock.Hash.ToString, vV.mBlock.FromBlockHash.ToString, BoolToStr(vIsWrite, True)]));
          InsertOnRoad(vV.mOrAddr, vV.mCaller, vOr, vIsWrite);
        end;
      end;
    end;
  finally
    vOnroadMap.Free;
  end;
end;

procedure TContractOnRoadPool.InsertOnRoad(ParaOrAddr, ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
var
  vCC: TCallerCache;
  vExist: Boolean;
begin
  FLog.Info(Format('insert onroad: %s -> %s %d %s isWrite=%s', [ParaCaller.ToString, ParaOrAddr.ToString, ParaOr.mHeight, ParaOr.mHash.ToString, BoolToStr(ParaIsWrite, True)]));
  EnterCriticalSection(FMutex);
  try
    vExist := FCache.TryGetValue(ParaOrAddr, vCC);
    if not vExist or (vCC = nil) then
    begin
      vCC := TCallerCache.Create(ParaOrAddr, FStorage);
      FCache.Add(ParaOrAddr, vCC);
    end;
  finally
    LeaveCriticalSection(FMutex);
  end;
  vCC.AddTx(ParaCaller, ParaOr, ParaIsWrite);
end;

procedure TContractOnRoadPool.DeleteOnRoad(ParaOrAddr, ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
var
  vIsCallerContract: Boolean;
  vCC: TCallerCache;
  vExist: Boolean;
begin
  FLog.Info(Format('delete onroad: %s -> %s %d %s isWrite=%s', [ParaCaller.ToString, ParaOrAddr.ToString, ParaOr.mHeight, ParaOr.mHash.ToString, BoolToStr(ParaIsWrite, True)]));
  vIsCallerContract := ParaCaller.IsContractAddress;
  EnterCriticalSection(FMutex);
  try
    vExist := FCache.TryGetValue(ParaOrAddr, vCC);
  finally
    LeaveCriticalSection(FMutex);
  end;
  if not vExist or (vCC = nil) then
    raise ELoadCallerCacheFailed.Create;
  vCC.RmTx(ParaCaller, vIsCallerContract, ParaOr, ParaIsWrite);
end;

function TContractOnRoadPool.LedgerBlockListToOnRoad(ParaOrAddr: TAddress; ParaBlocks: TArray<TAccountBlock>): TDictionary<TAddress, TPendingOnRoadList>;
var
  vOnroadMap: TDictionary<TAddress, TPendingOnRoadList>;
  vB: TAccountBlock;
  vOnroad: TPendingOnRoad;
  vOk: Boolean;
  vList: TPendingOnRoadList;
begin
  vOnroadMap := TDictionary<TAddress, TPendingOnRoadList>.Create;
  for vB in ParaBlocks do
  begin
    if vB = nil then
      Continue;
    try
      vOnroad := LedgerBlockToOnRoad(FChain, vB);
      vOk := vOnroadMap.TryGetValue(vOnroad.mCaller, vList);
      if not vOk then
      begin
        vList := TPendingOnRoadList.Create;
        vOnroadMap.Add(vOnroad.mCaller, vList);
      end;
      vList.Add(vOnroad);
    except
      on E: Exception do
      begin
        if vB.IsSendBlock then
          FLog.Error(Format('LedgerBlockToOnRoad s fail self=%s t=%s hash=%s height=%d', [vB.AccountAddress.ToString, vB.ToAddress.ToString, vB.Hash.ToString, vB.Height]), 'err', E.Message)
        else
          FLog.Error(Format('LedgerBlockToOnRoad r fail self=%s fHash=%s hash=%s height%d', [vB.AccountAddress.ToString, vB.FromBlockHash.ToString, vB.Hash.ToString, vB.Height]), 'err', E.Message);
        raise;
      end;
    end;
  end;
  Result := vOnroadMap;
end;

function TContractOnRoadPool.Info: TDictionary<string, TObject>;
var
  vSum: Integer;
  vKey: TAddress;
  vValue: TCallerCache;
begin
  Result := TDictionary<string, TObject>.Create;
  vSum := 0;
  EnterCriticalSection(FMutex);
  try
    for vKey in FCache.Keys do
    begin
      vValue := FCache[vKey];
      Result.Add(vKey.ToString, TObject(vValue.Len));
      vSum := vSum + vValue.Len;
    end;
  finally
    LeaveCriticalSection(FMutex);
  end;
  Result.Add('Sum', TObject(vSum));
end;

{ TCallerCache }

constructor TCallerCache.Create(ParaAddress: TAddress; ParaStorage: IOnroadStorage);
begin
  inherited Create;
  FAddress := ParaAddress;
  FStorage := ParaStorage;
  InitializeCriticalSection(FMu);
end;

destructor TCallerCache.Destroy;
begin
  DeleteCriticalSection(FMu);
  inherited;
end;

procedure TCallerCache.InitAdd(ParaFromAddr, ParaToAddr: TAddress; ParaHashHeight: THashHeight);
var
  vIsCallerContract: Boolean;
  vOr: TOrHashHeight;
  vIndex: Cardinal;
  vInitLog: ILog;
begin
  vInitLog := TLog15.New('initOnRoadPool', nil);
  vIsCallerContract := ParaFromAddr.IsContractAddress;
  vOr := TOrHashHeight.Create;
  vOr.mHeight := ParaHashHeight.Height;
  vOr.mHash := ParaHashHeight.Hash;
  if not vIsCallerContract then
  begin
    vIndex := 0;
    vOr.mSubIndex := @vIndex;
  end;
  vInitLog.Debug(Format('addTx %s', [vOr.ToString]));
  AddTx(ParaFromAddr, vOr, True);
end;

function TCallerCache.GetAndLazyUpdateFrontTxOfAllCallers(ParaReader: IChainReader): TArray<TOrHashHeight>;
var
  vTxs: TArray<TOrHeightValue>;
  vResult: TArray<TOrHashHeight>;
  vTx: TOrHeightValue;
  vRr: TOrHashHeight;
  vOnroadPoolLog: ILog;
begin
  vOnroadPoolLog := TLog15.New('onroadPool', nil);
  vTxs := GetFrontTxOfAllCallers;
  vResult := [];
  for vTx in vTxs do
  begin
    try
      vRr := LazyUpdateFrontTx(ParaReader, vTx);
      if vRr <> nil then
      begin
        SetLength(vResult, Length(vResult) + 1);
        vResult[High(vResult)] := vRr;
      end;
    except
      on E: Exception do
        vOnroadPoolLog.Warn('lazy update front tx failed', 'err', E.Message);
    end;
  end;
  Result := vResult;
end;

function TCallerCache.GetFrontTxOfAllCallers: TArray<TOrHeightValue>;
var
  vM: TDictionary<TAddress, TOnroadTxs>;
  vOrList: TArray<TOrHeightValue>;
  vList: TOnroadTxs;
  vFront: TOrHeightValue;
begin
  EnterCriticalSection(FMu);
  try
    vM := FStorage.GetAllFirstOnroadTx(FAddress);
    vOrList := [];
    for vList in vM.Values do
    begin
      vFront := NewOrHeightValueFromOnroadTxs(vList);
      SetLength(vOrList, Length(vOrList) + 1);
      vOrList[High(vOrList)] := vFront;
    end;
    Result := vOrList;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TCallerCache.GetAndLazyUpdateFrontTxByCaller(ParaReader: IChainReader; ParaCaller: TAddress): TOrHashHeight;
var
  vOrVal: TOrHeightValue;
begin
  vOrVal := GetFrontTxByCaller(ParaCaller);
  if vOrVal = nil then
  begin
    Result := nil;
    Exit;
  end;
  Result := LazyUpdateFrontTx(ParaReader, vOrVal);
end;

function TCallerCache.GetFrontTxByCaller(ParaCaller: TAddress): TOrHeightValue;
var
  vTxs: TOnroadTxs;
begin
  EnterCriticalSection(FMu);
  try
    vTxs := FStorage.GetFirstOnroadTx(FAddress, ParaCaller);
    Result := NewOrHeightValueFromOnroadTxs(vTxs);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TCallerCache.LazyUpdateFrontTx(ParaReader: IChainReader; ParaHv: TOrHeightValue): TOrHashHeight;
var
  vSubs: TArray<TOnroadTx>;
  vBlock: TAccountBlock;
  vI: Integer;
  vSendBlock: TAccountBlock;
  vSub: TOnroadTx;
  vJ: Cardinal;
  vUpdateResult: Boolean;
  vTx: TOnroadTx;
begin
  EnterCriticalSection(FMu);
  try
    vSubs := ParaHv.DirtyTxs;
    if Length(vSubs) > 0 then
    begin
      vBlock := ParaReader.GetCompleteBlockByHash(vSubs[0].mFromHash);
      if not vBlock.AccountAddress.IsContractAddress then
        raise Exception.Create('get update front tx failed. it''s not contract address');
      for vI := 0 to High(vBlock.SendBlockList) do
      begin
        vSendBlock := vBlock.SendBlockList[vI];
        for vSub in vSubs do
        begin
          if vSub.mFromHash.IsEqual(vSendBlock.Hash) then
          begin
            vJ := vI;
            vSub.mFromIndex := @vJ;
            vUpdateResult := FStorage.UpdateFromIndex(vSub);
            if not vUpdateResult then
              raise Exception.CreateFmt('dirty OnroadTx %s, %s, %s', [vSub.mToAddr.ToString, vSub.mFromAddr.ToString, vSub.mFromHash.ToString]);
          end;
        end;
      end;
      vSubs := ParaHv.DirtyTxs;
      if Length(vSubs) > 0 then
        raise Exception.Create('dirty sub index');
    end;
    vTx := ParaHv.MinTx;
    if vTx = nil then
    begin
      Result := nil;
      Exit;
    end;
    Result := NewOrHashHeightFromOnroadTx(vTx);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TCallerCache.Len: Integer;
begin
  EnterCriticalSection(FMu);
  try
    Result := FStorage.GetOnRoadCount(FAddress);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

procedure TCallerCache.AddTx(ParaCaller: TAddress; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
begin
  EnterCriticalSection(FMu);
  try
    FStorage.InsertOnRoadTx(NewOnroadTxFromOrHashHeight(ParaCaller, FAddress, ParaOr));
  finally
    LeaveCriticalSection(FMu);
  end;
end;

procedure TCallerCache.RmTx(ParaCaller: TAddress; ParaIsCallerContract: Boolean; ParaOr: TOrHashHeight; ParaIsWrite: Boolean);
begin
  EnterCriticalSection(FMu);
  try
    FStorage.DeleteOnRoadTx(NewOnroadTxFromOrHashHeight(ParaCaller, FAddress, ParaOr));
  finally
    LeaveCriticalSection(FMu);
  end;
end;

end.
