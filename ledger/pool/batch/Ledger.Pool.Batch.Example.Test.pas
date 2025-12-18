unit Ledger.Pool.Batch.Example.Test;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Mock.Chain,
  Ledger.Pool.Batch.Batch,
  Ledger.Pool.Batch.Batch.Executor.Impl,
  Ledger.Pool.Batch.Batch.Impl,
  Ledger.Pool.Batch.Batch.Test,
  Ledger.Pool.Batch.Bucket,
  Ledger.Pool.Batch.Level,
  Ledger.Pool.Batch.Level.Account,
  Ledger.Pool.Batch.Level.Snapshot,
  Ledger.Pool.Batch.Mock.Chain,
  Ledger.Pool.Batch.Mock.Item,
  SysUtils Classes;

type
  TBatchExample = class
  public
    // This procedure demonstrates the basic usage of the TBatchImpl class.
    procedure ShowBatchUsage;
  end;

implementation

{ TBatchExample }

procedure TBatchExample.ShowBatchUsage;
var
  chain: TMockChain;
  batch: TBatchImpl;
  tx1, tx2: ITransaction;
begin
  // 1. Setup a mock chain that the batch will be applied to.
  chain := TMockChain.Create;
  
  // 2. Create a new batch instance, linked to the chain.
  batch := TBatchImpl.Create(chain);
  
  try
    Writeln('Creating and adding transactions to the batch...');
    
    // 3. Create some mock transactions.
    tx1 := TTransaction.Create;
    tx1.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('tx1'));
    // ... set other tx1 properties
    
    tx2 := TTransaction.Create;
    tx2.Hash := THash.FromBytes(TEncoding.UTF8.GetBytes('tx2'));
    // ... set other tx2 properties
    
    // 4. Add the transactions to the batch.
    batch.Add(tx1);
    batch.Add(tx2);
    
    Writeln(Format('%d transactions added to the batch.', [batch.GetTransactions.Length]));
    
    // 5. Process the batch. This would typically involve validation
    // and updating an in-memory state tree.
    Writeln('Processing the batch...');
    batch.Process;
    
    // 6. Commit the batch to the chain. This applies the state changes.
    Writeln('Committing the batch...');
    batch.Commit;
    
    // 7. Verify the results (optional, for demonstration).
    // In a real application, you would check the chain state.
    // if chain.HasTransaction(tx1.Hash) and chain.HasTransaction(tx2.Hash) then
    //   Writeln('Successfully committed batch to the chain.')
    // else
    //   Writeln('Error: Batch was not committed correctly.');

  finally
    batch.Free;
    chain.Free;
    tx1.Free;
    tx2.Free;
  end;
end;

end.
