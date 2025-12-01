unit consensus.mock_dpos_reader;

interface

uses
  System.SysUtils,
  System.Classes,
  Vite.Core,
  Vite.Types,
  consensus.core,
  consensus.dpos;

type
  TMockDposReader = class(TInterfacedObject, IDposReader)
  public
    function ElectionIndex(Index: UInt64): TElectionResult;
    function GetInfo: TGroupInfo;
    function Time2Index(T: TDateTime): UInt64;
    function Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
    function GenProofTime(T: UInt64): TDateTime;
    function VerifyProducer(const Address: TAddress; T: TDateTime): Boolean;
  end;

implementation

{ TMockDposReader }

function TMockDposReader.ElectionIndex(Index: UInt64): TElectionResult;
begin
  // Mock implementation
  Result := nil;
end;

function TMockDposReader.GetInfo: TGroupInfo;
begin
  // Mock implementation
  Result := nil;
end;

function TMockDposReader.Time2Index(T: TDateTime): UInt64;
begin
  // Mock implementation
  Result := 0;
end;

function TMockDposReader.Index2Time(I: UInt64): TTuple<TDateTime, TDateTime>;
begin
  // Mock implementation
  Result := TTuple<TDateTime, TDateTime>.Create(0, 0);
end;

function TMockDposReader.GenProofTime(T: UInt64): TDateTime;
begin
  // Mock implementation
  Result := 0;
end;

function TMockDposReader.VerifyProducer(const Address: TAddress; T: TDateTime): Boolean;
begin
  // Mock implementation
  Result := False;
end;

end.
