unit reader;

interface

uses
  Ledger.Verifier.Account.Verifier,
  Ledger.Verifier.Common,
  Ledger.Verifier.Errors,
  Ledger.Verifier.Snapshot.Verifier,
  Ledger.Verifier.Snapshot.Verifier.Test,
  Ledger.Verifier.Verifier,
  System.SysUtils System.Classes,
  Vite.Common Vite.Ledger Vm_Db;

type
  ICssConsensus = interface
    ['{A9B8C7B2-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function VerifyAccountProducer(block: TAccountBlock): Boolean;
  end;

  IOnRoadPool = interface
    ['{B8C7D6C3-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function IsFrontOnRoadOfCaller(gid: TGid; orAddr, caller: TAddress; hash: THash): Boolean;
  end;

  IAccountChain = interface(IChain)
    ['{C7D6E5D4-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function IsReceived(sendBlockHash: THash): Boolean;
    function GetReceiveAbBySendAb(sendBlockHash: THash): TAccountBlock;
    function IsGenesisAccountBlock(block: THash): Boolean;
    function IsSeedConfirmedNTimes(blockHash: THash; n: UInt64): Boolean;
  end;

implementation

end.
