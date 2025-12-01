unit Ledger.Chain.Flusher.Flusher.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  Ledger.Chain.Flusher.Flusher, Common.DB.XLevelDB, Common.Test.Tools,
  Vite.Common.Types, Common.Utils, Crypto.Hash;

type
  TMockDB = class(TInterfacedObject, IReplay)
  public
    Kv: TDictionary<string, TBytes>;
    constructor Create;
    destructor Destroy; override;
    procedure Put(key, value: TBytes);
    procedure Delete(key: TBytes);
  end;

  TStorageOptions = record
    RedoLogFailed: Boolean;
    CommitFailed: Boolean;
    PatchRedoFailed: Boolean;
  end;

  TMockStorage = class(TInterfacedObject, IStorage)
  private
    FCommitTimes: UInt64;
    FId: TBytes;
    FOpts: TStorageOptions;
    FBatch: TLevelDBBatch;
    FDb: TMockDB;
    function BaseNum: UInt64;
  public
    constructor Create(const ParaName: string; ParaOpt: TStorageOptions; ParaDb: TMockDB);
    destructor Destroy; override;
    function Opts: TStorageOptions;
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

  [TestFixture]
  TTestFlusher = class
  private
    procedure CheckDB(ParaDb: TMockDB; ParaCommitTimes: UInt64; ParaWriteToDB: Boolean);
    function InitFlusher(const ParaOpts: TArray<TStorageOptions>): TPair<TFlusher, TArray<IStorage>>;
    procedure CheckFlusher(ParaTimes: Integer; const ParaOpts: TArray<TStorageOptions>);
    procedure CheckRecover(ParaTimes: Integer; const ParaOpts: TArray<TStorageOptions>);
  public
    [Test]
    procedure TestFlushMultiTimes;
    [Test]
    procedure TestRedoLogFailed;
    [Test]
    procedure TestCommitFailed;
    [Test]
    procedure TestPatchRedoFailed;
    [Test]
    procedure TestRecover;
  end;

implementation

{ TMockDB }

constructor TMockDB.Create;
begin
  inherited Create;
  Kv := TDictionary<string, TBytes>.Create;
end;

destructor TMockDB.Destroy;
begin
  Kv.Free;
  inherited Destroy;
end;

procedure TMockDB.Put(key, value: TBytes);
begin
  Kv.AddOrSetValue(TEncoding.UTF8.GetString(key), value);
end;

procedure TMockDB.Delete(key: TBytes);
begin
  Kv.Remove(TEncoding.UTF8.GetString(key));
end;

{ TMockStorage }

constructor TMockStorage.Create(const ParaName: string; ParaOpt: TStorageOptions; ParaDb: TMockDB);
begin
  inherited Create;
  FId := THash256.GetHash(TEncoding.UTF8.GetBytes(ParaName));
  FOpts := ParaOpt;
  if not Assigned(ParaDb) then
  begin
    FDb := TMockDB.Create
  end
  else
  begin
    FDb := ParaDb;
  end;
end;

destructor TMockStorage.Destroy;
begin
  if Assigned(FBatch) then
  begin
    FBatch.Free;
  end;
  inherited Destroy;
end;

function TMockStorage.Opts: TStorageOptions;
begin
  Result := FOpts;
end;

function TMockStorage.Id: TBytes;
begin
  Result := FId;
end;

function TMockStorage.BaseNum: UInt64;
begin
  Result := FCommitTimes * 30;
end;

procedure TMockStorage.Prepare;
var
  vBaseNum, i: UInt64;
begin
  FBatch := TLevelDBBatch.Create;
  vBaseNum := BaseNum;
  for i := 0 + vBaseNum to vBaseNum + 9 do
  begin
    FBatch.Put(Uint64ToBytes(i), Uint64ToBytes(i));
  end;
  for i := 10 + vBaseNum to vBaseNum + 19 do
  begin
    FBatch.Delete(Uint64ToBytes(i));
  end;
  for i := 20 + vBaseNum to vBaseNum + 29 do
  begin
    FBatch.Put(Uint64ToBytes(i), Uint64ToBytes(i));
  end;
  for i := 25 + vBaseNum to vBaseNum + 34 do
  begin
    FBatch.Delete(Uint64ToBytes(i));
  end;
