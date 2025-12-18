unit task_pqueue;

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
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite.Common;

type
  TContractTask = class
  public
    Addr: TAddress;
    Index: Integer;
    Quota: UInt64;
  end;

  TContractTaskPQueue = class(TPriorityQueue<TContractTask>)
  public
    procedure Push(x: TContractTask);
    function Pop: TContractTask;
    procedure Swap(i, j: Integer);
  end;

implementation

{ TContractTaskPQueue }

procedure TContractTaskPQueue.Push(x: TContractTask);
begin
  x.Index := Count;
  Enqueue(x);
end;

function TContractTaskPQueue.Pop: TContractTask;
begin
  Result := Dequeue;
  Result.Index := -1; // for safety
end;

procedure TContractTaskPQueue.Swap(i, j: Integer);
var
  temp: TContractTask;
begin
  temp := Items[i];
  Items[i] := Items[j];
  Items[j] := temp;
  Items[i].Index := i;
  Items[j].Index := j;
end;

end.
