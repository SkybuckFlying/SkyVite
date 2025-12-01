unit reader;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common, Vite.Interfaces, Vite.Net, Vite.Producer;

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
