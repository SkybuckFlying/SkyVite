unit Ledger.Chain.Plugins.Onroad.Info.Test;

interface

uses
  Common.Types,
  Ledger.Chain.Plugins.DB.Key.Prefix,
  Ledger.Chain.Plugins.Filter.Token,
  Ledger.Chain.Plugins.Interface,
  Ledger.Chain.Plugins.Onroad.Info,
  Ledger.Chain.Plugins.Plugins;

var
  Contract1, Contract2, Contract3: TAddress;
  Caller1, Caller2, Caller3: TAddress;
  ContractList: TArray<TAddress>;
  GeneralList: TArray<TAddress>;

implementation

initialization
  Contract1 := TAddress.FromBytes(TBytes.Create($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01));
  Contract2 := TAddress.FromBytes(TBytes.Create($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02));
  Contract3 := TAddress.FromBytes(TBytes.Create($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03));
  Caller1 := TAddress.FromBytes(TBytes.Create($01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01));
  Caller2 := TAddress.FromBytes(TBytes.Create($01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02));
  Caller3 := TAddress.FromBytes(TBytes.Create($01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03));

  ContractList := [Contract1, Contract2, Contract3];
  GeneralList := [Caller1, Caller2, Caller3];
end.
