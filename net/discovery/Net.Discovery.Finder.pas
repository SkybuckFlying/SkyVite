unit net.discovery.finder;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  net.vnode;

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
