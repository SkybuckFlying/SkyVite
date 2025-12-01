unit Ledger.Verifier.Account.Verifier;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Common.Version,
  Crypto,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Ledger.Consensus.Core,
  Ledger.Generator,
  Ledger.OnRoad,
  Pow,
  Ledger.Verifier.Common,
  Ledger.Verifier.Errors,
  GoToDelphi.Helpers.BigInt;

type
  TAccountVerifier = class
  private
    FChain: IAccountChain;
    FSbpStatReader: ISBPStatReader;
    FVerifier: IConsensusVerifier;
    FOrManager: IOnRoadPool;
    FLog: ILog;
    function VerifySelf(ParaBlock: TAccountBlock): TVerifierError;
    function CheckAccountAddress(ParaBlock: TAccountBlock): Boolean;
    function VerifyDependency(ParaPendingTask: TAccBlockPendingTask; ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): TVerifyResult;
    function VerifySequenceOfContractReceive(ParaSend: TAccountBlock): Boolean;
    function VerifySendBlockIntegrity(ParaBlock: TAccountBlock): Boolean;
    function VerifyReceiveBlockIntegrity(ParaBlock: TAccountBlock): Boolean;
    function VerifySignature(ParaBlock: TAccountBlock): Boolean;
    function VerifyHash(ParaBlock: TAccountBlock): Boolean;
    function VerifyNonce(ParaBlock: TAccountBlock): Boolean;
    function VerifyProducerLegality(ParaBlock: TAccountBlock): Boolean;
    function VmVerify(ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): IVmAccountBlock;
    function VerifyVMResult(ParaOrigBlock, ParaGenBlock: TAccountBlock): Boolean;
    function VerifyIsReceivedSucceed(ParaBlock: TAccountBlock): Boolean;
    function VerifyConfirmedTimes(ParaRecvBlock: TAccountBlock; ParaSbHeight: UInt64): Boolean;
  public
    constructor Create(ParaChain: IAccountChain; ParaVerifier: IConsensusVerifier; ParaSbpStatReader: ISBPStatReader);
    procedure InitOnRoadPool(ParaManager: TManager);
    function VerifyReferred(ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): TTuple<TVerifyResult, TAccBlockPendingTask, TVerifierError>;
  end;

implementation

uses
  System.StrUtils,
  Log15;

{ TAccountVerifier }

constructor TAccountVerifier.Create(ParaChain: IAccountChain; ParaVerifier: IConsensusVerifier; ParaSbpStatReader: ISBPStatReader);
begin
  inherited Create;
  FChain := ParaChain;
  FVerifier := ParaVerifier;
  FSbpStatReader := ParaSbpStatReader;
  FLog := TLog15.New('module', 'AccountVerifier');
end;

procedure TAccountVerifier.InitOnRoadPool(ParaManager: TManager);
begin
  FLog.Info('InitOnRoadPool');
  FOrManager := ParaManager;
end;

function TAccountVerifier.VerifyReferred(ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): TTuple<TVerifyResult, TAccBlockPendingTask, TVerifierError>;
var
  vPendingTask: TAccBlockPendingTask;
  vErr: TVerifierError;
  vResult: TVerifyResult;
begin
  vPendingTask := Default(TAccBlockPendingTask);
  vErr := VerifySelf(ParaBlock);
  if vErr <> nil then
  begin
    Result := TTuple.Create(TVerifyResult.Fail, vPendingTask, vErr);
    Exit;
  end;

  vResult := VerifyDependency(vPendingTask, ParaBlock, ParaSnapshotHashHeight);
  if vResult <> TVerifyResult.Success then
  begin
    if vResult = TVerifyResult.Pending then
      vPendingTask.AccountTask := vPendingTask.AccountTask + [TAccountPendingTask.Create(ParaBlock.AccountAddress, ParaBlock.Hash)];
    Result := TTuple.Create(vResult, vPendingTask, vErr);
    Exit;
  end;
  Result := TTuple.Create(TVerifyResult.Success, nil, nil);
end;

function TAccountVerifier.VerifyConfirmedTimes(ParaRecvBlock: TAccountBlock; ParaSbHeight: UInt64): Boolean;
var
  vMeta: TContractMeta;
  vSendConfirmedTimes: UInt64;
  vIsSeedCountOk: Boolean;
