unit Ledger.Onroad.Pool.Storage.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  GoToDelphi.Helpers.LevelDB,
  Ledger.Onroad.Pool.Caller.Cache.Test,
  Ledger.Onroad.Pool.Contract.Pool,
  Ledger.Onroad.Pool.Error.Table,
  Ledger.Onroad.Pool.Pool,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Types,
  Ledger.Onroad.Pool.Types.Test,
  System.IOUtils,
  System.SysUtils;

type
  TTxAction = record
    mFromHash: Byte;
    mFromHeight: UInt64;
    mAction: Boolean;
    mIndex: Int64;
  end;

  TStorageCase = record
    mActions: TArray<TTxAction>;
    mExpectedTxs: TArray<TTxAction>;
  end;

  [TestFixture]
  TOnroadStorageTest = class(TObject)
  private
    FDb: TLevelDB;
    FDir: string;
    procedure ClearTestStorage;
    function NewTestStorage: IOnroadStorage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestOnroadStorages;
  end;

implementation

uses
  System.Generics.Collections;

procedure TOnroadStorageTest.Setup;
var
  vHomeDir: string;
begin
  vHomeDir := TPath.GetHomePath;
  FDir := TPath.Combine(vHomeDir, '.gvite');
  FDir := TPath.Combine(FDir, 'tmp');
  FDir := TPath.Combine(FDir, 'onroad');
  ClearTestStorage;
end;

procedure TOnroadStorageTest.TearDown;
begin
  ClearTestStorage;
end;

procedure TOnroadStorageTest.ClearTestStorage;
begin
  if TDirectory.Exists(FDir) then
    TDirectory.Delete(FDir, True);
end;

function TOnroadStorageTest.NewTestStorage: IOnroadStorage;
begin
  if not TDirectory.Exists(FDir) then
    TDirectory.CreateDirectory(FDir);
  FDb := TLevelDB.OpenFile(FDir);
  Result := TOnroadStorage.Create(FDb);
end;

procedure TOnroadStorageTest.TestOnroadStorages;
var
  vCases: TArray<TStorageCase>;
  vFromAddr, vToAddr: TAddress;
  vCe: TStorageCase;
  vStorage: IOnroadStorage;
  vAction: TTxAction;
  vIndex: PUInt32;
  vDd: UInt32;
  vOnroadTx: TOnroadTx;
  vOt: TArray<TOnroadTx>;
  vI: Integer;
  vTx: TOnroadTx;
begin
  SetLength(vCases, 2);
  vCases[0].mActions := [
    TTxAction.Create(1, 10, True, -1),
    TTxAction.Create(2, 10, True, 0),
    TTxAction.Create(3, 8, True, 0),
    TTxAction.Create(3, 8, False, 0)
  ];
  vCases[0].mExpectedTxs := [
    TTxAction.Create(2, 10, False, 0),
    TTxAction.Create(1, 10, False, -1)
  ];

  vCases[1].mActions := [
    TTxAction.Create(1, 10, True, -1),
    TTxAction.Create(2, 10, True, 0),
    TTxAction.Create(3, 8, True, 1),
    TTxAction.Create(2, 10, False, 0)
  ];
  vCases[1].mExpectedTxs := [
    TTxAction.Create(3, 8, False, 1)
  ];

  vFromAddr := TAddressDexFund;
  vToAddr := TAddressDexTrade;

  ClearTestStorage;
  for vCe in vCases do
  begin
    vStorage := NewTestStorage;
    for vAction in vCe.mActions do
    begin
      vIndex := nil;
      if vAction.mIndex >= 0 then
      begin
        vDd := vAction.mIndex;
        vIndex := @vDd;
      end;

      vOnroadTx := Default(TOnroadTx);
      vOnroadTx.mFromAddr := vFromAddr;
      vOnroadTx.mToAddr := vToAddr;
      vOnroadTx.mFromHeight := vAction.mFromHeight;
      vOnroadTx.mFromHash := TDataHash.FromBytes([vAction.mFromHash]);
      vOnroadTx.mFromIndex := vIndex;

      if vAction.mAction then
        vStorage.InsertOnRoadTx(vOnroadTx)
      else
        vStorage.DeleteOnRoadTx(vOnroadTx);
    end;
    vOt := vStorage.GetFirstOnroadTx(vToAddr, vFromAddr);

    for vI := 0 to High(vOt) do
    begin
      vTx := vOt[vI];
      Assert.AreEqual(vCe.mExpectedTxs[vI].mFromHeight, vTx.mFromHeight);
      Assert.AreEqual(TDataHash.FromBytes([vCe.mExpectedTxs[vI].mFromHash]), vTx.mFromHash);
      if vTx.mFromIndex = nil then
        Assert.AreEqual(Int64(-1), vCe.mExpectedTxs[vI].mIndex)
      else
        Assert.AreEqual(vCe.mExpectedTxs[vI].mIndex, Int64(vTx.mFromIndex^));
    end;
    FDb.Free;
    ClearTestStorage;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TOnroadStorageTest);
end.
