unit VM.Contracts.Contracts.Test;

interface

procedure RunContractsTest;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  GoVite.Types, GoVite.VM, VM.Contracts.ABI, VM.ABI.ABI, VM.Contracts.Contracts, // Assumed units
  DUnitX.TestFramework;

procedure PrintMethodIDs;
var
  Pair: TPair<TAddress, TSimpleContract>;
begin
  // Assumes a global or accessible SimpleContracts: TDictionary<TAddress, TSimpleContract>
  if not Assigned(SimpleContracts) then
    Exit;

  for Pair in SimpleContracts do
  begin
    Writeln(Pair.Key.ToString);
    for var Method in Pair.Value.ABI.Methods.Values do
    begin
      Writeln(Format('%s'#9'%s', [Method.Name, THex.Encode(Method.ID)]));
    end;
  end;
end;

procedure TestSpecificContractCalls;
var
  Addr: TAddress;
  Data1, Data2, Data3: TBytes;
  Method: IBuiltinMethod;
  IsSend: Boolean;
  Err: Exception;
  ParamReIssue: TParamReIssue;
begin
  // This test mirrors the debugging nature of the original Go test.
  // It does not contain strict assertions but rather executes specific scenarios.
  
  TUpgradeBox.CleanupUpgradeBox;
  TUpgradeBox.InitUpgradeBox(TUpgradeBox.NewLatestUpgradeBox);

  Addr := TAddress.Asset;
  Data1 := TBytes.Create($1A, $DB, $55, $72, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $56, $49, $54, $45, $20, $54, $4F, $4B, $45, $4E, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $8B, $BB, $6C, $02, $B3, $01, $67, $2B, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $14, $E3, $68, $71, $ED, $6F, $B2, $3C, $46, $D4, $6E, $CA, $FD, $18, $8A, $CC, $A8, $0B, $6F, $6E, $00);
  Data2 := TBytes.Create($1A, $DB, $55, $72, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $56, $49, $54, $45, $20, $54, $4F, $4B, $45, $4E, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $8B, $BB, $75, $BF, $0A, $1C, $55, $77, $C1, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $14, $E3, $68, $71, $ED, $6F, $B2, $3C, $46, $D4, $6E, $CA, $FD, $18, $8A, $CC, $A8, $0B, $6F, $6E, $00);

  Method := GetBuiltinContractMethod(Addr, Data1, 22906, IsSend, Err);
  if Method is TMethodReIssue then
    Writeln('Method Name: ' + (Method as TMethodReIssue).MethodName);

  // Attempt to unpack using a different method name to see the result
  ParamReIssue := TParamReIssue.Create;
  try
    ABIAsset.UnpackMethod(TValue.From<TParamReIssue>(ParamReIssue), 'Issue', Data1);
    Writeln('Unpacked with Issue: ', ParamReIssue.TokenId.ToString); // Example of logging
  finally
    ParamReIssue.Free;
  end;

  // Add tests for Data2 and Data3 if necessary to replicate the full debugging scenario
end;

procedure RunContractsTest;
begin
  PrintMethodIDs;
  TestSpecificContractCalls;
end;

end.
