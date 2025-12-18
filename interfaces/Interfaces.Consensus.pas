unit Interfaces.Consensus;

interface

uses
  Common.Types,
  Interfaces.Chain,
  Interfaces.Generator,
  Interfaces.Verifier,
  Interfaces.VMDB,
  Interfaces.Wallet,
  Ledger.Consensus.Core,
  SysUtils Classes Generics.Collections Math.BigInt;

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
