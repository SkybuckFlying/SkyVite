unit RpcApi.API.Utils.Test;

interface
uses
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2;

procedure RunUtilsTest;

implementation

uses
  System.SysUtils,
  System.Rtti,
  System.JSON,
  GoVite.ABI,       // Assumed unit for TAbiContract, TAbiArgument
  RpcApi.API.Utils, // Assumed unit for the Convert function
  DUnitX.TestFramework;

const
  ABI_STR = '[{"inputs":[' +
    '{"type":"bool"},' +
    '{"type":"int8"},{"type":"int256"},{"type":"int56"},' +
    '{"type":"uint8"},{"type":"uint256"},{"type":"uint56"},' +
    '{"type":"address"},{"type":"tokenId"},{"type":"gid"},{"type":"string"},' +
    '{"type":"bytes"},{"type":"bytes32"},' +
    '{"type":"bool[]"},{"type":"bool[2]"},' +
    '{"type":"int8[]"},{"type":"int256[]"},{"type":"int56[]"},' +
    '{"type":"int8[2]"},{"type":"int256[2]"},{"type":"int56[2]"},' +
    '{"type":"uint8[]"},{"type":"uint256[]"},{"type":"uint56[]"},' +
    '{"type":"uint8[2]"},{"type":"uint256[2]"},{"type":"uint56[2]"},' +
    '{"type":"address[]"},{"type":"address[2]"},' +
    '{"type":"tokenId[]"},{"type":"tokenId[2]"},' +
    '{"type":"gid[]"},{"type":"gid[2]"},' +
    '{"type":"string[]"},{"type":"string[2]"}' +
    '],"name":"testFunction","type":"function"}]';

procedure TestConvert;
var
  Params: TArray<string>;
  AbiContract: TAbiContract;
  Arguments: TArray<TValue>;
  PackedData: TBytes;
begin
  Params := [
    'true',
    '-1', '-01', '-0x1',
    '1', '01', '0x1',
    'vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a',
    'tti_5649544520544f4b454e6e40',
    '00000000000000000001',
    'test',
    '89520241000000000000000000000000000000000000000000000000000000000000007b',
    '000000000000000000000000000000000000000000000000000000000000007b',
    '[true,false]', '[true,false]',
    '[-1,-2]', '[-1,-2]', '[-1,-2]',
    '[-1,-2]', '[-1,-2]', '[-1,-2]',
    '[1,2]', '[1,2]', '[1,2]',
    '[1,2]', '[1,2]', '[1,2]',
    '["vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a","vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23"]',
    '["vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a","vite_56fd05b23ff26cd7b0a40957fb77bde60c9fd6ebc35f809c23"]',
    '["tti_5649544520544f4b454e6e40","tti_2d95b4ae402bbcf1429aa1e5"]',
    '["tti_5649544520544f4b454e6e40","tti_2d95b4ae402bbcf1429aa1e5"]',
    '["00000000000000000001","00000000000000000002"]',
    '["00000000000000000001","00000000000000000002"]',
    '["test1","test2"]', '["test1","test2"]'
  ];

  AbiContract := TAbiContract.FromJSON(ABI_STR);
  Assert.IsNotNull(AbiContract, 'ABI contract parsing failed');
  try
    Arguments := Convert(Params, AbiContract.Methods['testFunction'].Inputs);
    Assert.AreEqual(Length(Params), Length(Arguments), 'Converted arguments count mismatch');

    PackedData := AbiContract.PackMethod('testFunction', Arguments);
    Assert.IsTrue(Length(PackedData) > 0, 'Packing method returned no data');

    // The original test prints the results for verification.
    // A full implementation would assert PackedData against a known-good hex string.
    // For now, we just ensure it runs without exceptions.
    // Writeln(BytesToHex(PackedData));
  finally
    AbiContract.Free;
  end;
end;

procedure RunUtilsTest;
begin
  TestConvert;
end;

end.
