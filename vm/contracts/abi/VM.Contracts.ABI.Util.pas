unit Vm.Contracts.Abi.AbiUtil;

interface

uses
  Common.Types.Address Interfaces.Chain,
  System.SysUtils System.Classes,
  VM.Contracts.ABI.ABI.Asset,
  VM.Contracts.ABI.ABI.Dex.Fund,
  VM.Contracts.ABI.ABI.Dex.Fund.Test,
  VM.Contracts.ABI.ABI.Dex.Trade,
  VM.Contracts.ABI.ABI.Gonvernance,
  VM.Contracts.ABI.ABI.Quota,
  VM.Contracts.ABI.ABI.Test;

type
  IStorageDatabase = interface
    ['{A7E4E2D8-338A-462E-A41E-2722816945E0}']
    function GetValue(Key: TBytes): TBytes;
    function NewStorageIterator(Prefix: TBytes): IStorageIterator;
    function Address: TAddress;
  end;

function FilterKeyValue(Key, Value: TBytes; F: TFunc<TBytes, Boolean>): Boolean;

implementation

function FilterKeyValue(Key, Value: TBytes; F: TFunc<TBytes, Boolean>): Boolean;
begin
  Result := (Length(Value) > 0) and ((F = nil) or F(Key));
end;

end.
