unit Ledger.Consensus.Core.TimeIndex;

interface

uses
  System.SysUtils;

type
  ITimeIndex = interface
    ['{E3A2E8B9-A2C3-4B8D-9B1A-2A8E5C1B4A5D}']
    function Index2Time(AIndex: UInt64): TDateTime;
    function Time2Index(const ATime: TDateTime): UInt64;
  end;

  TTimeIndex = class(TInterfacedObject, ITimeIndex)
  private
    FGenesisTime: TDateTime;
    FInterval: TTimeSpan; // Represented as TTimeSpan for clarity
  public
    constructor Create(const AGenesisTime: TDateTime; const AInterval: TTimeSpan);
    function Index2Time(AIndex: UInt64): TDateTime;
    function Time2Index(const ATime: TDateTime): UInt64;
  end;

implementation

{ TTimeIndex }

constructor TTimeIndex.Create(const AGenesisTime: TDateTime; const AInterval: TTimeSpan);
begin
  FGenesisTime := AGenesisTime;
  FInterval := AInterval;
end;

function TTimeIndex.Index2Time(AIndex: UInt64): TDateTime;
var
  vOffset: Int64;
begin
  // TTimeSpan stores time in 100-nanosecond ticks.
  // Multiply interval by index to get total offset from genesis.
  vOffset := FInterval.Ticks * AIndex;
  Result := FGenesisTime + TTimeSpan.FromTicks(vOffset);
end;

function TTimeIndex.Time2Index(const ATime: TDateTime): UInt64;
var
  vSubSec: Int64;
begin
  if ATime < FGenesisTime then
    Result := 0
  else
  begin
    vSubSec := (ATime - FGenesisTime).TotalSeconds;
    Result := vSubSec div FInterval.TotalSeconds;
  end;
end;

end.
