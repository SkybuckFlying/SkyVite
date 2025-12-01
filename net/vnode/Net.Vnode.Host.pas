unit Net.VNode.Host;

interface

type
  THostType = (htIPv4, htIPv6, htIP, htDomain);

function IsHostType(const A, B: THostType): Boolean;

implementation

function IsHostType(const A, B: THostType): Boolean;
begin
  Result := (Ord(A) and Ord(B)) > 0;
end;

end.