end;

procedure TMockStorage.CancelPrepare;
begin
  FBatch.Reset;
end;

function TMockStorage.RedoLog: TBytes;
begin
  if FOpts.RedoLogFailed then
  begin
    raise EFlusherException.Create('redoLog failed');
  end;
  Result := FBatch.Dump;
end;

function TMockStorage.Commit: Boolean;
begin
  Inc(FCommitTimes);
  if FOpts.CommitFailed then
  begin
    Result := False;
    Exit;
  end;
  FBatch.Replay(FDb);
  Result := True;
end;

procedure TMockStorage.AfterCommit;
begin
end;

procedure TMockStorage.BeforeRecover(const ParaRedoLog: TBytes);
begin
end;

procedure TMockStorage.AfterRecover;
begin
end;

function TMockStorage.PatchRedoLog(const ParaRedoLog: TBytes): Boolean;
var
  vBatch: TLevelDBBatch;
begin
  if FOpts.PatchRedoFailed then
  begin
    Result := False;
    Exit;
  end;
  vBatch := TLevelDBBatch.Create;
  try
    if not vBatch.Load(ParaRedoLog) then
    begin
      Result := False;
      Exit;
    end;
    vBatch.Replay(FDb);
    Result := True;
  finally
    vBatch.Free;
  end;
end;

{ TTestFlusher }

procedure TTestFlusher.CheckDB(ParaDb: TMockDB; ParaCommitTimes: UInt64; ParaWriteToDB: Boolean);
var
  vKv: TDictionary<string, TBytes>;
  vBaseNum, vKeyNum, vValueNum: UInt64;
  vPair: TPair<string, TBytes>;
begin
  vKv := ParaDb.Kv;
  if ParaWriteToDB then
  begin
    Assert.AreEqual(15 * (ParaCommitTimes + 1), vKv.Count);
  end;
  vBaseNum := ParaCommitTimes * 30;
  for vPair in vKv do
  begin
    vKeyNum := BytesToUint64(TEncoding.UTF8.GetBytes(vPair.Key));
    vValueNum := BytesToUint64(vPair.Value);
    if ParaWriteToDB then
    begin
      Assert.IsFalse(((vKeyNum > 10 + vBaseNum) and (vKeyNum < 20 + vBaseNum)) or (vKeyNum > 25 + vBaseNum));
      Assert.IsFalse(((vValueNum > 10 + vBaseNum) and (vValueNum < 20 + vBaseNum)) or (vValueNum > 25 + vBaseNum));
    end
    else
    begin
      Assert.IsTrue((vKeyNum < vBaseNum) and (vValueNum < vBaseNum));
    end;
  end;
end;

function TTestFlusher.InitFlusher(const ParaOpts: TArray<TStorageOptions>): TPair<TFlusher, TArray<IStorage>>;
var
  vDbList: TList<TMockDB>;
  vStoreList: TList<IStorage>;
  i: Integer;
  vOpt: TStorageOptions;
  vBr: TMockDB;
  vMu: TRTLCriticalSection;
  vChainDir: string;
  vFlusher: TFlusher;
