unit Ledger.Onroad.Pool.CallerCache.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Ledger.Onroad.Pool.Types,
  Common.Types,
  Ledger.Onroad.Pool.Storage,
  GoToDelphi.Helpers.LevelDB;

type
  TNormalCase = record
    mTxs: TArray<TOrHashHeight>;
    mCaller: TAddress;
    mExpectedFrontTxHeight: UInt64;
    mExpectedFrontTxSize: Integer;
  end;

  TOrHashHeightAction = record
    mOrHashHeight: TOrHashHeight;
    mNewOrDestory: Boolean; // true -> new, false -> destory
    mInsertOrRollback: Boolean; // true -> insert, false -> rollback
  end;

  TCaseStruct = record
    mActions: TArray<TOrHashHeightAction>;
    mCaller: TAddress;
    mExpectedFrontTxHeight: UInt64;
    mExpectedFrontTxSize: Integer;
  end;

  [TestFixture]
  TCallerCacheTest = class(TObject)
  private
    FDb: TLevelDB;
    FDir: string;
    function GenerateCases: TArray<TNormalCase>;
    function GenerateCases2: TArray<TCaseStruct>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestCallerCache1;
    [Test]
    procedure TestCallerCache2;
  end;

implementation

uses
  System.Generics.Collections;

procedure TCallerCacheTest.Setup;
var
  vHomeDir: string;
begin
  vHomeDir := TPath.GetHomePath;
  FDir := TPath.Combine(vHomeDir, '.gvite');
  FDir := TPath.Combine(FDir, 'tmp');
  FDir := TPath.Combine(FDir, 'onroad');
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
  TDirectory.CreateDirectory(FDir);
  FDb := TLevelDB.OpenFile(FDir);
end;

procedure TCallerCacheTest.TearDown;
begin
  FDb.Free;
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
end;

function TCallerCacheTest.GenerateCases: TArray<TNormalCase>;
begin
  SetLength(Result, 3);
  Result[0].mTxs := [
    TOrHashHeight.Create(TDataHash.FromBytes([1]), 2, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([2]), 1, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([3]), 1, nil)
  ];
  Result[0].mCaller := TAddressAsset;
  Result[0].mExpectedFrontTxHeight := 1;
  Result[0].mExpectedFrontTxSize := 2;

  Result[1].mTxs := [
    TOrHashHeight.Create(TDataHash.FromBytes([1]), 1, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([2]), 1, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([3]), 1, nil)
  ];
  Result[1].mCaller := TAddressAsset;
  Result[1].mExpectedFrontTxHeight := 1;
  Result[1].mExpectedFrontTxSize := 3;

  Result[2].mTxs := [
    TOrHashHeight.Create(TDataHash.FromBytes([1]), 4, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([2]), 1, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([3]), 3, nil),
    TOrHashHeight.Create(TDataHash.FromBytes([4]), 1, nil)
  ];
  Result[2].mCaller := TAddressAsset;
  Result[2].mExpectedFrontTxHeight := 1;
  Result[2].mExpectedFrontTxSize := 2;
end;

function TCallerCacheTest.GenerateCases2: TArray<TCaseStruct>;
var
  vSubIndex: ^uint32;
begin
  SetLength(Result, 1);
  new(vSubIndex);
  Result[0].mActions := [
    TOrHashHeightAction.Create(TOrHashHeight.Create(TDataHash.FromBytes([1]), 1, vSubIndex), True, True),
    TOrHashHeightAction.Create(TOrHashHeight.Create(TDataHash.FromBytes([2]), 2, vSubIndex), True, True),
    TOrHashHeightAction.Create(TOrHashHeight.Create(TDataHash.FromBytes([3]), 1, vSubIndex), True, True),
    TOrHashHeightAction.Create(TOrHashHeight.Create(TDataHash.FromBytes([2]), 2, vSubIndex), False, True),
    TOrHashHeightAction.Create(TOrHashHeight.Create(TDataHash.FromBytes([3]), 1, vSubIndex), False, True)
  ];
  Result[0].mCaller := TAddressAsset;
  Result[0].mExpectedFrontTxHeight := 1;
  Result[0].mExpectedFrontTxSize := 1;
