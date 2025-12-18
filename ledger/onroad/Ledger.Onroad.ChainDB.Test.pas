unit Ledger.Onroad.ChainDB.Test;

interface

uses
  SysUtils, Classes,
  Ledger.Onroad.ChainDB, // The unit under test
  Common.DB,             // For mock database
  Common.Types,
  Interfaces.Core;

type
  TChainDBTest = class
  private
    procedure TestGetPut;
  public
    procedure RunAllTests;
  end;

implementation

{ TChainDBTest }

procedure TChainDBTest.TestGetPut;
var
  db: IDB;
  chainDB: TChainDB;
  onroadBlock: IOnroadBlock;
  retrievedBlock: IOnroadBlock;
begin
  // 1. Setup
  db := TMemDB.Create; // Use an in-memory database for testing
  chainDB := TChainDB.Create(db);
  
  // Create a mock onroad block
  onroadBlock := TOnroadBlock.Create;
  onroadBlock.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('test_hash'));
  // ... set other properties
  
  try
    // 2. Test Put
    chainDB.Put(onroadBlock);
    
    // 3. Test Get
    retrievedBlock := chainDB.Get(onroadBlock.Hash);
    
    // 4. Verify
    if retrievedBlock = nil then
      raise Exception.Create('Failed to retrieve onroad block');
      
    if retrievedBlock.Hash <> onroadBlock.Hash then
      raise Exception.Create('Retrieved block hash does not match');
      
  finally
    chainDB.Free;
    db.Free;
    onroadBlock.Free;
    if retrievedBlock <> nil then
      retrievedBlock.Free;
  end;
end;

procedure TChainDBTest.RunAllTests;
begin
  TestGetPut;
end;

end.
