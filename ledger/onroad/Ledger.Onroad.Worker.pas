unit worker;

interface

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
