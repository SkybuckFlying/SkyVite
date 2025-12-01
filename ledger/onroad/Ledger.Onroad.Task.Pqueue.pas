unit task_pqueue;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
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
