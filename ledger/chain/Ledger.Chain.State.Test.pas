unit Ledger.Chain.State.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TStateTests = class
  public
    [Test]
    procedure TestChain_State;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.IOUtils,
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.Util,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Utils,
  Ledger.Chain;

procedure GetValue(const AChain: TChain; const AAccounts: TDictionary<TAddress, TAccount>);
var
  vQueryValue: TBytes;
begin
  for var KVP in AAccounts do
  begin
    var Account := KVP.Value;
    var KeyValue := Account.KeyValue;
    for var KV in KeyValue do
    begin
      vQueryValue := AChain.GetValue(Account.Addr, TEncoding.UTF8.GetBytes(KV.Key));
      Assert.IsTrue(TBytes.Equals(vQueryValue, KV.Value));
    end;
  end;
end;

function checkIterator(AKVSet: TDictionary<string, TBytes>; AGetIterator: TFunc<IStorageIterator>): string;
var
  vIter: IStorageIterator;
  vCount, vCount2: Integer;
  vKey, vValue: TBytes;
  vKVSetStr: string;
begin
  vIter := AGetIterator();
  vCount := 0;
  while vIter.Next do
  begin
    Inc(vCount);
    if vCount > AKVSet.Count then
      raise Exception.Create('too more key');
    vKey := vIter.Key;
    vValue := vIter.Value;
    if not TBytes.Equals(AKVSet[string(vKey)], vValue) then
    begin
      vKVSetStr := '';
      for var KV in AKVSet do
        vKVSetStr := vKVSetStr + Format('%s: %s, ', [KV.Key, BytesToHex(KV.Value)]);
      Result := Format('key: %s, kv: %s, value: %s, queryValue: %s', [string(vKey), vKVSetStr, BytesToHex(AKVSet[string(vKey)]), BytesToHex(vValue)]);
      Exit;
    end;
  end;
  if vCount <> AKVSet.Count then
  begin
    Result := 'key count mismatch';
    Exit;
  end;

  var vIterOk := vIter.Last;
  vCount2 := 0;
  while vIterOk do
  begin
    Inc(vCount2);
    if vCount2 > AKVSet.Count then
      raise Exception.Create(Format('too more key, count2: %d, len(kvSet): %d', [vCount2, AKVSet.Count]));
    vKey := vIter.Key;
    vValue := vIter.Value;
    if not TBytes.Equals(AKVSet[string(vKey)], vValue) then
    begin
      Result := Format('key: %s, kvValue:%s, value: %s', [string(vKey), BytesToHex(AKVSet[string(vKey)]), BytesToHex(vValue)]);
      Exit;
    end;
    vIterOk := vIter.Prev;
  end;
  if vCount2 <> AKVSet.Count then
  begin
    Result := 'key count mismatch';
    Exit;
  end;

  Result := '';
end;

procedure GetStorageIterator(const AChain: TChain; const AAccounts: TDictionary<TAddress, TAccount>);
var
  vErr: string;
begin
  for var KVP in AAccounts do
  begin
    var Account := KVP.Value;
    var KeyValue := Account.KeyValue;
    vErr := checkIterator(KeyValue, function: IStorageIterator
      begin
        Result := AChain.GetStorageIterator(Account.Addr, nil);
      end);
    if vErr <> '' then
      raise Exception.Create(Format('%s, account: %s, account.latestAccountBlock: %s', [vErr, Account.Addr.ToString, Account.LatestBlock.ToString]));
  end;
end;

procedure TestState(const AChain: TChain; const AAccounts: TDictionary<TAddress, TAccount>; const ASnapshotBlocks: TArray<TAccountBlock>);
begin
  GetValue(AChain, AAccounts);
  GetStorageIterator(AChain, AAccounts);
  // Other test calls would go here
end;

procedure TStateTests.TestChain_State;
var
  vChainInstance: TChain;
  vAccounts: TDictionary<TAddress, TAccount>;
  vSnapshotBlockList: TArray<TAccountBlock>;
begin
  SetUp(vChainInstance, vAccounts, vSnapshotBlockList, 10, 910, 3);
  try
    TestState(vChainInstance, vAccounts, vSnapshotBlockList);
  finally
    TearDown(vChainInstance);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStateTests);
end.