end;

procedure TCallerCacheTest.TestCallerCache1;
var
  vCases: TArray<TNormalCase>;
  vItem: TNormalCase;
  vCC: TCallerCache;
  vTx: TOrHashHeight;
  vOhv: TOrHashHeightVersion;
  vOhvs: TArray<TOrHashHeightVersion>;
  vTxs: TArray<TOrHashHeight>;
  vStorage: IOnroadStorage;
begin
  vCases := GenerateCases;
  for vItem in vCases do
  begin
    if TDirectory.Exists(FDir) then
      TDirectory.Delete(FDir, True);
    TDirectory.CreateDirectory(FDir);
    FDb.Free;
    FDb := TLevelDB.OpenFile(FDir);
    vStorage := TOnroadStorage.Create(FDb);
    vCC := TCallerCache.Create(TAddressDexFund, vStorage);
    for vTx in vItem.mTxs do
    begin
      vCC.AddTx(vItem.mCaller, vTx, True);
    end;

    vOhv := vCC.GetFrontTxByCaller(vItem.mCaller);
    Assert.IsNotNull(vOhv);
    vTxs := vOhv.Value;
    Assert.AreEqual(vItem.mExpectedFrontTxHeight, vTxs[0].mHeight);
    Assert.AreEqual(vItem.mExpectedFrontTxSize, Length(vTxs));

    vOhvs := vCC.GetFrontTxOfAllCallers;
    Assert.IsNotNull(vOhvs);
    Assert.AreEqual(1, Length(vOhvs));
    vTxs := vOhvs[0].Value;
    Assert.AreEqual(vItem.mExpectedFrontTxHeight, vTxs[0].mHeight);
    Assert.AreEqual(vItem.mExpectedFrontTxSize, Length(vTxs));
    vCC.Free;
  end;
end;

procedure TCallerCacheTest.TestCallerCache2;
var
  vCases: TArray<TCaseStruct>;
  vItem: TCaseStruct;
  vCC: TCallerCache;
  vAction: TOrHashHeightAction;
  vOhv: TOrHashHeightVersion;
  vOhvs: TArray<TOrHashHeightVersion>;
  vTxs: TArray<TOrHashHeight>;
  vStorage: IOnroadStorage;
begin
  vCases := GenerateCases2;
  for vItem in vCases do
  begin
    if TDirectory.Exists(FDir) then
      TDirectory.Delete(FDir, True);
    TDirectory.CreateDirectory(FDir);
    FDb.Free;
    FDb := TLevelDB.OpenFile(FDir);
    vStorage := TOnroadStorage.Create(FDb);
    vCC := TCallerCache.Create(TAddressGovernance, vStorage);

    for vAction in vItem.mActions do
    begin
      if vAction.mNewOrDestory then
        vCC.AddTx(vItem.mCaller, vAction.mOrHashHeight, True)
      else
        vCC.RmTx(vItem.mCaller, False, vAction.mOrHashHeight, False);
    end;

    vOhv := vCC.GetFrontTxByCaller(vItem.mCaller);
    Assert.IsNotNull(vOhv);
    vTxs := vOhv.Value;
    Assert.AreEqual(vItem.mExpectedFrontTxHeight, vTxs[0].mHeight);
    Assert.AreEqual(vItem.mExpectedFrontTxSize, Length(vTxs));

    vOhvs := vCC.GetFrontTxOfAllCallers;
    Assert.IsNotNull(vOhvs);
    Assert.AreEqual(1, Length(vOhvs));
    vTxs := vOhvs[0].Value;
    Assert.AreEqual(vItem.mExpectedFrontTxHeight, vTxs[0].mHeight);
    Assert.AreEqual(vItem.mExpectedFrontTxSize, Length(vTxs));
    vCC.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCallerCacheTest);
end.
