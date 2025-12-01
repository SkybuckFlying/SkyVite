unit Ledger.Chain.Utils.Key_Prefix;

interface

const
  // index db
  AccountBlockHashKeyPrefix = 1;
  AccountBlockHeightKeyPrefix = 2;
  ReceiveKeyPrefix = 3;
  ConfirmHeightKeyPrefix = 4;
  OnRoadKeyPrefix = 5;
  SnapshotBlockHashKeyPrefix = 7;
  SnapshotBlockHeightKeyPrefix = 8;
  AccountAddressKeyPrefix = 9;
  AccountIdKeyPrefix = 10;

  // state db
  StorageKeyPrefix = 1;
  StorageHistoryKeyPrefix = 2;
  BalanceKeyPrefix = 3;
  BalanceHistoryKeyPrefix = 4;
  CodeKeyPrefix = 5;
  // CodeHistoryKeyPrefix = 6;
  ContractMetaKeyPrefix = 7;
  // ContractMetaHistoryKeyPrefix = 8;
  GidContractKeyPrefix = 9;
  VmLogListKeyPrefix = 10;
  CallDepthKeyPrefix = 11;

  // state redo db
  SnapshotKeyPrefix = 1;

  // onroad db
  OnRoadAddressHeightKeyPrefix = 1;

implementation

end.
