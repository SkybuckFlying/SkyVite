unit Ledger.Pool.Batch.Mock.Chain;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Batch.Batch,
  Ledger.Pool.Batch.Batch.Executor.Impl,
  Ledger.Pool.Batch.Batch.Impl,
  Ledger.Pool.Batch.Batch.Test,
  Ledger.Pool.Batch.Bucket,
  Ledger.Pool.Batch.Example.Test,
  Ledger.Pool.Batch.Level,
  Ledger.Pool.Batch.Level.Account,
  Ledger.Pool.Batch.Level.Snapshot,
  Ledger.Pool.Batch.Mock.Item,
  System.Generics.Collections,
  SysUtils Classes;

type
  // This is a mock implementation of IChain for testing the batch package
  TMockChain = class(TInterfacedObject, IChainReadWriter)
  private
    FBlocks: TDictionary<THash, IAccountBlock>;
    // ... other mock state, e.g., for account states
  public
    constructor Create;
    destructor Destroy; override;
    
    // Implement IChainReader methods
    function GetAccountState(Addr: TAddress): IAccountState;
    function GetBlockByHash(Hash: THash): IAccountBlock;
    // ... other reader methods
    
    // Implement IChainWriter methods
    procedure AddBlock(Block: IAccountBlock);
    procedure ApplyChanges(Changes: TStateChanges); // Simplified
    // ... other writer methods
    
    // Mock-specific methods
    function HasBlock(Hash: THash): Boolean;
  end;

implementation

{ TMockChain }

constructor TMockChain.Create;
begin
  inherited Create;
  FBlocks := TDictionary<THash, IAccountBlock>.Create;
end;

destructor TMockChain.Destroy;
begin
  FBlocks.Free;
  inherited;
end;

function TMockChain.GetAccountState(Addr: TAddress): IAccountState;
begin
  // Return a mock account state for testing
  Result := TAccountState.Create;
  // Result.Balance := ...
end;

function TMockChain.GetBlockByHash(Hash: THash): IAccountBlock;
begin
  FBlocks.TryGetValue(Hash, Result);
end;

procedure TMockChain.AddBlock(Block: IAccountBlock);
begin
  FBlocks.AddOrSetValue(Block.Hash, Block);
end;

procedure TMockChain.ApplyChanges(Changes: TStateChanges);
begin
  // In a real mock, you might inspect the changes
  // to verify they are correct.
end;

function TMockChain.HasBlock(Hash: THash): Boolean;
begin
  Result := FBlocks.ContainsKey(Hash);
end;

// ... implementation of other IChain methods

end.
