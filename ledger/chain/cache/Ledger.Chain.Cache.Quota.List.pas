unit Ledger.Chain.Cache.QuotaList;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Cache,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Hot.Data,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Interface,
  Ledger.Chain.Cache.Quota,
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite.Common.Types Interfaces.Core Ledger.Chain.Cache.Interfaces Common.Log;

type
  TQuotaInfo = record
    BlockCount: UInt64;
    QuotaTotal: UInt64;
    QuotaUsedTotal: UInt64;
  end;

  TQuotaList = class
  private
    const
      Uninitialized = 0;
      Initialized = 1;
  private
    mChain: IChain;
    mBackElement: TDictionary<TAddress, TQuotaInfo>;
    mGlobalUsed: TQuotaInfo;
    mUsedStart: TLink<TDictionary<TAddress, TQuotaInfo>>;
    mUsedAccumulateHeight: Integer;
    mList: TList<TDictionary<TAddress, TQuotaInfo>>;
    mListMaxLength: Integer;
    mStatus: Byte;
    mLog: ILogger;
    procedure Build;
    procedure MoveNext(ParaBackElement: TDictionary<TAddress, TQuotaInfo>);
    procedure AddToMap(ParaQuotaInfoMap: TDictionary<TAddress, TQuotaInfo>; ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
    procedure SubFromMap(ParaQuotaInfoMap: TDictionary<TAddress, TQuotaInfo>; ParaAddr: TAddress; ParaBlockCount, ParaQuota, ParaQuotaUsed: UInt64);
    procedure CalculateGlobalUsed;
    procedure ResetUsedStart;
    function Aggregate(ParaQuotaMap: TDictionary<TAddress, TQuotaInfo>): TQuotaInfo;
  public
    constructor Create(ParaChain: IChain);
    destructor Destroy; override;
    function Init: Boolean;
    function GetGlobalQuota: TQuotaInfo;
    function GetQuotaUsedList(ParaAddr: TAddress): TArray<TQuotaInfo>;
    procedure Add(ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
    procedure Sub(ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
    procedure ResetUnconfirmedQuotas(ParaUnconfirmedBlocks: TArray<TAccountBlock>);
    procedure NewNext(ParaConfirmedBlocks: TArray<TAccountBlock>);
    procedure Rollback(ParaDeletedChunks: TArray<TSnapshotChunk>);
  end;

implementation

{ TQuotaList }

constructor TQuotaList.Create(ParaChain: IChain);
begin
  inherited Create;
  mChain := ParaChain;
  mBackElement := TDictionary<TAddress, TQuotaInfo>.Create;
  mList := TList<TDictionary<TAddress, TQuotaInfo>>.Create;
  mListMaxLength := 600;
  mUsedAccumulateHeight := 75;
  mLog := TLog.New('module', 'quota_list');
  mStatus := Uninitialized;
end;

destructor TQuotaList.Destroy;
begin
  mBackElement.Free;
  mList.Free;
  inherited Destroy;
end;

function TQuotaList.Init: Boolean;
begin
  try
    Build;
    MoveNext(TDictionary<TAddress, TQuotaInfo>.Create);
    mStatus := Initialized;
    Result := True;
  except
    on E: Exception do
    begin
      mLog.Error('Failed to initialize quota list', ['error', E.Message]);
      Result := False;
    end;
  end;
end;

function TQuotaList.GetGlobalQuota: TQuotaInfo;
var
  vGlobalQuota: TQuotaInfo;
  vQuotaInfo: TQuotaInfo;
begin
  vGlobalQuota := mGlobalUsed;
  for vQuotaInfo in mBackElement.Values do
  begin
    vGlobalQuota.BlockCount := vGlobalQuota.BlockCount - vQuotaInfo.BlockCount;
    vGlobalQuota.QuotaTotal := vGlobalQuota.QuotaTotal - vQuotaInfo.QuotaTotal;
    vGlobalQuota.QuotaUsedTotal := vGlobalQuota.QuotaUsedTotal - vQuotaInfo.QuotaUsedTotal;
  end;
  Result := vGlobalQuota;
end;

function TQuotaList.GetQuotaUsedList(ParaAddr: TAddress): TArray<TQuotaInfo>;
var
  vUsedList: TList<TQuotaInfo>;
  vPointer: TLink<TDictionary<TAddress, TQuotaInfo>>;
  vTmpUsed: TDictionary<TAddress, TQuotaInfo>;
  vAddrUsed: TQuotaInfo;
begin
  vUsedList := TList<TQuotaInfo>.Create;
  try
    vPointer := mUsedStart;
    while Assigned(vPointer) do
    begin
      vTmpUsed := vPointer.Value;
      if vTmpUsed.TryGetValue(ParaAddr, vAddrUsed) then
      begin
        vUsedList.Add(vAddrUsed);
      end
      else
      begin
        vUsedList.Add(Default(TQuotaInfo));
      end;
      vPointer := vPointer.Next;
    end;

    if vUsedList.Count <= 0 then
    begin
      mLog.Warn(Format('GetQuotaUsedList: %s, return %d list,', [ParaAddr.ToString, vUsedList.Count]), ['method', 'GetQuotaUsedList']);
    end;
    Result := vUsedList.ToArray;
  finally
    vUsedList.Free;
  end;
end;

procedure TQuotaList.Add(ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
begin
  AddToMap(mBackElement, ParaAddr, ParaQuota, ParaQuotaUsed);
  mGlobalUsed.BlockCount := mGlobalUsed.BlockCount + 1;
  mGlobalUsed.QuotaTotal := mGlobalUsed.QuotaTotal + ParaQuota;
  mGlobalUsed.QuotaUsedTotal := mGlobalUsed.QuotaUsedTotal + ParaQuotaUsed;
end;

procedure TQuotaList.Sub(ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
begin
  SubFromMap(mBackElement, ParaAddr, 1, ParaQuota, ParaQuotaUsed);
  mGlobalUsed.BlockCount := mGlobalUsed.BlockCount - 1;
  mGlobalUsed.QuotaTotal := mGlobalUsed.QuotaTotal - ParaQuota;
  mGlobalUsed.QuotaUsedTotal := mGlobalUsed.QuotaUsedTotal - ParaQuotaUsed;
end;

procedure TQuotaList.ResetUnconfirmedQuotas(ParaUnconfirmedBlocks: TArray<TAccountBlock>);
var
  vBackElement: TDictionary<TAddress, TQuotaInfo>;
  vUnconfirmedBlock: TAccountBlock;
  vQi: TQuotaInfo;
  vOriginAgg, vNewAgg: TQuotaInfo;
begin
  if mStatus < Initialized then
  begin
    Exit;
  end;

  vBackElement := TDictionary<TAddress, TQuotaInfo>.Create;
  try
    for vUnconfirmedBlock in ParaUnconfirmedBlocks do
    begin
      if not vBackElement.TryGetValue(vUnconfirmedBlock.AccountAddress, vQi) then
      begin
        vQi := Default(TQuotaInfo);
      end;
      vQi.BlockCount := vQi.BlockCount + 1;
      vQi.QuotaTotal := vQi.QuotaTotal + vUnconfirmedBlock.Quota;
      vQi.QuotaUsedTotal := vQi.QuotaUsedTotal + vUnconfirmedBlock.QuotaUsed;
      vBackElement.AddOrSetValue(vUnconfirmedBlock.AccountAddress, vQi);
    end;

    vOriginAgg := Aggregate(mBackElement);
    vNewAgg := Aggregate(vBackElement);

    mGlobalUsed.BlockCount := mGlobalUsed.BlockCount - vOriginAgg.BlockCount + vNewAgg.BlockCount;
    mGlobalUsed.QuotaTotal := mGlobalUsed.QuotaTotal - vOriginAgg.QuotaTotal + vNewAgg.QuotaTotal;
    mGlobalUsed.QuotaUsedTotal := mGlobalUsed.QuotaUsedTotal - vOriginAgg.QuotaUsedTotal + vNewAgg.QuotaUsedTotal;

    mList.Delete(mList.Count - 1);
    mBackElement.Free;
    mBackElement := vBackElement;
    mList.Add(mBackElement);
  except
    vBackElement.Free;
    raise;
  end;
end;

procedure TQuotaList.NewNext(ParaConfirmedBlocks: TArray<TAccountBlock>);
var
  vCurrentSnapshotQuota: TDictionary<TAddress, TQuotaInfo>;
  vConfirmedBlock: TAccountBlock;
  vQi, vBackQi: TQuotaInfo;
begin
  if mStatus < Initialized then
  begin
    Exit;
  end;

  vCurrentSnapshotQuota := TDictionary<TAddress, TQuotaInfo>.Create;
  try
    for vConfirmedBlock in ParaConfirmedBlocks do
    begin
      if not vCurrentSnapshotQuota.TryGetValue(vConfirmedBlock.AccountAddress, vQi) then
      begin
        vQi := Default(TQuotaInfo);
      end;
      vQi.BlockCount := vQi.BlockCount + 1;
      vQi.QuotaTotal := vQi.QuotaTotal + vConfirmedBlock.Quota;
      vQi.QuotaUsedTotal := vQi.QuotaUsedTotal + vConfirmedBlock.QuotaUsed;
      vCurrentSnapshotQuota.AddOrSetValue(vConfirmedBlock.AccountAddress, vQi);

      if mBackElement.TryGetValue(vConfirmedBlock.AccountAddress, vBackQi) then
      begin
        if vBackQi.BlockCount <= 1 then
        begin
          mBackElement.Remove(vConfirmedBlock.AccountAddress);
        end
        else
        begin
          vBackQi.BlockCount := vBackQi.BlockCount - 1;
          vBackQi.QuotaTotal := vBackQi.QuotaTotal - vConfirmedBlock.Quota;
          vBackQi.QuotaUsedTotal := vBackQi.QuotaUsedTotal - vConfirmedBlock.QuotaUsed;
          mBackElement.AddOrSetValue(vConfirmedBlock.AccountAddress, vBackQi);
        end;
      end;
    end;

    mList.Items[mList.Count - 1] := vCurrentSnapshotQuota;
    MoveNext(mBackElement);
  finally
    // vCurrentSnapshotQuota is now owned by mList, so we don't free it.
  end;
end;

procedure TQuotaList.Rollback(ParaDeletedChunks: TArray<TSnapshotChunk>);
var
  vBackElem: TDictionary<TAddress, TQuotaInfo>;
  vN, i: Integer;
begin
  if mList.Count = 0 then
  begin
    Exit;
  end;
  vBackElem := mList.Last;
  if vBackElem.Count <= 0 then
  begin
    mList.Delete(mList.Count - 1);
  end;

  vN := Length(ParaDeletedChunks);
  if vN >= mListMaxLength then
  begin
    mList.Clear;
  end
  else
  begin
    for i := 0 to vN - 1 do
    begin
      if mList.Count > 0 then
      begin
        mList.Delete(mList.Count - 1);
      end;
    end;
  end;

  Build;
  MoveNext(TDictionary<TAddress, TQuotaInfo>.Create);
end;

procedure TQuotaList.Build;
var
  vListLength: Integer;
  vLatestSb: TSnapshotBlock;
  vLatestSbHeight, vEndSbHeight, vStartSbHeight, vLackListLen: UInt64;
  vSnapshotSegments: TArray<TSnapshotChunk>;
  vSeg: TSnapshotChunk;
  vNewItem: TDictionary<TAddress, TQuotaInfo>;
  vBlock: TAccountBlock;
  vQuotaInfo: TQuotaInfo;
  i: Integer;
begin
  vListLength := mList.Count;
  if vListLength >= mUsedAccumulateHeight then
  begin
    Exit;
  end;

  vLatestSb := mChain.QueryLatestSnapshotBlock;
  if not Assigned(vLatestSb) then
  begin
    Exit;
  end;

  vLatestSbHeight := vLatestSb.Height;
  if vLatestSbHeight <= UInt64(vListLength) then
  begin
    Exit;
  end;

  vEndSbHeight := vLatestSbHeight + 1 - UInt64(vListLength);
  vStartSbHeight := 1;
  vLackListLen := UInt64(mListMaxLength - vListLength);
  if vEndSbHeight > vLackListLen then
  begin
    vStartSbHeight := vEndSbHeight - vLackListLen;
  end;

  if vListLength <= 0 then
  begin
    vSnapshotSegments := mChain.GetSubLedgerAfterHeight(vStartSbHeight);
    if Length(vSnapshotSegments) = 0 then
    begin
      raise Exception.CreateFmt('ql.chain.GetSubLedgerAfterHeight, snapshotSegments is nil, startSbHeight is %d', [vStartSbHeight]);
    end;

    for i := 1 to High(vSnapshotSegments) do
    begin
      vSeg := vSnapshotSegments[i];
      vNewItem := TDictionary<TAddress, TQuotaInfo>.Create;
      for vBlock in vSeg.AccountBlocks do
      begin
        if not vNewItem.TryGetValue(vBlock.AccountAddress, vQuotaInfo) then
        begin
          vQuotaInfo := Default(TQuotaInfo);
          vQuotaInfo.BlockCount := 1;
          vQuotaInfo.QuotaTotal := vBlock.Quota;
          vQuotaInfo.QuotaUsedTotal := vBlock.QuotaUsed;
        end
        else
        begin
          vQuotaInfo.BlockCount := vQuotaInfo.BlockCount + 1;
          vQuotaInfo.QuotaTotal := vQuotaInfo.QuotaTotal + vBlock.Quota;
          vQuotaInfo.QuotaUsedTotal := vQuotaInfo.QuotaUsedTotal + vBlock.QuotaUsed;
        end;
        vNewItem.AddOrSetValue(vBlock.AccountAddress, vQuotaInfo);
      end;
      mList.Add(vNewItem);
    end;
  end
  else
  begin
    vSnapshotSegments := mChain.GetSubLedger(vStartSbHeight, vEndSbHeight);
    if Length(vSnapshotSegments) = 0 then
    begin
      raise Exception.CreateFmt('ql.chain.GetSubLedger, snapshotSegments is nil, startSbHeight is %d, endSbHeight is %d', [vStartSbHeight, vEndSbHeight]);
    end;

    for i := High(vSnapshotSegments) downto 1 do
    begin
      vSeg := vSnapshotSegments[i];
      vNewItem := TDictionary<TAddress, TQuotaInfo>.Create;
      for vBlock in vSeg.AccountBlocks do
      begin
        if not vNewItem.TryGetValue(vBlock.AccountAddress, vQuotaInfo) then
        begin
          vQuotaInfo := Default(TQuotaInfo);
          vQuotaInfo.BlockCount := 1;
          vQuotaInfo.QuotaTotal := vBlock.Quota;
          vQuotaInfo.QuotaUsedTotal := vBlock.QuotaUsed;
        end
        else
        begin
          vQuotaInfo.BlockCount := vQuotaInfo.BlockCount + 1;
          vQuotaInfo.QuotaTotal := vQuotaInfo.QuotaTotal + vBlock.Quota;
          vQuotaInfo.QuotaUsedTotal := vQuotaInfo.QuotaUsedTotal + vBlock.QuotaUsed;
        end;
        vNewItem.AddOrSetValue(vBlock.AccountAddress, vQuotaInfo);
      end;
      mList.Insert(0, vNewItem);
    end;
  end;

  if mList.Count > 0 then
  begin
    mBackElement := mList.Last;
    ResetUsedStart;
    CalculateGlobalUsed;
  end;
end;

procedure TQuotaList.MoveNext(ParaBackElement: TDictionary<TAddress, TQuotaInfo>);
var
  vQuotaUsedStart: TDictionary<TAddress, TQuotaInfo>;
  vUsedStartItem: TQuotaInfo;
begin
  mList.Add(ParaBackElement);
  mBackElement := ParaBackElement;

  if not Assigned(mUsedStart) then
  begin
    mUsedStart := mList.First;
  end;

  if mList.Count <= mUsedAccumulateHeight then
  begin
    Exit;
  end;

  vQuotaUsedStart := mUsedStart.Value;
  for vUsedStartItem in vQuotaUsedStart.Values do
  begin
    mGlobalUsed.QuotaUsedTotal := mGlobalUsed.QuotaUsedTotal - vUsedStartItem.QuotaUsedTotal;
    mGlobalUsed.BlockCount := mGlobalUsed.BlockCount - vUsedStartItem.BlockCount;
    mGlobalUsed.QuotaTotal := mGlobalUsed.QuotaTotal - vUsedStartItem.QuotaTotal;
  end;

  mUsedStart := mUsedStart.Next;
  if mList.Count > mListMaxLength then
  begin
    mList.Delete(0);
  end;
end;

procedure TQuotaList.AddToMap(ParaQuotaInfoMap: TDictionary<TAddress, TQuotaInfo>; ParaAddr: TAddress; ParaQuota, ParaQuotaUsed: UInt64);
var
  vQi: TQuotaInfo;
begin
  if not ParaQuotaInfoMap.TryGetValue(ParaAddr, vQi) then
  begin
    vQi := Default(TQuotaInfo);
  end;
  vQi.BlockCount := vQi.BlockCount + 1;
  vQi.QuotaTotal := vQi.QuotaTotal + ParaQuota;
  vQi.QuotaUsedTotal := vQi.QuotaUsedTotal + ParaQuotaUsed;
  ParaQuotaInfoMap.AddOrSetValue(ParaAddr, vQi);
end;

procedure TQuotaList.SubFromMap(ParaQuotaInfoMap: TDictionary<TAddress, TQuotaInfo>; ParaAddr: TAddress; ParaBlockCount, ParaQuota, ParaQuotaUsed: UInt64);
var
  vQi: TQuotaInfo;
begin
  if not ParaQuotaInfoMap.TryGetValue(ParaAddr, vQi) then
  begin
    Exit;
  end;

  if vQi.BlockCount <= ParaBlockCount then
  begin
    ParaQuotaInfoMap.Remove(ParaAddr);
  end
  else
  begin
    vQi.BlockCount := vQi.BlockCount - ParaBlockCount;
    vQi.QuotaTotal := vQi.QuotaTotal - ParaQuota;
    vQi.QuotaUsedTotal := vQi.QuotaUsedTotal - ParaQuotaUsed;
    ParaQuotaInfoMap.AddOrSetValue(ParaAddr, vQi);
  end;
end;

procedure TQuotaList.CalculateGlobalUsed;
var
  vGlobalUsed: TQuotaInfo;
  vPointer: TLink<TDictionary<TAddress, TQuotaInfo>>;
  vTmpUsed: TDictionary<TAddress, TQuotaInfo>;
  vTmpItem: TQuotaInfo;
begin
  vGlobalUsed := Default(TQuotaInfo);
  vPointer := mUsedStart;
  while Assigned(vPointer) do
  begin
    vTmpUsed := vPointer.Value;
    for vTmpItem in vTmpUsed.Values do
    begin
      vGlobalUsed.BlockCount := vGlobalUsed.BlockCount + vTmpItem.BlockCount;
      vGlobalUsed.QuotaTotal := vGlobalUsed.QuotaTotal + vTmpItem.QuotaTotal;
      vGlobalUsed.QuotaUsedTotal := vGlobalUsed.QuotaUsedTotal + vTmpItem.QuotaUsedTotal;
    end;
    vPointer := vPointer.Next;
  end;
  mGlobalUsed := vGlobalUsed;
end;

procedure TQuotaList.ResetUsedStart;
var
  i: Integer;
  vPrev: TLink<TDictionary<TAddress, TQuotaInfo>>;
begin
  mUsedStart := mList.Last;
  for i := 1 to mUsedAccumulateHeight - 1 do
  begin
    vPrev := mUsedStart.Prev;
    if not Assigned(vPrev) then
    begin
      break;
    end;
    mUsedStart := vPrev;
  end;
end;

function TQuotaList.Aggregate(ParaQuotaMap: TDictionary<TAddress, TQuotaInfo>): TQuotaInfo;
var
  vQi: TQuotaInfo;
begin
  Result := Default(TQuotaInfo);
  for vQi in ParaQuotaMap.Values do
  begin
    Result.BlockCount := Result.BlockCount + vQi.BlockCount;
    Result.QuotaTotal := Result.QuotaTotal + vQi.QuotaTotal;
    Result.QuotaUsedTotal := Result.QuotaUsedTotal + vQi.QuotaUsedTotal;
  end;
end;

end.
