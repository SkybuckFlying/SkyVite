unit Ledger.Chain.Flusher.Flusher;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections,
  System.IOUtils, System.Threading,
  Vite.Common.Types, Common.Log, Common.FileUtils, Crypto.Hash;

type
  EFlusherException = class(Exception);

  IStorage = interface
    ['{B5F4C3D2-A1B0-C9D8-E7F6-A5B4C3D2E1F0}']
    function Id: TBytes;
    procedure Prepare;
    procedure CancelPrepare;
    function RedoLog: TBytes;
    function Commit: Boolean;
    procedure AfterCommit;
    procedure BeforeRecover(const ParaRedoLog: TBytes);
    procedure AfterRecover;
    function PatchRedoLog(const ParaRedoLog: TBytes): Boolean;
  end;

  TFlusher = class
  private
    const
      StopStatus = 0;
      StartStatus = 1;
      AbortedStatus = 2;
  private
    mDirName: string;
    mStoreList: TList<IStorage>;
    mIdMap: TDictionary<TBytes, IStorage>;
    mLog: ILogger;
    mFd: TFileStream;
    mMu: TRTLCriticalSection;
    mSyncFlush: TCountdownEvent;
    mWg: TCountdownEvent;
    mFlushInterval: Cardinal;
    mFlushingMu: TRTLCriticalSection;
    mStartCommitFlag: TBytes;
    mCommitWg: TCountdownEvent;
    mTerminal: TEvent;
    mFlusherStatus: Integer;
    procedure LoopFlush;
    procedure FlushInternal;
    procedure WriteRedoLog;
    function SyncRedoLog: Boolean;
    function CommitAll: Boolean;
    procedure AfterCommitAll;
    procedure BeforeRecoverAll(const ParaStores: TArray<IStorage>; const ParaRedoLogList: TArray<TBytes>);
    procedure AfterRecoverAll;
    function Redo(const ParaStores: TArray<IStorage>; const ParaRedoLogList: TArray<TBytes>): Boolean;
    function LoadRedo(ParaFd: TFileStream): TPair<TArray<TBytes>, TArray<IStorage>>;
    procedure CleanRedoLog;
    procedure PrepareAll;
    function CommitRedo: Boolean;
  public
    constructor Create(const ParaStoreList: TArray<IStorage>; ParaFlushMu: TRTLCriticalSection; const ParaChainDir: string);
    destructor Destroy; override;
    procedure Close;
    procedure ReplaceStore(const ParaId: TBytes; const ParaStore: IStorage);
    procedure Abort;
    procedure Start;
    procedure Stop;
    procedure Flush;
    function Recover: Boolean;
    function LoadRedoPublic(ParaFd: TFileStream): TPair<TArray<TBytes>, TArray<IStorage>>;
  end;

implementation

{ TFlusher }

constructor TFlusher.Create(const ParaStoreList: TArray<IStorage>; ParaFlushMu: TRTLCriticalSection; const ParaChainDir: string);
var
  vFileName: string;
  vStore: IStorage;
  vStartCommitFlagBytes: TBytes;
begin
  inherited Create;
  vFileName := TPath.Combine(ParaChainDir, 'flush.redo.log');
  if not TFile.Exists(vFileName) then
  begin
    mFd := TFileStream.Create(vFileName, fmCreate)
  end
  else
  begin
    mFd := TFileStream.Create(vFileName, fmOpenReadWrite);
  end;

  mIdMap := TDictionary<TBytes, IStorage>.Create;
  mStoreList := TList<IStorage>.Create;
  for vStore in ParaStoreList do
  begin
    mIdMap.Add(vStore.Id, vStore);
    mStoreList.Add(vStore);
  end;

  vStartCommitFlagBytes := TEncoding.UTF8.GetBytes('start commit');
  mStartCommitFlag := THash256.GetHash(vStartCommitFlagBytes);

  mDirName := TPath.Combine(ParaChainDir, 'flusher');
  mMu := ParaFlushMu;
  mLog := TLog.New('module', 'flusher');
  mFlushInterval := 900;
  mTerminal := TEvent.Create(nil, True, False, '');
  mFlusherStatus := StopStatus;
  InitializeCriticalSection(mFlushingMu);
end;

destructor TFlusher.Destroy;
begin
  Close;
  mIdMap.Free;
  mStoreList.Free;
  mTerminal.Free;
  DeleteCriticalSection(mFlushingMu);
  inherited Destroy;
end;

procedure TFlusher.Close;
begin
  if Assigned(mFd) then
  begin
    mFd.Free;
    mFd := nil;
  end;
end;

procedure TFlusher.ReplaceStore(const ParaId: TBytes; const ParaStore: IStorage);
var
  i: Integer;
