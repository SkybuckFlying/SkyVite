unit VM.Contracts.ABI.ABI.Dex.Fund.Test;

interface
uses
  VM.Contracts.ABI.ABI.Asset,
  VM.Contracts.ABI.ABI.Dex.Fund,
  VM.Contracts.ABI.ABI.Dex.Trade,
  VM.Contracts.ABI.ABI.Gonvernance,
  VM.Contracts.ABI.ABI.Quota,
  VM.Contracts.ABI.ABI.Test,
  VM.Contracts.ABI.Util;

procedure RunDexFundAbiTest;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.VM, VM.Contracts.ABI, // Assumed units
  DUnitX.TestFramework;

procedure TestABI_MethodNameDexFundPeriodJob;
var
  Result: TArray<string>;
  JobIds: TArray<Byte>;
  I: Integer;
  JobId: Byte;
  LastPeriod: UInt64;
  Byts: TBytes;
begin
  Result := ['803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAI=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY=',
    '803SLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAc='];
  JobIds := [1, 2, 3, 4, 5, 6, 7];

  for I := 0 to High(JobIds) do
  begin
    JobId := JobIds[I];
    LastPeriod := 0;
    Byts := ABIDexFund.PackMethod(MethodNameDexFundPeriodJob, [TValue.From<UInt64>(LastPeriod + 1), TValue.From<Byte>(JobId)]);
    Assert.AreEqual(Result[I], TConvert.ToBase64(Byts), 'Packed data mismatch for JobId ' + JobId.ToString);
  end;
end;

procedure TestABI_MethodNameDexFundEndorseVxV2;
var
  Result: string;
  Byts: TBytes;
begin
  Result := 'Kcu6jg==';
  Byts := ABIDexFund.PackMethod(MethodNameDexFundEndorseVxV2, []);
  Assert.AreEqual(Result, TConvert.ToBase64(Byts), 'Packed data for EndorseVxV2 mismatch');
end;

procedure TestABI_MethodNameDexFundTradeAdminConfig;
var
  VTT, BTC, ETH, USDT, VITE: TTokenId;
  Enable: Boolean;
  Data: TBytes;
  Result: string;
begin
  VTT := TTokenId.FromHexString('tti_2736f320d7ed1c2871af1d9d');
  BTC := TTokenId.FromHexString('tti_322862b3f8edae3b02b110b1');
  ETH := TTokenId.FromHexString('tti_06822f8d096ecdf9356b666c');
  USDT := TTokenId.FromHexString('tti_973afc9ffd18c4679de42e93');
  VITE := TTokenId.FromHexString('tti_5649544520544f4b454e6e40');
  Enable := True;

  // Test Case 1
  Data := ABIDexFund.PackMethod(MethodNameDexFundTradeAdminConfig, [TValue.From<Byte>(1), TValue.From<TTokenId>(VTT), TValue.From<TTokenId>(BTC), TValue.From<Boolean>(Enable), TValue.From<TTokenId>(VITE), TValue.From<Byte>(1), TValue.From<Byte>(1), TValue.From<TBigInteger>(0), TValue.From<Byte>(1), TValue.From<TBigInteger>(0)]);
  Result := 'Qa/ldgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAACc28yDX7Rwoca8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAMihis/jtrjsCsQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFZJVEUgVE9LRU4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  Assert.AreEqual(Result, TConvert.ToBase64(Data));

  // Test Case 2
  Data := ABIDexFund.PackMethod(MethodNameDexFundTradeAdminConfig, [TValue.From<Byte>(1), TValue.From<TTokenId>(VTT), TValue.From<TTokenId>(USDT), TValue.From<Boolean>(Enable), TValue.From<TTokenId>(VITE), TValue.From<Byte>(1), TValue.From<Byte>(1), TValue.From<TBigInteger>(0), TValue.From<Byte>(1), TValue.From<TBigInteger>(0)]);
  Result := 'Qa/ldgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAACc28yDX7Rwoca8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAlzr8n/0YxGed5AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFZJVEUgVE9LRU4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  Assert.AreEqual(Result, TConvert.ToBase64(Data));

  // ... other test cases from the Go file would be added here ...
end;


procedure RunDexFundAbiTest;
begin
  TestABI_MethodNameDexFundPeriodJob;
  TestABI_MethodNameDexFundEndorseVxV2;
  TestABI_MethodNameDexFundTradeAdminConfig;
end;

end.
