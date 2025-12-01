unit Ledger.Pool.Pool.Batch;

interface

uses
  Ledger.Pool.Pool,
  Ledger.Pool.Batch;

type
  TPoolBatchHelper = class helper for TPool
  public
    procedure Insert;
    function MakeQueue: IBatch;
  end;

implementation

{ TPoolBatchHelper }

procedure TPoolBatchHelper.Insert;
begin
  // Implementation to be added
end;

function TPoolBatchHelper.MakeQueue: IBatch;
begin
  // Implementation to be added
  Result := nil;
end;

end.