begin
  vMeta := FChain.GetContractMeta(ParaRecvBlock.AccountAddress);
  if vMeta = nil then
    raise EVerifyContractMetaNotExists.Create;
  if vMeta.SendConfirmedTimes = 0 then
  begin
    Result := True;
    Exit;
  end;
  vSendConfirmedTimes := FChain.GetConfirmedTimes(ParaRecvBlock.FromBlockHash);
  if vSendConfirmedTimes < vMeta.SendConfirmedTimes then
    raise EVerifyConfirmedTimesNotEnough.Create;
  if TUpgrade.IsSeedUpgrade(ParaSbHeight) and (vMeta.SeedConfirmedTimes > 0) then
  begin
    vIsSeedCountOk := FChain.IsSeedConfirmedNTimes(ParaRecvBlock.FromBlockHash, vMeta.SeedConfirmedTimes);
    if not vIsSeedCountOk then
      raise EVerifySeedConfirmedTimesNotEnough.Create;
  end;
  Result := True;
end;

function TAccountVerifier.VerifySelf(ParaBlock: TAccountBlock): TVerifierError;
begin
  if not CheckAccountAddress(ParaBlock) then
  begin
    Result := TVerifierError.Create('Invalid account address');
    Exit;
  end;
  if ParaBlock.IsSendBlock then
  begin
    if not VerifySendBlockIntegrity(ParaBlock) then
    begin
      Result := TVerifierError.CreateDetail(ErrVerifyBlockFieldData.Message, 'Invalid send block integrity');
      Exit;
    end;
  end
  else
  begin
    if not VerifyReceiveBlockIntegrity(ParaBlock) then
    begin
      Result := TVerifierError.CreateDetail(ErrVerifyBlockFieldData.Message, 'Invalid receive block integrity');
      Exit;
    end;
  end;
  if not VerifyProducerLegality(ParaBlock) then
  begin
    Result := TVerifierError.Create('Invalid producer');
    Exit;
  end;
  if not VerifyNonce(ParaBlock) then
  begin
    Result := TVerifierError.Create('Invalid nonce');
    Exit;
  end;
  Result := nil;
end;

function TAccountVerifier.CheckAccountAddress(ParaBlock: TAccountBlock): Boolean;
var
  vMeta: TContractMeta;
begin
  if ParaBlock.AccountAddress.IsContractAddress then
  begin
    vMeta := FChain.GetContractMeta(ParaBlock.AccountAddress);
    if vMeta = nil then
      raise EVerifyContractMetaNotExists.Create;
  end
  else
  begin
    if ParaBlock.IsSendBlock and (ParaBlock.Height <= 1) then
      raise EVerifyAccountNotInvalid.Create;
  end;
  Result := True;
end;

function TAccountVerifier.VerifyDependency(ParaPendingTask: TAccBlockPendingTask; ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): TVerifyResult;
var
  vLatestBlock: TAccountBlock;
  vSendBlock: TAccountBlock;
  vIsReceived: Boolean;
  vReceived: TAccountBlock;
  vIsCorrect: Boolean;
begin
  vLatestBlock := FChain.GetLatestAccountBlock(ParaBlock.AccountAddress);
  if vLatestBlock = nil then
  begin
    if (ParaBlock.Height <> 1) or (not ParaBlock.PrevHash.IsZero) then
      raise EVerifyPrevBlockFailed.Create;
  end
  else
  begin
    if (ParaBlock.Height <> vLatestBlock.Height + 1) or (not ParaBlock.PrevHash.IsEqual(vLatestBlock.Hash)) then
      raise EVerifyPrevBlockFailed.Create;
  end;

  if ParaBlock.IsReceiveBlock then
  begin
    if ParaBlock.FromBlockHash.IsZero then
      raise EVerifyBlockFieldData.Create('receive block FromBlockHash can''t be ZERO_HASH');
    vSendBlock := FChain.GetAccountBlockByHash(ParaBlock.FromBlockHash);
    if vSendBlock = nil then
    begin
      ParaPendingTask.AccountTask := ParaPendingTask.AccountTask + [TAccountPendingTask.Create(nil, ParaBlock.FromBlockHash)];
      Result := TVerifyResult.Pending;
      Exit;
    end;

    vIsReceived := FChain.IsReceived(ParaBlock.FromBlockHash);
    if vIsReceived then
    begin
      vReceived := FChain.GetReceiveAbBySendAb(ParaBlock.FromBlockHash);
      if vReceived <> nil then
        raise EVerifySendIsAlreadyReceived.CreateFmt('already received[received:%s, from:%s]', [vReceived.Hash.ToString, ParaBlock.FromBlockHash.ToString]);
      raise EVerifySendIsAlreadyReceived.Create;
    end;

    if ParaBlock.AccountAddress.IsContractAddress then
    begin
      vIsCorrect := VerifySequenceOfContractReceive(vSendBlock);
      if not vIsCorrect then
        raise EVerifyContractReceiveSequenceFailed.Create;
      if not VerifyConfirmedTimes(ParaBlock, ParaSnapshotHashHeight.Height) then
        raise EVerifyConfirmedTimesNotEnough.Create;
    end;
  end;
  Result := TVerifyResult.Success;
