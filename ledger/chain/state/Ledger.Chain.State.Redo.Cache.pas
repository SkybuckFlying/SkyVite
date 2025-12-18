unit Ledger.Chain.State.RedoCache;

interface

uses
  Common.Types,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  TRedoCache = class
  private
    mSnapshotLogMap: TDictionary<TUInt64, TSnapshotLog>;
    mCurrentHeight: TUInt64;
    mRetainHeightGap: TUInt64;
    mMutex: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init(ParaCurrentHeight: TUInt64);
    function Current: TSnapshotLog;
    function Get(ParaSnapshotHeight: TUInt64; out ParaSnapshotLog: TSnapshotLog): Boolean;
    procedure Delete(ParaSnapshotHeight: TUInt64);
    procedure Set(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
    procedure SetCurrent(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
    procedure AddLog(ParaAddr: TAddress; ParaLog: TLogItem);
  end;

implementation

{ TRedoCache }

constructor TRedoCache.Create;
begin
  inherited Create;
  mSnapshotLogMap := TDictionary<TUInt64, TSnapshotLog>.Create;
  mRetainHeightGap := 12;
  InitializeCriticalSection(mMutex);
end;

destructor TRedoCache.Destroy;
begin
  mSnapshotLogMap.Free;
  DeleteCriticalSection(mMutex);
  inherited Destroy;
end;

procedure TRedoCache.Init(ParaCurrentHeight: TUInt64);
begin
  EnterCriticalSection(mMutex);
  try
    mSnapshotLogMap.Clear;
    mCurrentHeight := ParaCurrentHeight;
    mSnapshotLogMap.Add(mCurrentHeight, TSnapshotLog.Create);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

function TRedoCache.Current: TSnapshotLog;
begin
  EnterCriticalSection(mMutex);
  try
    Result := mSnapshotLogMap[mCurrentHeight];
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

function TRedoCache.Get(ParaSnapshotHeight: TUInt64; out ParaSnapshotLog: TSnapshotLog): Boolean;
begin
  EnterCriticalSection(mMutex);
  try
    Result := mSnapshotLogMap.TryGetValue(ParaSnapshotHeight, ParaSnapshotLog);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TRedoCache.Delete(ParaSnapshotHeight: TUInt64);
begin
  EnterCriticalSection(mMutex);
  try
    mSnapshotLogMap.Remove(ParaSnapshotHeight);
    if mCurrentHeight >= ParaSnapshotHeight then
    begin
      mCurrentHeight := mCurrentHeight - 1;
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TRedoCache.Set(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
begin
  EnterCriticalSection(mMutex);
  try
    mSnapshotLogMap.AddOrSetValue(ParaSnapshotHeight, ParaSnapshotLog);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TRedoCache.SetCurrent(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
var
  vStaleHeight: TUInt64;
  vHeight: TUInt64;
  vHeightsToRemove: TArray<TUInt64>;
  I: Integer;
begin
  EnterCriticalSection(mMutex);
  try
    mCurrentHeight := ParaSnapshotHeight;
    mSnapshotLogMap.AddOrSetValue(ParaSnapshotHeight, ParaSnapshotLog);
    if (mSnapshotLogMap.Count > mRetainHeightGap) and (ParaSnapshotHeight > mRetainHeightGap) then
    begin
      vStaleHeight := ParaSnapshotHeight - mRetainHeightGap;
      SetLength(vHeightsToRemove, 0);
      for vHeight in mSnapshotLogMap.Keys do
      begin
        if vHeight <= vStaleHeight then
        begin
          vHeightsToRemove := vHeightsToRemove + [vHeight];
        end;
      end;
      for I := 0 to High(vHeightsToRemove) do
      begin
        mSnapshotLogMap.Remove(vHeightsToRemove[I]);
      end;
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TRedoCache.AddLog(ParaAddr: TAddress; ParaLog: TLogItem);
var
  vCurrent: TSnapshotLog;
  vLogList: TArray<TLogItem>;
begin
  EnterCriticalSection(mMutex);
  try
    vCurrent := mSnapshotLogMap[mCurrentHeight];
    if vCurrent.TryGetValue(ParaAddr, vLogList) then
    begin
      vLogList := vLogList + [ParaLog]
    end
    else
    begin
      vLogList := [ParaLog];
    end;
    vCurrent.AddOrSetValue(ParaAddr, vLogList);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

end.
