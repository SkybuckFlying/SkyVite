unit verifier;

interface

uses
  Ledger.Verifier.Account.Verifier,
  Ledger.Verifier.Common,
  Ledger.Verifier.Errors,
  Ledger.Verifier.Reader,
  Ledger.Verifier.Snapshot.Verifier,
  Ledger.Verifier.Snapshot.Verifier.Test,
  System.SysUtils System.Classes,
  Verifier.SnapshotVerifier Verifier.AccountVerifier,
  Vite.Common Vite.Crypto Vite.Interfaces Vite.Ledger Vite.Ledger.Chain,
  Vite.Ledger.Consensus Vite.Ledger.OnRoad Verifier.Common Verifier.Errors;

type
  IVerifier = interface
    ['{D6E5F4A3-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function VerifyNetSnapshotBlock(block: TSnapshotBlock): Boolean;
    function VerifyNetAccountBlock(block: TAccountBlock): Boolean;
    function VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): TAccBlockPendingTask;
    function VerifyAccountBlockNonce(block: TAccountBlock): Boolean;
    function VerifyAccountBlockHash(block: TAccountBlock): Boolean;
    function VerifyAccountBlockSignature(block: TAccountBlock): Boolean;
    function VerifyAccountBlockProducerLegality(block: TAccountBlock): Boolean;
    function VerifySnapshotBlockHash(block: TSnapshotBlock): Boolean;
    function VerifySnapshotBlockSignature(block: TAccountBlock): Boolean;
    function VerifyNetSb(block: TSnapshotBlock): Boolean;
    function VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
    function Init(v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
  end;

  TVerifier = class(TInterfacedObject, IVerifier)
  private
    FReader: IChain;
    FSv: TSnapshotVerifier;
    FAv: TAccountVerifier;
    FLog: TLogger;
  public
    constructor Create(ch: IChain);
    destructor Destroy; override;
    function Init(v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
    function VerifyNetSnapshotBlock(block: TSnapshotBlock): Boolean;
    function VerifyNetAccountBlock(block: TAccountBlock): Boolean;
    function VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): TAccBlockPendingTask;
    function VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
    function VerifyAccountBlockHash(block: TAccountBlock): Boolean;
    function VerifyAccountBlockSignature(block: TAccountBlock): Boolean;
    function VerifyAccountBlockNonce(block: TAccountBlock): Boolean;
    function VerifyAccountBlockProducerLegality(block: TAccountBlock): Boolean;
    function VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
    function VerifyNetSb(block: TSnapshotBlock): Boolean;
    function VerifySnapshotBlockHash(block: TSnapshotBlock): Boolean;
    function VerifySnapshotBlockSignature(block: TAccountBlock): Boolean;
  end;

implementation

{ TVerifier }

constructor TVerifier.Create(ch: IChain);
begin
  inherited Create;
  FReader := ch;
  FLog := TLogger.New('module', 'verifier');
end;

destructor TVerifier.Destroy;
begin
  FSv.Free;
  FAv.Free;
  inherited;
end;

function TVerifier.Init(v: IConsensusVerifier; sbpStatReader: ISBPStatReader; manager: TManager): IVerifier;
begin
  FSv := TSnapshotVerifier.Create(FReader, v);
  FAv := TAccountVerifier.Create(FReader, v, sbpStatReader);
  FAv.InitOnRoadPool(manager);
  Result := Self;
end;

function TVerifier.VerifyNetSnapshotBlock(block: TSnapshotBlock): Boolean;
begin
  Result := FSv.VerifyNetSb(block);
end;

function TVerifier.VerifyNetAccountBlock(block: TAccountBlock): Boolean;
begin
  if not VerifyAccountBlockHash(block) then
    Exit(False);
  if not VerifyAccountBlockSignature(block) then
    Exit(False);
  Result := True;
end;

function TVerifier.VerifyPoolAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): TAccBlockPendingTask;
var
  eLog: TLogger;
  detail: string;
  snapshotHashHeight: THashHeight;
  verifyResult: TVerifyResult;
  task: TAccBlockPendingTask;
  err: TVerifierError;
  blocks: IVmAccountBlock;