end;

function TAccountVerifier.VerifySequenceOfContractReceive(ParaSend: TAccountBlock): Boolean;
var
  vMeta: TContractMeta;
begin
  if FOrManager = nil then
    raise Exception.Create('onroad manager is not available or supported');
  vMeta := FChain.GetContractMeta(ParaSend.ToAddress);
  if vMeta = nil then
    raise Exception.Create('find contract meta nil');
  Result := FOrManager.IsFrontOnRoadOfCaller(vMeta.Gid, ParaSend.ToAddress, ParaSend.AccountAddress, ParaSend.Hash);
end;

function TAccountVerifier.VerifySendBlockIntegrity(ParaBlock: TAccountBlock): Boolean;
begin
  if ParaBlock.TokenId.IsZero then
  begin
    if (ParaBlock.Amount <> nil) and (ParaBlock.Amount.Cmp(TBigInteger.Zero) <> 0) then
      raise Exception.Create('sendBlock.TokenId can''t be ZERO_TOKENID when amount has value');
  end;
  if ParaBlock.Amount = nil then
    ParaBlock.Amount := TBigInteger.Zero
  else
  begin
    if (ParaBlock.Amount.Sign < 0) or (ParaBlock.Amount.BitLength > TMath.MaxBigIntLen) then
      raise Exception.Create('sendBlock.Amount out of bounds');
  end;

  if ParaBlock.Fee = nil then
    ParaBlock.Fee := TBigInteger.Zero
  else
  begin
    if (ParaBlock.Fee.Sign < 0) or (ParaBlock.Fee.BitLength > TMath.MaxBigIntLen) then
      raise Exception.Create('sendBlock.Fee out of bounds');
  end;
  if not ParaBlock.FromBlockHash.IsZero then
    raise Exception.Create('sendBlock.FromBlockHash must be ZERO_HASH');

  if ParaBlock.AccountAddress.IsContractAddress then
  begin
    if ParaBlock.Height <> 0 then
      raise Exception.Create('contract''s sendBlock.Height must be 0');
    if (Length(ParaBlock.Signature) <> 0) or (Length(ParaBlock.PublicKey) <> 0) then
      raise Exception.Create('signature and publicKey of the contract''s send must be nil');
  end
  else
  begin
    if ParaBlock.Height <= 1 then
      raise EVerifyAccountNotInvalid.Create;
  end;
  Result := True;
end;

function TAccountVerifier.VerifyReceiveBlockIntegrity(ParaBlock: TAccountBlock): Boolean;
var
  vK: Integer;
  vSendBlock: TAccountBlock;
begin
  if not ParaBlock.TokenId.IsZero then
    raise Exception.Create('receive.TokenId must be ZERO_TOKENID');
  if (ParaBlock.Amount <> nil) and (ParaBlock.Amount.Cmp(TBigInteger.Zero) <> 0) then
    raise Exception.Create('receive.Amount can''t be anything other than nil or 0 ');
  if (ParaBlock.Fee <> nil) and (ParaBlock.Fee.Cmp(TBigInteger.Zero) <> 0) then
    raise Exception.Create('receive.Fee can''t be anything other than nil or 0');
  if not ParaBlock.ToAddress.IsZero then
    raise Exception.Create('receive.ToAddress must be ZERO_ADDRESS');
  if ParaBlock.Height <= 0 then
    raise Exception.Create('receive.Height must be larger than 0');
  if (Length(ParaBlock.Data) > 0) and (not ParaBlock.AccountAddress.IsContractAddress) then
    raise Exception.Create('receive.Data is not allowed when the account is general user');

  if (Length(ParaBlock.SendBlockList) > 0) and (not ParaBlock.AccountAddress.IsContractAddress) then
    raise Exception.Create('generalAddr''s receive.SendBlockList must be nil');
  for vK := 0 to High(ParaBlock.SendBlockList) do
  begin
    vSendBlock := ParaBlock.SendBlockList[vK];
    if not VerifySendBlockIntegrity(vSendBlock) then
      raise Exception.CreateFmt('%s, contract:%s, recv-subSends[%d](%s, %s)',
        ['Invalid send block integrity', ParaBlock.AccountAddress.ToString, vK, ParaBlock.Hash.ToString, vSendBlock.Hash.ToString]);
  end;
  Result := True;