begin
  EnterCriticalSection(mFlushingMu);
  try
    mIdMap.AddOrSetValue(ParaId, ParaStore);
    for i := 0 to mStoreList.Count - 1 do
    begin
      if TBytes.Equals(mStoreList[i].Id, ParaId) then
      begin
        mStoreList[i] := ParaStore;
        break;
      end;
    end;
  finally
    LeaveCriticalSection(mFlushingMu);
  end;
end;

procedure TFlusher.Abort;
begin
  if TInterlocked.CompareExchange(mFlusherStatus, AbortedStatus, StartStatus) = StartStatus then
  begin
    mTerminal.SetEvent;
    if Assigned(mWg) then
    begin
      mWg.Wait;
    end;
  end;
end;

procedure TFlusher.Start;
begin
  if TInterlocked.CompareExchange(mFlusherStatus, StartStatus, StopStatus) = StopStatus then
  begin
    mTerminal.ResetEvent;
    TTask.Run(procedure
      begin
        LoopFlush;
      end);
  end;
end;

procedure TFlusher.Stop;
begin
  if TInterlocked.CompareExchange(mFlusherStatus, StopStatus, StartStatus) = StartStatus then
  begin
    mTerminal.SetEvent;
    if Assigned(mWg) then
    begin
      mWg.Wait;
    end;
  end;
end;

procedure TFlusher.Flush;
begin
  FlushInternal;
end;

function TFlusher.Recover: Boolean;
var
  vPair: TPair<TArray<TBytes>, TArray<IStorage>>;
begin
  EnterCriticalSection(mMu);
  try
    vPair := LoadRedo(mFd);
    if (Length(vPair.Key) = 0) then
    begin
      CleanRedoLog;
      Result := True;
      Exit;
    end;

    BeforeRecoverAll(vPair.Value, vPair.Key);
    if not Redo(vPair.Value, vPair.Key) then
    begin
      Result := False;
      Exit;
    end;
    AfterRecoverAll;
    Result := True;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TFlusher.LoadRedoPublic(ParaFd: TFileStream): TPair<TArray<TBytes>, TArray<IStorage>>;
begin
  Result := LoadRedo(ParaFd);
end;

procedure TFlusher.LoopFlush;
begin
  mWg := TCountdownEvent.Create(1);
  try
    while True do
    begin
      if mTerminal.WaitFor(mFlushInterval) = wrSignaled then
      begin
        if TInterlocked.Read(mFlusherStatus) = AbortedStatus then
        begin
          mLog.Warn('flusher is aborted', ['method', 'loopFlush']);
          Exit;
        end;
        FlushInternal;
        Exit;
      end;
      FlushInternal;
    end;
  finally
    mWg.Signal;
  end;
end;

procedure TFlusher.FlushInternal;
begin
  EnterCriticalSection(mFlushingMu);
  try
    PrepareAll;
    WriteRedoLog;
    if not SyncRedoLog then
    begin
      Exit;
    end;
    if not CommitAll then
    begin
      if not CommitRedo then
      begin
        raise EFlusherException.Create('Failed to commit redo log');
      end;
    end;
    AfterCommitAll;
    CleanRedoLog;
  finally
    LeaveCriticalSection(mFlushingMu);
  end;
end;

procedure TFlusher.WriteRedoLog;
var
  vStore: IStorage;
  vRedoLog: TBytes;
  vRedoLogLengthBytes: TBytes;
begin
  CleanRedoLog;
  SetLength(vRedoLogLengthBytes, 4);
  for vStore in mStoreList do
  begin
    vRedoLog := vStore.RedoLog;
    if Length(vRedoLog) > 0 then
    begin
      mFd.Write(vStore.Id, Length(vStore.Id));
      TBitConverter.GetBytes(Length(vRedoLog), vRedoLogLengthBytes);
      mFd.Write(vRedoLogLengthBytes, 4);
      mFd.Write(vRedoLog, Length(vRedoLog));
    end;
  end;
  mFd.Write(mStartCommitFlag, Length(mStartCommitFlag));
end;

function TFlusher.SyncRedoLog: Boolean;
begin
  try
    mFd.Flush;
    Result := True;
  except
    on E: Exception do
    begin
      mLog.Error(Format('sync failed. Error: %s', [E.Message]), ['method', 'Flush']);
      EnterCriticalSection(mMu);
      try
        for var store in mStoreList do
        begin
          store.CancelPrepare;
        end;
      finally
        LeaveCriticalSection(mMu);
      end;
      CleanRedoLog;
      Result := False;
    end;
  end;
end;

function TFlusher.CommitAll: Boolean;
var
  vCommitErr: Boolean;
  vStore: IStorage;
