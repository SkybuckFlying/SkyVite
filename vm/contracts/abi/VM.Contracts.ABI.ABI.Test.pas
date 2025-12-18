unit VM.Contracts.ABI.ABI.Test;

interface
uses
  VM.Contracts.ABI.ABI.Asset,
  VM.Contracts.ABI.ABI.Dex.Fund,
  VM.Contracts.ABI.ABI.Dex.Fund.Test,
  VM.Contracts.ABI.ABI.Dex.Trade,
  VM.Contracts.ABI.ABI.Gonvernance,
  VM.Contracts.ABI.ABI.Quota,
  VM.Contracts.ABI.Util;

procedure RunAbiContractTests;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.VM, VM.ABI.ABI, VM.Contracts.ABI, // Assumed units
  DUnitX.TestFramework;

procedure TestContractsABIInit;
var
  Tests: TArray<string>;
  Data: string;
  ABI: TAbiContract;
begin
  Tests := [JSONQuota, JSONGovernance, JSONAsset];
  for Data in Tests do
  begin
    try
      ABI := TAbiContract.Create(Data);
      ABI.Free;
    except
      on E: Exception do
        Assert.Fail('Failed to parse ABI JSON: ' + E.Message);
    end;
  end;
end;

procedure TestDeleteTokenId;
type
  TTestCase = record
    Input: TArray<TTokenId>;
    TokenID: TTokenId;
    Output: TArray<TTokenId>;
  end;
var
  Tests: TArray<TTestCase>;
  t1, t2, t3: TTokenId;
  Test: TTestCase;
  IdList, Result, Target: TBytes;
  TID: TTokenId;
begin
  t1 := TTokenId.FromBytes(TBytes.Create($0,$0,$0,$0,$0,$0,$0,$0,$0,$1));
  t2 := TTokenId.FromBytes(TBytes.Create($0,$0,$0,$0,$0,$0,$0,$0,$0,$2));
  t3 := TTokenId.FromBytes(TBytes.Create($0,$0,$0,$0,$0,$0,$0,$0,$0,$3));

  Tests := [
    TTestCase.Create([t1], t1, []),
    TTestCase.Create([t1], t2, [t1]),
    TTestCase.Create([t1, t2], t1, [t2]),
    TTestCase.Create([t1, t2], t2, [t1]),
    TTestCase.Create([t1, t2, t3], t2, [t1, t3])
  ];

  for Test in Tests do
  begin
    IdList := [];
    for TID in Test.Input do
      IdList := AppendTokenID(IdList, TID);

    Result := DeleteTokenID(IdList, Test.TokenID);

    Target := [];
    for TID in Test.Output do
      Target := AppendTokenID(Target, TID);

    Assert.IsTrue(TBytes.Equals(Result, Target), 'DeleteTokenID failed');
  end;
end;

procedure PrintAllMethodIDs;
var
  Pair: TPair<string, TMethod>;
begin
  Writeln('ABI Quota Callbacks:');
  for Pair in ABIQuota.Callbacks do
    Writeln(Format('%s: %s', [Pair.Value.Sig, THex.Encode(Pair.Value.ID)]));

  Writeln('');
  Writeln('ABI Governance Methods:');
  for Pair in ABIGovernance.Methods do
    Writeln(Format('%s: %s', [Pair.Value.Sig, THex.Encode(Pair.Value.ID)]));
end;


procedure RunAbiContractTests;
begin
  TestContractsABIInit;
  TestDeleteTokenId;
  PrintAllMethodIDs;
end;

end.
