unit Ledger.Chain.IntegrationTest.Test.Insert;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Chain.Integration.Test.Account.For.Integration,
  Ledger.Chain.IntegrationTest.Test.AccountForIntegration,
  Ledger.Chain.TestTools,
  Ledger.Verifier,
  Log15.Doc,
  Log15.Format,
  Log15.Handler,
  Log15.Handler.Go13,
  Log15.Handler.Go14,
  Log15.Logger,
  Log15.Root,
  Log15.Syslog,
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  VM,
  VM.Quota;

type
  [TestFixture]
  TInsertTest = class
  public
    [Test]
    procedure TestTmpInsert;
    [Test]
    procedure BenchmarkInsert;
  private
    function createVmBlock(ParaAccount: TAccount; ParaAccounts: TDictionary<TAddress, TAccount>): IVmAccountBlock;
    function getRandomAccount(ParaAccounts: TDictionary<TAddress, TAccount>): TAccount;
    function createSnapshotContent(ParaChainInstance: IChain): ISnapshotContent;
    function createSnapshotBlock(ParaChainInstance: IChain; ParaSnapshotAll: Boolean): ISnapshotBlock;
  end;

implementation

uses
  System.Diagnostics,
  System.Math,
  Common.DB.XLevelDB.Util,
  Ledger.TestTools;

{ TInsertTest }

procedure TInsertTest.TestTmpInsert;
var
  vChainInstance: IChain;
  vTempDir: string;
  vAccounts: TDictionary<TAddress, TAccount>;
  vSbCount: Integer;
  vAbCount: Integer;
  vI: Integer;
  vSnapshotBlock: ISnapshotBlock;
  vErr: Exception;
  vRandN: Integer;
  vVmBlock: IVmAccountBlock;
  vAccount: TAccount;
  vIndexDB, vStateDB: IDB;
begin
  TQuota.InitQuotaConfig(True, True);
  TVM.InitVMConfig(True, True, False, False, '');

  vChainInstance := TTestTools.NewTestChainInstance('TestTmpInsert', True, nil, vTempDir);
  try
    vAccounts := MakeAccounts(vChainInstance, 100);

    vSbCount := 0;
    vAbCount := 0;

    for vI := 1 to 10 do
    begin
      Inc(vSbCount);
      vSnapshotBlock := createSnapshotBlock(vChainInstance, True);

      vChainInstance.InsertSnapshotBlock(vSnapshotBlock, vErr);
      if vErr <> nil then
      begin
        raise vErr;
      end;

      if vSbCount mod 1000 = 0 then
      begin
        WriteLn('sbCount', vSbCount);
      end;

      vRandN := Random(100);
      if vRandN > 15 then
      begin
        Continue;
      end;
      Inc(vAbCount);

      vVmBlock := nil;
      repeat
        vAccount := getRandomAccount(vAccounts);
        vVmBlock := createVmBlock(vAccount, vAccounts);
        if vVmBlock <> nil then
        begin
          Break;
        end;
      until False;

      vAccount.InsertBlock(vVmBlock, vAccounts);

      vErr := vChainInstance.InsertAccountBlock(vVmBlock);
      if vErr <> nil then
      begin
        raise vErr;
      end;
    end;

    vIndexDB := vChainInstance.DBs[0];
    vStateDB := vChainInstance.DBs[2];

    vIndexDB.Store.CompactRange(TRange.Create);
    vStateDB.Store.CompactRange(TRange.Create);

    WriteLn(vChainInstance.GetLatestSnapshotBlock.Height);
    WriteLn('sb count', vSbCount, 'ab count', vAbCount);
  finally
    TTestTools.ClearChain(vChainInstance, vTempDir);
  end;
end;

procedure TInsertTest.BenchmarkInsert;
var
  vSnapshotPerNum: Integer;
  vChainInstance: IChain;
  vTempDir: string;
  vVerify: IVerifier;
  vAccounts: TDictionary<TAddress, TAccount>;
  vStopwatch: TStopwatch;
  vI: Integer;
  vSnapshotBlock: ISnapshotBlock;
  vStat: IVerifyStat;
  vQueryTime: TDateTime;
  vErr: Exception;
  vVmBlock: IVmAccountBlock;
  vAccount: TAccount;
  vLatestSnapshotBlock: ISnapshotBlock;
  vBlocks: TArray<IBlock>;
