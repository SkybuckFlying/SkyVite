unit errors;

interface

uses
  Ledger.Verifier.Account.Verifier,
  Ledger.Verifier.Common,
  Ledger.Verifier.Reader,
  Ledger.Verifier.Snapshot.Verifier,
  Ledger.Verifier.Snapshot.Verifier.Test,
  Ledger.Verifier.Verifier,
  System.SysUtils;

var
  ErrVerifyVmGeneratorFailed: Exception;
  ErrVerifyAccountNotInvalid: Exception;
  ErrVerifyContractMetaNotExists: Exception;
  ErrVerifyConfirmedTimesNotEnough: Exception;
  ErrVerifySeedConfirmedTimesNotEnough: Exception;
  ErrVerifyHashFailed: Exception;
  ErrVerifySignatureFailed: Exception;
  ErrVerifyNonceFailed: Exception;
  ErrVerifyPrevBlockFailed: Exception;
  ErrVerifyRPCBlockPendingState: Exception;
  ErrVerifyDependentSendBlockNotExists: Exception;
  ErrVerifyPowNotEligible: Exception;
  ErrVerifyProducerIllegal: Exception;
  ErrVerifyBlockFieldData: Exception;
  ErrVerifyContractReceiveSequenceFailed: Exception;
  ErrVerifySendIsAlreadyReceived: Exception;
  ErrVerifyVmResultInconsistent: Exception;

type
  TVerifierError = class(Exception)
  private
    FDetail: string;
  public
    constructor Create(const AMessage: string);
    constructor CreateDetail(const AMessage, ADetail: string);
    property Detail: string read FDetail;
  end;

implementation

{ TVerifierError }

constructor TVerifierError.Create(const AMessage: string);
begin
  inherited Create(AMessage);
end;

constructor TVerifierError.CreateDetail(const AMessage, ADetail: string);
begin
  inherited Create(AMessage);
  FDetail := ADetail;
end;

initialization
  ErrVerifyVmGeneratorFailed := Exception.Create('generator in verifier run failed');
  ErrVerifyAccountNotInvalid := Exception.Create('general account''s sendBlock.Height must be larger than 1');
  ErrVerifyContractMetaNotExists := Exception.Create('contract meta not exists');
  ErrVerifyConfirmedTimesNotEnough := Exception.Create('verify referred send''s confirmedTimes not enough');
  ErrVerifySeedConfirmedTimesNotEnough := Exception.Create('verify referred send''s seed confirmedTimes not enough');
  ErrVerifyHashFailed := Exception.Create('verify hash failed');
  ErrVerifySignatureFailed := Exception.Create('verify signature failed');
  ErrVerifyNonceFailed := Exception.Create('check pow nonce failed');
  ErrVerifyPrevBlockFailed := Exception.Create('verify prevBlock failed, incorrect use of prevHash or fork happened');
  ErrVerifyRPCBlockPendingState := Exception.Create('verify referred block failed, pending for them');
  ErrVerifyDependentSendBlockNotExists := Exception.Create('receive''s dependent send block is not exists on chain');
  ErrVerifyPowNotEligible := Exception.Create('verify that it''s not eligible to do pow');
  ErrVerifyProducerIllegal := Exception.Create('verify that the producer is illegal');
  ErrVerifyBlockFieldData := Exception.Create('verify that block field data is illegal');
  ErrVerifyContractReceiveSequenceFailed := Exception.Create('verify that contract''s receive sequence is illegal');
  ErrVerifySendIsAlreadyReceived := Exception.Create('block is already received successfully');
  ErrVerifyVmResultInconsistent := Exception.Create('inconsistent execution results in vm');

end.
