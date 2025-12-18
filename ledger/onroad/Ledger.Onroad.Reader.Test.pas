unit Ledger.Onroad.Reader.Test;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Mock.Chain    // For mock chain,
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
  Ledger.Onroad.Reader // The unit under test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  SysUtils Classes;

type
  TReaderTest = class
  private
    procedure TestGetOnroadData;
  public
    procedure RunAllTests;
  end;

implementation

{ TReaderTest }

procedure TReaderTest.TestGetOnroadData;
var
  chain: TMockChain;
  reader: TReader;
  onroadBlock: IOnroadBlock;
  retrievedData: TBytes;
begin
  // 1. Setup
  chain := TMockChain.Create;
  
  // Create a mock onroad block and add it to the chain
  onroadBlock := TOnroadBlock.Create;
  onroadBlock.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('test_onroad'));
  onroadBlock.Data := TEncoding.UTF8.GetBytes('some on-road data');
  chain.AddOnroadBlock(onroadBlock); // Assuming mock chain has this method
  
  reader := TReader.Create(chain);
  
  try
    // 2. Test getting the data
    retrievedData := reader.GetData(onroadBlock.Hash);
    
    // 3. Verify
    if TEncoding.UTF8.GetString(retrievedData) <> 'some on-road data' then
      raise Exception.Create('Retrieved on-road data does not match');

  finally
    reader.Free;
    chain.Free;
    onroadBlock.Free;
  end;
end;

procedure TReaderTest.RunAllTests;
begin
  TestGetOnroadData;
end;

end.
