unit Ledger.Consensus.Core.SBP.Reader;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  BigNumbers,
  Common.Types,
  Ledger.Consensus.Core.TimeIndex;

type
  // Custom BigInt wrapper for JSON marshaling is not directly needed in Delphi if using a library that handles it.
  // We'll use TBigInteger directly. Serialization can be customized if needed.

  TSbpStats = class
  public
    Index: UInt64;
    BlockNum: UInt64;
    ExceptedBlockNum: UInt64;
    VoteCnt: TBigInteger;
    Name: string;
  end;

  TDayStats = class
  public
    Index: UInt64;
    Stats: TDictionary<string, TSbpStats>;
    VoteSum: TBigInteger;
    BlockTotal: UInt64;

    constructor Create;
    destructor Destroy; override;
  end;

  TBaseStats = class
  public
    Index: UInt64;
    Stats: TDictionary<TAddress, TSbpStats>;

    constructor Create;
    destructor Destroy; override;
  end;

  THourStats = class(TBaseStats)
  end;

  TPeriodStats = class(TBaseStats)
  end;

  ISBPStatReader = interface
    ['{B1A2C3D4-E5F6-A7B8-C9D0-E1F2A3B4C5D6}']
    function DayStats(AStartIndex, AEndIndex: UInt64): TArray<TDayStats>;
    function GetDayTimeIndex: ITimeIndex;

    function HourStats(AStartIndex, AEndIndex: UInt64): TArray<THourStats>;
    function GetHourTimeIndex: ITimeIndex;

    function PeriodStats(AStartIndex, AEndIndex: UInt64): TArray<TPeriodStats>;
    function GetPeriodTimeIndex: ITimeIndex;

    function GetSuccessRateByHour(AIndex: UInt64): TDictionary<TAddress, Integer>;
    function GetNodeCount: Integer;
  end;

implementation

{ TDayStats }

constructor TDayStats.Create;
begin
  Stats := TDictionary<string, TSbpStats>.Create;
end;

destructor TDayStats.Destroy;
begin
  Stats.Free;
  inherited;
end;

{ TBaseStats }

constructor TBaseStats.Create;
begin
  Stats := TDictionary<TAddress, TSbpStats>.Create;
end;

destructor TBaseStats.Destroy;
begin
  Stats.Free;
  inherited;
end;

end.
