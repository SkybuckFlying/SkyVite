unit worker;

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
  Ledger.Onroad.Utils.Test;

const
  csCreate = 0;
  csStart = 1;
  csStop = 2;

type
  IWorker = interface
    ['{A7B6C5A0-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function Status: Integer;
    procedure Start;
    procedure Stop;
    function Close: Boolean;
  end;

const
  POMAXPROCS = 2;
  ContractTaskProcessorSize = POMAXPROCS;

type
  TInferiorState = (isRetry, isOut);

implementation

end.
