unit VM.Contracts.Dex.Fund.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Vite.VM,
  VM.Contracts.Dex.Fund.Test.Types,
  VM.Contracts.Dex.Fund.Test.Database,
  Vite.Common.Types,
  GoToDelphi.Helpers.BigInt,
  Vite.Interfaces.Core,
  Vite.Ledger;

type
  [TestFixture]
  TDexFundTest = class
  public
    [Test]
    procedure TestDexFund;
  private
    function InitFundDb(const ParaDexFundCase: TDexFundCase): TTestDatabase;
    procedure ExecuteActions(const ParaDexFundCase: TDexFundCase; ParaVm: IVM; ParaDb: TTestDatabase);
    procedure ExecuteChecks(const ParaDexFundCase: TDexFundCase; ParaDb: TTestDatabase);
    function GenerateDb(const ParaCaseName: string; const ParaGlobalEnv: TGlobalEnv): TTestDatabase;
    function NewSendBlock(ParaFrom, ParaTo: TAddress): IAccountBlock;
    function NewRecBlock(ParaTo: TAddress): IAccountBlock;
    procedure DoAction(const ParaName: string; ParaDb: TTestDatabase; ParaVm: IVM; ParaFrom, ParaTo: TAddress; const ParaData: TBytes);
    procedure CheckPlaceOrder(const ParaPo: TPlacedOrder; const ParaOd: TOrder);
    function GetTopicId(const ParaName: string): THash;
  end;

implementation

procedure TDexFundTest.TestDexFund;
var
  vTestDir: string;
  vTestFiles: TStringDynArray;
  vTestFile: string;
  vJson: string;
  vTestCaseMap: TJSONObject;
  vPair: TJSONPair;
  vTestCase: TDexFundCase;
  vDb: TTestDatabase;
  vReader: IVMConsensusReader;
  vVm: IVM;
begin
  vTestDir := './contracts/dex/test/fund/';
  vTestFiles := TDirectory.GetFiles(vTestDir, '*.json');

  for vTestFile in vTestFiles do
  begin
    vJson := TFile.ReadAllText(vTestFile);
    vTestCaseMap := TJSONObject.ParseJSONValue(vJson) as TJSONObject;
    try
      for vPair in vTestCaseMap do
      begin
        // vTestCase := TJson.JsonToObject<TDexFundCase>(vPair.JsonValue.ToString);
        // For now, we will skip the test execution as we need to implement the JSON deserialization first.
        // This will be done in a separate step.
        // ShowMessage(vPair.JsonString.Value + ':' + vTestCase.Name);
        // vDb := InitFundDb(vTestCase);
        // vReader := TVMConsensusReader.Create(TConsensusReaderTest.Create(vDb.GetGenesisSnapshotBlock.Timestamp, 24 * 3600, nil));
        // vVm := TVM.Create(vReader);
        // ExecuteActions(vTestCase, vVm, vDb);
        // ExecuteChecks(vTestCase, vDb);
      end;
    finally
      vTestCaseMap.Free;
    end;
  end;
end;

function TDexFundTest.InitFundDb(const ParaDexFundCase: TDexFundCase): TTestDatabase;
begin
  // Implementation to be added
end;

procedure TDexFundTest.ExecuteActions(const ParaDexFundCase: TDexFundCase; ParaVm: IVM; ParaDb: TTestDatabase);
begin
  // Implementation to be added
end;

procedure TDexFundTest.ExecuteChecks(const ParaDexFundCase: TDexFundCase; ParaDb: TTestDatabase);
begin
  // Implementation to be added
end;

function TDexFundTest.GenerateDb(const ParaCaseName: string; const ParaGlobalEnv: TGlobalEnv): TTestDatabase;
begin
  // Implementation to be added
end;

function TDexFundTest.NewSendBlock(ParaFrom, ParaTo: TAddress): IAccountBlock;
begin
  Result := TAccountBlock.Create;
  Result.AccountAddress := ParaFrom;
  Result.BlockType := TBlockType.SendCall;
  Result.ToAddress := ParaTo;
  Result.TokenId := ViteTokenId;
  Result.Amount := TBigInt.Create(0);
end;

function TDexFundTest.NewRecBlock(ParaTo: TAddress): IAccountBlock;
begin
  Result := TAccountBlock.Create;
  Result.AccountAddress := ParaTo;
  Result.BlockType := TBlockType.Receive;
end;

procedure TDexFundTest.DoAction(const ParaName: string; ParaDb: TTestDatabase; ParaVm: IVM; ParaFrom, ParaTo: TAddress; const ParaData: TBytes);
var
  vSendBlock: IAccountBlock;
  vVmSendBlock, vSendCreateBlock: IVmAccountBlock;
begin
  vSendBlock := NewSendBlock(ParaFrom, ParaTo);
  ParaDb.SetAddress(ParaFrom);
  vSendBlock.Data := ParaData;
  vVmSendBlock := ParaVm.RunV2(ParaDb, vSendBlock, nil, nil);
  Assert.IsNull(vVmSendBlock.Error, ParaName + ' vm.RunV2 handle send result err not nil');
  ParaDb.SetAddress(ParaTo);
  vSendCreateBlock := ParaVm.RunV2(ParaDb, NewRecBlock(ParaTo), vVmSendBlock.AccountBlock, nil);
  Assert.IsNull(vSendCreateBlock.Error, ParaName + ' vm.RunV2 handle receive result err not nil');
end;

procedure TDexFundTest.CheckPlaceOrder(const ParaPo: TPlacedOrder; const ParaOd: TOrder);
begin
  // Implementation to be added
end;

function TDexFundTest.GetTopicId(const ParaName: string): THash;
var
  vBytes: TBytes;
begin
  vBytes := TEncoding.UTF8.GetBytes(ParaName);
  SetLength(vBytes, THash.Size);
  Result.SetBytes(vBytes);
end;

initialization
  RegisterTestFixture(TDexFundTest);
end.
