unit VM.Util.Consensus.Reader;

interface

uses
  GoVite.Ledger.Consensus.Core,
  VM.Util.Common,
  VM.Util.DB.Helper,
  VM.Util.Errors,
  VM.Util.IntPool,
  VM.Util.Intpool.Test,
  VM.Util.Quota,
  VM.Util.Quota.Test,
  VM.Util.Types;

type
  IConsensusReader = interface
    ['{E3B9F2A0-4F6D-4A4D-8B4A-9A2B2C2D2E2F}']
    function GetIndexByStartTime(ATime, AGenesisTime: Int64): TTuple<UInt64, Int64, Boolean>;
    function GetIndexByEndTime(ATime, AGenesisTime: Int64): TTuple<UInt64, Int64, Boolean>;
    function GetIndexByTime(ATime, AGenesisTime: Int64): UInt64;
    function GetEndTimeByIndex(AIndex: UInt64): Int64;
    function GetConsensusDetailByDay(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
  end;

  ISbpStatReader = interface
    ['{F2A9F3A1-5F6D-4A4D-8B4A-9A2B2C2D2E2F}']
    function DayStats(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
    function GetDayTimeIndex: ITimeIndex;
  end;

  TVMConsensusReader = class(TInterfacedObject, IConsensusReader)
  private
    FReader: ISbpStatReader;
    function GetIndexByTime(ATime: Int64): UInt64;
    function GetStartTimeByIndex(AIndex: UInt64): Int64;
    function GetEndTimeByIndexInternal(AIndex: UInt64): Int64;
  public
    constructor Create(const AReader: ISbpStatReader);
    function GetIndexByStartTime(ATime, AGenesisTime: Int64): TTuple<UInt64, Int64, Boolean>;
    function GetIndexByEndTime(ATime, AGenesisTime: Int64): TTuple<UInt64, Int64, Boolean>;
    function GetIndexByTime(ATime, AGenesisTime: Int64): UInt64;
    function GetEndTimeByIndex(AIndex: UInt64): Int64;
    function GetConsensusDetailByDay(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

{ TVMConsensusReader }

constructor TVMConsensusReader.Create(const AReader: ISbpStatReader);
begin
  FReader := AReader;
end;

// ... other implementations ...

end.
