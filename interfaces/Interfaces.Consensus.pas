unit Interfaces.Consensus;

interface

uses
  SysUtils, Classes, Generics.Collections, Math.BigInt,
  Common.Types,
  Ledger.Consensus.Core;

type
  TVoteDetails = record
    Vote: TConsensusVote;
    CurrentAddr: TAddress;
    RegisterList: TArray<TAddress>;
    Addr: TDictionary<TAddress, TBigInt>;
  end;

  ITimeIndex = interface(IInterface)
    ['{C0F4F4F4-4F4F-4F4F-9F4F-4F4F4F4F4F4F}']
    function Index2Time(ParaIndex: UInt64; out ParaStartTime, ParaEndTime: TDateTime): Boolean;
    function Time2Index(ParaTime: TDateTime): UInt64;
  end;

implementation

end.