begin
  vSnapshotPerNum := 1;
  TQuota.InitQuotaConfig(True, True);
  TVM.InitVMConfig(True, True, False, False, '');

  vChainInstance := TTestTools.NewTestChainInstance('BenchmarkInsert', True, nil, vTempDir);
  try
    vVerify := TVerifier.Create(vChainInstance).Init(TChainTestTools.NewVerifier, nil, nil);
    vAccounts := MakeAccounts(vChainInstance, 100);

    vStopwatch := TStopwatch.StartNew;
    for vI := 1 to 100 do // Replace b.N with a fixed number for Delphi
    begin
      if vI mod vSnapshotPerNum = 0 then
      begin
        vSnapshotBlock := createSnapshotBlock(vChainInstance, True);
        vStat := vVerify.VerifyReferred(vSnapshotBlock);

        vQueryTime := vSnapshotBlock.Timestamp.AddSeconds(-75);
        vChainInstance.GetSnapshotHeaderBeforeTime(vQueryTime);
        vChainInstance.GetRandomSeed(vSnapshotBlock.Hash, 25);

        if vStat.VerifyResult <> TVerifyResult.Success then
        begin
          raise Exception.Create(vStat.ErrMsg);
        end;
        vChainInstance.InsertSnapshotBlock(vSnapshotBlock, vErr);
        if vErr <> nil then
        begin
          raise vErr;
        end;
        Continue;
      end;

      vVmBlock := nil;
      repeat
        vAccount := getRandomAccount(vAccounts);
        vVmBlock := createVmBlock(vAccount, vAccounts);
        if vVmBlock <> nil then
        begin
          Break;
        end;
      until False;

      vLatestSnapshotBlock := vChainInstance.GetLatestSnapshotBlock;
      if vVmBlock.AccountBlock.Height > 1 then
      begin
        vBlocks := vVerify.VerifyPoolAccountBlock(vVmBlock.AccountBlock, vLatestSnapshotBlock, vErr);
        if vErr <> nil then
        begin
          raise vErr;
        end;
        if vBlocks = nil then
        begin
          raise Exception.Create('verify error!');
        end;
      end;

      vAccount.InsertBlock(vVmBlock, vAccounts);

      vErr := vChainInstance.InsertAccountBlock(vVmBlock);
      if vErr <> nil then
      begin
        raise vErr;
      end;
    end;
    vStopwatch.Stop;
    WriteLn('Elapsed: ', vStopwatch.ElapsedMilliseconds, ' ms');
    WriteLn(vChainInstance.GetLatestSnapshotBlock.Height);
  finally
    TTestTools.ClearChain(vChainInstance, vTempDir);
  end;
end;

function TInsertTest.createVmBlock(ParaAccount: TAccount; ParaAccounts: TDictionary<TAddress, TAccount>): IVmAccountBlock;
var
  vVmBlock: IVmAccountBlock;
  vCreateBlockErr: Exception;
  vLatestHeight: UInt64;
  vIsCreateSendBlock: Boolean;
  vRandNum: Integer;
  vToAccount: TAccount;
begin
  vVmBlock := nil;
  vCreateBlockErr := nil;

  vLatestHeight := ParaAccount.LatestHeight;
  if vLatestHeight < 1 then
  begin
    Result := ParaAccount.CreateReceiveBlock;
    Exit;
  end;

  vIsCreateSendBlock := True;

  if ParaAccount.HasOnRoadBlock then
  begin
    vRandNum := Random(100);
    if vRandNum > 40 then
    begin
      vIsCreateSendBlock := False;
    end;
  end;

  if vIsCreateSendBlock then
  begin
    vToAccount := getRandomAccount(ParaAccounts);
    vVmBlock := ParaAccount.CreateSendBlock(vToAccount);
  end
  else
  begin
    vVmBlock := ParaAccount.CreateReceiveBlock;
  end;

  Result := vVmBlock;
end;

function TInsertTest.getRandomAccount(ParaAccounts: TDictionary<TAddress, TAccount>): TAccount;
var
  vAccount: TAccount;
  vKey: TAddress;
begin
  for vKey in ParaAccounts.Keys do
  begin
    vAccount := ParaAccounts[vKey];
    Break;
  end;
  Result := vAccount;
end;

function TInsertTest.createSnapshotContent(ParaChainInstance: IChain): ISnapshotContent;
var
  vUnconfirmedBlocks: TArray<IBlock>;
  vSc: ISnapshotContent;
  vI: Integer;
  vBlock: IBlock;
  vHashHeight: IHashHeight;
begin
  vUnconfirmedBlocks := ParaChainInstance.GetAllUnconfirmedBlocks;
  vSc := TSnapshotContent.Create;

  for vI := High(vUnconfirmedBlocks) downto 0 do
  begin
    vBlock := vUnconfirmedBlocks[vI];
    if not vSc.ContainsKey(vBlock.AccountAddress) then
    begin
      vHashHeight := THashHeight.Create;
      vHashHeight.Hash := vBlock.Hash;
      vHashHeight.Height := vBlock.Height;
      vSc.Add(vBlock.AccountAddress, vHashHeight);
    end;
  end;

  Result := vSc;
end;

function TInsertTest.createSnapshotBlock(ParaChainInstance: IChain; ParaSnapshotAll: Boolean): ISnapshotBlock;
var
  vLatestSb: ISnapshotBlock;
  vSbNow: TDateTime;
  vSb: ISnapshotBlock;
begin
  vLatestSb := ParaChainInstance.GetLatestSnapshotBlock;
  vSbNow := vLatestSb.Timestamp.AddSeconds(1);

  vSb := TSnapshotBlock.Create;
  vSb.PrevHash := vLatestSb.Hash;
  vSb.Height := vLatestSb.Height + 1;
  vSb.Timestamp := vSbNow;
  vSb.SnapshotContent := createSnapshotContent(ParaChainInstance);
  vSb.Hash := vSb.ComputeHash;
  Result := vSb;
end;

initialization
  TDUnitX.RegisterTestFixture(TInsertTest);
end.
