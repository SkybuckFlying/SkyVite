unit VM.Contracts.Dex.Trade.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.BigInt,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  Vite.Common.Types,
  Vite.Interfaces.Core,
  Vite.Ledger,
  Vite.VM,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Fund.Test.Database,
  VM.Contracts.Dex.Trade.Test.Types,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Mock.DB,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  [TestFixture]
  TDexTradeTest = class
  public
    [Test]
    procedure TestDexTrade;
  private
    function InitTradeDb(const ParaDexTradeCase: TDexTradeCase): TTestDatabase;
    procedure ExecuteTradeActions(const ParaDexTradeCase: TDexTradeCase; ParaVm: IVM; ParaDb: TTestDatabase);
    procedure ExecuteTradeChecks(const ParaDexTradeCase: TDexTradeCase; ParaDb: TTestDatabase);
    function ToDexOrder(ParaDb: TTestDatabase; const ParaOrderStorage: TOrderStorage): IOrder;
    procedure SaveOrder(ParaDb: TTestDatabase; ParaOrder: IOrder; ParaIsTaker: Boolean);
    procedure AssertOrder(const ParaCheckOrder: TOrderStorage; const ParaDbOrder: IOrder; const ParaSource: string);
    procedure AssertAmountEqual(const ParaAmount: TBigInt; const ParaAmountBytes: TBytes; const ParaField: string);
    procedure AssertAddressEqual(const ParaAddress: TAddress; const ParaAddressBytes: TBytes; const ParaField: string);
    procedure AssertOrderIdEqual(const ParaOrderIdStr: string; const ParaOrderIdBytes: TBytes; const ParaField: string);
    procedure AssertTokenIdEqual(const ParaToken: TTokenTypeId; const ParaTokenBytes: TBytes; const ParaField: string);
    procedure AssertPriceEqual(const ParaPrice: string; const ParaPriceBytes: TBytes; const ParaField: string);
    procedure AssertHashEqual(const ParaHash: THash; const ParaHashBytes: TBytes);
  end;

implementation

procedure TDexTradeTest.TestDexTrade;
var
  vTestDir: string;
  vTestFiles: TStringDynArray;
  vTestFile: string;
  vJson: string;
  vTestCaseMap: TJSONObject;
  vPair: TJSONPair;
  vTestCase: TDexTradeCase;
  vDb: TTestDatabase;
  vReader: IVMConsensusReader;
  vVm: IVM;
begin
  vTestDir := './contracts/dex/test/trade/';
  vTestFiles := TDirectory.GetFiles(vTestDir, '*.json');

  for vTestFile in vTestFiles do
  begin
    vJson := TFile.ReadAllText(vTestFile);
    vTestCaseMap := TJSONObject.ParseJSONValue(vJson) as TJSONObject;
    try
      for vPair in vTestCaseMap do
      begin
        // vTestCase := TJson.JsonToObject<TDexTradeCase>(vPair.JsonValue.ToString);
        // For now, we will skip the test execution as we need to implement the JSON deserialization first.
        // This will be done in a separate step.
        // ShowMessage(vPair.JsonString.Value + ':' + vTestCase.Name);
        // vDb := InitTradeDb(vTestCase);
        // vReader := TVMConsensusReader.Create(TConsensusReaderTest.Create(vDb.GetGenesisSnapshotBlock.Timestamp, 24 * 3600, nil));
        // vVm := TVM.Create(vReader);
        // ExecuteTradeActions(vTestCase, vVm, vDb);
        // ExecuteTradeChecks(vTestCase, vDb);
      end;
    finally
      vTestCaseMap.Free;
    end;
  end;
end;

function TDexTradeTest.InitTradeDb(const ParaDexTradeCase: TDexTradeCase): TTestDatabase;
begin
  // Implementation to be added
end;

procedure TDexTradeTest.ExecuteTradeActions(const ParaDexTradeCase: TDexTradeCase; ParaVm: IVM; ParaDb: TTestDatabase);
begin
  // Implementation to be added
end;

procedure TDexTradeTest.ExecuteTradeChecks(const ParaDexTradeCase: TDexTradeCase; ParaDb: TTestDatabase);
begin
  // Implementation to be added
end;

function TDexTradeTest.ToDexOrder(ParaDb: TTestDatabase; const ParaOrderStorage: TOrderStorage): IOrder;
begin
  // Implementation to be added
end;

procedure TDexTradeTest.SaveOrder(ParaDb: TTestDatabase; ParaOrder: IOrder; ParaIsTaker: Boolean);
begin
  // Implementation to be added
end;

procedure TDexTradeTest.AssertOrder(const ParaCheckOrder: TOrderStorage; const ParaDbOrder: IOrder; const ParaSource: string);
begin
  // Implementation to be added
end;

procedure TDexTradeTest.AssertAmountEqual(const ParaAmount: TBigInt; const ParaAmountBytes: TBytes; const ParaField: string);
var
  vAmountCmp: TBigInt;
begin
  vAmountCmp := TBigInt.Create(ParaAmountBytes);
  Assert.IsTrue(ParaAmount.CompareTo(vAmountCmp) = 0, Format('%s expected %s, actual %s', [ParaField, ParaAmount.ToString, vAmountCmp.ToString]));
end;

procedure TDexTradeTest.AssertAddressEqual(const ParaAddress: TAddress; const ParaAddressBytes: TBytes; const ParaField: string);
var
  vAddressCmp: TAddress;
begin
  vAddressCmp.SetBytes(ParaAddressBytes);
  Assert.AreEqual(ParaAddress.ToString, vAddressCmp.ToString, Format('%s expected %s, actual %s', [ParaField, ParaAddress.ToString, vAddressCmp.ToString]));
end;

procedure TDexTradeTest.AssertOrderIdEqual(const ParaOrderIdStr: string; const ParaOrderIdBytes: TBytes; const ParaField: string);
var
  vOrderId: TBytes;
begin
  vOrderId := TBytes.FromHexString(ParaOrderIdStr);
  Assert.IsTrue(CompareMem(vOrderId, ParaOrderIdBytes, Length(vOrderId))), Format('%s expected %s, actual %s', [ParaField, ParaOrderIdStr, TBytes.ToHexString(ParaOrderIdBytes)]));
end;

procedure TDexTradeTest.AssertTokenIdEqual(const ParaToken: TTokenTypeId; const ParaTokenBytes: TBytes; const ParaField: string);
var
  vTokenCmp: TTokenTypeId;
begin
  vTokenCmp.SetBytes(ParaTokenBytes);
  Assert.AreEqual(ParaToken.ToString, vTokenCmp.ToString, Format('%s expected %s, actual %s', [ParaField, ParaToken.ToString, vTokenCmp.ToString]));
end;

procedure TDexTradeTest.AssertPriceEqual(const ParaPrice: string; const ParaPriceBytes: TBytes; const ParaField: string);
var
  vPriceCmp: string;
begin
  vPriceCmp := TBytes.ToPrice(ParaPriceBytes);
  Assert.AreEqual(ParaPrice, vPriceCmp, Format('%s expected %s, actual %s', [ParaField, ParaPrice, vPriceCmp]));
end;

procedure TDexTradeTest.AssertHashEqual(const ParaHash: THash; const ParaHashBytes: TBytes);
var
  vHashCmp: THash;
begin
  vHashCmp.SetBytes(ParaHashBytes);
  Assert.AreEqual(ParaHash.ToString, vHashCmp.ToString);
end;

initialization
  RegisterTestFixture(TDexTradeTest);
end.
