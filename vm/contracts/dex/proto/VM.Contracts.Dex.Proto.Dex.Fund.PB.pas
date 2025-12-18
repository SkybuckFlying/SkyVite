unit VM.Contracts.Dex.Proto.Dex.Fund.PB;

interface

uses
  System.SysUtils System.Generics.Collections,
  VM.Contracts.Dex.Proto.Dex.Order.PB;

type
  TAccount = class
  public
    Token: TBytes;
    Available: TBytes;
    Locked: TBytes;
    VxLocked: TBytes;
    VxUnlocking: TBytes;
    CancellingStake: TBytes;
  end;

  TVxUnlock = class
  public
    PeriodId: UInt64;
    Amount: TBytes;
  end;

  TVxUnlocks = class
  public
    Unlocks: TArray<TVxUnlock>;
  end;
  // ... and so on for all the other message types from the .proto file

implementation

end.