end;

function TAccountVerifier.VerifySignature(ParaBlock: TAccountBlock): Boolean;
var
  vIsVerified: Boolean;
begin
  if ParaBlock.AccountAddress.IsContractAddress and ParaBlock.IsSendBlock then
  begin
    if (Length(ParaBlock.Signature) <> 0) or (Length(ParaBlock.PublicKey) <> 0) then
      raise Exception.Create('signature and publicKey of the contract''s send must be nil');
    Result := True;
    Exit;
  end;
  if (Length(ParaBlock.Signature) <= 0) or (Length(ParaBlock.PublicKey) <= 0) then
    raise Exception.Create('signature and publicKey all must have value');
  vIsVerified := TCrypto.VerifySig(ParaBlock.PublicKey, ParaBlock.Hash.Bytes, ParaBlock.Signature);
  if not vIsVerified then
    raise EVerifySignatureFailed.Create;
  Result := True;
end;

function TAccountVerifier.VerifyHash(ParaBlock: TAccountBlock): Boolean;
var
  vComputedHash: THash;
  vIdx: Integer;
  vV: TAccountBlock;
begin
  vComputedHash := ParaBlock.ComputeHash;
  if ParaBlock.Hash.IsZero then
    raise EVerifyHashFailed.Create;
  if not vComputedHash.IsEqual(ParaBlock.Hash) then
    raise EVerifyHashFailed.Create;
  if (not ParaBlock.AccountAddress.IsContractAddress) or ParaBlock.IsSendBlock or (Length(ParaBlock.SendBlockList) <= 0) then
  begin
    Result := True;
    Exit;
  end;
  for vIdx := 0 to High(ParaBlock.SendBlockList) do
  begin
    vV := ParaBlock.SendBlockList[vIdx];
    if not vV.Hash.IsEqual(vV.ComputeSendHash(ParaBlock, vIdx)) then
      raise EVerifyHashFailed.Create;
  end;
  Result := True;
end;

function TAccountVerifier.VerifyNonce(ParaBlock: TAccountBlock): Boolean;
var
  vHash256Data: TBytes;
begin
  if Length(ParaBlock.Nonce) <> 0 then
  begin
    if ParaBlock.AccountAddress.IsContractAddress then
      raise EVerifyPowNotEligible.Create;
    if ParaBlock.Difficulty = nil then
      raise EVerifyPowNotEligible.Create;
    if Length(ParaBlock.Nonce) <> 8 then
      raise EVerifyPowNotEligible.Create;
    vHash256Data := TCrypto.Hash256(ParaBlock.AccountAddress.Bytes, ParaBlock.PrevHash.Bytes);
    if not TPoW.CheckPowNonce(ParaBlock.Difficulty, ParaBlock.Nonce, vHash256Data) then
      raise EVerifyNonceFailed.Create;
  end
  else
  begin
    if ParaBlock.Difficulty <> nil then
      raise EVerifyPowNotEligible.Create;
  end;
  Result := True;
end;

function TAccountVerifier.VerifyProducerLegality(ParaBlock: TAccountBlock): Boolean;
var
  vSend: TAccountBlock;
  vResult: Boolean;
begin
  if ParaBlock.IsReceiveBlock then
  begin
    vSend := FChain.GetAccountBlockByHash(ParaBlock.FromBlockHash);
    if vSend = nil then
      raise EVerifyDependentSendBlockNotExists.Create;
    if not vSend.ToAddress.IsEqual(ParaBlock.AccountAddress) then
      raise EVerifyProducerIllegal.Create;
  end;
  if ParaBlock.AccountAddress.IsContractAddress then
  begin
    if ParaBlock.IsReceiveBlock then
    begin
      vResult := FVerifier.VerifyAccountProducer(ParaBlock);
      if not vResult then
        raise EVerifyProducerIllegal.Create;
    end;
    Result := True;
    Exit;
  end;
  if not TAddress.PubkeyToAddress(ParaBlock.PublicKey).IsEqual(ParaBlock.AccountAddress) then
    raise EVerifyProducerIllegal.Create;
  Result := True;
end;

