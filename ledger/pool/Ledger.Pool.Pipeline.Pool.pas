unit Ledger.Pool.Pipeline.Pool;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool // For TPool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  SysUtils Classes,
  unit_GoLang_Compatibility_version_006;

type
  // Define a delegate for a pipeline stage
  TPipelineStage = reference to procedure(Tx: ITransaction);

  TPipelinePool = class
  private
    FInput: TGoChannel<ITransaction>;
    FStages: TArray<TPipelineStage>;
    FQuitChan: TGoChannel<Boolean>;
    FPool: TPool;
    
    procedure Loop;
    
  public
    constructor Create(Pool: TPool; Stages: TArray<TPipelineStage>);
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    procedure Add(Tx: ITransaction);
  end;

implementation

uses System.Threading;

{ TPipelinePool }

constructor TPipelinePool.Create(Pool: TPool; Stages: TArray<TPipelineStage>);
begin
  inherited Create;
  FPool := Pool;
  FStages := Stages;
  FInput := TGoChannel<ITransaction>.Create(100);
  FQuitChan := TGoChannel<Boolean>.Create(1);
end;

destructor TPipelinePool.Destroy;
begin
  FInput.Free;
  FQuitChan.Free;
  inherited;
end;

procedure TPipelinePool.Start;
begin
  TTask.Run(procedure begin Loop; end);
end;

procedure TPipelinePool.Stop;
begin
  FQuitChan.Send(True);
end;

procedure TPipelinePool.Add(Tx: ITransaction);
begin
  FInput.Send(Tx);
end;

procedure TPipelinePool.Loop;
var
  tx: ITransaction;
  quit: Boolean;
  stage: TPipelineStage;
begin
  quit := False;
  while not quit do
  begin
    // Simplified select
    if FInput.Receive(tx) then
    begin
      // Process transaction through all stages
      for stage in FStages do
      begin
        stage(tx);
      end;
      // Finally, add to the main pool
      FPool.Add(tx);
    end;
    
    if FQuitChan.Receive(quit) then
    begin
      // Exit loop
    end;
  end;
end;

end.
