unit Net.Discovery.Node.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Net.Sockets,
  Net.VNode,
  Net.Discovery.Node;

type
  [TestFixture]
  TNodeTest = class(TObject)
  public
    [Test]
    procedure TestExtractEndPoint;
  end;

implementation

uses
  System.Net.IP,
  System.Types;

{ TNodeTest }

procedure TNodeTest.TestExtractEndPoint;
type
  TSampleHandle = reference to function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception;

  TSample = record
    Sender: TSocketAddress;
    FromStr: string;
    Handle: TSampleHandle;
  end;
var
  vSamples: TArray<TSample>;
  vSamp: TSample;
  vFromEP: TVNodeEndPoint;
  vPair: TPair<TVNodeEndPoint, TSocketAddress>;
  vErr: Exception;
begin
  vSamples := [
    (Sender: TSocketAddress.Create('127.0.0.1', 8483); FromStr: 'vite.org';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if ParaE.Typ.IsA(THostIP) then
         Result := Exception.Create('should be domain');
       if ParaE.ToString <> 'vite.org:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('193.110.91.250', 8483); FromStr: '0.0.0.0:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '193.110.91.250:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('193.110.91.250', 8483); FromStr: '127.0.0.1:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '193.110.91.250:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('192.168.1.36', 8483); FromStr: '127.0.0.1:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '192.168.1.36:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('192.168.1.36', 8483); FromStr: '0.0.0.0:8888';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '192.168.1.36:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;)
  ];

  for vSamp in vSamples do
  begin
    vFromEP := TVNodeEndPoint.ParseEndPoint(vSamp.FromStr);
    Assert.IsNotNull(vFromEP, Format('Failed to parse endpoint: %s', [vSamp.FromStr]));
    try
      vPair := extractEndPoint(vSamp.Sender, vFromEP);
      vErr := vSamp.Handle(vPair.Key, vPair.Value);
      Assert.IsNull(vErr, vErr.Message);
    finally
      vFromEP.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TNodeTest);
end.
