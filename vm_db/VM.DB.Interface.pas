unit Vm.Db.Interfaces;

interface

uses
  System.SysUtils, System.Classes, System.Math.BigInteger,
  Vite.Common.Types, Vite.Interfaces, Vite.Interfaces.Core;

type
  IChain = interface
    ['{D4A2A8B7-0B4A-4E2D-8F1A-3B6C1E5D7F6B}']
    function GetQuotaUsedList(Address: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;
    function GetBalance(Addr: TAddress; TokenId: TTokenTypeId): TPair<TBigInteger, Exception>;
    function GetContractCode(ContractAddr: TAddress): TPair<TBytes, Exception>;
    function GetContractMeta(ContractAddress: TAddress): TPair<IContractMeta, Exception>;
    function GetConfirmSnapshotHeaderByAbHash(AbHash: THash): TPair<ISnapshotBlock, Exception>;
    function GetConfirmedTimes(BlockHash: THash): TPair<UInt64, Exception>;
    function GetContractMetaInSnapshot(ContractAddress: TAddress; SnapshotHeight: UInt64): TPair<IContractMeta, Exception>;
    function GetSnapshotHeaderByHash(Hash: THash): TPair<ISnapshotBlock, Exception>;
    function GetSnapshotBlockByHeight(Height: UInt64): TPair<ISnapshotBlock, Exception>;
    function GetAccountBlockByHash(BlockHash: THash): TPair<IAccountBlock, Exception>;
    function GetLatestAccountBlock(Addr: TAddress): TPair<IAccountBlock, Exception>;
    function GetVmLogList(LogHash: THash): TPair<IVmLogList, Exception>;
    function GetUnconfirmedBlocks(Addr: TAddress): TArray<IAccountBlock>;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetStakeBeneficialAmount(Addr: TAddress): TPair<TBigInteger, Exception>;
    function GetStorageIterator(Address: TAddress; Prefix: TBytes): TPair<IStorageIterator, Exception>;
    function GetValue(Addr: TAddress; Key: TBytes): TPair<TBytes, Exception>;
    function GetCallDepth(SendBlockHash: THash): TPair<UInt16, Exception>;
    function GetSnapshotBlockByContractMeta(Addr: TAddress; FromHash: THash): TPair<ISnapshotBlock, Exception>;
    function GetSeedConfirmedSnapshotBlock(Addr: TAddress; FromHash: THash): TPair<ISnapshotBlock, Exception>;
    function GetSeed(LimitSb: ISnapshotBlock; FromHash: THash): TPair<UInt64, Exception>;
  end;

implementation

end.
