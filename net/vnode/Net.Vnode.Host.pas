unit Net.VNode.Host;

interface
uses
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test;

type
  THostType = (htIPv4, htIPv6, htIP, htDomain);

function IsHostType(const A, B: THostType): Boolean;

implementation

function IsHostType(const A, B: THostType): Boolean;
begin
  Result := (Ord(A) and Ord(B)) > 0;
end;

end.
