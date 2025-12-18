unit Net.VNode.Host.Test;

interface

uses
  DUnitX.TestFramework,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.VNode.Host,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.SysUtils;

type
  [TestFixture]
  THostTest = class(TObject)
  public
    [Test]
    procedure TestIsHostType;
  end;

implementation

{ THostTest }

procedure THostTest.TestIsHostType;
begin
  Assert.IsTrue(IsHostType(htIPv4, htIPv4));
  Assert.IsTrue(IsHostType(htIPv6, htIPv6));
  Assert.IsTrue(IsHostType(htIP, htIP));
  Assert.IsTrue(IsHostType(htDomain, htDomain));
  Assert.IsTrue(IsHostType(htIPv4, htIP));
  Assert.IsTrue(IsHostType(htIPv6, htIP));
  Assert.IsFalse(IsHostType(htIPv4, htIPv6));
  Assert.IsFalse(IsHostType(htIPv6, htIPv4));
  Assert.IsFalse(IsHostType(htIPv4, htDomain));
  Assert.IsFalse(IsHostType(htIPv6, htDomain));
  Assert.IsFalse(IsHostType(htDomain, htIP));
  Assert.IsFalse(IsHostType(htIP, htDomain));
end;

initialization
  TDUnitX.RegisterTestFixture(THostTest);
end.
