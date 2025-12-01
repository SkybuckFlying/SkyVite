unit Ledger.Chain.IntegrationTest.Test.AccountForIntegration;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Numerics,
  GoToDelphi.Helpers.BigInt,
  Common.Types,
  Crypto,
  Crypto.Ed25519,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  VM.DB;

type
  TAccount = class
  private
    mChainInstance: IChain;
    mOnRoadBlocks: TDictionary<THash, IAccountBlock>;
    mOnRoadMu: TMultiReadExclusiveWriteSynchronizer;
    mLatestBlock: IAccountBlock;
    mAddr: TAddress;
    mPrivateKey: TEd25519PrivateKey;
    mPublicKey: TEd25519PublicKey;
    function GetLatestHeight: UInt64;
    function LatestHash: THash;
  public
    constructor Create(ParaChainInstance: IChain; ParaPubKey: TEd25519PublicKey; ParaPrivateKey: TEd25519PrivateKey);
    destructor Destroy; override;
    function CreateSendBlock(ParaToAccount: TAccount): IVmAccountBlock;
    function CreateReceiveBlock: IVmAccountBlock;
    procedure InsertBlock(ParaVmBlock: IVmAccountBlock; ParaAccounts: TDictionary<TAddress, TAccount>);
    function HasOnRoadBlock: Boolean;
    procedure AddOnRoadBlock(ParaBlock: IAccountBlock);
    procedure DeleteOnRoad(ParaBlockHash: THash);
    function PopOnRoadBlock: IAccountBlock;
    property Addr: TAddress read mAddr;
    property LatestHeight: UInt64 read GetLatestHeight;
  end;

function MakeAccounts(ParaChainInstance: IChain; ParaNum: Integer): TDictionary<TAddress, TAccount>;

implementation

uses
  System.Math;

{ TAccount }

constructor TAccount.Create(ParaChainInstance: IChain; ParaPubKey: TEd25519PublicKey; ParaPrivateKey: TEd25519PrivateKey);
var
  vAddr: TAddress;
  vLatestBlock: IAccountBlock;
  vErr: Exception;
