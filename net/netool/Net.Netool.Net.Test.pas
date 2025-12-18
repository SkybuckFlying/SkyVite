unit Net.Netool.Net.Test;

interface

uses
  DUnitX.TestFramework,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  System.Net.IP,
  System.SysUtils;

type
  [TestFixture]
  TNetTest = class(TObject)
  public
    [Test]
    procedure TestIsLAN;
    [Test]
    procedure TestIsSpecialNetwork;
    [Test]
    procedure TestCheckRelayIP;
    [Test]
    procedure TestSameNet;
    [Test]
    procedure TestDistinctNetSet;
  end;

implementation

{ TNetTest }

procedure TNetTest.TestIsLAN;
begin
  Assert.IsTrue(IsLAN(TIPAddress.Create('127.0.0.1')));
  Assert.IsTrue(IsLAN(TIPAddress.Create('10.0.0.1')));
  Assert.IsTrue(IsLAN(TIPAddress.Create('172.16.0.1')));
  Assert.IsTrue(IsLAN(TIPAddress.Create('192.168.0.1')));
  Assert.IsFalse(IsLAN(TIPAddress.Create('8.8.8.8')));
  Assert.IsTrue(IsLAN(TIPAddress.Create('fe80::1')));
  Assert.IsTrue(IsLAN(TIPAddress.Create('fc00::1')));
end;

procedure TNetTest.TestIsSpecialNetwork;
begin
  Assert.IsTrue(IsSpecialNetwork(TIPAddress.Create('224.0.0.1')));
  Assert.IsTrue(IsSpecialNetwork(TIPAddress.Create('192.0.2.1')));
  Assert.IsFalse(IsSpecialNetwork(TIPAddress.Create('8.8.8.8')));
  Assert.IsTrue(IsSpecialNetwork(TIPAddress.Create('2001:db8::1')));
end;

procedure TNetTest.TestCheckRelayIP;
var
  vSender, vAddr: TIPAddress;
begin
  vSender := TIPAddress.Create('1.2.3.4');
  vAddr := TIPAddress.Create('5.6.7.8');
  Assert.IsNull(CheckRelayIP(vSender, vAddr));

  vAddr := TIPAddress.Create('127.0.0.1');
  Assert.IsNotNull(CheckRelayIP(vSender, vAddr));

  vSender := TIPAddress.Create('127.0.0.1');
  Assert.IsNull(CheckRelayIP(vSender, vAddr));

  vSender := TIPAddress.Create('1.2.3.4');
  vAddr := TIPAddress.Create('192.168.0.1');
  Assert.IsNotNull(CheckRelayIP(vSender, vAddr));

  vSender := TIPAddress.Create('192.168.0.2');
  Assert.IsNull(CheckRelayIP(vSender, vAddr));

  vSender := TIPAddress.Create('192.168.0.0');
  vAddr := TIPAddress.Create('0.0.0.0');
  Assert.IsNotNull(CheckRelayIP(vSender, vAddr));
end;

procedure TNetTest.TestSameNet;
var
  vIP1, vIP2: TIPAddress;
begin
  vIP1 := TIPAddress.Create('192.168.0.1');
  vIP2 := TIPAddress.Create('192.168.0.2');
  Assert.IsTrue(SameNet(24, vIP1, vIP2));
  Assert.IsFalse(SameNet(25, vIP1, vIP2));

  vIP1 := TIPAddress.Create('2001:db8::1');
  vIP2 := TIPAddress.Create('2001:db8::2');
  Assert.IsTrue(SameNet(64, vIP1, vIP2));
  Assert.IsFalse(SameNet(65, vIP1, vIP2));
end;

procedure TNetTest.TestDistinctNetSet;
var
  vSet: TDistinctNetSet;
  vIP1, vIP2, vIP3: TIPAddress;
begin
  vSet := TDistinctNetSet.Create(24, 2);
  try
    vIP1 := TIPAddress.Create('192.168.0.1');
    vIP2 := TIPAddress.Create('192.168.0.2');
    vIP3 := TIPAddress.Create('192.168.0.3');

    Assert.IsTrue(vSet.Add(vIP1));
    Assert.IsTrue(vSet.Add(vIP2));
    Assert.IsFalse(vSet.Add(vIP3));

    Assert.AreEqual(2, vSet.Len);
    Assert.IsTrue(vSet.Contains(vIP1));

    vSet.Remove(vIP1);
    Assert.AreEqual(1, vSet.Len);
    Assert.IsFalse(vSet.Contains(vIP1));
    Assert.IsTrue(vSet.Add(vIP3));
  finally
    vSet.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TNetTest);
end.
