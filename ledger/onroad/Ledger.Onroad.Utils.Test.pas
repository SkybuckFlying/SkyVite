unit V2.Ledger.OnRoad.Utils.Test;

interface

uses
  Ledger.Onroad.Access,
  Ledger.Onroad.Access.Test,
  Ledger.Onroad.Chain.Events,
  Ledger.Onroad.ChainDB.Test,
  Ledger.Onroad.Contract,
  Ledger.Onroad.Contract.Test,
  Ledger.Onroad.Manager,
  Ledger.Onroad.Manager.Test,
  Ledger.Onroad.Pending.Cache,
  Ledger.Onroad.Pending.Cache.Test,
  Ledger.Onroad.Reader,
  Ledger.Onroad.Reader.Test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Worker,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  TestFramework,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.OnRoad.Utils;

type
  // Mock chain to satisfy the IJudgeGenesis interface
  TMockChain = class(TInterfacedObject, IJudgeGenesis)
    function IsGenesisAccountBlock(ABlock: THash): Boolean;
  end;

  [TestFixture]
  TOnRoadUtilsTest = class(TObject)
  public
    [Test]
    procedure Test_ExcludePairTrades;
  end;

implementation

{ TMockChain }

function TMockChain.IsGenesisAccountBlock(ABlock: THash): Boolean;
begin
  Result := False;
end;

{ TOnRoadUtilsTest }

procedure TOnRoadUtilsTest.Test_ExcludePairTrades;
var
  Blocks: TArray<IAccountBlock>;
  Block, Send1, Send2: IAccountBlock;
  MockChain: IJudgeGenesis;
  ResultMap: TDictionary<TAddress, TArray<IAccountBlock>>;
begin
  // 1. Setup the input data
  SetLength(Blocks, 0);

  Send1 := TAccountBlock.Create;
  Send1.BlockType := Send;
  Send1.Height := 0;
  Send1.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('3'));
  Send1.ToAddress := AddressQuota;

  Send2 := TAccountBlock.Create;
  Send2.BlockType := Send;
  Send2.Height := 0;
  Send2.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('4'));
  Send2.ToAddress := AddressAsset;

  Block := TAccountBlock.Create;
  Block.BlockType := Receive;
  Block.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes('1'));
  Block.Height := 5;
  Block.AccountAddress := AddressAsset;
  Block.ToAddress := AddressQuota;
  Block.FromBlockHash := TDataHash.Create(TEncoding.UTF8.GetBytes('2'));
  Block.SendBlockList := [Send1, Send2];

  Blocks := [Block];

  // 2. Execute the function
  MockChain := TMockChain.Create;
  ResultMap := ExcludePairTrades(MockChain, Blocks);

  // 3. Assert the results
  Assert.AreEqual(2, ResultMap.Count, 'Should be two addresses in the result map');

  Assert.IsTrue(ResultMap.ContainsKey(AddressAsset));
  Assert.AreEqual(2, Length(ResultMap[AddressAsset]), 'AddressAsset should have 2 pending blocks');
  Assert.AreEqual(Block.Hash, ResultMap[AddressAsset][0].Hash, 'First block for AddressAsset should be the receive block');
  Assert.AreEqual(Send2.Hash, ResultMap[AddressAsset][1].Hash, 'Second block for AddressAsset should be the unmatched send');

  Assert.IsTrue(ResultMap.ContainsKey(AddressQuota));
  Assert.AreEqual(1, Length(ResultMap[AddressQuota]), 'AddressQuota should have 1 pending block');
  Assert.AreEqual(Send1.Hash, ResultMap[AddressQuota][0].Hash, 'The block for AddressQuota should be the other unmatched send');

  // Log for verification
  for var Addr in ResultMap.Keys do
    for var B in ResultMap[Addr] do
      WriteLn(Format('%s: %s -> %s, Hash: %s, Height: %d', [Addr.ToString, B.AccountAddress.ToString, B.ToAddress.ToString, B.Hash.ToString, B.Height]));
end;

initialization
  RegisterTest(TOnRoadUtilsTest.Suite);
end.
