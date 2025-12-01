unit Client.SBPUpgrade.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSBPUpgradeTest = class(TObject)
  public
    [Test]
    procedure TestSBPUpgrade;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.Assert,
  Common.Types,
  Client,
  Rpc,
  Client.Test.Helper;

{ TSBPUpgradeTest }

procedure TSBPUpgradeTest.TestSBPUpgrade;
var
  vRpc: IRpcClient;
  vSbpMap: TDictionary<TAddress, string>;
  vVersionMap: TDictionary<string, Cardinal>;
  vSbpList: TArray<TSBPVoteInfo>;
  vSbp: TSBPVoteInfo;
  vLatestHeight: UInt64;
  vBlocks: TArray<TSnapshotBlock>;
  vBlock: TSnapshotBlock;
  vProducer: TAddress;
  vVersion: Cardinal;
  vKey: string;
  vValue: Cardinal;
  vTargetVersion: Cardinal;
  vErr: Exception;
begin
  vRpc := PreTestRpc(Self, RawUrl);
  if vRpc = nil then
    Exit;

  vSbpMap := TDictionary<TAddress, string>.Create;
  vVersionMap := TDictionary<string, Cardinal>.Create;
  try
    vErr := vRpc.GetSBPVoteList(vSbpList);
    Assert.IsNull(vErr, 'GetSBPVoteList failed: ' + vErr.Message);

    for vSbp in vSbpList do
    begin
      WriteLn(Format('%s %s', [vSbp.Name, vSbp.BlockProducingAddress.ToString]));
      vSbpMap.Add(vSbp.BlockProducingAddress, vSbp.Name);
    end;

    vErr := vRpc.GetSnapshotChainHeight(vLatestHeight);
    Assert.IsNull(vErr, 'GetSnapshotChainHeight failed: ' + vErr.Message);

    vErr := vRpc.GetSnapshotBlocks(vLatestHeight, 500, vBlocks);
    Assert.IsNull(vErr, 'GetSnapshotBlocks failed: ' + vErr.Message);

    for vBlock in vBlocks do
    begin
      vProducer := vBlock.Producer;
      vVersion := vBlock.Version;

      WriteLn(Format('%s %s %d', [vSbpMap[vProducer], vProducer.ToString, vVersion]));
      vVersionMap.AddOrSetValue(vSbpMap[vProducer], vVersion);
    end;

    vTargetVersion := 9;
    for vKey in vVersionMap.Keys do
    begin
      vValue := vVersionMap[vKey];
      if vValue < vTargetVersion then
      begin
        WriteLn(Format('%s %d', [vKey, vValue]));
      end;
    end;

    for vKey in vVersionMap.Keys do
    begin
      vValue := vVersionMap[vKey];
      if vValue >= vTargetVersion then
      begin
        Write(Format('%s,', [vKey]));
      end;
    end;
    WriteLn;

    for vKey in vVersionMap.Keys do
    begin
      vValue := vVersionMap[vKey];
      if vValue < vTargetVersion then
      begin
        Write(Format('%s,', [vKey]));
      end;
    end;
    WriteLn;

  finally
    vSbpMap.Free;
    vVersionMap.Free;
  end;
end;

initialization
  RegisterTestFixture(TSBPUpgradeTest);
end.