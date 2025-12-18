unit Ledger.Chain.Test.Tools.Mock;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Test.Tools.Data.Dir,
  Ledger.Consensus.Core,
  System.Generics.Collections,
  System.SysUtils;

type
  // Mock SBPStatReader can be implemented using a testing framework like DUnitX/Delphi Mocks if needed
  // For now, a placeholder or a simple manual mock class would suffice.
  IMockSBPStatReader = ISBPStatReader;

  TMockCssVerifier = class(TInterfacedObject, IConsensusVerifier)
  public
    function VerifyABsProducer(const aABs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
    function VerifySnapshotProducer(const aBlock: ISnapshotBlock): Boolean;
    function VerifyAccountProducer(const aBlock: IAccountBlock): Boolean;
  end;

function NewPeriodTimeIndex(const aGenesisTime: TDateTime): ITimeIndex;
function NewSbpStatReader: IMockSBPStatReader;
function NewVerifier: IConsensusVerifier;

implementation

{ TMockCssVerifier }

function TMockCssVerifier.VerifyABsProducer(const aABs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
begin
  Result := nil;
end;

function TMockCssVerifier.VerifySnapshotProducer(const aBlock: ISnapshotBlock): Boolean;
begin
  Result := True;
end;

function TMockCssVerifier.VerifyAccountProducer(const aBlock: IAccountBlock): Boolean;
begin
  Result := True;
end;

function NewPeriodTimeIndex(const aGenesisTime: TDateTime): ITimeIndex;
var
  vGenesis: TDateTime;
begin
  // The Go code uses Unix time. TDateTime is based on a different epoch.
  // We'll assume the caller provides a correct TDateTime.
  // The 75-second interval is represented as a timespan.
  vGenesis := aGenesisTime;
  Result := TTimeIndex.Create(vGenesis, TTimeSpan.FromSeconds(75));
end;

function NewSbpStatReader: IMockSBPStatReader;
begin
  // Without a mocking framework, we can't generate a mock.
  // Returning nil or a simple implementation. For this translation, we'll return nil
  // as the Go version relies on gomock to generate the implementation.
  Result := nil;
end;

function NewVerifier: IConsensusVerifier;
begin
  Result := TMockCssVerifier.Create;
end;

end.
