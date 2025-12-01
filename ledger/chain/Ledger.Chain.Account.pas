unit Ledger.Chain.Account;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces.Core,
  Crypto.Ed25519.Ed25519,
  vm_db;

type
  TAccount = class
  private
    mAddr: TAddress;
    mPrivateKey: TPrivateKey;
    mPublicKey: TPublicKey;
    mChainInstance: TObject; // TChain
    mInitBalance: TBigInteger;
    mContractMeta: IContractMeta;
    mCode: TBytes;
    mOnRoadBlocks: TDictionary<THash, IAccountBlock>;
    mBlocksMap: TDictionary<THash, IAccountBlock>;
    mSendBlocksMap: TDictionary<THash, IAccountBlock>;
    mReceiveBlocksMap: TDictionary<THash, IAccountBlock>;
    mConfirmedBlockMap: TDictionary<THash, TDictionary<THash, Boolean>>;
    mUnconfirmedBlocks: TDictionary<THash, Boolean>;
    mBalanceMap: TDictionary<THash, TBigInteger>;
    mKvSetMap: TDictionary<THash, TDictionary<string, TBytes>>;
    mLogListMap: TDictionary<THash, IVmLogList>;
    mLatestBlock: IAccountBlock;
  public
    constructor Create(const ParaChainInstance: TObject; const ParaPubKey: TPublicKey; const ParaPrivateKey: TPrivateKey);
    function CreateSendBlock(const ParaToAccount: TAccount; const ParaOptions: TObject): IVmAccountBlock;
    function CreateReceiveBlock(const ParaOptions: TObject): IVmAccountBlock;
    procedure InsertBlock(const ParaVmBlock: IVmAccountBlock; const ParaAccounts: TDictionary<TAddress, TAccount>);
    function KeyValue: TDictionary<string, TBytes>;
    function GetContractMeta: IContractMeta;
    procedure SetContractMeta(const ParaContractMeta: IContractMeta);
    function HasOnRoadBlock: Boolean;
    procedure AddOnRoadBlock(const ParaBlock: IAccountBlock);
    procedure DeleteOnRoad(const ParaBlockHash: THash);
    function PopOnRoadBlock: IAccountBlock;
    procedure Snapshot(const ParaSnapshotHash: THash; const ParaHashHeight: IHashHeight);
    procedure DeleteSnapshotBlocks(const ParaAccounts: TDictionary<TAddress, TAccount>; const ParaSnapshotBlocks: TArray<ISnapshotBlock>; ParaHasRedoLog: Boolean);
    procedure DeleteContractMeta;
    function GetInitBalance: TBigInteger;
    function Balance: TBigInteger;
    procedure deleteAccountBlock(const ParaAccounts: TDictionary<TAddress, TAccount>; const ParaBlockHash: THash);
    procedure rollbackLatestBlock;
    procedure resetLatestBlock;
    function GetLatestHeight: UInt64;
    function latestHash: THash;
    procedure addSendBlock(const ParaBlock: IAccountBlock);
    procedure addReceiveBlock(const ParaBlock: IAccountBlock);
  end;

implementation

{ TAccount }

constructor TAccount.Create(const ParaChainInstance: TObject; const ParaPubKey: TPublicKey; const ParaPrivateKey: TPrivateKey);
begin
  // TODO: Implement this constructor
end;

function TAccount.CreateSendBlock(const ParaToAccount: TAccount; const ParaOptions: TObject): IVmAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TAccount.CreateReceiveBlock(const ParaOptions: TObject): IVmAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

procedure TAccount.InsertBlock(const ParaVmBlock: IVmAccountBlock; const ParaAccounts: TDictionary<TAddress, TAccount>);
begin
  // TODO: Implement this procedure
end;

function TAccount.KeyValue: TDictionary<string, TBytes>;
begin
  // TODO: Implement this function
  Result := nil;
end;

function TAccount.GetContractMeta: IContractMeta;
begin
  // TODO: Implement this function
  Result := nil;
end;

procedure TAccount.SetContractMeta(const ParaContractMeta: IContractMeta);
begin
  // TODO: Implement this procedure
end;

function TAccount.HasOnRoadBlock: Boolean;
begin
  // TODO: Implement this function
  Result := False;
end;

procedure TAccount.AddOnRoadBlock(const ParaBlock: IAccountBlock);
begin
  // TODO: Implement this procedure
end;

procedure TAccount.DeleteOnRoad(const ParaBlockHash: THash);
begin
  // TODO: Implement this procedure
end;

function TAccount.PopOnRoadBlock: IAccountBlock;
begin
  // TODO: Implement this function
  Result := nil;
end;

procedure TAccount.Snapshot(const ParaSnapshotHash: THash; const ParaHashHeight: IHashHeight);
begin
  // TODO: Implement this procedure
end;

procedure TAccount.DeleteSnapshotBlocks(const ParaAccounts: TDictionary<TAddress, TAccount>; const ParaSnapshotBlocks: TArray<ISnapshotBlock>; ParaHasRedoLog: Boolean);
begin
  // TODO: Implement this procedure
end;

procedure TAccount.DeleteContractMeta;
begin
  // TODO: Implement this procedure
end;

function TAccount.GetInitBalance: TBigInteger;
begin
  // TODO: Implement this function
  Result := 0;
end;

function TAccount.Balance: TBigInteger;
begin
  // TODO: Implement this function
  Result := 0;
end;

procedure TAccount.deleteAccountBlock(const ParaAccounts: TDictionary<TAddress, TAccount>; const ParaBlockHash: THash);
begin
  // TODO: Implement this procedure
end;

procedure TAccount.rollbackLatestBlock;
begin
  // TODO: Implement this procedure
end;

procedure TAccount.resetLatestBlock;
begin
  // TODO: Implement this procedure
end;

function TAccount.GetLatestHeight: UInt64;
begin
  // TODO: Implement this function
  Result := 0;
end;

function TAccount.latestHash: THash;
begin
  // TODO: Implement this function
  Result := Default(THash);
end;

procedure TAccount.addSendBlock(const ParaBlock: IAccountBlock);
begin
  // TODO: Implement this procedure
end;

procedure TAccount.addReceiveBlock(const ParaBlock: IAccountBlock);
begin
  // TODO: Implement this procedure
end;

end.