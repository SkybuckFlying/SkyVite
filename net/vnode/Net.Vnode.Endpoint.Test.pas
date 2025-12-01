unit Net.VNode.EndPoint.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Net.IP,
  Net.VNode.EndPoint;

type
  [TestFixture]
  TEndPointTest = class(TObject)
  public
    [Test]
    procedure TestParseEndPoint;
    [Test]
    procedure TestEndPoint_Serialize;
    [Test]
    procedure TestEndPoint_Deserialize;
    [Test]
    procedure TestEndPoint_JSON;
  end;

implementation

uses
  System.Math;

{ TEndPointTest }

procedure TEndPointTest.TestParseEndPoint;
type
  THandleFunc = reference to function(const E: TEndPoint): string;
  TTestCase = record
    URL: string;
    Handle: THandleFunc;
  end;
var
  vTestCases: TArray<TTestCase>;
  vTestCase: TTestCase;
  vEndPoint: TEndPoint;
  vErr: string;
begin
  vTestCases := [
    (URL: 'vite.org'; Handle: function(const E: TEndPoint): string
      begin
        if TEncoding.UTF8.GetString(E.Host) <> 'vite.org' then Result := 'different host';
        if E.Port <> DefaultPort then Result := 'different port';
        if E.Typ <> THostType.HostDomain then Result := 'different type';
        if E.ToString <> 'vite.org:' + IntToStr(DefaultPort) then Result := 'wrong string format';
      end),
    (URL: 'vite.org:8888'; Handle: function(const E: TEndPoint): string
      begin
        if TEncoding.UTF8.GetString(E.Host) <> 'vite.org' then Result := 'different host';
        if E.Port <> 8888 then Result := 'different port';
        if E.Typ <> THostType.HostDomain then Result := 'different type';
        if E.ToString <> 'vite.org:8888' then Result := 'wrong string format';
      end),
    (URL: '127.0.0.1'; Handle: function(const E: TEndPoint): string
      begin
        if not CompareMem(E.Host, TBytes.Create(127, 0, 0, 1), 4) then Result := 'different host';
        if E.Port <> DefaultPort then Result := 'different port';
        if E.Typ <> THostType.HostIPv4 then Result := 'different type';
        if E.ToString <> '127.0.0.1:' + IntToStr(DefaultPort) then Result := 'wrong string format';
      end),
    (URL: '[::1]:8080'; Handle: function(const E: TEndPoint): string
      var
        vIP: TIPAddress;
      begin
        vIP := TIPAddress.Create('::1');
        if not CompareMem(E.Host, vIP.GetAddressBytes, 16) then Result := 'different host';
        if E.Port <> 8080 then Result := 'different port';
        if E.Typ <> THostType.HostIPv6 then Result := 'different type';
        if E.ToString <> '[::1]:8080' then Result := 'wrong string format';
      end)
  ];

  for vTestCase in vTestCases do
  begin
    try
      vEndPoint := TEndPoint.Parse(vTestCase.URL);
      vErr := vTestCase.Handle(vEndPoint);
      Assert.IsTrue(vErr = '', vTestCase.URL + ': ' + vErr);
    except
      on E: Exception do
        Assert.Fail(vTestCase.URL + ': ' + E.Message);
    end;
  end;
end;

procedure TEndPointTest.TestEndPoint_Serialize;
var
  vEndPoint, vEndPoint2: TEndPoint;
  vBytes: TBytes;
  vHLen, vMeta: Integer;
begin
  vEndPoint := Default(TEndPoint);
  Assert.WillRaise(procedure
    begin
      vBytes := vEndPoint.Serialize;
    end, EInvalidOp);

  for vHLen := 1 to MaxHostLength do
  begin
    SetLength(vEndPoint.Host, vHLen);
    Randomize;
    for var i := 0 to vHLen - 1 do
      vEndPoint.Host[i] := Byte(Random(256));
    vEndPoint.Port := 8080;
    vEndPoint.Typ := THostType.HostIPv4;

    vBytes := vEndPoint.Serialize;
    Assert.AreEqual(vHLen + 3, Length(vBytes));

    vMeta := (vHLen shl 2) or 1;
    if (vHLen > 16) or (vEndPoint.Typ = THostType.HostDomain) then
      vMeta := vMeta or 2;
    Assert.AreEqual(vMeta, vBytes[0]);
  end;

  vEndPoint.Port := DefaultPort;
  vBytes := vEndPoint.Serialize;
  Assert.AreEqual(vHLen + 1, Length(vBytes));

  vMeta := vHLen shl 2;
  if (vHLen > 16) or (vEndPoint.Typ = THostType.HostDomain) then
    vMeta := vMeta or 2;
  Assert.AreEqual(vMeta, vBytes[0]);

  SetLength(vEndPoint.Host, MaxHostLength + 1);
  Assert.WillRaise(procedure
    begin
      vBytes := vEndPoint.Serialize;
    end, EInvalidOp);
end;

procedure TEndPointTest.TestEndPoint_Deserialize;
var
  vEndPoints: TArray<TEndPoint>;
  vEndPoint, vEndPoint2: TEndPoint;
  vData: TArray<TBytes>;
  vBytes: TBytes;
  vI: Integer;
begin
  vEndPoints := [
    TEndPoint.Create(TBytes.Create(0, 0, 0, 0), 8888, THostType.HostIPv4),
    TEndPoint.Create(TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), 8889, THostType.HostIPv6),
    TEndPoint.Create(TEncoding.UTF8.GetBytes('vite.org'), 9000, THostType.HostDomain),
    TEndPoint.Create(TEncoding.UTF8.GetBytes('vite.org'), 8483, THostType.HostDomain)
  ];

  SetLength(vData, Length(vEndPoints));
  for vI := 0 to High(vEndPoints) do
    vData[vI] := vEndPoints[vI].Serialize;

  for vI := 0 to High(vData) do
  begin
    vBytes := vData[vI];
    Assert.IsTrue(vEndPoint2.Deserialize(vBytes));
    Assert.IsTrue(vEndPoints[vI].Equal(vEndPoint2));
  end;
end;

procedure TEndPointTest.TestEndPoint_JSON;
var
  vEndPoint, vEndPoint2: TEndPoint;
  vJSON: TBytes;
begin
  vEndPoint := TEndPoint.Parse('127.0.0.1:8080');
  vJSON := vEndPoint.MarshalJSON;
  Assert.IsTrue(vEndPoint2.UnmarshalJSON(vJSON));
  Assert.IsTrue(vEndPoint.Equal(vEndPoint2));
end;

initialization
  TDUnitX.RegisterTestFixture(TEndPointTest);
end.