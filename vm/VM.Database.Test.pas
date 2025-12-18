unit VM.Database.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.BigInt,
  System.Generics.Collections,
  System.Hash,
  System.SysUtils,
  Vite.Common.Types,
  Vite.Crypto,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Vite.Ledger,
  VM.Abi,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Destination,
  VM.Destination.Test,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Mock.DB,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TTestDatabase = class(TInterfacedObject, IVmDb)
  private
    mBalanceMap: TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInt>>;
    mStorageMap: TDictionary<TAddress, TDictionary<string, TBytes>>;
    mCodeMap: TDictionary<TAddress, TBytes>;
    mContractMetaMap: TDictionary<TAddress, IContractMeta>;
    mLogList: TList<ILog>;
    mSnapshotBlockList: TList<ISnapshotBlock>;
    mAccountBlockMap: TDictionary<TAddress, TDictionary<THash, IAccountBlock>>;
    mAddr: TAddress;
  public
    constructor Create;
    destructor Destroy; override;

    // IVmDb
    function GetBalance(const ParaTokenID: TTokenTypeId): TBigInt;
    procedure SetBalance(const ParaTokenID: TTokenTypeId; const ParaAmount: TBigInt);
    function GetSnapshotBlockByHeight(const ParaHeight: UInt64): ISnapshotBlock;
    procedure Reset;
    procedure Finish;
    procedure SetContractCode(const ParaCode: TBytes);
    function GetContractCode: TBytes;
    function GetContractCodeBySnapshotBlock(const ParaAddr: TAddress; const ParaSnapshotBlock: ISnapshotBlock): TBytes;
    function GetOriginalValue(const ParaKey: TBytes): TBytes;
    function GetValue(const ParaKey: TBytes): TBytes;
    procedure SetValue(const ParaKey, ParaValue: TBytes);
    function PrintStorage(const ParaAddr: TAddress): string;
    function GetReceiptHash: THash;
    procedure AddLog(const ParaLog: ILog);
    function GetLogListHash: THash;
    function GetLogList: TList<ILog>;
    function GetHistoryLogList(const ParaLogHash: THash): TList<ILog>;
    function NewStorageIterator(const ParaPrefix: TBytes): IStorageIterator;
    function Address: TAddress;
    function LatestSnapshotBlock: ISnapshotBlock;
    function PrevAccountBlock: IAccountBlock;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetUnsavedStorage: TArray<TPair<TBytes, TBytes>>;
    function GetUnsavedBalanceMap: TDictionary<TTokenTypeId, TBigInt>;
    function GetUnsavedContractMeta: TDictionary<TAddress, IContractMeta>;
    function GetUnsavedContractCode: TBytes;
    function DebugGetStorage: TDictionary<string, TBytes>;
    function GetCallDepth(const ParaHash: THash): Word;
    procedure SetCallDepth(const ParaDepth: Word);
    function GetUnsavedCallDepth: Word;
    procedure DeleteValue(const ParaKey: TBytes);
    function GetUnconfirmedBlocks(const ParaAddress: TAddress): TArray<IAccountBlock>;
    function GetQuotaUsedList(const ParaAddr: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;
    function GetAccountBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    function GetCompleteBlockByHash(const ParaBlockHash: THash): IAccountBlock;
    procedure SetContractMeta(const ParaToAddr: TAddress; const ParaMeta: IContractMeta);
    function GetContractMeta: IContractMeta;
    function GetConfirmSnapshotHeader(const ParaBlockHash: THash): ISnapshotBlock;
    function GetContractMetaInSnapshot(const ParaContractAddress: TAddress; const ParaSnapshotBlock: ISnapshotBlock): IContractMeta;
    function GetStakeBeneficialAmount(const ParaAddr: TAddress): TBigInt;
    function GetConfirmedTimes(const ParaBlockHash: THash): UInt64;
    function GetLatestAccountBlock(const ParaAddr: TAddress): IAccountBlock;
    function CanWrite: Boolean;
  end;

  [TestFixture]
  TDatabaseTest = class
  public
    [Test]
    procedure TestPrepareDb;
  end;

function PrepareDb(const ParaViteTotalSupply: TBigInt; out ParaAddr1: TAddress; out ParaPrivKey: TPrivateKey; out ParaHash12: THash; out ParaSnapshot2: ISnapshotBlock; out ParaTimestamp: Int64): TTestDatabase;
function ToKey(const ParaKey: TBytes): string;
function ToBytes(const ParaKey: string): TBytes;

implementation

uses
  System.DateUtils,
  Vite.VM.Util;

{ TTestDatabase }

constructor TTestDatabase.Create;
begin
  inherited Create;
  mBalanceMap := TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInt>>.Create;
  mStorageMap := TDictionary<TAddress, TDictionary<string, TBytes>>.Create;
  mCodeMap := TDictionary<TAddress, TBytes>.Create;
  mContractMetaMap := TDictionary<TAddress, IContractMeta>.Create;
  mLogList := TList<ILog>.Create;
  mSnapshotBlockList := TList<ISnapshotBlock>.Create;
  mAccountBlockMap := TDictionary<TAddress, TDictionary<THash, IAccountBlock>>.Create;
end;

destructor TTestDatabase.Destroy;
begin
  mBalanceMap.Free;
  mStorageMap.Free;
  mCodeMap.Free;
  mContractMetaMap.Free;
  mLogList.Free;
  mSnapshotBlockList.Free;
  mAccountBlockMap.Free;
  inherited;
end;

// ... implementation of TTestDatabase methods ...

{ TDatabaseTest }

procedure TDatabaseTest.TestPrepareDb;
var
  vTotalSupply: TBigInt;
  vDb: TTestDatabase;
  vAddr1: TAddress;
  vPrivKey: TPrivateKey;
  vHash12: THash;
  vSnapshot2: ISnapshotBlock;
  vTimestamp: Int64;
  vTokenMap: TDictionary<TTokenTypeId, ITokenInfo>;
  vBalance: TBigInt;
  vGroupList: TArray<IConsensusGroup>;
  vStakeAmount: TBigInt;
  vRegistrationList: TArray<IRegistration>;
begin
  vTotalSupply := TBigInt.Create(1) * (TBigInt.Create(10).Power(18));
  vDb := PrepareDb(vTotalSupply, vAddr1, vPrivKey, vHash12, vSnapshot2, vTimestamp);
  vDb.mAddr := AddressAsset;
  vTokenMap := TAbi.GetTokenMap(vDb);
  Assert.AreEqual(1, vTokenMap.Count);
  Assert.IsNotNull(vTokenMap[ViteTokenId]);
  Assert.AreEqual(0, vTokenMap[ViteTokenId].TotalSupply.CompareTo(vTotalSupply));
  Assert.AreEqual(1, vDb.mAccountBlockMap.Count);
  Assert.AreEqual(2, vDb.mAccountBlockMap[vAddr1].Count);
  vDb.mAddr := vAddr1;
  vBalance := vDb.GetBalance(ViteTokenId);
  Assert.AreEqual(0, vTotalSupply.CompareTo(vBalance));
  vDb.mAddr := AddressGovernance;
  vGroupList := TAbi.GetConsensusGroupList(vDb);
  Assert.AreEqual(2, Length(vGroupList));
  vDb.mAddr := vAddr1;
  vStakeAmount := vDb.GetStakeBeneficialAmount(vAddr1);
  Assert.IsNotNull(vStakeAmount);
  Assert.IsTrue(vStakeAmount.Sign >= 0);
  vDb.mAddr := AddressGovernance;
  vRegistrationList := TAbi.GetRegistrationList(vDb, SNAPSHOT_GID, vAddr1);
  Assert.AreEqual(2, Length(vRegistrationList));
end;

function PrepareDb(const ParaViteTotalSupply: TBigInt; out ParaAddr1: TAddress; out ParaPrivKey: TPrivateKey; out ParaHash12: THash; out ParaSnapshot2: ISnapshotBlock; out ParaTimestamp: Int64): TTestDatabase;
begin
  // Implementation to be added
end;

function ToKey(const ParaKey: TBytes): string;
begin
  Result := TBytes.ToHexString(ParaKey);
end;

function ToBytes(const ParaKey: string): TBytes;
begin
  Result := TBytes.FromHexString(ParaKey);
end;

initialization
  RegisterTestFixture(TDatabaseTest);
end.