begin
  vCommitErr := False;
  mCommitWg := TCountdownEvent.Create(mStoreList.Count);
  for vStore in mStoreList do
  begin
    TTask.Run(procedure(Store: IStorage)
      begin
        try
          if not Store.Commit then
          begin
            vCommitErr := True;
            mLog.Error(Format('%s commit failed.', [Store.Id.ToString]), ['method', 'Flush']);
          end;
        finally
          mCommitWg.Signal;
        end;
      end, vStore);
  end;
  mCommitWg.Wait;
  Result := not vCommitErr;
end;

procedure TFlusher.AfterCommitAll;
begin
  EnterCriticalSection(mMu);
  try
    for var store in mStoreList do
    begin
      store.AfterCommit;
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TFlusher.BeforeRecoverAll(const ParaStores: TArray<IStorage>; const ParaRedoLogList: TArray<TBytes>);
var
  i: Integer;
begin
  for i := 0 to High(ParaRedoLogList) do
  begin
    ParaStores[i].BeforeRecover(ParaRedoLogList[i]);
  end;
end;

procedure TFlusher.AfterRecoverAll;
begin
  for var store in mStoreList do
  begin
    store.AfterRecover;
  end;
end;

function TFlusher.Redo(const ParaStores: TArray<IStorage>; const ParaRedoLogList: TArray<TBytes>): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to High(ParaRedoLogList) do
  begin
    if not ParaStores[i].PatchRedoLog(ParaRedoLogList[i]) then
    begin
      Result := False;
      Exit;
    end;
  end;
  CleanRedoLog;
end;

function TFlusher.LoadRedo(ParaFd: TFileStream): TPair<TArray<TBytes>, TArray<IStorage>>;
var
  vFileSize: Int64;
  vBuf: TBytes;
  vCurrentPointer, vNextPointer, vEndPointer, vStatus, vSize: Integer;
  vRedoLogList: TList<TBytes>;
  vStores: TList<IStorage>;
  vHasStartCommitFlag: Boolean;
  vBuffer: TBytes;
  vId: TBytes;
  vStore: IStorage;
begin
  vFileSize := ParaFd.Size;
  if vFileSize <= 0 then
  begin
    Result := TPair<TArray<TBytes>, TArray<IStorage>>.Create(nil, nil);
    Exit;
  end;

  SetLength(vBuf, vFileSize);
  ParaFd.Position := 0;
  ParaFd.Read(vBuf, 0, vFileSize);

  vCurrentPointer := 0;
  vEndPointer := vFileSize;
  vStatus := 0;
  vSize := 32; // HashSize
  vRedoLogList := TList<TBytes>.Create;
  vStores := TList<IStorage>.Create;
  vHasStartCommitFlag := False;

  try
    while True do
    begin
      vNextPointer := vCurrentPointer + vSize;
      if vNextPointer > vEndPointer then
      begin
        break;
      end;
      vBuffer := Copy(vBuf, vCurrentPointer, vSize);
      if Length(vBuffer) < vSize then
      begin
        raise EFlusherException.Create('read redo log failed');
      end;

      case vStatus of
        0:
          begin
            vId := vBuffer;
            if TBytes.Equals(vId, mStartCommitFlag) then
            begin
              vHasStartCommitFlag := True;
              break;
            end;
            if not mIdMap.TryGetValue(vId, vStore) then
            begin
              raise EFlusherException.CreateFmt('id is not existed, id: %s', [vId.ToString]);
            end;
            vStores.Add(vStore);
            vStatus := 1;
            vSize := 4;
          end;
        1:
          begin
            vStatus := 2;
            vSize := TBitConverter.ToUInt32(vBuffer, 0);
          end;
        2:
          begin
            vRedoLogList.Add(vBuffer);
            vStatus := 0;
            vSize := 32; // HashSize
          end;
      end;
      vCurrentPointer := vNextPointer;
    end;

    if not vHasStartCommitFlag then
    begin
      Result := TPair<TArray<TBytes>, TArray<IStorage>>.Create(nil, nil);
      Exit;
    end;

    Result := TPair<TArray<TBytes>, TArray<IStorage>>.Create(vRedoLogList.ToArray, vStores.ToArray);
  finally
    vRedoLogList.Free;
    vStores.Free;
  end;
end;

procedure TFlusher.CleanRedoLog;
begin
  mFd.Size := 0;
  mFd.Position := 0;
end;

procedure TFlusher.PrepareAll;
begin
  EnterCriticalSection(mMu);
  try
    if TInterlocked.Read(mFlusherStatus) = AbortedStatus then
    begin
      raise EFlusherException.Create('flusher is aborted');
    end;
    for var store in mStoreList do
    begin
      store.Prepare;
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TFlusher.CommitRedo: Boolean;
var
  vPair: TPair<TArray<TBytes>, TArray<IStorage>>;
begin
  vPair := LoadRedo(mFd);
  Result := Redo(vPair.Value, vPair.Key);
end;

end.
