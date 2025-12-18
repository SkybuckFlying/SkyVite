unit utils_test;

interface

uses
  Ledger.Generator.Generator,
  Ledger.Generator.Incoming.Message,
  Ledger.Generator.Utils,
  System.SysUtils System.Classes DUnitX.TestFramework,
  Vite.Common Vite.Ledger Vite.Interfaces generator.utils;

type
  [TestFixture]
  TUtilsTest = class
  private
    FChain: TMockChain;
  public
    [Test]
    procedure TestSeed;
  end;

  TMockChain = class(TInterfacedObject, IChain)
  private
    FSeed: UInt64;
  public
    constructor Create(seed: UInt64);
    function GetAccountBlockByHash(blockHash: THash): TAccountBlock;
    function GetSnapshotBlockByContractMeta(addr: TAddress; fromHash: THash): TSnapshotBlock;
    function GetSeed(limitSb: TSnapshotBlock; fromHash: THash): UInt64;
    function GetSeedConfirmedSnapshotBlock(addr: TAddress; fromHash: THash): TSnapshotBlock;
  end;

implementation

{ TMockChain }

constructor TMockChain.Create(seed: UInt64);
begin
  FSeed := seed;
end;

function TMockChain.GetAccountBlockByHash(blockHash: THash): TAccountBlock;
begin
  Result := nil;
end;

function TMockChain.GetSnapshotBlockByContractMeta(addr: TAddress; fromHash: THash): TSnapshotBlock;
begin
  Result := nil;
end;

function TMockChain.GetSeed(limitSb: TSnapshotBlock; fromHash: THash): UInt64;
begin
  Result := FSeed;
end;

function TMockChain.GetSeedConfirmedSnapshotBlock(addr: TAddress; fromHash: THash): TSnapshotBlock;
begin
  Result := nil;
end;

{ TUtilsTest }

procedure TUtilsTest.TestSeed;
var
  seed: UInt64;
  vmGlobalStatus: TVMGlobalStatus;
  i: Integer;
  rand: UInt64;
  randList: TArray<UInt64>;
  expected: UInt64;
begin
  seed := 15637427697709333733;
  FChain := TMockChain.Create(seed);
  vmGlobalStatus := TVMGlobalStatus.Create(FChain, nil, THash.Create);
  for i := 0 to 99 do
  begin
    rand := vmGlobalStatus.Seed;
    Assert.AreEqual(seed, rand, 'before hard fork');
  end;

  seed := 15637427697709333733;
  FChain := TMockChain.Create(seed);
  vmGlobalStatus := TVMGlobalStatus.Create(FChain, nil, THash.Create);
  randList := [3859229079807094838, 12152911693104629581, 9644037654042465595, 9243194358276174014, 11414992830392538450, 3925454220078744999, 16503802664012760397, 7980644548622968793, 13268626495317126268, 12067214392073868583];
  for i := 0 to High(randList) do
  begin
    expected := randList[i];
    rand := vmGlobalStatus.Random;
    Assert.AreEqual(expected, rand, 'after hard fork, index ' + i.ToString);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TUtilsTest);
end.
