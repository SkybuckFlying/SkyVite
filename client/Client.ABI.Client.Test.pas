unit Client.AbiClient.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TAbiClientTest = class(TObject)
  public
    [Test]
    procedure TestAbiCli_CallOffChain;
    [Test]
    procedure TestUnpack;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Net.Encodings,
  System.JSON,
  DUnitX.Assert,
  Common.Types,
  Vm.Abi,
  Client,
  Client.Rpc,
  Client.Test.Helper;

{ TAbiClientTest }

procedure TAbiClientTest.TestAbiCli_CallOffChain;
var
  rpc: IRpcClient;
  abiCode, offchainCode: string;
  contract: TAddress;
  abiCli: IAbiClient;
  result: TArray<TObject>;
  k: Integer;
  v: TObject;
begin
  Self.Skip('Skipped by default. This test can be used to call off-chain contract methods.');

  rpc := PreTestRpc(Self, RawUrl);
  if rpc = nil then
    Exit;

  abiCode := '';
  offchainCode := '';
  contract := THex.HexToAddressPanic('');

  abiCli := GetAbiCli(rpc, abiCode, offchainCode, contract);
  Assert.IsNotNull(abiCli, 'GetAbiCli should not return nil');

  result := abiCli.CallOffChain('');
  Assert.IsNotNull(result, 'CallOffChain should not return nil');

  for k, v in result do
    WriteLn(Format('%d %s', [k, v.ToString]));
end;

procedure TAbiClientTest.TestUnpack;
var
  abiCode: string;
  contract: IABIContract;
  data: TBytes;
  id: IMethod;
  inputs: TAddress;
  vStringReader: TStringReader;
begin
  Self.Skip('Skipped by default. This test can be used to unpack contract methods.');

  abiCode := '';
  vStringReader := TStringReader.Create(abiCode);
  try
    contract := TAbiContract.JSONToABIContract(vStringReader);
    Assert.IsNotNull(contract, 'JSONToABIContract should not return nil');
  finally
    vStringReader.Free;
  end;


  data := TBase64Encoding.DecodeStringToBytes('');
  Assert.IsTrue(Length(data) > 4, 'Decoded data should be longer than 4 bytes');

  id := contract.MethodById(Copy(data, 0, 4));
  Assert.IsNotNull(id, 'MethodById should not return nil');
  WriteLn(id.ToString);

  // The UnpackMethod in Delphi is a procedure and does not return an error.
  // It will raise an exception on failure.
  try
    contract.UnpackMethod(inputs, id.Name, data);
    WriteLn(inputs.ToString);
  except
    on E: Exception do
      Assert.Fail('UnpackMethod failed: ' + E.Message);
  end;
end;

initialization
  RegisterTestFixture(TAbiClientTest);
end.