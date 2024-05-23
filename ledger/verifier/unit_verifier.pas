unit unit_verifier;

// Convert GO to Delphi, Direct

interface

uses
  SysUtils, Classes, Interfaces, Ledger, Log15;

type
  TVerifyResult = (PENDING, SUCCESS);

  IVerifier = interface
    function VerifyNetSnapshotBlock(block: TSnapshotBlock): Exception;
    function VerifyNetAccountBlock(block: TAccountBlock): Exception;
    function VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyAccountBlockNonce(block: TAccountBlock): Exception;
    function VerifyAccountBlockHash(block: TAccountBlock): Exception;
    function VerifyAccountBlockSignature(block: TAccountBlock): Exception;
    function VerifyAccountBlockProducerLegality(block: TAccountBlock): Exception;
    function VerifySnapshotBlockHash(block: TSnapshotBlock): Exception;
    function VerifySnapshotBlockSignature(block: TSnapshotBlock): Exception;
    function VerifyNetSb(block: TSnapshotBlock): Exception;
    function VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
    function Init(cs_v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
  end;

  TVerifier = class(TInterfacedObject, IVerifier)
  private
    FReader: TChain;
    FSv: TSnapshotVerifier;
    FAv: TAccountVerifier;
    FLog: TLog15Logger;
  public
    constructor Create(ch: TChain);
    function VerifyNetSnapshotBlock(block: TSnapshotBlock): Exception;
    function VerifyNetAccountBlock(block: TAccountBlock): Exception;
    function VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyAccountBlockNonce(block: TAccountBlock): Exception;
    function VerifyAccountBlockHash(block: TAccountBlock): Exception;
    function VerifyAccountBlockSignature(block: TAccountBlock): Exception;
    function VerifyAccountBlockProducerLegality(block: TAccountBlock): Exception;
    function VerifySnapshotBlockHash(block: TSnapshotBlock): Exception;
    function VerifySnapshotBlockSignature(block: TSnapshotBlock): Exception;
    function VerifyNetSb(block: TSnapshotBlock): Exception;
    function VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
    function Init(cs_v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
  end;

implementation

constructor TVerifier.Create(ch: TChain);
begin
  FReader := ch;
  FLog := TLog15Logger.Create('module', 'verifier');
end;

function TVerifier.VerifyNetSnapshotBlock(block: TSnapshotBlock): Exception;
begin
  Result := FSv.VerifyNetSb(block);
end;

function TVerifier.VerifyNetAccountBlock(block: TAccountBlock): Exception;
begin
  if VerifyAccountBlockHash(block) <> nil then
    Exit(VerifyAccountBlockHash(block));
  if VerifyAccountBlockSignature(block) <> nil then
    Exit(VerifyAccountBlockSignature(block));
  Result := nil;
end;

function TVerifier.VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
var
  detail: string;
  snapshotHashHeight: THashHeight;
  verifyResult: TVerifyResult;
  task: TAccBlockPendingTask;
  vmBlock: IVmAccountBlock;
begin
  detail := Format('sbHash:%v %v; addr:%v, height:%v, hash:%v, pow:(%v,%v)', [snapshot.Hash, snapshot.Height, block.AccountAddress, block.Height, block.Hash, block.Difficulty, block.Nonce]);
  if block.IsReceiveBlock then
    detail := detail + Format(',fromH:%v', [block.FromBlockHash]);
  snapshotHashHeight := THashHeight.Create(snapshot.Height, snapshot.Hash);
  if VerifyNetAccountBlock(block) <> nil then
  begin
    FLog.Error(VerifyNetAccountBlock(block).Message, 'd', detail);
    Exit(nil);
  end;
  verifyResult := FAv.verifyReferred(block, snapshotHashHeight, task);
  if verifyResult <> SUCCESS then
  begin
    FLog.Error('verify block failed, pending for:' + task.pendingHashListToStr(), 'd', detail);
    Exit(nil);
  end;
  vmBlock := FAv.vmVerify(block, snapshotHashHeight);
  Result := vmBlock;
end;

function TVerifier.VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
var
  detail: string;
  snapshotHashHeight: THashHeight;
  verifyResult: TVerifyResult;
  task: TAccBlockPendingTask;
  vmBlock: IVmAccountBlock;
begin
  detail := Format('sbHash:%v %v; block:addr=%v height=%v hash=%v; ', [snapshot.Hash, snapshot.Height, block.AccountAddress, block.Height, block.Hash]);
  if block.IsReceiveBlock then
    detail := detail + Format('fromHash=%v;', [block.FromBlockHash]);
  snapshotHashHeight := THashHeight.Create(snapshot.Height, snapshot.Hash);
  verifyResult := FAv.verifyReferred(block, snapshotHashHeight, task);
  if verifyResult = PENDING then
    Exit(task, nil, nil)
  else if verifyResult = SUCCESS then
  begin
    vmBlock := FAv.vmVerify(block, snapshotHashHeight);
    Result := nil, vmBlock, nil;
  end
  else
    Result := nil, nil, nil;
end;

function TVerifier.VerifyAccountBlockHash(block: TAccountBlock): Exception;
begin
  Result := FAv.verifyHash(block);
end;

function TVerifier.VerifyAccountBlockSignature(block: TAccountBlock): Exception;
begin
  if FAv.chain.IsGenesisAccountBlock(block.Hash) then
    Exit(nil);
  Result := FAv.verifySignature(block);
end;

function TVerifier.VerifyAccountBlockNonce(block: TAccountBlock): Exception;
begin
  Result := FAv.verifyNonce(block);
end;

function TVerifier.VerifyAccountBlockProducerLegality(block: TAccountBlock): Exception;
begin
  Result := FAv.verifyProducerLegality(block);
end;

function TVerifier.VerifySnapshotBlockHash(block: TSnapshotBlock): Exception;
var
  computedHash: THash;
begin
  computedHash := block.ComputeHash;
  if block.Hash.IsZero or (computedHash <> block.Hash) then
    Result := ErrVerifyHashFailed
  else
    Result := nil;
end;

function TVerifier.VerifySnapshotBlockSignature(block: TSnapshotBlock): Exception;
var
  isVerified: Boolean;
begin
  if FSv.reader.IsGenesisSnapshotBlock(block.Hash) then
    Exit(nil);
  if (Length(block.Signature) = 0) or (Length(block.PublicKey) = 0) then
    Result := Exception.Create('signature or publicKey is nil')
  else
  begin
    isVerified := crypto.VerifySig(block.PublicKey, block.Hash.Bytes, block.Signature);
    if not isVerified then
      Result := ErrVerifySignatureFailed
    else
      Result := nil;
  end;
end;

function TVerifier.VerifyNetSb(block: TSnapshotBlock): Exception;
begin
  Result := FSv.VerifyNetSb(block);
end;

function TVerifier.VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
begin
  Result := FSv.VerifyReferred(block);
end;

function TVerifier.Init(cs_v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
begin
  FSv := TSnapshotVerifier.Create(FReader, cs_v);
  FAv := TAccountVerifier.Create(FReader, cs_v, sbpStatReader);
  FAv.InitOnRoadPool(manager);
  Result := Self;
end;

function NewVerifier(ch: TChain): IVerifier;
begin
  Result := TVerifier.Create(ch);
end;

end.