begin
  eLog := FLog.New('method', 'VerifyPoolAccountBlock');
  detail := Format('sbHash:%s %d; block:addr=%s height=%d hash=%s; ', [string(snapshot.Hash), snapshot.Height, string(block.AccountAddress), block.Height, string(block.Hash)]);
  if block.IsReceiveBlock then
    detail := detail + Format('fromHash=%s;', [string(block.FromBlockHash)]);
  snapshotHashHeight.Height := snapshot.Height;
  snapshotHashHeight.Hash := snapshot.Hash;
  verifyResult := FAv.VerifyReferred(block, @snapshotHashHeight, task, err);
  if err <> nil then
    eLog.Error(err.Message + ':' + err.Detail, 'd', detail);
  case verifyResult of
    vrPending:
      begin
        Result := task;
        Exit;
      end;
    vrSuccess:
      begin
        blocks := FAv.VmVerify(block, @snapshotHashHeight, err);
        if err <> nil then
        begin
          eLog.Error(err.Message + ':' + err.Detail, 'd', detail);
          raise err;
        end;
        Result := nil;
        Exit;
      end;
  else
    raise err;
  end;
end;

function TVerifier.VerifyRPCAccountBlock(block: TAccountBlock; snapshot: TSnapshotBlock): IVmAccountBlock;
var
  log: TLogger;
  detail: string;
  snapshotHashHeight: THashHeight;
  verifyResult: TVerifyResult;
  task: TAccBlockPendingTask;
  err: TVerifierError;
  vmBlock: IVmAccountBlock;
begin
  log := FLog.New('method', 'VerifyRPCAccountBlock');
  detail := Format('sbHash:%s %d; addr:%s, height:%d, hash:%s, pow:(%s,%s)', [string(snapshot.Hash), snapshot.Height, string(block.AccountAddress), block.Height, string(block.Hash), string(block.Difficulty), string(block.Nonce)]);
  if block.IsReceiveBlock then
    detail := detail + Format(',fromH:%s', [string(block.FromBlockHash)]);
  snapshotHashHeight.Height := snapshot.Height;
  snapshotHashHeight.Hash := snapshot.Hash;
  if not VerifyNetAccountBlock(block) then
    raise Exception.Create('Net account block verification failed');

  verifyResult := FAv.VerifyReferred(block, @snapshotHashHeight, task, err);
  if verifyResult <> vrSuccess then
  begin
    if err <> nil then
    begin
      log.Error(err.Message + ':' + err.Detail, 'd', detail);
      raise err;
    end;
    log.Error('verify block failed, pending for:' + task.PendingHashListToStr, 'd', detail);
    raise ErrVerifyRPCBlockPendingState;
  end;

  vmBlock := FAv.VmVerify(block, @snapshotHashHeight, err);
  if err <> nil then
  begin
    log.Error(err.Message + ':' + err.Detail, 'd', detail);
    raise err;
  end;
  Result := vmBlock;
end;

function TVerifier.VerifyAccountBlockHash(block: TAccountBlock): Boolean;
begin
  Result := FAv.VerifyHash(block);
end;

function TVerifier.VerifyAccountBlockSignature(block: TAccountBlock): Boolean;
begin
  if FAv.FChain.IsGenesisAccountBlock(block.Hash) then
  begin
    Result := True;
    Exit;
  end;
  Result := FAv.VerifySignature(block);
end;

function TVerifier.VerifyAccountBlockNonce(block: TAccountBlock): Boolean;
begin
  Result := FAv.VerifyNonce(block);
end;

function TVerifier.VerifyAccountBlockProducerLegality(block: TAccountBlock): Boolean;
begin
  Result := FAv.VerifyProducerLegality(block);
end;

function TVerifier.VerifyReferred(block: TSnapshotBlock): TSnapshotBlockVerifyStat;
begin
  Result := FSv.VerifyReferred(block);
end;

function TVerifier.VerifyNetSb(block: TSnapshotBlock): Boolean;
begin
  Result := FSv.VerifyNetSb(block);
end;

function TVerifier.VerifySnapshotBlockHash(block: TSnapshotBlock): Boolean;
var
  computedHash: THash;
begin
  computedHash := block.ComputeHash;
  if block.Hash.IsZero or (computedHash <> block.Hash) then
    raise ErrVerifyHashFailed;
  Result := True;
end;

function TVerifier.VerifySnapshotBlockSignature(block: TAccountBlock): Boolean;
var
  isVerified: Boolean;
begin
  if FSv.FReader.IsGenesisSnapshotBlock(block.Hash) then
  begin
    Result := True;
    Exit;
  end;

  if (Length(block.Signature) = 0) or (Length(block.PublicKey) = 0) then
    raise Exception.Create('signature or publicKey is nil');
  isVerified := TCrypto.VerifySig(block.PublicKey, block.Hash.Bytes, block.Signature);
  if not isVerified then
    raise ErrVerifySignatureFailed;
  Result := True;
end;

end.