begin
  vDbList := TList<TMockDB>.Create;
  vStoreList := TList<IStorage>.Create;
  try
    for i := 0 to High(ParaOpts) do
    begin
      vOpt := ParaOpts[i];
      vBr := TMockDB.Create;
      vDbList.Add(vBr);
      vStoreList.Add(TMockStorage.Create(Format('mock storage %d', [i]), vOpt, vBr));
    end;

    InitializeCriticalSection(vMu);
    try
      vChainDir := TPath.Combine(DefaultDataDir, 'test_flusher');
      TDirectory.CreateDirectory(vChainDir);
      vFlusher := TFlusher.Create(vStoreList.ToArray, vMu, vChainDir);
      Result := TPair<TFlusher, TArray<IStorage>>.Create(vFlusher, vStoreList.ToArray);
    finally
      DeleteCriticalSection(vMu);
    end;
  finally
    vDbList.Free;
    vStoreList.Free;
  end;
end;

procedure TTestFlusher.CheckFlusher(ParaTimes: Integer; const ParaOpts: TArray<TStorageOptions>);
var
  vPair: TPair<TFlusher, TArray<IStorage>>;
  vFlusher: TFlusher;
  vStoreList: TArray<IStorage>;
  vWriteToDB: Boolean;
  vStore: IStorage;
  vCurrentOpts: TStorageOptions;
  i: UInt64;
  vDb: TMockDB;
begin
  vPair := InitFlusher(ParaOpts);
  vFlusher := vPair.Key;
  vStoreList := vPair.Value;
  vWriteToDB := True;
  for vStore in vStoreList do
  begin
    vCurrentOpts := (vStore as TMockStorage).Opts;
    if vWriteToDB then
    begin
      vWriteToDB := not vCurrentOpts.RedoLogFailed;
    end;
  end;

  for i := 0 to UInt64(ParaTimes - 1) do
  begin
    vFlusher.Flush;
    for vStore in vStoreList do
    begin
      vDb := (vStore as TMockStorage).FDb;
      CheckDB(vDb, i, vWriteToDB);
    end;
  end;
end;

procedure TTestFlusher.CheckRecover(ParaTimes: Integer; const ParaOpts: TArray<TStorageOptions>);
var
  vPair: TPair<TFlusher, TArray<IStorage>>;
  vFlusher: TFlusher;
  i: UInt64;
  vDb: TMockDB;
  vStore: IStorage;
begin
  vPair := InitFlusher(ParaOpts);
  vFlusher := vPair.Key;
  i := 0;
  try
    for i := 0 to UInt64(ParaTimes - 1) do
    begin
      vFlusher.Flush;
    end;
  except
    for vStore in vPair.Value do
    begin
      vDb := (vStore as TMockStorage).FDb;
      CheckDB(vDb, i, False);
    end;
    vFlusher.Recover;
    for vStore in vPair.Value do
    begin
      vDb := (vStore as TMockStorage).FDb;
      CheckDB(vDb, i, True);
    end;
    Exit;
  end;
  Assert.Fail('Exception not raised');
end;

procedure TTestFlusher.TestFlushMultiTimes;
begin
  CheckFlusher(100, []);
end;

procedure TTestFlusher.TestRedoLogFailed;
var
  vOpts: TArray<TStorageOptions>;
begin
  SetLength(vOpts, 1);
  vOpts[0].RedoLogFailed := True;
  CheckFlusher(1, vOpts);
end;

procedure TTestFlusher.TestCommitFailed;
var
  vOpts: TArray<TStorageOptions>;
begin
  SetLength(vOpts, 1);
  vOpts[0].CommitFailed := True;
  CheckFlusher(1, vOpts);
end;

procedure TTestFlusher.TestPatchRedoFailed;
var
  vOpts: TArray<TStorageOptions>;
begin
  SetLength(vOpts, 1);
  vOpts[0].CommitFailed := True;
  vOpts[0].PatchRedoFailed := True;
  Assert.WillRaise(procedure
    begin
      CheckFlusher(1, vOpts);
    end, EFlusherException);
end;

procedure TTestFlusher.TestRecover;
var
  vOpts: TArray<TStorageOptions>;
begin
  SetLength(vOpts, 1);
  vOpts[0].CommitFailed := True;
  vOpts[0].PatchRedoFailed := True;
  CheckRecover(100, vOpts);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlusher);
end.