function TAccountVerifier.VmVerify(ParaBlock: TAccountBlock; ParaSnapshotHashHeight: THashHeight): IVmAccountBlock;
var
  vFromBlock: TAccountBlock;
  vGen: IGenerator;
  vGenResult: IGenResult;
begin
  if ParaBlock.IsReceiveBlock then
  begin
    vFromBlock := FChain.GetAccountBlockByHash(ParaBlock.FromBlockHash);
    if vFromBlock = nil then
      raise EVerifyDependentSendBlockNotExists.Create;
  end;
  vGen := TGenerator.Create(FChain, FSbpStatReader, ParaBlock.AccountAddress, ParaSnapshotHashHeight.Hash, ParaBlock.PrevHash);
  vGenResult := vGen.GenerateWithBlock(ParaBlock, vFromBlock);
  if vGenResult = nil then
    raise EVerifyVmGeneratorFailed.Create('genResult is nil');
  if vGenResult.VMBlock = nil then
  begin
    if vGenResult.Err <> nil then
      raise vGenResult.Err;
    raise Exception.Create('vm failed, blockList is empty');
  end;
  if not VerifyVMResult(ParaBlock, vGenResult.VMBlock.AccountBlock) then
    raise EVerifyVmResultInconsistent.Create('VM result inconsistent');
  Result := vGenResult.VMBlock;
end;

function TAccountVerifier.VerifyVMResult(ParaOrigBlock, ParaGenBlock: TAccountBlock): Boolean;
var
  vK: Integer;
  vV: TAccountBlock;
begin
  if ParaOrigBlock.Hash.IsEqual(ParaGenBlock.Hash) then
  begin
    Result := True;
    Exit;
  end;

  if ParaOrigBlock.BlockType <> ParaGenBlock.BlockType then
    raise Exception.Create('BlockType');
  if not ParaOrigBlock.AccountAddress.IsEqual(ParaGenBlock.AccountAddress) then
    raise Exception.Create('AccountAddress');
  if not ParaOrigBlock.ToAddress.IsEqual(ParaGenBlock.ToAddress) then
    raise Exception.Create('ToAddress');
  if not ParaOrigBlock.FromBlockHash.IsEqual(ParaGenBlock.FromBlockHash) then
    raise Exception.Create('FromBlockHash');
  if ParaOrigBlock.Height <> ParaGenBlock.Height then
    raise Exception.Create('Height');
  if not TBytes.Equals(ParaOrigBlock.Data, ParaGenBlock.Data) then
    raise Exception.Create('Data');
  if not TBytes.Equals(ParaOrigBlock.Nonce, ParaGenBlock.Nonce) then
    raise Exception.Create('Nonce');
  if ((ParaOrigBlock.LogHash = nil) and (ParaGenBlock.LogHash <> nil)) or ((ParaOrigBlock.LogHash <> nil) and (ParaGenBlock.LogHash = nil)) then
    raise Exception.Create('LogHash');
  if (ParaOrigBlock.LogHash <> nil) and (ParaGenBlock.LogHash <> nil) and (not ParaOrigBlock.LogHash.IsEqual(ParaGenBlock.LogHash)) then
    raise Exception.Create('LogHash');

  if ParaOrigBlock.IsSendBlock then
  begin
    if ParaOrigBlock.Fee.Cmp(ParaGenBlock.Fee) <> 0 then
      raise Exception.Create('Fee');
    if ParaOrigBlock.Amount.Cmp(ParaGenBlock.Amount) <> 0 then
      raise Exception.Create('Amount');
    if not ParaOrigBlock.TokenId.IsEqual(ParaGenBlock.TokenId) then
      raise Exception.Create('TokenId');
  end
  else
  begin
    if Length(ParaOrigBlock.SendBlockList) <> Length(ParaGenBlock.SendBlockList) then
      raise Exception.Create('SendBlockList len');
    for vK := 0 to High(ParaOrigBlock.SendBlockList) do
    begin
      vV := ParaOrigBlock.SendBlockList[vK];
      if not vV.Hash.IsEqual(ParaGenBlock.SendBlockList[vK].Hash) then
        raise Exception.CreateFmt('SendBlockList[%d] Hash', [vK]);
    end;
  end;
  raise Exception.Create('Hash');
end;

function TAccountVerifier.VerifyIsReceivedSucceed(ParaBlock: TAccountBlock): Boolean;
begin
  Result := FChain.IsReceived(ParaBlock.FromBlockHash);
end;

end.