unit Ledger.Onroad.Reader.Test;

interface

uses
  SysUtils, Classes,
  Ledger.Onroad.Reader, // The unit under test
  Ledger.Mock.Chain,    // For mock chain
  Common.Types,
  Interfaces.Core;

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
