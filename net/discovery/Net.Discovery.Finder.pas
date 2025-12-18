unit net.discovery.finder;

interface

uses
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  net.vnode,
  System.SysUtils System.Classes System.Generics.Collections;

type
  ISubscriber = interface
    ['{YOUR_GUID_HERE}']
    procedure OnNodesFound(Nodes: TArray<TVNode>);
  end;

  IObserver = interface
    ['{YOUR_GUID_HERE}']
    procedure Sub(Sub: ISubscriber);
    procedure UnSub(Sub: ISubscriber);
  end;

  IDiscoveryResolver = interface
    ['{YOUR_GUID_HERE}']
    function GetNodes(Count: Integer): TArray<TVNode>;
  end;

  IFinder = interface(IObserver)
    ['{YOUR_GUID_HERE}']
    procedure SetResolver(Discv: IDiscoveryResolver);
    function FindNeighbors(FromId, Target: TVNodeID; Count: Integer): TArray<TVNodeEndPoint>;
  end;

implementation

end.
