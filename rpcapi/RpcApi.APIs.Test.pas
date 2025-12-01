unit RpcApi.Apis.Test;

interface

uses
  DUnitX.TestFramework,
  RpcApi.Apis,
  Rpc,
  RpcApi.Api.Filters,
  Vite;

type
  [TestFixture]
  TApisTest = class(TObject)
  public
    [Test]
    procedure TestApiTypeValues;
    [Test]
    procedure TestApiTypeName;
    [Test]
    procedure TestPrintAllApiTypes;
    [Test]
    procedure TestPrintAllExposedApiMethods;
    [Test]
    procedure TestPrintAllExposedApiSubscriptions;
  private
    function CreateServer: TRpcServer;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

{ TApisTest }

function TApisTest.CreateServer: TRpcServer;
var
  vViteServer: TVite;
  vServer: TRpcServer;
  vApiType: TApiType;
  vApi: TRpcAPI;
begin
  vViteServer := TVite.NewMock(nil, nil);
  TFilters.Es := TEventSystem.Create(vViteServer);

  vServer := TRpcServer.Create;

  for vApiType := Low(TApiType) to High(TApiType) do
  begin
    if vApiType = apiTypeLimit then
    begin
      break;
    end;
    vApi := GetApi(vViteServer, vApiType.Name);
    vServer.RegisterName(vApi.Namespace, vApi.Service);
  end;

  Result := vServer;
end;

procedure TApisTest.TestApiTypeName;
var
  vExpected1: string;
  vActual1: string;
  vExpected2: string;
  vActual2: string;
begin
  vExpected1 := 'health';
  vActual1 := TApiType.HEALTH.Name;
  Assert.AreEqual(vExpected1, vActual1, 'expected ApiType name: ' + vExpected1 + ' / actual: ' + vActual1);

  vExpected2 := 'virtual';
  vActual2 := TApiType.VIRTUAL.Name;
  Assert.AreEqual(vExpected2, vActual2, 'expected ApiType name: ' + vExpected2 + ' / actual: ' + vActual2);
end;

procedure TApisTest.TestApiTypeValues;
var
  vExpected: Integer;
  vActual: Integer;
begin
  vExpected := Ord(apiTypeLimit);
  vActual := Length(TApiType.Values);
  Assert.AreEqual(vExpected, vActual, 'length of apiTypeStrings ' + vActual.ToString + ' does not match with apiTypeLimit ' + vExpected.ToString);
end;

procedure TApisTest.TestPrintAllApiTypes;
var
  vApiType: TApiType;
begin
  for vApiType := Low(TApiType) to High(TApiType) do
  begin
    if vApiType = apiTypeLimit then
    begin
      break;
    end;
    WriteLn(vApiType.Name);
  end;
end;

procedure TApisTest.TestPrintAllExposedApiMethods;
var
  vServer: TRpcServer;
  vSvcName: string;
  vMethods: TDictionary<string, string>;
  vMethodName: string;
begin
  vServer := CreateServer;
  try
    for vSvcName in vServer.Methods.Keys do
    begin
      vMethods := vServer.Methods[vSvcName];
      for vMethodName in vMethods.Keys do
      begin
        WriteLn(vSvcName + '_' + vMethods[vMethodName]);
      end;
    end;
  finally
    vServer.Free;
  end;
end;

procedure TApisTest.TestPrintAllExposedApiSubscriptions;
var
  vServer: TRpcServer;
  vSvcName: string;
  vSubs: TDictionary<string, string>;
  vSubName: string;
begin
  vServer := CreateServer;
  try
    for vSvcName in vServer.Subscriptions.Keys do
    begin
      vSubs := vServer.Subscriptions[vSvcName];
      for vSubName in vSubs.Keys do
      begin
        WriteLn(vSvcName + '_' + vSubs[vSubName]);
      end;
    end;
  finally
    vServer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TApisTest);
end.
