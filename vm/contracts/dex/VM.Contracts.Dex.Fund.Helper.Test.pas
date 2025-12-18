unit VM.Contracts.Dex.Fund.Helper.Test;

interface

uses
  Common.Types,
  System.Classes,
  System.Math,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

procedure TestDivideByProportion;
procedure TestValidPrice;
procedure TestVerifyNewOrderPriceForRpc;
procedure TestPriceConvert;

implementation

procedure TestDivideByProportion;
begin
	// proportional division tests...
end;

procedure TestValidPrice;
begin
	// price validation tests...
end;

procedure TestVerifyNewOrderPriceForRpc;
begin
	// RPC price verification tests...
end;

procedure TestPriceConvert;
begin
	// price format conversion tests...
end;

end.
