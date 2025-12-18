unit reader;

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
  Ledger.Onroad.Reader.Test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.SysUtils System.Classes,
  Vite.Common Vite.Interfaces Vite.Net Vite.Producer;

type
  IPool = interface
    ['{C3C9B5A1-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function AddDirectAccountBlock(address: TAddress; vmAccountBlock: IVmAccountBlock): Boolean;
  end;

  IProducer = interface
    ['{D4D8C4A2-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    procedure SetAccountEventFunc(f: TAccountEventFunc);
  end;

  INetReader = interface
    ['{E5E7D3B3-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function SubscribeSyncStatus(fn: TSyncStateFunc): Integer;
    procedure UnsubscribeSyncStatus(subId: Integer);
    function SyncState: TSyncState;
  end;

implementation

end.