begin
  inherited Create;
  vAddr := PubkeyToAddress(ParaPubKey);
  mAddr := vAddr;
  mPrivateKey := ParaPrivateKey;
  mPublicKey := ParaPubKey;
  mChainInstance := ParaChainInstance;
  mOnRoadBlocks := TDictionary<THash, IAccountBlock>.Create;
  mOnRoadMu := TMultiReadExclusiveWriteSynchronizer.Create;

  vLatestBlock := ParaChainInstance.GetLatestAccountBlock(vAddr, vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
  mLatestBlock := vLatestBlock;
end;

destructor TAccount.Destroy;
begin
  mOnRoadBlocks.Free;
  mOnRoadMu.Free;
  inherited Destroy;
end;

function TAccount.CreateSendBlock(ParaToAccount: TAccount): IVmAccountBlock;
var
  vPrevHash: THash;
  vLatestSnapshotBlock: ISnapshotBlock;
  vVmDb: IVmDb;
  vErr: Exception;
  vKey: TBytes;
  vBlock: IAccountBlock;
  vVmBlock: IVmAccountBlock;
begin
  vPrevHash := LatestHash;
  vLatestSnapshotBlock := mChainInstance.GetLatestSnapshotBlock;
  vVmDb := Tvm_db.NewVmDb(mChainInstance, @mAddr, @vLatestSnapshotBlock.Hash, @vPrevHash, vErr);
  if vErr <> nil then
  begin
    Result := nil;
    Exit;
  end;

  SetLength(vKey, 8);
  TBigEndian.PutUInt64(vKey, TBigInteger.Create(Random(MaxInt)).ToUInt64);
  vErr := vVmDb.SetValue(vKey, vKey);
  if vErr <> nil then
  begin
    Result := nil;
    Exit;
  end;

  vVmDb.Finish;

  vBlock := TAccountBlock.Create;
  vBlock.BlockType := TBlockType.SendCall;
  vBlock.AccountAddress := mAddr;
  vBlock.ToAddress := ParaToAccount.Addr;
  vBlock.Amount := TBigInteger.Create(2);
  vBlock.Height := GetLatestHeight + 1;
  vBlock.PrevHash := vPrevHash;
  vBlock.TokenId := ViteTokenId;
  vBlock.PublicKey := mPublicKey;

  vBlock.Hash := vBlock.ComputeHash;
  vBlock.Signature := TBytes.Create('This is chain mock signature');

  vVmBlock := TVmAccountBlock.Create;
  vVmBlock.AccountBlock := vBlock;
  vVmBlock.VmDb := vVmDb;

  Result := vVmBlock;
end;

function TAccount.CreateReceiveBlock: IVmAccountBlock;
var
  vLatestHeight: UInt64;
  vBlockType: TBlockType;
  vFromBlockHash: THash;
  vUnreceivedBlock: IAccountBlock;
  vPrevHash: THash;
  vLatestSnapshotBlock: ISnapshotBlock;
  vVmDb: IVmDb;
  vErr: Exception;
  vKey: TBytes;
  vBlock: IAccountBlock;
  vVmBlock: IVmAccountBlock;
begin
  vLatestHeight := GetLatestHeight;
  vBlockType := TBlockType.Receive;
  if vLatestHeight >= 1 then
  begin
    vUnreceivedBlock := PopOnRoadBlock;
    if vUnreceivedBlock = nil then
    begin
      Result := nil;
      Exit;
    end;
    vFromBlockHash := vUnreceivedBlock.Hash;
  end;

  vPrevHash := LatestHash;
  vLatestSnapshotBlock := mChainInstance.GetLatestSnapshotBlock;
  vVmDb := Tvm_db.NewVmDb(mChainInstance, @mAddr, @vLatestSnapshotBlock.Hash, @vPrevHash, vErr);
  if vErr <> nil then
  begin
    Result := nil;
    Exit;
  end;

  SetLength(vKey, 8);
  vErr := vVmDb.SetValue(vKey, vKey);
  if vErr <> nil then
  begin
    Result := nil;
    Exit;
  end;

  if vLatestHeight < 1 then
  begin
    vVmDb.SetBalance(ViteTokenId, TBigInteger.Create(1000 * 1000 * 1000));
  end;

  vVmDb.Finish;

  vBlock := TAccountBlock.Create;
  vBlock.BlockType := vBlockType;
  vBlock.AccountAddress := mAddr;
  vBlock.FromBlockHash := vFromBlockHash;
  vBlock.Height := vLatestHeight + 1;
  vBlock.PrevHash := vPrevHash;
  vBlock.PublicKey := mPublicKey;

  vBlock.Hash := vBlock.ComputeHash;
  vBlock.Signature := TBytes.Create('This is chain mock signature');

  vVmBlock := TVmAccountBlock.Create;
  vVmBlock.AccountBlock := vBlock;
  vVmBlock.VmDb := vVmDb;

  Result := vVmBlock;
end;

procedure TAccount.InsertBlock(ParaVmBlock: IVmAccountBlock; ParaAccounts: TDictionary<TAddress, TAccount>);
var
  vBlock: IAccountBlock;
  vToAccount: TAccount;
  vSendBlock: IAccountBlock;
begin
  vBlock := ParaVmBlock.AccountBlock;
  mLatestBlock := vBlock;

  if vBlock.IsSendBlock then
  begin
    vToAccount := ParaAccounts[vBlock.ToAddress];
    vToAccount.AddOnRoadBlock(vBlock);
  end;

  for vSendBlock in vBlock.SendBlockList do
  begin
    vToAccount := ParaAccounts[vSendBlock.ToAddress];
    vToAccount.AddOnRoadBlock(vSendBlock);
  end;
end;

function TAccount.HasOnRoadBlock: Boolean;
begin
  mOnRoadMu.BeginRead;
  try
    Result := mOnRoadBlocks.Count > 0;
  finally
    mOnRoadMu.EndRead;
  end;
end;

procedure TAccount.AddOnRoadBlock(ParaBlock: IAccountBlock);
begin
  mOnRoadMu.BeginWrite;
  try
    mOnRoadBlocks.Add(ParaBlock.Hash, ParaBlock);
  finally
    mOnRoadMu.EndWrite;
  end;
end;

procedure TAccount.DeleteOnRoad(ParaBlockHash: THash);
begin
  mOnRoadMu.BeginWrite;
  try
    mOnRoadBlocks.Remove(ParaBlockHash);
  finally
    mOnRoadMu.EndWrite;
  end;
end;

function TAccount.PopOnRoadBlock: IAccountBlock;
var
  vUnreceivedBlock: IAccountBlock;
  vKey: THash;
begin
  mOnRoadMu.BeginWrite;
  try
    if mOnRoadBlocks.Count <= 0 then
    begin
      Result := nil;
      Exit;
    end;

    for vKey in mOnRoadBlocks.Keys do
    begin
      vUnreceivedBlock := mOnRoadBlocks[vKey];
      Break;
    end;
    mOnRoadBlocks.Remove(vUnreceivedBlock.Hash);
    Result := vUnreceivedBlock;
  finally
    mOnRoadMu.EndWrite;
  end;
end;

function TAccount.GetLatestHeight: UInt64;
begin
  if mLatestBlock <> nil then
  begin
    Result := mLatestBlock.Height;
  end
  else
  begin
    Result := 0;
  end;
end;

function TAccount.LatestHash: THash;
begin
  if mLatestBlock <> nil then
  begin
    Result := mLatestBlock.Hash;
  end
  else
  begin
    Result := THash.Create;
  end;
end;

function MakeAccounts(ParaChainInstance: IChain; ParaNum: Integer): TDictionary<TAddress, TAccount>;
var
  vAccountMap: TDictionary<TAddress, TAccount>;
  vI: Integer;
  vPub: TEd25519PublicKey;
  vPri: TEd25519PrivateKey;
  vErr: Exception;
  vAddr: TAddress;
begin
  vAccountMap := TDictionary<TAddress, TAccount>.Create;
  for vI := 0 to ParaNum - 1 do
  begin
    TEd25519.GenerateKey(vPub, vPri, vErr);
    if vErr <> nil then
    begin
      raise vErr;
    end;
    vAddr := PubkeyToAddress(vPub);
    vAccountMap.Add(vAddr, TAccount.Create(ParaChainInstance, vPub, vPri));
  end;
  Result := vAccountMap;
end;

end.
